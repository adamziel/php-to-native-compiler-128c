# LINK-02 Handoff

## Summary

- Milestone: M3 linked native execution.
- Ported a narrow LINK-02-style native executable path onto current `main`.
- `phpc compile <input.php> --emit-exe <output>` now emits linkable LLVM IR for the current supported string/integer echo literal surface, links it with `libphp_runtime.a` through `clang`, and writes an executable.
- The CLI test builds the runtime staticlib, produces a native executable for `fixtures/bootstrap/hello.php`, runs it, and compares stdout/stderr with `phpc run` and system PHP when available.
- This is execution plumbing for the supported literal echo denominator only; it is not broad native lowering, PHP-core, or WordPress progress.

## Files Changed

- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `crates/phpc_core/src/lib.rs`
- `docs/SUPPORT.md`
- `swarm/handoffs/LINK-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core linkable_ir_calls_runtime_echo_for_supported_literals`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass. Focused M3 CLI test produced and ran a native executable for `fixtures/bootstrap/hello.php`; full workspace tests passed 42 tests.

## Blockers

- Native executable emission only supports the current parser/compiler surface: string and integer echo literals.
- `--emit-asm` remains unimplemented.
- Broader M3 comparison needs a reusable native runner/differential harness once more lowering exists.

## Latest Commit

- Pending commit for current-main port.

## Next Suggested Slice

- Add a reusable test helper or CLI path that runs native executables and compares stdout, stderr, and exit status against `phpc run` for a small committed fixture set.
