# Operational Caveats

- `CronCreate` liveness monitoring is session-scoped and best-effort — it
  does not survive the session ending, is capped at 7 days, and only fires
  while idle. State on disk (`STATE.md`, `records/` — including the
  per-run-date `ledger-YYYY-MM-DD.tsv` files — and git commits) is the
  only real durability guarantee, which is exactly what
  the `## Queue` section and `--resume` are for. Say this plainly in the
  end-of-sweep report rather than implying continuous monitoring.
- `gh` API rate limits: watch for `gh` rate-limit errors from
  concurrently-running sub-agents (each does several `gh` calls),
  especially at higher `--concurrency` or once many sub-agents have
  cumulatively run across a long sweep. If you see them, drop
  `--concurrency` for the rest of the sweep (refill fewer slots at a time)
  rather than retrying immediately.
- A full-backlog sweep costs real tokens/wall-clock across many sub-agents
  (Investigator, sometimes + Arbiter + Executor, per PR) sustained over a
  long session. `--concurrency` is your throttle on that cost as well as
  on same-repo/API risk — the default of 5 reflects what this workflow
  actually exercised without incident across its first 2 rounds; raise it
  deliberately, not by default, and mention the scale of the sweep (queue
  size, expected sub-agent count) to the user before starting a
  large one if it wasn't already an explicit, sized request.
