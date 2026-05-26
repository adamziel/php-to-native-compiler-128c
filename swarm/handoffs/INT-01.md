# INT-01 Handoff

summary: Ported the useful LOW-04 boolean/null echo behavior onto the current parser/core shape without taking the stale `Literal` parser model. `Expression` now has boolean and null literal variants. `phpc run` matches PHP echo output for `true`, `false`, and `null`; `--emit-ir` reports the supported literal kinds; and `phpc compile --emit-exe` links and runs a native executable for a committed `true`/`false`/`null` fixture, comparing output with `phpc run` and system PHP when available. Existing parser trivia/comment support and final echo before `?>` behavior were preserved.

files changed:
- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `fixtures/bootstrap/bool_null_echo.php`
- `docs/SUPPORT.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core parser::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core boolean_and_null`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core linkable_ir_calls_runtime_echo_for_supported_literals`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emits_ir_for_boolean_and_null_echo -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_boolean_and_null_echo -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: parser tests cover case-insensitive `true`, `false`, and `null` parsing plus keyword-prefix rejection.
- PASS: core tests cover PHP-compatible boolean/null echo output and truthful IR comments.
- PASS: CLI linked executable test builds `libphp_runtime.a`, emits a native executable for `fixtures/bootstrap/bool_null_echo.php`, runs it, and compares stdout/stderr with `phpc run` and system PHP when available.
- PASS: full workspace `cargo test` reported 75 tests passing: 19 runtime, 11 CLI, 45 core.
- PASS: local coordination gate.

blockers:
- No blocker for this slice.
- Broader native lowering remains limited to literal echo expressions; variables, arrays, functions, constants/`define`, objects, and WordPress bootstrap remain unsupported general PHP/compiler gaps.

latest commit:
- Branch HEAD for this slice: `Add boolean and null native echo support`

next suggested slice:
- Add a small native execution fixture for mixed string, integer, boolean, and null echoes with closing-tag coverage, or reduce the WordPress `define( 'WPINC', 'wp-includes' )` blocker through a general parser/interpreter fixture without WordPress-specific behavior.
