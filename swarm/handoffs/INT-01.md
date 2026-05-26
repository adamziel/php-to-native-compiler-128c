# INT-01 Handoff

summary:
- Milestone: Integration / status gate accuracy.
- Narrow denominator: `scripts/status-gate.sh` validation of `Latest Commit` handoff sections.
- Tightened the gate so unresolved pending markers are rejected in both `## Latest Commit` and lowercase `latest commit:` / `latest commit if any:` handoff styles.
- Added focused fixture coverage for a lowercase `latest commit: pending` handoff.
- Replaced the stale `SAPI-05` latest-commit placeholder with the concrete integrated commit already present in repository history.
- No compiler/runtime behavior, PHP-core denominator, WordPress behavior, launcher behavior, generated progress output, or broad native support claim changed.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/handoffs/SAPI-05.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/status-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused status-gate regression rejects lowercase unresolved latest-commit placeholders.
- PASS: live status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.

blockers:
- None for this integration-safety slice.

latest commit:
- `HEAD` after commit: Tighten latest commit handoff gate

next suggested slice:
- Add a focused handoff gate for stale archive-branch latest-commit references if that policy is accepted, as noted by INT-04.
