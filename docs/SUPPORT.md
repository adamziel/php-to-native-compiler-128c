# Support Matrix

## Current Supported PHP Surface

- `<?php echo "literal";`
- `<?php echo 'literal';`
- `<?php echo 123;`
- `<?php echo true;`
- `<?php echo false;`
- `<?php echo null;`
- `<?php define('NAME', 'literal');` as a top-level statement that records a
  string constant and produces no output in `phpc run`.
- `<?php global $name, $other;` as a top-level declaration that is a no-op in
  the current non-function/global execution model.
- A final supported `echo` statement may omit the semicolon when it is immediately
  followed by the closing PHP tag, for example `<?php echo "literal" ?>`.
- Whitespace and PHP comments (`/* ... */`, `// ...`, `# ...`) before supported statements.

String literal support distinguishes PHP single-quoted and double-quoted escape handling for committed escapes: single-quoted strings only unescape `\\` and `\'`, while double-quoted strings support the existing `\n`, `\r`, and `\t` escapes.

## Current Native Compiler Surface

- `phpc compile --emit-ir` emits bootstrap LLVM-like comments for string, integer, boolean, and null echo literals.
- `phpc compile --emit-ir` accepts top-level `define('NAME', 'literal');`
  statements and reports them as string-constant definitions.
- `phpc compile --emit-ir` accepts top-level `global $name, $other;`
  declarations and reports them as no-output global declarations.
- `phpc compile <input.php> --emit-exe <output>` links a native executable for string, integer, boolean, and null echo literals through `php_runtime::phpc_echo`.

## Current Harness Surface

- Minimal `.phpt` parser for `TEST`, `FILE`, `FILEEOF`, `EXPECT`, `EXPECTF`, `EXPECTREGEX`, and `SKIPIF` sections.
- Static `.phpt` metadata model for `SKIPIF` scripts and `XFAIL` reasons.
- Parser-level `.phpt` harness input builder for tests with `FILE` or `FILEEOF` and one expectation section; metadata is carried forward without outcome classification.
- `.phpt` files with both `FILE` and `FILEEOF` sections are rejected as ambiguous.
- Minimal `phpc run` `.phpt` evaluator for parsed tests with `FILE` or `FILEEOF` plus literal `EXPECT` or `EXPECTF`; it normalizes line endings and classifies pass, fail, skip, xfail, unexpected-pass, unsupported matcher, and interpreter-error outcomes.
- `SKIPIF` execution is limited to scripts supported by `phpc run`; output beginning with `skip` classifies the test as skipped, empty or non-skip output continues to the main test, and unsupported `SKIPIF` scripts report interpreter errors.
- CLI status probe: `phpc phpt-run <input.phpt>` runs a single `.phpt` through the existing `phpc run` evaluator and prints a machine-readable status report. It does not execute native code.
- Recorded php-src runnable subset: `tests/basic/001.phpt` from the pinned PHP-8.3 tree executes through `phpc phpt-run` and currently reports `fail` because exact `EXPECT` comparison includes a trailing newline while `phpc run` emits the literal output without one.

## Explicitly Unsupported

Everything else is unsupported until implemented and tested.
