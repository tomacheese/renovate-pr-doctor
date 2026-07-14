# broken-renovate-prs

Tooling and records for maintaining Renovate-authored PRs that cannot
auto-merge due to failing CI, across a configurable set of GitHub orgs/users
(default: `book000`, `tomacheese`, and `jaoafa` — this is the author's own
scope; override via `$RENOVATE_MAINTAIN_ORGS`/`$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE`,
see `scripts/find-broken-prs.sh`, to point this at your own repos).

See `.claude/skills/renovate-maintain/reference/` for full operational
detail, and `STATE.md` for the current run's status.

## Usage

- `/renovate-maintain [--concurrency N] [--repo owner/repo] [--assignee login] [--resume]` —
  runs the workflow to completion: discovery, ledger-based bulk skip
  classification, then a continuously-refilled N-concurrent (default 5)
  queue of Investigator/Arbiter/Executor sub-agents until every candidate
  is terminal. `--assignee` restricts discovery to Renovate PRs assigned to
  a specific GitHub login (combinable with `--repo`); **defaults to
  `$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE`** (falls back to `book000` if
  unset) — pass `--assignee ""` to scan regardless of assignee.
- `/renovate-status [--repo owner/repo]` — read-only report on in-flight
  sub-agents, the ledger, and the undispatched backlog. Never dispatches
  or changes state.

Agent roles used by these skills: `.claude/agents/investigator.md`,
`.claude/agents/arbiter.md`, `.claude/agents/executor.md`.

## Scripts

- `scripts/find-broken-prs.sh [--repo owner/repo] [--assignee login]` —
  enumerate open Renovate PRs across `$RENOVATE_MAINTAIN_ORGS` (or one repo)
  whose latest CI run failed. `--assignee` defaults to
  `$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE`; pass `--assignee ""` to scan
  regardless of assignee. Outputs one tab-separated line per matching PR:
  `repo<TAB>pr_number<TAB>pr_url<TAB>failing_check_names`.
- `scripts/pr-ci-detail.sh <owner/repo> <pr-number>` — print which checks are
  failing for one PR, with their detail URLs.

Run tests with:

```bash
for t in scripts/tests/test-*.sh; do bash "$t" || echo "FAILED: $t"; done
```

## Records

`STATE.md` and `records/` are local, gitignored working state — they are not
part of this published repo (they may contain private operational detail
about specific target repos and PRs).

- `STATE.md` — ephemeral, always-overwritten status of the in-progress run.
  Read at the start of every turn; must be self-contained (no reliance on
  conversation memory).
- `records/YYYY-MM-DD-run.md` — permanent record of what was done on a given
  run date.
- `records/ledger-YYYY-MM-DD.tsv` — permanent, machine-readable,
  append-only record of every PR handled on that run date (repo, PR
  number, root cause signature, status, fix PR); one file per sweep
  run-date, so no single file grows unbounded across the workflow's
  lifetime. What `/renovate-maintain` uses to avoid redispatching and to
  bulk-classify known signatures, queried across all dates with a
  `records/ledger*.tsv` glob.
