#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
session="${SWARM_SESSION:-phpc-swarm}"
worktree_root="${WORKTREE_ROOT:-/home/ubuntu/phpc-worktrees}"
target_root="${TARGET_ROOT:-/home/ubuntu/phpc-targets}"
interval="${SWARM_WATCHDOG_INTERVAL:-60}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-0}"
include_auditor="${SWARM_INCLUDE_AUDITOR:-1}"
existing_only="${SWARM_WATCHDOG_EXISTING_ONLY:-0}"

source "$repo_root/scripts/swarm-lanes.sh"
source "$repo_root/scripts/swarm-interactive.sh"
swarm_select_lanes

case "$include_auditor" in
  0|1) ;;
  *) echo "SWARM_INCLUDE_AUDITOR must be 0 or 1." >&2; exit 1 ;;
esac
case "$existing_only" in
  0|1) ;;
  *) echo "SWARM_WATCHDOG_EXISTING_ONLY must be 0 or 1." >&2; exit 1 ;;
esac

if [ "$include_auditor" = "1" ]; then
  lanes+=(AUD-01)
fi

respawn_lane() {
  local lane="$1"
  local worktree="${worktree_root}/${lane}"
  local prompt="${repo_root}/swarm/worker-prompts/${lane}.md"
  if [ ! -e "${worktree}/.git" ] || [ ! -f "$prompt" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: cannot respawn ${lane}; missing worktree or prompt"
    return 0
  fi

  mkdir -p "${target_root}/${lane}"
  tmux respawn-pane -k -t "=${session}:${lane}" -c "$worktree" \
    "$(swarm_codex_command "$repo_root" "$target_root" "$lane" "$worktree")"
  swarm_paste_prompt "$session" "$lane" "$prompt" &
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: respawned interactive ${lane}"
}

ensure_reporter() {
  if tmux has-session -t =phpc-pages-reporter 2>/dev/null; then
    return 0
  fi
  tmux new-session -d -s phpc-pages-reporter -n reporter -c "$repo_root" \
    "PAGES_REPORT_INTERVAL=180 ./scripts/pages-reporter-loop.sh"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: started phpc-pages-reporter"
}

while true; do
  if ! tmux has-session -t "=${session}" 2>/dev/null; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${session} missing; launch-swarm.sh must be run by supervisor"
    sleep "$interval"
    continue
  fi

  ensure_reporter

  missing=0
  window_names="$(tmux list-windows -t "=${session}" -F '#{window_name}' 2>/dev/null || true)"
  for lane in "${lanes[@]}"; do
    if ! printf '%s\n' "$window_names" | grep -Fxq "$lane"; then
      if [ "$existing_only" = "1" ]; then
        continue
      fi
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: ${lane} window missing"
      missing=$((missing + 1))
      continue
    fi
    if ! swarm_pane_has_interactive_codex "$session" "$lane"; then
      respawn_lane "$lane"
    fi
  done

  windows="$(tmux list-windows -t "=${session}" 2>/dev/null | wc -l)"
  codex="$(swarm_interactive_codex_count "$session")"
  execs="$(swarm_codex_exec_count)"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) watchdog: windows=${windows} interactive_codex=${codex} codex_exec=${execs} missing_windows=${missing}"
  sleep "$interval"
done
