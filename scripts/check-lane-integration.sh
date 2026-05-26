#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: scripts/check-lane-integration.sh <lane-branch-or-commit> [main-ref]

Classifies a lane candidate against main without changing refs or the worktree.
Default main-ref is origin/main.
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

target_input="$1"
main_ref="${2:-origin/main}"

resolve_ref() {
  local input="$1"
  local direct_commit=""
  local lane_commit=""

  direct_commit="$(git rev-parse --verify --quiet "${input}^{commit}" || true)"
  lane_commit="$(git rev-parse --verify --quiet "lane/${input}^{commit}" || true)"

  if [[ -n "$direct_commit" && -n "$lane_commit" && "$direct_commit" != "$lane_commit" ]]; then
    echo "lane integration check: ambiguous target ref: ${input} matches both ${input} and lane/${input}" >&2
    echo "lane integration check: use an explicit ref such as lane/${input}" >&2
    return 2
  fi
  if [[ -n "$direct_commit" ]]; then
    printf '%s\n' "$input"
    return 0
  fi
  if [[ -n "$lane_commit" ]]; then
    printf '%s\n' "lane/${input}"
    return 0
  fi
  return 1
}

if ! git rev-parse --verify --quiet "${main_ref}^{commit}" >/dev/null; then
  echo "lane integration check: main ref not found: ${main_ref}" >&2
  exit 2
fi

target_ref_status=0
target_ref="$(resolve_ref "$target_input")" || target_ref_status=$?
if [[ "$target_ref_status" -ne 0 ]]; then
  if [[ "$target_ref_status" -eq 2 ]]; then
    exit 2
  fi
  echo "lane integration check: target ref not found: ${target_input}" >&2
  exit 2
fi

main_commit="$(git rev-parse "${main_ref}^{commit}")"
target_commit="$(git rev-parse "${target_ref}^{commit}")"
target_full_ref="$(git rev-parse --symbolic-full-name --quiet "$target_ref" || true)"
if [[ "$main_ref" == "$target_ref" ]]; then
  echo "lane integration check: main ref and target ref are identical: ${main_ref}" >&2
  echo "lane integration check: use the current integration base, usually origin/main, as main-ref" >&2
  exit 2
fi
if ! merge_base="$(git merge-base "$main_commit" "$target_commit")"; then
  echo "main: ${main_ref} $(git rev-parse --short "$main_commit")"
  echo "target: ${target_ref} $(git rev-parse --short "$target_commit")"
  echo "merge-base: none"
  echo "classification: unsafe-to-merge"
  echo "action: request a rebase or manual integration; target does not share history with main."
  exit 1
fi

lane_name="$target_input"
case "$target_ref" in
  lane/*) lane_name="${target_ref#lane/}" ;;
esac
handoff="swarm/handoffs/${lane_name}.md"
if [[ ! -f "$handoff" && "$lane_name" =~ ^([A-Z]+-[0-9]+)- ]]; then
  base_handoff="swarm/handoffs/${BASH_REMATCH[1]}.md"
  if [[ -f "$base_handoff" ]]; then
    handoff="$base_handoff"
  fi
fi

echo "main: ${main_ref} $(git rev-parse --short "$main_commit")"
echo "target: ${target_ref} $(git rev-parse --short "$target_commit")"
echo "merge-base: $(git rev-parse --short "$merge_base")"

if [[ -f "$handoff" ]]; then
  echo "handoff: present ${handoff}"
else
  echo "handoff: missing ${handoff}"
fi

if git merge-base --is-ancestor "$target_commit" "$main_commit"; then
  echo "classification: already-integrated"
  echo "action: do not merge; record the lane as integrated or stale against current main."
  exit 0
fi

if git diff --quiet "$main_commit" "$target_commit"; then
  echo "classification: no-net-diff"
  echo "action: do not merge; the target tree matches main even though commit history differs."
  exit 0
fi

current_worktree=""
current_branch=""
current_head=""
while IFS= read -r line; do
  if [[ "$line" == worktree\ * ]]; then
    current_worktree="${line#worktree }"
    current_branch=""
    current_head=""
    continue
  fi
  if [[ "$line" == HEAD\ * ]]; then
    current_head="${line#HEAD }"
    continue
  fi
  if [[ "$line" == branch\ * ]]; then
    current_branch="${line#branch }"
    if [[ -n "$(git -C "$current_worktree" status --porcelain)" ]] &&
      { [[ "$current_branch" == "$target_full_ref" ]] || [[ "$current_head" == "$target_commit" ]]; }; then
      echo "worktree: dirty ${current_worktree}"
      echo "classification: unsafe-to-merge"
      echo "action: finish, commit, or hand off dirty work in the checked-out lane worktree before integration."
      exit 1
    fi
  fi
done < <(git worktree list --porcelain)

cherry_output="$(git cherry "$main_commit" "$target_commit")"
plus_count="$(printf '%s\n' "$cherry_output" | grep -c '^+' || true)"
minus_count="$(printf '%s\n' "$cherry_output" | grep -c '^-' || true)"

if [[ "$plus_count" -eq 0 && "$minus_count" -gt 0 ]]; then
  echo "classification: stale-equivalent"
  echo "action: do not merge; the patch-id already exists on main under different commit ids."
  exit 0
fi

if [[ "$merge_base" != "$main_commit" ]]; then
  echo "base: stale"
else
  echo "base: current"
fi

if [[ "$plus_count" -gt 0 ]]; then
  echo "unique-commits: ${plus_count}"
fi
if [[ "$minus_count" -gt 0 ]]; then
  echo "equivalent-commits: ${minus_count}"
fi

merge_tree="$(git merge-tree "$merge_base" "$main_commit" "$target_commit")"
if printf '%s\n' "$merge_tree" | grep -Eq '^(<<<<<<<|CONFLICT\b|changed in both|added in both)'; then
  echo "classification: unsafe-to-merge"
  echo "action: request a rebase or manual integration; merge-tree reports conflicts."
  exit 1
fi

if [[ -f "$handoff" ]]; then
  echo "classification: review-required"
  echo "action: inspect the diff and handoff, then run focused tests before merging."
else
  echo "classification: review-required-missing-handoff"
  echo "action: require a lane handoff before merging unless this is a documented research-only artifact."
  exit 1
fi
