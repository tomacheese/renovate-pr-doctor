#!/usr/bin/env bash
# Pure helper functions for judging PR CI status from
# `gh pr view --json statusCheckRollup -q '.statusCheckRollup'` output.
# No network calls in this file.

# has_failing_check <status_check_rollup_json>
# Exit 0 (true) if any check in the rollup has conclusion/state FAILURE or ERROR.
# Excludes Renovate's own status contexts (`renovate/*`, e.g. `renovate/artifacts`) —
# those reflect Renovate's own lockfile-generation bookkeeping, not the target
# repo's actual CI, and are out of scope per architecture.md's "Target definition".
has_failing_check() {
  local rollup_json="$1"
  echo "$rollup_json" | jq -e '
    any(.[] | select((.context // "" | startswith("renovate/")) | not);
      ((.conclusion // .state // "") | ascii_upcase) as $c | $c == "FAILURE" or $c == "ERROR")
  ' > /dev/null
}

# extract_failing_checks <status_check_rollup_json>
# Prints one line per failing check: "<name>\t<detailsUrl>"
# Same renovate/* exclusion as has_failing_check.
extract_failing_checks() {
  local rollup_json="$1"
  echo "$rollup_json" | jq -r '
    .[] |
    select((.context // "" | startswith("renovate/")) | not) |
    ((.conclusion // .state // "") | ascii_upcase) as $c |
    select($c == "FAILURE" or $c == "ERROR") |
    "\(.name // .context)\t\(.detailsUrl // .targetUrl // "")"
  '
}
