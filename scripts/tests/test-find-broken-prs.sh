#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$DIR/stubs/gh"

actual=$(PATH="$DIR/stubs:$PATH" bash "$DIR/../find-broken-prs.sh")
expected=$'tomacheese/test-repo\t1\thttps://github.com/tomacheese/test-repo/pull/1\tbuild'

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: find-broken-prs.sh outputs only the PR with a failing check"
  exit 0
else
  echo "FAIL: find-broken-prs.sh output mismatch"
  echo "  expected: $expected"
  echo "  actual:   $actual"
  exit 1
fi
