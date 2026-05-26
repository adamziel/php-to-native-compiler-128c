# Integration Log

## Policy

1. Review the diff before integrating.
2. Reject unrelated formatting and generated noise.
3. Run focused tests for the changed area.
4. Update progress and manifests.
5. Integrate in small batches.

## Lane Review Workflow

Before reviewing or porting a `lane/*` candidate, fetch current `main` and run:

```sh
scripts/check-lane-integration.sh lane/<name> origin/main
```

For batches, use the non-mutating wrapper and review every printed section before
acting on a lane:

```sh
scripts/check-lanes-integration.sh --main-ref origin/main lane/<name> lane/<other>
```

The batch wrapper keeps checking later lanes after an individual unsafe or
missing-handoff result, then exits nonzero if any lane check failed.

Interpret the classification as follows:

- `already-integrated`: do not merge or cherry-pick. Record the lane as integrated or stale against current `main`.
- `stale-equivalent`: do not merge or cherry-pick. The patch-id already exists on `main` under different commit ids.
- `unsafe-to-merge`: do not merge directly. Request a rebase or manually port only the coherent slice after inspecting conflicts and preserving current `main` behavior.
- `review-required`: inspect the diff and `swarm/handoffs/<lane>.md`, then run focused tests for the changed area before merging.
- `review-required-missing-handoff`: require a handoff before merging unless the artifact is explicitly research-only. The checker exits nonzero for this classification so automated review loops stop on missing handoffs.

Before any manual port or cherry-pick lands, run the focused tests named by the handoff, `scripts/local-gate.sh` when practical, and `git diff --check`. If `scripts/local-gate.sh` is not practical, record the reason and the narrower verification in the integration decision and lane handoff.

## Current Integration Queue

Active integration work is follow-up only. The first M3 linked executable path is integrated for the literal echo denominator, and reviewed committed candidates are tracked below instead of being advertised as active work.

## Reviewed Candidates

| Lane | Source Commit | Result | Evidence |
| --- | --- | --- | --- |
| `PHPT-03` | `ea96852` | Accepted compatible parser-level `SKIPIF`/`XFAIL` metadata into `INT-03`; standalone candidate now verified stale and should not be reapplied. | `cargo test -p phpc_core phpt::tests` and `scripts/status-gate.sh` in INT-03 handoff; `git merge-base --is-ancestor 0cbd609 main` returned 0 during INT-06 review. |
| `PHPT-02` | `9ce60ac` | Accepted compatible typed `EXPECTF`/`EXPECTREGEX` parsing and ambiguous expectation rejection; skipped stale parser scaffolding and did not add execution semantics. | `cargo test -p phpc_core phpt::tests`, `scripts/local-gate.sh`, and `git diff --check` in INT-03 integration. |
| `PHPT-06` | `537bb5e` | Accepted the narrow `FILEEOF` source-section compatibility behavior and ambiguous `FILE`/`FILEEOF` rejection; no `.phpt` execution or runnable-count change added. | Ported onto current `main` while preserving the existing exact-EXPECT runner; `cargo test -p phpc_core phpt::tests`, full `cargo test`, `scripts/local-gate.sh`, and `git diff --check` passed. |
| `WP-12` | `348ad3b` | Verified as a net-new reproducible inventory improvement; acceptable for integration as status/harness evidence only. | `git merge-base --is-ancestor 348ad3b main` returned 1; current `main:swarm/wordpress-manifest.json` has only the pinned entrypoint list, while WP-12 records all five entrypoint byte counts and SHA-256 values matching `/home/ubuntu/phpc-external/wordpress/wordpress`. |
| `DOC-03` | `4ebe2ab` | Rejected; do not apply the standalone generated dashboard refresh. | `git merge-base --is-ancestor 4ebe2ab main` returned 1; current `main` has later `Update published swarm progress` commits, `scripts/pages-reporter-loop.sh`, and `scripts/test-refresh-progress-labels.sh`, while DOC-03 refreshes `progress.md`/`docs/progress.html` from `lane/DOC-03` and assigns `Q-002` to DOC-03. |

