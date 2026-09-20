# Current state (last updated: 2026-09-20)

## Phase

Sweep in progress: 2026-09-20. Discovery found 82 candidates (default:
book000/tomacheese/jaoafa orgs, assignee=book000) — none matched an
existing ledger row (all classified NEW). Filling initial 5 concurrency
slots; refill loop in progress.

## Targets and their state

(populated per-PR as Investigators/Arbiters/Executors report in)

### book000/pixivts#1928

- checkpoint: fix-pr-opened
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: Same root-cause pattern as `tomacheese/fauxcord#314`/`tomacheese/telcheck#2635`. The eslint-config bump newly flags 42 pre-existing lint violations (41 errors, 1 warning) across `packages/core/src/*.ts`, `packages/core/tests/**`, `packages/db-mysql/tests/*.ts`, and `scripts/check-pr-language.mjs` (`unicorn/prefer-ternary`, `unicorn/prefer-early-return`, one unused eslint-disable directive). `pnpm run lint` (eslint step) fails, failing both `node-ci` and its downstream `Check finished Node CI`. Base branch is `develop` (not `main`). Fix: included the eslint-config 1.16.67 bump, ran `eslint . --fix` (38/41 auto-fixed) and hand-converted the remaining 3 `unicorn/prefer-early-return` cases (`novels.e2e.test.ts`, `illusts.test.ts`, `recorder.test.ts`). No push access to `book000/pixivts` — forked to `akubiusa/pixivts`, pushed there. Verified locally: `pnpm run lint` clean, `pnpm run test` 234/234 passing. Fix PR: https://github.com/book000/pixivts/pull/1931 — CI's `node-ci` job has been stuck in GitHub's `waiting` status (not `pending`/running) since ~11:03 UTC: the repo's workflow requires manual Environment approval (`fork-pr-build`) for any PR whose head repo differs from `book000/pixivts`, which is exactly the case here since I had no push access and opened from a fork. Only a `book000/pixivts` maintainer can click Approve on the Actions run; this is a normal, expected gate for external/fork PRs, not a code defect. Still `fix-pr-opened`, not `completed` — CI hasn't actually executed the lint fix yet.

### tomacheese/watch-vrchat-user#531

