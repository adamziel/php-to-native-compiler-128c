# Blockers

| ID | Area | Blocker | Impact | Next Action |
| --- | --- | --- | --- | --- |
| B-001 | Tooling | Rust/Cargo/PHP/LLVM were missing at bootstrap | Resolved for baseline verification | Installed and verified versions on 2026-05-25 |
| B-002 | M5 | php-src is pinned but no `.phpt` runner exists | Static denominator only | PHPT lanes implement parser/runner |
| B-003 | M6 | WordPress 7.0 is pinned but no bootstrap runner exists | Entry files inventoried only | WP lanes implement runner and classify first blocker |
| B-004 | M3 | Linked executable path exists only for literal echo fixtures | M3 has first execution plumbing but not broad native lowering | Extend runner/differential coverage beyond the bootstrap echo denominator |
