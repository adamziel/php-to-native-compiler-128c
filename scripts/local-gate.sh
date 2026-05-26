#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

scripts/status-gate.sh
scripts/verify-status-consistency.sh
scripts/test-status-consistency.sh
scripts/verify-runtime-abi-docs.sh
scripts/test-status-gate.sh
scripts/test-runtime-abi-docs.sh
scripts/test-refresh-progress-labels.sh
scripts/test-launcher-observability.sh
scripts/test-check-lane-integration.sh
cargo test
git diff --check
