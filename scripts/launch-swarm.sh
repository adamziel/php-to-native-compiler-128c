#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
session="${1:-phpc-swarm}"
worktree_root="${WORKTREE_ROOT:-/home/ubuntu/phpc-worktrees}"
target_root="${TARGET_ROOT:-/home/ubuntu/phpc-targets}"
max_active_codex="${SWARM_MAX_ACTIVE_CODEX:-50}"
initial_stagger_max="${SWARM_INITIAL_STAGGER_MAX:-90}"

mkdir -p "$worktree_root" "$target_root" "$repo_root/swarm/worker-prompts" "$repo_root/swarm/handoffs"
rm -rf "${SWARM_SLOT_ROOT:-/tmp/phpc-swarm-codex-slots}"

if ! git -C "$repo_root" rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Repository needs an initial commit before launching worktrees." >&2
  exit 1
fi

if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

tmux new-session -d -s "$session" -n supervisor -c "$repo_root"
tmux send-keys -t "$session:supervisor" "cd '$repo_root' && watch -n 10 'date -u; git status --short --branch; tmux list-windows -t $session | tail -n +1 | wc -l; tail -n 20 progress.md'" C-m

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
)

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
  tmux new-window -t "$session" -n "$lane" -c "$worktree"
  effort="low"
  case "${lane%%-*}" in
    ABI|LINK|SEM|SAPI) effort="medium" ;;
  esac
  tmux send-keys -t "$session:$lane" "export CARGO_TARGET_DIR='${target_root}/${lane}' CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 SWARM_MAX_ACTIVE_CODEX='${max_active_codex}' SWARM_INITIAL_STAGGER_MAX='${initial_stagger_max}' CODEX_SERVICE_TIER='fast' CODEX_MODEL='gpt-5.5' CODEX_REASONING_EFFORT='${effort}'; '$repo_root/scripts/worker-loop.sh' '$lane' '$worktree' '$prompt'" C-m
done

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
tmux new-window -t "$session" -n AUD-01 -c "$aud_worktree"
tmux send-keys -t "$session:AUD-01" "export CARGO_TARGET_DIR='${target_root}/AUD-01' SWARM_MAX_ACTIVE_CODEX='${max_active_codex}' SWARM_INITIAL_STAGGER_MAX='${initial_stagger_max}' CODEX_SERVICE_TIER='fast' CODEX_MODEL='gpt-5.5' CODEX_REASONING_EFFORT='medium'; '$repo_root/scripts/worker-loop.sh' AUD-01 '$aud_worktree' '$aud_prompt'" C-m

tmux new-window -t "$session" -n dashboard -c "$repo_root"
tmux send-keys -t "$session:dashboard" "cd '$repo_root' && python3 -m http.server 8080 -d docs" C-m

echo "Launched ${#lanes[@]} workers plus auditor in tmux session ${session}."
