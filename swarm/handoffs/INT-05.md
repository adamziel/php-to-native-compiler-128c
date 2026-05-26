# INT-05 Handoff

## Summary

- Time: 2026-05-26T01:11:00Z.
- Milestone: Integration / M2 runtime ABI safety.
- Fresh slice: extended the existing runtime ABI documentation verifier to require runtime-test annotations for documented value-handle ownership edge cases.
- Annotated each `docs/NATIVE_RUNTIME_ABI.md` ownership claim with the focused `php_runtime` test that covers it.
- Added regression coverage for a missing ownership test annotation and an annotation that names a nonexistent runtime test.
- Narrow denominator: documentation/test coverage linkage for the current 8 value-handle ownership claims only; no new PHP/compiler behavior claimed.

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

- Pass. The runtime ABI documentation gate reports 7 exported helpers, 6 constants, and ownership test annotations documented.

## Blockers

- None for this slice.

## Latest Commit

- Current lane HEAD: `6850d47 Gate runtime ABI ownership test annotations`

## Next Suggested Slice

- Add an integration-safety check that fails if a new `php_runtime` ABI test is added without being classified in the ABI handoff or test matrix.
