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
| `PHPT-03` | `ea96852` | `.phpt` harness | Skip/XFAIL metadata in `phpt.rs` plus handoff | Reviewed by `INT-06`: stale as a standalone candidate because current `main` already contains parser-level `SKIPIF`/`XFAIL` metadata and harness input support. |
| `WP-12` | `348ad3b` | WordPress inventory | Inventory scripts, manifest update, handoff | Reviewed by `INT-06`: verified as net-new reproducible inventory evidence; current `main` manifest lacks per-entry byte counts, SHA-256 values, and inventory unit tests. |
| `DOC-03` | `4ebe2ab` | Reporting | Progress/dashboard refresh and handoff | Reviewed by `INT-06`: rejected as stale generated progress output and outdated queue assignment; current `main` Pages reporter and label-hygiene gate own this surface. |

## Reviewed Candidates

| Lane | Source Commit | Result | Evidence |
| --- | --- | --- | --- |
| `PHPT-03` | `ea96852` | Accepted compatible parser-level `SKIPIF`/`XFAIL` metadata into `INT-03`; standalone candidate now verified stale and should not be reapplied. | `cargo test -p phpc_core phpt::tests` and `scripts/status-gate.sh` in INT-03 handoff; `git merge-base --is-ancestor 0cbd609 main` returned 0 during INT-06 review. |
| `PHPT-02` | `9ce60ac` | Accepted compatible typed `EXPECTF`/`EXPECTREGEX` parsing and ambiguous expectation rejection; skipped stale parser scaffolding and did not add execution semantics. | `cargo test -p phpc_core phpt::tests`, `scripts/local-gate.sh`, and `git diff --check` in INT-03 integration. |
| `WP-12` | `348ad3b` | Verified as a net-new reproducible inventory improvement; acceptable for integration as status/harness evidence only. | `git merge-base --is-ancestor 348ad3b main` returned 1; current `main:swarm/wordpress-manifest.json` has only the pinned entrypoint list, while WP-12 records all five entrypoint byte counts and SHA-256 values matching `/home/ubuntu/phpc-external/wordpress/wordpress`. |
| `DOC-03` | `4ebe2ab` | Rejected; do not apply the standalone generated dashboard refresh. | `git merge-base --is-ancestor 4ebe2ab main` returned 1; current `main` has later `Update published swarm progress` commits, `scripts/pages-reporter-loop.sh`, and `scripts/test-refresh-progress-labels.sh`, while DOC-03 refreshes `progress.md`/`docs/progress.html` from `lane/DOC-03` and assigns `Q-002` to DOC-03. |

## Integration Decisions

| Date | Lane | Commit | Decision | Evidence | Follow-up |
| --- | --- | --- | --- | --- | --- |
| 2026-05-26 | `LINK-01` | `d0257ee` | Reject as-is; request rebase and resubmission | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compiles_links_and_runs_bootstrap_echo` passed in the LINK-01 worktree, proving the slice has a real compile/link/run path for the bootstrap echo fixture. `git merge-tree $(git merge-base HEAD lane/LINK-01) HEAD lane/LINK-01` from INT-01 reports conflicts in `crates/phpc/tests/bootstrap_cli.rs` and `crates/phpc_core/src/lib.rs`; the candidate is based on an older core shape and must preserve current `phpt` module exports, integer echo support, and the existing linked-exe unsupported gate transition. | LINK-01 should rebase onto current main, keep the narrow literal-echo executable denominator, preserve current parser/core behavior, and resubmit with the same native comparison test. Do not count this lane as integrated M3 progress until the rebased compile/link/run slice lands. |
| 2026-05-26 | `LINK-02` | `ecd29ce` | Reject as-is; request focused rebase | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-02-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo` passed in the LINK-02 worktree, proving a real native executable is produced and run for `fixtures/bootstrap/hello.php` and compared to `phpc run` plus system PHP when available. `git merge-tree $(git merge-base HEAD lane/LINK-02) HEAD lane/LINK-02` reports a conflict in `crates/phpc/tests/bootstrap_cli.rs` against the current linked-exe gate test, while `crates/phpc_core/src/lib.rs` merges cleanly and preserves current `phpt` exports plus integer echo support. | LINK-02 is the preferred LINK candidate after rebase: preserve the current gate coverage, replace the unsupported `--emit-exe` expectation with the native compile/link/run test when M3 is accepted, and keep the denominator to supported string/integer echo literals. Do not count as integrated M3 progress until the rebased slice lands. |
| 2026-05-26 | `LINK-08` | `767e9ea` | Reject as-is; salvage cleanup after preferred path lands | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-08-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test native_link` passed in the LINK-08 worktree, proving its CLI can link and run the bootstrap fixture and that stale output executables are removed when `--runtime-lib` is missing. `git merge-tree $(git merge-base HEAD lane/LINK-08) HEAD lane/LINK-08` reports a conflict in `crates/phpc_core/src/lib.rs`; LINK-08 changes `CompileMode::EmitExe` into a C-source emission mode, which conflicts with current main's explicit unsupported gate and with the cleaner LINK-02 design where executable linking is a separate CLI path. | Do not integrate LINK-08 as the primary M3 path. After LINK-02 rebases or another link path lands, consider porting only the stale-output cleanup regression and helper behavior if still applicable. Do not count LINK-08 as integrated M3 progress. |
| 2026-05-26 | `LINK-09` | `fa436cb` | Reject as-is; prefer LINK-02 design | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-09-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core compile_emit_exe_produces_linked_echo_binary -- --nocapture` and `cargo test -p phpc cli_compile_emit_exe_runs_linked_echo_binary -- --nocapture` passed in the LINK-09 worktree. `git merge-tree $(git merge-base HEAD lane/LINK-09) HEAD lane/LINK-09` reports conflicts in `crates/phpc/tests/bootstrap_cli.rs`, `progress.md`, and `docs/progress.html`; LINK-09 routes executable behavior through `CompileMode::EmitExe` in core like LINK-08. LINK-11 was inspected but has uncommitted `crates/phpc_core/src/lib.rs` changes and is not review-ready. | Do not integrate LINK-09 as the primary M3 path. Keep LINK-02 as the preferred rebase target with a separate executable CLI path, and mine LINK-09 diagnostics only after the accepted executable-linking shape lands. |

