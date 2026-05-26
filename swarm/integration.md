# Integration Log

## Policy

1. Review the diff before integrating.
2. Reject unrelated formatting and generated noise.
3. Run focused tests for the changed area.
4. Update progress and manifests.
5. Integrate in small batches.

## Current Integration Queue

Several worker branches now contain reviewable dirty slices, and four lanes have committed handoff-backed work. Integration lanes should inspect these worktrees directly, require focused tests, and ask the producing lane to commit a coherent slice before merge unless the work is only a research artifact.

## Committed Lane Candidates

| Lane | Commit | Area | Artifact | Review instruction |
| --- | --- | --- | --- | --- |
| `INT-02` | `c10395c` | CLI gates | Native emission status tests and handoff | Integration reviewer should verify the test gate still matches current CLI behavior before merge. |
| `PHPT-03` | `ea96852` | `.phpt` harness | Skip/XFAIL metadata in `phpt.rs` plus handoff | Compare with the integrated minimal parser and keep only compatible metadata behavior with focused tests. |
| `WP-12` | `348ad3b` | WordPress inventory | Inventory scripts, manifest update, handoff | Prefer if it improves reproducible WordPress denominator; reject if it duplicates existing manifest generation without added checks. |
| `DOC-03` | `4ebe2ab` | Reporting | Progress/dashboard refresh and handoff | Review cautiously because the dedicated Pages reporter now owns this surface. |

## Reviewed Candidates

| Lane | Source Commit | Result | Evidence |
| --- | --- | --- | --- |
| `PHPT-03` | `ea96852` | Accepted compatible parser-level `SKIPIF`/`XFAIL` metadata into `INT-03`; no runner semantics or skip execution added. | `cargo test -p phpc_core phpt::tests` and `scripts/status-gate.sh` in INT-03 handoff. |

| Priority | Lane(s) | Area | Current artifact | Integration instruction |
| --- | --- | --- | --- | --- |
| P1 | `LINK-01`, `LINK-02`, `LINK-08`, `LINK-09`, `LINK-11` | M3 linked/native path | Core compile/link diffs | Review first because native executable support is still 0%; accept only a narrow compile/link/run slice with tests. |
| P1 | `LOW-03`, `LOW-04`, `LOW-07`, `LOW-12`, `LOW-15`, `LOW-16`, `MINE-02` | M4 parser/lowering | Parser and related lib diffs | Deduplicate overlapping parser work; pick the smallest compatible token/parser improvement and require unsupported diagnostics tests. |
| P1 | `PHPT-01`, `PHPT-02`, `PHPT-03`, `PHPT-06`, `PHPT-07`, `PHPT-09`, `PHPT-10`, `PHPT-13`, `PHPT-16` | M5 `.phpt` harness | `phpt.rs`, module exports, and harness diffs | Compare against already-integrated minimal parser; keep only net-new parser/runner behavior with tests. |
| P2 | `WP-01`, `WP-02`, `WP-04`, `WP-06`, `WP-12` | M6 WordPress harness | WordPress harness scripts, manifests, and CLI entry changes | Prefer inventory/bootstrap harnesses that minimize general PHP blockers; reject WordPress-specific compiler hacks. |
| P2 | `ABI-03`, `ABI-07`, `ABI-10`, `ABI-11`, `SAPI-03`, `SAPI-05`, `SAPI-06`, `SAPI-07` | M2/M7 runtime ABI and SAPI | Runtime/SAPI diffs and ABI docs | Review ownership semantics carefully; require runtime tests and avoid incompatible handle APIs. |
| P2 | `SEM-02`, `SEM-04`, `SEM-09` | M1/M7 semantics | Semantics design/test artifacts | Prefer shared COW/reference/object mechanisms over isolated behavior patches. |
| P3 | `AUD-01`, `DOC-02`, `DOC-03`, `INT-01`, `INT-06`, `INT-07` | Coordination/tests/reporting | Audit, CLI tests, and progress script diffs | Integrate only if they improve gates or reporting accuracy without duplicating the dedicated Pages reporter. |

Latest supervisor inventory: 2026-05-25T23:27:37Z. Expected 429/reconnect states are normal and should not block review.
