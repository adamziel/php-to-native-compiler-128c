#!/usr/bin/env bash
set -euo pipefail

mode="${1:-refresh}"
if [ "$mode" != "refresh" ] && [ "$mode" != "--check" ]; then
  echo "usage: scripts/refresh-progress.sh [--check]" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
source "$repo_root/scripts/swarm-interactive.sh"

repo="adamziel/php-to-native-compiler-128c"
head="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
branch="$(git branch --show-current 2>/dev/null || echo none)"
dirty="$(git status --short 2>/dev/null | wc -l)"
if tmux list-windows -t =phpc-swarm >/dev/null 2>&1; then
  windows="$(tmux list-windows -t =phpc-swarm | wc -l)"
  pane_pids="$(
    tmux list-panes -a -F '#{session_name} #{pane_pid}' 2>/dev/null |
      awk '$1 == "phpc-swarm" { print $2 }' |
      tr '\n' ' '
  )"
  worker_loops="$(
    ps -eo pid=,ppid=,args= |
      awk -v pane_pids="$pane_pids" '
        BEGIN {
          split(pane_pids, ids)
          for (i in ids) {
            if (ids[i] != "") {
              pane[ids[i]] = 1
            }
          }
        }
        ($1 in pane || $2 in pane) && index($0, "codex") && index($0, "codex exec") == 0 { count++ }
        END { print count + 0 }
      '
  )"
else
  windows="0"
  worker_loops="0"
fi
if tmux has-session -t =phpc-pages-reporter 2>/dev/null; then
  pages_reporter="running"
else
  pages_reporter="not running"
fi
if tmux has-session -t =phpc-swarm-launcher 2>/dev/null; then
  swarm_launcher="running"
else
  swarm_launcher="not running"
fi
latest_launcher_event="$(
  { grep -E 'launch:' /tmp/phpc-swarm-launcher.log 2>/dev/null || true; } |
    tail -n 1
)"
if [ -z "$latest_launcher_event" ]; then
  latest_launcher_event="none"
fi
active_codex="$(swarm_codex_exec_count)"
slot_locks="0"
if [ -d /tmp/phpc-swarm-codex-slots ]; then
  slot_locks="$(find /tmp/phpc-swarm-codex-slots -maxdepth 1 -type d -name '*.lock' 2>/dev/null | wc -l)"
fi
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
state_files="0"
if [ -d /home/ubuntu/phpc-worktrees ]; then
  state_files="$(find /home/ubuntu/phpc-worktrees -path '*/swarm/handoffs/*.state' -type f 2>/dev/null | wc -l)"
fi
rate_limited="$(
  {
    find /home/ubuntu/phpc-worktrees -path '*/swarm/handoffs/*.state' -type f -exec grep -l '^rate_limited' {} + 2>/dev/null || true
  } | wc -l
)"
active_cap="interactive"
supervised_target="${SWARM_WORKER_COUNT:-50} workers + auditor"
launch_cadence="${SWARM_LAUNCH_STAGGER_SECONDS:-unknown}"
manifest_vars="$(
  python3 - <<'PY'
import json
import pathlib

root = pathlib.Path.cwd()
php_manifest = json.loads((root / "swarm/php-core-manifest.json").read_text(encoding="utf-8"))
wp_manifest = json.loads((root / "swarm/wordpress-manifest.json").read_text(encoding="utf-8"))

php_phpt_total = int(php_manifest["denominator"]["total_phpt"])
wp_version = wp_manifest["wordpress"]["version"]
wp_entrypoints = len(wp_manifest["entrypoints"])

print(f"php_phpt_total={php_phpt_total}")
print(f"php_phpt_total_display='{php_phpt_total:,}'")
print(f"wp_version={wp_version!r}")
print(f"wp_entrypoints={wp_entrypoints}")
PY
)"
eval "$manifest_vars"
if [ "$mode" = "--check" ]; then
  updated_display="CHECK MODE"
  updated_iso="CHECK-MODE"
else
  updated_display="$(date -u '+%Y-%m-%d %H:%M UTC')"
  updated_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

progress_out="progress.md"
html_out="docs/progress.html"
if [ "$mode" = "--check" ]; then
  progress_out="$(mktemp)"
  html_out="$(mktemp)"
  trap 'rm -f "$progress_out" "$html_out"' EXIT
fi

