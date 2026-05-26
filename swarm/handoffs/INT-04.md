# INT-04 Handoff

## Summary

Milestone: Integration / M6 WordPress bootstrap truthfulness and status accuracy.

Accepted a narrowed WP-06-style bootstrap check on current `main`: `phpc wordpress-bootstrap-check <wordpress-root>` inventories the five pinned entrypoints, runs the existing general compiler IR path on `wp-settings.php`, and reports the first general PHP blocker. No WordPress-specific compiler semantics were added.

Follow-up status slice: `scripts/refresh-progress.sh` derives the M6 WordPress bootstrap phrase from `swarm/wordpress-manifest.json` instead of hardcoding `runner queued`, so generated progress reports the current blocker: bootstrap check blocked in `wp-settings.php`.

## Files Changed

- `crates/phpc/src/main.rs`
- `crates/phpc/tests/bootstrap_cli.rs`
- `docs/WORDPRESS_COMPATIBILITY.md`
- `scripts/refresh-progress.sh`
- `scripts/test-refresh-progress-labels.sh`
- `swarm/blockers.md`
- `swarm/handoffs/INT-04.md`
- `swarm/integration.md`
- `swarm/test-matrix.md`
- `swarm/wordpress-manifest.json`
- `progress.md`
- `docs/progress.html`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test -p phpc --test bootstrap_cli cli_reports_wordpress_bootstrap_general_php_gap -- --nocapture`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 cargo run -p phpc -- wordpress-bootstrap-check /home/ubuntu/phpc-external/wordpress/wordpress`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 cargo test`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/test-refresh-progress-labels.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/main-wp-bootstrap CARGO_BUILD_JOBS=1 CARGO_INCREMENTAL=0 RUST_TEST_THREADS=1 scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass: focused `phpc` bootstrap CLI integration test.
- Pass: real pinned WordPress bootstrap check reports all five entrypoints present and blocks in `wp-settings.php` with a general parser gap at the opening docblock.
- Pass: full workspace `cargo test`, 58 passed.
- Pass: focused progress-label gate catches stale WordPress bootstrap `queued` text and raw launch-cadence rendering.
- Pass: status gate and manifest consistency checks.
- Pass: local coordination gate.
- Pass: diff whitespace check.

## Blockers

- M6 remains blocked on general PHP parser/compiler support for comments/docblocks before WordPress bootstrap can reach includes or request setup.

## Latest Commit

- Main port pending: WordPress bootstrap blocker check plus generated status-label derivation.

## Next Suggested Slice

- Reduce the reported WordPress blocker through a general M4 parser fixture for PHP comments/docblocks before statements, then re-run `phpc wordpress-bootstrap-check` to classify the next general PHP gap.
