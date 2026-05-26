#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
import pathlib
import re
import sys


def read_inputs():
    root = pathlib.Path.cwd()
    runtime_src = root / "crates/php_runtime/src/lib.rs"
    abi_doc = root / "docs/NATIVE_RUNTIME_ABI.md"
    return (
        runtime_src.read_text(encoding="utf-8"),
        abi_doc.read_text(encoding="utf-8"),
    )


def runtime_exports(source):
    return set(
        re.findall(
            r"#\[no_mangle\]\s+pub\s+(?:unsafe\s+)?extern\s+\"C\"\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            source,
            flags=re.MULTILINE,
        )
    )


def documented_exports(doc):
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
    return documented


def check_exports(exported, documented):
    errors = []
    missing = sorted(exported - documented)
    stale = sorted(documented - exported)

    if missing:
        errors.append("runtime exports missing from ABI doc: " + ", ".join(missing))
    if stale:
        errors.append("ABI doc helpers not exported by runtime: " + ", ".join(stale))
    return errors


def runtime_constants(source):
    return {
        name: int(value)
        for name, value in re.findall(
            r"pub\s+const\s+(PHPC_(?:VALUE_KIND|STATUS)_[A-Z0-9_]+):\s+i32\s+=\s+(-?\d+);",
            source,
        )
    }


def documented_constants(doc):
    return {
        name: int(value)
        for name, value in re.findall(
            r"- `(PHPC_(?:VALUE_KIND|STATUS)_[A-Z0-9_]+)\s+=\s+(-?\d+)`",
            doc,
        )
    }


def check_constants(source_constants, documented_constants):
    errors = []
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
    return errors


def runtime_tests(source):
    return set(
        re.findall(
            r"#\[test\]\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            source,
            flags=re.MULTILINE,
        )
    )


def check_ownership_annotations(doc, test_names):
    errors = []
    ownership_match = re.search(
        r"## Value Handle Ownership\n\n(?P<section>(?:- .+\n)+)",
        doc,
        flags=re.MULTILINE,
    )
    if not ownership_match:
        return ["docs/NATIVE_RUNTIME_ABI.md missing `Value Handle Ownership` section"]

    missing_test_annotations = []
    unknown_test_annotations = {}
    for line in ownership_match.group("section").splitlines():
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
    return errors


def check_test_classifications(doc, test_names):
    errors = []
    classification_match = re.search(
        r"## Runtime ABI Test Classification\n\n(?P<section>(?:- `[^`]+`: .+\n)+)",
        doc,
        flags=re.MULTILINE,
    )
    if not classification_match:
        return ["docs/NATIVE_RUNTIME_ABI.md missing `Runtime ABI Test Classification` section"]

    malformed_classifications = []
    classified_tests = {}
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
    return errors


def main():
    source, doc = read_inputs()
    exported = runtime_exports(source)
    documented = documented_exports(doc)
    source_constants = runtime_constants(source)
    doc_constants = documented_constants(doc)
    test_names = runtime_tests(source)

    errors = []
    errors.extend(check_exports(exported, documented))
    errors.extend(check_constants(source_constants, doc_constants))
    errors.extend(check_ownership_annotations(doc, test_names))
    errors.extend(check_test_classifications(doc, test_names))

    if errors:
        for error in errors:
            print(f"runtime ABI documentation error: {error}", file=sys.stderr)
        sys.exit(1)

    print(
        "runtime ABI docs ok: "
        f"{len(exported)} exported helpers, {len(source_constants)} constants, "
        f"{len(test_names)} classified tests, and ownership test annotations documented"
    )


main()
PY
