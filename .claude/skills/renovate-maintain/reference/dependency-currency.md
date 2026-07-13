# Dependency Currency Check

## Scope

Not in scope: CI-passing-but-stale Renovate PRs. Only PRs that are already
targets under the base CI-failure definition (open + Renovate-authored + CI
`FAILURE`/`ERROR`) get a currency check.

## Where it fits in the existing flow

`.claude/agents/investigator.md`'s per-PR procedure has a first step, before
root-cause investigation of the CI failure itself:

1. **Currency check** — described below.
2. Root-cause investigation of the CI failure, informed by the currency
   check's outcome: if the check found an unexplained patch/minor gap, the
   fix targets the actual latest version instead of the version the
   Renovate PR happened to propose.

There is no separate slash command for this — the check is entirely inside
what an Investigator does for a PR it was already going to process, and
`/renovate-maintain`'s own discovery/queue/refill procedure is unaffected.

## Currency check procedure

Deterministic script: `scripts/check-dependency-currency.sh <owner/repo>
<pr-number>`. Deterministic/scriptable parts only; judgment (is a gap
"explained", is this actually safe to bump) stays with the Investigator/
Arbiter.

1. **Extract dependency table**: fetch the PR body via `gh pr view --json
   body` and parse Renovate's standard "This PR contains the following
   updates" table (columns: Package | Type | Update | Change). A single PR
   can list multiple packages (e.g. `renovate/all-minor-patch` grouped
   PRs) — **loop over every row**, not just the first.
2. **Determine ecosystem/manager for the PR** from the set of changed file
   paths (`gh pr diff --name-only`), not from the dependency table itself —
   Renovate's PR body doesn't reliably print an explicit manager label per
   package, but the touched files do (`package.json`/lockfiles → `npm`,
   `pom.xml` → `maven`, `requirements*.txt`/`pyproject.toml`/etc. → `pip`,
   `Dockerfile`/compose files → `docker`, `.github/workflows/*.yml` →
   `github-actions`). If the changed files span more than one ecosystem
   (ambiguous), classify the whole PR's manager as `unknown` and fall
   through to the lookup-failure handling in step 6 for every package —
   don't guess. Then read each package's name and proposed target version
   (the "to" side of the Change column) from the table as before.
3. **Query actual latest published version**, dispatched by manager:
   - `npm` → npm registry (`npm view <pkg> version` or equivalent registry
     API call)
   - `maven` → Maven Central search API
   - `pip` → PyPI JSON API
   - `docker`/`github-actions` (image or action tags) → the relevant
     registry/tags API
   - Any other manager Renovate reports → best-effort equivalent lookup;
     if none is implemented yet, treat as "unknown", skip gracefully (see
     step 6).
4. **Check for an intentional gap**: read the repo's Renovate config
   (`renovate.json`/`renovate.json5`/`.github/renovate.json5`/
   `package.json#renovate`, whichever exists) for `packageRules` matching
   this package (`ignoreDeps`, `allowedVersions`, `matchUpdateTypes`,
   `schedule`, `minimumReleaseAge`, `groupName`), and check for an open
   "Dependency Dashboard" issue in the repo with a status line for this
   package (Pending Approval / Rate-Limited / Errored / etc.). If either
   explains the gap, it is **not** stale — record the explanation and move
   on.
5. **Classify** each package's result as one of: `current` (PR already
   proposes latest, or no newer version exists), `stale-explained`
   (gap exists but justified by config/dashboard), `stale-unexplained-
   minor` (patch/minor gap, no justification found), `stale-unexplained-
   major` (major-version gap, no justification found).
6. **On lookup failure** (private/internal registry, auth required, rate
   limited, unknown manager, parse failure) — skip that package's currency
   check entirely and fall back to the base behavior (fix CI for whatever
   version the PR currently proposes). Never let a currency-check failure
   block the underlying CI fix.

## Outcome handling

Classifications are evaluated **per PR** across all of its packages, in
this priority order (a grouped PR with a mix of classifications across its
packages is handled entirely under the highest-priority bullet that
applies — findings never split across bullets within one PR):

1. **Any package `stale-unexplained-major`** (highest priority — checked
   first, across all packages in the PR): never auto-fixed and bumped
   unilaterally. The Investigator still fixes CI for the currently-proposed
   version as usual (so the Renovate PR itself remains mergeable), but
   additionally escalates via `NEEDS_ARBITER`, flagging the major-version
   gap as a separate concern from the CI failure. This is a third mode for
   the Investigator beyond the binary "implement a confident fix" /
   "escalate and end the turn" choice in `investigator.md` — call it
   `fix-pr-opened-plus-escalated`: the fix PR is opened and its checkpoint
   recorded first, then `NEEDS_ARBITER` is sent for the separate
   major-version finding, referencing the already-opened fix PR so the
   Arbiter (and any human review) has full context. `arbiter.md` has a
   standing rule: **a `stale-unexplained-major` finding always resolves to
   a new `escalate-to-user` verdict — distinct from its existing `proceed`/
   `skip` verdicts — never a unilateral `proceed`.** On `escalate-to-user`,
   the Arbiter gathers and presents the trade-offs (breaking-change risk,
   changelog summary if available) but does not decide go/no-go itself; the
   main coordinator relays the question to the user via `AskUserQuestion`.
   This is a stricter rule than the Arbiter's other judgment calls, given
   the higher blast radius of major version bumps compared to the
   mechanical lint/config fixes otherwise handled. (If some other package
   in the same PR is merely `stale-unexplained-minor`, it is *not*
   separately auto-bumped under bullet 2 below — the whole PR is handled
   under this bullet instead, to keep the decision logic simple.)
2. **Otherwise, any package `stale-unexplained-minor`**: the Investigator's
   fix PR targets the actual latest version for that package instead of the
   version the Renovate PR proposed, in the same fix PR that resolves the
   CI failure (one combined PR, not two). `STATE.md`'s detail line notes
   this explicitly, e.g.: "dependency currency: `@book000/eslint-config`
   proposed 1.15.44, latest 1.15.51 (unexplained gap) — bumped to 1.15.51 in
   fix PR." No ledger.tsv schema change; this is prose-only in `STATE.md`
   (ledger.tsv's `fix_pr_url` column already points at the one fix PR either
   way).
3. **Otherwise (all packages `current` or `stale-explained`)**: proceed
   exactly as the base behavior already does — fix CI for the version(s)
   the Renovate PR currently proposes. Record which packages were checked
   and their explanation (if any) in the PR's `STATE.md` subsection for
   traceability.
