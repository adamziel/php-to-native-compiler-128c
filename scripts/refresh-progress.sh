#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

head="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
branch="$(git branch --show-current 2>/dev/null || echo none)"
dirty="$(git status --short 2>/dev/null | wc -l)"
if tmux list-windows -t phpc-swarm >/dev/null 2>&1; then
  windows="$(tmux list-windows -t phpc-swarm | wc -l)"
else
  windows="0"
fi
if tmux has-session -t phpc-pages-reporter 2>/dev/null; then
  pages_reporter="running"
else
  pages_reporter="not running"
fi
worker_loops="$(pgrep -fc '/scripts/worker-loop.sh' || true)"
active_codex="$(pgrep -fc 'codex exec' || true)"
slot_locks="$(find /tmp/phpc-swarm-codex-slots -maxdepth 1 -type d -name '*.lock' 2>/dev/null | wc -l)"
dirty_lanes="0"
if [ -d /home/ubuntu/phpc-worktrees ]; then
  dirty_lanes="$(
    for lane_dir in /home/ubuntu/phpc-worktrees/*; do
      [ -e "${lane_dir}/.git" ] || continue
      if [ "$(git -C "$lane_dir" status --porcelain 2>/dev/null | wc -l)" -gt 0 ]; then
        printf '.'
      fi
    done | wc -c
  )"
fi
state_files="$(find /home/ubuntu/phpc-worktrees -path '*/swarm/handoffs/*.state' -type f 2>/dev/null | wc -l)"
rate_limited="$(find /home/ubuntu/phpc-worktrees -path '*/swarm/handoffs/*.state' -type f -exec grep -l '^rate_limited' {} + 2>/dev/null | wc -l)"
active_cap="${SWARM_MAX_ACTIVE_CODEX:-50}"
supervised_target="${SWARM_WORKER_COUNT:-50} workers + auditor"
updated_display="$(date -u '+%Y-%m-%d %H:%M UTC')"
updated_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

tmp="$(mktemp)"
{
  echo "# PHP-To-Native Compiler Swarm Progress"
  echo
  echo "Last refreshed: ${updated_iso}"
  echo
  echo "## Current State"
  echo
  echo "- Repository: \`adamziel/php-to-native-compiler-128c\`"
  echo "- Branch: \`${branch}\`"
  echo "- Report base HEAD: \`${head}\`"
  echo "- Dirty entries: \`${dirty}\`"
  echo "- tmux windows in \`phpc-swarm\`: \`${windows}\`"
  echo "- Worker loops: \`${worker_loops}\`"
  echo "- Active \`codex exec\` processes: \`${active_codex}\`"
  echo "- Active Codex slot cap: \`${active_cap}\`"
  echo "- Active slot locks: \`${slot_locks}\`"
  echo "- Dirty lane worktrees preserved for review: \`${dirty_lanes}\`"
  echo "- Worker state files: \`${state_files}\`"
  echo "- Expected backend retry/rate-limit states: \`${rate_limited}\`"
  echo "- GitHub Pages reporter: \`${pages_reporter}\`"
  echo
  echo "## Milestone Estimates"
  echo
  echo "| Milestone | Denominator | Current | Status |"
  echo "| --- | --- | ---: | --- |"
  echo "| M1 COW shared mechanisms | RPR, DMB, CCA, regression matrix | 0% | Not started |"
  echo "| M2 runtime value ABI | value kinds and ownership semantics | 3% | Runtime-owned null and binary-string handles integrated |"
  echo "| M3 linked native execution | compile, link, run, compare | 0% | Queued |"
  echo "| M4 native lowering | interpreter-supported constructs lowered or rejected | 2% | String and integer echo literals; explicit variable diagnostic |"
  echo "| M5 PHP core .phpt harness | pinned php-src denominator | 2% | PHP-8.3 inventory pinned and minimal .phpt parser integrated |"
  echo "| M6 WordPress harness | pinned entrypoints/scenarios | 1% | WordPress 7.0 pinned; five entrypoints present; runner queued |"
  echo "| M7 object/SAPI/DB generality | required semantic families | 0% | Queued |"
  echo "| M8 performance after correctness | truthful native benchmarks | 0% | Deferred |"
  echo
  echo "## Latest Verification"
  echo
  if command -v cargo >/dev/null 2>&1; then
    echo "- cargo available: \`$(cargo --version)\`"
  else
    echo "- cargo unavailable"
  fi
  if command -v php >/dev/null 2>&1; then
    echo "- php available: \`$(php -v | head -n 1)\`"
  else
    echo "- php unavailable"
  fi
  if command -v clang >/dev/null 2>&1; then
    echo "- clang available: \`$(clang --version | head -n 1)\`"
  else
    echo "- clang unavailable"
  fi
  echo
  echo "## Current Blockers"
  sed -n '1,120p' swarm/blockers.md | sed 's/^/> /'
} > "$tmp"
mv "$tmp" progress.md

tmp="$(mktemp)"
{
  cat <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PHP-to-Native Compiler Swarm Progress</title>
  <style>
    body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, sans-serif; color: #17202a; background: #f6f7f9; }
    header { padding: 28px 32px; background: #17202a; color: #fff; }
    main { padding: 24px 32px; }
    h1 { margin: 0 0 8px; font-size: 28px; letter-spacing: 0; }
    h2 { margin-top: 28px; font-size: 20px; }
    table { width: 100%; border-collapse: collapse; background: #fff; border: 1px solid #d8dee6; }
    th, td { padding: 10px 12px; border-bottom: 1px solid #e6ebf1; text-align: left; vertical-align: top; font-size: 14px; }
    th { background: #edf1f5; font-weight: 650; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }
    .metric { background: #fff; border: 1px solid #d8dee6; padding: 14px; border-radius: 6px; }
    .metric strong { display: block; font-size: 22px; }
    .bar { height: 8px; background: #e1e7ef; border-radius: 999px; overflow: hidden; }
    .bar span { display: block; height: 100%; background: #2f7d5b; }
    code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
  </style>
</head>
<body>
  <header>
    <h1>PHP-to-Native Compiler Swarm Progress</h1>
    <div>From-scratch bootstrap for <code>adamziel/php-to-native-compiler-128c</code>. Last updated ${updated_display}.</div>
  </header>
  <main>
    <section class="grid">
      <div class="metric"><span>Supervised agents target</span><strong>${supervised_target}</strong></div>
      <div class="metric"><span>tmux windows</span><strong>${windows}</strong></div>
      <div class="metric"><span>Worker loops</span><strong>${worker_loops}</strong></div>
      <div class="metric"><span>Active codex exec</span><strong>${active_codex}</strong></div>
      <div class="metric"><span>Active slot cap</span><strong>${active_cap}</strong></div>
      <div class="metric"><span>Retry states</span><strong>${rate_limited}</strong></div>
      <div class="metric"><span>Pages reporter</span><strong>${pages_reporter}</strong></div>
      <div class="metric"><span>PHP core denominator</span><strong>19,346 .phpt</strong></div>
      <div class="metric"><span>WordPress denominator</span><strong>7.0 pinned</strong></div>
    </section>
    <h2>Milestones</h2>
    <table>
      <thead><tr><th>Milestone</th><th>Progress</th><th>Denominator</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td>M1 COW mechanisms</td><td><div class="bar"><span style="width:0%"></span></div>0%</td><td>RPR, DMB, CCA, regression matrix</td><td>Not started</td></tr>
        <tr><td>M2 runtime ABI</td><td><div class="bar"><span style="width:3%"></span></div>3%</td><td>PHP value kinds and ownership semantics</td><td>Runtime-owned null and binary-string handles integrated</td></tr>
        <tr><td>M3 linked native execution</td><td><div class="bar"><span style="width:0%"></span></div>0%</td><td>compile, link, run, compare</td><td>Not started</td></tr>
        <tr><td>M4 native lowering</td><td><div class="bar"><span style="width:2%"></span></div>2%</td><td>interpreter-supported constructs</td><td>String and integer echo literals; explicit variable diagnostic</td></tr>
        <tr><td>M5 PHP core harness</td><td><div class="bar"><span style="width:2%"></span></div>2%</td><td>PHP-8.3 branch, 19,346 .phpt files</td><td>Static inventory pinned; minimal parser integrated</td></tr>
        <tr><td>M6 WordPress harness</td><td><div class="bar"><span style="width:1%"></span></div>1%</td><td>WordPress 7.0 entrypoints</td><td>Source pinned; entrypoints present; runner queued</td></tr>
      </tbody>
    </table>
    <h2>Swarm Health</h2>
    <table>
      <thead><tr><th>Signal</th><th>Value</th></tr></thead>
      <tbody>
        <tr><td>Branch</td><td><code>${branch}</code></td></tr>
        <tr><td>Report base HEAD</td><td><code>${head}</code></td></tr>
        <tr><td>Main dirty entries</td><td><code>${dirty}</code></td></tr>
        <tr><td>Dirty lane worktrees preserved for review</td><td><code>${dirty_lanes}</code></td></tr>
        <tr><td>Active Codex slot cap</td><td><code>${active_cap}</code></td></tr>
        <tr><td>Active slot locks</td><td><code>${slot_locks}</code></td></tr>
        <tr><td>Worker state files</td><td><code>${state_files}</code></td></tr>
        <tr><td>Expected backend retry/rate-limit states</td><td><code>${rate_limited}</code></td></tr>
      </tbody>
    </table>
    <h2>Immediate Actions</h2>
    <table>
      <thead><tr><th>Action</th><th>Owner</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td>Keep ${supervised_target} topology alive</td><td>Supervisor</td><td>Running in <code>phpc-swarm</code></td></tr>
        <tr><td>Publish progress to GitHub Pages</td><td>Pages reporter</td><td><code>${pages_reporter}</code></td></tr>
        <tr><td>Map php-src denominator</td><td>PHPT lanes</td><td>Done: 19,346 .phpt files; runner queued</td></tr>
        <tr><td>Pin WordPress source</td><td>WP lanes</td><td>Done: WordPress 7.0; bootstrap runner queued</td></tr>
      </tbody>
    </table>
  </main>
</body>
</html>
HTML
} > "$tmp"
mv "$tmp" docs/progress.html
