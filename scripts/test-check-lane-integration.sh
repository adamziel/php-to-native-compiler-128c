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
git switch -q main
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

git switch -q --orphan unrelated
git rm -q -r --ignore-unmatch .
printf 'unrelated\n' > unrelated.txt
git add unrelated.txt
git commit -q -m unrelated
git branch lane/unrelated-history
git switch -q main

if scripts/check-lane-integration.sh lane/unrelated-history main > unrelated.out 2> unrelated.err; then
  echo "check-lane-integration.sh accepted a lane with unrelated history" >&2
  cat unrelated.out >&2
  cat unrelated.err >&2
  exit 1
fi
grep -F "merge-base: none" unrelated.out >/dev/null
grep -F "classification: unsafe-to-merge" unrelated.out >/dev/null
grep -F "target does not share history with main" unrelated.out >/dev/null

git switch -q -c lane/review main
printf 'review\n' > review.txt
git add review.txt
git commit -q -m review
printf '# handoff\n' > swarm/handoffs/review.md

git switch -q main
scripts/check-lane-integration.sh lane/review main > review.out
grep -F "handoff: present swarm/handoffs/review.md" review.out >/dev/null
grep -F "classification: review-required" review.out >/dev/null

printf '# dirty handoff\n' > swarm/handoffs/dirty.md
git worktree add -q -b lane/dirty "$tmpdir/dirty-worktree" main
printf 'dirty committed\n' > "$tmpdir/dirty-worktree/dirty.txt"
git -C "$tmpdir/dirty-worktree" add dirty.txt
git -C "$tmpdir/dirty-worktree" commit -q -m dirty-committed
printf 'uncommitted\n' >> "$tmpdir/dirty-worktree/dirty.txt"

if scripts/check-lane-integration.sh lane/dirty main > dirty-worktree.out 2> dirty-worktree.err; then
  echo "check-lane-integration.sh accepted a checked-out dirty lane worktree" >&2
  cat dirty-worktree.out >&2
  cat dirty-worktree.err >&2
  exit 1
fi
grep -F "worktree: dirty $tmpdir/dirty-worktree" dirty-worktree.out >/dev/null
grep -F "classification: unsafe-to-merge" dirty-worktree.out >/dev/null
grep -F "finish, commit, or hand off dirty work" dirty-worktree.out >/dev/null

dirty_commit="$(git -C "$tmpdir/dirty-worktree" rev-parse HEAD)"
if scripts/check-lane-integration.sh "$dirty_commit" main > dirty-commit.out 2> dirty-commit.err; then
  echo "check-lane-integration.sh accepted a raw commit checked out in a dirty lane worktree" >&2
  cat dirty-commit.out >&2
  cat dirty-commit.err >&2
  exit 1
fi
grep -F "worktree: dirty $tmpdir/dirty-worktree" dirty-commit.out >/dev/null
grep -F "classification: unsafe-to-merge" dirty-commit.out >/dev/null
grep -F "finish, commit, or hand off dirty work" dirty-commit.out >/dev/null

set +e
scripts/check-lane-integration.sh lane/review lane/review > same-ref.out 2> same-ref.err
same_ref_status=$?
set -e
if [[ "$same_ref_status" -ne 2 ]]; then
  echo "check-lane-integration.sh did not reject identical main and target commits with status 2" >&2
  cat same-ref.out >&2
  cat same-ref.err >&2
  exit 1
fi
grep -F "main ref and target ref are identical: lane/review" same-ref.err >/dev/null
grep -F "use the current integration base, usually origin/main, as main-ref" same-ref.err >/dev/null

git branch review main
if scripts/check-lane-integration.sh review main > ambiguous.out 2> ambiguous.err; then
  echo "check-lane-integration.sh accepted an ambiguous unqualified target" >&2
  cat ambiguous.out >&2
  cat ambiguous.err >&2
  exit 1
fi
grep -F "ambiguous target ref: review matches both review and lane/review" ambiguous.err >/dev/null
grep -F "use an explicit ref such as lane/review" ambiguous.err >/dev/null

git switch -q -c lane/INT-02-fresh-0409 main
printf 'fresh\n' > fresh.txt
git add fresh.txt
git commit -q -m fresh
printf '# base worker handoff\n' > swarm/handoffs/INT-02.md

git switch -q main
scripts/check-lane-integration.sh lane/INT-02-fresh-0409 main > fresh.out
grep -F "handoff: present swarm/handoffs/INT-02.md" fresh.out >/dev/null
grep -F "classification: review-required" fresh.out >/dev/null

