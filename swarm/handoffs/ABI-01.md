# ABI-01 Handoff

## Summary

- Milestone: M2 Runtime ABI.
- Implemented `phpc_value_clone(handle) -> handle` for the runtime value ABI.
- The helper returns a new owned runtime handle for live values and invalid handle `0` for invalid, unknown, or already-freed handles.
- Added ownership tests covering invalid clone attempts, independent null-handle lifetime, and cloned binary strings that remain valid after freeing the source handle.
- Updated `docs/NATIVE_RUNTIME_ABI.md` to document the clone helper and its ownership contract.

## Files Changed

- `crates/php_runtime/src/lib.rs`
- `docs/NATIVE_RUNTIME_ABI.md`
- `swarm/handoffs/ABI-01.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p php_runtime`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `git diff --check`

## Pass/Fail State

- Pass: `php_runtime` unit tests, 8 passed.
- Pass: workspace tests, 27 passed.
- Pass: `git diff --check`.
- Tooling note: `cargo fmt --check` could not run because this Cargo install has no `fmt` subcommand; standalone `rustfmt` is also not installed.

## Blockers

- No implementation blocker for this slice.
- Formatting blocker: rustfmt tooling is absent in this environment.

## Latest Commit

- Implementation commit: `0c07762 Add runtime value clone ABI`.

## Next Suggested Slice

- Add the next small M2 scalar ABI helper, such as integer value handles with constructor/kind/free/clone tests, or introduce the first cell/reference handle only if ownership semantics can be kept equally narrow and tested.
