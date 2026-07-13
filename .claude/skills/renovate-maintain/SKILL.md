---
name: renovate-maintain
description: Runs the Renovate PR maintenance workflow to completion in one invocation — discovers candidates, classifies known-signature PRs against the ledger, then drives a continuously-refilled N-concurrent queue of Investigator/Arbiter/Executor sub-agents until every candidate reaches a terminal state. See .claude/skills/renovate-maintain/reference/ for full operational detail. Invoke with /renovate-maintain.
argument-hint: "[--concurrency N] [--repo owner/repo] [--assignee login] [--resume]"
disable-model-invocation: true
---

# Renovate PR Maintenance

See `.claude/skills/renovate-maintain/reference/` for full operational
detail (architecture, escalation, liveness monitoring, fix-PR conflict
monitoring, dependency currency) — this file only covers the skill's own
operational procedure (arguments, ledger use, the queue loop).
Agent role files: `.claude/agents/investigator.md`, `.claude/agents/arbiter.md`,
`.claude/agents/executor.md`.

**Working directory**: this repository's root (wherever it is checked out).
All state below is relative to it.

**This skill drives itself to completion.** One invocation is meant to
process the entire candidate backlog it finds (or resumes), not just one
batch. Do not stop and hand control back to the user between dispatches —
keep dispatching from the queue every time a slot frees up, for as many
turns as it takes, until the queue is empty and every in-flight sub-agent
(including anything it escalated to) has reached a terminal checkpoint.
The only reasons to stop early: the user interrupts, or a genuine
system-level failure (e.g. `gh` auth broken) blocks all further progress —
not "this is taking a while."

## Arguments

- `--concurrency N` — how many Investigator-or-later sub-agents may be in
  flight at once, **steady-state**. **Default: 5.** Unlike a per-invocation
  cap, this is a pool size: the moment any slot's occupant reaches a
  terminal state, the next queued candidate is dispatched into that slot
  immediately — no waiting for the whole batch to finish. The queue itself
  has no size limit; it's however many real candidates discovery (minus
  ledger-classified bulk skips) produces.
- `--repo owner/repo` — restrict discovery to one repo (for a targeted
  re-run). Omit to scan all orgs in `$RENOVATE_MAINTAIN_ORGS` (default:
  `book000`/`tomacheese`/`jaoafa` — see `scripts/find-broken-prs.sh`).
- `--assignee login` — restrict discovery to Renovate PRs whose GitHub
  assignee is `login`. **Default: `$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE`**
  (falls back to `book000` if unset) — omitting this flag does NOT mean "no
  filter," it means the same thing as passing that default explicitly. Pass
  `--assignee ""` (empty string) explicitly to disable the assignee filter
  and scan every Renovate PR regardless of assignee. Independent of, and
  combinable with, `--repo`. Passed straight through to
  `scripts/find-broken-prs.sh --assignee`.
- `--resume` — skip discovery and rebuild the queue from `STATE.md`'s `##
  Queue` section and any non-terminal per-PR checkpoints left by an
  interrupted previous invocation (see "Resuming" below), instead of
  starting a fresh discovery pass.

## STATE.md `## Queue` section (new — required for this skill's own bookkeeping)

The per-PR `### owner/repo#pr-number` subsections already track individual
PR progress. Driving a whole-backlog sweep in one invocation additionally
needs a durable record of *queue* state — which candidates haven't been
dispatched yet, and which slot each in-flight sub-agent currently occupies
— so the sweep can resume correctly if the session is interrupted mid-run
(conversation memory is not trusted; see `CLAUDE.md`'s STATE.md-discipline
note). Maintain this section in `STATE.md`, rewritten every time
the queue changes (a dispatch, a completion, a slot refill):

```markdown
## Queue
concurrency: 5
in-flight:
  - slot: investigator-owner-repo-123
    target: owner/repo#123
pending (not yet dispatched, in order):
  - owner/repo2#456
  - owner/repo3#789
done this sweep: 12 (fixed=5 skipped=6 blocked=1)
```

Update it in the same commit as any per-PR `STATE.md` subsection change
that moves a slot (dispatch, terminal completion, escalation handoff) — it
is cheap (one small section) and is what makes `--resume` reconstruct the
sweep instead of restarting it from scratch.

## Procedure

Every Investigator dispatched below automatically runs a dependency
currency check as its own Step 0 (see
`.claude/skills/renovate-maintain/reference/dependency-currency.md`
and `.claude/agents/investigator.md`) — this needs no extra step here,
except handling the new `escalate-to-user` Arbiter verdict in the refill
loop (step 4 below).

### 1. Discover (skip if `--resume`)

```bash
scripts/find-broken-prs.sh > /tmp/renovate-broken-prs.tsv                             # default: all 3 orgs
scripts/find-broken-prs.sh --repo owner/repo > /tmp/renovate-broken-prs.tsv            # --repo passed through
scripts/find-broken-prs.sh --assignee login > /tmp/renovate-broken-prs.tsv             # --assignee passed through
scripts/find-broken-prs.sh --repo owner/repo --assignee login > /tmp/renovate-broken-prs.tsv  # combinable
```

