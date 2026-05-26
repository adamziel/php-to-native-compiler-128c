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

if PATH="$tmpdir:$PATH" \
  PHPC_FAKE_CARGO_RECORD="$record_file" \
  env -u CARGO_TARGET_DIR scripts/local-gate.sh >"$tmpdir/unset-target.out" 2>"$tmpdir/unset-target.err"; then
  echo "local-gate.sh accepted an unset CARGO_TARGET_DIR" >&2
  exit 1
fi

if ! grep -F "requires CARGO_TARGET_DIR" "$tmpdir/unset-target.err" >/dev/null; then
  echo "local-gate.sh failed without the expected CARGO_TARGET_DIR diagnostic" >&2
  cat "$tmpdir/unset-target.err" >&2
  exit 1
fi

if [ -s "$record_file" ]; then
  echo "local-gate.sh invoked cargo before validating CARGO_TARGET_DIR" >&2
  cat "$record_file" >&2
  exit 1
fi

PATH="$tmpdir:$PATH" \
PHPC_FAKE_CARGO_RECORD="$record_file" \
CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/ubuntu/phpc-targets/local-gate-test}" \
  scripts/local-gate.sh

if ! grep -Fx "test" "$record_file" >/dev/null; then
  echo "local-gate.sh did not invoke cargo test" >&2
  cat "$record_file" >&2
  exit 1
fi

: >"$record_file"
PATH="$tmpdir:$PATH" \
PHPC_FAKE_CARGO_RECORD="$record_file" \
PHPC_REQUIRE_WORKER_ENV=1 \
PHPC_WORKTREE_ROOT="$repo_root" \
PHPC_ALLOW_WORKTREE_LANE_MISMATCH=1 \
PHPC_TARGET_ROOT=/tmp/phpc-targets \
PHPC_LANE_ID=LOCAL-GATE \
CARGO_TARGET_DIR=/tmp/phpc-targets/LOCAL-GATE \
  scripts/local-gate.sh

if ! grep -Fx "test" "$record_file" >/dev/null; then
  echo "local-gate.sh did not continue to cargo test after worker env preflight passed" >&2
  cat "$record_file" >&2
  exit 1
fi

: >"$record_file"
if PATH="$tmpdir:$PATH" \
  PHPC_FAKE_CARGO_RECORD="$record_file" \
  PHPC_REQUIRE_WORKER_ENV=1 \
  PHPC_WORKTREE_ROOT="$repo_root" \
  PHPC_ALLOW_WORKTREE_LANE_MISMATCH=1 \
  PHPC_TARGET_ROOT=/tmp/phpc-targets \
  PHPC_LANE_ID=LOCAL-GATE \
  CARGO_TARGET_DIR=/tmp/phpc-targets/OTHER \
  scripts/local-gate.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "local-gate.sh accepted a mismatched worker CARGO_TARGET_DIR" >&2
  exit 1
fi

if ! grep -F "CARGO_TARGET_DIR must be /tmp/phpc-targets/LOCAL-GATE" "$tmpdir/err" >/dev/null; then
  echo "local-gate.sh failed without the expected worker env diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

if [ -s "$record_file" ]; then
  echo "local-gate.sh invoked cargo after worker env preflight failed" >&2
  cat "$record_file" >&2
  exit 1
fi
