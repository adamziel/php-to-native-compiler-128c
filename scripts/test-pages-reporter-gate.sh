#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

php_core_backup="$(mktemp)"
progress_backup="$(mktemp)"
html_backup="$(mktemp)"
fake_bin="$(mktemp -d)"
git_log="$(mktemp)"
out_log="$(mktemp)"
err_log="$(mktemp)"
real_git="$(command -v git)"
trap 'cp "$php_core_backup" swarm/php-core-manifest.json; cp "$progress_backup" progress.md; cp "$html_backup" docs/progress.html; rm -rf "$fake_bin"; rm -f "$php_core_backup" "$progress_backup" "$html_backup" "$git_log" "$out_log" "$err_log"' EXIT

cp swarm/php-core-manifest.json "$php_core_backup"
cp progress.md "$progress_backup"
cp docs/progress.html "$html_backup"

cat > "$fake_bin/git" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = "commit" ]; then
  echo commit >> "$PHP_PAGES_TEST_GIT_LOG"
fi
exec "$PHP_PAGES_TEST_REAL_GIT" "$@"
SH
chmod +x "$fake_bin/git"

python3 - <<'PY'
import json
from pathlib import Path

path = Path("swarm/php-core-manifest.json")
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["denominator"]["mapped"] = manifest["denominator"]["total_phpt"] - 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

if PHP_PAGES_TEST_GIT_LOG="$git_log" PHP_PAGES_TEST_REAL_GIT="$real_git" PATH="$fake_bin:$PATH" PAGES_REPORT_ONCE=1 scripts/pages-reporter-loop.sh >"$out_log" 2>"$err_log"; then
  echo "pages reporter accepted a failing status gate" >&2
  exit 1
fi

if [ -s "$git_log" ]; then
  echo "pages reporter attempted to commit after a failing status gate" >&2
  cat "$git_log" >&2
  exit 1
fi

if ! grep -F "denominator.mapped must match denominator.total_phpt" "$err_log" >/dev/null; then
  echo "pages reporter failed without the expected status-gate diagnostic" >&2
  cat "$err_log" >&2
  exit 1
fi
