# INT-06 Handoff

## Summary

- Time: 2026-05-26T01:25:00Z.
- Milestone: Coordination / M5 status accuracy.
- Narrow denominator: stale committed-candidate review status for `Q-022` / `PHPT-03` skip/XFAIL metadata.
- Verified that current `main` already contains the accepted parser-level `SKIPIF`/`XFAIL` metadata behavior from the PHPT metadata integration path.
- Marked `Q-022` verified as stale to avoid reapplying standalone commit `ea96852`.

## Files Changed

- `swarm/queue.md`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-06.md`

## Tests Run

- `git merge-base --is-ancestor 0cbd609 main`
  - Pass: exit 0; the accepted PHPT metadata integration commit is an ancestor of `main`.
- Inspected `main:crates/phpc_core/src/phpt.rs`
  - Pass: current `main` exposes `PhptMetadata`, `PhptSkip`, `PhptXfail`, `xfail()`, `metadata()`, and metadata-carrying harness input tests.
- `git diff --check`
  - Pass.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-06-main-gate CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
  - Pass in `/home/ubuntu/php-to-native-compiler-128c` on current `main`.

## Pass/Fail State

- Pass for the narrow Q-022 status decision.

## Blockers

- None for the main status update. The stale `lane/INT-06` checkout lacks `scripts/local-gate.sh`, so the gate evidence was run from current `main`.

## Latest Commit

- Current lane HEAD for this slice: `6194c83 Verify PHPT-03 candidate status`.

## Next Suggested Slice

- After this status update lands, review the next stale committed candidate, likely `Q-023` / `WP-12`, against current `main` and the WordPress manifest evidence.
