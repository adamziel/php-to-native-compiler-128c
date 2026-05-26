# Test Matrix

| Layer | Command | Current Status | Notes |
| --- | --- | --- | --- |
| Rust workspace | `cargo test` | passing | 6 tests passed on 2026-05-25 |
| CLI run | `cargo run -p phpc -- run fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| CLI compile IR | `cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir` | passing | Emits placeholder IR |
| CLI native output gates | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-int04 cargo test -p phpc --test bootstrap_cli` | passing | Verifies `--emit-asm` and `--emit-exe` fail explicitly until M3 implements real native output |
| PHP oracle | `php fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| `.phpt` parser | `cargo test -p phpc_core phpt::tests` | passing | Minimal TEST/FILE/EXPECT/SKIPIF parser plus static metadata-carrying harness input |
| PHPT-03 committed candidate review | `git merge-base --is-ancestor 0cbd609 main`; inspect `main:crates/phpc_core/src/phpt.rs`; run `scripts/local-gate.sh` on current `main` | verified | Current `main` already contains accepted parser-level `SKIPIF`/`XFAIL` metadata behavior; standalone `ea96852` candidate should not be reapplied |
| Progress labels | `scripts/test-refresh-progress-labels.sh` | passing | Guards tool-neutral public status labels in generated progress output |
| WP-12 committed candidate review | `git merge-base --is-ancestor 348ad3b main`; compare WP-12 manifest hashes with `/home/ubuntu/phpc-external/wordpress/wordpress` | verified | Current `main` lacks the per-entry byte/SHA inventory; WP-12 evidence matches all five pinned WordPress 7.0 entrypoints and adds no compiler behavior |
| Local coordination gate | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-local-gate scripts/local-gate.sh` | passing | Runs non-generating status checks and diff hygiene |
| Status gate | `scripts/status-gate.sh` | passing | Non-mutating progress check plus manifest and WordPress inventory consistency |
| php-src `.phpt` | `find /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3 -name '*.phpt'` | inventory only | 19,346 tests pinned; runner not implemented |
| WordPress | entrypoint file inventory under `/home/ubuntu/phpc-external/wordpress/wordpress` | inventory only | WordPress 7.0 pinned; bootstrap runner not implemented |
