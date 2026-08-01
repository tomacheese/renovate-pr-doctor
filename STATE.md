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

### tomacheese/api.tomacheese.com#500
checkpoint: escalated-to-user
detail: CI verification confirmed independently — PR #500 (`renovate/all-minor-patch`, "chore(deps): update all non-major dependencies") is `MERGEABLE`/`CLEAN` with every check `SUCCESS` (`Node CI / setup`, `Node CI / node-ci (.)`, `Node CI / Check finished Node CI`, `Approval gate`, `Docker CI` x3 run + 3 legitimately `SKIPPED` release steps). No CI fix exists to implement; the escalation is purely the dependency-currency `node` finding. Package: `node` in `.node-version`, proposed 24.18.0 -> 24.18.1 (a PATCH bump), flagged `stale-unexplained-major` against latest 26.5.1. Independent verification says this is almost certainly a FALSE POSITIVE of `scripts/check-dependency-currency.sh`, for two compounding reasons: (1) LTS blindness — `https://nodejs.org/dist/index.json` shows v24.18.1 is `lts: "Krypton"` (Active LTS) and is the newest release on the LTS line, released 2026-07-28, the SAME DAY as v26.5.1; v26.5.1 is `lts: false` (Current line, becomes LTS ~Oct 2026) and v25.9.0 is `lts: false` and EOL. Renovate's `node` versioning deliberately treats non-LTS lines as unstable, so proposing 24.18.1 is correct behaviour, not staleness — there is no major bump on the table for a human to approve or reject. (2) Preset-resolution blindness — `check_explained_gap` only inspects the repo's own `renovate.json`, which merely contains `extends: ["github>book000/templates//renovate/base-private"]`; it does not resolve preset `extends`, so it never sees that `book000/templates//renovate/base.json` carries an explicit `{matchPackageNames: ["node"], matchManagers: ["dockerfile"], enabled: false}` rule (Dockerfile is pinned `FROM node:24-alpine` on purpose). Recommended answer for the human: no action — let this PR merge as-is; do not pin/pause, and do not chase Node 26 until it reaches Active LTS in Oct 2026. Trade-off if the human wants Node 26 anyway: 26.x is Current-only until Oct 2026, and this repo ships a Docker image with `better-sqlite3` (a native module needing a prebuilt/ABI-compatible binary per Node major) — an early move would trade LTS support for churn with no functional gain. Follow-up worth filing separately (out of scope for this PR): `scripts/check-dependency-currency.sh` looks `node` up via `latest_npm` and so will re-raise this same bogus `stale-unexplained-major` on every repo with a `.node-version` for the next ~2 months; it needs a `node`-datasource lookup that filters to LTS.
### tomacheese/collect-points#670
checkpoint: escalated-to-user
detail: Recheck of the 2026-07-22 `fixed` ledger row (`eslint-config-1-16-14-lint-errors-large-scope`) — failing check name had changed to `Approval gate`. Confirmed via `gh api .../jobs/<id>` that the initial `Approval gate` failures matched the org-wide GitHub Actions billing-outage signature (`steps: []`, ~7s runtime, `runner_id: 0`) seen elsewhere in today's sweep; `gh run rerun --failed` turned both `Approval gate` jobs green, confirming the outage has resolved. After rerun, `Docker CI` passed cleanly but `Node CI / node-ci` failed for real: `lint:tsc` reports `TS2307: Cannot find module './instrumentation-serde'` inside `node_modules/.pnpm/@apm-js-collab+code-transformer-bundler-plugins@0.7.1/.../dist/cjs/core.d.cts`. Root cause: this Renovate PR bumps `@sentry/node` to `10.68.0`, which pulls in `@sentry/server-utils@10.68.0` → `@apm-js-collab/code-transformer-bundler-plugins@0.7.1` as a transitive dependency; 0.7.1's published `.d.cts` files use an extension-less relative import (`from './instrumentation-serde'`) that Node16/NodeNext TS module resolution cannot resolve, while upstream fixed this in 0.7.2/0.7.3 (confirmed by downloading both tarballs from npm and diffing `core.d.cts`/`core.d.ts`). Dependency currency check: `@sentry/node` proposed 10.68.0 vs latest 10.69.0 (`stale-unexplained-minor`), `@book000/eslint-config` proposed 1.16.23 vs latest 1.16.24 (`stale-unexplained-minor`), `@book000/node-utils` proposed 1.25.18 vs latest 1.25.19 (`stale-unexplained-minor`), `pnpm` proposed 11.17.0 vs latest 11.18.0 (`stale-unexplained-minor`), `eslint`/`prettier` current, and `node` proposed 24.18.1 vs latest 26.5.1 (`stale-unexplained-major`). Per priority rules, the major-version finding on `node` takes precedence over all the minor findings, so none of the minor bumps are being made in this fix — the fix targets the currently-proposed versions only. Fix PR https://github.com/tomacheese/collect-points/pull/716 opened against `master` from branch `fix/apm-js-collab-transformer-plugins-dts-override` (pushed directly — push access confirmed, no fork needed): added `overrides: '@apm-js-collab/code-transformer-bundler-plugins': '0.7.3'` to `pnpm-workspace.yaml` (not `package.json`'s `pnpm.overrides`, which pnpm 11.15+ warns is no longer read — a pre-existing, out-of-scope quirk noted here for traceability since it silently means the repo's existing `puppeteer`/`puppeteer-core` overrides in `package.json` may also not actually be applied by current pnpm, but this is unrelated to the CI failure being fixed and not touched in this PR). Verified locally before opening, both on `master`'s own dependency versions and combined with PR #670's proposed bumps: `pnpm install --frozen-lockfile` succeeds, `pnpm lint` (prettier/eslint/tsc) all pass, `pnpm test` (139 tests) all pass. Now waiting on the fix PR's own CI before declaring `completed`. Escalating separately (`NEEDS_ARBITER`) the `node` major-version dependency-currency finding (proposed 24.18.1, latest 26.5.1) per the dependency-currency priority rules — this is a distinct judgment call from the CI fix above and does not block it. ARBITER VERDICT (2026-08-01): `escalate-to-user` — mandatory for `stale-unexplained-major` dependency-currency findings; verified independently against `https://nodejs.org/dist/index.json`. Package: `node` via `.node-version` (repo currently `24.16.0`, PR #670 proposes `24.18.1`, "latest" reported `26.5.1`). Findings that reframe the gap: `24.18.1` and `26.5.1` were both released 2026-07-28, and `24.18.1` is the newest release of the **Active LTS** line (Krypton, `lts: "Krypton"`), while `26.5.1` is the **Current** line (`lts: false`) which does not enter LTS until 2026-10; `25.x` is already EOL (last release `25.9.0`, 2026-03-31). So the proposed bump is not "stale" in the maintenance sense — it is the latest LTS patch, and the two-major gap is an LTS-vs-Current distinction, not neglect. Repo-specific constraints against jumping to 26: `Dockerfile` hardcodes `FROM node:24-alpine` for the builder stage and the runner stage is `zenika/alpine-chrome:with-puppeteer-xvfb`, so moving `.node-version` to 26 alone would desync CI from both the build and runtime images; `@types/node` is pinned to `24.13.2` and would need a lockstep major bump; the app drives headless Chrome via `rebrowser-puppeteer-core` on Alpine/musl, the class of workload most exposed to a V8/ICU/N-API major change (`modules` ABI 137 → 147). No Renovate node-major PR is open in the repo (only #670 `all-minor-patch`, #697 `pin-dependencies`, #714 `lock-file-maintenance`). Recommendation to the user: let #670 proceed with `24.18.1` and stay on the 24 LTS line; revisit 26 after it becomes Active LTS in 2026-10, as a coordinated change touching `.node-version` + `Dockerfile` + `@types/node` together. Same package/gap as the parallel escalation on tomacheese/api.tomacheese.com#500 (org-wide `.node-version` convention), decided independently here on this repo's own Docker/Chrome constraints. This is NOT terminal — stays open until the coordinator relays to the human and reports back. Independent of the CI fix above (PR #716), which remains tracked separately by the Investigator.

