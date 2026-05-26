#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

out_file="$tmpdir/worker-env.out"
err_file="$tmpdir/worker-env.err"
fixture_worktree="/tmp/phpc-worktrees/INT-05"
fixture_target_root="/tmp/phpc-targets"

run_fixture() {
  PHPC_WORKTREE_ROOT="$fixture_worktree" \
    PHPC_TARGET_ROOT="$fixture_target_root" \
    PHPC_LANE_ID=INT-05 \
    "$@"
}

expect_failure() {
  local expected="$1"
  local label="$2"
  shift 2

  if run_fixture "$@" >"$out_file" 2>"$err_file"; then
    echo "verify-worker-env.sh accepted $label" >&2
    exit 1
  fi

  if ! grep -F "$expected" "$err_file" >/dev/null; then
    echo "verify-worker-env.sh failed without the expected diagnostic for $label" >&2
    cat "$err_file" >&2
    exit 1
  fi
}

expect_failure \
  "CARGO_TARGET_DIR must be set for lane INT-05" \
  "an unset target directory" \
  env -u CARGO_TARGET_DIR scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must be absolute" \
  "a relative target directory" \
  env CARGO_TARGET_DIR=target/INT-05 scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must be /tmp/phpc-targets/INT-05" \
  "the wrong lane target directory" \
  env CARGO_TARGET_DIR=/tmp/phpc-targets/INT-06 scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must not be inside the worktree" \
  "a worktree-local target directory" \
  env PHPC_TARGET_ROOT=/tmp/phpc-worktrees CARGO_TARGET_DIR=/tmp/phpc-worktrees/INT-05 scripts/verify-worker-env.sh

run_fixture env CARGO_TARGET_DIR=/tmp/phpc-targets/INT-05 scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=/tmp/phpc-targets/INT-05" "$out_file" >/dev/null

current_branch="$(git branch --show-current)"

expect_failure \
  "current branch must be lane/not-current for lane INT-05" \
  "a mismatched expected branch" \
  env PHPC_WORKTREE_ROOT="$repo_root" CARGO_TARGET_DIR=/tmp/phpc-targets/INT-05 PHPC_EXPECT_BRANCH=lane/not-current scripts/verify-worker-env.sh

run_fixture env PHPC_WORKTREE_ROOT="$repo_root" CARGO_TARGET_DIR=/tmp/phpc-targets/INT-05 PHPC_EXPECT_BRANCH="$current_branch" scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=/tmp/phpc-targets/INT-05" "$out_file" >/dev/null
