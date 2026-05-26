# INT-02 Handoff

## Summary

- Milestone: M4 parser/lowering integration.
- Rejected and reverted the stale dashboard-target slice because current supervision is `100 workers + auditor`.
- Merged current `main` into `lane/INT-02` so the slice is based on the accepted linked-executable path and real `scripts/local-gate.sh`.
- Implemented a narrow general PHP parser/runtime fix: a final supported `echo` expression may omit the semicolon when immediately followed by the closing PHP tag, for example `<?php echo "closing\n" ?>`.
- Added coverage for parser behavior, `phpc run`, linkable native IR, and a linked native executable comparison.

## Files Changed

- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `swarm/handoffs/INT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc cli_emits_linked_native_executable_without_semicolon_before_closing_tag`
- `printf '%s' '<?php echo "hello" ?>' | php | od -An -tx1`
- `printf '%s' '<?php echo "closing\n" ?>' | php | od -An -tx1`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 cargo fmt --all`

## Pass/Fail State

- PASS: `phpc_core` test suite, 27 passed.
- PASS: focused native CLI regression for semicolonless final `echo` before `?>`.
- PASS: system PHP oracle bytes for `<?php echo "hello" ?>` are `68 65 6c 6c 6f`.
- PASS: system PHP oracle bytes for `<?php echo "closing\n" ?>` are `63 6c 6f 73 69 6e 67 0a`.
- PASS: `scripts/local-gate.sh`.
- PASS: `git diff --check`.
- FAIL/BLOCKED: `cargo fmt --all` cannot run because this toolchain has no `fmt` subcommand.

## Blockers

- Existing project blockers remain for broader PHP syntax, inline HTML after `?>`, full native lowering, and WordPress/bootstrap coverage.
- Observation for a separate runtime slice: a no-newline linked native executable fixture compiled successfully but emitted empty stdout, while `phpc run` and system PHP emitted `closing`. The committed native executable regression uses a newline fixture to keep this slice focused on closing-tag parsing rather than stdout flushing.

## Latest Commit

- `Allow final echo before closing tag` - current slice commit at lane `HEAD` after this handoff update.

## Next Suggested Slice

- Minimize and fix the linked-runtime stdout flushing/no-newline behavior in `php_runtime::phpc_echo`, then add a native executable test for `<?php echo "closing" ?>` without relying on newline output.
