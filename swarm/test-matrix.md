# Test Matrix

| Layer | Command | Current Status | Notes |
| --- | --- | --- | --- |
| Rust workspace | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test` | passing | 42 tests passed on 2026-05-26: 12 runtime, 6 CLI, 24 core |
| Bootstrap toolchain | `cargo --version`; `rustc --version`; `php --version`; `clang --version` | passing | cargo 1.75.0; rustc 1.75.0; PHP 8.3.6 CLI; Ubuntu clang 18.1.3 |
| CLI run | `cargo run -p phpc -- run fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| CLI compile IR | `cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir` | passing | Emits placeholder IR |
| CLI linked native executable | `cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo` | passing | Builds `libphp_runtime.a`, emits a native executable for `fixtures/bootstrap/hello.php`, runs it, and compares output with `phpc run` and system PHP when available |
| CLI native output gates | `cargo test -p phpc --test bootstrap_cli cli_rejects_native_assembly_emission_until_m3_exists` | passing | Verifies `--emit-asm` still fails explicitly until assembly emission exists |
| CLI run argument hygiene | `cargo test -p phpc --test bootstrap_cli cli_run_rejects_trailing_arguments` | passing | `phpc run <input.php>` rejects trailing arguments instead of silently ignoring bad test invocations |
| CLI compile flag hygiene | `cargo test -p phpc --test bootstrap_cli cli_compile_rejects_conflicting_emit_flags` | passing | Conflicting compile emit flags fail explicitly with no stdout |
| PHP oracle | `php fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| `.phpt` parser | `cargo test -p phpc_core phpt::tests` | passing | Minimal TEST/FILE/EXPECT/EXPECTF/EXPECTREGEX/SKIPIF parser plus static metadata-carrying harness input |
| PHPT-03 committed candidate review | `git merge-base --is-ancestor 0cbd609 main`; inspect `main:crates/phpc_core/src/phpt.rs`; run `scripts/local-gate.sh` on current `main` | verified | Current `main` already contains accepted parser-level `SKIPIF`/`XFAIL` metadata behavior; standalone `ea96852` candidate should not be reapplied |
| Progress labels | `scripts/test-refresh-progress-labels.sh` | passing | Guards tool-neutral public status labels in generated progress output |
| WP-12 committed candidate review | `git merge-base --is-ancestor 348ad3b main`; compare WP-12 manifest hashes with `/home/ubuntu/phpc-external/wordpress/wordpress` | verified | Current `main` lacks the per-entry byte/SHA inventory; WP-12 evidence matches all five pinned WordPress 7.0 entrypoints and adds no compiler behavior |
| DOC-03 committed candidate review | `git merge-base --is-ancestor 4ebe2ab main`; inspect current `main` Pages reporter and refresh-progress label gate | rejected | DOC-03 is a stale lane-local generated progress refresh; current `main` has later reporter-owned published progress commits and a dedicated label-hygiene gate |
| Local coordination gate | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-local-gate scripts/local-gate.sh` | passing | Runs non-generating status checks and diff hygiene |
| Status gate | `scripts/status-gate.sh` | passing | Non-mutating progress check plus manifest, WordPress inventory, and integration-priority consistency |
| php-src `.phpt` | `find /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3 -name '*.phpt'` | inventory only | 19,346 tests pinned; runner not implemented |
| WordPress | entrypoint file inventory under `/home/ubuntu/phpc-external/wordpress/wordpress` | inventory only | WordPress 7.0 pinned; bootstrap runner not implemented |
