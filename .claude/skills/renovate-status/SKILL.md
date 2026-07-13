---
name: renovate-status
description: Read-only status report on the Renovate PR maintenance workflow — in-flight sub-agents, ledger summary, undispatched backlog size. Never dispatches sub-agents or changes state. Invoke with /renovate-status.
argument-hint: "[--repo owner/repo]"
disable-model-invocation: true
---

# Renovate Maintenance Status

Read-only companion to `/renovate-maintain`. **Never dispatches a sub-agent,
never writes to `STATE.md`/`records/`/`ledger.tsv`, never runs `find-broken-
prs.sh`.** If you find yourself wanting to act on something this report
surfaces (retry a dead sub-agent, dispatch an Arbiter for a stuck
escalation), that's `/renovate-maintain --resume`'s job — stop and tell the
user to run that instead.

**Working directory**: this repository's root (wherever it is checked out).

## What to report

1. **In-flight sub-agents**: any Investigator/Arbiter/Executor currently
   running (check active agent list). For each, cross-reference `STATE.md`'s
   checkpoint for that PR — flag any that look stale per
   `.claude/skills/renovate-maintain/reference/liveness-monitoring.md`'s
   staleness check (`git log -1` on its
   `scratchpad/renovate-fix-<repo>-<pr>` clone/branch, compared to when its
   `STATE.md` checkpoint last changed) but do **not** probe or redispatch it
   yourself — just note it as "looks stale, consider `/renovate-maintain
   --resume`".
2. **STATE.md summary**: current `## Phase`, and a one-line-per-PR list of
   `## Targets and their state` checkpoints, split into terminal
   (`completed`/`skipped`/`blocked`) vs. non-terminal.
3. **Ledger summary** (`records/ledger.tsv`): counts by `status`, and the
   distinct `root_cause_signature` values seen so far with their counts —
   this is the same view `/renovate-maintain` uses to decide what can be
   bulk-skipped next run, so it doubles as a preview of that.
4. **Undispatched backlog**: if `--repo` is given, or if a recent discovery
   TSV exists (e.g. `/tmp/renovate-broken-prs.tsv`), report how many
   candidate PRs are neither in the ledger nor currently in flight — i.e.
   what a `/renovate-maintain` run would have to choose from. Do not re-run
   discovery yourself to produce this if a recent-enough TSV already exists
   (say how old it is); only mention that a fresh discovery pass would give
   an up-to-date count.

## Output format

A short structured summary, not a full dump of `STATE.md`/ledger contents:

```
Phase: <STATE.md's ## Phase, one line>

In flight (N):
  - owner/repo#123 (investigator-xyz) — checkpoint: fix-pr-opened [stale? y/n]
  ...

Terminal this run (N): fixed=<n> skipped=<n> blocked=<n>

Ledger totals (all runs): fixed=<n> skipped=<n> blocked=<n> pending=<n>
Known signatures: <slug> (<n> PRs, last: skipped) ...

Backlog: <n> undispatched candidates known from <TSV path, age>
  (re-run discovery for a fresh count)
```

If nothing is in flight and the ledger is empty, say so plainly — don't
pad the report.
