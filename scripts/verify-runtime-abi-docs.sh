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

if errors:
    for error in errors:
        print(f"runtime ABI documentation error: {error}", file=sys.stderr)
    sys.exit(1)

print(f"runtime ABI docs ok: {len(exported)} exported helpers documented")
PY
