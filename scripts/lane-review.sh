#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/lane-review.sh [--base <ref>] [--repo <path>]

Print a read-only integration review summary for a lane worktree.

Defaults:
  --repo  current directory
  --base  origin/main when present, otherwise main
EOF
}

repo="."
base=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      if [ "$#" -lt 2 ]; then
        echo "error: --base requires a ref" >&2
        exit 2
      fi
      base="$2"
      shift 2
      ;;
    --repo)
      if [ "$#" -lt 2 ]; then
        echo "error: --repo requires a path" >&2
        exit 2
      fi
      repo="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

git_in_repo() {
  git -C "$repo" "$@"
}

if ! git_in_repo rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not a git worktree: $repo" >&2
  exit 2
fi

if [ -z "$base" ]; then
  if git_in_repo rev-parse --verify --quiet origin/main >/dev/null; then
    base="origin/main"
  else
    base="main"
  fi
fi

if ! git_in_repo rev-parse --verify --quiet "$base" >/dev/null; then
  echo "error: base ref not found: $base" >&2
  exit 2
fi

branch="$(git_in_repo branch --show-current)"
if [ -z "$branch" ]; then
  branch="(detached)"
fi
head_short="$(git_in_repo rev-parse --short HEAD)"
head_full="$(git_in_repo rev-parse HEAD)"
base_short="$(git_in_repo rev-parse --short "$base")"
merge_base="$(git_in_repo merge-base HEAD "$base")"
merge_base_short="$(git_in_repo rev-parse --short "$merge_base")"
ahead="$(git_in_repo rev-list --count "${merge_base}..HEAD")"
behind="$(git_in_repo rev-list --count "${merge_base}..${base}")"

porcelain="$(git_in_repo status --porcelain=v1)"
dirty_count=0
untracked_count=0
if [ -n "$porcelain" ]; then
  dirty_count="$(printf '%s\n' "$porcelain" | wc -l | tr -d ' ')"
  untracked_count="$(printf '%s\n' "$porcelain" | awk 'substr($0, 1, 2) == "??" { count++ } END { print count + 0 }')"
fi

upstream="$(git_in_repo rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
if [ -z "$upstream" ]; then
  upstream="(none)"
fi

echo "lane review"
echo "repo: $(git_in_repo rev-parse --show-toplevel)"
echo "branch: $branch"
echo "head: $head_short $head_full"
echo "upstream: $upstream"
echo "base: $base $base_short"
echo "merge-base: $merge_base_short"
echo "divergence: ahead $ahead, behind $behind"
echo "dirty entries: $dirty_count"
echo "untracked entries: $untracked_count"

if [ "$dirty_count" -gt 0 ]; then
  echo "dirty files:"
  printf '%s\n' "$porcelain" | sed 's/^/  /'
fi
