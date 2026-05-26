# PHP-To-Native Compiler Swarm Progress

Last refreshed: 2026-05-26T00:08:50Z

## Current State

- Repository: `adamziel/php-to-native-compiler-128c`
- Branch: `main`
- Report base HEAD: `3c2bf39`
- Dirty entries: `0`
- tmux windows in `phpc-swarm`: `22`
- Worker loops: `20`
- Active `codex exec` processes: `38`
- Active Codex slot cap: `19`
- Active slot locks: `19`
- Dirty lane worktrees preserved for review: `59`
- Worker state files: `101`
- Expected backend retry/rate-limit states: `101`
- GitHub Pages reporter: `running`

## Milestone Estimates

| Milestone | Denominator | Current | Status |
| --- | --- | ---: | --- |
| M1 COW shared mechanisms | RPR, DMB, CCA, regression matrix | 0% | Not started |
| M2 runtime value ABI | value kinds and ownership semantics | 3% | Runtime-owned null and binary-string handles integrated |
| M3 linked native execution | compile, link, run, compare | 0% | Queued |
| M4 native lowering | interpreter-supported constructs lowered or rejected | 2% | String and integer echo literals; explicit variable diagnostic |
| M5 PHP core .phpt harness | pinned php-src denominator | 2% | PHP-8.3 inventory pinned and minimal .phpt parser integrated |
| M6 WordPress harness | pinned entrypoints/scenarios | 1% | WordPress 7.0 pinned; five entrypoints present; runner queued |
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
> | B-002 | M5 | php-src is pinned but no `.phpt` runner exists | Static denominator only | PHPT lanes implement parser/runner |
> | B-003 | M6 | WordPress 7.0 is pinned but no bootstrap runner exists | Entry files inventoried only | WP lanes implement runner and classify first blocker |
> | B-004 | M3 | No linked executable path | Native compiler cannot prove execution | LINK-01 implement minimal path |
