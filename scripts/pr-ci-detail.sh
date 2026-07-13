#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/check-status.sh"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <owner/repo> <pr-number>" >&2
  exit 1
fi

repo="$1"
number="$2"

rollup=$(gh pr view "$number" -R "$repo" --json statusCheckRollup -q '.statusCheckRollup')

echo "Failing checks for $repo#$number:"
extract_failing_checks "$rollup" | while IFS=$'\t' read -r name url; do
  echo "- $name: ${url:-no URL}"
done
