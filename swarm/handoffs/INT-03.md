summary:
- Improved M5 PHP core `.phpt` status accuracy and test-gate safety without adding compiler semantics or native `.phpt` execution.
- Added `phpc phpt-run <input.phpt>` as a narrow CLI probe over the existing `phpc run` library evaluator.
- Recorded the first named php-src runnable subset item, `tests/basic/001.phpt`, as executed through `phpc_run` and currently failing exact EXPECT comparison.
- Tightened `scripts/status-gate.sh` so nonzero `denominator.runnable` must match recorded `subset_runs`.

files changed:
- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `docs/progress.html`
- `progress.md`
- `scripts/refresh-progress.sh`
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/blockers.md`
- `swarm/php-core-manifest.json`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_runs_minimal_phpt_with_phpc_runner`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/tests/basic/001.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/verify-status-consistency.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused CLI probe test for the minimal `.phpt` runner report.
- RECORDED FAIL: pinned php-src `tests/basic/001.phpt` through `phpc_run` reports `status=fail`, expected stdout length 12, actual stdout length 11.
- PASS: status gate rejects runnable/subset-run accounting drift.
- PASS: full `phpc` CLI integration suite, 21 tests.
- PASS: local gate, including status/docs checks, runtime ABI docs, launcher observability, and workspace tests: 23 `php_runtime`, 21 `phpc` CLI integration, and 76 `phpc_core` tests.
- PASS: `git diff --check`.

blockers:
- No blocker for this integration-safety slice.
- M5 remains blocked on broad php-src progress: 19,345 of 19,346 pinned `.phpt` tests remain inventory-only, and the one recorded runnable subset test is not passing under `phpc_run`.
- The immediate semantic/accounting blocker is exact EXPECT newline policy: `tests/basic/001.phpt` expects 12 bytes including the trailing newline, while `phpc run` emits 11 bytes for the literal output.

latest commit if any:
- `HEAD` of `lane/INT-03` for this committed slice.

next suggested slice:
- Decide and test the `.phpt` exact EXPECT trailing-newline policy against PHP run-tests behavior, then either make `tests/basic/001.phpt` pass honestly or record a clearer unsupported/output-normalization classification before expanding the php-src runnable subset.
