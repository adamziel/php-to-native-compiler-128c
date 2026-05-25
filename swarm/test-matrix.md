# Test Matrix

| Layer | Command | Current Status | Notes |
| --- | --- | --- | --- |
| Rust workspace | `cargo test` | passing | 6 tests passed on 2026-05-25 |
| CLI run | `cargo run -p phpc -- run fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| CLI compile IR | `cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir` | passing | Emits placeholder IR |
| PHP oracle | `php fixtures/bootstrap/hello.php` | passing | Printed `hello from phpc` |
| php-src `.phpt` | TBD | blocked | php-src not pinned |
| WordPress | TBD | blocked | WordPress not pinned |
