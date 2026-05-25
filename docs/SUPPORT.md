# Support Matrix

## Current Supported PHP Surface

- `<?php echo "literal";`
- `<?php echo 'literal';`

## Current Native Compiler Surface

- `phpc compile --emit-ir` emits bootstrap LLVM-like comments for echo literals.

## Explicitly Unsupported

Everything else is unsupported until implemented and tested.

