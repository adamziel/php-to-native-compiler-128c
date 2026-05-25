#!/usr/bin/env bash

swarm_all_lanes=(
  INT-01 INT-02 INT-03 INT-04 INT-05 INT-06 INT-07 INT-08
  ABI-01 ABI-02 ABI-03 ABI-04 ABI-05 ABI-06 ABI-07 ABI-08 ABI-09 ABI-10 ABI-11 ABI-12
  LINK-01 LINK-02 LINK-03 LINK-04 LINK-05 LINK-06 LINK-07 LINK-08 LINK-09 LINK-10 LINK-11 LINK-12
  LOW-01 LOW-02 LOW-03 LOW-04 LOW-05 LOW-06 LOW-07 LOW-08 LOW-09 LOW-10 LOW-11 LOW-12 LOW-13 LOW-14 LOW-15 LOW-16
  PHPT-01 PHPT-02 PHPT-03 PHPT-04 PHPT-05 PHPT-06 PHPT-07 PHPT-08 PHPT-09 PHPT-10 PHPT-11 PHPT-12 PHPT-13 PHPT-14 PHPT-15 PHPT-16
  WP-01 WP-02 WP-03 WP-04 WP-05 WP-06 WP-07 WP-08 WP-09 WP-10 WP-11 WP-12
  SEM-01 SEM-02 SEM-03 SEM-04 SEM-05 SEM-06 SEM-07 SEM-08 SEM-09 SEM-10
  SAPI-01 SAPI-02 SAPI-03 SAPI-04 SAPI-05 SAPI-06 SAPI-07 SAPI-08
  MINE-01 MINE-02 MINE-03
  DOC-01 DOC-02 DOC-03
)

swarm_default_50_lanes=(
  INT-01 INT-02 INT-06 INT-07
  ABI-03 ABI-07 ABI-10 ABI-11 ABI-01 ABI-02
  LINK-01 LINK-02 LINK-08 LINK-09 LINK-11 LINK-03 LINK-04 LINK-05
  LOW-03 LOW-04 LOW-07 LOW-12 LOW-15 LOW-16 LOW-01 LOW-02 LOW-05 LOW-06
  PHPT-01 PHPT-02 PHPT-03 PHPT-06 PHPT-07 PHPT-09 PHPT-10 PHPT-13
  WP-01 WP-02 WP-04 WP-06 WP-12
  SEM-02 SEM-04 SEM-09 SEM-01
  SAPI-03 SAPI-05 SAPI-06
  MINE-02
  DOC-03
)

swarm_select_lanes() {
  if [ -n "${SWARM_LANES:-}" ]; then
    # shellcheck disable=SC2206
    lanes=(${SWARM_LANES})
    return 0
  fi

  local worker_count="${SWARM_WORKER_COUNT:-50}"
  if [ "$worker_count" = "all" ]; then
    lanes=("${swarm_all_lanes[@]}")
    return 0
  fi

  if ! [[ "$worker_count" =~ ^[0-9]+$ ]]; then
    echo "SWARM_WORKER_COUNT must be an integer or 'all': ${worker_count}" >&2
    return 1
  fi

  if [ "$worker_count" -ge "${#swarm_all_lanes[@]}" ]; then
    lanes=("${swarm_all_lanes[@]}")
  elif [ "$worker_count" -le "${#swarm_default_50_lanes[@]}" ]; then
    lanes=("${swarm_default_50_lanes[@]:0:${worker_count}}")
  else
    lanes=("${swarm_default_50_lanes[@]}")
    local lane
    for lane in "${swarm_all_lanes[@]}"; do
      if [ "${#lanes[@]}" -ge "$worker_count" ]; then
        break
      fi
      if [[ " ${lanes[*]} " != *" ${lane} "* ]]; then
        lanes+=("$lane")
      fi
    done
  fi
}
