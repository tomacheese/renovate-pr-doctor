#!/usr/bin/env bash
# Enumerate open Renovate PRs across $RENOVATE_MAINTAIN_ORGS (or one --repo)
# whose latest CI run has a failing check. Restricted by default to PRs
# assigned to $RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE (--assignee ""  disables
# the assignee filter entirely; --assignee login overrides it to a
# different login).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/check-status.sh"

# Fork/deployment-specific defaults — override via env vars rather than
# editing this script, so a `git pull` never clobbers a local fork's config.
orgs=(${RENOVATE_MAINTAIN_ORGS:-book000 tomacheese jaoafa})
default_assignee="${RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE:-book000}"

target_repo=""
assignee="$default_assignee"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      target_repo="$2"
      shift 2
      ;;
    --assignee)
      assignee="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

search_args=(--author "app/renovate" --state open --limit 1000)
if [[ -n "$target_repo" ]]; then
  search_args+=(--repo "$target_repo")
else
  for o in "${orgs[@]}"; do search_args+=(--owner "$o"); done
fi
if [[ -n "$assignee" ]]; then
  search_args+=(--assignee "$assignee")
fi

prs_json=$(gh search prs "${search_args[@]}" --json number,url,repository)

echo "$prs_json" | jq -c '.[]' | while IFS= read -r pr; do
  number=$(echo "$pr" | jq -r '.number')
  pr_repo=$(echo "$pr" | jq -r '.repository.nameWithOwner')
  url=$(echo "$pr" | jq -r '.url')

  rollup=$(gh pr view "$number" -R "$pr_repo" --json statusCheckRollup -q '.statusCheckRollup')

  if has_failing_check "$rollup"; then
    failing=$(extract_failing_checks "$rollup" | cut -f1 | paste -sd, -)
    printf '%s\t%s\t%s\t%s\n' "$pr_repo" "$number" "$url" "$failing"
  fi
done
