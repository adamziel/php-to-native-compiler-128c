#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
progress_backup="$(mktemp)"
html_backup="$(mktemp)"
trap 'cp "$progress_backup" progress.md; cp "$html_backup" docs/progress.html; rm -rf "$tmpdir"; rm -f "$progress_backup" "$html_backup"' EXIT

launcher_log="$tmpdir/phpc-swarm-launcher.log"
cat > "$launcher_log" <<'LOG'
=== supervised restart: 2026-05-26T03:00:00Z SWARM_WORKER_COUNT=100 SWARM_INCLUDE_AUDITOR=1 SWARM_AUDITOR_FIRST=1 SWARM_LAUNCH_STAGGER_SECONDS=480 ===
2026-05-26T03:00:01Z launch: started Codex session 1/101 (AUD-01).
2026-05-26T03:00:01Z launch: waiting 480s before starting Codex session 2/101.
LOG

cp progress.md "$progress_backup"
cp docs/progress.html "$html_backup"

PHPC_SWARM_LAUNCHER_LOG="$launcher_log" scripts/refresh-progress.sh

grep -F -- "- Supervised agents target: \`100 workers + auditor\`" progress.md >/dev/null
grep -F -- "- Interactive launch cadence: \`480s\`" progress.md >/dev/null
grep -F -- "- Latest launcher event: \`2026-05-26T03:00:01Z launch: waiting 480s before starting Codex session 2/101.\`" progress.md >/dev/null
grep -F -- "<div class=\"metric\"><span>Supervised agents target</span><strong>100 workers + auditor</strong></div>" docs/progress.html >/dev/null
grep -F -- "<tr><td>Latest launcher event</td><td><code>2026-05-26T03:00:01Z launch: waiting 480s before starting Codex session 2/101.</code></td></tr>" docs/progress.html >/dev/null
