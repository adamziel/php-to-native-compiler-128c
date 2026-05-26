# Support Matrix

## Current Supported PHP Surface

- `<?php echo "literal";`
- `<?php echo 'literal';`
- `<?php echo 123;`

String literal support distinguishes PHP single-quoted and double-quoted escape handling for committed escapes: single-quoted strings only unescape `\\` and `\'`, while double-quoted strings support the existing `\n`, `\r`, and `\t` escapes.

## Current Native Compiler Surface

- `phpc compile --emit-ir` emits bootstrap LLVM-like comments for string and integer echo literals.

## Current Harness Surface

- Minimal `.phpt` parser for `TEST`, `FILE`, `EXPECT`, and `SKIPIF` sections.
- Static `.phpt` metadata model for `SKIPIF` scripts and `XFAIL` reasons; `SKIPIF` is parsed but not executed yet.
- Parser-level `.phpt` harness input builder for tests with `FILE` and `EXPECT`; metadata is carried forward without outcome classification.

## Explicitly Unsupported

Everything else is unsupported until implemented and tested.
