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
PHPC_EXPECT_INCLUDE_AUDITOR=1 PHPC_SWARM_LAUNCHER_LOG="$launcher_log" scripts/check-launcher-observability.sh

worker_command="$(bash -c 'source scripts/swarm-interactive.sh; swarm_codex_command /repo /targets INT-05 /worktrees/INT-05')"
for expected in \
  "CARGO_TARGET_DIR='/targets/INT-05'" \
  "PHPC_REQUIRE_WORKER_ENV=1" \
  "PHPC_WORKTREE_ROOT='/worktrees/INT-05'" \
  "PHPC_TARGET_ROOT='/targets'" \
  "PHPC_LANE_ID='INT-05'" \
  "PHPC_EXPECT_BRANCH='lane/INT-05'" \
  "codex --cd '/worktrees/INT-05'"
do
  if ! printf '%s\n' "$worker_command" | grep -F "$expected" >/dev/null; then
    echo "swarm_codex_command missing expected worker preflight export: $expected" >&2
    printf '%s\n' "$worker_command" >&2
    exit 1
  fi
done

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

sed 's/SWARM_INCLUDE_AUDITOR=1/SWARM_INCLUDE_AUDITOR=0/' "$launcher_log" > "$tmpdir/no-auditor.log"
if PHPC_EXPECT_INCLUDE_AUDITOR=1 PHPC_SWARM_LAUNCHER_LOG="$tmpdir/no-auditor.log" scripts/check-launcher-observability.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "check-launcher-observability.sh accepted a launcher without the expected auditor" >&2
  exit 1
fi
if ! grep -F "launcher auditor target drift" "$tmpdir/err" >/dev/null; then
  echo "check-launcher-observability.sh failed without the expected auditor diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

sed 's/session 2\/101/session 2\/100/' "$launcher_log" > "$tmpdir/bad-denominator.log"
if PHPC_SWARM_LAUNCHER_LOG="$tmpdir/bad-denominator.log" scripts/check-launcher-observability.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "check-launcher-observability.sh accepted a stale launcher session denominator" >&2
  exit 1
fi
if ! grep -F "launcher session denominator drift" "$tmpdir/err" >/dev/null; then
  echo "check-launcher-observability.sh failed without the expected session denominator diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

cat > "$tmpdir/started-without-wait.log" <<'LOG'
=== supervised restart: 2026-05-26T01:51:27Z SWARM_WORKER_COUNT=100 SWARM_INCLUDE_AUDITOR=1 SWARM_AUDITOR_FIRST=1 SWARM_LAUNCH_STAGGER_SECONDS=480 ===
2026-05-26T01:51:28Z launch: started Codex session 1/101 (AUD-01).
2026-05-26T01:51:28Z launch: waiting 480s before starting Codex session 2/101.
2026-05-26T01:52:00Z launch: started Codex session 2/101 (INT-01).
LOG
if PHPC_SWARM_LAUNCHER_LOG="$tmpdir/started-without-wait.log" scripts/check-launcher-observability.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "check-launcher-observability.sh accepted a latest started session without a newer wait event" >&2
  exit 1
fi
if ! grep -F "launcher latest started session is not behind latest wait event" "$tmpdir/err" >/dev/null; then
  echo "check-launcher-observability.sh failed without the expected latest started session diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
