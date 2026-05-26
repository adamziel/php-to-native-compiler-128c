#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

php_core_backup="$(mktemp)"
wordpress_backup="$(mktemp)"
integration_backup="$(mktemp)"
trap 'cp "$php_core_backup" swarm/php-core-manifest.json; cp "$wordpress_backup" swarm/wordpress-manifest.json; cp "$integration_backup" swarm/integration.md; rm -f "$php_core_backup" "$wordpress_backup" "$integration_backup"' EXIT

cp swarm/php-core-manifest.json "$php_core_backup"
cp swarm/wordpress-manifest.json "$wordpress_backup"
cp swarm/integration.md "$integration_backup"

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
cp "$integration_backup" swarm/integration.md

python3 - <<'PY'
import json
from pathlib import Path

path = Path("swarm/php-core-manifest.json")
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["results"]["native"]["pass"] = manifest["denominator"]["runnable"] + 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

if scripts/status-gate.sh >/tmp/phpc-status-gate-test.out 2>/tmp/phpc-status-gate-test.err; then
  echo "status-gate.sh accepted php-core results above the runnable denominator" >&2
  exit 1
fi

if ! grep -F "results.native pass/fail total must not exceed denominator.runnable" /tmp/phpc-status-gate-test.err >/dev/null; then
  echo "status-gate.sh failed without the expected runnable-results diagnostic" >&2
  cat /tmp/phpc-status-gate-test.err >&2
  exit 1
fi

cp "$php_core_backup" swarm/php-core-manifest.json
cp "$wordpress_backup" swarm/wordpress-manifest.json
cp "$integration_backup" swarm/integration.md

python3 - <<'PY'
from pathlib import Path

path = Path("swarm/integration.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "| P1 | LINK follow-up lanes | M3 linked/native path | First LINK-02-style executable path integrated for literal echo fixtures | Extend native run/differential helpers carefully; accept only slices that run executables and compare stdout, stderr, and exit status without broad support claims. |",
    "| P1 | `LINK-01`, `LINK-02` | M3 linked/native path | Stale reviewed candidates | Extend the accepted executable path only with compile/link/run comparison tests. |",
)
path.write_text(text, encoding="utf-8")
PY

if scripts/status-gate.sh >/tmp/phpc-status-gate-test.out 2>/tmp/phpc-status-gate-test.err; then
  echo "status-gate.sh accepted terminal integration lanes in the priority table" >&2
  exit 1
fi

if ! grep -F "integration priority table lists lanes with terminal decisions: LINK-01, LINK-02" /tmp/phpc-status-gate-test.err >/dev/null; then
  echo "status-gate.sh failed without the expected stale integration diagnostic" >&2
  cat /tmp/phpc-status-gate-test.err >&2
  exit 1
fi

cp "$php_core_backup" swarm/php-core-manifest.json
cp "$wordpress_backup" swarm/wordpress-manifest.json
cp "$integration_backup" swarm/integration.md

python3 - <<'PY'
from pathlib import Path

path = Path("swarm/integration.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "## Current Integration Queue\n\nActive integration work is follow-up only. The first M3 linked executable path is integrated for the literal echo denominator, and reviewed committed candidates are tracked below instead of being advertised as active work.\n\n## Reviewed Candidates",
    "## Current Integration Queue\n\nActive integration work is follow-up only.\n\n## Committed Lane Candidates\n\n| Lane | Commit | Area | Artifact | Review instruction |\n| --- | --- | --- | --- | --- |\n| `PHPT-03` | `ea96852` | `.phpt` harness | Skip/XFAIL metadata in `phpt.rs` plus handoff | Reviewed already. |\n\n## Reviewed Candidates",
)
path.write_text(text, encoding="utf-8")
PY

if scripts/status-gate.sh >/tmp/phpc-status-gate-test.out 2>/tmp/phpc-status-gate-test.err; then
  echo "status-gate.sh accepted an already reviewed committed candidate" >&2
  exit 1
fi

if ! grep -F "integration committed-candidate table lists already reviewed lanes: PHPT-03" /tmp/phpc-status-gate-test.err >/dev/null; then
  echo "status-gate.sh failed without the expected reviewed-candidate diagnostic" >&2
  cat /tmp/phpc-status-gate-test.err >&2
  exit 1
fi

cp "$php_core_backup" swarm/php-core-manifest.json
cp "$wordpress_backup" swarm/wordpress-manifest.json
cp "$integration_backup" swarm/integration.md

python3 - <<'PY'
from pathlib import Path

path = Path("swarm/integration.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "Preserve the current `phpc compile <input.php> --emit-exe <output>` executable path and keep any broader native claims tied to tested fixture denominators.",
    "Keep `--emit-exe` explicitly unsupported until a real linked executable path exists.",
)
path.write_text(text, encoding="utf-8")
PY

if scripts/status-gate.sh >/tmp/phpc-status-gate-test.out 2>/tmp/phpc-status-gate-test.err; then
  echo "status-gate.sh accepted obsolete pre-M3 emit-exe wording" >&2
  exit 1
fi

if ! grep -F "integration log contains obsolete pre-M3 emit-exe wording" /tmp/phpc-status-gate-test.err >/dev/null; then
  echo "status-gate.sh failed without the expected pre-M3 wording diagnostic" >&2
  cat /tmp/phpc-status-gate-test.err >&2
  exit 1
fi

cp "$php_core_backup" swarm/php-core-manifest.json
cp "$wordpress_backup" swarm/wordpress-manifest.json
cp "$integration_backup" swarm/integration.md
scripts/status-gate.sh
