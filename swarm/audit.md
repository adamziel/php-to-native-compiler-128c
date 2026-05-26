# Auditor Notes

Cycle: 2026-05-26T06:25:00Z
Auditor: AUD-01

Evidence inspected: `progress.md`, `docs/progress.html`, `swarm/queue.md`,
`swarm/agents.md`, `swarm/handoffs`, `swarm/integration.md`,
`swarm/test-matrix.md`, `swarm/blockers.md`, PHP core and WordPress manifests,
recent git history, `git status`, and `origin/main` copies of key coordination
files. Local verification: `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/AUD-01-status
CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`.

## What is going right

- The status gate passes locally, and the current reports are guarded by
  non-mutating consistency checks rather than hand-edited dashboard claims.
- M3 now has a real but narrow integrated executable path: `phpc compile
  <input.php> --emit-exe <output>` is reported and tested for literal echo
  fixtures, including string, integer, boolean, null, no-final-semicolon, and
  no-trailing-newline cases.
- Runtime ABI work is moving through tested ownership slices. Boolean values,
  existing scalar handles, cloning/free/error behavior, and request-header
  storage are documented and covered by runtime tests.
- WordPress work is currently framed correctly as a pressure test for general PHP
  behavior. The manifest pins WordPress 7.0, inventories five entrypoints, and
  records the present general blocker as unsupported `require` execution.
- PHP core accounting still names the denominator: PHP-8.3 branch snapshot,
  19,346 `.phpt` files. The runner claims remain narrow enough to distinguish
  parser metadata from runnable coverage.
- Integration notes reject stale or conflicting LINK candidates instead of
  merging every lane-local executable experiment.

## What is going wrong

- AUD-01 was behind `origin/main` when this audit was handed off (`HEAD`
  `5e5736e`, supervisor `origin/main` `d71b1c5`). This audit checked the remote
  versions of the major coordination files, but the lane itself should be
  refreshed before any further local verification is treated as current-main
  evidence.
- `swarm/agents.md` still says the target is 100 implementation/research workers
  plus auditor, while the checked-out `progress.md` says 50 workers. `origin/main`
  progress has the cleaner `100 workers + auditor` wording. This is a concrete
  stale-lane drift signal.
- `swarm/queue.md` still has old `ready` rows whose work is already represented
  by verified rows: Q-001/Q-002, Q-005 versus integrated ABI work, Q-007 versus
  the pinned PHP core manifest, and Q-009 versus the WordPress manifest. The queue
  is partly a backlog and partly history, which weakens scheduling.
- The test matrix is ahead of the PHP core manifest: it describes a minimal
  `.phpt` runner, while `swarm/php-core-manifest.json` still says `runnable: 0`
  and "No .phpt runner is implemented yet." The manifest needs a truthful
  runnable-subset count or sharper wording that separates library-level runner
  capability from php-src inventory execution.
- Several handoffs still say "pending commit" or report older pass counts. That
  makes handoff evidence less useful for auditing what is actually integrated.

## Idle, Stuck, Duplicated, Drifting Lanes

- The active swarm was still mostly idle from a compiler-progress standpoint at
  audit time: progress reported one interactive pane, zero active worker command
  processes, zero active slot locks, and all 101 worker state files in expected
  retry or rate-limit state.
- LINK lanes are duplicated. LINK-02-style execution is the accepted shape now;
  LINK-08/LINK-09-style core `CompileMode::EmitExe` rewrites should remain
  rejected unless mined for focused diagnostics or stale-output cleanup.
- LOW/MINE parser work is still the main duplicate pool. It should be integrated
  as small general PHP parser/lowering slices only, not as broad parser rewrites.
- PHPT lanes risk drifting into metadata or matcher breadth without increasing
  the pinned php-src runnable subset. Future PHPT work should produce a small
  counted php-src subset run, not just more parser metadata.
- WordPress lanes are acceptable only while reducing the current blocker through
  general `require`/include, constants, globals, function-call, and request
  semantics. Any WordPress-path special case should be rejected.

## Weak Progress Claims

- M3 at 2% is defensible only as "first linked executable plumbing for literal
  echo fixtures." It is not broad native lowering and should not imply a reusable
  differential harness yet.
- M4 at 4% is still literal and top-level-statement support plus diagnostics.
  It does not yet cover arrays, functions, control flow, includes, classes,
  references, or normal PHP call frames.
- M5 at 6% is high unless tied to the exact runnable subset. The global manifest
  still reports 19,346 mapped tests and zero runnable php-src tests.
- M6 at 1% is inventory plus blocker classification only. WordPress bootstrap
  still cannot execute through `wp-settings.php`.
- M7 at 1% is request-header storage, not PHP `header()` semantics, SAPI lifecycle
  integration, sessions, streams, filesystem, database, or object behavior.

## Missing Tests

- No committed php-src subset run records concrete `.phpt` pass/fail/skip/xfail
  counts against the 19,346-test denominator.
- No shared differential runner compares system PHP, `phpc run`, and native
  executable stdout, stderr, and exit status across a named fixture set.
- `.phpt` execution still lacks broad `SKIPIF`, `EXPECTREGEX`, full `EXPECTF`,
  stderr, exit status, `INI`, `ENV`, `ARGS`, `CLEAN`, and native execution.
- WordPress has no executable bootstrap step past `require`/include, and no
  general include/require fixture proves the next slice.
- Runtime/SAPI tests do not yet prove compiler-facing PHP `header()` behavior.
- M1 has no RPR/DMB/CCA mechanism tests, so COW/reference progress remains zero.

## Next Integration Target

The next best integration target is a general `require`/include slice driven by
the WordPress blocker, but reduced to small PHP fixtures first. Acceptance should
be: parse and execute a literal-path `require` or `include` in `phpc run`, define
the failure behavior for missing files, add focused tests independent of
WordPress paths, and then update the WordPress bootstrap check to report the next
general blocker.

The second integration target is a tiny php-src `.phpt` runnable subset manifest
update. It should name exact test files, run them through the existing minimal
runner, and update `swarm/php-core-manifest.json` from `runnable: 0` only if
those tests are actually executed.

## Single Best Supervisor Intervention

Refresh AUD and other stale lanes onto current `origin/main`, then force the
queue to pick one compiler-semantic integration lane: general `require`/include
execution. Pause new coordination-gate work unless it fixes a demonstrated
reporting inconsistency, because the roadmap now needs fewer launcher/status
slices and more tested PHP semantics.
