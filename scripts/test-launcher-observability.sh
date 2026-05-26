#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

launcher_log="$tmpdir/phpc-swarm-launcher.log"
cat > "$launcher_log" <<'LOG'
=== supervised restart: 2026-05-26T01:51:27Z SWARM_WORKER_COUNT=100 SWARM_INCLUDE_AUDITOR=1 SWARM_AUDITOR_FIRST=1 SWARM_LAUNCH_STAGGER_SECONDS=480 ===
2026-05-26T01:51:28Z launch: started Codex session 1/101 (AUD-01).
2026-05-26T01:51:28Z launch: waiting 480s before starting Codex session 2/101.
LOG

PHPC_SWARM_LAUNCHER_LOG="$launcher_log" scripts/check-launcher-observability.sh

sed 's/SWARM_LAUNCH_STAGGER_SECONDS=480/SWARM_LAUNCH_STAGGER_SECONDS=60/' "$launcher_log" > "$tmpdir/bad-cadence.log"
if PHPC_SWARM_LAUNCHER_LOG="$tmpdir/bad-cadence.log" scripts/check-launcher-observability.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "check-launcher-observability.sh accepted a stale launcher cadence" >&2
  exit 1
fi
if ! grep -F "launcher cadence drift" "$tmpdir/err" >/dev/null; then
  echo "check-launcher-observability.sh failed without the expected cadence diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
