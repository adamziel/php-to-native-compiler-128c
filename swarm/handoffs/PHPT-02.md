# PHPT-02 Handoff

## Summary

- Milestone: M5.
- Preserved completed gh15905, bug47596, and base-path-aware `.phpt` runner commits.
- Added a small non-denominator harness reporting improvement: `phpc phpt-run` now prints `test_name=<name>` when the `.phpt` has a `TEST` section.
- The emitted test name is escaped for backslashes and line breaks so the status report remains one key/value per line.
- No php-src runnable denominator change in this slice.

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

- PASS: focused CLI `.phpt` runner report test, including `test_name=Trivial "Hello World" test`.
- PASS: status gate.
- PASS: `git diff --check`.

## Latest Commit

- This committed slice: `Report phpt test names in CLI output`

## Blockers

- No blocker for this reporting slice.
- M5 remains blocked on broader `.phpt` semantics: INI, native execution, full SKIPIF, EXPECTREGEX, and many unsupported PHP language/runtime features.

## Next Suggested Slice

- Add focused result metadata for another parsed section only if it improves run classification, or continue mining tiny already-supported pinned `.phpt` tests without counting unsupported probes.
