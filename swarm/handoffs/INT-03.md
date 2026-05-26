summary:
- M5 integration slice reviewed PHPT-02 source commit `9ce60ac` and accepted only the compatible typed expectation parser behavior.
- Added `PhptExpectationKind`, borrowed `PhptExpectation`, `EXPECTF`/`EXPECTREGEX` accessors, and ambiguous expectation rejection.
- Updated `PhptHarnessInput` to carry expectation kind/body while preserving already-integrated `SKIPIF`/`XFAIL` metadata behavior.
- No `SKIPIF` execution, `XFAIL` classification, php-src runnable count, or native progress was added.

files changed:
- `crates/phpc_core/src/phpt.rs`
- `docs/SUPPORT.md`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-03.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-03 scripts/local-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: `scripts/local-gate.sh`; focused PHPT parser tests, status gate, and whitespace check completed cleanly on the lane.
- PASS: explicit `git diff --check`.

blockers:
- No `.phpt` runner exists yet, so `SKIPIF` scripts are not executed and `XFAIL` is not applied to result classification.
- `EXPECTF` and `EXPECTREGEX` are parsed and carried, but no output matcher executes them yet.

latest lane commit:
- `2601ca0` Integrate PHPT expectation variants.

integration note:
- Ported onto current `main` while preserving the richer main `scripts/local-gate.sh`; the stale lane-local gate was not copied.

next suggested slice:
- Review PHPT-06 for `FILEEOF` compatibility or build a non-executing parser classification pass over a tiny pinned php-src sample using `PhptHarnessInput`, without changing `swarm/php-core-manifest.json` runnable counts.
