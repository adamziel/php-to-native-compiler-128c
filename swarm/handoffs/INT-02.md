# INT-02 Handoff

## Summary

- Milestone: Integration / coordination safety.
- Started fresh from current `origin/main` on `lane/INT-02-fresh-0436`.
- Added an opt-in `PHPC_REQUIRE_CLEAN_WORKTREE=1` check to `scripts/verify-worker-env.sh` so worker preflights can fail fast on dirty lane state before expensive gates.
- Extended the focused worker-env regression to prove the clean-worktree check accepts a clean fixture repo and rejects a dirty one.
- No compiler, runtime, native lowering, PHP-core denominator, or WordPress behavior changed.

## Files Changed

- `scripts/verify-worker-env.sh`
- `scripts/test-worker-env.sh`
- `swarm/handoffs/INT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-worker-env.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- PASS: focused worker environment regression, including opt-in clean and dirty worktree checks.
- PASS: `scripts/local-gate.sh`, including status checks, ABI doc checks, launcher observability, worker env checks, lane integration checker tests, full workspace `cargo test`, and diff hygiene.
- PASS: `git diff --check`.

## Blockers

- None for this slice.

## Latest Commit

- `6d7075e` Add opt-in clean worktree worker preflight.

## Next Suggested Slice

- Consider wiring `PHPC_REQUIRE_CLEAN_WORKTREE=1` into specific supervisor or worker launch paths only after confirming generated progress/status jobs do not intentionally run with local output changes.
