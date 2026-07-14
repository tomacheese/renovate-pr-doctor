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
    checks: build,lint
pending (not yet dispatched, in order):
  - owner/repo2#456 [checks: test]
  - owner/repo3#789 [checks: build]
done this sweep: 12 (fixed=5 skipped=6 blocked=1)
```

`checks` is the comma-joined failing check names discovery already reported
for that PR (column 4 of `scripts/find-broken-prs.sh`'s output) — carried
through the queue so it's available, without any extra `gh` call, both when
the completing sub-agent's ledger row gets written (Step 4, step 2) and if
the same PR needs to be recompared for staleness on a future sweep (Step 2).
For a candidate re-queued by Step 2's staleness recheck (see below), also
note `recheck-of: <prior status>/<prior root_cause_signature>` next to it so
the dispatched Investigator gets that context for free instead of starting
from zero.

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

### 0. Pre-work cleanup (always runs, `--resume` included)

Before Discover/Resume, clean up state left over from previous sweeps —
this runs every invocation regardless of `--resume`, since everything it
touches is already confirmed terminal and therefore cannot affect
`--resume`'s own non-terminal reconciliation (see `reference/resuming.md`).
`/renovate-status` never runs this step (it stays read-only).

1. **Stale `STATE.md` per-PR subsections**: for each `### owner/repo#pr-
   number` subsection under `## Targets and their state`, check whether a
   matching row (same repo + PR number) already exists in
   `records/ledger*.tsv` (glob covers both the current per-run-date files
   and any pre-rotation legacy `records/ledger.tsv` — see Step 2 below).
   If a matching row exists, the PR is already terminal and this
   subsection is dead weight left over from a session that ended before
   the refill loop's own Terminal handling (`### 4`, step 2) could delete
   it — delete the subsection now. Leave subsections with no matching
   ledger row untouched (still non-terminal, needed by `--resume`).
2. **Stale `## Phase` narrative**: if `## Queue` is already empty (no
   `pending`, no `in-flight`) but `## Phase` still holds multi-paragraph
   narrative about a finished sweep (i.e. Step 5's close-out compression
   never ran, most likely because the session ended before reaching it),
   compress it now using the same rule as Step 5: replace it with "Last
   completed sweep: YYYY-MM-DD, see `records/YYYY-MM-DD-run.md`. Currently
   idle." This is a safety net for Step 5, not a replacement for it — Step
   5 still runs normally at the end of a sweep that completes cleanly.
3. **Stale `scratchpad/renovate-fix-<repo>-<pr>` clones**: for each
   directory matching `scratchpad/renovate-fix-*`, recover `repo`/`pr`
   from the directory name and check `records/ledger*.tsv` for a matching
   terminal row (`fixed`/`skipped`/`blocked`, regardless of whether a
   `fixed` row's own fix PR has itself reached `MERGED`/`CLOSED` on
   GitHub — this check only looks at the ledger's own status column, not
   live GitHub state). If found, delete the clone directory
   (`rm -rf scratchpad/renovate-fix-<repo>-<pr>`). If a conflict-fixer
   later needs to work a `fixed` PR whose fix PR went stale, it clones
   fresh — see `.claude/agents/conflict-fixer.md`. Clones with no matching
   ledger row are left alone (still in progress).

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

`records/ledger-YYYY-MM-DD.tsv` — one file per sweep run-date, same
`date  repo  pr_number  renovate_pr_url  root_cause_signature  status
fix_pr_url  failing_checks` columns as before, plus one new 8th column
(`failing_checks` — comma-joined failing check names known at the time this
row was written, from discovery's own output; see "Staleness recheck"
below) — is the durable, machine-readable memory of every PR this workflow
has ever touched, across all runs. Rows written before this column existed
simply have it blank; treat a blank `failing_checks` on an old row as
"unknown," never as "matches" (see below). Today's sweep appends only to
today's own `records/ledger-YYYY-MM-DD.tsv` (created fresh if this is the
first sweep run today); never to a previous day's file. Query across all of
history with a glob, `records/ledger*.tsv` (the unhyphenated pattern also
matches any pre-rotation legacy `records/ledger.tsv` still on disk from
before this rotation existed) — always via `grep`/`awk` targeted queries,
never by loading every file's full contents with the `Read` tool. Do not
re-derive this from parsing `records/*.md` prose tables.

For each candidate PR from discovery:

