# PHPT-02 Handoff

## Summary

- Milestone: M5.
- Current `origin/main` already contains the previous PHPT-02 `test_name` reporting slice, so this slice extends that reporting without duplicating denominator accounting.
- `phpc phpt-run` now prints `source_kind=<FILE|FILEEOF>` and `expectation_kind=<EXPECT|EXPECTF|EXPECTREGEX>` when those sections are present.
- This is a machine-readable reporting improvement only. The php-src runnable denominator remains 4 of 19,346.

## Files Changed

- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `swarm/handoffs/PHPT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_runs_minimal_phpt_with_phpc_runner`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: focused CLI `.phpt` runner report test, including `test_name`, `source_kind=FILE`, and `expectation_kind=EXPECT`.
- PASS: status gate.
- PASS: `git diff --check`.

## Latest Commit

- This committed slice: `Report phpt section kinds in CLI output`

## Blockers

- No blocker for this reporting slice.
- M5 remains blocked on broader `.phpt` semantics: INI, native execution, full SKIPIF, EXPECTREGEX matching, and many unsupported PHP language/runtime features.

## Next Suggested Slice

- Add focused result metadata only when it improves classification, or mine another tiny already-supported pinned `.phpt` without counting unsupported probes.
