# INT-05 Handoff

## Summary

- Time: 2026-05-26T01:11:00Z.
- Milestone: Integration / M2 runtime ABI safety.
- Fresh slice: added a `Runtime ABI Test Classification` section to `docs/NATIVE_RUNTIME_ABI.md`.
- Extended the runtime ABI docs verifier to require every current `php_runtime` unit test to be classified in the ABI docs and to reject stale classifications.
- Added regression coverage for a missing runtime ABI test classification and a stale classification.
- Narrow denominator: classification coverage for the current 5 `php_runtime` ABI tests only; no new PHP/compiler behavior claimed.

## Files Changed

- `docs/NATIVE_RUNTIME_ABI.md`
- `scripts/verify-runtime-abi-docs.sh`
- `scripts/test-runtime-abi-docs.sh`
- `swarm/handoffs/INT-05.md`

## Tests Run

- `scripts/verify-runtime-abi-docs.sh` - pass
- `scripts/test-runtime-abi-docs.sh` - pass
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-05 cargo test -p php_runtime` - pass, 5 tests
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-05 scripts/local-gate.sh` - pass
- `git diff --check` - pass

## Pass/Fail State

- Pass. The runtime ABI documentation gate reports 7 exported helpers, 6 constants, 5 classified tests, and ownership test annotations documented.

## Blockers

- None for this slice.

## Latest Commit

- Current lane HEAD: `d15ca37 Classify runtime ABI tests in docs gate`

## Next Suggested Slice

- Split `scripts/verify-runtime-abi-docs.sh` into smaller verifier functions once the next runtime ABI family adds more sections, to keep diagnostics reviewable.
