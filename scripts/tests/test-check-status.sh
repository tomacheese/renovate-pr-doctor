#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../lib/check-status.sh"

fail=0

assert_true() {
  local desc="$1" fixture="$2" json
  json=$(cat "$DIR/fixtures/$fixture")
  if has_failing_check "$json"; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc (expected has_failing_check to return true)"
    fail=1
  fi
}

assert_false() {
  local desc="$1" fixture="$2" json
  json=$(cat "$DIR/fixtures/$fixture")
  if has_failing_check "$json"; then
    echo "FAIL: $desc (expected has_failing_check to return false)"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

assert_true  "all-failure fixture is detected as failing"        "status-check-rollup-failure.json"
assert_false "all-success fixture is not failing"                "status-check-rollup-success.json"
assert_true  "mixed fixture with one failure is detected"        "status-check-rollup-mixed.json"
assert_true  "StatusContext-shaped ERROR is detected"             "status-check-rollup-context-shape.json"

extracted=$(extract_failing_checks "$(cat "$DIR/fixtures/status-check-rollup-mixed.json")")
expected=$'test\thttps://example.com/2'
if [[ "$extracted" == "$expected" ]]; then
  echo "PASS: extract_failing_checks returns only the failing check"
else
  echo "FAIL: extract_failing_checks mismatch"
  echo "  expected: $expected"
  echo "  actual:   $extracted"
  fail=1
fi

exit $fail
