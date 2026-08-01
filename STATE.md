# Current state (last updated: 2026-08-01)

## Phase

2026-08-01 sweep in progress. Discovery ran across the default 3 orgs
(book000/tomacheese/jaoafa), assignee book000 (default). 19 candidates
found; 0 auto-classified via bulk-skip (none matched an established
systemic signature closely enough to skip without a real Investigator —
see notes on book000/templates below), all 19 queued. Pre-work cleanup
already ran: no stale STATE.md subsections, `## Phase` already compressed,
one stale clone (`scratchpad/renovate-fix-collect-points-670`) removed
(matching terminal `fixed` ledger row confirmed first). Preparatory
uncommitted script changes found at session start (archived-repo skip in
`find-broken-prs.sh`, `renovate/*` check exclusion in `check-status.sh`,
plus 2026-07-22 sweep close-out records) were committed (`92656b8`) before
discovery ran.

## Targets and their state

(none yet — queue dispatch in progress, per-PR subsections will appear
here as Investigators/Arbiters/Executors report back non-terminal
checkpoints.)

## Queue

concurrency: 5
in-flight:
  - slot: investigator-collect-points-714
    target: tomacheese/collect-points#714
    checks: Approval gate,Approval gate
  - slot: investigator-api-tomacheese-com-502
    target: tomacheese/api.tomacheese.com#502
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-comico-downloader-823
    target: tomacheese/comico-downloader#823
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-comet-web-router-60
    target: tomacheese/comet-web-router#60
    checks: hadolint / hadolint,Approval gate
  - slot: investigator-vrcx-web-server-1085
    target: tomacheese/vrcx-web-server#1085
    checks: Docker CI / Docker build (vrcx-web-server, linux/amd64),Docker CI / Check finished Docker CI
pending (not yet dispatched, in order):
  - book000/templates#462 [checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished]
  - book000/rss-deliver#2625 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/chrome-mcp-router#14 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/create-ts#65 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/chrome-response-recorder#409 [checks: Docker CI / Docker build (chrome-response-recorder, linux/amd64),Docker CI / Check finished Docker CI] recheck-of: skipped/pnpm11-requires-node22-docker-base-stale
  - tomacheese/collect-points#697 [checks: Approval gate,Approval gate]
  - tomacheese/api.tomacheese.com#501 [checks: Add reviewer / add-reviewer,Node CI / setup,Approval gate,Node CI / Check finished Node CI]
  - tomacheese/comico-downloader#820 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI]
  - book000/templates#456 [checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished]
  - tomacheese/collect-points#670 [checks: Approval gate,Approval gate] recheck-of: fixed/eslint-config-1-16-14-lint-errors-large-scope
  - tomacheese/api.tomacheese.com#500 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI]
  - book000/templates#455 [checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished] recheck-of: skipped/actionlint-invalid-parallel-step-keys-PR450-master-breakage (stale, 10d old)
  - book000/templates#454 [checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished] recheck-of: skipped/actionlint-invalid-parallel-step-keys-PR450-master-breakage (stale, 10d old)
  - book000/templates#453 [checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished] recheck-of: skipped/actionlint-invalid-parallel-step-keys-PR450-master-breakage (stale, 10d old)
done this sweep: 0 (fixed=0 skipped=0 blocked=0)

Notes on classification (Step 2):
- book000/templates has 5 candidates (462/456/455/454/453) all sharing the
  identical actionlint failing-check signature. 454/453 already have a
  `skipped` ledger row (`actionlint-invalid-parallel-step-keys-PR450-
  master-breakage`, 2026-07-22) but it's past the 3-day staleness window
  today (2026-08-01), so both are queued as `recheck` rather than dropped.
  462/456/455 have no ledger row at all. Given same-repo serialization
  means only one book000/templates Investigator runs at a time anyway,
  these were NOT bulk-skipped up front (the signature is being
  independently re-verified this same sweep) — instead, once the first
  templates dispatch reports back, classify the remaining 4 directly from
  its verdict without separate Investigator dispatches, mirroring the
  2026-07-22 sweep's #453-from-#454 precedent, unless its findings show
  the root cause has actually changed.
- tomacheese/collect-points#670 has a `fixed` ledger row (2026-07-22) but
  still appears in discovery (still open, still CI-failing) — per the
  "fixed row still showing up" rule this is always `recheck` regardless of
  check-name match (confirmed here: recorded checks were the eslint/Node-CI
  set, current failing check is `Approval gate` — a different failure, so
  this needed recheck on two independent grounds).
- book000/chrome-response-recorder#409's `skipped` row is also past the
  3-day staleness window → `recheck`.
- All other candidates (Node CI / node-ci generic failures, `Approval
  gate`-only failures, comico-downloader/api.tomacheese.com Node CI
  failures, comet-web-router hadolint, vrcx-web-server Docker CI) have no
  ledger row and their failing-check names don't closely match any
  established systemic signature closely enough to bulk-skip with
  confidence — queued for real Investigators per "when in doubt,
  investigate."

## Conflict-fixer queue

(empty — no fix PRs opened yet this sweep.)

## Escalate-to-user policy

No standing override in effect. Default behavior applies: relay any
`escalate-to-user` Arbiter verdict immediately via `AskUserQuestion`.

## Next concrete action

Liveness-monitoring cron needs to be started now that the first
Investigators are in flight. Then continue the refill loop: on each
`SendMessage` report, handle escalation/terminal per SKILL.md step 4,
refill the freed slot from `pending` (respecting same-repo
serialization), commit STATE.md queue changes, and keep going until both
`in-flight` and `pending` are empty.

## Open questions / concerns
(none)
