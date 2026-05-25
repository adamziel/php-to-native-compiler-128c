# PHP-To-Native Compiler Swarm Progress

Last refreshed: 2026-05-25T23:00:50Z

## Current State

- Repository: `adamziel/php-to-native-compiler-128c`
- Branch: `main`
- HEAD: `none`
- Dirty entries: `13`
- tmux windows in `phpc-swarm`: `0`

## Milestone Estimates

| Milestone | Denominator | Current | Status |
| --- | --- | ---: | --- |
| M1 COW shared mechanisms | RPR, DMB, CCA, regression matrix | 0% | Not started |
| M2 runtime value ABI | value kinds and ownership semantics | 1% | Bootstrap echo helper |
| M3 linked native execution | compile, link, run, compare | 0% | Queued |
| M4 native lowering | interpreter-supported constructs lowered or rejected | 1% | Echo literal scaffold |
| M5 PHP core .phpt harness | pinned php-src denominator | 0% | Queued |
| M6 WordPress harness | pinned entrypoints/scenarios | 0% | Queued |
| M7 object/SAPI/DB generality | required semantic families | 0% | Queued |
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
> | B-002 | M5 | php-src is not pinned | No `.phpt` denominator | PHPT-01 pin source and inventory |
> | B-003 | M6 | WordPress is not pinned | No WordPress denominator | WP-01 pin source outside repo |
> | B-004 | M3 | No linked executable path | Native compiler cannot prove execution | LINK-01 implement minimal path |
