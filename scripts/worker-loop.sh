#!/usr/bin/env bash
set -euo pipefail

lane_id="${1:?lane id required}"
worktree="${2:?worktree path required}"
prompt_file="${3:?prompt file required}"

export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-1}"
export CARGO_INCREMENTAL="${CARGO_INCREMENTAL:-0}"
export RUST_TEST_THREADS="${RUST_TEST_THREADS:-1}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/ubuntu/phpc-targets/${lane_id}}"
export CODEX_MODEL="${CODEX_MODEL:-gpt-5.5}"
export CODEX_REASONING_EFFORT="${CODEX_REASONING_EFFORT:-low}"
export CODEX_SERVICE_TIER="${CODEX_SERVICE_TIER:-fast}"

mkdir -p "$CARGO_TARGET_DIR"
mkdir -p "${worktree}/swarm/handoffs"

log_file="${worktree}/swarm/handoffs/${lane_id}.log"
state_file="${worktree}/swarm/handoffs/${lane_id}.state"
slot_root="${SWARM_SLOT_ROOT:-/tmp/phpc-swarm-codex-slots}"
max_active="${SWARM_MAX_ACTIVE_CODEX:-30}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-90}"
mkdir -p "$slot_root"

lane_num="$(printf '%s' "$lane_id" | cksum | awk '{print $1}')"

acquire_slot() {
  local slot
  acquired_slot=""
  while true; do
    for slot in $(seq 1 "$max_active"); do
      if mkdir "${slot_root}/${slot}.lock" 2>/dev/null; then
        printf '%s\n' "$$" > "${slot_root}/${slot}.lock/owner.pid"
        acquired_slot="$slot"
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

if [ "$initial_stagger_max" -gt 0 ]; then
  initial_sleep=$((lane_num % initial_stagger_max))
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} initial stagger ${initial_sleep}s" | tee -a "$log_file"
  sleep "$initial_sleep"
fi

while true; do
  acquire_slot
  slot="$acquired_slot"
  tmp_log="$(mktemp)"
  date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} starting slice in slot ${slot}" | tee -a "$log_file"
  set +e
  codex exec \
    --cd "$worktree" \
    --model "$CODEX_MODEL" \
    -c "service_tier=\"${CODEX_SERVICE_TIER}\"" \
    -c "model_reasoning_effort=\"${CODEX_REASONING_EFFORT}\"" \
    --dangerously-bypass-approvals-and-sandbox \
    "$(cat "$prompt_file")" 2>&1 | tee "$tmp_log"
  status="${PIPESTATUS[0]}"
  set -e
  release_slot "$slot"
  cat "$tmp_log" >> "$log_file"
  if grep -Eq "429 Too Many Requests|ERROR: Reconnecting|exceeded retry limit" "$tmp_log"; then
    cooldown=$((180 + lane_num % 240))
    date -u +"%Y-%m-%dT%H:%M:%SZ worker ${lane_id} backend reconnect/rate-limit; cooling down ${cooldown}s" | tee -a "$log_file"
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
