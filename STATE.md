# Current state (last updated: 2026-09-20)

## Phase

Sweep in progress: 2026-09-20. Discovery found 82 candidates (default:
book000/tomacheese/jaoafa orgs, assignee=book000) — none matched an
existing ledger row (all classified NEW). Filling initial 5 concurrency
slots; refill loop in progress.

## Targets and their state

(populated per-PR as Investigators/Arbiters/Executors report in)

### tomacheese/telcheck#2635

- checkpoint: fix-pr-opened
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: The eslint-config bump (1.16.66 → 1.16.67) updates `eslint-plugin-unicorn` to v75, which newly flags 7 pre-existing `if` statements (in `src/main.ts`, `src/utils/nvr510.ts`, `src/utils/search-number.ts`, `src/utils/web-push.ts`) under `unicorn/prefer-ternary`. `pnpm run lint` (eslint step) fails, which fails both `Node CI / node-ci (.)` and its downstream `Node CI / Check finished Node CI`. Fix: bumped `@book000/eslint-config` to 1.16.67, converted the 7 flagged `if` statements to ternary expressions (6/7 via `eslint --fix`, 1 by hand in `src/utils/nvr510.ts` due to an interleaved comment), reformatted with prettier. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm run lint` (prettier+eslint+tsc, clean), `npx depcheck` (no issues). Fix PR: https://github.com/tomacheese/telcheck/pull/2640 — waiting on its CI.

### tomacheese/fauxcord#314

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: Same root-cause pattern as `tomacheese/telcheck#2635`. The eslint-config bump (1.16.66 → 1.16.67) updates `eslint-plugin-unicorn` to v75, which newly flags 131 pre-existing lint violations across `src/services/*.ts` and `src/validators/*.ts` (`unicorn/no-immediate-mutation`, `unicorn/prefer-ternary`, `unicorn/prefer-early-return`). `pnpm run lint` (eslint step) fails, which fails both `Node CI / node-ci (.)` and its downstream `Node CI / Check finished Node CI`. Confident fix: apply eslint `--fix` (112/131 auto-fixable) and manually fix the remaining ~19.

### tomacheese/samechan-crawler#3429

- checkpoint: fix-pr-opened
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 (unexplained minor gap) — bumped to 12.5.1 in fix PR.
- detail: PR only bumps `packageManager` in `package.json` from `pnpm@11.27.0` to `pnpm@12.4.2`. Repo's `pnpm-workspace.yaml` still sets `confirmModulesPurge: false`, a pnpm-v11-only setting that pnpm 12 no longer recognizes; `pnpm install --frozen-lockfile` fails with `ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`, failing both `Node CI / node-ci (.)` and `Docker CI / Docker build`. Confirmed via pnpm 12.4.2's own CHANGELOG.md (no replacement setting was introduced — the option was simply dropped). Fix: removed `confirmModulesPurge: false` from `pnpm-workspace.yaml`, bumped `packageManager` to `pnpm@12.5.1`, regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm install` (no ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS), `pnpm run lint` (prettier+eslint+tsc, clean). Fix PR: https://github.com/tomacheese/samechan-crawler/pull/3472 — waiting on CI.

### tomacheese/watch-follow-follower#703

- checkpoint: root-cause-identified
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 (unexplained minor gap) — will bump to 12.5.1 in fix PR.
- detail: Same root-cause pattern as `tomacheese/samechan-crawler#3429`. PR only bumps `packageManager` in `package.json` from `pnpm@11.27.0` to `pnpm@12.4.2`. Repo's `pnpm-workspace.yaml` still sets `confirmModulesPurge: false`, a pnpm-v11-only setting pnpm 12 no longer recognizes; `pnpm install`/`pnpm fetch` fails with `ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`, failing `Node CI / node-ci (.)` and both `Docker CI / Docker build` matrix legs (amd64/arm64), and their downstream "Check finished" jobs. Confident fix: remove `confirmModulesPurge: false` from `pnpm-workspace.yaml`, bump `packageManager` to `pnpm@12.5.1`, regenerate `pnpm-lock.yaml`.

### tomacheese/sync-claude-folder#116

- checkpoint: completed
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 (unexplained minor gap) — bumped to 30.5.2 in fix PR.
- detail: Same root-cause pattern as `tomacheese/get-twitter-birthdays#299` / `tomacheese/booth-purchased-items-manager#1137` / `tomacheese/watch-jcb#1609`. jest 30.5.x pulls in a new transitive dep `@parcel/watcher@2.6.0` with a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allowlist only has `esbuild`/`unrs-resolver`, so `pnpm install` fails with `ERR_PNPM_IGNORED_BUILDS` in `Node CI / node-ci (.)`, which fails downstream `Node CI / Check finished Node CI`. Fix: added `@parcel/watcher: true` to `allowBuilds` in `pnpm-workspace.yaml`, bumped `jest` to 30.5.2, regenerated `pnpm-lock.yaml`. Had push access — pushed branch directly, no fork needed. Verified locally: `pnpm install` (no ERR_PNPM_IGNORED_BUILDS), `pnpm run lint` (prettier+eslint+tsc, clean), `pnpm test` (4 suites, 36 tests, all passed). Fix PR: https://github.com/tomacheese/sync-claude-folder/pull/152 — all 6 real checks passed on CI (Node CI setup/node-ci/Check finished, Analyze x2, CodeQL), no unrelated failures.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-tomacheese-watch-follow-follower-703
    target: tomacheese/watch-follow-follower#703
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-follow-follower, linux/amd64),Docker CI / Docker build (watch-follow-follower, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-samechan-crawler-3429
    target: tomacheese/samechan-crawler#3429
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (samechan-crawler, linux/amd64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-sync-claude-folder-116
    target: tomacheese/sync-claude-folder#116
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-tomacheese-telcheck-2635
    target: tomacheese/telcheck#2635
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-tomacheese-fauxcord-314
    target: tomacheese/fauxcord#314
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
pending (not yet dispatched, in order):
  - book000/pixivts#1928 [checks: node-ci,Check finished Node CI]
  - book000/twitter-rss#3770 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/rss-deliver#2787 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/kindle-booklog#2510 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/niconico-mylist-video-checker#2716 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/twitter-auto-spam-crawler#637 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/moneyforward-collector#2672 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/chrome-response-recorder#583 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/create-ts#221 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - jaoafa/watch-guilds#2312 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/web-session-tracer#148 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - book000/node-utils#1646 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - jaoafa/jaotan.ts#2268 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (jaotan.ts, linux/amd64),Docker CI / Docker build (jaotan.ts, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/vrcx-web-server#1203 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (vrcx-web-server, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/pex-crawler#2155 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (pex-crawler, linux/amd64),Docker CI / Docker build (pex-crawler, linux/arm64),Docker CI / Check finished Docker CI]
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
done this sweep: 16 (fixed=16 skipped=0 blocked=0)

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
