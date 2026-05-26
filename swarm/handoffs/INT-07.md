# INT-07 Handoff

## Summary

- Milestone: Integration safety / status accuracy.
- Narrow denominator: static progress-output structure inside the existing non-mutating `scripts/refresh-progress.sh --check` path.
- Added section and milestone-row assertions for generated markdown and HTML output.
- Follow-up: aligned the generated HTML milestone table with the eight Markdown milestone rows and tightened `refresh-progress.sh --check` to require all eight HTML rows.
- Renamed the HTML dirty-count label to `Working tree dirty entries`, matching the branch-local measurement.
- Preserved existing live-value checks for repository, branch, supervised target, worker command count, slot label, launcher status, and HTML health rows.
- The structural checks intentionally avoid refreshed timestamps, branch/HEAD values, process counts, dirty counts, and other live counters.

## Files Changed

- `scripts/refresh-progress.sh`
- `swarm/handoffs/INT-07.md`

## Tests Run

- `scripts/refresh-progress.sh --check`
- `scripts/test-refresh-progress-labels.sh`
- `scripts/local-gate.sh`
- `git diff --check`

## Pass/Fail State

- Pass: progress label, structural, and non-mutating refresh checks completed with no output/errors.
- Pass: `git diff --check` reported no whitespace errors.

## Blockers

- None for this slice.
- M3 linked native executable emission remains blocked outside this slice by the missing linked execution implementation.

## Latest Commit

- Ported from `3d9bed1 Tighten progress structural check`.
- Follow-up helper port: `Align progress dashboard milestones`.

## Next Suggested Slice

- Add a focused failure-message helper for `refresh-progress.sh --check` so structural failures identify the missing section or wrong row count directly.
