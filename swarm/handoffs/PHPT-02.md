# PHPT-02 Handoff

## Summary

- Milestone: M5.
- Preserved completed bug47596 evidence while rebasing onto current `origin/main`.
- Implemented the next smallest harness capability: `.phpt` FILE bodies can now resolve literal-path `require`/`include` relative to a supplied base directory.
- Wired `phpc phpt-run <input.phpt>` to use the `.phpt` file's parent directory as that base directory.
- Did not increase the php-src runnable denominator for this base-path slice. It remains 4 of 19,346 until an include-relative php-src test is actually executed and recorded.

## Files Changed

- `crates/phpc_core/src/lib.rs`
- `crates/phpc_core/src/phpt.rs`
- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `swarm/php-core-manifest.json`
- `swarm/test-matrix.md`
- `progress.md`
- `docs/progress.html`
- `swarm/handoffs/PHPT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests::runs_file_body_with_relative_require_from_base_dir`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_phpt_run_resolves_relative_require_from_phpt_directory`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: focused library `.phpt` base-dir test.
- PASS: focused CLI `.phpt` relative require test.
- PASS: focused `.phpt` test module, 38 tests.
- PASS: status gate.
- PASS: `git diff --check`.

## Latest Commit

- This committed slice: `Add base path for phpt relative requires`

## Blockers

- The runner still ignores `INI` sections, lacks native `.phpt` execution, and has limited `SKIPIF`/`EXPECTREGEX` support.
- Include-based php-src tests should not be counted until a real pinned test executes and passes with this base-path-aware runner.

## Next Suggested Slice

- Re-scan literal include/require php-src `.phpt` tests and record a new pass only if the test body reduces to currently supported PHP behavior.