## Parser/Lowering Lane Review

Reviewed for this slice:

| Source | Decision | Evidence |
| --- | --- | --- |
| MINE-03 dirty test | accepted | Ported the single-quoted string escape defect as a general M4 parser/runtime fix with focused tests. |
| LOW-10 dirty parser diff | rejected for this slice | Boolean literal parsing needs coordinated interpreter/IR/docs support; not the smallest compatible parser-only improvement. |
| LOW-12 dirty parser diff | rejected for this slice | Mixes boolean literal parsing with signed-integer work; current main already has integer echo support and this would broaden scope. |
| LOW-07 function diffs | rejected for this slice | Function declaration/call handling is broader M4 lowering work and not a small diagnostic/parser safety fix. |

## Recently Integrated Coordination Slices

| Lane | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `INT-01` | integrated | Reporter/local coordination gates present in `main`. | Covers reporter health and the local coordination gate; avoid duplicating reporter-gate work. |
| `INT-02` | integrated | Manifest-sourced denominator refresh and generated-output consistency checks present in `main`. | Covers PHP core and WordPress manifest denominator rendering and drift checks. |
| `INT-03` | integrated | `.phpt` parser metadata work present in `main`. | Covers parser metadata accounting; avoid duplicate `.phpt` metadata-only slices. |
| `INT-04` | integrated | Linked executable unsupported CLI gate present in `main`. | Covers truthful M3 unsupported-mode behavior; does not count as linked native execution progress. |

## Next Non-Duplicate Integration Candidate

Highest-priority small candidate: review a real LINK lane implementation slice and accept only a narrow compile/link/run improvement with focused tests.

Acceptance:

- The slice must produce and run a native executable, not only add scaffolding, generated fixtures, wrappers, or shell-outs.
- Compare stdout, stderr, and exit status against `phpc run` and system PHP for committed fixtures.
- Keep `--emit-exe` explicitly unsupported until a real linked executable path exists.

Out of scope:

- No additional progress-denominator checks unless a real drift is found.
- No reporter-gate duplication.
- No `.phpt` parser metadata work.
- No fake linked execution progress.

| Priority | Lane(s) | Area | Current artifact | Integration instruction |
| --- | --- | --- | --- | --- |
| P1 | LINK lanes after rebase or coherent handoff | M3 linked/native path | No current unreviewed committed candidate | Prefer a LINK-02-style resubmission because native executable support is still 0%; accept only a narrow compile/link/run slice with tests. |
| P1 | `LOW-03`, `LOW-04`, `LOW-07`, `LOW-12`, `LOW-15`, `LOW-16`, `MINE-02` | M4 parser/lowering | Parser and related lib diffs | Deduplicate overlapping parser work; pick the smallest compatible token/parser improvement and require unsupported diagnostics tests. |
| P1 | `PHPT-01`, `PHPT-02`, `PHPT-03`, `PHPT-06`, `PHPT-07`, `PHPT-09`, `PHPT-10`, `PHPT-13`, `PHPT-16` | M5 `.phpt` harness | `phpt.rs`, module exports, and harness diffs | Compare against already-integrated minimal parser; keep only net-new parser/runner behavior with tests. |
| P2 | `WP-01`, `WP-02`, `WP-04`, `WP-06`, `WP-12` | M6 WordPress harness | WordPress harness scripts, manifests, and CLI entry changes | Prefer inventory/bootstrap harnesses that minimize general PHP blockers; reject WordPress-specific compiler hacks. |
| P2 | `ABI-03`, `ABI-07`, `ABI-10`, `ABI-11`, `SAPI-03`, `SAPI-05`, `SAPI-06`, `SAPI-07` | M2/M7 runtime ABI and SAPI | Runtime/SAPI diffs and ABI docs | Review ownership semantics carefully; require runtime tests and avoid incompatible handle APIs. |
| P2 | `SEM-02`, `SEM-04`, `SEM-09` | M1/M7 semantics | Semantics design/test artifacts | Prefer shared COW/reference/object mechanisms over isolated behavior patches. |
| P3 | `AUD-01`, `DOC-02`, `DOC-03`, `INT-01`, `INT-06`, `INT-07` | Coordination/tests/reporting | Audit, CLI tests, and progress script diffs | Integrate only if they improve gates or reporting accuracy without duplicating the dedicated Pages reporter. |

Latest supervisor inventory: 2026-05-25T23:27:37Z. Expected 429/reconnect states are normal and should not block review.
