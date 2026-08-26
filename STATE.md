# Current state (last updated: 2026-08-27)

## Phase

2026-08-27 sweep in progress. Discovery found 5 candidates (3 new, 2
staleness-rechecks of known create-ts#65 / collect-points#697).

## Queue

concurrency: 5
in-flight:
  (empty)
pending (not yet dispatched, in order):
  - tomacheese/comico-downloader#831 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI]
  - tomacheese/collect-points#757 [checks: Approval gate,Approval gate]
  - tomacheese/api.tomacheese.com#511 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI]
  - book000/create-ts#65 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI] recheck-of: skipped/rolldown-plugin-dts-override-bump-reintroduces-volar-typescript-type-leak
  - tomacheese/collect-points#697 [checks: Approval gate,Approval gate] recheck-of: blocked/github-actions-billing-payment-failure
done this sweep: 0

## Cleanup

Attempted removal of stale `scratchpad/renovate-fix-chrome-response-recorder-409` (matching ledger row confirms `fixed`, 2026-08-01); `dist/` subfiles remain root-owned and not removable without privilege escalation — unchanged from prior sweep.
