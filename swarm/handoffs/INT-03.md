summary:
- Improved M5 PHP core status accuracy without changing compiler, runtime, parser, PHPT execution, or WordPress behavior.
- Updated `swarm/php-core-manifest.json` so the pinned 19,346-test php-src denominator still reports zero committed php-src runnable tests, but no longer falsely says that no `.phpt` runner exists.
- Added a `scripts/status-gate.sh` guard and focused regression test to reject the obsolete "No .phpt runner is implemented yet" blocker wording.

files changed:
- `swarm/php-core-manifest.json`
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/verify-status-consistency.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused status-gate regression for stale PHP core runner wording.
- PASS: status gate and status consistency checks against the pinned 19,346 `.phpt` denominator.
- PASS: local gate, including worker env, status/docs checks, runtime ABI docs, launcher observability, and workspace tests: 23 `php_runtime`, 20 `phpc` CLI integration, and 76 `phpc_core` tests.
- PASS: `git diff --check`.

blockers:
- No blocker for this coordination slice.
- M5 remains blocked from increasing `denominator.runnable` until an actual committed php-src `.phpt` subset run records concrete pass/fail/skip/xfail results.

latest commit if any:
- `cd23f4a` Tighten php core manifest status gate

next suggested slice:
- Run and record a tiny named php-src `.phpt` subset through the existing minimal runner, then update `swarm/php-core-manifest.json` runnable/result counts only for tests that actually executed.