(All 5 originally-dispatched Investigators — tomacheese/vrcx-web-server#1085,
book000/templates#462 (+ siblings #456/#455/#454/#453 bulk-classified from its
Arbiter verdict), book000/rss-deliver#2625, book000/chrome-mcp-router#14, and
book000/create-ts#65 — plus the earlier
comico-downloader#823/api.tomacheese.com#502/comet-web-router#60/collect-
points#714 batch, plus tomacheese/collect-points#697,
tomacheese/comico-downloader#820, tomacheese/api.tomacheese.com#501, and
book000/chrome-response-recorder#409 — are all terminal now and their
subsections have been removed. Ledger rows and `records/2026-08-01-run.md`
rows are the durable record.)

## Queue

concurrency: 5
in-flight:
  - slot: investigator-collect-points-670
    target: tomacheese/collect-points#670
    checks: Approval gate,Approval gate
    recheck-of: fixed/eslint-config-1-16-14-lint-errors-large-scope
  - slot: investigator-api-tomacheese-com-500
    target: tomacheese/api.tomacheese.com#500
    checks: Node CI / setup,Approval gate,Node CI / Check finished Node CI
pending (not yet dispatched, in order):
  (empty)
done this sweep: 19 (fixed=14 skipped=5 blocked=0)

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
currently tracking 7 open fix PRs: tomacheese/vrcx-web-server#1104,
book000/rss-deliver#2651, book000/chrome-mcp-router#34,
book000/create-ts#97, tomacheese/comico-downloader#824,
tomacheese/api.tomacheese.com#503,
book000/chrome-response-recorder#495. It re-scans
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
(none — `inv-chrome-response-recorder-409`'s earlier suspect flag is
resolved: it has since reached `fix-pr-opened` with fix PR #495, real
progress since the probe.)
