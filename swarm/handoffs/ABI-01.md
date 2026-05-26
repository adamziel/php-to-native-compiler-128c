# ABI-01 Handoff

## Summary

- Milestone: M2 Runtime ABI.
- Ported only the current-main-safe boolean ABI from `lane/ABI-01`; current `main` already had the integer handle family.
- Implemented `phpc_boolean_new(value) -> handle` for runtime-owned boolean values using C-style truthiness.
- Implemented `phpc_boolean_value(handle, out_value) -> status` for typed boolean reads.
- Extended `phpc_value_kind` with `PHPC_VALUE_KIND_BOOLEAN = 3`.
- Existing `phpc_value_clone` now clones boolean handles through the shared `PhpValue: Clone` path.
- Added focused ownership/error tests for boolean construct/read/free, invalid and non-boolean reads, null output pointer rejection, and cloned boolean ownership after source free.
- Updated `docs/NATIVE_RUNTIME_ABI.md` to document new exports, constants, ownership behavior, and test classifications.

## Files Changed

- `crates/php_runtime/src/lib.rs`
- `docs/NATIVE_RUNTIME_ABI.md`
- `swarm/handoffs/ABI-01.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-abi-boolean CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p php_runtime`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-runtime-abi-docs CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-runtime-abi-docs.sh`
- `git diff --check`

## Pass/Fail State

- Pass: `php_runtime` unit tests, 23 passed.
- Pass: runtime ABI docs verifier reports 20 exported helpers, 8 constants, 23 classified tests, and ownership annotations documented.
- Pass: `git diff --check`.

## Blockers

- No implementation blocker for this slice.
- Formatting tooling is still not provided by this environment (`cargo fmt`/`rustfmt` absent from prior ABI-01 run), but the requested gates passed.

## Latest Commit

- Ported from `25cbc5a Add runtime boolean value ABI` and `86c95f6 Update ABI-01 boolean handoff`.

## Next Suggested Slice

- Add the next smallest scalar ABI family or conversions only when the ownership and typed-read behavior can be covered with similarly focused tests.
- Defer arrays, references, and COW cells until the ABI can expose mutation/aliasing semantics without broad untested surface area.
