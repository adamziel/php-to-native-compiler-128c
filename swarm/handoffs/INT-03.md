summary:
- Started fresh from current `origin/main` on `lane/INT-03-fresh-0454`; previous INT-03 lane work was not merged or rebased.
- Tightened the worker environment preflight for clean-worktree enforcement.
- `scripts/verify-worker-env.sh` now validates that `PHPC_WORKTREE_ROOT` is a git worktree when `PHPC_REQUIRE_CLEAN_WORKTREE=1`, even if no expected branch is configured.
- Added a focused fixture proving non-git clean-required roots fail with the lane-specific diagnostic instead of raw git status output.
- No compiler, runtime, parser, PHPT, or WordPress semantics changed.

files changed:
- `scripts/verify-worker-env.sh`
- `scripts/test-worker-env.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-local-gate.sh`
- `PHPC_REQUIRE_WORKER_ENV=1 PHPC_LANE_ID=INT-03 PHPC_EXPECT_BRANCH=lane/INT-03-fresh-0454 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: focused worker-env fixture, including the new non-git clean-required root case.
- PASS: local-gate fixture still preserves opt-in worker preflight behavior.
- PASS: live INT-03 opt-in local gate, including full workspace `cargo test` with 106 Rust tests passing.

blockers:
- None for this coordination slice.
- `PHPC_REQUIRE_CLEAN_WORKTREE=1` remains opt-in and should only be enabled in launcher paths where dirty in-progress worker slices are not expected.

latest commit if any:
- Latest HEAD commit for this slice: `Tighten clean-worktree preflight`.

next suggested slice:
- Add launcher-side observability for which workers opt into `PHPC_REQUIRE_WORKER_ENV` and `PHPC_REQUIRE_CLEAN_WORKTREE`, without making clean-worktree enforcement mandatory for active implementation lanes.