See `reference/architecture.md`'s "Target definition" for exactly what counts (open,
`app/renovate`-authored, latest-commit CI conclusion `FAILURE`/`ERROR`).

### 2. Classify against the ledger before queuing anything

`records/ledger.tsv` (columns: `date  repo  pr_number  renovate_pr_url
root_cause_signature  status  fix_pr_url`) is the durable, machine-readable
memory of every PR this workflow has ever touched, across all runs — do not
re-derive this from parsing `records/*.md` prose tables.

For each candidate PR from discovery:

- **Already in the ledger for this exact repo+PR number** → drop it, don't
  queue (already handled in a prior run; `/renovate-status` is where you'd
  check whether it since went green/merged, not this skill).
- **Not yet in the ledger, but its failing-check names/signature exactly
  match an existing `root_cause_signature` that is still `skipped`-for-a-
  systemic reason** (e.g. `ts7-typescript-eslint-load-crash` — an
  ecosystem-wide incompatibility, not a per-repo bug) → classify it
  `skipped` automatically, with the same root-cause text, **without
  queuing an Investigator at all**. Append a ledger row and a
  `records/YYYY-MM-DD-run.md` row directly. This is the "bulk
  pre-classification" scale lever — intentionally fully automatic (no
  per-batch confirmation gate), since the underlying signature was already
  independently verified by a real Investigator when first discovered. If
  you are ever unsure whether a new PR's failure truly matches an existing
  signature (not just a superficially similar check name), do NOT bulk-skip
  it — queue a real Investigator instead. When in doubt, investigate.
- **Everything else** (new signature, or a `fixed`/`escalated` signature
  that needs real per-PR judgment) → goes into the queue.

### 3. Build the queue and fill the pool

Order the queue however you like (repo diversity first mirrors the pilot's
selection rule, but it doesn't matter much since the whole queue will
eventually be drained). Write it to `STATE.md`'s `## Queue` section (all
pending, no in-flight yet), commit.

Then fill up to `--concurrency` slots: dispatch one Investigator sub-agent
per PR taken off the front of the queue (`subagent_type: investigator`),
background mode, per its own file's input contract (repo, PR number, URL,
failing check names — nothing else) — **except** skip over any queued PR
whose repo already has another sub-agent in flight (same-repo
serialization: never two Investigators racing to push competing fix
branches into the same repo). Send all of a fill's `Agent` calls in a
single message so they actually run concurrently. Move each dispatched PR
from `pending` to `in-flight` in `STATE.md`, commit.

Start the liveness-monitoring cron (see `reference/liveness-monitoring.md`)
the moment the first sub-agent is dispatched, if one isn't already running.
Given a full-backlog sweep runs far longer than a small pilot batch, expect
this cron to matter more here — but it is still best-effort only (see
"Operational caveats").

Start the fix-PR conflict monitor (see `reference/fix-pr-conflict-monitoring.md`)
as soon as the first fix PR is opened (the first `fixed` ledger
row with a real `fix_pr_url` this sweep) — a persistent `Monitor` polling
every fix PR opened so far both for `mergeable`/`mergeStateStatus` drift
*and* for reaching a terminal GitHub state (`MERGED`/`CLOSED`), if one isn't
already running. This is a separate mechanism from the liveness cron above:
it catches fix PRs that go stale *after* their own sub-agent already
finished successfully, because other unrelated PRs kept merging into the
default branch throughout the sweep — and it also tracks each fix PR through
to merge/close so the sweep's true end state is known without a manual
re-check. On a detected conflict, dispatch a `conflict-fixer` sub-agent
(`subagent_type: conflict-fixer`) per `reference/fix-pr-conflict-monitoring.md`'s procedure — same
`--concurrency` pool/same-repo-serialization discipline, tracked in its own
`## Conflict-fixer queue` STATE.md section. On a detected merge/close,
independently confirm via `gh pr view --json state` and append a one-line
note to the PR's `STATE.md` subsection per `reference/fix-pr-conflict-monitoring.md`'s
"On a detected merge or close" — no slot bookkeeping needed; flag an *unexpected* close
(not already explained by a conflict-fixer `closed-redundant` finding or a
user RESET) to the user rather than silently recording it.

### 4. The refill loop — this is the core of the skill

On every `SendMessage` report you receive (from any Investigator, Arbiter,
or Executor), in order:

1. **Escalation handling** (does not free the slot yet — the case is still
   in flight, just handed to a different sub-agent):
   - `NEEDS_ARBITER` → dispatch a fresh Arbiter sibling (`subagent_type:
     arbiter`) with the Investigator's findings and options.
   - Arbiter `proceed` → dispatch a fresh Executor sibling (`subagent_type:
     executor`) with the chosen option.
   - Arbiter `escalate-to-user` (dependency-currency major-version gap
     only — see `.claude/skills/renovate-maintain/reference/dependency-
     currency.md`) → do not dispatch another sub-agent yet. Relay
     the Arbiter's findings and trade-offs to the user via
     `AskUserQuestion` (proceed with the major-version bump, or skip it for
     now). This still does not free the slot. Once the user answers:
     "proceed" → dispatch a fresh Executor sibling with the major-version
     bump as its chosen option, same as an Arbiter `proceed` would; "skip"/
     decline → treat as terminal `skipped` per step 2 below, with `detail`
     noting it was the user's explicit decision on the major-version gap
     specifically (the underlying CI fix, if the Investigator already
     opened one via `fix-pr-opened-plus-escalated`, is unaffected either
     way — it already exists and its own ledger row, if any, already
     reflects the CI-fix outcome, not this separate currency decision).
