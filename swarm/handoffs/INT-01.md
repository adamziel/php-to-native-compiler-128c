summary: Tightened the status gate for M5 accounting. `scripts/status-gate.sh` now requires `system_php`, `phpc_run`, and `native` `.phpt` pass/fail counts to be non-negative integers and to stay within `denominator.runnable`, preventing status from claiming more results than the pinned runnable subset supports.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`

pass/fail state: pass

blockers: none for this integration-safety slice; broader M5 remains blocked on an actual `.phpt` runner, so `denominator.runnable` remains `0`.

latest commit: lane/INT-01 HEAD, `Tighten phpt status gate accounting`

next suggested slice: Add a status gate for stale or inconsistent queue/review state, or continue reviewing committed integration candidates only when they include focused tests and coherent handoffs.
