# renovate-pr-doctor

Tooling and records for maintaining Renovate-authored PRs that cannot auto-merge due to failing CI, across a configurable set of GitHub orgs/users (default: `book000`, `tomacheese`, `jaoafa`). Override with `$RENOVATE_MAINTAIN_ORGS` / `$RENOVATE_MAINTAIN_DEFAULT_ASSIGNEE` (see `scripts/find-broken-prs.sh`). The workflow itself is Claude Code skills and sub-agents under `.claude/`; the shell scripts are helpers for them.

## Language

- Write commit messages, PR/Issue text, review comments, code comments, and documentation (including README and this file) in English.
- Exceptions: quotations, external text, technical identifiers, and generated files stay as they are.

## Layout

- `.claude/skills/renovate-maintain/` — full sweep skill; `reference/` holds the operational detail (architecture, liveness monitoring, fix-PR conflict monitoring, escalation, dependency currency, resuming, caveats).
- `.claude/skills/renovate-status/` — read-only status skill.
- `.claude/agents/` — `investigator.md`, `arbiter.md`, `executor.md`, `conflict-fixer.md`.
- `scripts/` — `find-broken-prs.sh`, `pr-ci-detail.sh`, `check-dependency-currency.sh`, helpers in `scripts/lib/`.
- `STATE.md`, `records/` — run state and history (see Safety rules).

## Commands

- `/renovate-maintain [--concurrency N] [--repo owner/repo] [--assignee login] [--resume]` — runs the full sweep. Side-effect-heavy; invoke only explicitly.
- `/renovate-status [--repo owner/repo]` — read-only report; never dispatches or changes state.
- Tests: `for t in scripts/tests/test-*.sh scripts/test-check-dependency-currency.sh; do bash "$t" || echo "FAILED: $t"; done` (they stub `gh` via `PATH`; run with `gh` resolving to the stub, i.e. no shim that reorders `PATH`).
- Lint: `shellcheck scripts/*.sh scripts/lib/*.sh scripts/tests/*.sh`

## Conventions

- Working directory is the repository root; never hardcode its path.
- Deployment-specific settings go in env vars, not in script edits.
- Keep `scripts/lib/*` pure (no network); `gh` calls live in the top-level scripts.

## Safety rules

- Same-repo serialization: never run two sub-agents (Investigator, Arbiter, Executor, Conflict-Fixer) against the same target repo concurrently; they would race to push competing branches.
- Fix PRs are this workflow's own PRs, opened against the target repo's default branch. Never commit to a Renovate-authored PR's own branch.
- `STATE.md` and `records/` are intended as local-only working state (listed in `.gitignore`) because they can contain private detail about target repos and PRs; do not add new private detail to anything that gets published.
- STATE.md discipline: `STATE.md` is ephemeral and always overwritten; it must be self-contained (conversation memory is not trusted). Read it at the start of every turn and keep it bounded.
- `records/ledger-YYYY-MM-DD.tsv` is the permanent machine-readable record of every handled PR. Query it with targeted `grep`/`awk` over `records/ledger*.tsv`; never load whole files or re-derive it from `records/*.md` prose. A matching row still gets a staleness recheck (`scripts/lib/ledger-staleness.sh`) before a PR is dropped from a sweep.
- `records/YYYY-MM-DD-run.md` is the permanent human-readable record of a run date.

See `README.md` for the user-facing overview.
