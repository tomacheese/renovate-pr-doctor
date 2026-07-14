#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../lib/ledger-staleness.sh"

fail=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: $desc"
    else
        echo "FAIL: $desc"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        fail=1
    fi
}

# Same-day row: always trusted, regardless of status/checks.
assert_eq "same-day row is dropped (fast path)" \
    "drop" \
    "$(classify_ledger_match 2026-07-15 skipped "lint" "test" 2026-07-15)"

# fixed rows recurring in discovery are always re-checked, even with
# identical check names (the outpaced-fix case: same check, moved further).
assert_eq "fixed row still failing is always rechecked" \
    "recheck:fixed-row-still-open-and-failing" \
    "$(classify_ledger_match 2026-07-12 fixed "build" "build" 2026-07-15)"

# Pre-migration rows with no recorded checks are unknown and re-checked once.
assert_eq "row with no recorded checks is rechecked" \
    "recheck:no-recorded-checks" \
    "$(classify_ledger_match 2026-07-12 skipped "" "build" 2026-07-15)"

# Failing checks changed since the row was recorded: different failure now.
assert_eq "changed failing checks trigger a recheck" \
    "recheck:failing-checks-changed" \
    "$(classify_ledger_match 2026-07-12 skipped "eslint" "prettier" 2026-07-15)"

# Check-name order/duplication differences alone must not trigger a recheck.
assert_eq "reordered/duplicated check names still match" \
    "drop" \
    "$(classify_ledger_match 2026-07-15 skipped "build,lint" "lint,build,lint" 2026-07-15)"

# Same checks, recent row, under the staleness window: still trusted.
assert_eq "recent blocked row under the staleness window is dropped" \
    "drop" \
    "$(classify_ledger_match 2026-07-14 blocked "minimumReleaseAge" "minimumReleaseAge" 2026-07-15)"

# Same checks, but the row has aged past the staleness window: recheck even
# though nothing about the failing checks themselves changed.
assert_eq "blocked row past the staleness window is rechecked" \
    "recheck:stale-after-3d" \
    "$(classify_ledger_match 2026-07-12 blocked "minimumReleaseAge" "minimumReleaseAge" 2026-07-15)"

# Custom staleness window via the optional 6th argument.
assert_eq "custom stale_days argument is honored" \
    "recheck:stale-after-1d" \
    "$(classify_ledger_match 2026-07-14 skipped "eslint" "eslint" 2026-07-15 1)"

exit $fail
