# PHPT-02 Handoff

## Summary

- Milestones: M4/M5/M6.
- Validated the integrated general literal include/require execution slice for `phpc run <input.php>`.
- Parser now accepts `require` and `include` only when the path is a literal string.
- `phpc run` resolves literal include paths relative to the input file's directory and executes the included PHP through the existing supported interpreter path.
- Native lowering remains truthful: include/require statements are rejected by `compile --emit-ir` with an explicit native-lowering diagnostic.
- WordPress bootstrap now advances from "include/require execution not implemented" to the next general blocker: non-literal `require` path expression `ABSPATH . WPINC . '/version.php'`.
- Re-ran a pinned recorded php-src subset: `tests/basic/001.phpt` reports `status=pass`, `expected_stdout_len=11`, `actual_stdout_len=11`.
- Scanned pinned `tests/basic/*.phpt` and `tests/run-test/*.phpt` with the current `phpc phpt-run` evaluator; no additional passing php-src `.phpt` candidate was found.
- Current rebased php-src runnable denominator is 2 of 19,346 after upstream recorded `tests/output/ob_001.phpt`; literal include/require support is not counted as php-src `.phpt` progress because the current `.phpt` runner still executes FILE bodies without an input file path/base directory.

## Files Changed

- `swarm/handoffs/PHPT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_run_executes_literal_require_sibling_file`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/tests/basic/001.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/tests/output/ob_001.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`
- `cargo fmt --check`

## Pass/Fail State

- PASS: `phpc_core`, 84 tests.
- PASS: focused CLI literal require execution test.
- PASS: focused CLI WordPress bootstrap blocker test.
- PASS: full workspace tests, covering 27 `php_runtime`, 22 `phpc` CLI integration, and 84 `phpc_core` tests.
- PASS: pinned php-src `tests/basic/001.phpt` through `phpc_run`, `status=pass`, expected stdout length 11, actual stdout length 11.
- PASS: pinned php-src `tests/output/ob_001.phpt` through `phpc_run`, `status=pass`, expected stdout length 3, actual stdout length 3.
- PASS: real WordPress 7.0 bootstrap check reports all five entrypoints present and `general_php_gap=unsupported require statement: expected literal string path`.
- PASS: `scripts/status-gate.sh`.
- PASS: `scripts/local-gate.sh`.
- PASS: `git diff --check`.
- FAIL: `cargo fmt --check` could not run because the toolchain lacks `cargo-fmt`.

## Latest Commit

- This committed slice: `Record PHPT-02 literal require evidence`

## Blockers

- `cargo fmt --check` could not run because the toolchain lacks `cargo-fmt`.
- WordPress remains blocked on general PHP expression support for include/require paths: constants plus string concatenation.
- The php-src `.phpt` runnable denominator remains 2 of 19,346 until the runner has base-path-aware execution or another pinned test fits the supported literal surface.

## Next Suggested Slice

- Add general expression support needed for include/require paths: constant lookup plus string concatenation, then re-run the WordPress bootstrap check.
- For M5, make the `.phpt` runner base-path-aware before counting include/require php-src tests, or find a different pinned test that fits the currently supported literal surface.
