# INT-02 Handoff

## Summary

- Milestone: M4 parser/lowering integration.
- Rejected and reverted the stale dashboard-target slice because current supervision is `100 workers + auditor`.
- Merged current `main` into `lane/INT-02` so the slice is based on the accepted linked-executable path and real `scripts/local-gate.sh`.
- Implemented a narrow general PHP parser/runtime fix: a final supported `echo` expression may omit the semicolon when immediately followed by the closing PHP tag, for example `<?php echo "closing\n" ?>`.
- Added coverage for parser behavior, `phpc run`, linkable native IR, and a linked native executable comparison.
- Supervisor follow-up fixed the no-newline linked runtime output by flushing `php_runtime::phpc_echo` after writes, then added a native executable comparison for `<?php echo "closing" ?>`.

## Files Changed

- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/php_runtime/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc cli_emits_linked_native_executable_without_semicolon_before_closing_tag`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-closing-tag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_without_trailing_newline -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-closing-tag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_without_semicolon_before_closing_tag -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-closing-tag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-closing-tag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `printf '%s' '<?php echo "hello" ?>' | php | od -An -tx1`
- `printf '%s' '<?php echo "closing\n" ?>' | php | od -An -tx1`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 cargo fmt --all`

## Pass/Fail State

- PASS: `phpc_core` test suite, 27 passed.
- PASS: current `phpc_core` test suite, 33 passed after the main-branch port.
- PASS: focused native CLI regression for semicolonless final `echo` before `?>`.
- PASS: focused native CLI regression for no-newline linked stdout flushing.
- PASS: full workspace `cargo test`, 53 passed.
- PASS: system PHP oracle bytes for `<?php echo "hello" ?>` are `68 65 6c 6c 6f`.
- PASS: system PHP oracle bytes for `<?php echo "closing\n" ?>` are `63 6c 6f 73 69 6e 67 0a`.
- PASS: `scripts/local-gate.sh`.
- PASS: `git diff --check`.
- FAIL/BLOCKED: `cargo fmt --all` cannot run because this toolchain has no `fmt` subcommand.

## Blockers

- Existing project blockers remain for broader PHP syntax, inline HTML after `?>`, full native lowering, and WordPress/bootstrap coverage.
- No blocker remains for the observed no-newline linked stdout case; `php_runtime::phpc_echo` now flushes after writing.

## Latest Commit

- `Allow final echo before closing tag` - current slice commit at lane `HEAD` after this handoff update.
- Supervisor follow-up pending commit on `main`: flush linked runtime stdout for no-newline native output.

## Next Suggested Slice

- Continue mining small M4 parser/lowering slices, but keep each denominator tied to a PHP oracle and a native/interpreter comparison where the compiler surface supports it.
