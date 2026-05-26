# INT-01 Handoff

summary:
- Milestone: Integration / branch hygiene and review safety.
- Narrow denominator: `scripts/check-lane-integration.sh` dirty-worktree guard for lane candidates reviewed by raw commit SHA.
- Tightened the gate so a target commit checked out in any dirty worktree is classified `unsafe-to-merge`, matching the existing protection for branch refs.
- Kept already-integrated and no-net-diff candidates classifiable before the dirty-worktree scan so redirected test output in the integration worktree does not create false failures.
- No compiler/runtime behavior, PHP-core denominator, WordPress behavior, generated progress output, or broad native support claim changed.

files changed:
- `scripts/check-lane-integration.sh`
- `scripts/test-check-lane-integration.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `scripts/test-check-lane-integration.sh`
- `scripts/status-gate.sh`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 cargo test --locked -p phpc --test bootstrap_cli`

pass/fail state:
- PASS: focused lane integration regression rejects a raw commit checked out in a dirty lane worktree.
- PASS: live status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.
- PASS: focused CLI bootstrap suite passed, 20 tests.

blockers:
- None for this integration-safety slice.

latest commit:
- `HEAD` after commit: Tighten lane dirty commit integration check

next suggested slice:
- Add a focused status consistency check for generated progress branch/HEAD drift if the supervisor wants lane-local progress files to reflect the active worktree instead of the published main report.
