# Auditor Notes

Cycle: 2026-05-26T06:45:00Z
Auditor: AUD-01

Evidence inspected: `progress.md`, `docs/progress.html`, `swarm/queue.md`,
`swarm/agents.md`, `swarm/handoffs`, `swarm/integration.md`,
`swarm/test-matrix.md`, `swarm/blockers.md`, PHP core and WordPress manifests,
recent git history, `git status`, and `origin/main` copies of key coordination
files. Local verification: `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/AUD-01-status
CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/status-gate.sh`.

## What is going right

- The checked coordination status gate passes locally. The report/dashboard
  surface is now protected by non-mutating checks, label checks, launcher
  observability checks, and manifest consistency checks.
- M3 has real first execution plumbing: `phpc compile <input.php> --emit-exe
  <output>` can build and run a linked executable for the current literal echo
  denominator. The docs correctly keep this claim narrow.
- M4 has made small but useful general PHP progress: comments/docblocks,
  string/integer/boolean/null echo literals, top-level string `define`, top-level
  `global` no-output declarations, and explicit unsupported-variable diagnostics
  are represented in current reporting.
- WordPress is still being used correctly as a pressure test for general PHP
  semantics. The current blocker is no longer the opening docblock or `define`;
  it is general `require`/include execution in `wp-settings.php`.
- Runtime ABI work has focused ownership tests and documentation. Boolean values,
  scalar handles, clone/free/error behavior, and request-header storage are
  covered as runtime behavior rather than claimed as full SAPI support.
- Integration notes are increasingly disciplined about rejecting stale lane
  branches, no-net-diff candidates, missing handoffs, and duplicated LINK shapes.

## What is going wrong

- AUD-01 itself was stale at handoff time: `git status` reported
  `lane/AUD-01...origin/main [behind 1]`. The audit checked remote copies for
  the major coordination files, but further AUD work should be refreshed before
  treating lane-local files as current.
- The queue is no longer a clean scheduler. It still lists ready bootstrap tasks
  whose evidence already exists elsewhere: Q-001/Q-002, Q-005, Q-007, and Q-009
  are stale or duplicated by verified rows/manifests.
- The queue and integration log are over-weighted toward coordination/gate
  slices. Many recent INT handoffs improve review safety, but they do not move
  PHP semantics, native coverage, PHP core runnable counts, or WordPress
  execution.
- `swarm/php-core-manifest.json` still reports `runnable: 0` and says no `.phpt`
  runner exists, while `swarm/test-matrix.md` describes a minimal `.phpt` runner
  and pass/fail/xfail classification. The distinction may be "library helper
  exists, pinned php-src subset has not run," but the manifest wording is now
  misleading.
- Handoffs still mix current and stale language. Several say "pending commit" or
  report older full-suite counts, while later test-matrix rows show larger
  counts. This weakens handoffs as integration evidence.
- Progress percentages are plausible only if read as early plumbing. Without
  named fixture denominators, M4 at 4% and M5 at 6% can easily be overread.

## Idle, Stuck, Duplicated, Drifting Lanes

- The swarm is active as a launcher, but idle as compiler execution capacity:
  progress reports zero active worker command processes, zero active slot locks,
  and 101 worker state files in expected retry/rate-limit states.
- INT lanes are drifting into repeated hygiene work. The checker/local-gate
  improvements are useful, but they should not consume the next integration
  window unless a concrete reporting failure appears.
- LINK duplication is mostly resolved. LINK-02-style executable emission is the
  accepted shape; LINK-08/LINK-09-style core `CompileMode::EmitExe` rewrites
  should stay rejected except for small mined regressions such as stale-output
  cleanup.
- LOW/MINE parser lanes remain the main duplicate pool. They need one small
  accepted semantic slice at a time, with unsupported-diagnostic tests, not a
  broad parser replacement.
- PHPT lanes risk drifting into parser metadata and matcher breadth while the
  pinned php-src denominator stays at zero runnable tests.
- WP lanes must stay tied to general PHP behavior. The next blocker is
  `require`/include; any WordPress-path special case would be roadmap drift.

## Weak Progress Claims

- M3 at 2% is justified only for linked executable plumbing over literal echo
  fixtures. It is not a reusable native differential harness and does not cover
  real PHP control flow, includes, arrays, functions, objects, or request state.
- M4 at 4% is still a very small language surface. Comments, literals, top-level
  string `define`, and no-output `global` declarations are useful, but they are
  not a token-stream foundation or general lowering layer.
- M5 at 6% is weak until the manifest records exact pinned php-src files that
  were actually run. Inventory over 19,346 `.phpt` files is not runnable
  compiler progress.
- M6 at 1% remains inventory plus blocker classification. The bootstrap check
  cannot execute through `require`/include in `wp-settings.php`.
- M7 at 1% is runtime request-header storage only. PHP `header()` calls,
  lifecycle integration, sessions, streams, filesystem, database, and object
  behavior are still absent.
- M1 remains correctly at 0%; no RPR/DMB/CCA mechanism tests exist.

## Missing Tests

- No committed php-src subset run records concrete pass/fail/skip/xfail counts
  against the 19,346-test denominator.
- No shared fixture runner compares system PHP, `phpc run`, and native
  executable stdout, stderr, and exit status across a named denominator.
- `.phpt` execution still lacks full `SKIPIF`, `EXPECTREGEX`, full `EXPECTF`,
  stderr, exit status, `INI`, `ENV`, `ARGS`, `CLEAN`, and native execution.
- There is no focused general `require`/include fixture proving parse and
  execution behavior independent of WordPress.
- Runtime/SAPI tests do not yet prove compiler-facing PHP `header()` behavior.
- COW/reference/object semantics have no mechanism-level tests.

## Next Integration Target

The next integration target should be a minimal, general `require`/include slice,
driven by the WordPress blocker but proven without WordPress paths. Acceptance:
parse a literal-path `require` and/or `include`, execute it in `phpc run`, define
missing-file behavior, add focused fixtures, preserve native unsupported
diagnostics where native execution cannot handle the feature yet, and then update
the WordPress bootstrap check to report the next general blocker.

The second target is PHP core accounting: run a tiny named php-src `.phpt` subset
through the existing minimal runner and update `swarm/php-core-manifest.json`
only with counts that were actually executed.

## Single Best Supervisor Intervention

Refresh stale auditor/worker lanes onto `origin/main`, then freeze routine
coordination-gate intake for one cycle and assign integration to one semantic
slice: general `require`/include execution. The project needs the next report to
show a new tested PHP behavior, not another launcher/checker improvement.
