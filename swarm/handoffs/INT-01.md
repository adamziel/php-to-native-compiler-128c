# INT-01 Handoff

summary:
- Milestone: M4/M6 require/include diagnostic coverage.
- Added focused parser coverage for missing semicolons after literal `include` and `require` statements.
- The new test asserts the existing diagnostic: `expected semicolon after include/require statement`.
- Preserved current diagnostic behavior for literal include/require execution, non-literal operands, and once-only include forms.
- No implementation behavior, WordPress-specific hack, native support claim, generated wrapper, shell-out, or `.phpt` denominator change.

files changed:
- `crates/phpc_core/src/parser.rs`
- `swarm/handoffs/INT-01.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 cargo test --locked -p phpc_core parser::tests::rejects_literal_include_require_without_semicolon -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-01 cargo test --locked -p phpc_core parser::tests::`
- `scripts/status-gate.sh`
- `git diff --check`

pass/fail state:
- PASS: focused missing-semicolon include/require diagnostic test passed.
- PASS: parser test subset passed, 30 tests.
- PASS: status gate completed with no diagnostics.
- PASS: diff hygiene check completed with no diagnostics.

blockers:
- None for this diagnostic-test slice.
- Broader WordPress bootstrap progress remains blocked on general non-literal `require` expression evaluation such as `ABSPATH . WPINC . '/version.php'`, which is outside this slice.

latest commit:
- `HEAD` after commit: Cover include require semicolon diagnostics

next suggested slice:
- Add a small expression-AST denominator for include/require operands that can represent string literal, constant fetch, and concatenation without expanding file-loading behavior beyond current literal-path support.
