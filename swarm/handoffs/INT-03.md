summary:
- Started fresh from current `origin/main` on `lane/INT-03-fresh-0510`; previous INT-03 lane work was not merged or rebased.
- Tightened worker preflight branch hygiene.
- `scripts/verify-worker-env.sh` now rejects `PHPC_EXPECT_BRANCH` values that do not start with the active lane namespace, while allowing fresh branches such as `lane/INT-03-fresh-0510`.
- Added focused shell fixtures for non-lane expected branches, other-lane expected branches, valid but unchecked-out lane branches, and valid fresh lane branches.
- No compiler, runtime, parser, PHPT, or WordPress semantics changed.

files changed:
- `scripts/verify-worker-env.sh`
- `scripts/test-worker-env.sh`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-local-gate.sh`
- `PHPC_REQUIRE_WORKER_ENV=1 PHPC_LANE_ID=INT-03 PHPC_EXPECT_BRANCH=lane/INT-03-fresh-0510 CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused worker-env fixture, including expected-branch namespace diagnostics and fresh-branch success.
- PASS: local-gate fixture when rerun serially.
- PASS: live INT-03 opt-in local gate, including full workspace `cargo test` with 106 Rust tests passing.
- PASS: `git diff --check`.

blockers:
- None for this coordination slice.
- A first parallel run of `scripts/test-local-gate.sh` alongside another focused test hit an unrelated runtime-ABI-doc negative-fixture race through fixed `/tmp/phpc-runtime-abi-docs-test.*` files; rerunning the gate serially passed. A future safety slice should move those temp files under each test's `mktemp -d` directory.

latest commit if any:
- Latest HEAD commit for this slice: `Validate worker expected branch namespace`.

next suggested slice:
- Make `scripts/test-runtime-abi-docs.sh` use per-run temp output files instead of fixed `/tmp/phpc-runtime-abi-docs-test.out` and `.err`, then add a focused self-test or shellcheck-style assertion for parallel-safe temp paths.
