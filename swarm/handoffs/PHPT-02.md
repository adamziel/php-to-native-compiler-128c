# PHPT-02 Handoff

## Summary

- Milestone: M5.
- Preserved the current `origin/main` PHPT-02 reporting work and added one new executed php-src subset pass.
- New recorded passing test: `Zend/tests/multibyte/bug68665.phpt`.
- The FILE body reduces to supported single-quoted string echo plus a closing tag. The `EXTENSIONS` and `INI` metadata are present but do not affect the executed output under the current `phpc_run` runner.
- Updated the php-src runnable denominator from 4 to 5 of 19,346. The remaining 19,341 tests stay inventory-only.

## Files Changed

- `swarm/php-core-manifest.json`
- `docs/SUPPORT.md`
- `swarm/blockers.md`
- `swarm/test-matrix.md`
- `progress.md`
- `docs/progress.html`
- `swarm/handoffs/PHPT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo run -q -p phpc -- phpt-run /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3/Zend/tests/multibyte/bug68665.phpt`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/PHPT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: `Zend/tests/multibyte/bug68665.phpt` through `phpc_run`, `status=pass`, expected stdout length 6, actual stdout length 6.
- PASS: focused `.phpt` core tests, 38 tests.
- PASS: status gate.
- PASS: `git diff --check`.

## Latest Commit

- This committed slice: `Record bug68665 php-src PHPT pass`

## Blockers

- M5 remains blocked on broader `.phpt` semantics: INI, native execution, full SKIPIF, EXPECTREGEX matching, and many unsupported PHP language/runtime features.
- Do not count additional metadata-bearing PHPTs unless their executed FILE behavior is supported and verified.

## Next Suggested Slice

- Continue mining tiny already-supported pinned `.phpt` tests without counting unsupported probes, or add a focused result classification improvement that helps distinguish unsupported metadata from executed behavior.
