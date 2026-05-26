#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

before_progress="$(mktemp)"
before_html="$(mktemp)"
after_progress="$(mktemp)"
after_html="$(mktemp)"
trap 'rm -f "$before_progress" "$before_html" "$after_progress" "$after_html"' EXIT

cp progress.md "$before_progress"
cp docs/progress.html "$before_html"
scripts/refresh-progress.sh --check
grep -q 'refresh-progress check failed: missing' scripts/refresh-progress.sh
grep -q 'refresh-progress check failed: .* count was' scripts/refresh-progress.sh
grep -q 'expected fixed text:' scripts/refresh-progress.sh
grep -q 'expected regex:' scripts/refresh-progress.sh
cp progress.md "$after_progress"
cp docs/progress.html "$after_html"

diff -u "$before_progress" "$after_progress" >/dev/null
diff -u "$before_html" "$after_html" >/dev/null
