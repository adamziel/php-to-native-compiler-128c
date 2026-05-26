# INT-01 Handoff

summary:
- Milestone: Integration / coordination gate safety.
- Started cleanly from current `origin/main` on `lane/INT-01-fresh-0454`.
- Updated `scripts/local-gate.sh` to run `cargo test --locked`, so the coordination gate verifies the committed lockfile instead of allowing dependency resolution drift during lane checks.
- Extended `scripts/test-local-gate.sh` to prove the local gate invokes `cargo test --locked` after both the normal target-dir guard and the optional worker-env preflight.
- No compiler/runtime semantics, PHP-core denominator, WordPress behavior, launcher behavior, or generated progress output changed.

files changed:
- `scripts/local-gate.sh`
- `scripts/test-local-gate.sh`
- `swarm/handoffs/INT-01.md`

tests run:
- `git fetch origin`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-local-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: focused local-gate regression confirms the gate uses `cargo test --locked` and still stops before cargo when `CARGO_TARGET_DIR` or worker-env validation fails.
- PASS: local coordination gate, including status consistency, runtime ABI docs, progress launcher-log fixture, launcher observability, lane integration checker tests, worker-env tests, full locked workspace tests, and diff hygiene.
- PASS: full locked workspace tests reported 19 runtime, 11 CLI, and 76 core tests passing.

blockers:
- None for this integration-safety slice.

latest commit:
- This lane commit: `Run local gate cargo tests locked`.

next suggested slice:
- Keep INT-01 focused on gate hygiene and status publication reliability; candidate follow-up is a narrow status/test-matrix cleanup so documented Cargo verification commands consistently show an explicit `CARGO_TARGET_DIR`.
