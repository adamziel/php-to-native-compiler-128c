# INT-01 Handoff

summary:
- Milestone: M4/M6 require/include diagnostic coverage.
- Integrated focused parser coverage for `require_once`, matching the existing `include_once` unsupported behavior.
- The new test covers both literal and expression operands and asserts the existing once-only diagnostic: `include_once/require_once execution is not implemented`.
- Preserved current diagnostic behavior for non-literal `require`/`include` operands and once-only include forms.
- No implementation behavior, WordPress-specific hack, native support claim, generated wrapper, shell-out, or `.phpt` denominator change.

files changed:
- `crates/phpc_core/src/parser.rs`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 cargo test --locked -p phpc_core parser::tests::rejects_require_once_with_precise_unsupported_diagnostic -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 cargo test --locked -p phpc_core parser::tests::`
- `scripts/status-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused `require_once` unsupported diagnostic test passed.
- PASS: parser test subset passed, 29 tests.
- PASS: status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.

blockers:
- None for this diagnostic-test slice.
- Broader WordPress bootstrap progress remains blocked on general non-literal `require` expression evaluation such as `ABSPATH . WPINC . '/version.php'`, which is outside this slice.

latest commit:
- `HEAD` after commit: Cover require_once parser diagnostic symmetry

next suggested slice:
- Add a small expression-AST denominator for include/require operands that can represent string literal, constant fetch, and concatenation without expanding file-loading behavior beyond current literal-path support.
