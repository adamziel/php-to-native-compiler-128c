#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 - <<'PY'
import json
import os
import pathlib
import sys
from html.parser import HTMLParser

root = pathlib.Path.cwd()

def repo_path(env_name, default):
    return pathlib.Path(os.environ.get(env_name, root / default))


php_manifest = json.loads(repo_path("PHPC_PHP_CORE_MANIFEST", "swarm/php-core-manifest.json").read_text(encoding="utf-8"))
wp_manifest = json.loads(repo_path("PHPC_WORDPRESS_MANIFEST", "swarm/wordpress-manifest.json").read_text(encoding="utf-8"))
progress = repo_path("PHPC_PROGRESS_MD", "progress.md").read_text(encoding="utf-8")
progress_html = repo_path("PHPC_PROGRESS_HTML", "docs/progress.html").read_text(encoding="utf-8")
test_matrix = repo_path("PHPC_TEST_MATRIX", "swarm/test-matrix.md").read_text(encoding="utf-8")
wp_doc = repo_path("PHPC_WORDPRESS_DOC", "docs/WORDPRESS_COMPATIBILITY.md").read_text(encoding="utf-8")

errors = []


class TableCellTextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.cells = []
        self._in_cell = False
        self._parts = []

    def handle_starttag(self, tag, attrs):
        if tag in {"td", "th"}:
            self._in_cell = True
            self._parts = []

    def handle_data(self, data):
        if self._in_cell:
            self._parts.append(data)

    def handle_endtag(self, tag):
        if tag in {"td", "th"} and self._in_cell:
            self.cells.append("".join(self._parts).strip())
            self._in_cell = False
            self._parts = []


def html_cells(text):
    parser = TableCellTextParser()
    parser.feed(text)
    return parser.cells


def wordpress_status_lines(text_name, text):
    if text_name.endswith(".html"):
        return [cell for cell in html_cells(text) if "WordPress" in cell or "bootstrap" in cell]
    return [
        line
        for line in text.splitlines()
        if "WordPress" in line or "bootstrap" in line
    ]


def markdown_current_state(text):
    fields = {}
    for line in text.splitlines():
        if not line.startswith("- "):
            continue
        label, sep, value = line[2:].partition(":")
        if not sep:
            continue
        fields[label.strip()] = value.strip().strip("`")
    return fields


def html_table_fields(text):
    cells = html_cells(text)
    fields = {}
    for index in range(0, len(cells) - 1, 2):
        fields[cells[index]] = cells[index + 1]
    return fields


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

progress_state = markdown_current_state(progress)
html_state = html_table_fields(progress_html)
published_status_pairs = (
    ("Branch", "Branch"),
    ("Report base HEAD", "Report base HEAD"),
    ("Dirty entries", "Working tree dirty entries"),
)
for markdown_label, html_label in published_status_pairs:
    markdown_value = progress_state.get(markdown_label)
    html_value = html_state.get(html_label)
    if markdown_value is None:
        errors.append(f"progress.md missing published status field `{markdown_label}`")
    if html_value is None:
        errors.append(f"docs/progress.html missing published status field `{html_label}`")
    if markdown_value is not None and html_value is not None and markdown_value != html_value:
        errors.append(
            f"published status mismatch for {markdown_label}: "
            f"progress.md={markdown_value}, docs/progress.html={html_value}"
        )

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

bootstrap_check = wp_manifest.get("results", {}).get("bootstrap_check")
if bootstrap_check:
    stale_bootstrap_phrases = (
        "runner queued",
        "bootstrap runner queued",
        "no bootstrap runner exists",
    )
    bootstrap_status = bootstrap_check.get("status")
    bootstrap_file = bootstrap_check.get("bootstrap")
    if not bootstrap_status:
        errors.append("WordPress manifest bootstrap_check is missing status")
    if not bootstrap_file:
        errors.append("WordPress manifest bootstrap_check is missing bootstrap file")

    for text_name, text in (("progress.md", progress), ("docs/progress.html", progress_html)):
        wp_lines = wordpress_status_lines(text_name, text)
        for stale in stale_bootstrap_phrases:
            if any(stale in line for line in wp_lines):
                errors.append(
                    f"{text_name} uses stale WordPress bootstrap wording `{stale}` "
                    "despite manifest results.bootstrap_check"
                )
        if bootstrap_status and bootstrap_status not in text:
            errors.append(
                f"{text_name} does not include WordPress bootstrap status `{bootstrap_status}`"
            )
        if bootstrap_file and bootstrap_file not in text:
            errors.append(
                f"{text_name} does not include WordPress bootstrap file `{bootstrap_file}`"
            )

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
