# PHP-To-Native Compiler Swarm Progress

Last refreshed: 2026-05-26T04:11:57Z

## Current State

- Repository: `adamziel/php-to-native-compiler-128c`
- Branch: `main`
- Report base HEAD: `565cac2`
- Dirty entries: `0`
- tmux windows in `phpc-swarm`: `7`
- Supervised agents target: `100 workers`
- Interactive launch cadence: `480s`
- Staggered swarm launcher: `running`
- Latest launcher event: `2026-05-26T04:11:14Z launch: waiting 480s before starting Codex session 6/100.`
- Interactive Codex panes: `5`
- Active worker command processes: `0`
- Active agent slot cap: `interactive`
- Active slot locks: `0`
- Dirty lane worktrees preserved for review: `53`
- Worker state files: `101`
- Expected backend retry/rate-limit states: `101`
- GitHub Pages reporter: `running`

## Milestone Estimates

| Milestone | Denominator | Current | Status |
| --- | --- | ---: | --- |
| M1 COW shared mechanisms | RPR, DMB, CCA, regression matrix | 0% | Not started |
| M2 runtime value ABI | value kinds, ownership, and request state | 4% | Runtime-owned value handles plus request header storage integrated |
| M3 linked native execution | compile, link, run, compare | 2% | Linked executable path covers string, integer, boolean, and null echo literals |
| M4 native lowering | interpreter-supported constructs lowered or rejected | 4% | String, integer, boolean, and null echo literals; top-level string define/global no-output statements; explicit variable diagnostic |
| M5 PHP core .phpt harness | PHP-8.3 branch, 19,346 `.phpt` files | 6% | PHP-8.3 inventory pinned; minimal FILE/FILEEOF exact-EXPECT/EXPECTF runner plus limited SKIPIF classification integrated |
| M6 WordPress harness | pinned entrypoints/scenarios | 1% | WordPress 7.0 pinned; 5 entrypoints present; bootstrap check blocked in wp-settings.php |
| M7 object/SAPI/DB generality | required semantic families | 1% | Request header runtime state integrated; PHP header() wiring queued |
| M8 performance after correctness | truthful native benchmarks | 0% | Deferred |

## Latest Verification

- cargo available: `cargo 1.75.0`
- php available: `PHP 8.3.6 (cli) (built: Mar 20 2026 02:32:55) (NTS)`
- clang available: `Ubuntu clang version 18.1.3 (1ubuntu1)`

## Current Blockers
> # Blockers
> 
> | ID | Area | Blocker | Impact | Next Action |
> | --- | --- | --- | --- | --- |
> | B-001 | Tooling | Rust/Cargo/PHP/LLVM were missing at bootstrap | Resolved for baseline verification | Installed and verified versions on 2026-05-25 |
> | B-002 | M5 | php-src is pinned but `.phpt` execution only supports minimal `FILE`/`FILEEOF`, limited `SKIPIF`, and exact `EXPECT`/`EXPECTF` cases | Most PHP core tests remain inventory-only | Extend broad SKIPIF semantics, EXPECTREGEX, and php-src result classification |
> | B-003 | M6 | WordPress `wp-settings.php` bootstrap check reaches unsupported require/include execution | Bootstrap cannot reach includes, request setup, or entrypoint execution yet | Reduce require/include parsing and execution into general fixtures |
> | B-004 | M3 | Linked executable path exists only for literal echo fixtures | M3 has first execution plumbing but not broad native lowering | Extend runner/differential coverage beyond the bootstrap echo denominator |
