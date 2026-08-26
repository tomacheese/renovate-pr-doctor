# Current state (last updated: 2026-08-27)

## Phase

2026-08-27 sweep in progress. Discovery found 5 candidates (3 new, 2
staleness-rechecks of known create-ts#65 / collect-points#697).

## Queue

concurrency: 5
in-flight:
  (empty)
pending (not yet dispatched, in order):
  (empty)
done this sweep: 5 (fixed=0 skipped=1 blocked=4)

## Targets and their state

### tomacheese/collect-points#697

- checkpoint: blocked
- detail: Staleness recheck (2026-08-24 row, 3+ days old) re-confirmed
  unchanged. PR still OPEN, "Approval gate" still fails with the same
  purely environmental cause: "The job was not started because recent
  account payments have failed or your spending limit needs to be
  increased." Identical root-cause-signature
  (`github-actions-billing-payment-failure`) already independently
  confirmed this sweep on sibling PRs tomacheese/comico-downloader#831,
  tomacheese/api.tomacheese.com#511, tomacheese/collect-points#757. No
  code fix possible/attempted; org-level GitHub Actions billing issue,
  outside repo scope. No currency-check special handling applies (blocked
  purely on environmental grounds, currency check not relevant to the
  blocking cause).

## Cleanup

Attempted removal of stale `scratchpad/renovate-fix-chrome-response-recorder-409` (matching ledger row confirms `fixed`, 2026-08-01); `dist/` subfiles remain root-owned and not removable without privilege escalation — unchanged from prior sweep.
