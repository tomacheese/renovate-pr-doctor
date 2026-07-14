# Liveness Monitoring

Background sub-agents can be killed or simply stop making progress without
any error being surfaced to the orchestrator. Relying solely on the
completion notification is not enough — a dead sub-agent never sends one, and
the run would silently stall.

- While any sub-agent is in flight, the orchestrator schedules a recurring
  check roughly every 15 minutes via `CronCreate` (e.g. `"6,21,36,51 * * *
  *"` — off the `:00`/`:30` marks per scheduling guidance, since "about 15
  minutes" is approximate).
- Each firing: list in-flight sub-agents/tasks, compare against `STATE.md`'s
  per-PR checkpoints. A sub-agent is considered **suspect** if it holds a PR
  at a non-terminal checkpoint (not `completed`/`skipped`/`blocked`, and not
  the `escalated` waiting-on-Arbiter state) and, since the
  previous firing, neither (a) its `STATE.md` section's `checkpoint`/`detail`
  text changed, nor (b) a new commit landed in its
  `scratchpad/renovate-fix-<repo>-<pr>` clone or fix branch — both are cheap
  to check (`git log -1` timestamp in each location) without probing the
  agent itself.
- **Probe before assuming death**: for a suspect sub-agent, send it a status
  check via `SendMessage` (to its agent ID) asking it to report its current
  checkpoint, rather than immediately redispatching. This probe is cheap and
  may be repeated across several consecutive firings (e.g. 2-3 checks, ~30-45
  minutes) — a sub-agent that is merely slow (large repo, slow CI logs) will
  eventually respond and update `STATE.md` itself.
- **A probe is only ever for a genuinely suspect (no-progress) sub-agent.**
  Never send a status-check message to an in-flight sub-agent just because
  its `STATE.md` checkpoint *advanced* (e.g. it reached `escalated` or
  `fix-pr-opened-plus-escalated`) but you haven't yet received its
  `SendMessage` report — that is progress, the opposite of a stall, and its
  real completion notification will arrive on its own. Soliciting a report in
  that case adds noise and risks interrupting a sub-agent still finishing its
  own verification steps. See `SKILL.md`'s refill loop (Step 4) opening note.
- **Only after repeated probes get no response** (the agent does not reply
  and its `STATE.md` checkpoint still hasn't moved) is it treated as
  genuinely dead. At that point, and without asking the user (consistent
  with the no-mid-run-questions rule — see `escalation.md`): re-dispatch that
  PR to a fresh sub-agent exactly once. Before opening a new fix PR, the
  fresh sub-agent must first check whether the dead sub-agent already opened
  one (e.g. `gh pr list` on the target repo filtered to a fix-branch naming
  pattern, or the dead sub-agent's last `STATE.md` `detail` line if it
  recorded a `fix_pr_url`) — reuse/continue that PR instead of opening a
  duplicate. If the retry also goes unresponsive, mark it `blocked` in
  `records/` with reason `sub-agent died` (not a judgment call, so `blocked`
  rather than `skipped`) and move on.
- This monitoring is best-effort, not a durability guarantee: `CronCreate`
  jobs are session-only (in-memory), only fire while the session is idle, and
  are capped at 7 days. It catches silent deaths *during* an active session;
  it is not a substitute for the on-disk checkpoints in `STATE.md`/`records/`,
  which remain the actual source of truth if the session itself ends.
- Once no sub-agents remain in flight (run complete), the cron job is
  cancelled via `CronDelete`.
