# INT-08 Handoff

## Summary

- Milestone: Integration.
- Added a focused CLI hygiene gate for unsupported `phpc compile` flag combinations.
- `phpc compile <input.php> --emit-ir --emit-exe` is now covered as an explicit failure with no stdout and the existing truthful unsupported-flags diagnostic.

## Files Changed

- `crates/phpc/tests/bootstrap_cli.rs`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-08.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-08 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
- `scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: focused CLI gate, 5 tests passed on current main after porting this slice.
- PASS: local gate and diff check.

## Blockers

- No blocker for this integration-safety slice.
- Existing M3 blocker remains: linked native executable emission is not implemented.

## Latest Commit

- `d8e861f Update INT-08 handoff`

## Next Suggested Slice

- Add a focused CLI gate for unsupported compile flag combinations or missing input behavior if not already covered by another lane.
