#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
import pathlib
import re
import sys

root = pathlib.Path.cwd()
runtime_src = root / "crates/php_runtime/src/lib.rs"
abi_doc = root / "docs/NATIVE_RUNTIME_ABI.md"

source = runtime_src.read_text(encoding="utf-8")
doc = abi_doc.read_text(encoding="utf-8")

exported = set(
    re.findall(
        r"#\[no_mangle\]\s+pub\s+(?:unsafe\s+)?extern\s+\"C\"\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        source,
        flags=re.MULTILINE,
    )
)

section_match = re.search(
    r"Existing exported helpers:\n\n(?P<section>(?:- `[^`]+`\n)+)",
    doc,
    flags=re.MULTILINE,
)
if not section_match:
    raise SystemExit("docs/NATIVE_RUNTIME_ABI.md missing `Existing exported helpers` list")

documented = set()
for line in section_match.group("section").splitlines():
    item = re.match(r"- `([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(|->|`)", line)
    if not item:
        raise SystemExit(f"unparseable ABI helper documentation line: {line}")
    documented.add(item.group(1))

missing = sorted(exported - documented)
stale = sorted(documented - exported)

errors = []
if missing:
    errors.append("runtime exports missing from ABI doc: " + ", ".join(missing))
if stale:
    errors.append("ABI doc helpers not exported by runtime: " + ", ".join(stale))

source_constants = {
    name: int(value)
    for name, value in re.findall(
        r"pub\s+const\s+(PHPC_(?:VALUE_KIND|STATUS)_[A-Z0-9_]+):\s+i32\s+=\s+(-?\d+);",
        source,
    )
}

documented_constants = {
    name: int(value)
    for name, value in re.findall(
        r"- `(PHPC_(?:VALUE_KIND|STATUS)_[A-Z0-9_]+)\s+=\s+(-?\d+)`",
        doc,
    )
}

missing_constants = sorted(set(source_constants) - set(documented_constants))
stale_constants = sorted(set(documented_constants) - set(source_constants))
wrong_values = sorted(
    name
    for name in set(source_constants) & set(documented_constants)
    if source_constants[name] != documented_constants[name]
)

if missing_constants:
    errors.append(
        "runtime constants missing from ABI doc: " + ", ".join(missing_constants)
    )
if stale_constants:
    errors.append(
        "ABI doc constants not defined by runtime: " + ", ".join(stale_constants)
    )
if wrong_values:
    errors.append(
        "ABI doc constants with wrong values: "
        + ", ".join(
            f"{name} documented={documented_constants[name]} source={source_constants[name]}"
            for name in wrong_values
        )
    )

test_names = set(
    re.findall(
        r"#\[test\]\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        source,
        flags=re.MULTILINE,
    )
)

ownership_match = re.search(
    r"## Value Handle Ownership\n\n(?P<section>(?:- .+\n)+)",
    doc,
    flags=re.MULTILINE,
)
if not ownership_match:
    errors.append("docs/NATIVE_RUNTIME_ABI.md missing `Value Handle Ownership` section")
else:
    missing_test_annotations = []
    unknown_test_annotations = {}
    for line in ownership_match.group("section").splitlines():
        if not line.startswith("- "):
            continue
        annotation_match = re.search(r"\bTests?: ([^.]+)\.$", line)
        if not annotation_match:
            missing_test_annotations.append(line)
            continue
        documented_tests = [
            test.strip().strip("`")
            for test in annotation_match.group(1).split(",")
        ]
        unknown_tests = sorted(test for test in documented_tests if test not in test_names)
        if unknown_tests:
            unknown_test_annotations[line] = unknown_tests

    if missing_test_annotations:
        errors.append(
            "ownership claims missing runtime test annotations: "
            + " | ".join(missing_test_annotations)
        )
    if unknown_test_annotations:
        errors.append(
            "ownership claims reference missing runtime tests: "
            + " | ".join(
                f"{line} -> {', '.join(tests)}"
                for line, tests in unknown_test_annotations.items()
            )
        )

classification_match = re.search(
    r"## Runtime ABI Test Classification\n\n(?P<section>(?:- `[^`]+`: .+\n)+)",
    doc,
    flags=re.MULTILINE,
)
if not classification_match:
    errors.append("docs/NATIVE_RUNTIME_ABI.md missing `Runtime ABI Test Classification` section")
else:
    classified_tests = {}
    malformed_classifications = []
    for line in classification_match.group("section").splitlines():
        item = re.match(r"- `([A-Za-z_][A-Za-z0-9_]*)`: (.+)\.$", line)
        if not item:
            malformed_classifications.append(line)
            continue
        classified_tests[item.group(1)] = item.group(2)

    if malformed_classifications:
        errors.append(
            "unparseable runtime ABI test classifications: "
            + " | ".join(malformed_classifications)
        )

    missing_classifications = sorted(test_names - set(classified_tests))
    stale_classifications = sorted(set(classified_tests) - test_names)
    empty_classifications = sorted(
        test for test, classification in classified_tests.items() if not classification.strip()
    )

    if missing_classifications:
        errors.append(
            "runtime ABI tests missing doc classification: "
            + ", ".join(missing_classifications)
        )
    if stale_classifications:
        errors.append(
            "ABI doc test classifications missing from runtime tests: "
            + ", ".join(stale_classifications)
        )
    if empty_classifications:
        errors.append(
            "runtime ABI test classifications are empty: "
            + ", ".join(empty_classifications)
        )

if errors:
    for error in errors:
        print(f"runtime ABI documentation error: {error}", file=sys.stderr)
    sys.exit(1)

print(
    "runtime ABI docs ok: "
    f"{len(exported)} exported helpers, {len(source_constants)} constants, "
    f"{len(test_names)} classified tests, and ownership test annotations documented"
)
PY
