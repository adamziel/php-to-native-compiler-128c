#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmpdir="$(mktemp -d)"
integration_backup="$(mktemp)"
queue_backup="$(mktemp)"
trap 'cp "$integration_backup" swarm/integration.md; cp "$queue_backup" swarm/queue.md; rm -rf "$tmpdir"; rm -f "$integration_backup" "$queue_backup"' EXIT

php_core_fixture="$tmpdir/php-core-manifest.json"
wordpress_fixture="$tmpdir/wordpress-manifest.json"
out_file="$tmpdir/status-gate.out"
err_file="$tmpdir/status-gate.err"

cp swarm/integration.md "$integration_backup"
cp swarm/queue.md "$queue_backup"

reset_fixtures() {
  cp swarm/php-core-manifest.json "$php_core_fixture"
  cp swarm/wordpress-manifest.json "$wordpress_fixture"
}

restore_integration() {
  cp "$integration_backup" swarm/integration.md
}

restore_queue() {
  cp "$queue_backup" swarm/queue.md
}

run_fixture_gate() {
  PHP_CORE_MANIFEST_PATH="$php_core_fixture" \
    WORDPRESS_MANIFEST_PATH="$wordpress_fixture" \
    scripts/status-gate.sh
}

expect_fixture_failure() {
  local expected="$1"
  local label="$2"

  if run_fixture_gate >"$out_file" 2>"$err_file"; then
    echo "status-gate.sh accepted $label" >&2
    exit 1
  fi

  if ! grep -F "$expected" "$err_file" >/dev/null; then
    echo "status-gate.sh failed without the expected diagnostic for $label" >&2
    cat "$err_file" >&2
    exit 1
  fi
}

expect_status_failure() {
  local expected="$1"
  local label="$2"

  if scripts/status-gate.sh >"$out_file" 2>"$err_file"; then
    echo "status-gate.sh accepted $label" >&2
    exit 1
  fi

  if ! grep -F "$expected" "$err_file" >/dev/null; then
    echo "status-gate.sh failed without the expected diagnostic for $label" >&2
    cat "$err_file" >&2
    exit 1
  fi
}

reset_fixtures
scripts/status-gate.sh
run_fixture_gate

PHP_CORE_FIXTURE="$php_core_fixture" python3 - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["PHP_CORE_FIXTURE"])
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["denominator"]["mapped"] = manifest["denominator"]["total_phpt"] - 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

expect_fixture_failure \
  "denominator.mapped must match denominator.total_phpt" \
  "a mismatched php-core denominator"

reset_fixtures

PHP_CORE_FIXTURE="$php_core_fixture" python3 - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["PHP_CORE_FIXTURE"])
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["results"]["native"]["pass"] = manifest["denominator"]["runnable"] + 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

expect_fixture_failure \
  "results.native pass/fail total must not exceed denominator.runnable" \
  "php-core results above the runnable denominator"

reset_fixtures

WORDPRESS_FIXTURE="$wordpress_fixture" python3 - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["WORDPRESS_FIXTURE"])
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["results"]["inventory"]["entrypoints_present"] = len(manifest["entrypoints"]) - 1
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

expect_fixture_failure \
  "wordpress inventory entrypoints_present must match entrypoints length" \
  "a mismatched WordPress entrypoint inventory"

reset_fixtures
restore_integration
restore_queue

python3 - <<'PY'
from pathlib import Path

path = Path("swarm/queue.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "| Q-008 | verified | M5 | PHPT-02/PHPT-06 | Implement minimal `.phpt` section parser | Verified on current `main`: parser covers TEST/FILE/FILEEOF/EXPECT/EXPECTF/EXPECTREGEX/SKIPIF metadata; exact-EXPECT execution remains the runnable subset |",
    "| Q-008 | ready | M5 | PHPT-02 | Implement minimal `.phpt` section parser | Tests for TEST/FILE/EXPECT/SKIPIF |",
)
path.write_text(text, encoding="utf-8")
PY

expect_status_failure \
  "queue contains obsolete pre-FILEEOF .phpt parser wording" \
  "obsolete pre-FILEEOF queue wording"

restore_queue

python3 - <<'PY'
from pathlib import Path

path = Path("swarm/queue.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "| Q-010 | verified | M6 | WP-06/INT-04 | Build first WordPress bootstrap runner design | Verified on current `main`: `phpc wordpress-bootstrap-check` inventories pinned entrypoints and classifies the current `wp-settings.php` blocker as a general PHP parser gap |",
    "| Q-010 | ready | M6 | WP-02 | Build first WordPress bootstrap runner design | First blocker classified as general compiler gap |",
)
path.write_text(text, encoding="utf-8")
PY

expect_status_failure \
  "queue advertises WordPress bootstrap-check design as ready after bootstrap_check exists" \
  "ready WordPress bootstrap-check design after manifest bootstrap_check"

restore_queue

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

expect_status_failure \
  "integration priority table lists lanes with terminal decisions: LINK-01, LINK-02" \
  "terminal integration lanes in the priority table"

restore_integration

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

expect_status_failure \
  "integration committed-candidate table lists already reviewed lanes: PHPT-03" \
  "an already reviewed committed candidate"

restore_integration

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

expect_status_failure \
  "integration log contains obsolete pre-M3 emit-exe wording" \
  "obsolete pre-M3 emit-exe wording"

restore_integration
scripts/status-gate.sh
