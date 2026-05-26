summary: Reviewed LINK-09 as the next coherent native executable candidate. Its focused core and CLI linked-executable tests pass, but it is rejected as-is because it uses the same less-preferred `CompileMode::EmitExe`-inside-`phpc_core` design as LINK-08 and merge simulation reports conflicts in `crates/phpc/tests/bootstrap_cli.rs`, `progress.md`, and `docs/progress.html`. LINK-11 was inspected only for readiness and is not review-ready because it has uncommitted dirty `crates/phpc_core/src/lib.rs` changes.

files changed:
- `swarm/integration.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-09-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core compile_emit_exe_produces_linked_echo_binary -- --nocapture` in `/home/ubuntu/phpc-worktrees/LINK-09`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-09-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc cli_compile_emit_exe_runs_linked_echo_binary -- --nocapture` in `/home/ubuntu/phpc-worktrees/LINK-09`
- `git merge-tree $(git merge-base HEAD lane/LINK-09) HEAD lane/LINK-09` in `/home/ubuntu/phpc-worktrees/INT-01`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass for verification; LINK-09 integration decision is reject-as-is

blockers: LINK-09 conflicts with current CLI gate and generated progress artifacts, and its M3 design is less suitable than LINK-02's separate executable CLI path. LINK-11 needs a coherent commit or handoff before review.

latest commit: `6b2a43f Record LINK-09 integration decision`

next suggested slice: Keep LINK-02 as the preferred M3 rebase target; optionally mine LINK-09 diagnostics after the accepted executable-linking shape lands.
