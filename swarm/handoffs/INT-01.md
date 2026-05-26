# INT-01 Handoff

summary: Started a fresh slice from `origin/main` on branch `lane/INT-01-define` without reusing or rebasing prior lane commits. Added a narrow top-level `define('NAME', 'literal');` statement path using the current parser/core shape: `Statement::Call(CallExpression)` parses `define(...)`, `phpc run` records string constants with no output, `--emit-ir` reports string constant definitions, and linked IR accepts supported `define(...)` statements as no-output statements. The WordPress bootstrap check now advances past the leading docblock and `define( 'WPINC', 'wp-includes' )`; the pinned WordPress 7.0 blocker is now the general PHP top-level `global $wp_version, $wp_db_versi...` declaration.

files changed:
- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `docs/WORDPRESS_COMPATIBILITY.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core parser::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core define`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests::reports_phpc_parse_errors_as_phpt_run_errors`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-define CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: parser tests cover `define( 'WPINC', 'wp-includes' );` after PHP comments while preserving final echo and trivia behavior.
- PASS: core tests cover `phpc run` no-output define behavior, IR reporting, define signature rejection for non-string values, and linked IR no-output handling.
- PASS: retained `.phpt` parse-error behavior for unsupported `var_dump(1);` after narrowing call parsing to `define(...)` only.
- PASS: WordPress bootstrap CLI test now verifies the blocker moves past `define(...)` to the next general PHP statement.
- PASS: real pinned WordPress bootstrap check reports all five entrypoints present and blocks at `global $wp_version, $wp_db_versi...`.
- PASS: local coordination gate, including full workspace tests: 19 runtime, 11 CLI, 52 core.

blockers:
- No blocker for this slice.
- WordPress bootstrap remains blocked on general PHP `global` declaration parsing/interpreter behavior.
- Constant lookup, `defined()`, conditional statements, includes, and broader function calls remain unsupported; this slice intentionally supports only string-literal `define(...)` statements.

latest commit:
- Branch HEAD for this slice: `Support string literal define statements`

next suggested slice:
- Reduce the new WordPress blocker with a general top-level `global $name, ...;` statement parser/interpreter no-op for the current non-function global scope, with focused tests and no WordPress-specific names.
