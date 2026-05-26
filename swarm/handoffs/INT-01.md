# INT-01 Handoff

summary:
- Milestone: Integration / coordination gate safety and status accuracy.
- Started cleanly from current `origin/main` on `lane/INT-01-fresh-0504`.
- Added a `scripts/status-gate.sh` check that fails when `swarm/test-matrix.md` documents `cargo test` or `cargo run` verification commands without an explicit `CARGO_TARGET_DIR`.
- Updated current test-matrix Cargo verification rows to include isolated target dirs, matching the local-gate and swarm worker hygiene rules.
- Extended `scripts/test-status-gate.sh` with a negative fixture for an unisolated test-matrix Cargo command.
- No compiler/runtime semantics, PHP-core denominator, WordPress behavior, launcher behavior, or generated progress output changed.

files changed:
- `scripts/status-gate.sh`
- `scripts/test-status-gate.sh`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `git fetch origin`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-status-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: focused status-gate regression rejects a test-matrix `cargo test` command that lacks `CARGO_TARGET_DIR`.
- PASS: local coordination gate, including status consistency, runtime ABI docs, progress launcher-log fixture, launcher observability, lane integration checker tests, worker-env tests, full locked workspace tests, and diff hygiene.
- PASS: full locked workspace tests reported 19 runtime, 11 CLI, and 76 core tests passing.

blockers:
- None for this integration-safety slice.

latest commit:
- This lane commit: `Gate test matrix cargo target docs`.

next suggested slice:
- Keep INT-01 focused on gate hygiene and status publication reliability; a useful follow-up would be a narrow status gate for generated progress freshness fields or launcher log fixture coverage.
