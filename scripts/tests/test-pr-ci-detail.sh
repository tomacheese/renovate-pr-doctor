#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$DIR/stubs/gh"

actual=$(PATH="$DIR/stubs:$PATH" bash "$DIR/../pr-ci-detail.sh" tomacheese/test-repo 3)
expected=$'Failing checks for tomacheese/test-repo#3:\n- test: https://example.com/2'

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: pr-ci-detail.sh reports only the failing check from a mixed rollup"
  exit 0
else
  echo "FAIL: pr-ci-detail.sh output mismatch"
  echo "  expected: $expected"
  echo "  actual:   $actual"
  exit 1
fi
