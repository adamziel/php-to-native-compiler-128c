#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
worktree_root="${PHPC_WORKTREE_ROOT:-$repo_root}"
target_root="${PHPC_TARGET_ROOT:-/home/ubuntu/phpc-targets}"
lane_id="${PHPC_LANE_ID:-$(basename "$worktree_root")}"
expected_target_dir="${target_root%/}/$lane_id"

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

printf 'worker env ok: lane=%s CARGO_TARGET_DIR=%s\n' "$lane_id" "$CARGO_TARGET_DIR"
