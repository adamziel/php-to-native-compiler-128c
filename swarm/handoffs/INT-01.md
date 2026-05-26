summary: Reviewed current `main` after the PHPT `FILEEOF` and WordPress bootstrap-check integrations and tightened queue/status hygiene. `swarm/queue.md` now marks the PHPT parser slice and first WordPress bootstrap-check design slice as verified against the current integrated behavior instead of advertising stale ready work. `scripts/status-gate.sh` now fails if the queue regresses to pre-`FILEEOF` parser wording or claims the first WordPress bootstrap-check design is still ready after `swarm/wordpress-manifest.json` has `results.bootstrap_check`.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/queue.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass

blockers: none for this integration-safety slice. M5 still has only the minimal exact-EXPECT runnable subset, and M6 remains blocked at the general PHP `define( 'WPINC', 'wp-includes' )` parser gap.

latest commit: branch HEAD for this slice (`Retire stale PHPT and WordPress queue wording`)

next suggested slice: Add a queue/status consistency check that reviewed lanes in `swarm/integration.md` cannot remain listed by exact lane id in active priority rows once their accepted subset has landed.
