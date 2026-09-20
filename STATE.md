# Current state (last updated: 2026-09-20)

## Phase

Sweep in progress: 2026-09-20. Discovery found 82 candidates (default:
book000/tomacheese/jaoafa orgs, assignee=book000) — none matched an
existing ledger row (all classified NEW). Filling initial 5 concurrency
slots; refill loop in progress.

## Targets and their state

(populated per-PR as Investigators/Arbiters/Executors report in)

### book000/chrome-mcp-router#115

- checkpoint: completed
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: `@book000/eslint-config` bump to 1.16.67 enables/tightens `unicorn/prefer-ternary` and `unicorn/prefer-early-return` rules, flagging 6 pre-existing lint violations in `src/bridge.ts`, `src/config.ts`, `src/index.ts` (tests pass, depcheck passes). Note: repo has no `.prettierrc` — used manual style-matched fixes (no semicolons, single quotes) instead of `pnpm run format`, which uses prettier's own defaults and would have reformatted every file. Fix PR: https://github.com/book000/chrome-mcp-router/pull/116, branch `fix/eslint-config-1-16-67-lint-errors` — all 3 checks (setup, node-ci, Check finished) passed on run 35504946870. Done.

### tomacheese/fetch-youtube-bgm#3021

- checkpoint: fix-pr-opened
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest lookup-failed — no special handling, proceed with proposed version.
- detail: `@book000/eslint-config` bump to 1.16.67 tightens `unicorn/prefer-ternary`, `unicorn/prefer-early-return`, `unicorn/prefer-continue`, `unicorn/no-useless-length-check` rules, flagging 7 pre-existing lint errors + 2 warnings across `downloader/src/{discord,lib,main,musicbrainz}.ts` (5 errors/2 warnings auto-fixable, 2 need manual fix). Docker build failure for downloader is a downstream consequence of the same lint failure (build step runs lint). Fixed via `eslint --fix` + manual fixes for the 2 non-auto-fixable rules (verified locally against eslint-config 1.16.67), NOT bumping the dependency itself. Fix PR: https://github.com/tomacheese/fetch-youtube-bgm/pull/3031 — waiting on its CI.

### tomacheese/pixiv-public-to-private#3289

- checkpoint: fix-pr-opened
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 (unexplained minor gap) — bumped to 12.5.1 in fix PR.
- detail: PR bumps pnpm 11.27.0 → 12.4.2 and pins it via `packageManager` in package.json. `pnpm-workspace.yaml` still has `confirmModulesPurge: false`, a pnpm v11-only setting. With `packageManager` pinned, pnpm 12 treats an unrecognized workspace setting as a hard error (`ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`) rather than a warning, failing `pnpm install --frozen-lockfile` in both Node CI and Docker CI (same install step, both platforms). Fix: removed `confirmModulesPurge` from `pnpm-workspace.yaml`, bumped `packageManager`/lockfile to pnpm 12.5.1 (latest), regenerated `pnpm-lock.yaml`. Local verification passed (`pnpm install --frozen-lockfile`, lint, `docker build`). Had push access — pushed branch directly, no fork needed. Fix PR: https://github.com/tomacheese/pixiv-public-to-private/pull/3326 — waiting on its own CI to confirm before marking completed.

### tomacheese/tomachi-emojis-sync-perms#2543

- checkpoint: completed
- dependency currency: `jest` proposed 30.5.1, latest 30.5.2 (unexplained minor gap) — bumped to 30.5.2 in fix PR.
- detail: jest 30.4.2 → 30.5.1 bump pulls in a new transitive dependency `@parcel/watcher@2.6.0` with a native postinstall build script; pnpm's default build-script allowlist blocks it (`ERR_PNPM_IGNORED_BUILDS`), failing `pnpm install --frozen-lockfile` in Node CI (and Docker CI, which runs the same install). Fix: added `@parcel/watcher: true` to `pnpm-workspace.yaml`'s `allowBuilds`, bumped jest to 30.5.2 (latest), regenerated lockfile. Local verification passed (install/test/compile/lint). Had push access — pushed branch directly, no fork needed. Fix PR: https://github.com/tomacheese/tomachi-emojis-sync-perms/pull/2598 — CI confirmed green (all 5 originally-failing checks now pass: Node CI / node-ci (.), Node CI / Check finished Node CI, Docker CI / Docker build amd64+arm64, Docker CI / Check finished Docker CI; no new failures). Done.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-tomacheese-watch-vrchat-user-529
    target: tomacheese/watch-vrchat-user#529
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-vrchat-user, linux/amd64),Docker CI / Docker build (watch-vrchat-user, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-book000-chrome-mcp-router-115
    target: book000/chrome-mcp-router#115
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-tomacheese-pixiv-public-to-private-3289
    target: tomacheese/pixiv-public-to-private#3289
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (pixiv-public-to-private, linux/amd64),Docker CI / Docker build (pixiv-public-to-private, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-fetch-youtube-bgm-3021
    target: tomacheese/fetch-youtube-bgm#3021
    checks: Node CI / node-ci (downloader),Node CI / Check finished Node CI,Docker CI / Docker build (fetch-youtube-bgm-downloader, linux/amd64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-tomachi-emojis-sync-perms-2543
    target: tomacheese/tomachi-emojis-sync-perms#2543
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (tomachi-emojis-sync-perms, linux/amd64),Docker CI / Docker build (tomachi-emojis-sync-perms, linux/arm64),Docker CI / Check finished Docker CI
pending (not yet dispatched, in order):
  - tomacheese/twitter-bookmark-hub#545 [checks: Node CI / node-ci (crawler),Node CI / node-ci (viewer/backend),Node CI / node-ci (viewer/frontend),Node CI / node-ci (analyzer),Node CI / Check finished Node CI]
  - tomacheese/misskey-list-eyes#2594 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (misskey-list-eyes, linux/amd64),Docker CI / Docker build (misskey-list-eyes, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/auto-update-web-scrobbler#2310 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-quicpay#2478 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-quicpay, linux/amd64),Docker CI / Docker build (watch-quicpay, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/discord-crosspost-auto-translate#2644 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (discord-crosspost-auto-translate, linux/amd64),Docker CI / Docker build (discord-crosspost-auto-translate, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/cmcutter#2810 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-bsky-likes#1383 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-bsky-likes, linux/amd64),Docker CI / Docker build (watch-bsky-likes, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/booth-purchased-items-manager#1137 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (booth-purchased-items-manager, linux/amd64),Docker CI / Docker build (booth-purchased-items-manager, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/watch-jcb#1609 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-jcb, linux/amd64),Docker CI / Docker build (watch-jcb, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/lock-move-channel#2659 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (lock-move-channel, linux/amd64),Docker CI / Docker build (lock-move-channel, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/get-twitter-birthdays#299 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (get-twitter-birthdays, linux/amd64),Docker CI / Docker build (get-twitter-birthdays, linux/arm64),Docker CI / Check finished Docker CI]
  - tomacheese/samechan-crawler#3429 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (samechan-crawler, linux/amd64),Docker CI / Check finished Docker CI]
  - tomacheese/sync-claude-folder#116 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/telcheck#2635 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/fauxcord#314 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI]
  - tomacheese/watch-follow-follower#703 [checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-follow-follower, linux/amd64),Docker CI / Docker build (watch-follow-follower, linux/arm64),Docker CI / Check finished Docker CI]
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
done this sweep: 0

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
