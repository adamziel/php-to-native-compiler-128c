# Auditor Notes

Cycle: 2026-05-26T01:54:27Z
Auditor: AUD-01

Evidence inspected: `progress.md`, `docs/progress.html`, `swarm/queue.md`,
`swarm/agents.md`, `swarm/handoffs`, lane-local handoffs under
`/home/ubuntu/phpc-worktrees`, `swarm/integration.md`, `swarm/test-matrix.md`,
`swarm/blockers.md`, manifests, recent git history, `git status`, and focused
verification with `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/AUD-01`.

## What is going right

- The integrated baseline is passing: `cargo test` passes 40 tests: 12
  `php_runtime`, 5 `phpc` CLI integration tests, and 23 `phpc_core` tests.
- M2 has moved beyond null/string handles: integer value handles, clone
  ownership, invalid-handle checks, null out-pointer rejection, and ABI docs
  verification are integrated and tested.
- M4 remains narrow but is better covered: string echo, integer echo, PHP
  single-quoted escape behavior, variable-echo diagnostics, and placeholder IR
  tests all have focused coverage.
- M5 denominator accounting is honest on main: PHP-8.3 is pinned at 19,346
  `.phpt` files with `runnable: 0`, and status gates prevent pass/fail counts
  from exceeding that runnable subset.
- M6 inventory is reproducible at the coarse level: WordPress 7.0 is pinned,
  five entrypoints are present, and no compiler result is claimed.
- Integration triage is improving. `swarm/integration.md` has reviewed the main
  LINK contenders and rejects LINK-01, LINK-02, LINK-08, and LINK-09 as-is.
- Truthfulness gates exist for unsupported native output: current main tests
  prove `--emit-exe` and `--emit-asm` fail explicitly until M3 exists.

## What is going wrong

- Main still has no linked executable path. AUD-01 verification showed
  `phpc compile fixtures/bootstrap/hello.php --emit-exe` exits with
  `linked native executable emission is not implemented yet`.
- The queue still needs more cleanup. Q-003 is now verified, but several older
  ready items are superseded by integration review tasks and should be re-owned
  or closed with evidence.
- Handoff visibility is fragmented. Canonical handoffs are useful, but many
  lane-local copies exist under `/home/ubuntu/phpc-worktrees` and can drift from
  current main.
- There are more than 100 worktrees and many dirty lanes. That is useful review
  inventory, but it is also a large pile of unintegrated claims that can drift
  away from current main.

## Drifting Lanes

- Critical stuck area: M3/LINK. LINK-01, LINK-02, LINK-08, and LINK-09 have
  demonstrated executable ideas in lanes, but none has landed on main. LINK-02
  remains the preferred candidate after rebase.
- Duplicated LINK work remains high risk. LINK-08 and LINK-09 route executable
  behavior through core `CompileMode::EmitExe`; integration prefers a cleaner
  separate CLI executable path.
- Parser/lowering remains duplicated across LOW and MINE lanes. These lanes
  should be mined for the smallest compatible parser/runtime tests, not merged
  wholesale.
- PHPT lanes are drifting toward runner/matcher breadth before native execution
  exists. Their useful output right now is parser metadata, denominator hygiene,
  and explicit unsupported classification.
- WordPress lanes are drifting toward bootstrap probing, which is acceptable
  only when blockers reduce to general PHP/compiler behavior.

## Weak Progress Claims

- M2 at 3% is scalar runtime ABI progress only. It does not yet cover arrays,
  references, COW cells, objects, request state, or compiler-side value passing.
- M3 at 0% is accurate for main. Lane-local generated C, clang invocations,
  wrappers, and probes must not count until one tested path lands on main.
- M4 at 2% remains literal-only. Placeholder IR comments are not LLVM/object
  input and should not be counted as native backend progress.
- M5 at 2% must be read with the denominator: 19,346 mapped `.phpt`, 0 runnable,
  and 0 system-PHP/phpc/native pass/fail results on main.
- M6 at 1% is inventory only.

## Missing Tests

- No main-branch test proves `phpc compile --emit-exe` writes an executable,
  runs it, and compares stdout, stderr, and exit status against `phpc run` and
  system PHP.
- No shared differential harness compares system PHP, `phpc run`, and native
  output for a fixture set.
- `.phpt` coverage still lacks SKIPIF execution, EXPECTF matching,
  EXPECTREGEX matching, CLEAN, INI, ARGS, ENV, XFAIL classification, stderr,
  exit status, system-PHP oracle execution, and native execution.
- No WordPress bootstrap runner test records the first generalized
  compiler/runtime blocker on main.
- No COW/reference/object/request-state tests exist for M1/M7.

## Next Integration Target

Rebase and review LINK-02 as the single M3 integration target. Its lane review
already passed a native executable test for `fixtures/bootstrap/hello.php` and
compared against `phpc run` plus system PHP when available, but it conflicted
with current `bootstrap_cli.rs`.

Acceptance must be explicit: the merged slice may count as M3 execution plumbing
only for supported string/integer echo literals. It must not claim general native
lowering, PHP-core progress, or WordPress progress.

## Single Best Supervisor Intervention

Stop reviewing competing LINK rewrites until one reviewer lands or formally
rejects the rebased LINK-02 slice. Keep `swarm/queue.md`,
`swarm/blockers.md`, `swarm/test-matrix.md`, `progress.md`, and
`docs/progress.html` aligned so the queue, dashboard, blocker list, and test
evidence all tell the same M3 truth.
