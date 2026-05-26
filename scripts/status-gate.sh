#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

scripts/refresh-progress.sh --check

python3 - <<'PY'
import json
import os
import re
from pathlib import Path


def load_json(path):
    with Path(path).open(encoding="utf-8") as handle:
        return json.load(handle)


php_core_manifest_path = os.environ.get(
    "PHP_CORE_MANIFEST_PATH", "swarm/php-core-manifest.json"
)
wordpress_manifest_path = os.environ.get(
    "WORDPRESS_MANIFEST_PATH", "swarm/wordpress-manifest.json"
)
handoff_dir = Path(os.environ.get("PHPC_HANDOFF_DIR", "swarm/handoffs"))

php_core = load_json(php_core_manifest_path)
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

wordpress = load_json(wordpress_manifest_path)
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

integration = Path("swarm/integration.md").read_text(encoding="utf-8")
queue = Path("swarm/queue.md").read_text(encoding="utf-8")
test_matrix = Path("swarm/test-matrix.md").read_text(encoding="utf-8")
if "native executable support is still 0%" in integration:
    raise SystemExit("integration log contains obsolete pre-M3 native-support wording")
if "Keep `--emit-exe` explicitly unsupported" in integration:
    raise SystemExit("integration log contains obsolete pre-M3 emit-exe wording")
if "Tests for TEST/FILE/EXPECT/SKIPIF" in queue:
    raise SystemExit("queue contains obsolete pre-FILEEOF .phpt parser wording")
if (
    wordpress.get("results", {}).get("bootstrap_check")
    and "Build first WordPress bootstrap runner design" in queue
    and "| Q-010 | ready " in queue
):
    raise SystemExit("queue advertises WordPress bootstrap-check design as ready after bootstrap_check exists")

unisolated_cargo_rows = []
for row in test_matrix.splitlines():
    if not row.startswith("| "):
        continue
    columns = [column.strip() for column in row.strip("|").split("|")]
    if len(columns) < 2 or columns[0] in {"Layer", "---"}:
        continue
    command_column = columns[1]
    if (
        re.search(r"\bcargo (test|run)\b", command_column)
        and "CARGO_TARGET_DIR=" not in command_column
    ):
        unisolated_cargo_rows.append(columns[0])

if unisolated_cargo_rows:
    raise SystemExit(
        "test matrix cargo verification commands missing CARGO_TARGET_DIR: "
        + ", ".join(unisolated_cargo_rows)
    )

if handoff_dir.is_dir():
    required_handoff_sections = (
        ("Summary", ("## Summary", "summary:")),
        ("Files Changed", ("## Files Changed", "files changed:")),
        ("Tests Run", ("## Tests Run", "tests run:")),
        ("Pass/Fail State", ("## Pass/Fail State", "pass/fail state:")),
        ("Blockers", ("## Blockers", "blockers:")),
        ("Latest Commit", ("## Latest Commit", "latest commit:", "latest commit if any:")),
        ("Next Suggested Slice", ("## Next Suggested Slice", "next suggested slice:")),
    )
    incomplete_handoffs = []
    stale_handoffs = []
    pending_commit_re = re.compile(r"\bpending\b|\bcommit\b.*\bpending\b", re.IGNORECASE)
    latest_commit_section_re = re.compile(
        r"(?ims)^(?:##\s+Latest Commit|latest commit(?: if any)?):?[ \t]*(?:\n|$)(.*?)(?=^## |\n[a-z][a-z /-]*:\s*|\Z)"
    )
    for path in sorted(handoff_dir.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        for match in latest_commit_section_re.finditer(text):
            if pending_commit_re.search(match.group(1)):
                stale_handoffs.append(path.name)
                break
    if stale_handoffs:
        raise SystemExit(
            "handoffs contain unresolved latest-commit pending markers: "
            + ", ".join(stale_handoffs)
        )
    for path in sorted(handoff_dir.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        missing_sections = [
            name
            for name, markers in required_handoff_sections
            if not any(marker in text for marker in markers)
        ]
        if missing_sections:
            incomplete_handoffs.append(
                f"{path.name} missing " + ", ".join(f"## {name}" for name in missing_sections)
            )
    if incomplete_handoffs:
        raise SystemExit(
            "handoffs missing required sections: "
            + "; ".join(incomplete_handoffs)
        )

terminal_lanes = set()
reviewed_lanes = set()
in_reviewed_candidates = False
in_committed_candidates = False
committed_candidate_lanes = set()
for row in integration.splitlines():
    if row == "## Reviewed Candidates":
        in_reviewed_candidates = True
        in_committed_candidates = False
        continue
    if row == "## Committed Lane Candidates":
        in_committed_candidates = True
        in_reviewed_candidates = False
        continue
    if row.startswith("## ") and row not in ("## Reviewed Candidates", "## Committed Lane Candidates"):
        in_reviewed_candidates = False
        in_committed_candidates = False

    if in_reviewed_candidates and row.startswith("| `"):
        columns = [column.strip() for column in row.strip("|").split("|")]
        if columns and columns[0] != "Lane":
            reviewed_lanes.update(re.findall(r"`([^`]+)`", columns[0]))
    if in_committed_candidates and row.startswith("| `"):
        columns = [column.strip() for column in row.strip("|").split("|")]
        if columns and columns[0] != "Lane":
            committed_candidate_lanes.update(re.findall(r"`([^`]+)`", columns[0]))

    if not row.startswith("| 202"):
        continue
    columns = [column.strip() for column in row.strip("|").split("|")]
    if len(columns) < 4:
        continue
    lane_column = columns[1]
    decision = columns[3]
    if not re.match(r"^(Reject|Blocked)\b", decision):
        continue
    for lane in re.findall(r"`([^`]+)`", lane_column):
        terminal_lanes.add(lane)

stale_reviewed_candidates = sorted(reviewed_lanes & committed_candidate_lanes)
if stale_reviewed_candidates:
    raise SystemExit(
        "integration committed-candidate table lists already reviewed lanes: "
        + ", ".join(stale_reviewed_candidates)
    )

for row in integration.splitlines():
    if not row.startswith("| P"):
        continue
    columns = [column.strip() for column in row.strip("|").split("|")]
    if len(columns) < 2:
        continue
    priority_lane_column = columns[1]
    reviewed_priority_lanes = sorted(
        lane for lane in reviewed_lanes if f"`{lane}`" in priority_lane_column
    )
    if reviewed_priority_lanes:
        raise SystemExit(
            "integration priority table lists already reviewed lanes: "
            + ", ".join(reviewed_priority_lanes)
        )
    stale_lanes = sorted(
        lane for lane in terminal_lanes if f"`{lane}`" in priority_lane_column
    )
    if stale_lanes:
        raise SystemExit(
            "integration priority table lists lanes with terminal decisions: "
            + ", ".join(stale_lanes)
        )
PY
