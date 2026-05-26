#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

scripts/lane-review.sh --help >"$tmpdir/help.out"
grep -F "Usage: scripts/lane-review.sh" "$tmpdir/help.out" >/dev/null
grep -F "Print a read-only integration review summary" "$tmpdir/help.out" >/dev/null

before_status="$(git status --porcelain=v1)"
scripts/lane-review.sh --base HEAD >"$tmpdir/review.out"
after_status="$(git status --porcelain=v1)"

if [ "$before_status" != "$after_status" ]; then
  echo "lane-review.sh mutated worktree status" >&2
  diff -u <(printf '%s\n' "$before_status") <(printf '%s\n' "$after_status") >&2 || true
  exit 1
fi

for expected in \
  "lane review" \
  "repo: $repo_root" \
  "branch:" \
  "head:" \
  "upstream:" \
  "base: HEAD" \
  "merge-base:" \
  "divergence: ahead 0, behind 0" \
  "dirty entries:" \
  "untracked entries:"
do
  if ! grep -F "$expected" "$tmpdir/review.out" >/dev/null; then
    echo "lane-review.sh output missing expected field: $expected" >&2
    cat "$tmpdir/review.out" >&2
    exit 1
  fi
done

if scripts/lane-review.sh --base refs/heads/definitely-missing-lane-review-base >"$tmpdir/missing.out" 2>"$tmpdir/missing.err"; then
  echo "lane-review.sh accepted a missing base ref" >&2
  exit 1
fi
grep -F "base ref not found" "$tmpdir/missing.err" >/dev/null

fixture_repo="$tmpdir/diverged-lane"
git init -q "$fixture_repo"
git -C "$fixture_repo" config user.email test@example.invalid
git -C "$fixture_repo" config user.name "Integration Test"
printf 'root\n' >"$fixture_repo/file.txt"
git -C "$fixture_repo" add file.txt
git -C "$fixture_repo" commit -q -m root
git -C "$fixture_repo" branch integration-base
git -C "$fixture_repo" switch -q -c lane-under-review
printf 'lane\n' >>"$fixture_repo/file.txt"
git -C "$fixture_repo" commit -q -am lane
git -C "$fixture_repo" switch -q integration-base
printf 'base\n' >>"$fixture_repo/file.txt"
git -C "$fixture_repo" commit -q -am base
git -C "$fixture_repo" switch -q lane-under-review

scripts/lane-review.sh --repo "$fixture_repo" --base integration-base >"$tmpdir/diverged.out"
for expected in \
  "repo: $fixture_repo" \
  "branch: lane-under-review" \
  "base: integration-base" \
  "divergence: ahead 1, behind 1" \
  "dirty entries: 0" \
  "untracked entries: 0"
do
  if ! grep -F "$expected" "$tmpdir/diverged.out" >/dev/null; then
    echo "lane-review.sh output missing expected diverged fixture field: $expected" >&2
    cat "$tmpdir/diverged.out" >&2
    exit 1
  fi
done

detached_head="$(git -C "$fixture_repo" rev-parse HEAD)"
git -C "$fixture_repo" switch -q --detach "$detached_head"

scripts/lane-review.sh --repo "$fixture_repo" --base HEAD >"$tmpdir/detached.out"
for expected in \
  "repo: $fixture_repo" \
  "branch: (detached)" \
  "base: HEAD" \
  "divergence: ahead 0, behind 0" \
  "dirty entries: 0" \
  "untracked entries: 0"
do
  if ! grep -F "$expected" "$tmpdir/detached.out" >/dev/null; then
    echo "lane-review.sh output missing expected detached fixture field: $expected" >&2
    cat "$tmpdir/detached.out" >&2
    exit 1
  fi
done
