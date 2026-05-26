# INT-01 Handoff

summary: Started a fresh slice from current `origin/main` on branch `lane/INT-01-global-2`. Added narrow top-level `global $name, $other;` parsing as `Statement::Global(Vec<String>)`. In the current non-function/global execution model it is a no-op for `phpc run`, reports a no-output `global[...]` line in `--emit-ir`, and is skipped by linked native IR emission. The WordPress bootstrap check now advances past the leading docblock, `define( 'WPINC', 'wp-includes' )`, and the top-level `global $wp_version, ...` declaration; the next pinned WordPress 7.0 blocker is the general PHP `require ABSPATH . WPINC . '/version.php';` statement.

files changed:
- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `docs/WORDPRESS_COMPATIBILITY.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-global CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core parser::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-global CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core global`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-global CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-global CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-global CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: parser tests cover comma-separated `global` declarations, global after comments/`define`, missing variable rejection, and missing semicolon rejection.
- PASS: core tests cover `phpc run` no-op behavior, truthful IR reporting, and linked native no-output handling for `global`.
- PASS: focused WordPress bootstrap CLI test now verifies the blocker moves past `global` to `require`.
- PASS: real pinned WordPress bootstrap check reports all five entrypoints present and blocks at `require ABSPATH . WPINC . '/vers`.
- PASS: local coordination gate, including status checks, launcher observability, runtime ABI docs, full workspace tests, and diff hygiene. Full workspace tests reported 19 runtime, 11 CLI, and 68 core tests passing.

blockers:
- No blocker for this slice.
- WordPress bootstrap remains blocked on general PHP `require`/include expression parsing and execution.
- This slice intentionally does not add variable reads/writes, function-scope global binding, includes, constants lookup, `defined()`, or conditional statements.

latest commit:
- Branch HEAD for this slice: `Support top-level global declarations`

next suggested slice:
- Reduce the new WordPress blocker with a general `require` statement parser/interpreter slice for a narrow constant/string concatenation include path, or first add a precise unsupported diagnostic for include/require expressions if implementation would broaden scope.
