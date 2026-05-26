summary: Tightened integration status hygiene for the M3 review queue. `scripts/status-gate.sh` now fails when `swarm/integration.md` keeps lanes with terminal Reject/Blocked decisions in the active priority lane list, preventing stale reviewed LINK candidates from being advertised as current integration work. Updated the LINK priority row to require a rebase or coherent handoff before further review.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`

pass/fail state: pass

blockers: none for this integration-safety slice. M3 linked native execution remains blocked on a rebased/coherent LINK candidate; do not count LINK-01, LINK-02, LINK-08, LINK-09, LINK-11, or LINK-12 as integrated M3 progress from the reviewed artifacts.

latest commit: branch HEAD for this slice (`Tighten integration priority status gate`)

next suggested slice: Add a queue/status check that completed review tasks have matching follow-up queue states, or review the next committed candidate only after it has a coherent handoff and focused verification.
