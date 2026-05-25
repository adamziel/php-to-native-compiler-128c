#!/usr/bin/env bash
set -euo pipefail

lane_id="${1:?lane id required}"
worktree="${2:?worktree path required}"
prompt_file="${3:?prompt file required}"

export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-1}"
export CARGO_INCREMENTAL="${CARGO_INCREMENTAL:-0}"
export RUST_TEST_THREADS="${RUST_TEST_THREADS:-1}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/ubuntu/phpc-targets/${lane_id}}"

mkdir -p "$CARGO_TARGET_DIR"

while true; do
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} starting slice" | tee -a "${worktree}/swarm/handoffs/${lane_id}.log"
  codex exec \
    --cd "$worktree" \
    --dangerously-bypass-approvals-and-sandbox \
    "$(cat "$prompt_file")" || true
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} slice ended" | tee -a "${worktree}/swarm/handoffs/${lane_id}.log"
  sleep 15
done
