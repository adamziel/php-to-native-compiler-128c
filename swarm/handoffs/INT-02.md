# INT-02 Handoff

## Summary

- Milestone: M4/M6, Q-025.
- Added a general `Statement::Include` parser slice for top-level literal-path `require` and `include`; non-literal require/include paths and `*_once` remain explicit unsupported diagnostics.
- Added `phpc run` file-context execution so literal sibling includes resolve relative to the executing PHP file, including nested included files.
- Added non-WordPress fixtures proving `phpc run fixtures/bootstrap/require_sibling_main.php` loads a sibling PHP file.
- Kept native support truthful: `compile --emit-ir` and linked native emission reject literal include/require with explicit diagnostics rather than pretending support.
- Updated WordPress/status artifacts: the bootstrap check now advances to the next general blocker, `unsupported require statement: expected literal string path`.

## Files Changed

- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `fixtures/bootstrap/require_sibling_main.php`
- `fixtures/bootstrap/require_sibling_lib.php`
- `docs/SUPPORT.md`
- `docs/WORDPRESS_COMPATIBILITY.md`
- `docs/progress.html`
- `progress.md`
- `swarm/blockers.md`
- `swarm/test-matrix.md`
- `swarm/wordpress-manifest.json`
- `swarm/handoffs/INT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core parser::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_run_executes_literal_require_sibling_file`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- run fixtures/bootstrap/require_sibling_main.php`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `scripts/status-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: `phpc_core` tests, 83 passed.
- PASS: CLI integration tests, 22 passed.
- PASS: committed require-sibling fixture prints `main-before|sibling|main-after`.
- PASS: real WordPress 7.0 bootstrap check remains blocked, now at `general_php_gap=unsupported require statement: expected literal string path`.
- PASS: status gate.
- PASS: diff hygiene.

## Blockers

- No blocker for this slice.
- Remaining Q-025/M6 blocker: WordPress uses `require ABSPATH . WPINC . '/version.php';`; the interpreter still needs general constant expression/path evaluation before WordPress bootstrap can advance to executing that include.
- Native include/require support remains intentionally unsupported and truthfully diagnosed.

## Latest Commit

- Latest lane commit is this handoff commit: `Execute literal sibling includes`.

## Next Suggested Slice

- Add the smallest general expression-path include slice: evaluate concatenation of string literals and previously defined string constants in include/require paths, with non-WordPress fixtures first, then verify the WordPress bootstrap blocker moves again.
