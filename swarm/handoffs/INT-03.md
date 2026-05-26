summary:
- Improved M5 `.phpt` integration status accuracy by aligning the local `phpc_run` `.phpt` output comparison with php-src `run-tests.php`: normalize line endings, then trim expected and actual output before matching.
- Converted the pinned php-src recorded subset item, `tests/basic/001.phpt`, from a recorded fail to a passing `phpc_run` probe without adding native `.phpt` execution or broad PHP semantics.
- Updated support/status accounting so the denominator remains honest: 19,346 pinned `.phpt` files, 1 recorded runnable subset test passing under `phpc_run`, 19,345 inventory-only, 0 native `.phpt` runs.

files changed:
- `crates/phpc_core/src/phpt.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/SUPPORT.md`
- `docs/progress.html`
- `progress.md`
- `swarm/blockers.md`
- `swarm/php-core-manifest.json`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_runs_minimal_phpt_with_phpc_runner`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/tests/basic/001.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: `phpc_core` focused `.phpt` tests, 37 passed.
- PASS: focused CLI `.phpt` probe test.
- PASS: pinned php-src `tests/basic/001.phpt` through `phpc_run`, `status=pass`, expected stdout length 11, actual stdout length 11.
- PASS: status gate.
- PASS: local gate, including runtime ABI docs, launcher observability, workspace tests: 23 `php_runtime`, 21 `phpc` CLI integration, and 77 `phpc_core` tests.
- PASS: `git diff --check`.

blockers:
- No blocker for this integration-safety slice.
- M5 remains blocked on broad php-src progress: 19,345 of 19,346 pinned `.phpt` tests remain inventory-only, `EXPECTREGEX` matching is still unsupported, `SKIPIF` execution is limited to scripts supported by `phpc run`, and native `.phpt` execution is absent.

latest commit if any:
- This committed slice: `Align phpt output comparison with run-tests`

next suggested slice:
- Extend `.phpt` result classification for the next smallest php-src runnable denominator, preferably `EXPECTREGEX` support or a small manifest-backed subset run that records pass/fail/unsupported without claiming native progress.
