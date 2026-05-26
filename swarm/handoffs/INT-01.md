summary: Reviewed committed LINK-02 candidate `ecd29ce Add linked native executable path` as an integration decision artifact only. The candidate passes its native compile/link/run test in the LINK-02 worktree and is preferable to LINK-01 because its core changes preserve current `phpt` exports and integer echo support. It is still rejected as-is because `git merge-tree` reports a conflict in `crates/phpc/tests/bootstrap_cli.rs` against the current linked-exe gate test; LINK-02 should rebase and replace the unsupported gate with the native executable test when M3 is accepted.

files changed:
- `swarm/integration.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-02-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_emits_linked_native_executable_for_bootstrap_echo` in `/home/ubuntu/phpc-worktrees/LINK-02`
- `git merge-tree $(git merge-base HEAD lane/LINK-02) HEAD lane/LINK-02` in `/home/ubuntu/phpc-worktrees/INT-01`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass for verification; LINK-02 integration decision is reject-as-is pending focused rebase

blockers: LINK-02 conflicts with current `crates/phpc/tests/bootstrap_cli.rs` linked-exe gate. No M3 progress should be counted until a rebased compile/link/run slice lands.

latest commit: `d5fea30 Record LINK-02 integration decision`

next suggested slice: Have LINK-02 rebase onto current main and resubmit as the preferred M3 bootstrap executable candidate, or review LINK-08 as the next alternate LINK candidate.
