# Current state (last updated: 2026-09-20)

## Phase

Sweep in progress: 2026-09-20. Discovery found 82 candidates (default:
book000/tomacheese/jaoafa orgs, assignee=book000) — none matched an
existing ledger row (all classified NEW). Filling initial 5 concurrency
slots; refill loop in progress.

## Targets and their state

(populated per-PR as Investigators/Arbiters/Executors report in)

### tomacheese/twitter-bookmark-hub#545

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: `@book000/eslint-config` 1.16.67 bump pulls in `eslint-plugin-unicorn` v75, tightening `unicorn/prefer-ternary`, `unicorn/prefer-early-return`, `unicorn/prefer-continue`, `unicorn/no-immediate-mutation`. This flags 39 pre-existing lint errors across all 4 npm workspaces (`crawler` 11, `viewer/backend` 8, `viewer/frontend` 19, `analyzer` 1), which is why all 4 `node-ci` matrix jobs fail identically at the `lint:eslint` step. Fix: `eslint --fix` per workspace + manual fixes for the handful of non-auto-fixable violations, verified locally against eslint-config 1.16.67, not bumping the dependency itself.

### tomacheese/watch-bsky-likes#1383

- checkpoint: root-cause-identified
- dependency currency: `pnpm` proposed 12.4.2, latest 12.5.1 (unexplained minor gap) — will bump to 12.5.1 in fix PR.
- detail: PR bumps `packageManager` pnpm 11.27.0 → 12.4.2. `pnpm-workspace.yaml` still has `confirmModulesPurge: false`, a pnpm v11-only setting pnpm v12 refuses to recognize (`ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`), which fails `pnpm install --frozen-lockfile` immediately in Node CI (and correspondingly Docker CI, which also runs pnpm install). This also explains the `renovate/artifacts` failure — Renovate's own lockfile regeneration hit the same error. Fix: remove `confirmModulesPurge: false` from `pnpm-workspace.yaml`, bump packageManager to pnpm@12.5.1, and regenerate `pnpm-lock.yaml`.

### tomacheese/booth-purchased-items-manager#1137

- checkpoint: root-cause-identified
- dependency currency: `jest`/`@jest/globals` proposed 30.5.1, latest 30.5.2 (unexplained minor gap) — will bump to 30.5.2 in fix PR.
- detail: jest 30.5.x pulls in a new transitive dep `@parcel/watcher@2.6.0` with a native build/postinstall script. `pnpm-workspace.yaml`'s `allowBuilds` allowlist only has `esbuild`/`unrs-resolver`, so pnpm 12's strict build-script gating fails `pnpm install` with `ERR_PNPM_IGNORED_BUILDS` in both Node CI and Docker CI (both run `pnpm install`). Fix: add `@parcel/watcher: true` to `allowBuilds` in `pnpm-workspace.yaml`.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-tomacheese-watch-jcb-1609
    target: tomacheese/watch-jcb#1609
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-jcb, linux/amd64),Docker CI / Docker build (watch-jcb, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-lock-move-channel-2659
    target: tomacheese/lock-move-channel#2659
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (lock-move-channel, linux/amd64),Docker CI / Docker build (lock-move-channel, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-watch-bsky-likes-1383
    target: tomacheese/watch-bsky-likes#1383
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (watch-bsky-likes, linux/amd64),Docker CI / Docker build (watch-bsky-likes, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-tomacheese-twitter-bookmark-hub-545
    target: tomacheese/twitter-bookmark-hub#545
    checks: Node CI / node-ci (crawler),Node CI / node-ci (viewer/backend),Node CI / node-ci (viewer/frontend),Node CI / node-ci (analyzer),Node CI / Check finished Node CI
  - slot: investigator-tomacheese-booth-purchased-items-manager-1137
    target: tomacheese/booth-purchased-items-manager#1137
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (booth-purchased-items-manager, linux/amd64),Docker CI / Docker build (booth-purchased-items-manager, linux/arm64),Docker CI / Check finished Docker CI
pending (not yet dispatched, in order):
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
done this sweep: 10 (fixed=10 skipped=0 blocked=0)

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
