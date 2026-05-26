# INT-08 Handoff

## Summary

- Milestone: Integration / CLI hygiene.
- Ported only the current-main-safe part of `lane/INT-08`: focused tests for missing CLI input handling.
- `phpc run` and `phpc compile` with no input file are now covered as explicit failures with no stdout and the existing `missing input PHP file` diagnostic.
- The stale lane branch also contained obsolete native-executable expectations and generated status edits; those were not merged.

## Files Changed

- `crates/phpc/tests/bootstrap_cli.rs`
- `swarm/handoffs/INT-08.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-cli-missing-input CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-worker-env-4 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `git diff --check`

## Pass/Fail State

- PASS: focused CLI integration suite, 13 tests passed.
- PASS: worker-env regression tests still passed after the concurrent INT-03 integration.
- PASS: diff whitespace check.

## Blockers

- None for this narrow test slice.

## Latest Commit

- Pending main commit after verification.

## Next Suggested Slice

- Add a focused CLI gate for unknown command/help exit behavior if not already covered by another lane.