## Integration Decisions

| Date | Lane | Commit | Decision | Evidence | Follow-up |
| --- | --- | --- | --- | --- | --- |
| 2026-05-26 | `LINK-01` | `d0257ee` | Reject as-is; request rebase and resubmission | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compiles_links_and_runs_bootstrap_echo` passed in the LINK-01 worktree, proving the slice has a real compile/link/run path for the bootstrap echo fixture. `git merge-tree $(git merge-base HEAD lane/LINK-01) HEAD lane/LINK-01` from INT-01 reports conflicts in `crates/phpc/tests/bootstrap_cli.rs` and `crates/phpc_core/src/lib.rs`; the candidate is based on an older core shape and must preserve current `phpt` module exports, integer echo support, and the existing linked-exe unsupported gate transition. | LINK-01 should rebase onto current main, keep the narrow literal-echo executable denominator, preserve current parser/core behavior, and resubmit with the same native comparison test. Do not count this lane as integrated M3 progress until the rebased compile/link/run slice lands. |
| 2026-05-26 | `LINK-02` | `ecd29ce` | Reject as-is; request focused rebase | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-02-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo` passed in the LINK-02 worktree, proving a real native executable is produced and run for `fixtures/bootstrap/hello.php` and compared to `phpc run` plus system PHP when available. `git merge-tree $(git merge-base HEAD lane/LINK-02) HEAD lane/LINK-02` reports a conflict in `crates/phpc/tests/bootstrap_cli.rs` against the current linked-exe gate test, while `crates/phpc_core/src/lib.rs` merges cleanly and preserves current `phpt` exports plus integer echo support. | LINK-02 is the preferred LINK candidate after rebase: preserve the current gate coverage, replace the unsupported `--emit-exe` expectation with the native compile/link/run test when M3 is accepted, and keep the denominator to supported string/integer echo literals. Do not count as integrated M3 progress until the rebased slice lands. |
| 2026-05-26 | `LINK-02` | current-main port | Accept narrow M3 execution plumbing | Ported only the LINK-02-style executable path onto current `main`: `phpc compile <input.php> --emit-exe <output>` emits linkable LLVM IR for supported string/integer echo literals, links with `libphp_runtime.a` through `clang`, runs the produced binary in a CLI test, and compares output with `phpc run` plus system PHP when available. Verification: `cargo test -p phpc_core linkable_ir_calls_runtime_echo_for_supported_literals`, `cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo -- --nocapture`, full `cargo test`, `scripts/local-gate.sh`, and `git diff --check` all passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-link02-port`. | Count this only as first M3 execution plumbing for the supported literal echo denominator. Do not claim broad native lowering, PHP-core harness progress, or WordPress compatibility. |
| 2026-05-26 | `LINK-08` | `767e9ea` | Reject as-is; salvage cleanup after preferred path lands | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-08-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test native_link` passed in the LINK-08 worktree, proving its CLI can link and run the bootstrap fixture and that stale output executables are removed when `--runtime-lib` is missing. `git merge-tree $(git merge-base HEAD lane/LINK-08) HEAD lane/LINK-08` reports a conflict in `crates/phpc_core/src/lib.rs`; LINK-08 changes `CompileMode::EmitExe` into a C-source emission mode, which conflicts with current main's explicit unsupported gate and with the cleaner LINK-02 design where executable linking is a separate CLI path. | Do not integrate LINK-08 as the primary M3 path. After LINK-02 rebases or another link path lands, consider porting only the stale-output cleanup regression and helper behavior if still applicable. Do not count LINK-08 as integrated M3 progress. |
| 2026-05-26 | `LINK-09` | `fa436cb` | Reject as-is; prefer LINK-02 design | `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-09-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core compile_emit_exe_produces_linked_echo_binary -- --nocapture` and `cargo test -p phpc cli_compile_emit_exe_runs_linked_echo_binary -- --nocapture` passed in the LINK-09 worktree. `git merge-tree $(git merge-base HEAD lane/LINK-09) HEAD lane/LINK-09` reports conflicts in `crates/phpc/tests/bootstrap_cli.rs`, `progress.md`, and `docs/progress.html`; LINK-09 routes executable behavior through `CompileMode::EmitExe` in core like LINK-08. LINK-11 was inspected but has uncommitted `crates/phpc_core/src/lib.rs` changes and is not review-ready. | Do not integrate LINK-09 as the primary M3 path. Keep LINK-02 as the preferred rebase target with a separate executable CLI path, and mine LINK-09 diagnostics only after the accepted executable-linking shape lands. |
| 2026-05-26 | `WP-06`/`INT-04` | current-main port | Accept narrowed M6 bootstrap blocker check | Ported a small compatible harness command onto current `main`: `phpc wordpress-bootstrap-check <wordpress-root>` inventories the five pinned entrypoints, runs existing `compile_php(..., EmitIr)` on `wp-settings.php`, and reports the current general PHP parser gap. No compiler semantics or WordPress-specific hacks were added. Verification: `cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap -- --nocapture`, `cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`, full `cargo test`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap`. | Keep reducing the reported blocker through general parser/compiler fixtures, not WordPress special cases. |
| 2026-05-26 | `WP-01` | `47e6dad` current-main port | Accept general parser trivia slice | Ported only the general PHP parser behavior from WP-01 onto current `main`: whitespace plus `/* ... */`, `//`, and `#` comments are skipped before supported statements, with parser tests for docblocks, line comments, and unterminated block comments. The WordPress bootstrap check now advances past the opening docblock and reports the next blocker at `define( 'WPINC', 'wp-includes' )`. Verification: `cargo test -p phpc_core parser::tests -- --nocapture`, `cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`, full `cargo test`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-comment-trivia`. | Next reduce `define( 'NAME', literal );` through general parser/interpreter fixtures; do not add WordPress-specific parsing. |
| 2026-05-26 | `INT-01` | `f44ee54` current-main port | Accept branch hygiene worker-env guard | Ported only the focused branch-hygiene slice from the stale `lane/INT-01-require-diag` branch: `scripts/verify-worker-env.sh` now accepts optional `PHPC_EXPECT_BRANCH` and reports a precise mismatch; `scripts/test-worker-env.sh` covers mismatch and match cases; `scripts/local-gate.sh` now runs the synthetic worker-env fixture. Verification: `scripts/test-worker-env.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-worker-branch-env`. | Do not merge the stale lane branch as-is; it also carries already-integrated include diagnostics and old handoff/doc changes. Use `PHPC_EXPECT_BRANCH` in worker startup or manual preflight only when the lane branch name has been deliberately reconciled. |
| 2026-05-26 | `INT-02` | `86be003` current-main port | Accept no-net-diff lane classification | Ported only the focused checker hardening from stale `lane/INT-02-checker-workflow`: `scripts/check-lane-integration.sh` now classifies a candidate whose tree exactly matches main as `no-net-diff`, and the temp-repo regression suite covers an empty lane commit. Verification: `scripts/test-check-lane-integration.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-no-net-diff-checker`. | Do not merge the stale lane branch as-is; it also carries old handoff/integration text. Use this classification before spending review time on empty or metadata-only lane candidates. |
| 2026-05-26 | `INT-02` | `6d98065` current-main port | Accept launcher-log override progress fixture | Ported the fresh `lane/INT-02-next` coordination slice: `scripts/refresh-progress.sh` now honors `PHPC_SWARM_LAUNCHER_LOG`, and `scripts/test-refresh-progress-launcher-log.sh` verifies generated Markdown and HTML against a temporary 100-worker-plus-auditor launcher log. The fixture is wired into `scripts/local-gate.sh`. Verification: `scripts/test-refresh-progress-launcher-log.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-refresh-launcher-log`. | Use the override in future non-live progress tests instead of relying on `/tmp/phpc-swarm-launcher.log`. Do not merge the stale lane branch as-is. |
| 2026-05-26 | `INT-02`/`INT-04` | current-main port | Accept launcher auditor and denominator checks | Combined complementary launcher observability slices from stale `lane/INT-02-next-2` and `lane/INT-04-launcher-observability`: the live check validates a well-formed `SWARM_INCLUDE_AUDITOR` marker, can enforce `PHPC_EXPECT_INCLUDE_AUDITOR` when needed, and always verifies the latest stagger wait denominator equals worker count plus the marker's auditor flag. Verification: `scripts/test-launcher-observability.sh`, `scripts/check-launcher-observability.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-launcher-denominator`. | Current live run intentionally uses `SWARM_INCLUDE_AUDITOR=0`, so auditor presence is optional unless `PHPC_EXPECT_INCLUDE_AUDITOR=1` is set. Do not merge stale lane branches as-is. |
| 2026-05-26 | `INT-01` | `6ebedd9` current-main port | Accept missing-handoff hard failure | Ported the focused `lane/INT-01-fresh-409` integration-safety slice: `scripts/check-lane-integration.sh` now exits nonzero for `review-required-missing-handoff`, and the temp-repo checker fixture proves review lanes without `swarm/handoffs/<lane>.md` stop automated integration loops. Verification: `scripts/test-check-lane-integration.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-missing-handoff-gate`. | Do not merge the stale lane branch as-is. This changes only review-loop behavior, not compiler/runtime semantics. |
| 2026-05-26 | `INT-02` | `e86733a` current-main port | Accept base handoff lookup for fresh lane branches | Ported the focused `lane/INT-02-fresh-0409` checker slice: suffixed fresh branches such as `lane/INT-02-fresh-0409` can satisfy handoff presence with the canonical `swarm/handoffs/INT-02.md`, while unrelated missing-handoff lanes still fail. Verification: `scripts/test-check-lane-integration.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-base-handoff-lookup`. | This complements the missing-handoff hard failure and keeps fresh-branch naming compatible with existing worker handoff paths. Do not merge the stale lane branch as-is. |
| 2026-05-26 | `INT-03` | `b1fd394` current-main port | Accept opt-in local gate worker preflight | Ported the focused `lane/INT-03-fresh-409` coordination slice: `scripts/local-gate.sh` can now run `scripts/verify-worker-env.sh` before status checks and cargo when `PHPC_REQUIRE_WORKER_ENV=1`, and `scripts/test-local-gate.sh` proves the preflight both allows valid worker environments and stops before cargo on target-dir mismatches. Verification: `scripts/test-worker-env.sh`, `scripts/test-local-gate.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-local-gate-preflight`. | Keep the preflight opt-in until all active launcher lanes can satisfy branch labels consistently. Do not merge the stale lane branch as-is. |
| 2026-05-26 | `INT-01` | `cf11900` current-main port | Accept batch lane integration checker | Ported the focused `lane/INT-01-batch-0526` coordination slice: `scripts/check-lanes-integration.sh` wraps the single-lane checker without mutating refs, continues through mixed safe/unsafe batches, and exits nonzero if any lane check fails. The batch wrapper is covered in the existing temp-repo checker fixture and included in `scripts/local-gate.sh` as a smoke check. Verification: `scripts/test-check-lane-integration.sh`, `scripts/check-lanes-integration.sh --help`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-batch-lane-checker`. | Use this to review multiple dirty coordination lanes while preserving each lane's individual classification. Do not merge the stale lane branch as-is. |
| 2026-05-26 | `INT-02` | `6335a07` current-main port | Accept batch lane checker summary counts | Ported the focused `lane/INT-02-fresh-0430` status-accuracy slice: `scripts/check-lanes-integration.sh` now prints aggregate `passed`, `failed`, and `total` counts after each batch, and the temp-repo regression asserts both mixed and all-safe summary output. Verification: `scripts/test-check-lane-integration.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-batch-lane-summary`. | The summary is human-readable only; add a stable machine-readable mode separately if automation needs structured output. |
| 2026-05-26 | `INT-01` | `d6098bb` current-main port | Preserve batch checker ref-error status | Ported the focused `lane/INT-01-fresh-0430` status-accuracy slice on top of the current summary-count checker: batch lane checks now preserve aggregate exit status `2` when any target has a usage or ref-resolution error, while ordinary review failures still exit `1` and the final passed/failed/total summary remains intact. Verification: `scripts/test-check-lane-integration.sh`, `scripts/local-gate.sh`, and `git diff --check` passed with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-batch-ref-status`. | This keeps manual batch review useful for both review-required lanes and malformed/missing refs. Do not merge the stale lane branch as-is. |

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

