# INT-04 Handoff

## Summary

Milestone: Integration / supervisor safety.

Started a fresh slice from `origin/main` on `lane/INT-04-launcher-observability` to avoid building on the prior INT-04 status-consistency fixture. Added a non-mutating launcher observability check for the staggered interactive launcher.

Narrow denominator: supervisor status/worker observability only. No launcher behavior, compiler behavior, or worker launch behavior changed.

`scripts/check-launcher-observability.sh` verifies:

- worker commands are launched through the interactive `swarm_codex_command` path;
- `scripts/launch-swarm.sh` / `scripts/swarm-interactive.sh` do not start workers with `codex -p` or `codex exec`;
- the latest supervised restart marker records `SWARM_WORKER_COUNT=50`;
- the latest supervised restart marker and stagger wait event record a 480-second cadence;
- the live process table has zero active `codex -p` / `codex exec` worker processes;
- `scripts/refresh-progress.sh --check` still renders the observability surface.

Added a focused shell fixture that supplies a temporary launcher log and proves cadence drift fails with a precise diagnostic.

## Files Changed

- `scripts/check-launcher-observability.sh`
- `scripts/test-launcher-observability.sh`
- `scripts/local-gate.sh`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-04.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-launcher-observability.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/check-launcher-observability.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass: focused launcher observability fixture rejects stale 60-second cadence.
- Pass: live launcher observability check reports interactive-only, 50 workers, 480-second cadence, and zero `codex -p` / `codex exec` workers.
- Pass: local coordination gate.
- Pass: diff whitespace check.

## Blockers

- No blocker for this supervisor-safety slice.
- The live check depends on `/tmp/phpc-swarm-launcher.log` containing a supervised restart marker; tests use `PHPC_SWARM_LAUNCHER_LOG` with a temporary fixture so the check remains non-mutating.

## Latest Commit

- Current HEAD for this slice: `Add launcher observability gate`.

## Next Suggested Slice

- Add a small status/reporting note that distinguishes target sessions from started sessions when the auditor is included, if the operator wants the `1/101` vs `1/100` launcher-log wording made more explicit without changing launcher behavior.
