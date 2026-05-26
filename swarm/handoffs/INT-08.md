# INT-08 Handoff

## Summary

- Milestone: Integration / status accuracy.
- Narrow denominator: php-src recorded subset-run manifest integrity only.
- `scripts/verify-status-consistency.sh` now verifies each recorded `subset_runs[].path` stays under the pinned php-src checkout, names a `.phpt` file, and exists on disk.
- Added a focused negative fixture so stale/missing recorded subset-run paths fail with a precise diagnostic.
- No compiler/runtime behavior, native support claim, WordPress behavior, progress percentage, or php-src runnable count changed.

## Files Changed

- `scripts/verify-status-consistency.sh`
- `scripts/test-status-consistency.sh`
- `swarm/handoffs/INT-08.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-08 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-status-consistency.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-08 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-08 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

## Pass/Fail State

- PASS: focused status consistency fixture rejects a missing recorded php-src subset `.phpt` path.
- PASS: status gate completed with no diagnostics.
- PASS: full local gate completed, including status consistency, runtime ABI docs, status-gate fixtures, launcher/checker/worker-env fixtures, full locked workspace tests, doc tests, and diff hygiene.
- PASS: workspace tests reported 23 runtime tests, 21 CLI tests, and 77 core tests passing.

## Blockers

- None for this status-accuracy slice.

## Latest Commit

- This handoff is part of the INT-08 status-accuracy commit for this slice; final response records the exact commit hash after commit creation.

## Next Suggested Slice

- Add a status consistency check that recorded php-src subset-run stdout lengths match a fresh `phpc phpt-run` report for the pinned runnable subset, without increasing the runnable denominator.
