#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

abi_backup="$(mktemp)"
trap 'cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md; rm -f "$abi_backup"' EXIT

cp docs/NATIVE_RUNTIME_ABI.md "$abi_backup"

scripts/verify-runtime-abi-docs.sh

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- `phpc_value_kind(handle) -> kind`\n", "")
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted an undocumented runtime export" >&2
  exit 1
fi

if ! grep -F "runtime exports missing from ABI doc: phpc_value_kind" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected missing-helper diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md
scripts/verify-runtime-abi-docs.sh
