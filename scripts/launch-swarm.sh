#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
session="${1:-phpc-swarm}"
worktree_root="${WORKTREE_ROOT:-/home/ubuntu/phpc-worktrees}"
target_root="${TARGET_ROOT:-/home/ubuntu/phpc-targets}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-90}"
launch_stagger_seconds="${SWARM_LAUNCH_STAGGER_SECONDS:-0}"
start_watchdog_after_launch="${SWARM_START_WATCHDOG_AFTER_LAUNCH:-0}"
include_auditor="${SWARM_INCLUDE_AUDITOR:-1}"
auditor_first="${SWARM_AUDITOR_FIRST:-0}"

source "$repo_root/scripts/swarm-lanes.sh"
source "$repo_root/scripts/swarm-interactive.sh"
swarm_select_lanes

mkdir -p "$worktree_root" "$target_root" "$repo_root/swarm/worker-prompts" "$repo_root/swarm/handoffs"
rm -rf "${SWARM_SLOT_ROOT:-/tmp/phpc-swarm-codex-slots}"

if ! git -C "$repo_root" rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Repository needs an initial commit before launching worktrees." >&2
  exit 1
fi

if tmux has-session -t "=${session}" 2>/dev/null; then
  tmux kill-session -t "=${session}"
fi

tmux new-session -d -s "$session" -n supervisor -c "$repo_root"
tmux send-keys -t "=${session}:supervisor" "cd '$repo_root' && watch -n 10 'date -u; git status --short --branch; tmux list-windows -t =$session | tail -n +1 | wc -l; tail -n 20 progress.md'" C-m

tmux new-window -t "=${session}" -n dashboard -c "$repo_root"
tmux send-keys -t "=${session}:dashboard" "cd '$repo_root' && python3 -m http.server 8080 -d docs" C-m

stagger_before_next_codex_session() {
  local launched="$1"
  local total="$2"
  if [ "$launch_stagger_seconds" -gt 0 ] && [ "$launched" -lt "$total" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launch: waiting ${launch_stagger_seconds}s before starting Codex session $((launched + 1))/${total}."
    sleep "$launch_stagger_seconds"
  fi
}

make_prompt() {
  local lane="$1"
  local prompt="$repo_root/swarm/worker-prompts/${lane}.md"
  local group="${lane%%-*}"
  local milestone="Bootstrap"
  local task="Advance the compiler from scratch through the highest-value small tested slice for this lane."
  case "$group" in
    INT) milestone="Integration"; task="Improve integration safety, test gates, branch hygiene, or status accuracy without broad feature work." ;;
    ABI) milestone="M2 Runtime ABI"; task="Design and implement a small runtime ABI slice with ownership tests." ;;
    LINK) milestone="M3 Linked Native Execution"; task="Move the compiler toward producing, linking, running, and comparing native executables." ;;
    LOW) milestone="M4 Native Lowering"; task="Implement a focused parser/interpreter/lowering slice with fixtures and explicit unsupported diagnostics." ;;
    PHPT) milestone="M5 PHP Core Harness"; task="Build php-src .phpt inventory, parsing, execution, normalization, sharding, or failure minimization." ;;
    WP) milestone="M6 WordPress Harness"; task="Pin WordPress, inventory entrypoints, build bootstrap harnesses, or minimize blockers into general PHP fixtures." ;;
    SEM) milestone="M1/M7 Semantics"; task="Advance COW/reference/object mechanisms from general semantics, not case-by-case hacks." ;;
    SAPI) milestone="M7 SAPI"; task="Advance request, superglobal, header, stream, filesystem, or session semantics with tests." ;;
    MINE) milestone="Defect Mining"; task="Find, classify, and minimize high-value PHP/compiler defects without implementing broad fixes." ;;
    DOC) milestone="Coordination"; task="Keep progress, dashboard, manifests, docs, and operator runbooks truthful and current." ;;
  esac
  cat > "$prompt" <<PROMPT
You are worker ${lane} in the PHP-to-native compiler swarm.

Repository/worktree: ${worktree_root}/${lane}
Branch: lane/${lane}
Milestone: ${milestone}
CARGO_TARGET_DIR: ${target_root}/${lane}
Handoff: swarm/handoffs/${lane}.md

Task:
${task}

Read first:
- goal.md
- prompt.md
- progress.md
- AGENTS.md
- swarm/queue.md
- docs/ARCHITECTURE.md
- docs/SUPPORT.md
- docs/NATIVE_RUNTIME_ABI.md
- docs/WORDPRESS_COMPATIBILITY.md

Rules:
- If your worktree is already dirty from an earlier slice, first inspect it and either finish/commit the coherent slice or write a precise handoff/blocker before starting unrelated work.
- Keep the work mapped to the named milestone.
- Make a small, reviewable change or produce a precise blocker/research artifact.
- Add or update focused tests when changing implementation behavior.
- Do not run destructive git commands.
- Do not revert unrelated work.
- Do not count generated fixtures, wrappers, bridge calls, shell-outs, or probes as native implementation progress.
- Do not add WordPress-specific hacks.
- Use the unique CARGO_TARGET_DIR above.
- Run relevant focused verification if tools are available.
- Commit only inside your lane branch when you have a coherent slice.

Before ending a slice, write swarm/handoffs/${lane}.md with:
- summary;
- files changed;
- tests run;
- pass/fail state;
- blockers;
- latest commit if any;
- next suggested slice.

If the queue item is too broad, choose the smallest useful tested slice and record the narrower denominator.
PROMPT
}

