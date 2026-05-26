#!/usr/bin/env bash

swarm_lane_effort() {
  case "${1%%-*}" in
    ABI|LINK|SEM|SAPI|AUD) printf 'medium' ;;
    *) printf 'low' ;;
  esac
}

swarm_codex_command() {
  local repo_root="$1"
  local target_root="$2"
  local lane="$3"
  local worktree="$4"
  local effort
  effort="$(swarm_lane_effort "$lane")"

  printf "export CARGO_TARGET_DIR='%s/%s' CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 PHPC_REQUIRE_WORKER_ENV=1 PHPC_WORKTREE_ROOT='%s' PHPC_TARGET_ROOT='%s' PHPC_LANE_ID='%s' PHPC_EXPECT_BRANCH='lane/%s' CODEX_SERVICE_TIER='fast' CODEX_MODEL='gpt-5.5' CODEX_REASONING_EFFORT='%s'; codex --cd '%s' --model 'gpt-5.5' --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'service_tier=\"fast\"' -c 'model_reasoning_effort=\"%s\"'" \
    "$target_root" "$lane" "$worktree" "$target_root" "$lane" "$lane" "$effort" "$worktree" "$effort"
}

swarm_paste_prompt() {
  local session="$1"
  local lane="$2"
  local prompt="$3"
  local delay="${SWARM_INTERACTIVE_PROMPT_DELAY:-5}"

  sleep "$delay"
  tmux load-buffer -b "prompt-${lane}" "$prompt"
  tmux paste-buffer -t "=${session}:${lane}" -b "prompt-${lane}"
  sleep 1
  tmux send-keys -t "=${session}:${lane}" C-m
  sleep 1
  tmux send-keys -t "=${session}:${lane}" C-m
}

swarm_pane_has_interactive_codex() {
  local session="$1"
  local lane="$2"
  local pane_pid
  pane_pid="$(tmux list-panes -t "=${session}:${lane}" -F '#{pane_pid}' 2>/dev/null | head -n 1 || true)"
  if [ -z "$pane_pid" ]; then
    return 1
  fi

  ps -eo pid=,ppid=,args= |
    awk -v pane_pid="$pane_pid" '
      ($1 == pane_pid || $2 == pane_pid) &&
      index($0, "codex") &&
      index($0, "codex exec") == 0 { found = 1 }
      END { exit found ? 0 : 1 }
    '
}

swarm_interactive_codex_count() {
  local session="$1"
  local pane_pids
  pane_pids="$(
    tmux list-panes -a -F '#{session_name} #{pane_pid}' 2>/dev/null |
      awk -v session="$session" '$1 == session { print $2 }' |
      tr '\n' ' '
  )"
  ps -eo pid=,ppid=,args= |
    awk -v pane_pids="$pane_pids" '
      BEGIN {
        split(pane_pids, ids)
        for (i in ids) {
          if (ids[i] != "") {
            pane[ids[i]] = 1
          }
        }
      }
      ($1 in pane || $2 in pane) &&
      index($0, "codex") &&
      index($0, "codex exec") == 0 { count++ }
      END { print count + 0 }
    '
}

swarm_codex_exec_count() {
  ps -eo args= |
    awk '
      index($0, "codex exec") &&
      index($0, "pgrep") == 0 &&
      index($0, "awk") == 0 { count++ }
      END { print count + 0 }
    '
}