git switch -q -c lane/missing-handoff main
printf 'missing handoff\n' > missing-handoff.txt
git add missing-handoff.txt
git commit -q -m missing-handoff

git switch -q main
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

set +e
scripts/check-lanes-integration.sh --summary-json --main-ref main lane/review lane/missing-handoff > batch-json.out 2> batch-json.err
batch_json_status=$?
set -e
if [[ "$batch_json_status" -ne 1 ]]; then
  echo "check-lanes-integration.sh --summary-json did not preserve mixed batch status 1" >&2
  cat batch-json.out >&2
  cat batch-json.err >&2
  exit 1
fi
grep -F "summary: passed=1 failed=1 total=2" batch-json.out >/dev/null
grep -F 'summary-json: {"passed":1,"failed":1,"total":2,"status":1}' batch-json.out >/dev/null

set +e
scripts/check-lanes-integration.sh --main-ref main lane/missing-handoff lane/does-not-exist > batch-ref-error.out 2> batch-ref-error.err
batch_ref_error_status=$?
set -e
if [[ "$batch_ref_error_status" -ne 2 ]]; then
  echo "check-lanes-integration.sh did not preserve ref-error status 2" >&2
  cat batch-ref-error.out >&2
  cat batch-ref-error.err >&2
  exit 1
fi
grep -F "== lane/missing-handoff ==" batch-ref-error.out >/dev/null
grep -F "classification: review-required-missing-handoff" batch-ref-error.out >/dev/null
grep -F "== lane/does-not-exist ==" batch-ref-error.out >/dev/null
grep -F "lane integration check: target ref not found: lane/does-not-exist" batch-ref-error.err >/dev/null
grep -F "summary: passed=0 failed=2 total=2" batch-ref-error.out >/dev/null

scripts/check-lanes-integration.sh --main-ref main lane/integrated lane/stale-equivalent > batch-safe.out
grep -F "== lane/integrated ==" batch-safe.out >/dev/null
grep -F "classification: already-integrated" batch-safe.out >/dev/null
grep -F "== lane/stale-equivalent ==" batch-safe.out >/dev/null
grep -F "classification: stale-equivalent" batch-safe.out >/dev/null
grep -F "summary: passed=2 failed=0 total=2" batch-safe.out >/dev/null

scripts/check-lanes-integration.sh --summary-json --main-ref main lane/integrated lane/stale-equivalent > batch-safe-json.out
grep -F "summary: passed=2 failed=0 total=2" batch-safe-json.out >/dev/null
grep -F 'summary-json: {"passed":2,"failed":0,"total":2,"status":0}' batch-safe-json.out >/dev/null

set +e
scripts/check-lanes-integration.sh --main-ref main lane/missing-handoff missing-handoff > batch-alias-duplicate.out 2> batch-alias-duplicate.err
batch_alias_duplicate_status=$?
set -e
if [[ "$batch_alias_duplicate_status" -ne 2 ]]; then
  echo "check-lanes-integration.sh did not reject aliased duplicate targets with status 2" >&2
  cat batch-alias-duplicate.out >&2
  cat batch-alias-duplicate.err >&2
  exit 1
fi
grep -F "duplicate target: missing-handoff resolves to lane/missing-handoff" batch-alias-duplicate.err >/dev/null
if grep -F "== lane/missing-handoff ==" batch-alias-duplicate.out >/dev/null; then
  echo "check-lanes-integration.sh started lane checks before rejecting aliased duplicate targets" >&2
  cat batch-alias-duplicate.out >&2
  exit 1
fi

set +e
scripts/check-lanes-integration.sh --main-ref main lane/integrated lane/integrated > batch-duplicate.out 2> batch-duplicate.err
batch_duplicate_status=$?
set -e
if [[ "$batch_duplicate_status" -ne 2 ]]; then
  echo "check-lanes-integration.sh did not reject duplicate targets with status 2" >&2
  cat batch-duplicate.out >&2
  cat batch-duplicate.err >&2
  exit 1
fi
grep -F "duplicate target: lane/integrated" batch-duplicate.err >/dev/null
if grep -F "== lane/integrated ==" batch-duplicate.out >/dev/null; then
  echo "check-lanes-integration.sh started lane checks before rejecting duplicate targets" >&2
  cat batch-duplicate.out >&2
  exit 1
fi
