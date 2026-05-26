#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: scripts/check-lanes-integration.sh [--main-ref <ref>] <lane-or-commit>...

Runs scripts/check-lane-integration.sh for each supplied lane without changing refs
or the worktree. Exits nonzero if any individual lane check exits nonzero.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

main_ref="origin/main"
targets=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --main-ref)
      if [[ $# -lt 2 ]]; then
        usage
        exit 2
      fi
      main_ref="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      targets+=("$@")
      break
      ;;
    -*)
      usage
      exit 2
      ;;
    *)
      targets+=("$1")
      shift
      ;;
  esac
done

if [[ "${#targets[@]}" -eq 0 ]]; then
  usage
  exit 2
fi

status=0
passed=0
failed=0
for target in "${targets[@]}"; do
  echo "== ${target} =="
  if ! scripts/check-lane-integration.sh "$target" "$main_ref"; then
    status=1
    failed=$((failed + 1))
  else
    passed=$((passed + 1))
  fi
done

echo "summary: passed=${passed} failed=${failed} total=${#targets[@]}"

exit "$status"
