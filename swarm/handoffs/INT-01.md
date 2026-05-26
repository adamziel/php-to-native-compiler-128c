summary: Reviewed committed LINK-08 candidate `767e9ea Clean stale native executable outputs` as an integration decision artifact only. LINK-08 passes its native link test suite and includes a useful stale-output cleanup regression, but is rejected as-is because it conflicts with current `crates/phpc_core/src/lib.rs` by converting `CompileMode::EmitExe` into C-source emission. That design conflicts with current main's explicit unsupported gate and the preferred LINK-02 approach where executable linking is a separate CLI path.

files changed:
- `swarm/integration.md`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/LINK-08-review CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test native_link` in `/home/ubuntu/phpc-worktrees/LINK-08`
- `git merge-tree $(git merge-base HEAD lane/LINK-08) HEAD lane/LINK-08` in `/home/ubuntu/phpc-worktrees/INT-01`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 scripts/local-gate.sh`
- `git diff --check`

pass/fail state: pass for verification; LINK-08 integration decision is reject-as-is

blockers: LINK-08 conflicts with current `crates/phpc_core/src/lib.rs` and uses a less suitable `EmitExe`-as-C-source design. No M3 progress should be counted from this lane unless a cleaner rebased slice lands.

latest commit: `9bed68f Record LINK-08 integration decision`

next suggested slice: Prefer LINK-02 after rebase for the primary M3 path; salvage LINK-08 stale-output cleanup only after the accepted executable-linking shape is integrated.
