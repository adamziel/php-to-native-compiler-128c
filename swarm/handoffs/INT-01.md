summary: Rebased INT-01 onto current `main` with the first M3 linked executable plumbing, then tightened integration/status hygiene around that new baseline. `swarm/queue.md` now marks Q-016 verified instead of active integration work, `swarm/integration.md` no longer advertises reviewed committed candidates or pre-M3 `--emit-exe` unsupported wording, and `scripts/status-gate.sh` now fails if those stale states return.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/integration.md`
- `swarm/queue.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass

blockers: none for this integration-safety slice. M3 has first linked executable plumbing only for the tested literal echo denominator; broader native lowering, php-src execution, and WordPress bootstrap remain separate work.

latest commit: branch HEAD for this slice (`Retire stale integration review status`)

next suggested slice: Add a queue/status consistency check that verified or rejected queue items cannot also be advertised in active integration prose or active candidate tables.
