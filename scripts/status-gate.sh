#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

scripts/refresh-progress.sh --check

python3 - <<'PY'
import json
from pathlib import Path


def load_json(path):
    with Path(path).open(encoding="utf-8") as handle:
        return json.load(handle)


php_core = load_json("swarm/php-core-manifest.json")
denominator = php_core.get("denominator", {})
total_phpt = denominator.get("total_phpt")
mapped = denominator.get("mapped")
runnable = denominator.get("runnable")

if not isinstance(total_phpt, int) or total_phpt <= 0:
    raise SystemExit("php-core manifest must record a positive denominator.total_phpt")
if mapped != total_phpt:
    raise SystemExit("php-core manifest denominator.mapped must match denominator.total_phpt")
if not isinstance(runnable, int) or runnable < 0 or runnable > total_phpt:
    raise SystemExit("php-core manifest denominator.runnable must be between 0 and total_phpt")

results = php_core.get("results", {})
for runner in ("system_php", "phpc_run", "native"):
    runner_results = results.get(runner)
    if not isinstance(runner_results, dict):
        raise SystemExit(f"php-core manifest missing results.{runner}")
    passed = runner_results.get("pass")
    failed = runner_results.get("fail")
    if not isinstance(passed, int) or passed < 0:
        raise SystemExit(f"php-core manifest results.{runner}.pass must be a non-negative integer")
    if not isinstance(failed, int) or failed < 0:
        raise SystemExit(f"php-core manifest results.{runner}.fail must be a non-negative integer")
    if passed + failed > runnable:
        raise SystemExit(
            f"php-core manifest results.{runner} pass/fail total must not exceed denominator.runnable"
        )

php_src = php_core.get("php_src", {})
for key in ("path", "source", "branch", "commit", "version"):
    if not php_src.get(key):
        raise SystemExit(f"php-core manifest missing php_src.{key}")

wordpress = load_json("swarm/wordpress-manifest.json")
wp_source = wordpress.get("wordpress", {})
for key in ("path", "source", "version", "commit_or_archive_hash"):
    if not wp_source.get(key):
        raise SystemExit(f"wordpress manifest missing wordpress.{key}")

entrypoints = wordpress.get("entrypoints")
if not isinstance(entrypoints, list) or not entrypoints:
    raise SystemExit("wordpress manifest must record at least one entrypoint")

inventory = wordpress.get("results", {}).get("inventory", {})
present = inventory.get("entrypoints_present")
missing = inventory.get("entrypoints_missing")
if present != len(entrypoints):
    raise SystemExit("wordpress inventory entrypoints_present must match entrypoints length")
if missing != 0:
    raise SystemExit("wordpress inventory must not report missing pinned entrypoints")
PY
