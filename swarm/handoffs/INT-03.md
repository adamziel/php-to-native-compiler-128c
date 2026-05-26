summary:
- Started fresh from current `origin/main` on `lane/INT-03-fresh-0519`; previous INT-03 lane work was not merged or rebased.
- Fixed a progress/test publication reliability issue in `scripts/test-runtime-abi-docs.sh`.
- The runtime ABI docs test now captures expected-failure stdout/stderr under its per-run `mktemp -d` directory instead of fixed `/tmp/phpc-runtime-abi-docs-test.*` files.
- Added an inline guard that fails if those capture paths ever move outside the per-run temp directory.
- No compiler, runtime, parser, PHPT, or WordPress semantics changed.

files changed:
- `scripts/test-runtime-abi-docs.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `scripts/test-runtime-abi-docs.sh` twice in parallel.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-local-gate.sh`
- `PHPC_REQUIRE_WORKER_ENV=1 PHPC_LANE_ID=INT-03 PHPC_EXPECT_BRANCH=lane/INT-03-fresh-0519 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: two concurrent `scripts/test-runtime-abi-docs.sh` runs completed without output-file collision.
- PASS: local-gate fixture.
- PASS: live INT-03 opt-in local gate, including full workspace `cargo test --locked` with 108 Rust tests passing.
- PASS: `git diff --check`.

blockers:
- None for this coordination slice.

latest commit if any:
- Latest HEAD commit for this slice: `Isolate runtime ABI doc test output`.

next suggested slice:
- Audit other shell negative-fixture tests for fixed `/tmp` capture files or shared state that could make parallel gate runs flaky.
