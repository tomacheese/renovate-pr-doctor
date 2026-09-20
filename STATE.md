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

### jaoafa/jaotan.ts#2268

- checkpoint: completed
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 — stale-unexplained-minor, bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `tomacheese/tomachi-emojis-sync-perms#2543` and several sibling PRs this run. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in a brand-new transitive dependency, `@parcel/watcher@2.6.0` (used by jest's internal file watching), which ships a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allow-list doesn't include it, so `pnpm install` hard-fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0` in Node CI and (downstream, same root cause since Docker build also runs `pnpm install`) both Docker CI matrix jobs. Fix: added `@parcel/watcher: true` to `pnpm-workspace.yaml` allowBuilds, bumped `jest` to latest 30.5.2, regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm install` succeeds (no ERR_PNPM_IGNORED_BUILDS), `pnpm run lint` clean, `pnpm run test` 44/44 passing. Fix PR: https://github.com/jaoafa/jaotan.ts/pull/2329 — CI confirmed green: all 15 non-skipped checks passed, including all 5 originally-failing checks (`Node CI / node-ci (.)`, `Node CI / Check finished Node CI`, both `Docker CI / Docker build` matrix jobs, `Docker CI / Check finished Docker CI`); no unrelated new failures.

### tomacheese/pex-crawler#2155

- checkpoint: fix-pr-opened
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 — stale-unexplained-minor, bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `jaoafa/jaotan.ts#2268`/`tomacheese/tomachi-emojis-sync-perms#2543` and several sibling PRs this run. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in a brand-new transitive dependency, `@parcel/watcher@2.6.0` (confirmed absent from `origin/master`'s `pnpm-lock.yaml`, present in the PR branch's), which ships a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allow-list (currently `esbuild`, `unrs-resolver`) doesn't include it, so `pnpm install` hard-fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0` in Node CI and (downstream, same root cause since Docker build also runs `pnpm install`) both Docker CI matrix jobs (linux/amd64, linux/arm64). Fix: added `'@parcel/watcher': true` to `pnpm-workspace.yaml` allowBuilds, bumped `jest` to latest 30.5.2, regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm install` succeeds (no ERR_PNPM_IGNORED_BUILDS), `pnpm run lint` clean, `pnpm run test` 4/4 passing. Fix PR: https://github.com/tomacheese/pex-crawler/pull/2206 — waiting on CI.

### tomacheese/vrcx-web-server#1203

- checkpoint: completed
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 — stale-unexplained-minor, bumped to 12.5.1 in fix PR.
- detail: Renovate bumps `packageManager` pnpm 11.x -> 12.4.2. `pnpm-workspace.yaml` still has `confirmModulesPurge: false`, a pnpm v11-only setting removed in v12. Since `packageManager` pins the exact pnpm version, pnpm hard-errors (`ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`, not just a warning) on any install, failing `Node CI / node-ci (.)` and (same `pnpm install` step) `Docker CI / Docker build (vrcx-web-server, linux/amd64)`, plus their downstream "Check finished" jobs. Fix: removed `confirmModulesPurge` from `pnpm-workspace.yaml` (its purpose — confirm before purging node_modules — has no v12 equivalent setting, so no replacement needed), kept `allowBuilds`/`minimumReleaseAgeExclude` as-is (still recognized by v12), bumped `packageManager` to `pnpm@12.5.1` (per dependency-currency check), regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm install --frozen-lockfile` (same command CI runs) succeeds, `pnpm run lint` (prettier+eslint+tsc) clean; no test suite in this repo. Fix PR: https://github.com/tomacheese/vrcx-web-server/pull/1241 — CI confirmed green: all 4 targeted checks passed (`Node CI / node-ci (.)`, `Node CI / Check finished Node CI`, `Docker CI / Docker build (vrcx-web-server, linux/amd64)`, `Docker CI / Check finished Docker CI`); no unrelated new failures (10/10 non-skipped checks passed).

### book000/node-utils#1646

- checkpoint: fix-pr-opened
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 — stale-unexplained-minor, bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `jaoafa/jaotan.ts#2268`/`tomacheese/pex-crawler#2155`/`tomacheese/tomachi-emojis-sync-perms#2543` and several sibling PRs this run. Renovate bumps `jest` 30.4.2 -> 30.5.1, pulling in a brand-new transitive dependency, `@parcel/watcher@2.6.0` (jest-haste-map's watchman replacement per the 30.5.0 changelog), which ships a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allow-list (currently `esbuild`, `unrs-resolver`) doesn't include it, so `pnpm install` hard-fails with `ERR_PNPM_IGNORED_BUILDS: Ignored build scripts: @parcel/watcher@2.6.0`, and the reusable CI workflow (`book000/templates`'s `reusable-nodejs-ci-pnpm.yml`) additionally hard-fails the job on any "Ignored build scripts" line in the install log, failing both `Node CI / node-ci (.)` and its downstream `Check finished Node CI`. (Local repro was masked by this machine's own global `~/.config/pnpm/config.yaml` having `dangerouslyAllowAllBuilds: true`, which bypasses the exact check CI enforces — confirmed root cause from the actual failing run's logs instead, and did not touch that global user setting.) Fix: added `'@parcel/watcher': true` to `pnpm-workspace.yaml` allowBuilds, bumped `jest` to latest 30.5.2, regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm run compile` succeeds, `pnpm run test` 110/110 passing. Fix PR: https://github.com/book000/node-utils/pull/1688 — waiting on CI.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-tomacheese-vrcx-web-server-1203
    target: tomacheese/vrcx-web-server#1203
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (vrcx-web-server, linux/amd64),Docker CI / Check finished Docker CI
  - slot: investigator-book000-pixivts-1928
    target: book000/pixivts#1928
    checks: node-ci,Check finished Node CI
  - slot: investigator-tomacheese-pex-crawler-2155
    target: tomacheese/pex-crawler#2155
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (pex-crawler, linux/amd64),Docker CI / Docker build (pex-crawler, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-jaoafa-jaotan-ts-2268
    target: jaoafa/jaotan.ts#2268
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (jaotan.ts, linux/amd64),Docker CI / Docker build (jaotan.ts, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-book000-node-utils-1646
    target: book000/node-utils#1646
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
pending (not yet dispatched, in order):
  - tomacheese/watch-discord-dev-changes#2335 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-discord-dev-changes, linux/amd64),Docker CI / Docker build (watch-discord-dev-changes, linux/arm64),Docker CI / Check finished Docker CI]
  - book000/fixdevcontainer#361 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-pixiv-bookmarks#2186 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-pixiv-bookmarks, linux/amd64),Docker CI / Docker build (watch-pixiv-bookmarks, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/collect-points#758 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/api.tomacheese.com#512 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (api.tomacheese.com, linux/amd64),Docker CI / Check finished Docker CI]
  - jaoafa/ChatWatcher#392 [checks: build,build]
  - book000/templates#488 [checks: Test reusable-maven / Maven build,Test reusable-maven / Check finished Maven build,Test Summary Finished]
  - tomacheese/watch-vrchat-user#530 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI]
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
done this sweep: 31 (fixed=31 skipped=0 blocked=0)

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
