# Support Matrix

## Current Supported PHP Surface

- `<?php echo "literal";`
- `<?php echo 'literal';`
- `<?php echo 123;`
- A final supported `echo` statement may omit the semicolon when it is immediately
  followed by the closing PHP tag, for example `<?php echo "literal" ?>`.

String literal support distinguishes PHP single-quoted and double-quoted escape handling for committed escapes: single-quoted strings only unescape `\\` and `\'`, while double-quoted strings support the existing `\n`, `\r`, and `\t` escapes.

## Current Native Compiler Surface

- `phpc compile --emit-ir` emits bootstrap LLVM-like comments for string and integer echo literals.
- `phpc compile <input.php> --emit-exe <output>` links a native executable for string and integer echo literals through `php_runtime::phpc_echo`.

## Current Harness Surface

- Minimal `.phpt` parser for `TEST`, `FILE`, `FILEEOF`, `EXPECT`, `EXPECTF`, `EXPECTREGEX`, and `SKIPIF` sections.
- Static `.phpt` metadata model for `SKIPIF` scripts and `XFAIL` reasons; `SKIPIF` is parsed but not executed yet.
- Parser-level `.phpt` harness input builder for tests with `FILE` or `FILEEOF` and one expectation section; metadata is carried forward without outcome classification.
- `.phpt` files with both `FILE` and `FILEEOF` sections are rejected as ambiguous.
- Minimal `phpc run` `.phpt` evaluator for parsed tests with `FILE` plus literal `EXPECT`; it normalizes line endings and classifies pass, fail, xfail, unexpected-pass, unsupported matcher, and interpreter-error outcomes.

## Explicitly Unsupported

Everything else is unsupported until implemented and tested.
