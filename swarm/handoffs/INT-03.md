summary:
- Started fresh from current `origin/main` on `lane/INT-03-skipif`; old landed INT-03 lane commits were not reused.
- Added a narrow PHPT `SKIPIF` classification path to `run_phpt_with_phpc`.
- `SKIPIF` scripts are executed through the current `phpc run` interpreter; output beginning with `skip` returns `PhptRunStatus::Skip`, empty or non-skip output continues to normal test execution, and unsupported `SKIPIF` scripts report interpreter errors.
- Preserved existing exact `EXPECT`, `EXPECTF`, xfail/unexpected-pass, unsupported `EXPECTREGEX`, `FILE`/`FILEEOF`, and main-file error behavior.
- Updated support, blocker, and test-matrix status without changing php-src runnable counts.

files changed:
- `crates/phpc_core/src/phpt.rs`
- `docs/SUPPORT.md`
- `swarm/blockers.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: focused PHPT tests, 36 passed.
- PASS: `git diff --check`.
- PASS: `scripts/local-gate.sh`; status checks, runtime ABI docs check, launcher observability check, full workspace tests, and diff hygiene completed cleanly.

blockers:
- `SKIPIF` support is limited to scripts already supported by `phpc run`; common php-src `if (...) die('skip ...')` forms still report interpreter errors until general PHP parsing/execution expands.
- `EXPECTREGEX` still returns `PhptRunStatus::Unsupported`.
- No php-src-scale runner or runnable-count update was added for the pinned 19,346-test denominator.
- This remains a `phpc run` harness slice and does not prove linked native execution.

latest commit if any:
- Main commit for this slice: `Classify PHPT SKIPIF output`.

next suggested slice:
- Add a narrow general parser/interpreter construct that unlocks common `SKIPIF` scripts, such as top-level `if` with literal boolean condition and `die`/`exit` string output, only if it can be kept general and covered by focused parser/interpreter and PHPT tests.
