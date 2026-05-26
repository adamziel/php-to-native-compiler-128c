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

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "- `binary_string_data_reports_invalid_handles`: invalid binary-string data access.\n",
    "",
)
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted an unclassified runtime ABI test" >&2
  exit 1
fi

if ! grep -F "runtime ABI tests missing doc classification: binary_string_data_reports_invalid_handles" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected missing-classification diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
marker = "- `binary_string_data_reports_invalid_handles`: invalid binary-string data access.\n"
text = text.replace(marker, marker + "- `stale_runtime_abi_test`: stale classification fixture.\n")
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted a stale runtime ABI test classification" >&2
  exit 1
fi

if ! grep -F "ABI doc test classifications missing from runtime tests: stale_runtime_abi_test" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected stale-classification diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md
scripts/verify-runtime-abi-docs.sh

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace(" Test: `binary_string_data_reports_invalid_handles`.", "")
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted an untested ownership claim" >&2
  exit 1
fi

if ! grep -F "ownership claims missing runtime test annotations" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected missing-test-annotation diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "Test: `binary_string_rejects_null_pointer_with_nonzero_len`.",
    "Test: `missing_runtime_ownership_test`.",
)
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted an ownership claim with a missing runtime test" >&2
  exit 1
fi

if ! grep -F "missing_runtime_ownership_test" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected missing-runtime-test diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md
scripts/verify-runtime-abi-docs.sh

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- `PHPC_STATUS_INVALID_ARGUMENT = -2`\n", "")
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted an undocumented runtime constant" >&2
  exit 1
fi

if ! grep -F "runtime constants missing from ABI doc: PHPC_STATUS_INVALID_ARGUMENT" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected missing-constant diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md

python3 - <<'PY'
from pathlib import Path

path = Path("docs/NATIVE_RUNTIME_ABI.md")
text = path.read_text(encoding="utf-8")
text = text.replace("- `PHPC_VALUE_KIND_BINARY_STRING = 1`\n", "- `PHPC_VALUE_KIND_BINARY_STRING = 2`\n")
path.write_text(text, encoding="utf-8")
PY

if scripts/verify-runtime-abi-docs.sh >/tmp/phpc-runtime-abi-docs-test.out 2>/tmp/phpc-runtime-abi-docs-test.err; then
  echo "verify-runtime-abi-docs.sh accepted a runtime constant value mismatch" >&2
  exit 1
fi

if ! grep -F "PHPC_VALUE_KIND_BINARY_STRING documented=2 source=1" /tmp/phpc-runtime-abi-docs-test.err >/dev/null; then
  echo "verify-runtime-abi-docs.sh failed without the expected wrong-value diagnostic" >&2
  cat /tmp/phpc-runtime-abi-docs-test.err >&2
  exit 1
fi

cp "$abi_backup" docs/NATIVE_RUNTIME_ABI.md
scripts/verify-runtime-abi-docs.sh
