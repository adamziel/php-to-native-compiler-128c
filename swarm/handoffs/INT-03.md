summary:
- Improved coordination/test safety for the worker environment preflight tests.
- `scripts/test-worker-env.sh` now places its synthetic worktree root and target root under the per-run `mktemp -d` directory instead of shared `/tmp/phpc-worktrees` and `/tmp/phpc-targets` paths.
- The test still asserts lane-specific `CARGO_TARGET_DIR` diagnostics, worktree-local target rejection, branch checks, and clean-worktree checks, but no longer depends on or collides with global `/tmp` fixture state.
- No compiler, runtime, parser, PHPT, or WordPress semantics changed.

files changed:
- `scripts/test-worker-env.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused worker-env fixture test.
- PASS: local gate, including status/docs checks and full workspace `cargo test --locked` with 118 Rust tests passing.
- PASS: `git diff --check`.

blockers:
- None for this coordination slice.

latest commit if any:
- Ported to `main` as `Isolate worker env test fixtures`.

next suggested slice:
- Audit remaining shell fixtures for hard-coded shared `/tmp` paths that can collide under parallel worker or local-gate runs.
