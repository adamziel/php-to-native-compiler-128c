summary:
- M5 integration slice reviewed PHPT-02 source commit `9ce60ac` and accepted only the compatible typed expectation parser behavior.
- Added `PhptExpectationKind`, borrowed `PhptExpectation`, `EXPECTF`/`EXPECTREGEX` accessors, and ambiguous expectation rejection.
- Updated `PhptHarnessInput` to carry expectation kind/body while preserving already-integrated `SKIPIF`/`XFAIL` metadata behavior.
- Follow-up M5 integration ported INT-03 commit `537bb5e` by adding `FILEEOF` source metadata to the current main PHPT runner baseline, while preserving the existing exact-EXPECT runner.
- No `SKIPIF` execution, php-src runnable count, or native progress was added.

files changed:
- `crates/phpc_core/src/phpt.rs`
- `docs/SUPPORT.md`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 scripts/local-gate.sh`
- `git diff --check`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-fileeof CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-fileeof CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-phpt-fileeof CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`

pass/fail state:
- PASS: `scripts/local-gate.sh`; focused PHPT parser tests, status gate, and whitespace check completed cleanly on the lane.
- PASS: explicit `git diff --check`.
- PASS: current main focused PHPT tests, 22 passed after the `FILEEOF` port.
- PASS: current main full workspace `cargo test`, 57 passed.
- PASS: current main `scripts/local-gate.sh` and `git diff --check`.

blockers:
- The minimal `.phpt` runner exists only for `FILE` plus exact `EXPECT`; `SKIPIF` scripts are still not executed.
- `EXPECTF` and `EXPECTREGEX` are parsed and carried, but no output matcher executes them yet.
- `FILEEOF` is carried in `PhptHarnessInput`; the minimal `phpc run` `.phpt` evaluator remains limited to `FILE` plus exact `EXPECT`.

latest lane commit:
- `2601ca0` Integrate PHPT expectation variants.
- `537bb5e` Integrate PHPT FILEEOF source metadata.

integration note:
- Ported onto current `main` while preserving the richer main `scripts/local-gate.sh` and the exact-EXPECT PHPT runner.

next suggested slice:
- Build a non-executing parser classification pass over a tiny pinned php-src sample using `PhptHarnessInput`, without changing `swarm/php-core-manifest.json` runnable counts.
