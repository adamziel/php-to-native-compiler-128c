#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: scripts/check-lanes-integration.sh [--summary-json] [--main-ref <ref>] <lane-or-commit>...

Runs scripts/check-lane-integration.sh for each supplied lane without changing refs
or the worktree. Exits nonzero if any individual lane check exits nonzero.
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

main_ref="origin/main"
targets=()
summary_json=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary-json)
      summary_json=1
      shift
      ;;
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

resolve_target() {
  local input="$1"
  local direct_commit=""
  local lane_commit=""

  direct_commit="$(git rev-parse --verify --quiet "${input}^{commit}" || true)"
  lane_commit="$(git rev-parse --verify --quiet "lane/${input}^{commit}" || true)"

  if [[ -n "$direct_commit" && -n "$lane_commit" && "$direct_commit" != "$lane_commit" ]]; then
    echo "check-lanes-integration.sh: ambiguous target: ${input} matches both ${input} and lane/${input}" >&2
    echo "check-lanes-integration.sh: use an explicit ref such as lane/${input}" >&2
    return 2
  fi
  if [[ -n "$direct_commit" ]]; then
    printf '%s\n' "$input"
    return 0
  fi
  if [[ -n "$lane_commit" ]]; then
    printf '%s\n' "lane/${input}"
    return 0
  fi
  return 1
}

declare -A seen_resolved_targets=()
declare -A seen_input_targets=()
for target in "${targets[@]}"; do
  if [[ -n "${seen_input_targets[$target]:-}" ]]; then
    echo "check-lanes-integration.sh: duplicate target: ${target}" >&2
    exit 2
  fi
  seen_input_targets[$target]=1

  target_ref_status=0
  target_ref="$(resolve_target "$target")" || target_ref_status=$?
  if [[ "$target_ref_status" -eq 0 ]]; then
    if [[ -n "${seen_resolved_targets[$target_ref]:-}" ]]; then
      echo "check-lanes-integration.sh: duplicate target: ${target} resolves to ${target_ref}" >&2
      exit 2
    fi
    seen_resolved_targets[$target_ref]=1
  elif [[ "$target_ref_status" -eq 2 ]]; then
    exit 2
  fi
done

status=0
passed=0
failed=0
for target in "${targets[@]}"; do
  echo "== ${target} =="
  if scripts/check-lane-integration.sh "$target" "$main_ref"; then
    passed=$((passed + 1))
    continue
  else
    target_status=$?
  fi

  failed=$((failed + 1))
  if [[ "$target_status" -eq 2 ]]; then
    status=2
  elif [[ "$status" -eq 0 ]]; then
    status=1
  fi
done

echo "summary: passed=${passed} failed=${failed} total=${#targets[@]}"
if [[ "$summary_json" -eq 1 ]]; then
  printf 'summary-json: {"passed":%d,"failed":%d,"total":%d,"status":%d}\n' \
    "$passed" "$failed" "${#targets[@]}" "$status"
fi

exit "$status"
