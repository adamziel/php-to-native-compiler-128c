# Integration Log

## Policy

1. Review the diff before integrating.
2. Reject unrelated formatting and generated noise.
3. Run focused tests for the changed area.
4. Update progress and manifests.
5. Integrate in small batches.

## Current Integration Queue

Worker lane branches have mostly not committed yet, but several worktrees now contain reviewable dirty slices. Integration lanes should inspect these worktrees directly, require focused tests, and ask the producing lane to commit a coherent slice before merge unless the work is only a research artifact.

| Priority | Lane(s) | Area | Current artifact | Integration instruction |
| --- | --- | --- | --- | --- |
| P1 | `LINK-01`, `LINK-08` | M3 linked/native path | `crates/phpc_core/src/lib.rs` diffs | Review first because native executable support is still 0%; accept only a narrow compile/link/run slice with tests. |
| P1 | `LOW-03`, `LOW-04`, `LOW-07`, `LOW-12`, `LOW-15`, `MINE-02` | M4 parser/lowering | `crates/phpc_core/src/parser.rs` and related lib diffs | Deduplicate overlapping parser work; pick the smallest compatible token/parser improvement and require unsupported diagnostics tests. |
| P1 | `PHPT-01`, `PHPT-02`, `PHPT-03`, `PHPT-07`, `PHPT-09` | M5 `.phpt` harness | `crates/phpc_core/src/phpt.rs` and module exports | Compare against already-integrated minimal parser; keep only net-new parser/runner behavior with tests. |
| P2 | `WP-01`, `WP-04`, `WP-06`, `WP-12` | M6 WordPress harness | WordPress harness scripts and CLI entry changes | Prefer inventory/bootstrap harnesses that minimize general PHP blockers; reject WordPress-specific compiler hacks. |
| P2 | `ABI-03`, `ABI-07`, `ABI-11`, `SAPI-05` | M2/M7 runtime ABI and SAPI | `crates/php_runtime/src/lib.rs` and ABI docs | Review ownership semantics carefully; require runtime tests and avoid incompatible handle APIs. |
| P3 | `INT-07`, `DOC-02` | Coordination/tests/reporting | CLI tests and progress script diffs | Integrate only if they improve gates or reporting accuracy without duplicating the dedicated Pages reporter. |

Latest supervisor inventory: 2026-05-25T23:25:00Z. Expected 429/reconnect states are normal and should not block review.
