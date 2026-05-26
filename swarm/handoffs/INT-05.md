# INT-05 Handoff

## Summary

- Milestone: Integration / M2 runtime ABI safety.
- Added a focused gate that compares `php_runtime` exported `#[no_mangle] extern "C"` helpers with `docs/NATIVE_RUNTIME_ABI.md`'s `Existing exported helpers` list.
- Added a regression test that proves the gate rejects an undocumented runtime export.
- Wired the ABI documentation verifier into `scripts/local-gate.sh`.
- Narrow denominator: drift prevention for the current 7 exported runtime ABI helpers only; no new PHP/compiler behavior claimed.

## Files Changed

- `scripts/verify-runtime-abi-docs.sh`
- `scripts/test-runtime-abi-docs.sh`
- `scripts/local-gate.sh`
- `swarm/handoffs/INT-05.md`

## Tests Run

- `scripts/verify-runtime-abi-docs.sh`
- `scripts/test-runtime-abi-docs.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-int05 cargo test -p php_runtime`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-local-gate scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass. The runtime ABI documentation gate reports 7 exported helpers documented.

## Blockers

- None for this slice.

## Latest Lane Commit

- `7ede37c` Gate runtime ABI documentation drift.

## Integration Note

- Ported manually onto current `main` after local gate and M3/M5 integration work landed.

## Next Suggested Slice

- Extend the runtime ABI safety checks to validate documented status codes and value-kind constants against `php_runtime` once the next ABI helper family lands.
