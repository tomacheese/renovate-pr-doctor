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

(tomacheese/comico-downloader#823, tomacheese/api.tomacheese.com#502,
tomacheese/comet-web-router#60, and tomacheese/collect-points#714 are all
terminal now and their subsections have been removed — see the note under
`## Queue` for the reclassification. Ledger rows and `records/2026-08-01-
run.md` rows are the durable record.)

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

- checkpoint: fix-pr-opened
- detail: fix PR opened: https://github.com/tomacheese/vrcx-web-server/pull/1104
  (branch `fix/better-sqlite3-v13-alpine-gyp-build`, off `master`). Flipped
  `allowBuilds.better-sqlite3` to `false` in `pnpm-workspace.yaml`, bumped
  `better-sqlite3` to `13.0.2`, regenerated `pnpm-lock.yaml`. Locally
  verified: `docker build .` succeeds; a container built from the image
  can open a `better-sqlite3` DB and do CREATE/INSERT/SELECT; `pnpm lint`
  (Prettier/ESLint/tsc) passes clean. Waiting on the fix PR's own CI before
  declaring `completed`.

- checkpoint: completed
- detail: fix PR #1104's own CI finished — both originally-failing checks
  now pass (`Docker CI / Docker build (vrcx-web-server, linux/amd64)`,
  `Docker CI / Check finished Docker CI`), plus every other check
  (`Node CI`, `Approval gate`, `CodeQL`, `Analyze (actions)`, `Analyze
  (javascript-typescript)`), no unrelated failures introduced. Fix PR left
  open (not merged) per workflow rules. Renovate PR #1085 itself untouched
  (no commits made to its branch).

### book000/templates#462

- checkpoint: skipped
- detail: Arbiter verdict `skip` (independently verified 2026-08-01, not
  merely re-affirming the Investigator). Verified directly via `gh api`
  that `background: true` / `wait-all: true` step keys are still present
  verbatim on master's `reusable-nodejs-ci.yml` (lines ~139-153), that
  #462's diff is purely the `docker/login-action` v4.4.0 -> v4.5.2 bump
  (plus the same bump in `workflows/old/*`), and that the `actionlint`
  workflow has failed on every one of the last 5 master runs
  (e24ba5f, fda5125, bb5ae5c, be20e5a, 355d2f7) — so the failure is
  pre-existing master breakage, wholly independent of the Renovate bump.
  Additionally verified that GitHub's runner *accepts* these keys: the
  `Test reusable-nodejs-ci / node-ci` jobs on this PR's own run
  (30617646442) pass and their step list includes the `⏳ Wait for
  parallel steps` step. So the keys are a deliberate, working feature for
  the repo owner and only `actionlint` rejects them — option (a)
  (stripping the keys) would be a behavior-changing regression, not a
  mechanical lint fix, and option (b) (a standalone master repair PR) is
  out of this workflow's scope since there is no correct repair we can
  choose on the owner's behalf (suppress the rule vs. drop the feature is
  the owner's call). Nothing in this PR can be fixed to make its checks
  pass. Dependency currency `stale-unexplained-minor`
  (`docker/login-action` v4.5.2 vs latest v4.6.0) is moot — no fix PR.
- siblings: this verdict also covers book000/templates#456, #455, #454,
  #453 — independently confirmed each has exactly the same three FAILURE
  checks (`actionlint`, `Test reusable-actionlint / actionlint`, `Test
  Summary Finished`) and the same master-breakage root cause.

### book000/rss-deliver#2625

- checkpoint: root-cause-identified
- detail: dependency-currency check: `node-ical` proposed `0.27.1`, latest
  `0.27.1` — classification `current`, no special handling needed. Root
  cause of both failing checks (`Node CI / node-ci (.)`, `Node CI / Check
  finished Node CI`): `pnpm run lint` → `tsc` fails with `TS1038: A
  'declare' modifier cannot be used in an already ambient context` at
  `node_modules/.../node-ical@0.27.1/node-ical.d.ts:112` (`declare const
  _default: {...}` nested inside the file's outer `declare module
  'node-ical'` block). Confirmed by downloading `node-ical@0.27.1` from npm
  directly — this is a bug in node-ical's own shipped `.d.ts`, not in
  rss-deliver's code; no existing upstream issue found on
  jens-maus/node-ical for it. `tsconfig.json` currently has no
  `skipLibCheck`, so `tsc` type-checks node_modules `.d.ts` files too.
  Confident fix: add `"skipLibCheck": true` to `tsconfig.json` — the
  standard, low-risk remedy for a broken vendored declaration file (skips
  type-checking of `.d.ts` files only, does not affect `src/` semantics).

### book000/create-ts#65

- checkpoint: root-cause-identified
- detail: dependency-currency check: `rolldown-plugin-dts` proposed
  `0.27.14`, latest `0.28.0` — classification `stale-unexplained-minor` (no
  explanation given). However, bumping to `0.28.0` would NOT fix anything
  here (confirmed by downloading the `0.28.0` tarball from npm directly:
  its `dist/*.d.mts` still references `@volar/typescript`), so the
  currency-handling "bump to latest" rule is superseded by the actual root
  cause below — no version bump belongs in the fix here at all. Root cause
  of both failing checks (`Node CI / node-ci (.)`, `Node CI / Check
  finished Node CI`): this repo's `pnpm-workspace.yaml` already carries a
  deliberate `overrides: rolldown-plugin-dts: '0.27.9'` pin, with an
  explicit comment explaining that `rolldown-plugin-dts@0.27.10+` ships a
  `.d.mts` that unconditionally references `typeof
  import("@volar/typescript")` types even though `@volar/typescript` is
  only an optional peer dependency that is never installed, which breaks
  `tsc` (TS2307) since this repo has no `skipLibCheck`. Renovate PR #65
  bumps that same override from `0.27.9` to `0.27.14` — i.e. it proposes
  re-introducing the exact bug the pin exists to avoid. Confirmed via
  `gh run view --log-failed`: `tsc` fails with `TS2307: Cannot find module
  '@volar/typescript'` at
  `rolldown-plugin-dts/dist/custom-language-*.d.mts:20/27`, identical to
  the documented failure mode. Tried the "add `@volar/typescript` as a
  devDependency" workaround locally — it only cascades into a second
  missing-type error (`@volar/language-service` from
  `@volar/typescript`'s own `createSys.d.ts`), so that's not a clean fix
  either. Confident conclusion: PR #65 itself should not be merged (its
  bump is invalid — reverts a deliberate, documented workaround for a
  still-unfixed upstream bug, reconfirmed present in both `0.27.14` and
  latest `0.28.0`). The durable fix is a separate PR (against `main`, not
  PR #65's branch) adding a Renovate `packageRules` entry to stop Renovate
  from proposing further bumps to this pinned override until upstream
  fixes the type leak. Not escalating — this isn't a judgment call between
  multiple plausible fixes, it's confirming and hardening a workaround the
  repo owner already made deliberately and documented.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-vrcx-web-server-1085
    target: tomacheese/vrcx-web-server#1085
    checks: Docker CI / Docker build (vrcx-web-server, linux/amd64),Docker CI / Check finished Docker CI
  - slot: investigator-templates-462
    target: book000/templates#462
    checks: actionlint,Test reusable-actionlint / actionlint,Test Summary Finished
  - slot: investigator-rss-deliver-2625
    target: book000/rss-deliver#2625
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-chrome-mcp-router-14
    target: book000/chrome-mcp-router#14
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-create-ts-65
    target: book000/create-ts#65
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
pending (not yet dispatched, in order):
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
done this sweep: 4 (fixed=4 skipped=0 blocked=0)

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
