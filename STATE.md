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
- detail: Same root-cause pattern as `tomacheese/fauxcord#314`/`tomacheese/telcheck#2635`. The eslint-config bump newly flags 42 pre-existing lint violations (41 errors, 1 warning) across `packages/core/src/*.ts`, `packages/core/tests/**`, `packages/db-mysql/tests/*.ts`, and `scripts/check-pr-language.mjs` (`unicorn/prefer-ternary`, `unicorn/prefer-early-return`, one unused eslint-disable directive). `pnpm run lint` (eslint step) fails, failing both `node-ci` and its downstream `Check finished Node CI`. Base branch is `develop` (not `main`). Fix: included the eslint-config 1.16.67 bump, ran `eslint . --fix` (38/41 auto-fixed) and hand-converted the remaining 3 `unicorn/prefer-early-return` cases (`novels.e2e.test.ts`, `illusts.test.ts`, `recorder.test.ts`). No push access to `book000/pixivts` — forked to `akubiusa/pixivts`, pushed there. Verified locally: `pnpm run lint` clean, `pnpm run test` 234/234 passing. Fix PR: https://github.com/book000/pixivts/pull/1931 — waiting on CI.

### book000/fixdevcontainer#361

- checkpoint: completed
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 — stale-unexplained-minor, bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `tomacheese/pex-crawler#2155`/`book000/node-utils#1646`/`tomacheese/watch-discord-dev-changes#2335`/`jaoafa/jaotan.ts#2268`. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in a brand-new transitive dependency, `@parcel/watcher@2.6.0`, which ships a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allow-list (currently only `unrs-resolver`) doesn't include it, so `pnpm install --frozen-lockfile` hard-fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0`, failing `Node CI / node-ci (.)` and its downstream `Check finished Node CI`. Fix: added `'@parcel/watcher': true` to `pnpm-workspace.yaml` allowBuilds, bumped `jest` to latest 30.5.2, regenerated `pnpm-lock.yaml`. No push access to `book000/fixdevcontainer` — forked to `akubiusa/fixdevcontainer`, pushed there. Verified locally: `pnpm install --frozen-lockfile` succeeds (no ERR_PNPM_IGNORED_BUILDS), `pnpm test` 6/6 passing. Fix PR: https://github.com/book000/fixdevcontainer/pull/375 — CI confirmed green: both originally-failing checks passed (`Node CI / node-ci (.)`, `Node CI / Check finished Node CI`); no unrelated new failures (all 4 non-skipped checks passed).

### tomacheese/collect-points#758

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` 1.16.67 and `@book000/node-utils` 1.25.110 current; `@sentry/node` 10.75.0 and `zod` ^4.6.2 current. `@types/node` proposed 24.13.5, latest 26.6.2 — stale-unexplained-major. `node` (engines) proposed 24.21.0, latest 26.9.0 — stale-unexplained-major. `pnpm` proposed 11.27.0, latest 12.5.1 — stale-unexplained-major. `eslint` proposed 10.10.0, latest 10.11.0 and `prettier`/`tsx` also stale-unexplained-minor — per priority rule, major-package presence takes precedence, so fix PR targets the Renovate PR's currently-proposed versions unchanged and majors are escalated separately (see below).
- detail: Different root cause from the sibling jest/@parcel/watcher pattern in this sweep — verified independently, does not match. Not the same as `tomacheese/collect-points#670` either (different PR/signature). Tests pass (444/444); `Run linter` step fails: the `@book000/eslint-config` 1.16.67 bump enables/tightens `unicorn/prefer-ternary`, `unicorn/prefer-early-return`, `unicorn/prefer-continue`, newly flagging 52 pre-existing lint violations across many source/test files unrelated to this Renovate PR's diff. Same class of issue as `book000/pixivts#1928` (eslint-config bump exposing latent unicorn violations). Plan: run `eslint . --fix` (40/52 auto-fixable per CI log) then hand-fix the remaining ~12 non-auto-fixable violations, in a separate fix PR against `main`/default branch — confident mechanical fix, no escalation needed for the CI failure itself. Will ALSO escalate the 3 stale-unexplained-major packages (`@types/node`, `node`, `pnpm`) via NEEDS_ARBITER once fix PR is opened.

