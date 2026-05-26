# ABI-01 Handoff

## Summary

- Milestone: M2 Runtime ABI.
- Fresh slice: added signed integer value handles without duplicating the supervisor-integrated `phpc_value_clone` helper.
- Merged current `main` into `lane/ABI-01` first so the slice is based on the integrated clone ABI state.
- Implemented `phpc_integer_new(value) -> handle` for runtime-owned signed 64-bit integer values.
- Implemented `phpc_integer_value(handle, out_value) -> status` for typed integer reads.
- Extended `phpc_value_kind` with `PHPC_VALUE_KIND_INTEGER = 2`.
- Existing `phpc_value_clone` now clones integer handles through the shared `PhpValue: Clone` path.
- Added focused ownership/error tests for integer construct/read/free, invalid and non-integer reads, null output pointer rejection, and cloned integer ownership after source free.
- Updated `docs/NATIVE_RUNTIME_ABI.md` to document new exports, constants, ownership behavior, and test classifications.

## Files Changed

- `crates/php_runtime/src/lib.rs`
- `docs/NATIVE_RUNTIME_ABI.md`
- `swarm/handoffs/ABI-01.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p php_runtime`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass: `php_runtime` unit tests, 12 passed.
- Pass: `scripts/local-gate.sh`.
- Pass: `git diff --check`.

## Blockers

- No implementation blocker for this slice.
- Formatting tooling is still not provided by this environment (`cargo fmt`/`rustfmt` absent from prior ABI-01 run), but the requested gates passed.

## Latest Commit

- Pre-slice sync commit: `a1eb25c Merge branch 'main' into lane/ABI-01`.
- Integer ABI implementation commit: `0f01427 Add runtime integer value ABI`.

## Next Suggested Slice

- Add the next smallest scalar ABI family, likely booleans with constructor, typed read, kind/free/clone tests, and ABI docs.
- Defer arrays, references, and COW cells until the ABI can expose mutation/aliasing semantics without broad untested surface area.
