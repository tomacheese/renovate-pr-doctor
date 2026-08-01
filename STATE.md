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

### tomacheese/collect-points#670
checkpoint: root-cause-identified
detail: Recheck of the 2026-07-22 `fixed` ledger row (`eslint-config-1-16-14-lint-errors-large-scope`) — failing check name had changed to `Approval gate`. Confirmed via `gh api .../jobs/<id>` that the initial `Approval gate` failures matched the org-wide GitHub Actions billing-outage signature (`steps: []`, ~7s runtime, `runner_id: 0`) seen elsewhere in today's sweep; `gh run rerun --failed` turned both `Approval gate` jobs green, confirming the outage has resolved. After rerun, `Docker CI` passed cleanly but `Node CI / node-ci` failed for real: `lint:tsc` reports `TS2307: Cannot find module './instrumentation-serde'` inside `node_modules/.pnpm/@apm-js-collab+code-transformer-bundler-plugins@0.7.1/.../dist/cjs/core.d.cts`. Root cause: this Renovate PR bumps `@sentry/node` to `10.68.0`, which pulls in `@sentry/server-utils@10.68.0` → `@apm-js-collab/code-transformer-bundler-plugins@0.7.1` as a transitive dependency; 0.7.1's published `.d.cts` files use an extension-less relative import (`from './instrumentation-serde'`) that Node16/NodeNext TS module resolution cannot resolve, while upstream fixed this in 0.7.2/0.7.3 (confirmed by downloading both tarballs from npm and diffing `core.d.cts`/`core.d.ts`). Dependency currency check: `@sentry/node` proposed 10.68.0 vs latest 10.69.0 (`stale-unexplained-minor`), `@book000/eslint-config` proposed 1.16.23 vs latest 1.16.24 (`stale-unexplained-minor`), `@book000/node-utils` proposed 1.25.18 vs latest 1.25.19 (`stale-unexplained-minor`), `pnpm` proposed 11.17.0 vs latest 11.18.0 (`stale-unexplained-minor`), `eslint`/`prettier` current, and `node` proposed 24.18.1 vs latest 26.5.1 (`stale-unexplained-major`). Per priority rules, the major-version finding on `node` takes precedence over all the minor findings, so none of the minor bumps are being made in this fix — the fix targets the currently-proposed versions only, and the `node` major-version currency will be escalated separately (`fix-pr-opened-plus-escalated`) once the fix PR is open.

### book000/chrome-response-recorder#409
checkpoint: fix-pr-opened
detail: Recheck of the 2026-07-22 `skipped` row (`pnpm11-requires-node22-docker-base-stale`, past 3-day staleness window) — independently re-verified the root cause and it still holds, plus found an additional contributing bug. Dependency currency: `pnpm` proposed 11.17.0, latest 11.18.0 (`stale-unexplained-minor`) — bumped to 11.18.0 in the fix PR. `gh run view --log-failed` shows `Docker CI / Docker build`'s `pnpm fetch` step failing: `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING` inside corepack. Reproduced locally in the actual `zenika/alpine-chrome:with-puppeteer-xvfb` base image (confirmed it still ships Node.js v20.15.1, unchanged since the prior investigation): running `corepack`-installed pnpm 11.17.0/11.18.0 under Node 20.15.1 fails at module-load time with `ERR_UNKNOWN_BUILTIN_MODULE: No such built-in module: node:sqlite` — pnpm 11.x hard-requires Node.js >=22.13 (confirmed via corepack's own printed warning) and cannot even start under Node 20, not just misbehave. This also affects runtime, not just build: `supervisord.conf`'s `app` process previously invoked `/usr/local/bin/pnpm start` on the same Node-20 runtime image. Separately found a second, independent bug while reproducing: the Dockerfile never `COPY`s `pnpm-workspace.yaml` (which sets `allowBuilds: esbuild: true`) into the build context, so pnpm 11's stricter build-script-approval policy blocks `esbuild`'s postinstall unconditionally, failing `pnpm install --frozen-lockfile --offline` even once Node 22+ is used. Fix PR https://github.com/book000/chrome-response-recorder/pull/495 opened against `master` from branch `fix/docker-node22-pnpm-builder-stage` (pushed directly — push access confirmed, no fork needed): (1) split the Dockerfile into a multi-stage build — a new `deps` stage on `node:24-alpine` (matches the repo's own `.node-version`, 24.18.1) runs `pnpm fetch`/`pnpm install`, and the runtime `zenika/alpine-chrome` stage (still Node 20, unavoidable — third-party fixed-tag image) just copies the resulting `node_modules`, no longer installs/uses pnpm/corepack at all; (2) added the missing `COPY pnpm-workspace.yaml ./` to the `deps` stage; (3) changed `supervisord.conf`'s `app` command from `pnpm start` to a direct `node_modules/.bin/tsx /app/src/main.ts` invocation, since pnpm can never run on this runtime image's Node 20 regardless of the build-stage split. Verified locally before opening: `docker build --platform linux/amd64` succeeds end-to-end; built image's `node_modules/.bin/tsx` runs under Node 20.15.1 and the app's entrypoint reaches real startup logic (only fails on missing Xvfb, expected outside supervisord); `pnpm lint` (prettier/eslint/tsc) passes under Node 24; `hadolint` shows the same single pre-existing info-level finding as `master`, no new findings. Now waiting on the fix PR's own CI (`gh pr checks 495 -R book000/chrome-response-recorder --watch`) before declaring `completed`.

