summary:
- Started fresh from `origin/main` on `lane/INT-03-expectf` instead of building on stale `lane/INT-03` mini-runner commits.
- Extended the existing `run_phpt_with_phpc` / `PhptRunStatus` model with `EXPECTF` matching while preserving exact `EXPECT` and `EXPECTREGEX` unsupported behavior.
- Added focused tests for `EXPECTF` pass, fail, xfail, and unexpected-pass classification.
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

pass/fail state:
- PASS: focused PHPT tests, 26 passed.
- PASS: `git diff --check`.

blockers:
- `EXPECTREGEX` still returns `PhptRunStatus::Unsupported`.
- `SKIPIF` scripts are still not executed.
- The runner still requires `FILE`; `FILEEOF` is carried in harness input but is not executed by `run_phpt_with_phpc`.
- No php-src-scale runner or runnable-count update was added for the pinned 19,346-test denominator.
- This remains a `phpc run` harness slice and does not prove linked native execution.

latest commit if any:
- Pending until this handoff and slice are committed.

next suggested slice:
- Add `FILEEOF` execution to `run_phpt_with_phpc` using the existing `PhptFileKind` model, with focused tests proving exact `EXPECT`, `EXPECTF`, xfail, and existing `FILE` behavior remain unchanged.