### tomacheese/api.tomacheese.com#512

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` 1.16.67 and `@book000/node-utils` 1.25.110 current; `fastify` 5.12.5 and `undici` 8.10.2 current. `@types/node` proposed 25.9.7, latest 26.6.2 — stale-unexplained-major. `node` (engines) proposed 24.21.0, latest 26.9.0 — stale-unexplained-major. `eslint`/`jest`/`pnpm`/`prettier`/`tsx` also stale-unexplained-minor — per priority rule, major-package presence takes precedence, so fix PR targets the Renovate PR's currently-proposed versions unchanged and majors are escalated separately (see below).
- detail: Same root-cause pattern as `tomacheese/pex-crawler#2155`/`book000/node-utils#1646`/`jaoafa/jaotan.ts#2268`/`tomacheese/watch-discord-dev-changes#2335`/`tomacheese/watch-pixiv-bookmarks#2186` — verified independently. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in `@parcel/watcher@2.6.0`'s native postinstall script, not in `pnpm-workspace.yaml`'s `allowBuilds` allow-list (currently `better-sqlite3`, `esbuild`, `unrs-resolver`), so `pnpm install --frozen-lockfile` fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0`, failing `Node CI / node-ci (.)` + `Node CI / Check finished Node CI`. `Docker CI / Docker build (api.tomacheese.com, linux/amd64)` + `Docker CI / Check finished Docker CI` fail the same way (Docker build also runs `pnpm install --frozen-lockfile`). Fix: add `'@parcel/watcher': true` to `pnpm-workspace.yaml` allowBuilds, regenerate `pnpm-lock.yaml` (no version bumps, since 2 stale-unexplained-major packages are present — leaving proposed versions unchanged per priority rule), in a separate fix PR against `master`. Will ALSO escalate `@types/node` and `node` (stale-unexplained-major) via NEEDS_ARBITER once fix PR is opened.

### book000/templates#488

- checkpoint: fix-pr-opened
- dependency currency: `actions/setup-java` proposed v6.0.1, latest v6.0.1 — current, no special handling.
- detail: Same root-cause pattern as `jaoafa/ChatWatcher#392`. `.github/workflows/reusable-maven.yml`'s "Set up JDK 17" step hardcodes `distribution: adopt` (the `jdk-distribution` workflow_call input is declared but never actually wired into this step — pre-existing latent dead input, out of scope to fix here). `actions/setup-java` v6 removed the legacy `adopt`/`adopt-openj9` distributions, so `Test reusable-maven / Maven build` fails immediately with `No supported distribution was found for input adopt`, cascading to `Test reusable-maven / Check finished Maven build` and `Test Summary Finished`. Fix: bumped `actions/setup-java` to v6.0.1 (same version #488 proposes) and changed `distribution: adopt` to `distribution: temurin` in `reusable-maven.yml`, against `master` (not #488's own branch). Had push access — pushed branch directly, no fork needed. Fix PR: https://github.com/book000/templates/pull/511 — waiting on CI.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-tomacheese-api-tomacheese-com-512
    target: tomacheese/api.tomacheese.com#512
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (api.tomacheese.com, linux/amd64),Docker CI / Check finished Docker CI
  - slot: investigator-book000-pixivts-1928
    target: book000/pixivts#1928
    checks: node-ci,Check finished Node CI
  - slot: investigator-book000-templates-488
    target: book000/templates#488
    checks: Test reusable-maven / Maven build,Test reusable-maven / Check finished Maven build,Test Summary Finished
  - slot: investigator-tomacheese-watch-vrchat-user-530
    target: tomacheese/watch-vrchat-user#530
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-collect-points-758
    target: tomacheese/collect-points#758
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
pending (not yet dispatched, in order):
  - tomacheese/pixiv-public-to-private#3322 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/fetch-youtube-bgm#3023 [checks: Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/tomachi-emojis-sync-perms#2594 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/misskey-list-eyes#2630 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/auto-update-web-scrobbler#2360 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-quicpay#2492 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-quicpay, linux/amd64),Docker CI / Docker build (watch-quicpay, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/discord-crosspost-auto-translate#2694 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-bsky-likes#1410 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/booth-purchased-items-manager#1191 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-jcb#1667 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/lock-move-channel#2692 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/get-twitter-birthdays#308 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (get-twitter-birthdays, linux/amd64),Docker CI / Docker build (get-twitter-birthdays, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/samechan-crawler#3468 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/sync-claude-folder#150 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-follow-follower#733 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/rss-deliver#2793 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/kindle-booklog#2572 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/twitter-auto-spam-crawler#675 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/create-ts#269 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/node-utils#1685 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - jaoafa/jaotan.ts#2321 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (jaotan.ts, linux/amd64),Docker CI / Docker build (jaotan.ts, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/pex-crawler#2170 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (pex-crawler, linux/amd64),Docker CI / Docker build (pex-crawler, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-discord-dev-changes#2349 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-discord-dev-changes, linux/amd64),Docker CI / Docker build (watch-discord-dev-changes, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-vrchat-user#531 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
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
done this sweep: 39 (fixed=39 skipped=0 blocked=0)

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

## Next concrete action

Drive the 2026-09-20 sweep's refill loop to completion (82 candidates
queued, 5 in flight). Recommend the user resolve the `tomacheese` org's
GitHub Actions billing issue directly if it recurs in this sweep's
discovery.
