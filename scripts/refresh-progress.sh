#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

head="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
branch="$(git branch --show-current 2>/dev/null || echo none)"
dirty="$(git status --short 2>/dev/null | wc -l)"
if tmux list-windows -t phpc-swarm >/dev/null 2>&1; then
  windows="$(tmux list-windows -t phpc-swarm | wc -l)"
else
  windows="0"
fi

tmp="$(mktemp)"
{
  echo "# PHP-To-Native Compiler Swarm Progress"
  echo
  echo "Last refreshed: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "## Current State"
  echo
  echo "- Repository: \`adamziel/php-to-native-compiler-128c\`"
  echo "- Branch: \`${branch}\`"
  echo "- HEAD: \`${head}\`"
  echo "- Dirty entries: \`${dirty}\`"
  echo "- tmux windows in \`phpc-swarm\`: \`${windows}\`"
  echo
  echo "## Milestone Estimates"
  echo
  echo "| Milestone | Denominator | Current | Status |"
  echo "| --- | --- | ---: | --- |"
  echo "| M1 COW shared mechanisms | RPR, DMB, CCA, regression matrix | 0% | Not started |"
  echo "| M2 runtime value ABI | value kinds and ownership semantics | 1% | Bootstrap echo helper |"
  echo "| M3 linked native execution | compile, link, run, compare | 0% | Queued |"
  echo "| M4 native lowering | interpreter-supported constructs lowered or rejected | 1% | Echo literal scaffold |"
  echo "| M5 PHP core .phpt harness | pinned php-src denominator | 0% | Queued |"
  echo "| M6 WordPress harness | pinned entrypoints/scenarios | 0% | Queued |"
  echo "| M7 object/SAPI/DB generality | required semantic families | 0% | Queued |"
  echo "| M8 performance after correctness | truthful native benchmarks | 0% | Deferred |"
  echo
  echo "## Latest Verification"
  echo
  if command -v cargo >/dev/null 2>&1; then
    echo "- cargo available: \`$(cargo --version)\`"
  else
    echo "- cargo unavailable"
  fi
  if command -v php >/dev/null 2>&1; then
    echo "- php available: \`$(php -v | head -n 1)\`"
  else
    echo "- php unavailable"
  fi
  if command -v clang >/dev/null 2>&1; then
    echo "- clang available: \`$(clang --version | head -n 1)\`"
  else
    echo "- clang unavailable"
  fi
  echo
  echo "## Current Blockers"
  sed -n '1,120p' swarm/blockers.md | sed 's/^/> /'
} > "$tmp"
mv "$tmp" progress.md
