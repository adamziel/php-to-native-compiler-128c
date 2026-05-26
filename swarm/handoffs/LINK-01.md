# LINK-01 Handoff

## Summary

- Lane: `lane/LINK-01`.
- Milestone: M4/M6.
- Queue item: Q-025 native truthfulness for include/require.
- Continue slice: added include-side native diagnostic coverage without
  claiming native include execution.
- `compile --emit-ir` now has focused CLI coverage for non-literal
  `include APP_DIR . '/included.php';`, asserting the parser-level
  `expected literal string path` rejection.
- `compile --emit-exe` now has focused CLI coverage for literal
  `include 'missing.php';`, asserting the linked-native unsupported diagnostic
  is reported before include file execution or runtime archive setup.
- Updated `docs/SUPPORT.md` to clarify that native literal include/require
  rejection does not check target file existence, and that non-literal
  `include` path expressions share the same unsupported expression-path status
  as `require`.
- Recycle slice: verified non-literal `require` path expressions remain
  truthfully unsupported before linked-native setup while parser support is
  still literal-path only.
- Added focused CLI coverage for `compile --emit-exe` with
  `require APP_DIR . '/included.php';`; the test asserts the parser diagnostic
  `expected literal string path`, no missing-runtime masking, and stale output
  cleanup.
- Updated `docs/SUPPORT.md` to state that non-literal `require`/`include` path
  expressions are rejected before native lowering and must not be counted as
  linked-native support.
- Preserved the new `phpc run` literal include/require support while keeping
  native support truthfully unsupported.
- `compile --emit-exe` now parses and lowers before checking runtime archive
  availability, so literal `require` sources report the linked-native execution
  gap instead of being masked by link environment setup.
- Added focused CLI coverage for `compile --emit-ir` rejecting literal
  `include` and `compile --emit-exe` rejecting literal `require` before runtime
  link setup.
- Updated `docs/SUPPORT.md` to distinguish interpreter literal include/require
  support from native include/require rejection.

## Files Changed

- `crates/phpc/tests/bootstrap_cli.rs`
- `crates/phpc_core/src/lib.rs`
- `docs/SUPPORT.md`
- `swarm/handoffs/LINK-01.md`

## Tests Run

- `cargo fmt` could not run because this toolchain has no `cargo fmt`
  subcommand.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
  passed: 84 tests.
- Continue slice:
  `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_ir_rejects_non_literal_include_path_expression`
  passed.
- Continue slice:
  `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_exe_rejects_missing_literal_include_before_file_execution`
  passed.
- Recycle slice:
  `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_exe_rejects_non_literal_require_before_runtime_link_setup`
  passed.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_ir_rejects_include_with_truthful_native_diagnostic`
  passed.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_exe_rejects_require_before_runtime_link_setup`
  passed.
- After rebasing onto `origin/main` at `1a9f889`, reran
  `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_exe_rejects_require_before_runtime_link_setup`;
  passed.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
  passed: 27 tests.

## Pass/Fail State

- Pass for the narrow Q-025 native truthfulness slice.

## Blockers

- Native `require`/`include` execution remains unsupported. This slice only
  keeps diagnostics and link setup ordering truthful while interpreter support
  proceeds separately.

## Latest Commit

- Continue commit in `lane/LINK-01`: include missing-path/expression-path
  native diagnostic coverage.

## Next Suggested Slice

- Add native lowering only after the compiler has a real include execution
  model; until then, keep `emit-ir` and `emit-exe` rejection coverage in place.
