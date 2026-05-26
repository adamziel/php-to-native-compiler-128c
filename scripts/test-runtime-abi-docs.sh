#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

out_file="$tmpdir/runtime-abi-docs-test.out"
err_file="$tmpdir/runtime-abi-docs-test.err"

case "$out_file:$err_file" in
  "$tmpdir"/*:"$tmpdir"/*) ;;
  *)
    echo "test-runtime-abi-docs.sh must keep captured output files under its per-run temp directory" >&2
    exit 1
    ;;
esac

new_fixture() {
  local fixture
  fixture="$(mktemp "$tmpdir/runtime-abi-doc.XXXXXX.md")"
  cp docs/NATIVE_RUNTIME_ABI.md "$fixture"
  printf '%s\n' "$fixture"
}

verify_fixture() {
  RUNTIME_ABI_DOC_PATH="$1" scripts/verify-runtime-abi-docs.sh
}

expect_fixture_failure() {
  local fixture="$1"
  local expected="$2"
  local label="$3"

  if RUNTIME_ABI_DOC_PATH="$fixture" scripts/verify-runtime-abi-docs.sh >"$out_file" 2>"$err_file"; then
    echo "verify-runtime-abi-docs.sh accepted $label" >&2
    exit 1
  fi

  if ! grep -F "$expected" "$err_file" >/dev/null; then
    echo "verify-runtime-abi-docs.sh failed without the expected diagnostic for $label" >&2
    cat "$err_file" >&2
    exit 1
  fi
}

mutate_fixture() {
  FIXTURE_DOC="$1" python3 - "$2" "$3" <<'PY'
import os
import sys
from pathlib import Path

path = Path(os.environ["FIXTURE_DOC"])
old = sys.argv[1]
new = sys.argv[2]
text = path.read_text(encoding="utf-8")
if old not in text:
    raise SystemExit(f"fixture mutation source text not found: {old!r}")
path.write_text(text.replace(old, new), encoding="utf-8")
PY
}

scripts/verify-runtime-abi-docs.sh

fixture="$(new_fixture)"
mutate_fixture "$fixture" '- `phpc_value_kind(handle) -> kind`
' ''
expect_fixture_failure \
  "$fixture" \
  "runtime exports missing from ABI doc: phpc_value_kind" \
  "an undocumented runtime export"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  '- `binary_string_data_reports_invalid_handles`: invalid binary-string data access.
' \
  ''
expect_fixture_failure \
  "$fixture" \
  "runtime ABI tests missing doc classification: binary_string_data_reports_invalid_handles" \
  "an unclassified runtime ABI test"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  '- `cloned_binary_string_owns_independent_bytes`: cloned binary strings remain valid after freeing the source handle.
' \
  '- `cloned_binary_string_owns_independent_bytes`: cloned binary strings remain valid after freeing the source handle.
- `stale_runtime_abi_test`: stale classification fixture.
'
expect_fixture_failure \
  "$fixture" \
  "ABI doc test classifications missing from runtime tests: stale_runtime_abi_test" \
  "a stale runtime ABI test classification"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  ' Test: `binary_string_data_reports_invalid_handles`.' \
  ''
expect_fixture_failure \
  "$fixture" \
  "ownership claims missing runtime test annotations" \
  "an untested ownership claim"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  'Test: `binary_string_rejects_null_pointer_with_nonzero_len`.' \
  'Test: `missing_runtime_ownership_test`.'
expect_fixture_failure \
  "$fixture" \
  "missing_runtime_ownership_test" \
  "an ownership claim with a missing runtime test"

fixture="$(new_fixture)"
mutate_fixture "$fixture" '- `PHPC_STATUS_INVALID_ARGUMENT = -2`
' ''
expect_fixture_failure \
  "$fixture" \
  "runtime constants missing from ABI doc: PHPC_STATUS_INVALID_ARGUMENT" \
  "an undocumented runtime constant"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  '- `PHPC_VALUE_KIND_BINARY_STRING = 1`
' \
  '- `PHPC_VALUE_KIND_BINARY_STRING = 2`
'
expect_fixture_failure \
  "$fixture" \
  "PHPC_VALUE_KIND_BINARY_STRING documented=2 source=1" \
  "a runtime constant value mismatch"

fixture="$(new_fixture)"
mutate_fixture "$fixture" '- `PhpcHeaderResult::NullHeader = 2`
' ''
expect_fixture_failure \
  "$fixture" \
  "runtime header results missing from ABI doc: PhpcHeaderResult::NullHeader" \
  "an undocumented header result"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  '- `PhpcHeaderResult::HeadersAlreadySent = 5`
' \
  '- `PhpcHeaderResult::HeadersAlreadySent = 5`
- `PhpcHeaderResult::StaleFixture = 6`
'
expect_fixture_failure \
  "$fixture" \
  "ABI doc header results not defined by runtime: PhpcHeaderResult::StaleFixture" \
  "a stale header result"

fixture="$(new_fixture)"
mutate_fixture "$fixture" \
  '- `PhpcHeaderResult::ContainsLineBreak = 4`
' \
  '- `PhpcHeaderResult::ContainsLineBreak = 7`
'
expect_fixture_failure \
  "$fixture" \
  "PhpcHeaderResult::ContainsLineBreak documented=7 source=4" \
  "a header result value mismatch"

fixture="$(new_fixture)"
verify_fixture "$fixture"
