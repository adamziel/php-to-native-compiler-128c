#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

out_file="$tmpdir/worker-env.out"
err_file="$tmpdir/worker-env.err"
fixture_root="$tmpdir/phpc-worktrees"
fixture_worktree="$fixture_root/INT-05"
fixture_target_root="$tmpdir/phpc-targets"
fixture_target_dir="$fixture_target_root/INT-05"
mkdir -p "$fixture_worktree"

run_fixture() {
  PHPC_WORKTREE_ROOT="$fixture_worktree" \
    PHPC_TARGET_ROOT="$fixture_target_root" \
    PHPC_LANE_ID=INT-05 \
    env -u PHPC_EXPECT_BRANCH -u PHPC_ALLOW_WORKTREE_LANE_MISMATCH "$@"
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
  "PHPC_WORKTREE_ROOT must be absolute: relative/INT-05" \
  "a relative worktree root" \
  env PHPC_WORKTREE_ROOT=relative/INT-05 CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh

expect_failure \
  "PHPC_WORKTREE_ROOT must exist as a directory: $tmpdir/missing/INT-05" \
  "a missing worktree root" \
  env PHPC_WORKTREE_ROOT="$tmpdir/missing/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh

expect_failure \
  "PHPC_TARGET_ROOT must be absolute: relative-targets" \
  "a relative target root" \
  env PHPC_TARGET_ROOT=relative-targets CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh

expect_failure \
  "PHPC_ALLOW_WORKTREE_LANE_MISMATCH must be 0 or 1, got yes" \
  "a non-boolean worktree lane mismatch flag" \
  env PHPC_ALLOW_WORKTREE_LANE_MISMATCH=yes CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh

expect_failure \
  "PHPC_REQUIRE_CLEAN_WORKTREE must be 0 or 1, got yes" \
  "a non-boolean clean worktree flag" \
  env PHPC_REQUIRE_CLEAN_WORKTREE=yes CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh

expect_failure \
  "PHPC_LANE_ID must match worktree basename INT-05" \
  "a mismatched worktree lane id" \
  env PHPC_LANE_ID=INT-06 CARGO_TARGET_DIR="$fixture_target_root/INT-06" scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must be set for lane INT-05" \
  "an unset target directory" \
  env -u CARGO_TARGET_DIR scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must be absolute" \
  "a relative target directory" \
  env CARGO_TARGET_DIR=target/INT-05 scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must be $fixture_target_dir" \
  "the wrong lane target directory" \
  env CARGO_TARGET_DIR="$fixture_target_root/INT-06" scripts/verify-worker-env.sh

mkdir -p "$tmpdir/non-git/INT-05"
expect_failure \
  "worktree root must be a git worktree for lane INT-05: $tmpdir/non-git/INT-05" \
  "a non-git worktree root" \
  env PHPC_WORKTREE_ROOT="$tmpdir/non-git/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=lane/INT-05 scripts/verify-worker-env.sh

expect_failure \
  "worktree root must be a git worktree for lane INT-05: $tmpdir/non-git/INT-05" \
  "a non-git clean-required worktree root" \
  env PHPC_WORKTREE_ROOT="$tmpdir/non-git/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_REQUIRE_CLEAN_WORKTREE=1 scripts/verify-worker-env.sh

expect_failure \
  "CARGO_TARGET_DIR must not be inside the worktree" \
  "a worktree-local target directory" \
  env PHPC_TARGET_ROOT="$fixture_root" CARGO_TARGET_DIR="$fixture_root/INT-05" scripts/verify-worker-env.sh

if PHPC_REQUIRE_WORKER_ENV=yes CARGO_TARGET_DIR="$fixture_target_dir" scripts/local-gate.sh >"$out_file" 2>"$err_file"; then
  echo "local-gate.sh accepted a non-boolean PHPC_REQUIRE_WORKER_ENV" >&2
  exit 1
fi

if ! grep -F "PHPC_REQUIRE_WORKER_ENV to be 0 or 1, got yes" "$err_file" >/dev/null; then
  echo "local-gate.sh failed without the expected PHPC_REQUIRE_WORKER_ENV diagnostic" >&2
  cat "$err_file" >&2
  exit 1
fi

run_fixture env CARGO_TARGET_DIR="$fixture_target_dir" scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=$fixture_target_dir" "$out_file" >/dev/null

expect_failure \
  "PHPC_EXPECT_BRANCH must start with lane/INT-05 for lane INT-05, got main" \
  "an expected branch outside lane namespace" \
  env PHPC_ALLOW_WORKTREE_LANE_MISMATCH=1 PHPC_WORKTREE_ROOT="$repo_root" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=main scripts/verify-worker-env.sh

expect_failure \
  "PHPC_EXPECT_BRANCH must start with lane/INT-05 for lane INT-05, got lane/not-current" \
  "an expected branch for a different lane" \
  env PHPC_ALLOW_WORKTREE_LANE_MISMATCH=1 PHPC_WORKTREE_ROOT="$repo_root" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=lane/not-current scripts/verify-worker-env.sh

expect_failure \
  "current branch must be lane/INT-05-not-current for lane INT-05" \
  "a valid expected lane branch that is not checked out" \
  env PHPC_ALLOW_WORKTREE_LANE_MISMATCH=1 PHPC_WORKTREE_ROOT="$repo_root" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=lane/INT-05-not-current scripts/verify-worker-env.sh

git init -q "$tmpdir/INT-05"
git -C "$tmpdir/INT-05" config user.email test@example.invalid
git -C "$tmpdir/INT-05" config user.name "Integration Test"
printf 'clean\n' > "$tmpdir/INT-05/file.txt"
git -C "$tmpdir/INT-05" add file.txt
git -C "$tmpdir/INT-05" commit -q -m clean
git -C "$tmpdir/INT-05" switch -q -c lane/INT-05

run_fixture env PHPC_WORKTREE_ROOT="$tmpdir/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_REQUIRE_CLEAN_WORKTREE=1 scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=$fixture_target_dir" "$out_file" >/dev/null

run_fixture env PHPC_WORKTREE_ROOT="$tmpdir/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=lane/INT-05 scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=$fixture_target_dir" "$out_file" >/dev/null

git -C "$tmpdir/INT-05" switch -q -c lane/INT-05-fresh-test
run_fixture env PHPC_WORKTREE_ROOT="$tmpdir/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_EXPECT_BRANCH=lane/INT-05-fresh-test scripts/verify-worker-env.sh >"$out_file"
grep -F "worker env ok: lane=INT-05 CARGO_TARGET_DIR=$fixture_target_dir" "$out_file" >/dev/null

printf 'dirty\n' >> "$tmpdir/INT-05/file.txt"
expect_failure \
  "worktree must be clean for lane INT-05" \
  "a dirty worktree when cleanliness is required" \
  env PHPC_WORKTREE_ROOT="$tmpdir/INT-05" CARGO_TARGET_DIR="$fixture_target_dir" PHPC_REQUIRE_CLEAN_WORKTREE=1 scripts/verify-worker-env.sh
