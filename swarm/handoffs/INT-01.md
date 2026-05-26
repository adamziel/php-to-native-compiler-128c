summary: Integrated a fail-closed Pages reporter gate. `scripts/pages-reporter-loop.sh` now runs `scripts/status-gate.sh` after regenerating progress artifacts and before staging or committing them. Added `PAGES_REPORT_ONCE=1` test mode plus a focused failure-behavior test proving a broken manifest stops the reporter before `git commit`. Documented `scripts/status-gate.sh` as the canonical status gate in `swarm/test-matrix.md`.

files changed:
- `scripts/pages-reporter-loop.sh`
- `scripts/test-pages-reporter-gate.sh`
- `scripts/test-refresh-progress.sh`
- `scripts/test-status-gate.sh`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-pages-reporter-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-status-gate.sh`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/status-gate.sh`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/test-refresh-progress.sh`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-status-gate scripts/test-status-gate.sh`
- `git diff --check`

pass/fail state: pass

blockers: none

latest lane commit: `f5dc051 Gate pages reporter before publish`

integration note: Ported onto current `main` after the status-gate slice was already integrated and after newer manifest-sourced progress reporting landed.

next suggested slice: If the supervisor selects a canonical CI entrypoint, wire `scripts/local-gate.sh` there; keep php-src metadata and parser changes with the PHPT lanes.
