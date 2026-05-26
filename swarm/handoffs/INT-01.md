# INT-01 Handoff

summary:
- Milestone: Integration / coordination safety for linked native execution.
- Preserved the stale prior lane state at `lane/INT-01-archive-0559`, then recreated and checked out `lane/INT-01` from current `origin/main`.
- Added stale-output cleanup for `phpc compile <input> --emit-exe <output>`: a failed native compile with a missing runtime archive now removes any pre-existing output path before returning the error.
- Added focused CLI coverage for the missing-runtime archive failure so old native executables are not left behind after a failed compile.
- No WordPress behavior, PHP-core denominator, launcher behavior, generated progress output, or broad native support claim changed.

files changed:
- `crates/phpc_core/src/lib.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `swarm/handoffs/INT-01.md`

tests run:
- `git status --short --branch`
- `git fetch origin`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_compile_emit_exe_removes_stale_output_when_runtime_archive_is_missing`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli`
- `git diff --check`

pass/fail state:
- PASS: prior ahead state was preserved on `lane/INT-01-archive-0559` before recreating `lane/INT-01` from `origin/main`.
- PASS: focused stale-output regression fails the compile on a missing runtime archive, emits no stdout, and removes the stale output path.
- PASS: full `bootstrap_cli` test target reported 20 tests passing.
- PASS: `git diff --check`.

blockers:
- None for this integration-safety slice.

latest commit:
- `HEAD` after commit: Cover stale native output cleanup

next suggested slice:
- Keep INT-01 focused on integration safety; a useful follow-up is checking whether failed native links after temporary IR creation also need explicit stale-output cleanup coverage.
