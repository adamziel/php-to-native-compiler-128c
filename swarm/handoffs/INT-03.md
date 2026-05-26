summary:
- Started fresh from current `origin/main` on `lane/INT-03-fileeof-run`; the prior EXPECTF branch was stale/divergent and was not reused.
- Extended `run_phpt_with_phpc` to execute `FILEEOF` through the same path as `FILE` by using the existing `source_file()` selection.
- Preserved exact `EXPECT`, `EXPECTF`, xfail/unexpected-pass, unsupported `EXPECTREGEX`, and interpreter-error behavior.
- Added focused tests for `FILEEOF` execution with exact `EXPECT` and `EXPECTF`; existing ambiguous `FILE` plus `FILEEOF` rejection remains covered.
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
- PASS: focused PHPT tests, 33 passed.
- PASS: `git diff --check`.
- PASS: `scripts/local-gate.sh`; status checks, runtime ABI docs check, full workspace tests, and diff hygiene completed cleanly.

blockers:
- `EXPECTREGEX` still returns `PhptRunStatus::Unsupported`.
- `SKIPIF` scripts are still not executed.
- No php-src-scale runner or runnable-count update was added for the pinned 19,346-test denominator.
- This remains a `phpc run` harness slice and does not prove linked native execution.

latest commit if any:
- `a67cfe1` Run PHPT FILEEOF sources.
- `0a71d1b` Merge remote-tracking branch `origin/main` into `lane/INT-03-fileeof-run` after `origin/main` advanced with launcher observability and published-progress commits.

next suggested slice:
- Add the first narrow `SKIPIF` classification path without changing php-src runnable counts, or add explicit runner coverage for `FILEEOF` plus xfail/unexpected-pass if integration wants that denominator before SKIPIF.
