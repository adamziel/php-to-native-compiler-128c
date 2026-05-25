# Agent Operating Rules

All workers in this repository follow these rules.

- Work in an isolated worktree or clearly assigned lane.
- Use a unique `CARGO_TARGET_DIR`.
- Do not run destructive git commands.
- Do not revert unrelated work.
- Do not broaden scope without recording it in `swarm/queue.md`.
- Do not count generated fixtures, bridge calls, wrappers, shell-outs, or probes as native compiler progress.
- Every implementation slice must include focused tests or a documented blocker.
- WordPress work must reduce to general PHP/compiler/runtime behavior.
- PHP core progress must name the pinned `.phpt` denominator and runnable subset.
- Keep handoffs under `swarm/handoffs/`.

If blocked, write the blocker precisely and stop inventing broad compatibility hacks.

