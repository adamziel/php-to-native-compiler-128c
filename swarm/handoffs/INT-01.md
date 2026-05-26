# INT-01 Handoff

summary: Started a fresh slice from current `origin/main` on branch `lane/INT-01-require-diag`. Added a precise parser diagnostic for unsupported `require`, `require_once`, `include`, and `include_once` statements without implementing include execution or changing runnable counts. The WordPress bootstrap check now classifies the pinned blocker as unsupported general PHP require execution instead of a generic unsupported-statement snippet.

files changed:
- `crates/phpc_core/src/parser.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/WORDPRESS_COMPATIBILITY.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-require-diag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core include`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-require-diag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core parser::tests`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-require-diag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-require-diag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01-require-diag CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: parser tests cover precise `require` and `include_once` unsupported diagnostics plus keyword-prefix protection for `include_path`.
- PASS: focused WordPress bootstrap CLI test expects the new require diagnostic.
- PASS: real pinned WordPress bootstrap check reports all five entrypoints present and blocks with `unsupported require statement: include/require execution is not implemented`.
- PASS: local coordination gate, including status consistency, runtime ABI docs, launcher observability, full workspace tests, and diff hygiene. Full workspace tests reported 19 runtime, 11 CLI, and 73 core tests passing.

blockers:
- No blocker for this diagnostic slice.
- WordPress bootstrap remains blocked on general PHP require/include execution.
- This slice intentionally does not parse include expressions, resolve constants, read files, execute included PHP, or change php-src `.phpt` runnable counts.

latest commit:
- Branch HEAD for this slice: `Classify unsupported include statements`

next suggested slice:
- Either implement a narrow, general require/include statement model for literal or constant/string-concat paths with execution tests, or add PHPT `SKIPIF` classification without increasing runnable denominators.
