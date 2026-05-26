#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${repo_root}/scripts/refresh-progress.sh"

bash -n "$script"

grep -q 'Active worker command processes' "$script"
grep -q 'Active agent slot cap' "$script"
grep -q 'Active worker commands' "$script"
grep -q 'wp_bootstrap_summary' "$script"
grep -q 'launch_cadence_display' "$script"

if grep -Eq 'Active `?codex exec|Active Codex slot cap|Active codex exec' "$script"; then
  echo "refresh-progress.sh must use tool-neutral public status labels" >&2
  exit 1
fi

if grep -F 'bootstrap runner queued' "$script"; then
  echo "refresh-progress.sh must derive WordPress bootstrap status from the manifest" >&2
  exit 1
fi

if grep -F 'Interactive launch cadence: `${launch_cadence}s`' "$script" || grep -F '>${launch_cadence}s<' "$script"; then
  echo "refresh-progress.sh must not render unknown launch cadence as unknowns" >&2
  exit 1
fi
