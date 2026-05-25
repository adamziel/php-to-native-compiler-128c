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
mkdir -p "${worktree}/swarm/handoffs"

log_file="${worktree}/swarm/handoffs/${lane_id}.log"
state_file="${worktree}/swarm/handoffs/${lane_id}.state"
slot_root="${SWARM_SLOT_ROOT:-/tmp/phpc-swarm-codex-slots}"
max_active="${SWARM_MAX_ACTIVE_CODEX:-8}"
mkdir -p "$slot_root"

lane_num="$(printf '%s' "$lane_id" | cksum | awk '{print $1}')"

acquire_slot() {
  local slot
  while true; do
    for slot in $(seq 1 "$max_active"); do
      if mkdir "${slot_root}/${slot}.lock" 2>/dev/null; then
        printf '%s\n' "$slot"
        return 0
      fi
    done
    date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} waiting for codex slot (${max_active} active max)" | tee -a "$log_file" >&2
    sleep $((20 + lane_num % 40))
  done
}

release_slot() {
  local slot="${1:-}"
  if [ -n "$slot" ]; then
    rmdir "${slot_root}/${slot}.lock" 2>/dev/null || true
  fi
}

while true; do
  slot="$(acquire_slot)"
  tmp_log="$(mktemp)"
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} starting slice in slot ${slot}" | tee -a "$log_file"
  set +e
  codex exec \
    --cd "$worktree" \
    --dangerously-bypass-approvals-and-sandbox \
    "$(cat "$prompt_file")" 2>&1 | tee "$tmp_log"
  status="${PIPESTATUS[0]}"
  set -e
  release_slot "$slot"
  cat "$tmp_log" >> "$log_file"
  if grep -q "429 Too Many Requests" "$tmp_log"; then
    cooldown=$((240 + lane_num % 180))
    date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} rate-limited; cooling down ${cooldown}s" | tee -a "$log_file"
    printf 'rate_limited cooldown=%s last_status=%s updated=%s\n' "$cooldown" "$status" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$state_file"
    rm -f "$tmp_log"
    sleep "$cooldown"
    continue
  fi
  rm -f "$tmp_log"
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} slice ended with status ${status}" | tee -a "$log_file"
  printf 'last_status=%s updated=%s\n' "$status" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$state_file"
  sleep $((45 + lane_num % 45))
done
