# PHPT Runner Handoff

## Summary

- Milestone: M5 PHP Core Harness.
- Added a minimal `phpc run` evaluator for parsed `.phpt` tests.
- The helper supports tests with `FILE` plus exact `EXPECT`, normalizes CRLF/CR output to LF, and classifies pass, fail, xfail, unexpected-pass, unsupported matcher, and interpreter-error outcomes.
- `SKIPIF` remains parsed metadata only and is not executed.
- `EXPECTF` and `EXPECTREGEX` are explicit unsupported matcher outcomes for this runner slice.

## Files Changed

- `crates/phpc_core/src/phpt.rs`
- `docs/SUPPORT.md`
- `swarm/handoffs/PHPT-RUN.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-run CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-run CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-run CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass. Focused PHPT tests passed 18 tests; full workspace tests passed 48 tests.

## Blockers

- No system PHP oracle runner exists yet.
- No native executable `.phpt` runner exists yet.
- `SKIPIF`, `EXPECTF`, `EXPECTREGEX`, stderr, exit status, `INI`, `ENV`, `ARGS`, and `CLEAN` are still unsupported.

## Latest Commit

- Pending commit for current-main port.

## Next Suggested Slice

- Add exact `EXPECT` reporting over a tiny committed `.phpt` fixture subset, comparing system PHP, `phpc run`, and native execution only for the current supported literal echo denominator.
