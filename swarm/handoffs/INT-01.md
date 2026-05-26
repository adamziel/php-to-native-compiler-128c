summary: Reviewed committed LINK-01 candidate `d0257ee Add bootstrap linked executable path` as an integration decision artifact only. The candidate proves a real compile/link/run path in its own lane, but is rejected as-is because `git merge-tree` reports conflicts against current main in `crates/phpc/tests/bootstrap_cli.rs` and `crates/phpc_core/src/lib.rs`; it must rebase and preserve current `phpt` exports, integer echo support, and the linked-exe gate transition before integration.

files changed:
- `swarm/integration.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-01-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compiles_links_and_runs_bootstrap_echo` in `/home/ubuntu/phpc-worktrees/LINK-01`
- `git merge-tree $(git merge-base HEAD lane/LINK-01) HEAD lane/LINK-01` in `/home/ubuntu/phpc-worktrees/INT-01`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass for verification; LINK-01 integration decision is reject-as-is pending rebase

blockers: LINK-01 is based on an older core/test shape and conflicts with current main. No M3 progress should be counted until a rebased compile/link/run slice lands.

latest commit: `254f8da Record LINK-01 integration decision`

next suggested slice: Review another LINK lane candidate, or have LINK-01 rebase its passing bootstrap executable path onto current main and resubmit with the same native comparison test.
