summary: Ported the useful request-header runtime state from lane/SAPI-05 onto current main without replacing the existing runtime value ABI. The runtime now has request-owned response header storage with insertion order, case-insensitive replacement, duplicate-preserving append mode, CR/LF rejection, empty-header rejection, sent-state locking, and C ABI accessors.

files changed:
- `crates/php_runtime/src/lib.rs`
- `docs/NATIVE_RUNTIME_ABI.md`
- `swarm/handoffs/SAPI-05.md`

tests run:
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-sapi-request CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p php_runtime`
- `scripts/verify-runtime-abi-docs.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-sapi-request CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-sapi-request CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `git diff --check`

pass/fail state: pass. Runtime unit tests passed with 19 tests, full workspace tests passed with 68 tests, ABI documentation verification reported 18 exported helpers, 7 constants, and 19 classified tests, the local gate passed, and whitespace checks passed.

blockers:
- This is runtime/SAPI storage only. PHP `header()` parsing/interpreter/native lowering is not wired yet.

latest commit:
- pending

next suggested slice:
- Add a minimal compiler-facing `header()` semantic fixture or a native request lifecycle once parser/function-call support exists.
