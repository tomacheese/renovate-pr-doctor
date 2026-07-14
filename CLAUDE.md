# broken-renovate-prs

Tooling and records for maintaining Renovate-authored PRs that cannot
auto-merge due to failing CI, across a configurable set of GitHub orgs/users
(default: `book000`, `tomacheese`, and `jaoafa` — override via
`$RENOVATE_MAINTAIN_ORGS`/`$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE`, see
`scripts/find-broken-prs.sh`).

## Facts

- **Working directory**: the root of this repository (wherever it is
  checked out) — never hardcode a path to it.
- **`STATE.md` and `records/` are gitignored, local-only working state** —
  not part of the published repo (they can contain private operational
  detail about specific target repos and PRs). They still exist on disk
  during a run and are read/written normally; they are just never committed.
- **`STATE.md`**: ephemeral, always-overwritten status of the in-progress
  run. Read it at the start of every turn; it must be self-contained —
  conversation memory is not trusted (auto-compact can wipe it). Do not let
  it grow unbounded — see `.claude/skills/renovate-maintain/SKILL.md`'s
  pruning rule.
- **`records/ledger-YYYY-MM-DD.tsv`**: one per sweep run-date; together
  they are the only permanent, machine-readable record of every PR ever
  handled, across all runs. Never re-derive this from parsing
  `records/*.md` prose — query the TSVs directly (`records/ledger*.tsv`, a
  glob that also covers any legacy pre-rotation `records/ledger.tsv`),
  always via targeted `grep`/`awk`, never by loading a whole file's
  contents. A ledger row is not a permanent "never look at this PR again":
  a matching row still gets a cheap staleness recheck (failing-check-name
  drift, `fixed`-but-still-failing, or age-based re-verification) before
  being dropped from a future sweep's discovery — see
  `.claude/skills/renovate-maintain/SKILL.md`'s Step 2 and
  `scripts/lib/ledger-staleness.sh`.
- **`records/YYYY-MM-DD-run.md`**: permanent, human-readable record of what
  was done on a given run date.
- **Same-repo serialization**: never run two sub-agents (Investigator,
  Arbiter, Executor, Conflict-Fixer) against the same target repo
  concurrently — they'd race to push competing branches.
- **Fix PRs are this workflow's own PRs, opened against the target repo's
  default branch** — never commit to a Renovate-authored PR's own branch.
  This is distinct from (and not a relaxation of) the global "no commits to
  Renovate-created PRs" rule.

## Commands and roles

- `/renovate-maintain [--concurrency N] [--repo owner/repo] [--assignee
  login] [--resume]` — runs the full sweep. Side-effect-heavy; only invoke
  explicitly.
- `/renovate-status [--repo owner/repo]` — read-only report; never
  dispatches or changes state.
- Sub-agents: `.claude/agents/investigator.md`, `arbiter.md`, `executor.md`,
  `conflict-fixer.md`.
- Tests: `for t in scripts/tests/test-*.sh; do bash "$t" || echo "FAILED:
  $t"; done`

See `README.md` for the user-facing overview and `.claude/skills/
renovate-maintain/reference/` for full operational detail (liveness
monitoring, fix-PR conflict monitoring, escalation rules, dependency-
currency rules).
