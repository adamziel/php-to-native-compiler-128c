# INT-01 Handoff

summary: Tightened integration status hygiene for reviewed candidates. `scripts/status-gate.sh` now fails when any lane listed under `swarm/integration.md` Reviewed Candidates is still named literally in the active priority table. `swarm/integration.md` now uses follow-up lane groups for PHPT, WordPress, and coordination rows instead of re-advertising reviewed PHPT/WP/DOC candidates as active work.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/integration.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`

pass/fail state:
- PASS: focused status gate.
- PASS: status-gate regression test, including the new reviewed-lane priority-table negative case.
- PASS: local coordination gate, including status consistency, runtime ABI docs consistency, status-gate tests, progress-label tests, and `git diff --check`.

blockers:
- No blocker for this integration-safety slice.
- Broader project blockers remain unchanged: PHP core `.phpt` execution is still limited to `FILE` plus exact `EXPECT`, native execution is still limited to supported literal echo fixtures, and WordPress bootstrap remains blocked at the general PHP `define( 'WPINC', 'wp-includes' )` parser/compiler gap.

latest commit:
- main commit for this slice: `Tighten reviewed integration lane gate`

next suggested slice:
- Add a queue/status consistency check that ready queue items owned by integration lanes cannot duplicate already verified queue items or reviewed integration candidates by exact task wording.
