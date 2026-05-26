#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
record_file="$tmpdir/cargo-invocations"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/cargo" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$PHPC_FAKE_CARGO_RECORD"
SH
chmod +x "$tmpdir/cargo"

PATH="$tmpdir:$PATH" \
PHPC_FAKE_CARGO_RECORD="$record_file" \
CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/ubuntu/phpc-targets/local-gate-test}" \
  scripts/local-gate.sh

if ! grep -Fx "test" "$record_file" >/dev/null; then
  echo "local-gate.sh did not invoke cargo test" >&2
  cat "$record_file" >&2
  exit 1
fi
