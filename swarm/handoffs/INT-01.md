# INT-01 Handoff

summary:
- Milestone: Integration / coordination gate safety.
- Started from current `origin/main` on `lane/INT-01-fresh-0443`; after `origin/main` advanced during verification, fast-forwarded the lane and reapplied the slice without destructive git commands.
- Added an early `CARGO_TARGET_DIR` requirement to `scripts/local-gate.sh` so local coordination gates cannot silently share Cargo build output across lanes.
- Extended `scripts/test-local-gate.sh` to prove the gate fails before invoking cargo when `CARGO_TARGET_DIR` is unset.
- No compiler/runtime semantics, PHP-core denominator, WordPress behavior, launcher behavior, or generated progress output changed.

files changed:
- `scripts/local-gate.sh`
- `scripts/test-local-gate.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `git fetch origin`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/test-local-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: focused local-gate regression rejects an unset `CARGO_TARGET_DIR` and confirms cargo is not invoked before the isolation check.
- PASS: local coordination gate, including status consistency, runtime ABI docs, progress launcher-log fixture, launcher observability, lane integration checker tests, worker-env tests, full workspace tests, and diff hygiene.
- PASS: full workspace tests reported 19 runtime, 11 CLI, and 76 core tests passing.

blockers:
- None for this integration-safety slice.

latest commit:
- This lane commit: `Require isolated target dir for local gate`

next suggested slice:
- Keep INT-01 focused on gate hygiene and status publication reliability; candidate follow-up is a small status-gate check that validates documented verification commands name an explicit `CARGO_TARGET_DIR`.
