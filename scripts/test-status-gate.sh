#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

php_core_backup="$(mktemp)"
wordpress_backup="$(mktemp)"
trap 'cp "$php_core_backup" swarm/php-core-manifest.json; cp "$wordpress_backup" swarm/wordpress-manifest.json; rm -f "$php_core_backup" "$wordpress_backup"' EXIT

cp swarm/php-core-manifest.json "$php_core_backup"
cp swarm/wordpress-manifest.json "$wordpress_backup"

scripts/status-gate.sh

python3 - <<'PY'
import json
from pathlib import Path

path = Path("swarm/php-core-manifest.json")
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["denominator"]["mapped"] = manifest["denominator"]["total_phpt"] - 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

if scripts/status-gate.sh >/tmp/phpc-status-gate-test.out 2>/tmp/phpc-status-gate-test.err; then
  echo "status-gate.sh accepted a mismatched php-core denominator" >&2
  exit 1
fi

if ! grep -F "denominator.mapped must match denominator.total_phpt" /tmp/phpc-status-gate-test.err >/dev/null; then
  echo "status-gate.sh failed without the expected denominator diagnostic" >&2
  cat /tmp/phpc-status-gate-test.err >&2
  exit 1
fi

cp "$php_core_backup" swarm/php-core-manifest.json
cp "$wordpress_backup" swarm/wordpress-manifest.json
scripts/status-gate.sh
