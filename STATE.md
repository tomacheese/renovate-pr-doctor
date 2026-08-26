# Current state (last updated: 2026-08-27)

## Phase

2026-08-27 sweep in progress. Discovery found 5 candidates (3 new, 2
staleness-rechecks of known create-ts#65 / collect-points#697).

## Queue

concurrency: 5
in-flight:
  - slot: investigator-comico-downloader-831
    target: tomacheese/comico-downloader#831
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-collect-points-757
    target: tomacheese/collect-points#757
    checks: Approval gate,Approval gate
  - slot: investigator-api.tomacheese.com-511
    target: tomacheese/api.tomacheese.com#511
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-create-ts-65
    target: book000/create-ts#65
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
    recheck-of: skipped/rolldown-plugin-dts-override-bump-reintroduces-volar-typescript-type-leak
pending (not yet dispatched, in order):
  - tomacheese/collect-points#697 [checks: Approval gate,Approval gate] recheck-of: blocked/github-actions-billing-payment-failure (same-repo-blocked behind collect-points#757)
done this sweep: 0

## Targets and their state

### book000/create-ts#65

checkpoint: skipped
detail: Staleness recheck of the 2026-08-24 `skipped` verdict (3+ days old). Re-verified from scratch, nothing changed: PR #65 still OPEN, same two checks (`Node CI / node-ci (.)`, `Node CI / Check finished Node CI`) still failing with the identical signature — `tsc` `TS2307: Cannot find module '@volar/typescript'` in `rolldown-plugin-dts@0.28.2`'s shipped `custom-language-*.d.mts` (confirmed via `gh run view --log-failed` on run 32920367445, dated 2026-08-26). Dependency currency: `rolldown-plugin-dts` proposed `0.28.2` == latest `0.28.2` (`current`) — no newer version exists that could resolve the type leak. The only prior remediation attempt, fix PR #97 (Renovate `packageRules` hardening to stop further bumps of the deliberately-pinned `overrides.rolldown-plugin-dts: '0.27.9'`), remains CLOSED with the owner's explicit rejection comment unchanged: "改善されるまで待つ。特別定義追加はしない。" (wait for upstream, no special-case rules). Re-confirming the same `skipped` verdict — no new fix action taken, not escalated (owner's stance is a settled prior decision, not a fresh judgment call).

### tomacheese/comico-downloader#831

checkpoint: blocked
detail: dependency currency check returned `[]` (no packages, lockFileMaintenance-only PR) — no special handling needed. All three failing checks (`Node CI / setup`, `Approval gate`, `Node CI / Check finished Node CI`) fail immediately (3s) with `The job was not started because recent account payments have failed or your spending limit needs to be increased.` — a GitHub Actions billing/spending-limit failure at the account level, purely environmental, same root cause as the known `github-actions-billing-payment-failure` pattern seen on collect-points#697 (2026-08-24 ledger). Not a judgment call; no code fix possible or attempted.

### tomacheese/api.tomacheese.com#511

checkpoint: blocked
detail: dependency currency check returned `[]` (no packages parsed; lockFileMaintenance-only PR touching only `pnpm-lock.yaml`) — no special handling needed. All three failing checks (`Node CI / setup`, `Approval gate`, `Node CI / Check finished Node CI`) fail immediately (2-4s, zero steps run) with check-run annotation: "The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings." — a GitHub Actions billing/spending-limit failure at the account level, purely environmental, same root cause as the known `github-actions-billing-payment-failure` pattern seen on comico-downloader#831, collect-points#697/#757 (this sweep). Not a judgment call; no code fix possible or attempted.

## Cleanup

Attempted removal of stale `scratchpad/renovate-fix-chrome-response-recorder-409` (matching ledger row confirms `fixed`, 2026-08-01); `dist/` subfiles remain root-owned and not removable without privilege escalation — unchanged from prior sweep.
