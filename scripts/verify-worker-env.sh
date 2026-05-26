#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
worktree_root="${PHPC_WORKTREE_ROOT:-$repo_root}"
target_root="${PHPC_TARGET_ROOT:-/home/ubuntu/phpc-targets}"
lane_id="${PHPC_LANE_ID:-$(basename "$worktree_root")}"
expected_target_dir="${target_root%/}/$lane_id"
expected_branch="${PHPC_EXPECT_BRANCH:-}"
require_clean_worktree="${PHPC_REQUIRE_CLEAN_WORKTREE:-0}"
allow_worktree_lane_mismatch="${PHPC_ALLOW_WORKTREE_LANE_MISMATCH:-0}"
worktree_lane="$(basename "$worktree_root")"

case "$allow_worktree_lane_mismatch" in
  0|1) ;;
  *)
    echo "worker env error: PHPC_ALLOW_WORKTREE_LANE_MISMATCH must be 0 or 1, got $allow_worktree_lane_mismatch" >&2
    exit 1
    ;;
esac

case "$require_clean_worktree" in
  0|1) ;;
  *)
    echo "worker env error: PHPC_REQUIRE_CLEAN_WORKTREE must be 0 or 1, got $require_clean_worktree" >&2
    exit 1
    ;;
esac

if [[ "$allow_worktree_lane_mismatch" != "1" && "$worktree_lane" != "$lane_id" ]]; then
  echo "worker env error: PHPC_LANE_ID must match worktree basename $worktree_lane, got $lane_id" >&2
  exit 1
fi

if [[ -z "${CARGO_TARGET_DIR:-}" ]]; then
  echo "worker env error: CARGO_TARGET_DIR must be set for lane $lane_id" >&2
  exit 1
fi

case "$CARGO_TARGET_DIR" in
  /*) ;;
  *)
    echo "worker env error: CARGO_TARGET_DIR must be absolute: $CARGO_TARGET_DIR" >&2
    exit 1
    ;;
esac

if [[ "$CARGO_TARGET_DIR" != "$expected_target_dir" ]]; then
  echo "worker env error: CARGO_TARGET_DIR must be $expected_target_dir for lane $lane_id, got $CARGO_TARGET_DIR" >&2
  exit 1
fi

case "$CARGO_TARGET_DIR" in
  "$worktree_root" | "$worktree_root"/*)
    echo "worker env error: CARGO_TARGET_DIR must not be inside the worktree: $CARGO_TARGET_DIR" >&2
    exit 1
    ;;
esac

if [[ -n "$expected_branch" || "$require_clean_worktree" = "1" ]]; then
  if ! git -C "$worktree_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "worker env error: worktree root must be a git worktree for lane $lane_id: $worktree_root" >&2
    exit 1
  fi
fi

if [[ -n "$expected_branch" ]]; then
  current_branch="$(git -C "$worktree_root" branch --show-current)"
  if [[ "$current_branch" != "$expected_branch" ]]; then
    echo "worker env error: current branch must be $expected_branch for lane $lane_id, got ${current_branch:-detached HEAD}" >&2
    exit 1
  fi
fi

if [[ "$require_clean_worktree" = "1" ]]; then
  if [[ -n "$(git -C "$worktree_root" status --porcelain)" ]]; then
    echo "worker env error: worktree must be clean for lane $lane_id" >&2
    exit 1
  fi
fi

printf 'worker env ok: lane=%s CARGO_TARGET_DIR=%s\n' "$lane_id" "$CARGO_TARGET_DIR"
