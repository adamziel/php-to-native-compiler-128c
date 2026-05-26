#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [ -z "${CARGO_TARGET_DIR:-}" ]; then
  echo "local-gate.sh requires CARGO_TARGET_DIR to keep lane builds isolated" >&2
  exit 2
fi

case "$CARGO_TARGET_DIR" in
  /*) ;;
  *)
    echo "local-gate.sh requires an absolute CARGO_TARGET_DIR, got $CARGO_TARGET_DIR" >&2
    exit 2
    ;;
esac

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
cargo test --locked
git diff --check
