# PHPT-02 Handoff

## Summary

- Milestone: M5.
- Continued from the gh15905 pass now present on current `origin/main`; did not duplicate that accounting.
- Added one new already-supported passing `.phpt`: `Zend/tests/bug47596.phpt`.
- Recorded only executed evidence. The FILE body is a literal `echo "ok\n";` followed by line comments and a closing PHP tag, matching currently supported parser/runtime behavior.
- Updated the php-src runnable denominator from 3 to 4 of 19,346. The remaining 19,342 tests stay inventory-only.

## Files Changed

- `swarm/php-core-manifest.json`
- `docs/SUPPORT.md`
- `swarm/blockers.md`
- `swarm/test-matrix.md`
- `progress.md`
- `docs/progress.html`
- `swarm/handoffs/PHPT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/Zend/tests/bug47596.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/tests/basic/gh15905.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: `Zend/tests/bug47596.phpt` through `phpc_run`, `status=pass`, expected stdout length 2, actual stdout length 2.
- PASS: existing recorded `tests/basic/gh15905.phpt` through `phpc_run`, `status=pass`, expected stdout length 4, actual stdout length 4.
- PASS: focused `.phpt` core tests.
- PASS: status gate.
- PASS: `git diff --check`.

## Latest Commit

- This committed slice: `Record bug47596 php-src PHPT pass`

## Blockers

- The runner still ignores `INI` sections, lacks native `.phpt` execution, and has limited `SKIPIF`/`EXPECTREGEX` support.
- Include-based php-src tests should not be counted until `.phpt` execution has a real temp/input path and base directory.

## Next Suggested Slice

- Continue mining tiny already-supported `FILE`/`FILEEOF` plus exact `EXPECT`/`EXPECTF` tests, or add a base-path-aware `.phpt` execution mode before counting include-relative tests.
