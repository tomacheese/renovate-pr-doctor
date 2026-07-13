#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$DIR/stubs/gh"

args_file=$(mktemp)
trap 'rm -f "$args_file"' EXIT

# --repo/--assignee are passed through, and --repo suppresses --owner.
PATH="$DIR/stubs:$PATH" GH_STUB_SEARCH_ARGS_FILE="$args_file" \
  bash "$DIR/../find-broken-prs.sh" --assignee book000 --repo book000/EventFinder >/dev/null
actual_args=$(cat "$args_file")

if [[ "$actual_args" == *"--repo book000/EventFinder"* && "$actual_args" == *"--assignee book000"* \
      && "$actual_args" != *"--owner"* ]]; then
  echo "PASS: find-broken-prs.sh passes --repo/--assignee through to gh search prs and skips --owner"
else
  echo "FAIL: find-broken-prs.sh did not pass --repo/--assignee correctly"
  echo "  actual gh search prs args: $actual_args"
  exit 1
fi

# Omitting --assignee defaults to book000.
PATH="$DIR/stubs:$PATH" GH_STUB_SEARCH_ARGS_FILE="$args_file" \
  bash "$DIR/../find-broken-prs.sh" >/dev/null
actual_args=$(cat "$args_file")

if [[ "$actual_args" == *"--assignee book000"* ]]; then
  echo "PASS: find-broken-prs.sh defaults --assignee to book000 when omitted"
else
  echo "FAIL: find-broken-prs.sh did not default --assignee to book000"
  echo "  actual gh search prs args: $actual_args"
  exit 1
fi

# --assignee "" explicitly disables the assignee filter.
PATH="$DIR/stubs:$PATH" GH_STUB_SEARCH_ARGS_FILE="$args_file" \
  bash "$DIR/../find-broken-prs.sh" --assignee "" >/dev/null
actual_args=$(cat "$args_file")

if [[ "$actual_args" != *"--assignee"* ]]; then
  echo "PASS: find-broken-prs.sh --assignee \"\" disables the assignee filter"
else
  echo "FAIL: find-broken-prs.sh --assignee \"\" still applied a filter"
  echo "  actual gh search prs args: $actual_args"
  exit 1
fi
