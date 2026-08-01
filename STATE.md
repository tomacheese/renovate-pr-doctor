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

### tomacheese/comico-downloader#823

- checkpoint: blocked
- detail: dependency-currency check returned `[]` (lockFileMaintenance PR,
  no explicit package bumps to check — nothing to note). All 3 failing
  checks (`Node CI / setup`, `Node CI / Check finished Node CI`, `Approval
  gate`) fail with the same GitHub Actions org-wide billing outage already
  seen on `tomacheese/collect-points#670` this sweep: "The job was not
  started because recent account payments have failed or your spending
  limit needs to be increased." Purely environmental, not repo-specific
  (same `tomacheese` org) — not a judgment call, reporting `blocked`
  directly without escalation, no clone made.

### tomacheese/api.tomacheese.com#502

- checkpoint: blocked
- detail: dependency-currency check returned `[]` (lockFileMaintenance PR
  bumping only `pnpm-lock.yaml`, no explicit package version bumps to
  check — nothing to note). All 3 failing checks (`Node CI / setup`, `Node
  CI / Check finished Node CI`, `Approval gate`) fail with the same GitHub
  Actions org-wide billing outage already seen on
  `tomacheese/collect-points#670` and `tomacheese/comico-downloader#823`
  this sweep: "The job was not started because recent account payments
  have failed or your spending limit needs to be increased." Purely
  environmental, not repo-specific (same `tomacheese` org) — not a
  judgment call, reporting `blocked` directly without escalation. Clone
  attempted but investigation stopped once billing outage confirmed as
  root cause of all failing checks.

### tomacheese/comet-web-router#60

- checkpoint: blocked
- detail: dependency-currency check returned only `nginx` `1.31.2-alpine` →
  `1.31.3-alpine` with `latest_version` empty / `classification:
  lookup-failed` — treated as "nothing to note" per the fallback rule. Both
  failing checks (`hadolint / hadolint`, `Approval gate`) fail immediately
  (~3s, zero steps run) with the same GitHub Actions org-wide billing
  outage already seen this sweep on `tomacheese/collect-points#670`,
  `tomacheese/comico-downloader#823`, and `tomacheese/api.tomacheese.com#502`:
  check-run annotation reads "The job was not started because recent
  account payments have failed or your spending limit needs to be
  increased." Confirmed via annotations on both failing check-runs
  (89484948354, 89484949059). Purely environmental, not repo-specific
  (same `tomacheese` org) — not a judgment call, reporting `blocked`
  directly without escalation. Clone made
  (`scratchpad/renovate-fix-comet-web-router-60`) but no fix needed/possible;
  investigation stopped once billing outage confirmed as root cause of all
  failing checks.

### tomacheese/collect-points#714

- checkpoint: completed
- detail: dependency-currency check returned `[]` (lockFileMaintenance PR,
  no explicit package bumps to check — nothing to note). Both failing
  `Approval gate` checks initially failed (~3s, zero steps run) with the
  same GitHub Actions org-wide billing outage seen this sweep on
  `tomacheese/collect-points#670`, `tomacheese/comico-downloader#823`,
  `tomacheese/api.tomacheese.com#502`, and `tomacheese/comet-web-router#60`.
  **However, the outage has since resolved**: `gh run list` showed a
  successful `Docker` run in this same repo at 2026-08-01T05:27 UTC (after
  the PR's original 2026-07-30 failures), so I re-ran the two failed
  `Approval gate` jobs (`gh run rerun 30575753177/30575753201 --failed`)
  and all checks now pass (`Approval gate` x2, `Node CI` x3, `Docker CI`
  x4). PR is now `MERGEABLE`/`CLEAN`. No code fix was needed or made — no
  clone, no fix PR. **This confirms the org billing issue behind the
  sibling `blocked` PRs above is resolved as of ~05:27 UTC today; those
  should be worth a quick re-check/re-run rather than staying blocked.**

### tomacheese/vrcx-web-server#1085

- checkpoint: root-cause-identified
- detail: dependency-currency check: `better-sqlite3` proposed `13.0.1`,
  latest `13.0.2` — classification `stale-unexplained-minor` (no
  explanation given); will bump to `13.0.2` in the fix PR per the
  currency-handling rule. Root cause of both failing checks (`Docker CI /
  Docker build (vrcx-web-server, linux/amd64)`, `Docker CI / Check finished
  Docker CI`): `pnpm fetch` in the Dockerfile's `node:24-alpine` builder
  stage fails with "Could not find any Python installation to use" while
  building `better-sqlite3`'s native addon via `node-gyp rebuild`. This is
  a known upstream packaging bug in `better-sqlite3` v13
  (WiseLibs/better-sqlite3#1503, confirmed still present in `13.0.2`,
  latest as of this check): v13 dropped its old `install` script
  (`prebuild-install`) but ships a `binding.gyp`, so npm/pnpm auto-inject
  `"install": "node-gyp rebuild"` at publish time even though the package
  already bundles a matching prebuilt binary
  (`prebuilds/linuxmusl-x64.node`) that would otherwise be used directly.
  The repo's `pnpm-workspace.yaml` has `allowBuilds: better-sqlite3: true`
  (added for v12.11.1, where the equivalent auto-injected script was a
  network-fetching `prebuild-install`, which doesn't need Python) — the
  Alpine builder stage has no `python3`/`make`/`g++`, so the v13 gyp
  rebuild fails outright. Confirmed fix (verified working by multiple
  commenters on the upstream issue): flip `allowBuilds.better-sqlite3` to
  `false` in `pnpm-workspace.yaml`, which makes pnpm skip the auto-injected
  install script entirely and use the bundled prebuilt binary as-is — no
  Dockerfile/build-toolchain changes needed. Confident fix, proceeding to
  implement (not escalating).

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
