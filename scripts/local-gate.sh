#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

scripts/status-gate.sh
scripts/verify-status-consistency.sh
scripts/test-status-gate.sh
git diff --check
