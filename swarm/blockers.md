# Blockers

| ID | Area | Blocker | Impact | Next Action |
| --- | --- | --- | --- | --- |
| B-001 | Tooling | Rust/Cargo/PHP/LLVM were missing at bootstrap | Resolved for baseline verification | Installed and verified versions on 2026-05-25 |
| B-002 | M5 | php-src is pinned but only `tests/basic/001.phpt`, `tests/output/ob_001.phpt`, `tests/basic/gh15905.phpt`, and `Zend/tests/bug47596.phpt` have recorded passing subset runs under `phpc_run`; `.phpt` execution only supports minimal `FILE`/`FILEEOF`, limited `SKIPIF`, exact `EXPECT`/`EXPECTF` cases, and base-path-aware literal include/require resolution | 19,342 PHP core tests remain inventory-only and native `.phpt` execution is still absent | Extend broad SKIPIF semantics, EXPECTREGEX, php-src result classification, and native `.phpt` runner coverage |
| B-003 | M6 | WordPress `wp-settings.php` bootstrap check reaches unsupported non-literal `require` expression after literal-path require/include support | Bootstrap cannot evaluate `ABSPATH . WPINC . '/version.php'`, so request setup and entrypoint execution remain blocked | Reduce constant expression/path evaluation into general fixtures |
| B-004 | M3 | Linked executable path exists only for literal echo fixtures | M3 has first execution plumbing but not broad native lowering | Extend runner/differential coverage beyond the bootstrap echo denominator |
