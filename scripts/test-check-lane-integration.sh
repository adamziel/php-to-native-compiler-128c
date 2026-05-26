#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git init -q "$tmpdir/repo"
mkdir -p "$tmpdir/repo/scripts"
cp scripts/check-lane-integration.sh "$tmpdir/repo/scripts/check-lane-integration.sh"
cp scripts/check-lanes-integration.sh "$tmpdir/repo/scripts/check-lanes-integration.sh"
cd "$tmpdir/repo"

git config user.email test@example.invalid
git config user.name "Integration Test"
mkdir -p swarm/handoffs

printf 'base\n' > file.txt
git add file.txt
git commit -q -m base
git branch main

git switch -q -c lane/integrated main
printf 'integrated\n' >> file.txt
git commit -q -am integrated
git switch -q main
git merge -q --ff-only lane/integrated

scripts/check-lane-integration.sh lane/integrated main > integrated.out
grep -F "classification: already-integrated" integrated.out >/dev/null

git switch -q -c lane/stale-equivalent HEAD~1
printf 'equivalent\n' > equivalent.txt
git add equivalent.txt
git commit -q -m equivalent-lane
git switch -q main
printf 'equivalent\n' > equivalent.txt
git add equivalent.txt
git commit -q -m equivalent-main

scripts/check-lane-integration.sh lane/stale-equivalent main > stale.out
grep -F "classification: stale-equivalent" stale.out >/dev/null

git switch -q -c lane/no-net-diff main
git commit -q --allow-empty -m no-net-diff
scripts/check-lane-integration.sh lane/no-net-diff main > no-net-diff.out
grep -F "classification: no-net-diff" no-net-diff.out >/dev/null

git switch -q -c lane/conflict HEAD~1
printf 'lane-conflict\n' > file.txt
git commit -q -am lane-conflict
git switch -q main
printf 'main-conflict\n' > file.txt
git commit -q -am main-conflict

if scripts/check-lane-integration.sh lane/conflict main > conflict.out 2> conflict.err; then
  echo "check-lane-integration.sh accepted a conflicting lane" >&2
  cat conflict.out >&2
  cat conflict.err >&2
  exit 1
fi
grep -F "classification: unsafe-to-merge" conflict.out >/dev/null

git switch -q -c lane/review main
printf 'review\n' > review.txt
git add review.txt
git commit -q -m review
printf '# handoff\n' > swarm/handoffs/review.md

scripts/check-lane-integration.sh lane/review main > review.out
grep -F "handoff: present swarm/handoffs/review.md" review.out >/dev/null
grep -F "classification: review-required" review.out >/dev/null

git switch -q -c lane/INT-02-fresh-0409 main
printf 'fresh\n' > fresh.txt
git add fresh.txt
git commit -q -m fresh
printf '# base worker handoff\n' > swarm/handoffs/INT-02.md

scripts/check-lane-integration.sh lane/INT-02-fresh-0409 main > fresh.out
grep -F "handoff: present swarm/handoffs/INT-02.md" fresh.out >/dev/null
grep -F "classification: review-required" fresh.out >/dev/null

git switch -q -c lane/missing-handoff main
printf 'missing handoff\n' > missing-handoff.txt
git add missing-handoff.txt
git commit -q -m missing-handoff

if scripts/check-lane-integration.sh lane/missing-handoff main > missing-handoff.out 2> missing-handoff.err; then
  echo "check-lane-integration.sh accepted a review lane without a handoff" >&2
  cat missing-handoff.out >&2
  cat missing-handoff.err >&2
  exit 1
fi
grep -F "handoff: missing swarm/handoffs/missing-handoff.md" missing-handoff.out >/dev/null
grep -F "classification: review-required-missing-handoff" missing-handoff.out >/dev/null

if scripts/check-lanes-integration.sh --main-ref main lane/review lane/missing-handoff > batch.out 2> batch.err; then
  echo "check-lanes-integration.sh accepted a batch with a missing handoff" >&2
  cat batch.out >&2
  cat batch.err >&2
  exit 1
fi
grep -F "== lane/review ==" batch.out >/dev/null
grep -F "classification: review-required" batch.out >/dev/null
grep -F "== lane/missing-handoff ==" batch.out >/dev/null
grep -F "classification: review-required-missing-handoff" batch.out >/dev/null
grep -F "summary: passed=1 failed=1 total=2" batch.out >/dev/null

scripts/check-lanes-integration.sh --main-ref main lane/integrated lane/stale-equivalent > batch-safe.out
grep -F "== lane/integrated ==" batch-safe.out >/dev/null
grep -F "classification: already-integrated" batch-safe.out >/dev/null
grep -F "== lane/stale-equivalent ==" batch-safe.out >/dev/null
grep -F "classification: stale-equivalent" batch-safe.out >/dev/null
grep -F "summary: passed=2 failed=0 total=2" batch-safe.out >/dev/null
