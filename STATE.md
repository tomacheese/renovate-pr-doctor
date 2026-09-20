# Current state (last updated: 2026-09-20)

## Phase

Sweep in progress: 2026-09-20. Discovery found 82 candidates (default:
book000/tomacheese/jaoafa orgs, assignee=book000) — none matched an
existing ledger row (all classified NEW). Filling initial 5 concurrency
slots; refill loop in progress.

## Targets and their state

(populated per-PR as Investigators/Arbiters/Executors report in)

### tomacheese/fauxcord#314

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: Same root-cause pattern as `tomacheese/telcheck#2635`. The eslint-config bump (1.16.66 → 1.16.67) updates `eslint-plugin-unicorn` to v75, which newly flags 131 pre-existing lint violations across `src/services/*.ts` and `src/validators/*.ts` (`unicorn/no-immediate-mutation`, `unicorn/prefer-ternary`, `unicorn/prefer-early-return`). `pnpm run lint` (eslint step) fails, which fails both `Node CI / node-ci (.)` and its downstream `Node CI / Check finished Node CI`. Confident fix: apply eslint `--fix` (112/131 auto-fixable) and manually fix the remaining ~19.

### book000/pixivts#1928

- checkpoint: root-cause-identified
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: Same root-cause pattern as `tomacheese/fauxcord#314`/`tomacheese/telcheck#2635`. The eslint-config bump newly flags 42 pre-existing lint violations (41 errors, 1 warning) across `packages/core/src/*.ts`, `packages/core/tests/**`, `packages/db-mysql/tests/*.ts`, and `scripts/check-pr-language.mjs` (`unicorn/prefer-ternary`, `unicorn/prefer-early-return`, one unused eslint-disable directive). `pnpm run lint` (eslint step) fails, failing both `node-ci` and its downstream `Check finished Node CI`. Base branch is `develop` (not `main`). Confident fix: apply eslint `--fix` (38/41 auto-fixable) and manually fix the remaining ~3.

### book000/twitter-rss#3770

- checkpoint: fix-pr-opened
- dependency currency: `@book000/eslint-config` proposed 1.16.67, latest 1.16.67 — current, no special handling.
- detail: Same root-cause pattern as `tomacheese/fauxcord#314`/`book000/pixivts#1928`. The eslint-config bump newly flags 2 pre-existing lint violations in `src/main.ts` (`unicorn/no-immediate-mutation` at line 145, `unicorn/prefer-ternary` at line 248). `yarn lint:eslint` fails, failing both `Node CI / node-ci (.)` and downstream `Node CI / Check finished Node CI`. Confident fix: `eslint --fix` auto-fixes the ternary; manually rewrote the immediate-mutation to a conditional spread (`...(proxy && { proxy })`). Push access confirmed (no fork needed). Fix PR: https://github.com/book000/twitter-rss/pull/3774

### book000/kindle-booklog#2510

- checkpoint: root-cause-identified
- dependency currency: `tar-stream` proposed 3.2.1, latest 3.2.1 — current, no special handling.
- detail: PR bumps `tar-stream` 3.2.0 → 3.2.1, which bumps its transitive `streamx` dependency to 2.28.1. streamx 2.28.1 tightens the `on()`/`EventHandler` typings to a contravariant `(data: unknown) => R`, so the existing `stream.on('data', (chunk: { toString: () => string }) => ...)` handler in `src/amazon.ts:350` no longer type-checks (`TS2345`). `pnpm run lint:tsc` fails, failing `Node CI / node-ci (.)` and downstream `Node CI / Check finished Node CI`. Confident fix: retype the handler param as `unknown` and cast to `Buffer` inside (chunks are Buffers at runtime; behavior unchanged).

### book000/rss-deliver#2787

- checkpoint: root-cause-identified
- dependency currency: `node-ical` proposed 0.27.2, latest 0.27.2 — current, no special handling.
- detail: PR only bumps `node-ical` to 0.27.2 in `package.json`, but `pnpm-lock.yaml` was not updated (`renovate/artifacts` check itself failed with "Artifact file update failure"). `pnpm install --frozen-lockfile` fails with `ERR_PNPM_OUTDATED_LOCKFILE` (specifier mismatch: lockfile 0.27.1 vs manifest 0.27.2), failing `Node CI / node-ci (.)` and downstream `Node CI / Check finished Node CI`. Confident fix: regenerate `pnpm-lock.yaml` via `pnpm install --lockfile-only` (or plain `pnpm install`).

## Queue

concurrency: 5
in-flight:
  - slot: investigator-book000-kindle-booklog-2510
    target: book000/kindle-booklog#2510
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-book000-pixivts-1928
    target: book000/pixivts#1928
    checks: node-ci,Check finished Node CI
  - slot: investigator-book000-twitter-rss-3770
    target: book000/twitter-rss#3770
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-book000-rss-deliver-2787
    target: book000/rss-deliver#2787
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-tomacheese-fauxcord-314
    target: tomacheese/fauxcord#314
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
pending (not yet dispatched, in order):
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
done this sweep: 20 (fixed=20 skipped=0 blocked=0)

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
