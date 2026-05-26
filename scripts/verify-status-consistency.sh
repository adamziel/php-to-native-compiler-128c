#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
import json
import pathlib
import sys

root = pathlib.Path.cwd()

php_manifest = json.loads((root / "swarm/php-core-manifest.json").read_text(encoding="utf-8"))
wp_manifest = json.loads((root / "swarm/wordpress-manifest.json").read_text(encoding="utf-8"))
progress = (root / "progress.md").read_text(encoding="utf-8")
progress_html = (root / "docs/progress.html").read_text(encoding="utf-8")
test_matrix = (root / "swarm/test-matrix.md").read_text(encoding="utf-8")
wp_doc = (root / "docs/WORDPRESS_COMPATIBILITY.md").read_text(encoding="utf-8")

errors = []

php_src = pathlib.Path(php_manifest["php_src"]["path"])
manifest_total = int(php_manifest["denominator"]["total_phpt"])
if not php_src.is_dir():
    errors.append(f"php-src path is missing: {php_src}")
else:
    actual_total = sum(1 for _ in php_src.rglob("*.phpt"))
    if actual_total != manifest_total:
        errors.append(
            f"php-src .phpt count drift: manifest={manifest_total}, actual={actual_total}"
        )

runnable = int(php_manifest["denominator"]["runnable"])
if runnable != 0 and "runner not implemented" in progress:
    errors.append("progress.md still says the .phpt runner is missing, but runnable > 0")

for text_name, text in (
    ("progress.md", progress),
    ("docs/progress.html", progress_html),
    ("swarm/test-matrix.md", test_matrix),
):
    if str(manifest_total) not in text and f"{manifest_total:,}" not in text:
        errors.append(f"{text_name} does not name the pinned .phpt denominator {manifest_total}")

wp_root = pathlib.Path(wp_manifest["wordpress"]["path"])
if not wp_root.is_dir():
    errors.append(f"WordPress path is missing: {wp_root}")

entrypoints = wp_manifest["entrypoints"]
missing_entrypoints = [entry for entry in entrypoints if not (wp_root / entry).is_file()]
if missing_entrypoints:
    errors.append("WordPress entrypoints missing: " + ", ".join(missing_entrypoints))

wp_version = wp_manifest["wordpress"]["version"]
wp_hash = wp_manifest["wordpress"]["commit_or_archive_hash"].removeprefix("sha256:")
for required in (str(wp_root), wp_version, wp_hash):
    if required not in wp_doc:
        errors.append(f"docs/WORDPRESS_COMPATIBILITY.md does not include {required}")

present_count = int(wp_manifest["results"]["inventory"]["entrypoints_present"])
if present_count != len(entrypoints):
    errors.append(
        f"WordPress manifest entrypoint count drift: present={present_count}, listed={len(entrypoints)}"
    )

wp_progress_snippets = (f"WordPress {wp_version}", f"{len(entrypoints)} entrypoints")
for text_name, text in (("progress.md", progress), ("docs/progress.html", progress_html)):
    for required in wp_progress_snippets:
        if required not in text:
            errors.append(f"{text_name} does not include WordPress manifest value `{required}`")

if errors:
    for error in errors:
        print(f"status consistency error: {error}", file=sys.stderr)
    sys.exit(1)

print(
    "status consistency ok: "
    f"{manifest_total} php-src .phpt files, "
    f"WordPress {wp_version} with {len(entrypoints)} entrypoints"
)
PY
