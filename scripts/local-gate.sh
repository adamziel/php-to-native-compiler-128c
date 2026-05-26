#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ "${PHPC_REQUIRE_WORKER_ENV:-0}" = "1" ]; then
  scripts/verify-worker-env.sh
fi

scripts/status-gate.sh
scripts/verify-status-consistency.sh
scripts/test-status-consistency.sh
scripts/verify-runtime-abi-docs.sh
scripts/test-status-gate.sh
scripts/test-runtime-abi-docs.sh
scripts/test-refresh-progress-labels.sh
scripts/test-refresh-progress-launcher-log.sh
scripts/test-launcher-observability.sh
scripts/test-check-lane-integration.sh
scripts/check-lanes-integration.sh --help >/dev/null 2>&1
scripts/test-worker-env.sh
cargo test
git diff --check
