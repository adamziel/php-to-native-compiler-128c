# Swarm Queue

States: `ready`, `assigned`, `blocked`, `review`, `integration`, `verified`, `rejected`.

| ID | State | Milestone | Owner | Task | Acceptance |
| --- | --- | --- | --- | --- | --- |
| Q-001 | ready | Coordination | INT-01 | Establish current repo state and progress baseline | `progress.md` reflects branch, HEAD, dirty state, tools |
| Q-002 | ready | Coordination | DOC-01 | Keep `progress.md`, `docs/progress.html`, and manifests current | Dashboard matches current evidence |
| Q-003 | verified | Tooling | INT-06 | Verify bootstrap toolchain and `cargo test` | Verified on current `main`: toolchain versions recorded and `cargo test` passed with 40 tests using `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-toolchain-status` |
| Q-004 | ready | M4 | LOW-01 | Replace toy parser with token stream foundation | Tests for PHP open tag, echo, literals, errors |
| Q-005 | ready | M2 | ABI-01 | Define runtime value handle ownership model | Runtime tests for null/free/invalid handles |
| Q-006 | verified | M3 | LINK-02 | Design and implement first linked native executable path | Verified on current `main`: `phpc compile <input.php> --emit-exe <output>` produces and runs a native executable for the bootstrap echo fixture |
| Q-007 | ready | M5 | PHPT-01 | Pin php-src checkout and inventory `.phpt` denominator | `swarm/php-core-manifest.json` has source and counts |
| Q-008 | ready | M5 | PHPT-02 | Implement minimal `.phpt` section parser | Tests for TEST/FILE/EXPECT/SKIPIF |
| Q-009 | ready | M6 | WP-01 | Pin WordPress source outside repo | `swarm/wordpress-manifest.json` has source/version/path |
| Q-010 | ready | M6 | WP-02 | Build first WordPress bootstrap runner design | First blocker classified as general compiler gap |
| Q-011 | ready | M1 | SEM-01 | Specify RPR/DMB/CCA mechanisms from scratch | Architecture note and test plan |
| Q-012 | ready | M4 | LOW-05 | Implement arrays roadmap and first fixtures | Failing tests or passing first slice |
| Q-013 | ready | M4 | LOW-07 | Implement functions/call frame roadmap and first fixtures | Failing tests or passing first slice |
| Q-014 | ready | M7 | SAPI-01 | Specify request/SAPI state model | General model documented with fixtures |
| Q-015 | ready | M7 | SEM-04 | Specify object/class model | General object lifecycle plan and first tests |
| Q-016 | verified | M3 | INT-01 | Review dirty LINK lane native execution slices | Completed: first LINK-02-style executable path is integrated on current `main`; obsolete LINK candidates are recorded in `swarm/integration.md` |
| Q-017 | integration | M4 | INT-02 | Deduplicate dirty LOW/MINE parser slices | One tested parser slice selected; conflicts/blockers recorded |
| Q-018 | integration | M5 | INT-03 | Review dirty PHPT harness slices against integrated parser | Net-new behavior committed or rejected with reason |
| Q-019 | integration | M6 | INT-04 | Review dirty WP harness slices for generality | Harness/blocker artifact accepted without WordPress-specific compiler hacks |
| Q-020 | integration | M2/M7 | INT-05 | Review dirty ABI/SAPI runtime slices | Ownership/API compatibility and runtime tests verified |
| Q-021 | verified | Coordination | INT-06 | Review committed `INT-02` status gate slice | Verified against current CLI; unsupported native-mode gate folded into main with handoff |
| Q-022 | verified | M5 | INT-03 | Review committed `PHPT-03` skip/XFAIL metadata slice | Verified stale as a standalone candidate: current `main` already contains accepted parser-level `SKIPIF`/`XFAIL` metadata behavior |
| Q-023 | verified | M6 | INT-04 | Review committed `WP-12` WordPress inventory slice | Verified as a net-new reproducible inventory improvement: pinned entrypoint byte counts and SHA-256 values match `/home/ubuntu/phpc-external/wordpress/wordpress` |
| Q-024 | rejected | Coordination | INT-07 | Review committed `DOC-03` dashboard slice | Rejected as stale generated progress refresh; current `main` Pages reporter and label-hygiene gate own this surface |
