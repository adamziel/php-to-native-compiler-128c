# INT-02 Handoff

## Summary

- Milestone: Integration/M4.
- Ported the INT-02 single-quoted string escape fix onto current `main`.
- Single-quoted strings now preserve `\n` literally while still unescaping `\\` and `\'`, matching PHP single-quoted string behavior for this supported subset.
- Rejected broader boolean/function candidates for this slice because they require wider parser/interpreter/IR/docs coordination.

## Files Changed

- `crates/phpc_core/src/parser.rs`
- `crates/phpc_core/src/lib.rs`
- `docs/SUPPORT.md`
- `swarm/integration.md`
- `swarm/handoffs/INT-02.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-02 CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc_core run_preserves_single_quoted_backslash_n`
- `php -r "echo 'a\\nb';" | od -An -tx1`
- `scripts/verify-status-consistency.sh`
- `git diff --check`

## Pass/Fail State

- PASS: `phpc_core` focused tests on the lane.
- PASS: focused runtime regression `run_preserves_single_quoted_backslash_n`.
- PASS: system PHP oracle bytes for `'a\\nb'` are `61 5c 6e 62`.
- PASS: status consistency gate on the lane.
- PASS: diff hygiene on the lane.
- BLOCKED on the lane only: `scripts/local-gate.sh` was absent before this stale lane was ported to current `main`.
- BLOCKED: `cargo fmt --all` cannot run because this toolchain lacks `cargo-fmt`/`rustfmt`.

## Latest Lane Commit

- `b7d5ad1` - Fix single quoted string escape parsing.

## Integration Note

- Cherry-picked only the substantive parser/runtime/docs slice from the stale INT-02 branch; did not merge the full stale branch.

## Next Suggested Slice

- Verify the port on current `main` with `phpc_core`, `scripts/local-gate.sh`, and diff hygiene before integrating additional INT-02 work.
