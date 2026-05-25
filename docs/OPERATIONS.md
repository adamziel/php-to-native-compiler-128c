# Operations

This repo is operated by a supervisor session with many isolated worker lanes.

## Local Commands

```sh
cargo test
cargo run -p phpc -- run fixtures/bootstrap/hello.php
cargo run -p phpc -- compile fixtures/bootstrap/hello.php --emit-ir
```

## Worker Environment

```sh
export CARGO_BUILD_JOBS=1
export CARGO_INCREMENTAL=0
export RUST_TEST_THREADS=1
export CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/<lane-id>
```

## Dashboard

Progress is maintained in:

- `progress.md`
- `docs/progress.html`
- `swarm/*.json`

If served locally, use only port `8080`.

