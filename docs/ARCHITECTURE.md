# Architecture

The compiler is split into:

- `crates/phpc`: CLI.
- `crates/phpc_core`: parser, interpreter path, compiler path.
- `crates/php_runtime`: runtime ABI intended for linked native executables.

The architecture should evolve toward:

1. PHP parser and AST.
2. Interpreter/reference semantics for supported constructs.
3. Runtime value ABI for PHP values.
4. Native lowering through runtime helpers.
5. Linked executable runner with differential comparison.

