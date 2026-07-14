# Fix PR Conflict Monitoring

A full-backlog sweep runs many sub-agents over a long wall-clock window,
each opening its own fix PR off the default branch. Meanwhile, *other*
Renovate PRs (including ones this same workflow or Renovate itself opens)
keep auto-merging into that default branch throughout the sweep. A fix PR
opened early in the sweep can therefore go stale — git-conflicting with the
default branch — well after its own CI already went green and it was marked
`completed`/ledger-`fixed`, so it needs its own monitor separate from
Liveness Monitoring.

**This is a distinct problem from Liveness Monitoring** (see
`liveness-monitoring.md`): the sub-agent that opened the fix PR already
finished successfully; the fix PR itself degrades afterward, asynchronously,
for reasons outside that sub-agent's control (concurrent unrelated merges).
Detecting and repairing it needs its own monitor, separate from the
in-flight liveness cron.

## Setting up the monitor

As soon as the first fix PR is opened in a sweep (i.e. the moment today's
`records/ledger-YYYY-MM-DD.tsv` gets its first `fixed` row with a real
`fix_pr_url`), start a persistent background `Monitor` (not `CronCreate` —
this needs continuous polling, not a fixed-interval single check) that:

- Polls every fix PR opened so far this sweep (today's `records/ledger-
  YYYY-MM-DD.tsv` rows with `status=fixed` and a non-empty `fix_pr_url`) on
  an interval of a few minutes (`gh pr view <fix-pr-number> -R <owner/repo>
  --json state,mergeable,mergeStateStatus`, e.g. every 300s — cheap enough
  for the sweep's typical scale, courteous of `gh` API rate limits at higher
  `--concurrency`). Do **not** pre-filter to `state: OPEN` only — a fix PR
  that has just transitioned to `MERGED`/`CLOSED` is itself a signal the
  monitor must report (see below), not something to silently skip before
  ever checking.
- Emits one line per **newly** `CONFLICTING`/`DIRTY` fix PR found (track
  which repos have already been flagged/dispatched in a small local state
  file so a still-conflicting PR doesn't re-emit every poll once its
  conflict-fixer is already in flight or has already resolved it once).
- Emits one line per fix PR that has **newly** reached a terminal GitHub
  state (`MERGED` or `CLOSED`) since the previous poll — track a separate
  small local "already-reported-terminal" state file (distinct from the
  conflict-flagged one) so this only fires once per PR. Once a fix PR is
  confirmed terminal, drop it from the conflict-tracking flagged set (it can
  no longer go stale) and from the set of PRs polled on subsequent loops —
  no further `gh pr view` calls are needed for it.
- Re-scans today's `records/ledger-YYYY-MM-DD.tsv` `fixed` rows on each
  poll (not just a fixed snapshot taken at monitor-start time) so fix PRs
  opened later in the sweep are picked up automatically without
  restarting the monitor.
- Once every fix PR the ledger currently knows about for this sweep has
  reached a terminal state (i.e. a poll finds zero remaining `OPEN` fix
  PRs), emit a single summary line (e.g. `ALL FIX PRS TERMINAL: N merged,
  M closed — sweep fully resolved`) — this is the trigger for automatic
  close-out below.

## On a detected conflict

Dispatch a `conflict-fixer` sub-agent (`.claude/agents/conflict-fixer.md`)
as a sibling, passing just the repo and fix PR number — same
same-repo-serialization and `--concurrency` pool discipline as the main
Investigator/Arbiter/Executor queue in `architecture.md` (do not dispatch
two conflict-fixers, or a conflict-fixer and an Investigator/Executor,
against the same repo simultaneously; queue if the pool is full). Track this
queue the same way as the main `## Queue` section in `STATE.md` — a small
`## Conflict-fixer queue` section (`in-flight`/`pending`/`done this
sweep`) works the same way and should be rewritten on every dispatch/
completion, for the same resume-after-interruption reason as the main
queue.

On a conflict-fixer's terminal report:

- `fixed` → confirm `mergeable: MERGEABLE` on the fix PR now, note it in the
  original Renovate PR's `STATE.md` subsection (append, don't overwrite),
  free the slot, refill.
- `already-clean` → GitHub's mergeability computation was stale/lagging, not
  a real conflict; free the slot, refill, no further action needed.
- `NEEDS_ARBITER` → a genuine content conflict (not just a dependency-version
  drift) that needs a judgment call on which side wins; dispatch an Arbiter
  sibling same as the main queue's escalation handling.
- `blocked` → record it in `records/`, move on; a human will need to rebase
  that fix PR manually.

## On a detected merge or close

When the monitor reports a fix PR newly reached `MERGED` or `CLOSED`:

- This is routine, expected information, not an error or a conflict — most
  fix PRs are *supposed* to eventually merge (whether by the user or by
  Renovate/branch-protection automation). Do not treat a `MERGED` or
  `CLOSED` event itself as something requiring a fix.
- Independently confirm via `gh pr view <fix-pr-number> -R <owner/repo>
  --json state` before recording anything (same "never trust the monitor's
  word alone" discipline as a `CONFLICT DETECTED` event) — the monitor is a
  detector, not a source of truth.
- Append a short one-line note to the relevant `STATE.md` per-PR subsection
  (append, don't overwrite) recording the terminal GitHub state and
  timestamp, so a later `--resume` or `/renovate-status` doesn't need to
  re-query GitHub to know this PR is done. If the PR was `CLOSED` (not
  merged) and it isn't already recorded as an intentional close (e.g. a
  conflict-fixer's own `closed-redundant` finding, or a user-directed
  RESET), flag it as worth asking the user about — an unexpected close is
  the one case here that *does* warrant a question, since it could mean the
  user rejected the fix for a reason not yet captured in `STATE.md`.
- No slot/queue bookkeeping is needed for this beyond the STATE.md note
  itself — a fix PR reaching `MERGED`/`CLOSED` was not occupying a
  conflict-fixer slot (slots track *conflict-fixer sub-agents*, not fix PRs
  in general) unless a conflict-fixer happened to be actively working it at
  the same moment, which the terminal-state check in "Setting up the
  monitor" above already accounts for by dropping it from future polls.

## Closing out

Same as the main queue: once the `## Conflict-fixer queue` section is fully
drained (no more `CONFLICTING` fix PRs found on a poll, nothing in-flight)
**and** the monitor's `ALL FIX PRS TERMINAL` summary line has fired (every
fix PR this sweep opened has reached `MERGED`/`CLOSED`), the sweep is
provably done — stop the `Monitor` (it doesn't need a separate cancel call
the way `CronCreate` does — letting the sweep's own close-out end the
session-scoped monitor is sufficient, but call `TaskStop` on it explicitly
if it was started with `persistent: true`, to avoid leaving a dangling
watch). Do not fall back to manually re-`gh pr view`-ing every ledger row by
hand to confirm this — that was only ever needed before the monitor tracked
merge/close events itself; trust the monitor's terminal-state tracking (with
the usual one-off independent spot-check if something looks inconsistent),
same as the conflict-detection side. This monitoring is best-effort and
session-scoped, same caveat as Liveness Monitoring above — it is not a
durability guarantee, and a `--resume`d sweep should re-arm it fresh rather
than assume it's still running from a previous session.
