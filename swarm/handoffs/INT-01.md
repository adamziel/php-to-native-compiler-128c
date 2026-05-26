# INT-01 Handoff

summary:
- Milestone: Integration / worker environment safety and gate hygiene.
- Narrow denominator: `scripts/verify-worker-env.sh` preflight validation for assigned lane worktree roots.
- Tightened worker environment verification so `PHPC_WORKTREE_ROOT` must exist as a directory even when branch or clean-worktree enforcement is not requested.
- Added a focused missing-worktree regression to `scripts/test-worker-env.sh`.
- Made `scripts/test-local-gate.sh` hermetic for synthetic `LOCAL-GATE` worker-env checks by unsetting inherited `PHPC_EXPECT_BRANCH`.
- No compiler/runtime behavior, PHP-core denominator, WordPress behavior, generated progress output, or native support claim changed.

files changed:
- `scripts/verify-worker-env.sh`
- `scripts/test-worker-env.sh`
- `scripts/test-local-gate.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 PHPC_REQUIRE_WORKER_ENV=1 PHPC_WORKTREE_ROOT=/home/ubuntu/phpc-worktrees/INT-01 PHPC_LANE_ID=INT-01 PHPC_EXPECT_BRANCH=lane/INT-01 scripts/verify-worker-env.sh`
- `scripts/test-local-gate.sh`
- `scripts/status-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused worker-env regression rejects a missing `PHPC_WORKTREE_ROOT`.
- PASS: live INT-01 worker environment preflight accepts the assigned lane branch and target dir.
- PASS: local gate regression remains green with hermetic synthetic worker-env checks.
- PASS: status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.

blockers:
- None for this integration-safety slice.

latest commit:
- `HEAD` after commit: Require existing worker worktree roots

next suggested slice:
- Add a status consistency check that queue rows owned by an integration lane with `verified` state have a matching handoff whose latest commit is not pending.
