# Current state (last updated: 2026-08-12)

## Phase

Sweep in progress: started 2026-08-12. Discovery found 5 candidates
(book000/tomacheese/jaoafa, assignee=book000, default). All 5 dispatched
to Investigators immediately (concurrency 5, no backlog).

## Targets and their state

### tomacheese/cmcutter#2692
- Investigator dispatched 2026-08-12. Failing checks: Node CI / node-ci
  (.), Node CI / Check finished Node CI.

### book000/templates#465
- checkpoint: root-cause-identified (2026-08-12). Dependency currency:
  `hadolint/hadolint-action` proposed `v3.4.0`, latest `v3.4.0` (`current`,
  nothing to note). Root cause: this action bump pulls in hadolint
  `v2.15.0`, which flags `test-scenarios/docker/Dockerfile:31`
  (`USER appuser`) with `DL3066` ("Non-numeric user-id may not be
  resolvable by host system") at the default `info` failure-threshold —
  `appuser` is a named (non-numeric) user, previously not flagged by
  hadolint bundled in `v3.3.0`. Confident, low-risk fix: switch that line
  to the numeric `USER 1000:1000` (matches the UID/GID the same Dockerfile
  already creates via `addgroup -g 1000`/`adduser -u 1000`). Verified
  locally with `docker run --rm -i hadolint/hadolint:v2.15.0` against the
  fixed Dockerfile — clean, no findings.

### book000/node-utils#1593
- checkpoint: root-cause-identified (2026-08-12). Renovate bumped
  `@sentry/node` to `10.69.0` in `package.json` but failed to regenerate
  `pnpm-lock.yaml` (matches the separately-failing `renovate/artifacts`
  check: "Artifact file update failure"). `pnpm install --frozen-lockfile`
  in Node CI then fails with `ERR_PNPM_OUTDATED_LOCKFILE` (lockfile:
  10.68.0, manifest: 10.69.0). Confident fix: regenerate the lockfile on a
  fresh branch.
- dependency currency: `@sentry/node` classified `stale-unexplained-minor`
  (proposed 10.69.0, latest 10.70.0) — bumping to 10.70.0 in the fix PR
  instead of the Renovate-proposed 10.69.0.

### tomacheese/booth-purchased-items-manager#1047
- checkpoint: root-cause-identified (2026-08-12). Renovate bumped
  `node-html-parser` to `9.0.1` in `package.json` but failed to
  regenerate `pnpm-lock.yaml` (still pinned to `9.0.0`) — matches the
  separately-failing `renovate/artifacts` check ("Artifact file update
  failure"). `pnpm install --frozen-lockfile` then fails with
  `ERR_PNPM_OUTDATED_LOCKFILE`, which cascades to both Node CI and Docker
  CI (same frozen-lockfile install step). Confident fix: regenerate the
  lockfile on a fresh branch.
- dependency currency: `node-html-parser` classified `current` (proposed
  9.0.1 == latest 9.0.1) — no version bump beyond what the Renovate PR
  already proposes.

### book000/create-ts#65
- Investigator dispatched 2026-08-12 (recheck). Ledger had a `fixed` row
  (2026-08-01, signature
  `rolldown-plugin-dts-override-bump-reintroduces-volar-typescript-type-leak`,
  noted "PR #65 itself invalid/should be closed") but PR #65 still shows up
  in today's discovery as CI-failing — per the always-recheck-fixed-rows
  rule. Failing checks: Node CI / node-ci (.), Node CI / Check finished
  Node CI.

## Queue

concurrency: 5
in-flight:
  - slot: investigator-cmcutter-2692
    target: tomacheese/cmcutter#2692
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-templates-465
    target: book000/templates#465
    checks: Test reusable-hadolint-ci / hadolint,Test Summary Finished
  - slot: investigator-node-utils-1593
    target: book000/node-utils#1593
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
  - slot: investigator-booth-purchased-items-manager-1047
    target: tomacheese/booth-purchased-items-manager#1047
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI,Docker CI / Docker build (booth-purchased-items-manager, linux/amd64),Docker CI / Docker build (booth-purchased-items-manager, linux/arm64),Docker CI / Check finished Docker CI
  - slot: investigator-create-ts-65
    target: book000/create-ts#65
    checks: Node CI / node-ci (.),Node CI / Check finished Node CI
    recheck-of: fixed/rolldown-plugin-dts-override-bump-reintroduces-volar-typescript-type-leak
pending (not yet dispatched, in order):
  (empty)
done this sweep: 0

## Conflict-fixer queue

(empty — will arm once the first fix PR is opened this sweep.)

## Escalate-to-user policy

No standing override in effect. Default behavior applies: relay any
`escalate-to-user` Arbiter verdict immediately via `AskUserQuestion`.

## Next concrete action

Waiting on SendMessage reports from the 5 in-flight Investigators. On each
report: handle per skill Step 4 (escalation dispatch or terminal
ledger/records write + slot refill). Queue is empty so refills are no-ops
unless a report itself queues something new (none expected).

## Open questions / concerns
(none)
