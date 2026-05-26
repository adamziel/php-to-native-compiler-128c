# Support Matrix

## Current Supported PHP Surface

- `<?php echo "literal";`
- `<?php echo 'literal';`
- `<?php echo 123;`

## Current Native Compiler Surface

- `phpc compile --emit-ir` emits bootstrap LLVM-like comments for string and integer echo literals.

## Current Harness Surface

- Minimal `.phpt` parser for `TEST`, `FILE`, `EXPECT`, and `SKIPIF` sections.
- Static `.phpt` metadata model for `SKIPIF` scripts and `XFAIL` reasons; `SKIPIF` is parsed but not executed yet.

## Explicitly Unsupported

Everything else is unsupported until implemented and tested.
