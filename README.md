# PHP To Native Compiler 128c

This repository is the from-scratch 128-core swarm build of a PHP-to-native compiler.

The project is intentionally organized around truthful execution evidence:

- `phpc run` is the interpreter/reference path.
- `phpc compile` is the native compiler path.
- Linked native execution must compare against `phpc run` and system PHP.
- PHP core `.phpt` and WordPress compatibility are tracked as denominated harnesses.

See:

- [goal.md](goal.md)
- [prompt.md](prompt.md)
- [progress.md](progress.md)
- [progress dashboard](docs/progress.html)

## Current Bootstrap

This repo starts from scratch. The initial implementation is a minimal Rust workspace with a `phpc` CLI surface and placeholder compiler/runtime modules. Workers must expand it through small, tested slices.

```sh
cargo test
cargo run -p phpc -- run fixtures/bootstrap/hello.php
cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir
```

## Swarm

The supervisor maintains active lanes in `swarm/`:

- `swarm/queue.md`
- `swarm/agents.md`
- `swarm/test-matrix.md`
- `swarm/blockers.md`
- `swarm/php-core-manifest.json`
- `swarm/wordpress-manifest.json`

Workers must keep changes small, testable, and mapped to a named milestone.

