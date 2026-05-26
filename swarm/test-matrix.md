# Test Matrix

| Layer | Command | Current Status | Notes |
| --- | --- | --- | --- |
| Rust workspace | `cargo test` | passing | 6 tests passed on 2026-05-25 |
| CLI run | `cargo run -p phpc -- run fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| CLI compile IR | `cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir` | passing | Emits placeholder IR |
| PHP oracle | `php fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| `.phpt` parser | `cargo test -p phpc_core phpt::tests` | passing | Minimal TEST/FILE/EXPECT/SKIPIF parser |
| Local coordination gate | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/supervisor-local-gate scripts/local-gate.sh` | passing | Runs non-generating status checks and diff hygiene |
| Status gate | `scripts/status-gate.sh` | passing | Non-mutating progress check plus manifest and WordPress inventory consistency |
| php-src `.phpt` | `find /home/ubuntu/phpc-external/php-src/php-src-PHP-8.3 -name '*.phpt'` | inventory only | 19,346 tests pinned; runner not implemented |
| WordPress | entrypoint file inventory under `/home/ubuntu/phpc-external/wordpress/wordpress` | inventory only | WordPress 7.0 pinned; bootstrap runner not implemented |
