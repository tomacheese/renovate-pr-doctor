# Resuming (--resume)

Read `STATE.md`'s `## Queue` section first. If it has `pending` and/or
`in-flight` entries left over from an interrupted sweep (session ended,
or the liveness cron's own 7-day/session-only cap expired before the
sub-agents finished — see `operational-caveats.md`'s caveat that
`CronCreate` is **not** a durability guarantee):

- For each `in-flight` entry, check its PR's `STATE.md` per-PR checkpoint:
  - `escalated` waiting on an Arbiter that never got dispatched → dispatch
    the Arbiter now.
  - `arbiter-proceed` with no Executor yet → dispatch the Executor now.
  - Any other non-terminal checkpoint with no corresponding live sub-agent
    → treat as `liveness-monitoring.md`'s "genuinely dead" case: re-dispatch a fresh
    Investigator, instructing it to first check whether a fix PR already
    exists before opening a new one.
  - Already terminal (the report arrived but the queue bookkeeping wasn't
    updated before the interruption) → just free the slot and refill, per
    step 4.
- Then resume the step-4 refill loop with whatever's left in `pending`,
  refilling up to `--concurrency` (which may be re-specified on `--resume`
  if you want to change the pool size for the rest of the sweep).

If `## Queue` is empty/absent (no interrupted sweep), `--resume` has
nothing to do for the main queue — say so; that's what `/renovate-status`
is for if the user just wants a look.

**Also check `STATE.md`'s `## Conflict-fixer queue` section independently**
of the main `## Queue` — the two are unrelated to whether the other has
interrupted work, since fix PRs can keep going stale long after the main
sweep itself finished (see `fix-pr-conflict-monitoring.md`). A
prior session's persistent `Monitor` does **not** survive across sessions
(same caveat as the liveness cron) — never assume one is still polling.
On `--resume`, regardless of whether the main `## Queue` had anything
pending:

- Re-arm a fresh conflict `Monitor` if `records/ledger*.tsv` (all
  per-run-date files, plus any legacy pre-rotation `records/ledger.tsv`)
  has any `fixed` rows with a non-empty `fix_pr_url` still `state: OPEN` on
  GitHub — the monitor's own polling loop will discover current
  `mergeable`/`mergeStateStatus` for all of them on its first pass, so you
  do not need to replay history to reconstruct which ones were already
  flagged; the monitor's dedup state file starts empty and simply re-emits
  any that are currently `CONFLICTING`. The freshly re-armed monitor also
  starts tracking merge/close terminal-state for every ledger `fixed` row
  regardless of current `state` (not just the still-`OPEN` ones) — this
  correctly reports `ALL FIX PRS TERMINAL` immediately if everything
  actually finished while the monitor wasn't running, instead of silently
  assuming so.
- If `## Conflict-fixer queue` has `in-flight`/`pending` entries left over
  from an interrupted sweep, reconcile the same way as the main queue:
  check each in-flight fix PR's actual `mergeable` state directly (it may
  have resolved, or gone stale again, since the interruption) rather than
  trusting the stale section content — then fold any still-conflicting
  ones into `pending` and resume dispatching `conflict-fixer` siblings per
  `fix-pr-conflict-monitoring.md`'s "On a detected conflict"
  subsection.
