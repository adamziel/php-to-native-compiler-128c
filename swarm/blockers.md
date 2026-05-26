# Blockers

| ID | Area | Blocker | Impact | Next Action |
| --- | --- | --- | --- | --- |
| B-001 | Tooling | Rust/Cargo/PHP/LLVM were missing at bootstrap | Resolved for baseline verification | Installed and verified versions on 2026-05-25 |
| B-002 | M5 | php-src is pinned but `.phpt` execution only supports minimal `FILE` plus exact `EXPECT` cases | Most PHP core tests remain inventory-only | Extend SKIPIF, EXPECTF/EXPECTREGEX, FILEEOF execution, and php-src result classification |
| B-003 | M6 | WordPress `wp-settings.php` bootstrap check reaches unsupported PHP statement at the opening docblock | Bootstrap cannot reach includes, request setup, or entrypoint execution yet | Reduce comments/docblocks and `require` into general parser/compiler fixtures |
| B-004 | M3 | Linked executable path exists only for literal echo fixtures | M3 has first execution plumbing but not broad native lowering | Extend runner/differential coverage beyond the bootstrap echo denominator |
