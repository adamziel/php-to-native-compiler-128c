summary:
- Started fresh from current `origin/main` on `lane/INT-03-fresh-0504`; previous INT-03 lane work was not merged or rebased.
- Tightened worker preflight flag validation for integration safety.
- `scripts/verify-worker-env.sh` now rejects non-boolean `PHPC_ALLOW_WORKTREE_LANE_MISMATCH` and `PHPC_REQUIRE_CLEAN_WORKTREE` values instead of silently treating typos as disabled checks.
- Added focused shell fixtures for both invalid flag cases.
- No compiler, runtime, parser, PHPT, or WordPress semantics changed.

files changed:
- `scripts/verify-worker-env.sh`
- `scripts/test-worker-env.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-local-gate.sh`
- `PHPC_REQUIRE_WORKER_ENV=1 PHPC_LANE_ID=INT-03 PHPC_EXPECT_BRANCH=lane/INT-03-fresh-0504 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused worker-env fixture, including invalid boolean flag diagnostics.
- PASS: local-gate fixture still preserves opt-in worker preflight behavior.
- PASS: live INT-03 opt-in local gate, including full workspace `cargo test` with 106 Rust tests passing.
- PASS: `git diff --check`.

blockers:
- None for this coordination slice.
- Clean-worktree enforcement remains opt-in and should not be made mandatory for active implementation lanes without a separate launcher policy slice.

latest commit if any:
- Latest HEAD commit for this slice: `Validate worker preflight booleans`.

next suggested slice:
- Add launcher-side observability for workers that opt into `PHPC_REQUIRE_WORKER_ENV` and any future clean-worktree policy, keeping enforcement explicit in status output.
