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
  if git rev-parse --verify --quiet "${input}^{commit}" >/dev/null; then
    printf '%s\n' "$input"
    return
  fi
  if git rev-parse --verify --quiet "lane/${input}^{commit}" >/dev/null; then
    printf '%s\n' "lane/${input}"
    return
  fi
  return 1
}

if ! git rev-parse --verify --quiet "${main_ref}^{commit}" >/dev/null; then
  echo "lane integration check: main ref not found: ${main_ref}" >&2
  exit 2
fi

if ! target_ref="$(resolve_ref "$target_input")"; then
  echo "lane integration check: target ref not found: ${target_input}" >&2
  exit 2
fi

main_commit="$(git rev-parse "${main_ref}^{commit}")"
target_commit="$(git rev-parse "${target_ref}^{commit}")"
merge_base="$(git merge-base "$main_commit" "$target_commit")"

lane_name="$target_input"
case "$target_ref" in
  lane/*) lane_name="${target_ref#lane/}" ;;
esac
handoff="swarm/handoffs/${lane_name}.md"

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
fi