- **Already in the ledger for this exact repo+PR number** (`awk -F'\t' -v
  r="$repo" -v p="$pr" '$2==r && $3==p' records/ledger*.tsv` — if more than
  one row matches, e.g. because it was re-queued and re-classified across
  separate days, use only the most recent one, i.e. the last matching
  line) → **do not drop it unconditionally.** A ledger row only means "a
  human/sub-agent understood this PR's failure once" — not that the
  understanding, or the PR's current failure, is still the same today. Run
  the cheap staleness check below (`scripts/lib/ledger-staleness.sh`,
  function `classify_ledger_match`) before deciding:

  ```bash
  source scripts/lib/ledger-staleness.sh
  classify_ledger_match "$row_date" "$row_status" "$row_checks" "$current_checks" "$today"
  ```

  where `row_date`/`row_status`/`row_checks` are that matched row's columns
  1/6/8, `current_checks` is this candidate's failing check names from
  today's discovery output (already fetched — zero extra `gh` calls), and
  `today` is today's date. It returns `drop` (same fast path as before —
  don't queue) or `recheck:<reason>` (queue it like any new candidate,
  tagging the queue entry `recheck-of: <row_status>/<root_cause_signature>`
  from the matched row so the dispatched Investigator has that context for
  free). The decision, and why:
  - Same-day row → always `drop`: it was already looked at earlier this
    same sweep/run-date: no benefit to re-checking again within the day.
  - `fixed` row whose PR still shows up in discovery at all (still open,
    still CI-failing) → **always** `recheck`, regardless of whether the
    current failing check names match the row's. A fix that actually held
    should have left the PR green or closed; recurrence under the *same*
    check name can mean "the dependency moved further and outpaced the
    fix" (confirmed today: `book000/github-changelog-translator#1647`) just
    as easily as under a *different* check name — check-name comparison
    can't tell those apart, so don't rely on it for `fixed` rows
    specifically.
  - Row has no recorded `failing_checks` (pre-migration) → `recheck`: no
    baseline to compare against, so treat as unknown rather than assuming a
    match. Self-healing — the row this sweep writes back carries the
    column, restoring the fast path for that PR from the next sweep on.
  - Current failing check names differ from the row's recorded ones →
    `recheck`: this is probably a different failure than what's recorded,
    not a recurrence of the understood one (confirmed today:
    `tomacheese/collect-points#670`, ledgered `skipped` for an
    eslint-config/unicorn signature, now failing on an unrelated `prettier`
    reformat instead).
  - Otherwise (same check names, `blocked`/`skipped` status) → `drop`
    unless the row has aged past `$RENOVATE_MAINTAIN_LEDGER_STALE_DAYS`
    (default 3), in which case `recheck` anyway. This exists because a
    `blocked`/`skipped` verdict's own *reasoning* can be wrong in a way no
    check-name comparison ever surfaces — e.g. a judgment call that a gate
    is "transient, self-resolves" when the real cause is a structural
    misconfiguration that never will (confirmed today: `book000/create-
    ts#17`). Re-deriving that reasoning text isn't possible without parsing
    `records/*.md` prose (out of bounds per this file's own rule above), so
    this is a periodic time-based backstop instead: cheap (only the row's
    own date column), and it bounds how long a wrong "it'll resolve itself"
    call can go unchallenged.

  This keeps the common case — a PR still failing for the exact
  already-understood reason — on the original fast, zero-`gh`-call path
  (most `blocked`/`skipped` recurrences hit `drop` immediately), while
  surfacing the staleness modes above for a real Investigator instead of
  silently trusting a possibly-outdated row. When `classify_ledger_match`
  itself is unsure which bucket applies (e.g. ambiguous check-name
  normalization), prefer `recheck` — same "when in doubt, investigate"
  spirit as the bulk-skip path below.
- **Not yet in the ledger, but its failing-check names/signature exactly
  match an existing `root_cause_signature` that is still `skipped`-for-a-
  systemic reason** (`awk -F'\t' '$6=="skipped" {print $5}' records/
  ledger*.tsv | sort -u` for the known-signature set; e.g.
  `ts7-typescript-eslint-load-crash` — an ecosystem-wide incompatibility,
  not a per-repo bug) → classify it `skipped` automatically, with the same
  root-cause text, **without queuing an Investigator at all**. Append a
  row to today's `records/ledger-YYYY-MM-DD.tsv` (including this
  candidate's own `failing_checks` column, from discovery) and a
  `records/YYYY-MM-DD-run.md` row directly. This is the "bulk
  pre-classification" scale lever — intentionally fully automatic (no
  per-batch confirmation gate), since the underlying signature was already
  independently verified by a real Investigator when first discovered. If
  you are ever unsure whether a new PR's failure truly matches an existing
  signature (not just a superficially similar check name), do NOT bulk-skip
  it — queue a real Investigator instead. When in doubt, investigate.
- **Everything else** (new signature; a `fixed`/`escalated` signature that
  needs real per-PR judgment; or a `recheck:<reason>` result from the
  staleness check above) → goes into the queue.

### 3. Build the queue and fill the pool

Order the queue however you like (repo diversity first mirrors the pilot's
selection rule, but it doesn't matter much since the whole queue will
eventually be drained). Carry each candidate's `checks` (its failing check
names from discovery) into its queue entry as it's written — needed later
both to write the `failing_checks` ledger column on completion (Step 4,
step 2) and, on a future sweep, to re-run this same staleness check without
an extra `gh` call. For a `recheck:<reason>` candidate, also carry
`recheck-of: <prior status>/<prior root_cause_signature>` from the matched
row. Write it to `STATE.md`'s `## Queue` section (all pending, no in-flight
yet), commit.

Then fill up to `--concurrency` slots: dispatch one Investigator sub-agent
per PR taken off the front of the queue (`subagent_type: investigator`),
background mode, per its own file's input contract (repo, PR number, URL,
failing check names — nothing else) — plus, for a `recheck-of` entry, that
prior status/root-cause text as extra context so it isn't investigating
from a cold start — **except** skip over any queued PR whose repo already
has another sub-agent in flight (same-repo
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
as soon as the first fix PR is opened (the first `fixed` row with a real
`fix_pr_url` appended to today's `records/ledger-YYYY-MM-DD.tsv` this
sweep) — a persistent `Monitor` polling
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
     present and consistent, then append a row to today's
     `records/ledger-YYYY-MM-DD.tsv` (create the file, TSV rows in the
     same column order as before, if this is the first row appended
     today) — `root_cause_signature` is a short kebab-case slug you assign
     from the reported root cause —
     reuse an existing slug verbatim if this is the same underlying cause
     as a prior entry, so later PRs in *this same sweep* can also
     bulk-skip against it, not just future runs. Set the row's 8th column,
     `failing_checks`, from this completing slot's own queue entry's
     `checks` field (the failing check names discovery reported when this
     PR was queued — not a fresh `gh` lookup) so a future sweep's Step 2 can
     run its staleness check against this row without an extra `gh` call.
     Remove the slot from
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
