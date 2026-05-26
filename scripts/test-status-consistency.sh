#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp progress.md "$tmpdir/progress.md"
cp docs/progress.html "$tmpdir/progress.html"

scripts/verify-status-consistency.sh

python3 - "$tmpdir/progress.md" "$tmpdir/progress.html" <<'PY'
import json
from pathlib import Path
import sys

progress_path = Path(sys.argv[1])
html_path = Path(sys.argv[2])
manifest = json.loads(Path("swarm/wordpress-manifest.json").read_text(encoding="utf-8"))
version = manifest["wordpress"]["version"]
entrypoints = len(manifest["entrypoints"])
bootstrap = manifest["results"]["bootstrap_check"]["bootstrap"]

replacements = 0
progress = progress_path.read_text(encoding="utf-8")
progress_current = f"WordPress {version} pinned; {entrypoints} entrypoints present; bootstrap check blocked in {bootstrap}"
progress_stale = f"WordPress {version} pinned; {entrypoints} entrypoints present; bootstrap runner queued"
replacements += progress.count(progress_current)
progress = progress.replace(progress_current, progress_stale)
progress_path.write_text(progress, encoding="utf-8")

html = html_path.read_text(encoding="utf-8")
html_current = f"Source pinned; {entrypoints} entrypoints present; bootstrap check blocked in {bootstrap}"
html_stale = f"Source pinned; {entrypoints} entrypoints present; bootstrap runner queued"
replacements += html.count(html_current)
html = html.replace(html_current, html_stale)
html_path.write_text(html, encoding="utf-8")

if replacements < 2:
    raise SystemExit(f"expected to replace current WordPress bootstrap status in both generated files, replaced {replacements}")
PY

if PHPC_PROGRESS_MD="$tmpdir/progress.md" PHPC_PROGRESS_HTML="$tmpdir/progress.html" \
  scripts/verify-status-consistency.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "verify-status-consistency.sh accepted stale WordPress bootstrap status text" >&2
  exit 1
fi

if ! grep -F "stale WordPress bootstrap wording" "$tmpdir/err" >/dev/null; then
  echo "verify-status-consistency.sh failed without the expected stale bootstrap diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi

cp progress.md "$tmpdir/progress.md"
cp docs/progress.html "$tmpdir/progress.html"

python3 - "$tmpdir/progress.html" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
html = path.read_text(encoding="utf-8")
html = html.replace(
    "<tr><td>Report base HEAD</td><td><code>",
    "<tr><td>Report base HEAD</td><td><code>stale-",
    1,
)
path.write_text(html, encoding="utf-8")
PY

if PHPC_PROGRESS_MD="$tmpdir/progress.md" PHPC_PROGRESS_HTML="$tmpdir/progress.html" \
  scripts/verify-status-consistency.sh >"$tmpdir/out" 2>"$tmpdir/err"; then
  echo "verify-status-consistency.sh accepted mismatched published report HEAD fields" >&2
  exit 1
fi

if ! grep -F "published status mismatch for Report base HEAD" "$tmpdir/err" >/dev/null; then
  echo "verify-status-consistency.sh failed without the expected published status diagnostic" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