tmp="$(mktemp)"
{
  echo "# PHP-To-Native Compiler Swarm Progress"
  echo
  echo "Last refreshed: ${updated_iso}"
  echo
  echo "## Current State"
  echo
  echo "- Repository: \`${repo}\`"
  echo "- Branch: \`${branch}\`"
  echo "- Report base HEAD: \`${head}\`"
  echo "- Dirty entries: \`${dirty}\`"
  echo "- tmux windows in \`phpc-swarm\`: \`${windows}\`"
  echo "- Supervised agents target: \`${supervised_target}\`"
  echo "- Interactive launch cadence: \`${launch_cadence}s\`"
  echo "- Staggered swarm launcher: \`${swarm_launcher}\`"
  echo "- Latest launcher event: \`${latest_launcher_event}\`"
  echo "- Interactive Codex panes: \`${worker_loops}\`"
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
  echo "| M5 PHP core .phpt harness | PHP-8.3 branch, ${php_phpt_total_display} \`.phpt\` files | 2% | PHP-8.3 inventory pinned and minimal .phpt parser integrated |"
  echo "| M6 WordPress harness | pinned entrypoints/scenarios | 1% | WordPress ${wp_version} pinned; ${wp_entrypoints} entrypoints present; runner queued |"
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
mv "$tmp" "$progress_out"

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
    <div>From-scratch bootstrap for <code>${repo}</code>. Last updated ${updated_display}.</div>
  </header>
  <main>
    <section class="grid">
      <div class="metric"><span>Supervised agents target</span><strong>${supervised_target}</strong></div>
      <div class="metric"><span>Launch cadence</span><strong>${launch_cadence}s</strong></div>
      <div class="metric"><span>Staggered launcher</span><strong>${swarm_launcher}</strong></div>
      <div class="metric"><span>tmux windows</span><strong>${windows}</strong></div>
      <div class="metric"><span>Interactive Codex panes</span><strong>${worker_loops}</strong></div>
      <div class="metric"><span>Active codex exec</span><strong>${active_codex}</strong></div>
      <div class="metric"><span>Active slot cap</span><strong>${active_cap}</strong></div>
      <div class="metric"><span>Retry states</span><strong>${rate_limited}</strong></div>
      <div class="metric"><span>Pages reporter</span><strong>${pages_reporter}</strong></div>
      <div class="metric"><span>PHP core denominator</span><strong>${php_phpt_total_display} .phpt</strong></div>
      <div class="metric"><span>WordPress denominator</span><strong>${wp_version} pinned</strong></div>
    </section>
    <h2>Milestones</h2>
    <table>
      <thead><tr><th>Milestone</th><th>Progress</th><th>Denominator</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td>M1 COW mechanisms</td><td><div class="bar"><span style="width:0%"></span></div>0%</td><td>RPR, DMB, CCA, regression matrix</td><td>Not started</td></tr>
        <tr><td>M2 runtime ABI</td><td><div class="bar"><span style="width:3%"></span></div>3%</td><td>PHP value kinds and ownership semantics</td><td>Runtime-owned null and binary-string handles integrated</td></tr>
        <tr><td>M3 linked native execution</td><td><div class="bar"><span style="width:0%"></span></div>0%</td><td>compile, link, run, compare</td><td>Not started</td></tr>
        <tr><td>M4 native lowering</td><td><div class="bar"><span style="width:2%"></span></div>2%</td><td>interpreter-supported constructs</td><td>String and integer echo literals; explicit variable diagnostic</td></tr>
        <tr><td>M5 PHP core harness</td><td><div class="bar"><span style="width:2%"></span></div>2%</td><td>PHP-8.3 branch, ${php_phpt_total_display} .phpt files</td><td>Static inventory pinned; minimal parser integrated</td></tr>
        <tr><td>M6 WordPress harness</td><td><div class="bar"><span style="width:1%"></span></div>1%</td><td>WordPress ${wp_version} entrypoints</td><td>Source pinned; ${wp_entrypoints} entrypoints present; runner queued</td></tr>
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
        <tr><td>Latest launcher event</td><td><code>${latest_launcher_event}</code></td></tr>
      </tbody>
    </table>
    <h2>Immediate Actions</h2>
    <table>
      <thead><tr><th>Action</th><th>Owner</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td>Keep ${supervised_target} topology alive</td><td>Supervisor</td><td>Running in <code>phpc-swarm</code></td></tr>
        <tr><td>Publish progress to GitHub Pages</td><td>Pages reporter</td><td><code>${pages_reporter}</code></td></tr>
        <tr><td>Map php-src denominator</td><td>PHPT lanes</td><td>Done: ${php_phpt_total_display} .phpt files; runner queued</td></tr>
        <tr><td>Pin WordPress source</td><td>WP lanes</td><td>Done: WordPress ${wp_version}; bootstrap runner queued</td></tr>
      </tbody>
    </table>
  </main>
</body>
</html>
HTML
} > "$tmp"
mv "$tmp" "$html_out"

if [ "$mode" = "--check" ]; then
  grep -F -- "- Repository: \`${repo}\`" "$progress_out" >/dev/null
  grep -F -- "- Branch: \`${branch}\`" "$progress_out" >/dev/null
  grep -F -- "- Supervised agents target: \`${supervised_target}\`" "$progress_out" >/dev/null
  grep -F -- "- Staggered swarm launcher: \`${swarm_launcher}\`" "$progress_out" >/dev/null
  grep -F -- "From-scratch bootstrap for <code>${repo}</code>" "$html_out" >/dev/null
  grep -F -- "<tr><td>Latest launcher event</td><td><code>" "$html_out" >/dev/null
fi
