# Swarm Queue

States: `ready`, `assigned`, `blocked`, `review`, `integration`, `verified`, `rejected`.

| ID | State | Milestone | Owner | Task | Acceptance |
| --- | --- | --- | --- | --- | --- |
| Q-001 | ready | Coordination | INT-01 | Establish current repo state and progress baseline | `progress.md` reflects branch, HEAD, dirty state, tools |
| Q-002 | ready | Coordination | DOC-01 | Keep `progress.md`, `docs/progress.html`, and manifests current | Dashboard matches current evidence |
| Q-003 | ready | Tooling | INT-04 | Verify bootstrap toolchain and `cargo test` | Commands recorded with pass/fail |
| Q-004 | ready | M4 | LOW-01 | Replace toy parser with token stream foundation | Tests for PHP open tag, echo, literals, errors |
| Q-005 | ready | M2 | ABI-01 | Define runtime value handle ownership model | Runtime tests for null/free/invalid handles |
| Q-006 | ready | M3 | LINK-01 | Design and implement first linked native executable path | Produces executable for echo literal fixture |
| Q-007 | ready | M5 | PHPT-01 | Pin php-src checkout and inventory `.phpt` denominator | `swarm/php-core-manifest.json` has source and counts |
| Q-008 | ready | M5 | PHPT-02 | Implement minimal `.phpt` section parser | Tests for TEST/FILE/EXPECT/SKIPIF |
| Q-009 | ready | M6 | WP-01 | Pin WordPress source outside repo | `swarm/wordpress-manifest.json` has source/version/path |
| Q-010 | ready | M6 | WP-02 | Build first WordPress bootstrap runner design | First blocker classified as general compiler gap |
| Q-011 | ready | M1 | SEM-01 | Specify RPR/DMB/CCA mechanisms from scratch | Architecture note and test plan |
| Q-012 | ready | M4 | LOW-05 | Implement arrays roadmap and first fixtures | Failing tests or passing first slice |
| Q-013 | ready | M4 | LOW-07 | Implement functions/call frame roadmap and first fixtures | Failing tests or passing first slice |
| Q-014 | ready | M7 | SAPI-01 | Specify request/SAPI state model | General model documented with fixtures |
| Q-015 | ready | M7 | SEM-04 | Specify object/class model | General object lifecycle plan and first tests |
| Q-016 | integration | M3 | INT-01 | Review dirty LINK lane native execution slices | Coherent branch commit or rejection note in `swarm/integration.md` |
| Q-017 | integration | M4 | INT-02 | Deduplicate dirty LOW/MINE parser slices | One tested parser slice selected; conflicts/blockers recorded |
| Q-018 | integration | M5 | INT-03 | Review dirty PHPT harness slices against integrated parser | Net-new behavior committed or rejected with reason |
| Q-019 | integration | M6 | INT-04 | Review dirty WP harness slices for generality | Harness/blocker artifact accepted without WordPress-specific compiler hacks |
| Q-020 | integration | M2/M7 | INT-05 | Review dirty ABI/SAPI runtime slices | Ownership/API compatibility and runtime tests verified |
