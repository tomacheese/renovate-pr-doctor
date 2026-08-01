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

### tomacheese/api.tomacheese.com#501
checkpoint: root-cause-identified
detail: Dependency currency: `better-sqlite3` stale-unexplained-minor (proposed 13.0.1, latest 13.0.2) — will bump to 13.0.2 in the fix PR. Confirmed the 4 originally-reported failing checks (Add reviewer/add-reviewer, Node CI/setup, Approval gate, Node CI/Check finished Node CI) were the already-known tomacheese-org GH Actions billing outage — `gh run rerun --failed` on all 3 runs turned them green. However, once the outage clearance let the previously-`skipping` Docker CI job actually run, it failed for real: `Docker CI / Docker build (api.tomacheese.com, linux/amd64)` — `pnpm fetch` fails with `gyp ERR! Could not find any Python installation to use` while building `better-sqlite3` from source. Root cause: better-sqlite3 v13 (both 13.0.1 and 13.0.2) dropped `prebuild-install` and ships no explicit `install`/`postinstall` script override, so npm/pnpm's implicit "run `node-gyp rebuild` if `binding.gyp` exists" behavior kicks in unconditionally on install, ignoring the bundled `prebuilds/linuxmusl-x64.node` binary that v13 ships for exactly this platform. v12.11.1 avoided this via an explicit `"install": "prebuild-install || node-gyp rebuild --release"` script. The target repo's `Dockerfile` (`node:24-alpine`) has no C/Python build toolchain, so the fallback gyp compile fails. Verified fix in a real `node:24-alpine` container: adding `python3 make g++` via `apk add` before `pnpm fetch` lets `better-sqlite3@13.0.1`'s node-gyp fallback build succeed cleanly. This is a confident, non-ambiguous fix — proceeding to implement (Dockerfile toolchain addition + bump better-sqlite3 to 13.0.2), no escalation needed for the CI fix itself (dependency-currency minor bump handled inline, not an Arbiter case).

(All 5 originally-dispatched Investigators — tomacheese/vrcx-web-server#1085,
book000/templates#462 (+ siblings #456/#455/#454/#453 bulk-classified from its
Arbiter verdict), book000/rss-deliver#2625, book000/chrome-mcp-router#14, and
book000/create-ts#65 — plus the earlier
comico-downloader#823/api.tomacheese.com#502/comet-web-router#60/collect-
points#714 batch are all terminal now and their subsections have been
removed. Ledger rows and `records/2026-08-01-run.md` rows are the durable
record.)

### tomacheese/comico-downloader#820

- checkpoint: completed
- fix PR: https://github.com/tomacheese/comico-downloader/pull/824 — all
  checks pass (Approval gate, Node CI setup/node-ci/Check finished, Docker
  CI build x2/Check finished), no unrelated failures. Done, subsection can
  be removed.
- dependency currency: all 7 packages `lookup-failed` (script returned no
  usable classification) — no special handling, proceeding with the
  Renovate PR's proposed versions as-is.
- detail: `Node CI / setup` and `Approval gate` were the same org-wide
  GitHub Actions billing outage seen elsewhere this sweep — confirmed
  resolved via `gh run rerun --failed`, both now pass. But `Node CI /
  node-ci (downloader)` is a distinct, real failure: the
  `@book000/eslint-config` bump (1.16.8 → 1.16.23, part of this PR)
  enables the `unicorn/prefer-simple-condition-first` rule, which flags
  pre-existing code at `downloader/src/comico.ts:191` (an `else if` with
  a cheap boolean check listed after a pure function call). Fix:
  reorder the condition so `isGaugeRentable` (simple, side-effect-free)
  comes first — confirmed safe since `isRentable()` has no side effects.
  Verified locally with the PR's exact dependency versions:
  `pnpm run lint` passes clean after the reorder.

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
  - slot: investigator-comico-downloader-820
    target: tomacheese/comico-downloader#820
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
  - slot: investigator-collect-points-670
    target: tomacheese/collect-points#670
    checks: Approval gate,Approval gate
    recheck-of: fixed/eslint-config-1-16-14-lint-errors-large-scope
pending (not yet dispatched, in order):
  - tomacheese/api.tomacheese.com#500 [checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI] (waiting: same-repo serialization, api.tomacheese.com#501 in flight)
done this sweep: 16 (fixed=11 skipped=5 blocked=0)

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
currently tracking 4 open fix PRs: tomacheese/vrcx-web-server#1104,
book000/rss-deliver#2651, book000/chrome-mcp-router#34,
book000/create-ts#97. It re-scans `records/ledger-2026-08-01.tsv`'s `fixed`
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
