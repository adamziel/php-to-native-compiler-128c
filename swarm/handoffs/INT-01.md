# INT-01 Handoff

summary:
- Milestone: Integration / branch hygiene gate accuracy.
- Narrow denominator: `scripts/check-lane-integration.sh` classification of a lane branch that is checked out dirty in another worktree.
- Added an integration guard that rejects a target branch when any git worktree currently has that branch checked out with uncommitted or untracked changes.
- Added focused fixture coverage using a separate dirty `lane/dirty` worktree, and adjusted existing fixture checks to run candidate review from `main`.
- No compiler/runtime behavior, PHP-core denominator, WordPress behavior, launcher behavior, generated progress output, or broad native support claim changed.

files changed:
- `scripts/check-lane-integration.sh`
- `scripts/test-check-lane-integration.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-check-lane-integration.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/status-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused lane-integration regression rejected a checked-out dirty lane worktree as `unsafe-to-merge`.
- PASS: status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.

blockers:
- None for this integration-safety slice.

latest commit:
- `HEAD` after commit: Reject dirty checked-out integration lanes

next suggested slice:
- Keep INT-01 focused on existing gate accuracy. A useful follow-up is making `check-lanes-integration.sh` surface the dirty-worktree rejection in its batch summary with a dedicated fixture.