(All 5 originally-dispatched Investigators — tomacheese/vrcx-web-server#1085,
book000/templates#462 (+ siblings #456/#455/#454/#453 bulk-classified from its
Arbiter verdict), book000/rss-deliver#2625, book000/chrome-mcp-router#14, and
book000/create-ts#65 — plus the earlier
comico-downloader#823/api.tomacheese.com#502/comet-web-router#60/collect-
points#714 batch, plus tomacheese/collect-points#697,
tomacheese/comico-downloader#820, and tomacheese/api.tomacheese.com#501 —
are all terminal now and their subsections have been removed. Ledger rows
and `records/2026-08-01-run.md` rows are the durable record.)

## Queue

concurrency: 5
in-flight:
  - slot: investigator-chrome-response-recorder-409
    target: book000/chrome-response-recorder#409
    checks: Docker CI / Docker build (chrome-response-recorder, linux/amd64),Docker CI / Check finished Docker CI
    recheck-of: skipped/pnpm11-requires-node22-docker-base-stale
  - slot: investigator-api-tomacheese-com-501
    target: tomacheese/api.tomacheese.com#501
    checks: Add reviewer / add-reviewer,Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-collect-points-670
    target: tomacheese/collect-points#670
    checks: Approval gate,Approval gate
    recheck-of: fixed/eslint-config-1-16-14-lint-errors-large-scope
pending (not yet dispatched, in order):
  - tomacheese/api.tomacheese.com#500 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI] (waiting: same-repo serialization, api.tomacheese.com#501 in flight)
done this sweep: 17 (fixed=12 skipped=5 blocked=0)

Reclassification note (post-dispatch, before terminal handling of the above
4 was finalized): `comico-downloader#823`, `api.tomacheese.com#502`, and
`comet-web-router#60` were each initially reported `blocked` (org-wide
GitHub Actions billing outage in the `tomacheese` org). A concurrent
sibling (`collect-points#714`) discovered the outage had since resolved and
turned itself green by re-running the originally-failed jobs. The
orchestrator applied the same recheck to the 3 `blocked` siblings
(`gh run rerun --failed`, twice each — once for the initially-failed job
set, once more for the separately-gated `Approval gate` job) and confirmed
all 3 PRs are now fully green (`MERGEABLE`/`CLEAN`, `api.tomacheese.com#502`
briefly `UNKNOWN` mergeability which is a transient GitHub recompute, not a
check failure). All 4 reclassified/recorded as `fixed` with root-cause
signature `tomacheese-org-gh-actions-billing-outage` — see
`records/ledger-2026-08-01.tsv` and `records/2026-08-01-run.md`.

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

(empty — no conflicts detected yet. Fix-PR conflict/merge monitor is
running, see below.)

## Escalate-to-user policy

No standing override in effect. Default behavior applies: relay any
`escalate-to-user` Arbiter verdict immediately via `AskUserQuestion`.

## Next concrete action

Liveness-monitoring cron (`79e3eb57`, every ~15 min) already running.
Fix-PR conflict/merge monitor (persistent `Monitor` task `bu2abvg5c`,
polling every 300s) started once the first fix PRs landed in the ledger —
currently tracking 5 open fix PRs: tomacheese/vrcx-web-server#1104,
book000/rss-deliver#2651, book000/chrome-mcp-router#34,
book000/create-ts#97, tomacheese/comico-downloader#824. It re-scans
`records/ledger-2026-08-01.tsv`'s `fixed`
rows each poll, so newly-opened fix PRs (from the 4 in-flight Investigators
above) are picked up automatically without restarting it. On a `CONFLICT
DETECTED` line, dispatch a `conflict-fixer` sibling per
`reference/fix-pr-conflict-monitoring.md`. On a `TERMINAL`/`ALL FIX PRS
TERMINAL` line, independently confirm via `gh pr view` and note it in the
relevant PR's `STATE.md` history (already-removed subsections: just note
in this file's own running log if needed) — an unexpected `CLOSED` (not
already explained) is worth flagging to the user.

Continue the main refill loop: on each `SendMessage` report, handle
escalation/terminal per SKILL.md step 4, refill the freed slot from
`pending` (respecting same-repo serialization), commit STATE.md queue
changes, and keep going until both `in-flight` and `pending` are empty and
the conflict monitor reports `ALL FIX PRS TERMINAL`.

## Open questions / concerns

- `inv-chrome-response-recorder-409` flagged **suspect** at the 2026-08-01
  09:xx UTC liveness firing: no `STATE.md` subsection created and no new
  commit in `scratchpad/renovate-fix-chrome-response-recorder-409` beyond
  the original PR commit (`fc2628b`) since the previous firing's baseline.
  Sent a `SendMessage` probe asking for a status update (per
  `reference/liveness-monitoring.md`) — not yet redispatching; will repeat
  the probe across the next 1-2 firings before treating it as dead.
