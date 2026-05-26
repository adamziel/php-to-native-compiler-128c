summary: Integrated a CI-facing status gate for progress and manifest accuracy. `scripts/refresh-progress.sh --check` now renders reports to temporary files and validates their shape without rewriting `progress.md` or `docs/progress.html`. `scripts/status-gate.sh` validates PHP core and WordPress manifest denominators and source metadata.

files changed:
- `scripts/refresh-progress.sh`
- `scripts/status-gate.sh`
- `scripts/test-refresh-progress.sh`
- `scripts/test-status-gate.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/refresh-progress.sh --check`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/test-refresh-progress.sh`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/status-gate.sh`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-status-gate scripts/test-status-gate.sh`
- `git diff --check`

pass/fail state: pass

blockers: none

latest lane commit: `1c43159 Add status gate for manifest accuracy`

integration note: Ported onto current `main` instead of cherry-picking because current `main` had newer staggered-launcher progress fields.

next suggested slice: Add `scripts/status-gate.sh` to the normal integration gate runner once the canonical CI entrypoint is selected.
