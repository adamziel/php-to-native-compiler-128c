# ABI-01 Handoff

## Summary

- Milestone: M2 Runtime ABI.
- Narrow denominator: ordered array handles with append/read ownership only.
- Added `PHPC_VALUE_KIND_ARRAY = 4`.
- Added `phpc_array_new() -> handle` for runtime-owned empty array values.
- Added `phpc_array_count(handle) -> len`.
- Added `phpc_array_append_value(array_handle, value_handle) -> status`; append clones the live source value into array-owned storage and does not transfer the caller's handle.
- Added `phpc_array_value_at(array_handle, index) -> handle`; reads clone the array slot into a new owned handle.
- Added ownership/error tests for array construct/free, clone-on-append, independent read handles after array free, and invalid/non-array/out-of-range behavior.
- Updated `docs/NATIVE_RUNTIME_ABI.md` with the new exports, constant, ownership rules, and test classifications.

## Files Changed

- `crates/php_runtime/src/lib.rs`
- `docs/NATIVE_RUNTIME_ABI.md`
- `swarm/handoffs/ABI-01.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 cargo test -p php_runtime`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 scripts/verify-runtime-abi-docs.sh`
- Attempted `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/ABI-01 cargo fmt --check`; blocked because `cargo fmt` is unavailable in this toolchain.

## Pass/Fail State

- Pass: `php_runtime` unit tests, 27 passed.
- Pass: runtime ABI docs verifier reports 24 exported helpers, 9 constants, 6 header results, 27 classified tests, and ownership annotations documented.
- Blocked: formatting check because `cargo fmt`/`rustfmt` are not installed.

## Blockers

- Formatting tooling is unavailable in this environment.
- This slice intentionally does not implement int/string keys, keyed writes, append-key behavior, `isset`/`empty`, COW, or reference slots.
- No compiler lowering uses the new array helpers yet.

## Latest Commit

- `Add runtime array value ABI` (current lane commit)

## Next Suggested Slice

- Add keyed array writes with int/string keys and ownership tests for copied keys and replaced values, or add a deterministic `compile --emit-ir` probe that declares/uses the new array helpers for a supported source shape.
