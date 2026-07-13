# Escalation

**Phase separation**: design/setup questions go through `AskUserQuestion` as
normal. Once the **execution phase** begins, the running process must not
ask the user anything about an individual PR while the run is in progress.

Per-PR decision flow:

1. **Primary judgment (Investigator sub-agent)**: determines root cause and
   fix. If confident, proceeds straight through to opening the fix PR
   (status `fixed`).
   - If instead it hits a purely environmental obstacle — repo archived, no
     push access, a required secret unavailable, CI infrastructure itself
     down — that is not a judgment call at all; it reports `blocked`
     directly and does **not** escalate to the Arbiter (there is nothing for
     the Arbiter to weigh in on).
2. **Escalation trigger**: if any of the following hold, the sub-agent does
   not guess and does not ask the user — it escalates to a second sub-agent:
   - multiple plausible fixes exist with no clearly-better option,
   - the root cause cannot be pinned down with reasonable confidence,
   - the fix would involve a risky/behavior-changing change.
3. **Who spawns the Arbiter**: the orchestrator, not the Investigator. When
   the Investigator's checkpoint in `STATE.md` reports "escalation needed"
   (with its findings and candidate options), the orchestrator dispatches a
   fresh Arbiter sub-agent as a sibling — the Investigator does not spawn or
   block synchronously on it. The Investigator writes an `escalated`
   checkpoint and ends its own turn; liveness monitoring treats `escalated`
   as a terminal-for-now, non-suspect state so it is never misclassified as
   dead while waiting on the Arbiter.
4. **Secondary judgment (Arbiter sub-agent)**: given the Investigator's
   findings and the candidate options, evaluates independently (fresh
   context) and returns either `proceed` (with one option chosen, which the
   orchestrator then hands to a fresh sub-agent to execute through to
   `fixed`) or `skip`.
5. **Skip is terminal for that PR in this run**: if the arbiter also returns
   `skip`, the PR is marked `skipped` in `records/`, along with what was
   investigated, what options were considered, and why it was skipped. The
   run moves on to the next PR autonomously — still no user prompt.
6. **Reporting, not asking**: `skipped`/`blocked` PRs are collected and
   surfaced only in the end-of-run summary (in `records/YYYY-MM-DD-run.md`
   and in the final chat message), after the run completes — never as an
   in-run interruption.

This is a deliberate, narrowly-scoped exception to the general guardrail of
"ask if blocked," limited to the execution phase of this specific workflow.
It does not relax any other guardrail: PRs are still never merged without
explicit user instruction, and Renovate PR branches are still never
committed to.
