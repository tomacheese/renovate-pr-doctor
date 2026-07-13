# Architecture

## Target definition

A target PR is: open, authored by `app/renovate`, whose latest commit's CI
check conclusion is `FAILURE`/`ERROR`. Merge conflicts, PRs blocked on
review/approval, PRs with pending/neutral checks, and dependencyDashboard
labels are explicitly out of scope.

**No push access to the target repo**: fork the repo and open the fix PR
from the fork against the upstream default branch, rather than reporting
`blocked`. `blocked` for this specific reason is reserved for cases where
forking/pushing to the fork also fails (a distinct environmental problem).

## Repository Layout

This repository persists scripts and history permanently (it is a real git repo, not a scratch directory).

```
broken-renovate-prs/
├── CLAUDE.md
├── README.md
├── STATE.md
├── .claude/
│   ├── agents/
│   │   ├── investigator.md
│   │   ├── arbiter.md
│   │   ├── executor.md
│   │   └── conflict-fixer.md
│   └── skills/
│       ├── renovate-maintain/
│       │   ├── SKILL.md
│       │   └── reference/
│       │       ├── architecture.md
│       │       ├── escalation.md
│       │       ├── liveness-monitoring.md
│       │       ├── fix-pr-conflict-monitoring.md
│       │       ├── dependency-currency.md
│       │       ├── resuming.md
│       │       └── operational-caveats.md
│       └── renovate-status/
│           └── SKILL.md
├── scripts/
├── records/
└── scratchpad/                                        # git-ignored
```

## Orchestrator / Sub-agent Architecture

The parent (orchestrator) session does deterministic work and state
bookkeeping only. It does **not** perform deep investigation itself, to avoid
polluting its own context.

**Orchestrator responsibilities:**

1. Run `scripts/find-broken-prs.sh` directly to get the target list.
2. Build the full queue in `STATE.md`'s `## Queue` section (all pending, no
   in-flight yet), then fill up to `--concurrency` slots: dispatch one
   Investigator sub-agent per PR taken off the front of the queue
   (`subagent_type: investigator`, background mode), skipping any queued PR
   whose repo already has another sub-agent in flight (same-repo
   serialization — never two sub-agents racing to push competing branches
   into the same repo). Send all of a fill's `Agent` calls in a single
   message so they actually run concurrently.
3. As each in-flight sub-agent completes, refill its freed slot from the
   front of the remaining queue, respecting the same same-repo
   serialization rule, until the queue is empty and no slots remain
   in-flight.
4. On each sub-agent completion notification, confirm its `STATE.md`/`records`
   section and commit are present and consistent, and fold the run-level
   summary line into `records/YYYY-MM-DD-run.md`.
5. Trust only the sub-agent's **structured report**, not its raw
   investigation transcript/diff — spot-check individually only if something
   looks wrong.
6. While any sub-agent is in flight, maintain the liveness-monitoring cron job
   (start it once dispatch begins, cancel it once the run completes) — see
   `liveness-monitoring.md`.

**Per-PR sub-agent responsibilities** (one sub-agent per Renovate PR):

- Receives only `owner/repo` + the Renovate PR number as input.
- Clones the target repo itself into
  `scratchpad/renovate-fix-<repo>-<pr>` (the tracking repo's own
  `isolation: worktree` feature does not apply to external target repos, so
  the sub-agent must clone manually).
- Investigates the CI failure logs and determines the root cause.
- **Owns its own intermediate checkpoints**: as it reaches each of
  investigation-started / root-cause-identified / escalated / fix-pr-opened /
  completed / skipped / blocked, it writes/updates **its own PR-specific section**
  in `STATE.md` and, once known, its own row in
  `records/YYYY-MM-DD-run.md`, then commits. Each sub-agent only ever touches
  its own section/row (never another PR's), so parallel sub-agents don't
  conflict on the same file. This makes intermediate progress durable across
  auto-compact even if the orchestrator itself hasn't yet processed a
  completion notification.
- **Never commits to the Renovate PR's branch.** Creates a new branch off the
  default branch, implements the fix, pushes via SSH, and opens a separate PR.
  Opening this fix PR (not merging it) is pre-authorized — the sub-agent does
  not need to check with the user before opening it, PR by PR. Merging
  remains excluded under all circumstances and always requires explicit user
  instruction.
- Returns a compact structured report to the orchestrator:
  ```
  repo, renovate_pr_url, root_cause (1-2 sentences), fix_branch, fix_pr_url,
  status (fixed / skipped / blocked)
  ```
  - `fixed`: a fix PR was opened.
  - `skipped`: a judgment call (Investigator or Arbiter) concluded there is no
    safe action to take right now; the reason is recorded as free text.
  - `blocked`: not a judgment call — an environmental obstacle prevented any
    attempt (e.g. repo archived, no push access, required secret unavailable,
    CI infrastructure itself down). Surfaced separately from `skipped` in the
    end-of-run summary because it is often quick for a human to unblock,
    whereas `skipped` needs re-evaluation of the fix approach itself.

**Parallel-execution independence**: each sub-agent works in its own repo and
its own clone directory, so parallel runs across different repos do not
conflict. Multiple failing PRs in the *same* repo are serialized (never
dispatched concurrently) — see `CLAUDE.md`'s "Same-repo serialization" fact.
