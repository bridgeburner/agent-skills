# Delegation

You coordinate and verify. Workers do the substantive execution. This describes how to
run them so you actually hear from them.

## Persistent sessions, not one-shots

Give each work item its own long-lived agent in its own terminal tab, cwd set to that
item's worktree. If your harness manages agent sessions (Herdr does), use it:

    <mux> tab create --workspace <ws> --cwd <worktree> --label "#<pr>" --no-focus
    <mux> agent start pr<n> --kind codex --pane <root_pane> -- \
      -m <model> -c model_reasoning_effort=<effort> <sandbox flags>
    <mux> agent prompt pr<n> "Read <brief path> and follow it exactly." --wait

Two reasons this beats spawning a fresh process per task:

- **Nested delegation works in an interactive session and fails in a one-shot.** A
  worker that can spawn its own reviewer is materially more capable.
- **Context persists.** A follow-up is a few lines instead of a full re-brief. One PR
  can otherwise burn five separate processes, each re-establishing everything.

## Hearing back: watch the session transcript, not the status

**Do not trust an agent-status field.** It reports settled states while an agent is
demonstrably still working, and wait-for-settled calls return early.

**Do not rely on a cooperative message file either.** It only carries what the agent
chooses to report, which is exactly the filter that loses the message you needed.

If the agent runtime persists a session transcript, watch that instead. Codex writes
every non-ephemeral session to a rollout JSONL, and the mux reports the session id, so
the join is direct:

    <mux> agent get <name>   →  .agent_session.value   (a UUID)
    ~/.codex/sessions/<Y>/<M>/<D>/rollout-<ts>-<UUID>.jsonl

Tail it and route on event type. The useful ones:

| Event | Meaning |
| --- | --- |
| `event_msg` / `task_complete` | turn finished; **`last_agent_message` carries the agent's own account** |
| `event_msg` / `*approval_request*` | genuinely blocked, waiting on a human |
| `event_msg` / `error`, `stream_error` | failing |
| `inter_agent_communication_metadata` | its sub-agents are active |

This is strictly better than the alternatives because it is **involuntary** — the agent
cannot forget to write it — **structured**, **complete** rather than curated, and
durable across restarts. It surfaces the class of message that otherwise disappears:
not a failure, not a completion, but a material constraint hit mid-flight.

Keep a separate check for the session *disappearing*, which the transcript cannot show:
a closed session simply stops appending, and closed-by-the-user is indistinguishable
from finished.

## Files are authoritative; the pane is for liveness

The user may type into these panes, and you cannot tell from a read who authored a
line. So: the brief is the only input of record, the result file the only output of
record. Read a pane for progress, never for state. Instruct every agent to record
verbatim any instruction arriving outside your channel — otherwise a human steer is
invisible and you will act on a stale picture, or prompt over it.

Before prompting a live agent, check it is not mid-turn or holding a question.

## Writing a lease

Give constraints and authority, not a checklist. The quality ceiling of a prescriptive
brief is your own thinking; a well-constrained agent exceeds it. Include:

- **The strategic goal**, not just the task — what this serves and why it matters.
- **Established facts you already verified**, so it does not re-derive them, plus an
  instruction to re-verify live before mutating.
- **The judgement**, where there is any: what is plausible but unproven, which
  trade-offs are live, what an established prior decision already settled.
- **Authority and prohibitions**, named explicitly. If the sandbox is bypassed, say so
  — an agent told there is no backstop behaves more carefully than one assuming there is.
- **A real stop condition.** Not "stop if unsure", but the specific decision that is
  not theirs to make. Then honour it when they stop.
- **The closing steps**: reply, re-request review, restore team visibility, write the
  record. Put these in the prompt text, not by reference to a template — a rule that
  lives only in a template gets skipped.

## Verifying what comes back

Substance has been reliable; cross-references have not. Independently check any
structural claim before acting on it — a base, a parent, a title, an ancestry, a
"nothing answers this". Those errors are the ones that cause real damage, because they
change what you do next.

Require, and check for:

- **Test-first evidence.** A regression that failed for the stated reason before the
  fix, and passes after. Otherwise the defect is asserted, not demonstrated.
- **Observable assertions.** For a silent-failure claim, asserting a function returned
  success proves nothing. What state survives? What does the real consumer read?
- **No weakened tests.** A stale assertion gets corrected and reported, never loosened.
  A test that now passes because it no longer approaches the boundary it was written
  for has been destroyed, not fixed.
- **Validation on the merged state** for anything stacked.
- **Stated limits.** A worker that reports what it could not verify is worth more than
  one that reports success.
