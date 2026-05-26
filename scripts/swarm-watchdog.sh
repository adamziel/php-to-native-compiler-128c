#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
session="${SWARM_SESSION:-phpc-swarm}"
worktree_root="${WORKTREE_ROOT:-/home/ubuntu/phpc-worktrees}"
target_root="${TARGET_ROOT:-/home/ubuntu/phpc-targets}"
interval="${SWARM_WATCHDOG_INTERVAL:-60}"
max_active_codex="${SWARM_MAX_ACTIVE_CODEX:-19}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-0}"

source "$repo_root/scripts/swarm-lanes.sh"
swarm_select_lanes
lanes+=(AUD-01)

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

lane_has_direct_loop() {
  local lane="$1"
  local pane_pid
  pane_pid="$(tmux list-panes -t "${session}:${lane}" -F '#{pane_pid}' 2>/dev/null | head -n 1 || true)"
  if [ -z "$pane_pid" ]; then
    return 1
  fi
  ps -eo pid=,ppid=,args= |
    awk -v pane_pid="$pane_pid" -v script="bash ${repo_root}/scripts/worker-loop.sh ${lane} " '
      ($1 == pane_pid || $2 == pane_pid) && index($0, script) { found = 1 }
      END { exit found ? 0 : 1 }
    '
}

direct_loop_count() {
  local pane_pids
  pane_pids="$(
    tmux list-panes -a -F '#{session_name} #{pane_pid}' 2>/dev/null |
      awk -v session="$session" '$1 == session { print $2 }' |
      tr '\n' ' '
  )"
  ps -eo pid=,ppid=,args= |
    awk -v pane_pids="$pane_pids" -v script="bash ${repo_root}/scripts/worker-loop.sh" '
      BEGIN {
        split(pane_pids, ids)
        for (i in ids) {
          if (ids[i] != "") {
            pane[ids[i]] = 1
          }
        }
      }
      ($1 in pane || $2 in pane) && index($0, script) { count++ }
      END { print count + 0 }
    '
}

ensure_reporter() {
  if tmux has-session -t phpc-pages-reporter 2>/dev/null; then
    return 0
  fi
  tmux new-session -d -s phpc-pages-reporter -n reporter -c "$repo_root" \
    "PAGES_REPORT_INTERVAL=180 ./scripts/pages-reporter-loop.sh"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: started phpc-pages-reporter"
}

reap_nested_worker_loops() {
  local pids
  pids="$(
    ps -eo pid=,ppid=,args= |
      awk '/\/scripts\/worker-loop\.sh/ {
        pid=$1
        ppid=$2
        proc[pid]=1
        parent[pid]=ppid
      }
      END {
        for (pid in proc) {
          if (parent[pid] in proc) {
            print pid
          }
        }
      }'
  )"
  if [ -n "$pids" ]; then
    # These are nested worker loops spawned under an existing lane loop, not tmux pane roots.
    kill $pids 2>/dev/null || true
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: reaped nested worker loops: ${pids//$'\n'/ }"
  fi
}

while true; do
  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${session} missing; launch-swarm.sh must be run by supervisor"
    sleep "$interval"
    continue
  fi

  ensure_reporter
  reap_nested_worker_loops

  missing=0
  for lane in "${lanes[@]}"; do
    if ! tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | grep -Fxq "$lane"; then
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${lane} window missing"
      missing=$((missing + 1))
      continue
    fi
    if ! lane_has_direct_loop "$lane"; then
      respawn_lane "$lane"
    fi
  done

  windows="$(tmux list-windows -t "$session" 2>/dev/null | wc -l)"
  loops="$(direct_loop_count)"
  codex="$(pgrep -fc 'codex exec' || true)"
  slots="$(find /tmp/phpc-swarm-codex-slots -maxdepth 1 -type d -name '*.lock' 2>/dev/null | wc -l)"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: windows=${windows} worker_loops=${loops} codex_exec=${codex} slot_locks=${slots} missing_windows=${missing}"
  sleep "$interval"
done