- checkpoint: fix-pr-opened
- dependency currency: `@book000/node-utils` proposed 1.25.110, latest 1.25.110 — current, no special handling.
- detail: Same pre-existing `master`-level root cause as sibling `#529`/`#530` (unmerged fix PRs #538/#539): `pnpm-lock.yaml`/`pnpm-workspace.yaml` still reference `vrchat@2.22.8` (patch file + `patchedDependencies` key) even though `package.json` already requires `vrchat@2.22.9`, and `allowBuilds` omits `@parcel/watcher` (Jest transitive build script) — `pnpm install --frozen-lockfile` fails with `ERR_PNPM_OUTDATED_LOCKFILE`, failing Node CI and both Docker CI matrix builds (and is also why `renovate/artifacts` fails). Unrelated to this PR's own `@book000/node-utils` 1.25.87→1.25.110 bump. Unlike `#529`, no lint fallout since eslint-config isn't touched. Fix: same lockfile/patch/allowBuilds fix as `#538`/`#539`, plus this PR's node-utils bump. Had push access — pushed directly. Verified locally: `pnpm install --frozen-lockfile` succeeds, `pnpm run lint` clean, `pnpm test` 13/13 suites (78/78 tests) passing, `docker build .` succeeds. Fix PR: https://github.com/tomacheese/watch-vrchat-user/pull/540 — note this duplicates part of #538/#539's diff since neither sibling fix has merged yet.

### book000/fixdevcontainer#361

- checkpoint: completed
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 — stale-unexplained-minor, bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `tomacheese/pex-crawler#2155`/`book000/node-utils#1646`/`tomacheese/watch-discord-dev-changes#2335`/`jaoafa/jaotan.ts#2268`. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in a brand-new transitive dependency, `@parcel/watcher@2.6.0`, which ships a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allow-list (currently only `unrs-resolver`) doesn't include it, so `pnpm install --frozen-lockfile` hard-fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0`, failing `Node CI / node-ci (.)` and its downstream `Check finished Node CI`. Fix: added `'@parcel/watcher': true` to `pnpm-workspace.yaml` allowBuilds, bumped `jest` to latest 30.5.2, regenerated `pnpm-lock.yaml`. No push access to `book000/fixdevcontainer` — forked to `akubiusa/fixdevcontainer`, pushed there. Verified locally: `pnpm install --frozen-lockfile` succeeds (no ERR_PNPM_IGNORED_BUILDS), `pnpm test` 6/6 passing. Fix PR: https://github.com/book000/fixdevcontainer/pull/375 — CI confirmed green: both originally-failing checks passed (`Node CI / node-ci (.)`, `Node CI / Check finished Node CI`); no unrelated new failures (all 4 non-skipped checks passed).

### tomacheese/pex-crawler#2170

- checkpoint: fix-pr-opened
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 — stale-unexplained-minor, bumped to 12.5.1 in the fix PR (matches the established pattern for this same root cause, e.g. `tomacheese/watch-quicpay#2492`/`tomacheese/get-twitter-birthdays#308`).
- detail: `pnpm-workspace.yaml` has `confirmModulesPurge: false`, a pnpm v11-only setting. Renovate's PR bumps `packageManager` to pnpm 12.4.2; pnpm 12 dropped that setting entirely, so `pnpm install --frozen-lockfile` hard-fails with `ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`, failing `Node CI / node-ci (.)` (and downstream `Check finished Node CI`) and, by the same root cause, `Docker CI`'s build jobs (which also run `pnpm install`) — same root cause pattern as `tomacheese/watch-quicpay#2492`/`tomacheese/get-twitter-birthdays#308` and other siblings this run. Fix: removed the obsolete `confirmModulesPurge` line from `pnpm-workspace.yaml`, bumped `packageManager` to latest `pnpm@12.5.1`, regenerated `pnpm-lock.yaml`. Had push access — pushed directly. Verified locally: `pnpm install --frozen-lockfile` succeeds, `pnpm run lint` clean, `pnpm run test` 4/4 passing. Fix PR: https://github.com/tomacheese/pex-crawler/pull/2207

### tomacheese/watch-discord-dev-changes#2349

- checkpoint: fix-pr-opened
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 — stale-unexplained-minor. Bumped to 12.5.1 in the fix PR per rule.
- detail: Same root-cause pattern as `tomacheese/pex-crawler#2170` and several other sibling PRs. `pnpm-workspace.yaml` has `confirmModulesPurge: false`, a pnpm v11-only setting. Renovate's PR bumps `packageManager` to pnpm 12.4.2; pnpm 12 dropped that setting, so `pnpm install --frozen-lockfile` hard-fails with `ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`, failing `Node CI / node-ci (.)` (+ `Check finished Node CI`) and `Docker CI`'s build jobs (which also run `pnpm install`). Fix: removed the obsolete `confirmModulesPurge` line from `pnpm-workspace.yaml`, bumped `packageManager` to pnpm 12.5.1 (latest), regenerated `pnpm-lock.yaml`, on branch `fix/pnpm-v12-workspace-settings` off `master`. Had push access — pushed directly (via SSH remote). Verified locally: `pnpm install --frozen-lockfile` succeeds, `pnpm run lint` clean, `pnpm run test` 16/16 passing. Fix PR: https://github.com/tomacheese/watch-discord-dev-changes/pull/2387 — awaiting fix PR's own CI before marking completed.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-book000-pixivts-1928
    target: book000/pixivts#1928
    checks: node-ci,Check finished Node CI
  - slot: investigator-jaoafa-jaotan-ts-2321
    target: jaoafa/jaotan.ts#2321
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (jaotan.ts, linux/amd64),Docker CI / Docker build (jaotan.ts, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-pex-crawler-2170
    target: tomacheese/pex-crawler#2170
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (pex-crawler, linux/amd64),Docker CI / Docker build (pex-crawler, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-watch-discord-dev-changes-2349
    target: tomacheese/watch-discord-dev-changes#2349
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-discord-dev-changes, linux/amd64),Docker CI / Docker build (watch-discord-dev-changes, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-watch-vrchat-user-531
    target: tomacheese/watch-vrchat-user#531
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI
pending (not yet dispatched, in order):
  - tomacheese/fetch-youtube-bgm#3024 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-quicpay#2525 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/get-twitter-birthdays#332 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-vrchat-user#532 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3025 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-vrchat-user#534 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3026 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-vrchat-user#535 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3027 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-vrchat-user#536 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3028 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-vrchat-user#537 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3029 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/fetch-youtube-bgm#3030 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
done this sweep: 60 (fixed=60 skipped=0 blocked=0)

## Conflict-fixer queue

(empty — no fix PRs opened yet this sweep.)

## Escalate-to-user policy

No standing override in effect. Default behavior applies: relay any
`escalate-to-user` Arbiter verdict immediately via `AskUserQuestion`.

## Remaining broken Renovate PRs

(carried from prior sweeps, unaffected by this sweep unless re-discovered)

- book000/create-ts#65 — skipped: upstream rolldown-plugin-dts @volar/typescript type leak persists; owner previously declined special Renovate rule. Re-confirmed unchanged for 4 consecutive sweeps (2026-08-01, 2026-08-12, 2026-08-24, 2026-08-27).
- tomacheese/comico-downloader#831, tomacheese/api.tomacheese.com#511, tomacheese/collect-points#757, tomacheese/collect-points#697 — blocked: account-wide `tomacheese` org GitHub Actions billing/spending-limit outage, ongoing since 2026-08-22. No code fix possible; status not re-verified this sweep (not re-discovered by today's TSV — recheck next sweep if it recurs).

## Cleanup

`scratchpad/renovate-fix-chrome-response-recorder-409` still root-owned/unremovable (unchanged, 2026-09-20 re-check).

Duplicate fix PRs for the same root cause: `tomacheese/fetch-youtube-bgm#3021`'s fix PR #3031 and `#3023`'s fix PR #3033 both independently fix the identical `buildpack-deps:bullseye`→`bookworm` Dockerfile issue (discovered post-hoc by #3023's investigator; same-repo serialization was not violated, both were separate branches off master). Both are tracked by the fix-PR conflict/terminal monitor via the ledger; once one merges, close the other manually to avoid a stale/conflicting duplicate.

## Next concrete action

Drive the 2026-09-20 sweep's refill loop to completion (82 candidates
queued, 5 in flight). Recommend the user resolve the `tomacheese` org's
GitHub Actions billing issue directly if it recurs in this sweep's
discovery.
