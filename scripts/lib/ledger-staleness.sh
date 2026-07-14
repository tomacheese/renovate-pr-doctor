#!/usr/bin/env bash
# Pure helper for Step 2's per-candidate ledger-staleness decision. No
# network calls in this file — every input is already in hand from
# discovery's own TSV output and the matched ledger row, so this never
# costs an extra `gh` call per already-ledgered candidate.

# normalize_check_list <comma_separated_names>
# Sorts and de-dupes a comma-separated check-name list so two lists that
# differ only in order/duplication still compare equal.
normalize_check_list() {
    local list="$1"
    echo "$list" | tr ',' '\n' | sed '/^$/d' | sort -u | paste -sd, -
}

# classify_ledger_match <row_date> <row_status> <row_checks> <current_checks> <today>
# [<stale_days>]
#
# Given the most recent existing ledger row for a repo+PR already found by
# Step 2's `awk` lookup, decide whether it can still be trusted as-is
# ("drop" — same fast path as before) or whether the candidate should be
# queued for a fresh Investigator despite already having a row
# ("recheck:<reason>").
#
# row_date / row_status / row_checks: columns 1 / 6 / 8 of the matched
# ledger row (row_checks is "" for rows written before the `failing_checks`
# column existed, or for a status this rule doesn't apply to).
# current_checks: today's failing check names for this PR, from discovery
# (already fetched — no extra `gh` call).
# stale_days: overridable via $RENOVATE_MAINTAIN_LEDGER_STALE_DAYS, default 3.
classify_ledger_match() {
    local row_date="$1" row_status="$2" row_checks="$3" current_checks="$4" today="$5"
    local stale_days="${6:-${RENOVATE_MAINTAIN_LEDGER_STALE_DAYS:-3}}"

    # Same-day row: this sweep (or an earlier run today) already looked at
    # it — trust it, no benefit to re-checking again within the same day.
    if [[ "$row_date" == "$today" ]]; then
        echo "drop"
        return
    fi

    # A `fixed` row whose PR still shows up in today's discovery at all is
    # inherently anomalous: a fix that actually held should have left the
    # PR green (or closed), not still open and still CI-failing. Matching
    # check names can't distinguish "fix still holds" from "same check
    # name, dependency moved further and outpaced the fix" (both look
    # identical from check names alone) — so any recurrence is always
    # worth a fresh look, regardless of check-name comparison.
    if [[ "$row_status" == "fixed" ]]; then
        echo "recheck:fixed-row-still-open-and-failing"
        return
    fi

    # Pre-migration row with no recorded check names — nothing to compare
    # against, so treat as unknown and always re-verify once (the row this
    # sweep writes back will carry the column, restoring the fast path for
    # future sweeps).
    if [[ -z "$row_checks" ]]; then
        echo "recheck:no-recorded-checks"
        return
    fi

    local normalized_row normalized_current
    normalized_row=$(normalize_check_list "$row_checks")
    normalized_current=$(normalize_check_list "$current_checks")

    if [[ "$normalized_row" != "$normalized_current" ]]; then
        echo "recheck:failing-checks-changed"
        return
    fi

    # Same failing checks as recorded, but a `blocked`/`skipped` verdict's
    # reasoning (e.g. "transient, self-resolves") can itself be wrong in a
    # way that check names never surface (create-ts#17: the actual root
    # cause was a structural misconfiguration mislabeled as transient).
    # Force a periodic re-look after `stale_days`, purely from the row's
    # own date column — no prose parsing, no extra `gh` calls.
    local age_days
    age_days=$(((($(date -u -d "$today" +%s) - $(date -u -d "$row_date" +%s))) / 86400))
    if ((age_days >= stale_days)); then
        echo "recheck:stale-after-${stale_days}d"
        return
    fi

    echo "drop"
}
