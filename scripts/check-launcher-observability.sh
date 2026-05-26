#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

launcher_log="${PHPC_SWARM_LAUNCHER_LOG:-/tmp/phpc-swarm-launcher.log}"
expected_workers="${PHPC_EXPECT_SWARM_WORKERS:-100}"
expected_include_auditor="${PHPC_EXPECT_INCLUDE_AUDITOR:-}"
expected_cadence="${PHPC_EXPECT_LAUNCH_STAGGER_SECONDS:-480}"

bash -n scripts/launch-swarm.sh
bash -n scripts/swarm-interactive.sh
bash -n scripts/refresh-progress.sh

grep -F 'source "$repo_root/scripts/swarm-interactive.sh"' scripts/launch-swarm.sh >/dev/null
grep -F 'swarm_codex_command "$repo_root" "$target_root"' scripts/launch-swarm.sh >/dev/null
grep -F "codex --cd" scripts/swarm-interactive.sh >/dev/null

if grep -Eq "codex[[:space:]]+exec[[:space:]\\]|codex[[:space:]]+-p[[:space:]\\]" scripts/launch-swarm.sh scripts/swarm-interactive.sh; then
  echo "interactive launcher must not start workers with codex -p or codex exec" >&2
  exit 1
fi

if [ ! -f "$launcher_log" ]; then
  echo "launcher log is missing: $launcher_log" >&2
  exit 1
fi

launch_marker="$(
  { grep -E '^=== supervised restart:' "$launcher_log" 2>/dev/null || true; } |
    tail -n 1
)"
if [ -z "$launch_marker" ]; then
  echo "launcher log does not contain a supervised restart marker: $launcher_log" >&2
  exit 1
fi

launch_worker_count="$(printf '%s\n' "$launch_marker" | sed -n 's/.*SWARM_WORKER_COUNT=\([0-9][0-9]*\).*/\1/p')"
launch_include_auditor="$(printf '%s\n' "$launch_marker" | sed -n 's/.*SWARM_INCLUDE_AUDITOR=\([01]\).*/\1/p')"
launch_cadence="$(printf '%s\n' "$launch_marker" | sed -n 's/.*SWARM_LAUNCH_STAGGER_SECONDS=\([0-9][0-9]*\).*/\1/p')"
if [ "$launch_worker_count" != "$expected_workers" ]; then
  echo "launcher worker target drift: expected $expected_workers, found ${launch_worker_count:-missing}" >&2
  exit 1
fi
case "${launch_include_auditor:-missing}" in
  0|1) ;;
  *)
    echo "launcher auditor flag is not 0 or 1: ${launch_include_auditor:-missing}" >&2
    exit 1
    ;;
esac
if [ -n "$expected_include_auditor" ] && [ "$launch_include_auditor" != "$expected_include_auditor" ]; then
  echo "launcher auditor target drift: expected SWARM_INCLUDE_AUDITOR=$expected_include_auditor, found $launch_include_auditor" >&2
  exit 1
fi
if [ "$launch_cadence" != "$expected_cadence" ]; then
  echo "launcher cadence drift: expected ${expected_cadence}s, found ${launch_cadence:-missing}" >&2
  exit 1
fi
expected_sessions="$((expected_workers + launch_include_auditor))"

latest_wait="$(
  { grep -E 'launch: waiting [0-9]+s before starting Codex session' "$launcher_log" 2>/dev/null || true; } |
    tail -n 1
)"
if [ -z "$latest_wait" ]; then
  echo "launcher log does not contain a stagger wait event" >&2
  exit 1
fi
if ! printf '%s\n' "$latest_wait" | grep -F "waiting ${expected_cadence}s before starting Codex session" >/dev/null; then
  echo "latest stagger wait event does not use ${expected_cadence}s: $latest_wait" >&2
  exit 1
fi
latest_wait_total="$(printf '%s\n' "$latest_wait" | sed -n 's/.*Codex session [0-9][0-9]*\/\([0-9][0-9]*\).*/\1/p')"
if [ "$latest_wait_total" != "$expected_sessions" ]; then
  echo "launcher session denominator drift: expected $expected_sessions, found ${latest_wait_total:-missing}" >&2
  exit 1
fi
latest_started="$(
  { grep -E 'launch: started Codex session [0-9]+/[0-9]+' "$launcher_log" 2>/dev/null || true; } |
    tail -n 1
)"
if [ -n "$latest_started" ]; then
  latest_started_number="$(printf '%s\n' "$latest_started" | sed -n 's/.*Codex session \([0-9][0-9]*\)\/[0-9][0-9]*.*/\1/p')"
  latest_wait_number="$(printf '%s\n' "$latest_wait" | sed -n 's/.*Codex session \([0-9][0-9]*\)\/[0-9][0-9]*.*/\1/p')"
  if [ -n "$latest_started_number" ] && [ -n "$latest_wait_number" ] && [ "$latest_started_number" -ge "$latest_wait_number" ]; then
    echo "launcher latest started session is not behind latest wait event: started $latest_started_number, waiting for $latest_wait_number" >&2
    exit 1
  fi
fi

batch_workers="$(
  ps -eo args= |
    awk '
      (index($0, "codex exec") || index($0, "codex -p")) &&
      index($0, "check-launcher-observability.sh") == 0 &&
      index($0, "awk") == 0 &&
      index($0, "grep") == 0 { count++ }
      END { print count + 0 }
    '
)"
if [ "$batch_workers" != "0" ]; then
  echo "found active batch-style worker processes: $batch_workers" >&2
  exit 1
fi

SWARM_WORKER_COUNT="$expected_workers" SWARM_INCLUDE_AUDITOR="$launch_include_auditor" SWARM_LAUNCH_STAGGER_SECONDS="$expected_cadence" scripts/refresh-progress.sh --check

if [ "$launch_include_auditor" = "1" ]; then
  target_label="${expected_workers} workers + auditor"
else
  target_label="${expected_workers} workers"
fi
echo "launcher observability ok: interactive-only, ${target_label}, ${expected_cadence}s cadence, no codex -p/codex exec workers"
