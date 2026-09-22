# Delegation

You coordinate and verify. Workers do the substantive execution. This describes how to
run them so you actually hear from them.

**Two things this does not mean.** It does not mean you delegate everything: a one-file
mechanical conflict resolve, a status read, a re-request, a ticket check — just do those.
Spinning up a worker costs more than the work, and the exclusivity rules exist to stop
two *agents* colliding on one PR, not to stop you touching it. And if your harness has
no worker facility at all, you are the worker: run the queue serially, one PR at a time,
and use the lease structure below as your own checklist rather than a briefing you send.

## Persistent sessions, not one-shots

Give each work item its own long-lived agent in its own terminal tab, cwd set to that
item's worktree. If your harness manages agent sessions (Herdr does), use it:

    <mux> tab create --workspace <ws> --cwd <worktree> --label "#<pr>" --no-focus
    <mux> agent start pr<n> --kind codex --pane <root_pane> -- \
      -m <model> -c model_reasoning_effort=<effort> <sandbox flags>
    <mux> agent prompt pr<n> "Read <brief path> and follow it exactly."

Prompt and return. Do not block on a wait-for-settled flag — see below for why it
lies. You learn the agent finished from its transcript, not from the dispatch call.

Two reasons this beats spawning a fresh process per task:

- **Nested delegation works in an interactive session and fails in a one-shot.** A
  worker that can spawn its own reviewer is materially more capable.
- **Context persists.** A follow-up is a few lines instead of a full re-brief. One PR
  can otherwise burn five separate processes, each re-establishing everything.

## Hearing back: watch the session transcript, not the status

**First, find out whether anything tells you.** Some harnesses deliver a completion
notification when a delegated agent finishes; there, a watcher on that worker is
redundant and you should just wait to be told. Others — a named agent running in a
terminal pane, for instance — never say anything at all, and the agent will sit finished
and unnoticed until you look. Know which kind you have per worker, because mixing them up
means either pointless polling or a worker you forget for hours.

Everything below is for the second kind.

**Do not trust an agent-status field.** It reports settled states while an agent is
demonstrably still working, and wait-for-settled calls return early.

**Do not rely on a cooperative message file to know how the run is going.** It only
carries what the agent chooses to report, which is exactly the filter that loses the
thing you needed to hear — not a failure, not a completion, but a constraint it hit
halfway through and worked around.

This is not in tension with treating its result file as authoritative later. Those are
different jobs: the result file is what the worker *concluded*, and it settles that; it
is a poor instrument for noticing that the worker is stuck right now. If a result file
is genuinely all you have, accept the blind spot out loud rather than assuming silence
means progress, and ask for interim checkpoints.

If the agent runtime persists a session transcript, watch that instead. Codex writes
every non-ephemeral session to a rollout JSONL, and the mux reports the session id, so
the join is direct:

    <mux> agent get <name>   →  .agent_session.value   (a UUID)
    ~/.codex/sessions/<Y>/<M>/<D>/rollout-<ts>-<UUID>.jsonl

Tail it under the **same background watch as your PR streams** — this is stream 4 in
`monitoring.md`, not something you remember to check by hand. Checking manually is how a
worker sits finished for an hour, or sits blocked on a question you never saw. Route on
event type; the useful ones:

| Event | Meaning |
| --- | --- |
| `event_msg` / `task_complete` | turn finished; **`last_agent_message` carries the agent's own account** |
| `event_msg` / `*approval_request*` | genuinely blocked, waiting on a human |
| `event_msg` / `error`, `stream_error` | failing |
| `inter_agent_communication_metadata` | its sub-agents are active |

This is strictly better than the alternatives because it is **involuntary** — the agent
cannot forget to write it — **structured**, and **complete** rather than curated. It
surfaces the class of message that otherwise disappears: not a failure, not a
completion, but a material constraint hit mid-flight.

**Re-resolve the session id every poll; never pin the path.** The file is durable, but
the *binding* is not: restart an agent and it opens a new session with a new UUID, so a
tailer pinned to yesterday's path keeps reading a file nobody writes to any more. It
reports nothing and errors never — the silent-failure signature from `monitoring.md`,
in the one watch whose whole job is to break silence. Resolve name → session → path on
each pass, and treat the id changing as an event in itself.

Keep a separate check for the session *disappearing*, which the transcript cannot show:
a closed session simply stops appending, and closed-by-the-user is indistinguishable
from finished.

## One worker per PR, held by a lock

An event names a PR to look at; it does not define the job. The worker assesses that
PR's current state, so several events arriving close together are **one** piece of work,
not several — and an event about one PR is never a reason to sweep the whole queue.

Enforce that with a lock in your state directory, not with attention. A push and a reply
landing in consecutive cycles otherwise put two workers on one PR, and two workers can
reach opposite conclusions about the same finding, which you then publish onto the same
thread under your own name.

- Before dispatching, check for that PR's lock. If one exists, append the event to its
  pending list and dispatch nothing.
- Write the lock with the worker's identifier and start time, so a later session can
  tell a running worker from an abandoned one.
- Clear it when the result is published. If events piled up meanwhile, dispatch **once**
  against current state — not once per queued event.
- A lock whose worker is no longer running is releasable. Say so when you release one; a
  dead worker must not wedge a PR forever.

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
- **The outcome to assess, not the verdict.** A brief that announces what counts as
  blocking will get that verdict back. Say what the change claims and where a defect
  would hurt, then let severity follow from what they find. If a returned finding cites
  your brief as its reason, that is the brief marking its own homework — re-decide it on
  the merits. Say plainly when finding nothing is a valid outcome, or you invite a worker
  to justify its run by manufacturing something.
- **Authority and prohibitions**, named explicitly. If the sandbox is bypassed, say so —
  an agent told there is no backstop behaves more carefully than one assuming there is.
  It also means the boundary is no longer enforced by anything: the worker holds the same
  credentials you do, so spell out what it may not touch, and **check the returned result
  against that list** instead of assuming it held.
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
