#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
session="${SWARM_SESSION:-phpc-swarm}"
worktree_root="${WORKTREE_ROOT:-/home/ubuntu/phpc-worktrees}"
target_root="${TARGET_ROOT:-/home/ubuntu/phpc-targets}"
interval="${SWARM_WATCHDOG_INTERVAL:-60}"
max_active_codex="${SWARM_MAX_ACTIVE_CODEX:-50}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-0}"

lanes=(
  INT-01 INT-02 INT-03 INT-04 INT-05 INT-06 INT-07 INT-08
  ABI-01 ABI-02 ABI-03 ABI-04 ABI-05 ABI-06 ABI-07 ABI-08 ABI-09 ABI-10 ABI-11 ABI-12
  LINK-01 LINK-02 LINK-03 LINK-04 LINK-05 LINK-06 LINK-07 LINK-08 LINK-09 LINK-10 LINK-11 LINK-12
  LOW-01 LOW-02 LOW-03 LOW-04 LOW-05 LOW-06 LOW-07 LOW-08 LOW-09 LOW-10 LOW-11 LOW-12 LOW-13 LOW-14 LOW-15 LOW-16
  PHPT-01 PHPT-02 PHPT-03 PHPT-04 PHPT-05 PHPT-06 PHPT-07 PHPT-08 PHPT-09 PHPT-10 PHPT-11 PHPT-12 PHPT-13 PHPT-14 PHPT-15 PHPT-16
  WP-01 WP-02 WP-03 WP-04 WP-05 WP-06 WP-07 WP-08 WP-09 WP-10 WP-11 WP-12
  SEM-01 SEM-02 SEM-03 SEM-04 SEM-05 SEM-06 SEM-07 SEM-08 SEM-09 SEM-10
  SAPI-01 SAPI-02 SAPI-03 SAPI-04 SAPI-05 SAPI-06 SAPI-07 SAPI-08
  MINE-01 MINE-02 MINE-03
  DOC-01 DOC-02 DOC-03
  AUD-01
)

lane_effort() {
  case "${1%%-*}" in
    ABI|LINK|SEM|SAPI|AUD) printf 'medium' ;;
    *) printf 'low' ;;
  esac
}

respawn_lane() {
  local lane="$1"
  local worktree="${worktree_root}/${lane}"
  local prompt="${repo_root}/swarm/worker-prompts/${lane}.md"
  local effort
  effort="$(lane_effort "$lane")"

  if [ ! -e "${worktree}/.git" ] || [ ! -f "$prompt" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: cannot respawn ${lane}; missing worktree or prompt"
    return 0
  fi

  mkdir -p "${target_root}/${lane}"
  tmux respawn-pane -k -t "${session}:${lane}" -c "$worktree" \
    "export CARGO_TARGET_DIR='${target_root}/${lane}' CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 SWARM_MAX_ACTIVE_CODEX='${max_active_codex}' SWARM_INITIAL_STAGGER_MAX='${initial_stagger_max}' CODEX_SERVICE_TIER='fast' CODEX_MODEL='gpt-5.5' CODEX_REASONING_EFFORT='${effort}'; '${repo_root}/scripts/worker-loop.sh' '${lane}' '${worktree}' '${prompt}'"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: respawned ${lane}"
}

ensure_reporter() {
  if tmux has-session -t phpc-pages-reporter 2>/dev/null; then
    return 0
  fi
  tmux new-session -d -s phpc-pages-reporter -n reporter -c "$repo_root" \
    "PAGES_REPORT_INTERVAL=180 ./scripts/pages-reporter-loop.sh"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: started phpc-pages-reporter"
}

while true; do
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${session} missing; launch-swarm.sh must be run by supervisor"
    sleep "$interval"
    continue
  fi

  ensure_reporter

  missing=0
  for lane in "${lanes[@]}"; do
    if ! tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -Fxq "$lane"; then
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${lane} window missing"
      missing=$((missing + 1))
      continue
    fi
    if ! pgrep -f "worker-loop.sh ${lane} " >/dev/null 2>&1; then
      respawn_lane "$lane"
    fi
  done

  windows="$(tmux list-windows -t "$session" 2>/dev/null | wc -l)"
  loops="$(pgrep -fc '/scripts/worker-loop.sh' || true)"
  codex="$(pgrep -fc 'codex exec' || true)"
  slots="$(find /tmp/phpc-swarm-codex-slots -maxdepth 1 -type d -name '*.lock' 2>/dev/null | wc -l)"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: windows=${windows} worker_loops=${loops} codex_exec=${codex} slot_locks=${slots} missing_windows=${missing}"
  sleep "$interval"
done