2. **Terminal handling** (frees the slot):
   - Arbiter `skip`, or any terminal `fixed`/`skipped`/`blocked` report →
     confirm the sub-agent's own `STATE.md` subsection/`records` row are
     present and consistent, then append a ledger row (`root_cause_signature`
     is a short kebab-case slug you assign from the reported root cause —
     reuse an existing slug verbatim if this is the same underlying cause
     as a prior entry, so later PRs in *this same sweep* can also
     bulk-skip against it, not just future runs). Remove the slot from
     `in-flight` in `STATE.md`, **and delete that PR's own `###
     owner/repo#pr-number` subsection from `STATE.md`'s `## Targets and
     their state` entirely** — the ledger row and `records/` row just
     written are now the durable record, so keeping a second copy in
     `STATE.md` (a file read at the start of every turn) only adds dead
     weight. `## Targets and their state` should only ever contain
     subsections for PRs that are still non-terminal.
3. **Immediately refill the freed slot** (same turn, no waiting): take the
   next queued PR whose repo has no other sub-agent currently in flight
   (walk further into the queue if the front item's repo is busy — don't
   just stall the slot). Dispatch it, move it from `pending` to
   `in-flight`. If the entire remaining queue is same-repo-blocked (every
   pending PR's repo already has something in flight), leave the slot idle
   for now — it will be tried again on the next completion.
4. Commit the `STATE.md` queue-state change alongside whatever per-PR
   commit the completion/dispatch already required — don't add an extra
   round-trip just for the queue bookkeeping.

Trust the structured `SendMessage` report; do not re-derive status by
re-reading the sub-agent's full transcript unless something looks
inconsistent with its own STATE.md/records write.

Keep looping step 4 — receive report, handle, refill — for as long as
`in-flight` is non-empty or `pending` is non-empty. This is what makes one
`/renovate-maintain` invocation sweep the whole backlog: you are not
waiting for the user between fills, and you are not stopping until both
lists are empty.

### 5. Close out the sweep

Once the main `in-flight` and `pending` are both empty, **the sweep's fix
PRs can still go stale afterward** (see `reference/fix-pr-conflict-monitoring.md`)
— so close-out has two parts:

- Extend `records/YYYY-MM-DD-run.md`'s `## Summary` section covering
  everything processed this sweep (root-cause clustering, any follow-up
  recommendations — e.g. a new systemic signature worth pre-filtering next
  time).
- Clear `STATE.md`'s main `## Queue` section back to empty and cancel the
  liveness cron via `CronDelete`.
- Compress `STATE.md`'s `## Phase` section: once this sweep's summary is
  written to `records/YYYY-MM-DD-run.md` (the bullet above), replace any
  multi-paragraph narrative about this now-completed sweep with one or two
  lines pointing at that `records/` file (e.g. "Last completed sweep:
  YYYY-MM-DD, see `records/YYYY-MM-DD-run.md`. Currently idle."). `## Phase`
  should describe the *current* state in a few lines, not accumulate a
  history of every past sweep — that history already lives in `records/`.
- Report to the user: total counts by status (`fixed` / `skipped` /
  `blocked` / still-`escalated`-pending-human-review, if any) across the
  whole sweep, and confirm the queue is fully drained (0 pending, 0
  in-flight) — or, if you stopped early for a genuine blocking reason,
  say exactly what's left in the queue and why you stopped.
- **Do not stop the fix-PR conflict monitor just because the main queue
  drained.** Keep it (and its `## Conflict-fixer queue` section) running
  until it, too, has 0 pending/in-flight *and* it reports its
  `ALL FIX PRS TERMINAL` summary line (every fix PR this sweep opened has
  reached `MERGED`/`CLOSED`) — since other Renovate PRs can keep merging
  into default branches well after this sweep's own Investigators/Executors
  are done, and a fix PR going stale is a genuine problem regardless of
  whether the main sweep is still "in progress." Trust that summary line
  (with the usual one-off independent spot-check if anything looks
  inconsistent) rather than manually re-`gh pr view`-ing every ledger row —
  the monitor now tracks merge/close itself specifically so this close-out
  step doesn't need a manual sweep. Only once both queues are empty *and*
  every fix PR is confirmed terminal is the sweep truly closed; only then
  call `TaskStop` on the conflict `Monitor` if it's still running
  persistently.

## Resuming (`--resume`)

See `reference/resuming.md` for the full reconciliation procedure (per-PR
checkpoint handling, conflict-fixer queue re-arming).

## Operational caveats

See `reference/operational-caveats.md` for cron/monitor durability limits,
`gh` rate-limit handling, and cost/concurrency guidance.
