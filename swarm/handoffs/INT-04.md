# INT-04 Handoff

## Summary

Milestone: Integration / M3 status accuracy.

Added a focused CLI regression gate proving `phpc compile --emit-exe` fails with the explicit linked-native-executable blocker until the real M3 executable path exists. This is integration safety/status accuracy only; it does not count as native compiler progress.

Narrow denominator: CLI-visible M3 unsupported-mode behavior for the bootstrap fixture.

## Files Changed

- `crates/phpc/tests/bootstrap_cli.rs`
- `swarm/handoffs/INT-04.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-int04 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`

## Pass/Fail State

- Pass: focused `phpc` bootstrap CLI integration test suite.

## Blockers

- M3 remains blocked on real linked native executable implementation: compile/link/run/compare is not implemented.

## Latest Lane Commit

- `5ee3e31` Gate unsupported linked exe CLI mode.

## Integration Note

- Ported manually onto current `main` after newer progress and local-gate integrations landed.

## Next Suggested Slice

Add a matching CLI gate for `--emit-asm`, or review an existing LINK lane implementation slice and integrate only if it produces and runs an executable without shelling out to generated fixtures or counting scaffolding as native progress.