Highest-priority small candidate: extend the accepted M3 executable path only through slices that compile, link, run, and compare a committed fixture with focused tests.

Acceptance:

- The slice must produce and run a native executable, not only add scaffolding, generated fixtures, wrappers, or shell-outs.
- Compare stdout, stderr, and exit status against `phpc run` and system PHP for committed fixtures.
- Preserve the current `phpc compile <input.php> --emit-exe <output>` executable path and keep any broader native claims tied to tested fixture denominators.

Out of scope:

- No additional progress-denominator checks unless a real drift is found.
- No reporter-gate duplication.
- No `.phpt` parser metadata work.
- No fake linked execution progress.

| Priority | Lane(s) | Area | Current artifact | Integration instruction |
| --- | --- | --- | --- | --- |
| P1 | LINK follow-up lanes | M3 linked/native path | First LINK-02-style executable path integrated for literal echo fixtures | Extend native run/differential helpers carefully; accept only slices that run executables and compare stdout, stderr, and exit status without broad support claims. |
| P1 | `LOW-03`, `LOW-04`, `LOW-07`, `LOW-12`, `LOW-15`, `LOW-16`, `MINE-02` | M4 parser/lowering | Parser and related lib diffs | Deduplicate overlapping parser work; pick the smallest compatible token/parser improvement and require unsupported diagnostics tests. |
| P1 | PHPT follow-up lanes | M5 `.phpt` harness | `phpt.rs`, module exports, and harness diffs | Compare against already-integrated minimal parser; keep only net-new parser/runner behavior with tests. Do not reapply reviewed PHPT parser metadata slices. |
| P2 | WP follow-up lanes | M6 WordPress harness | WordPress harness scripts, manifests, and CLI entry changes | Prefer inventory/bootstrap harnesses that minimize general PHP blockers; reject WordPress-specific compiler hacks. Do not reapply reviewed WordPress inventory/bootstrap slices. |
| P2 | `ABI-03`, `ABI-07`, `ABI-10`, `ABI-11`, `SAPI-03`, `SAPI-05`, `SAPI-06`, `SAPI-07` | M2/M7 runtime ABI and SAPI | Runtime/SAPI diffs and ABI docs | Review ownership semantics carefully; require runtime tests and avoid incompatible handle APIs. |
| P2 | `SEM-02`, `SEM-04`, `SEM-09` | M1/M7 semantics | Semantics design/test artifacts | Prefer shared COW/reference/object mechanisms over isolated behavior patches. |
| P3 | Coordination follow-up lanes | Coordination/tests/reporting | Audit, CLI tests, and progress script diffs | Integrate only if they improve gates or reporting accuracy without duplicating the dedicated Pages reporter. Do not reapply reviewed generated-dashboard slices. |

Latest supervisor inventory: 2026-05-25T23:27:37Z. Expected 429/reconnect states are normal and should not block review.
