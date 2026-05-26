# INT-04 Handoff

## Summary

Milestone: Integration / launcher observability.

Started a fresh slice from current `origin/main` on `lane/INT-04-fresh-0510`. Tightened `scripts/check-launcher-observability.sh` so the launcher log must show the latest started Codex session behind the latest stagger wait event. This catches logs that imply workers continued starting without the expected newer wait marker.

Narrow denominator: launcher log observability only. No compiler/runtime behavior, worker launch behavior, or progress percentage changed.

## Files Changed

- `scripts/check-launcher-observability.sh`
- `scripts/test-launcher-observability.sh`
- `swarm/handoffs/INT-04.md`

## Tests Run

- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 bash scripts/test-launcher-observability.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 bash scripts/check-launcher-observability.sh`
- `CARGO_TARGET_DIR=/home/ubuntu/phpc-targets/INT-04 bash scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass: focused launcher fixture rejects cadence drift.
- Pass: focused launcher fixture rejects stale session denominator.
- Pass: focused launcher fixture now rejects a latest started session without a newer wait event.
- Pass: live launcher observability check reports interactive-only workers, 480-second cadence, and no `codex -p` / `codex exec` workers.
- Pass: local gate completed status checks, shell fixtures, full workspace `cargo test --locked` with 106 tests, doc tests, and `git diff --check` under `/home/ubuntu/phpc-targets/INT-04`.

## Blockers

- No blocker for this integration-safety slice.

## Latest Commit

- This slice commit: `Check launcher wait after started session` on `lane/INT-04-fresh-0510`.

## Next Suggested Slice

- Add a progress publication fixture that validates `refresh-progress.sh --check` reports the live launcher auditor target consistently with `check-launcher-observability.sh`.
