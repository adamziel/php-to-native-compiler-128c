# INT-06 Handoff

## Summary

- Time: 2026-05-26T01:40:00Z.
- Milestone: Coordination / M6 status accuracy.
- Narrow denominator: committed-candidate review status for `Q-023` / `WP-12` WordPress inventory evidence.
- Verified `WP-12` as a net-new reproducible inventory improvement because current `main` still has only the pinned entrypoint list, while `WP-12` records per-entry byte counts and SHA-256 values.
- Marked `Q-023` verified as acceptable integration evidence only; no WordPress-specific compiler behavior was added.

## Files Changed

- `swarm/queue.md`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/handoffs/INT-06.md`

## Tests Run

- `git merge-base --is-ancestor 348ad3b main`
  - Pass for review decision: exit 1 confirms the standalone `WP-12` candidate is not already contained in `main`.
- Compared `git show 348ad3b:swarm/wordpress-manifest.json` with pinned files under `/home/ubuntu/phpc-external/wordpress/wordpress`
  - Pass: all five entrypoint byte counts and SHA-256 hashes match the pinned WordPress 7.0 checkout.
- Inspected current `main:swarm/wordpress-manifest.json`
  - Pass: current `main` has the pinned source/version/path and five entrypoints, but lacks the per-entry byte/SHA inventory from `WP-12`.
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-06-main-gate CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
  - Pass in `/home/ubuntu/php-to-native-compiler-128c` on current `main`.
- `git diff --check`
  - Pass.

## Pass/Fail State

- Pass for the narrow Q-023 status decision.
- Pass for `scripts/local-gate.sh` on current `main`, the evidence base for this candidate review.
- Pass for `git diff --check` in `lane/INT-06`.

## Blockers

- `lane/INT-06` is behind current `main` and lacks `scripts/local-gate.sh`; the gate was run from the clean current main worktree instead.
- WordPress remains inventory-only: no bootstrap runner has executed these entrypoints through `phpc`, and no compiler progress is claimed.

## Latest Commit

- Current lane HEAD for this slice: `fa92dbf Verify WP-12 candidate status`.

## Next Suggested Slice

- Review `Q-024` / `DOC-03` as a stale committed-candidate status item, avoiding duplication with the dedicated Pages reporter.
