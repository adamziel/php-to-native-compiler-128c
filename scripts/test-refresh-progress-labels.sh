#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repo_root}/scripts/refresh-progress.sh"

bash -n "$script"

grep -q 'Active worker command processes' "$script"
grep -q 'Active agent slot cap' "$script"
grep -q 'Active worker commands' "$script"

if grep -Eq 'Active `?codex exec|Active Codex slot cap|Active codex exec' "$script"; then
  echo "refresh-progress.sh must use tool-neutral public status labels" >&2
  exit 1
fi