case "$include_auditor" in
  0|1) ;;
  *) echo "SWARM_INCLUDE_AUDITOR must be 0 or 1." >&2; exit 1 ;;
esac
case "$auditor_first" in
  0|1) ;;
  *) echo "SWARM_AUDITOR_FIRST must be 0 or 1." >&2; exit 1 ;;
esac

total_codex_sessions="$((${#lanes[@]} + include_auditor))"
launched_codex_sessions="0"

if [ "$include_auditor" = "1" ] && [ "$auditor_first" = "1" ]; then
aud_prompt="$repo_root/swarm/worker-prompts/AUD-01.md"
cat > "$aud_prompt" <<PROMPT
You are AUD-01, the independent auditor for the PHP-to-native compiler swarm.

Every cycle, inspect progress.md, docs/progress.html, swarm/queue.md, swarm/agents.md, swarm/handoffs, git status, and current evidence.

Write swarm/audit.md with:
- what is going right;
- what is going wrong;
- idle/stuck/duplicated/drifting lanes;
- weak progress claims;
- missing tests;
- next integration target;
- single best supervisor intervention.

Do not implement compiler features. Challenge quality and keep the roadmap honest.
PROMPT

aud_worktree="${worktree_root}/AUD-01"
if [ ! -e "$aud_worktree/.git" ]; then
  git -C "$repo_root" worktree add -B "lane/AUD-01" "$aud_worktree" HEAD >/dev/null
else
  git -C "$aud_worktree" merge --ff-only main >/dev/null || true
fi
tmux new-window -t "=${session}" -n AUD-01 -c "$aud_worktree"
tmux send-keys -t "=${session}:AUD-01" "$(swarm_codex_command "$repo_root" "$target_root" AUD-01 "$aud_worktree")" C-m
swarm_paste_prompt "$session" AUD-01 "$aud_prompt" &
launched_codex_sessions="$((launched_codex_sessions + 1))"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launch: started Codex session ${launched_codex_sessions}/${total_codex_sessions} (AUD-01)."
fi

for lane in "${lanes[@]}"; do
  worktree="${worktree_root}/${lane}"
  prompt="$repo_root/swarm/worker-prompts/${lane}.md"
  make_prompt "$lane"
  if [ ! -e "$worktree/.git" ]; then
    git -C "$repo_root" worktree add -B "lane/${lane}" "$worktree" HEAD >/dev/null
  else
    git -C "$worktree" merge --ff-only main >/dev/null || true
  fi
  mkdir -p "${target_root}/${lane}"
  tmux new-window -t "=${session}" -n "$lane" -c "$worktree"
  tmux send-keys -t "=${session}:$lane" "$(swarm_codex_command "$repo_root" "$target_root" "$lane" "$worktree")" C-m
  swarm_paste_prompt "$session" "$lane" "$prompt" &
  launched_codex_sessions="$((launched_codex_sessions + 1))"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launch: started Codex session ${launched_codex_sessions}/${total_codex_sessions} (${lane})."
  stagger_before_next_codex_session "$launched_codex_sessions" "$total_codex_sessions"
done

if [ "$include_auditor" = "1" ] && [ "$auditor_first" = "0" ]; then
aud_prompt="$repo_root/swarm/worker-prompts/AUD-01.md"
cat > "$aud_prompt" <<PROMPT
You are AUD-01, the independent auditor for the PHP-to-native compiler swarm.

Every cycle, inspect progress.md, docs/progress.html, swarm/queue.md, swarm/agents.md, swarm/handoffs, git status, and current evidence.

Write swarm/audit.md with:
- what is going right;
- what is going wrong;
- idle/stuck/duplicated/drifting lanes;
- weak progress claims;
- missing tests;
- next integration target;
- single best supervisor intervention.

Do not implement compiler features. Challenge quality and keep the roadmap honest.
PROMPT

aud_worktree="${worktree_root}/AUD-01"
if [ ! -e "$aud_worktree/.git" ]; then
  git -C "$repo_root" worktree add -B "lane/AUD-01" "$aud_worktree" HEAD >/dev/null
else
  git -C "$aud_worktree" merge --ff-only main >/dev/null || true
fi
tmux new-window -t "=${session}" -n AUD-01 -c "$aud_worktree"
tmux send-keys -t "=${session}:AUD-01" "$(swarm_codex_command "$repo_root" "$target_root" AUD-01 "$aud_worktree")" C-m
swarm_paste_prompt "$session" AUD-01 "$aud_prompt" &
launched_codex_sessions="$((launched_codex_sessions + 1))"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) launch: started Codex session ${launched_codex_sessions}/${total_codex_sessions} (AUD-01)."
fi

wait
if [ "$start_watchdog_after_launch" = "1" ]; then
  if tmux has-session -t =phpc-swarm-watchdog 2>/dev/null; then
    tmux kill-session -t =phpc-swarm-watchdog
  fi
  tmux new-session -d -s phpc-swarm-watchdog -n watchdog -c "$repo_root" \
    "SWARM_WORKER_COUNT=${#lanes[@]} SWARM_INTERACTIVE_PROMPT_DELAY=${SWARM_INTERACTIVE_PROMPT_DELAY:-8} ./scripts/swarm-watchdog.sh ${session}"
fi
if [ "$include_auditor" = "1" ]; then
  echo "Launched ${#lanes[@]} interactive workers plus auditor in tmux session ${session}."
else
  echo "Launched ${#lanes[@]} interactive workers in tmux session ${session}."
fi
