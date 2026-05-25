#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
interval="${PAGES_REPORT_INTERVAL:-300}"
url="${PAGES_REPORT_URL:-https://adamziel.github.io/php-to-native-compiler-128c/progress.html}"

cd "$repo_root"

while true; do
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "${started} pages reporter: refreshing progress artifacts"

  ./scripts/refresh-progress.sh

  if ! git diff --quiet -- progress.md docs/progress.html; then
    git add progress.md docs/progress.html
    git commit -m "Update published swarm progress" || true
    git push || true
  else
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) pages reporter: no publishable changes"
  fi

  if command -v curl >/dev/null 2>&1; then
    code="$(curl -L -s -o /dev/null -w '%{http_code}' "$url" || true)"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) pages reporter: ${url} -> HTTP ${code}"
  fi

  sleep "$interval"
done
