summary:
- Integrated the compatible PHPT parser metadata behavior reviewed by INT-03 from source commit `ea96852`.
- Added static `SKIPIF` and `XFAIL` metadata accessors on top of the existing `.phpt` parser.
- Narrow denominator: pinned PHP-8.3 inventory remains 19,346 `.phpt` files; this slice is parser metadata only and does not execute `SKIPIF` or classify outcomes.

files changed:
- `crates/phpc_core/src/phpt.rs`
- `docs/SUPPORT.md`
- `swarm/integration.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-int03 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core phpt::tests`
- `SWARM_WORKER_COUNT=100 SWARM_LAUNCH_STAGGER_SECONDS=480 scripts/status-gate.sh`
- `git diff --check`
- `cargo fmt --check -p phpc_core`

pass/fail state:
- PASS: focused PHPT parser tests.
- PASS: status gate.
- PASS: `git diff --check`.
- BLOCKED: `cargo fmt --check -p phpc_core` failed because this environment has no `cargo fmt` subcommand.

blockers:
- No `.phpt` runner exists yet, so `SKIPIF` scripts are not executed and `XFAIL` is not applied to result classification.
- Formatting verification is limited until `rustfmt`/`cargo-fmt` is installed.

latest lane commit:
- `6033bee` Integrate PHPT metadata slice.

integration note:
- Ported manually onto current `main` to preserve newer swarm progress, status-gate, and reporter-gate changes.

next suggested slice:
- PHPT-04/system PHP oracle runner can consume `PhptTest::metadata()` and record actual skip/XFAIL classification without inflating native compiler progress.
