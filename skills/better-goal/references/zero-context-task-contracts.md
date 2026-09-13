# Strategic handoffs and recovery

Use this reference for delegated dependencies, restart boundaries, and accepted
machine results. Recovery without conversation history must still retain the
strategic context and judgment that governed the work.

## Assignment

A resuming coordinator starts at `goal.md`. A worker given a tracker and task ID
starts at that task's unique entry in `tasks.md`, then follows its goal/context
links. Include only the details needed to execute the assignment safely:

```markdown
## T3 — Outcome

Goal: [strategic goal](goal.md), relevant sub-goal/design and why this task matters.
Governing judgment: parent conclusions, user choices, relevant rejected options.
Inputs/readiness: predecessor results and identities to refresh before action.
Scope: files/services the worker may change, prohibitions, decision authority.
Result: expected outcome, evidence location, downstream reader and acceptance.
```

The scheduling table records the mutable owner/claim and status. Avoid copying
those fields into other documents. Shared context belongs at one linked location;
critical current conclusions also travel in the dispatch brief. A live context
fork can add nuance but cannot replace discoverable durable context at restart.

Future work need not have a complete contract. Before dispatch, ensure the next
executor can understand the strategic goal and relevant decisions, find its
inputs, identify authorized changes, and verify the result. Resolve ambiguity
that could change autonomous decisions; do not require a separate reviewer for
every task. A fresh recovery exercise is useful at consequential handoffs.

## Assignment and return

The coordinating parent is the sole shared task/event writer. It records the
claim before dispatch, and the worker checks its assignment before mutation.
Workers write only task-scoped evidence/action records and return them through
the harness. Include actions, attempted approaches, decisions with rationale,
outcomes, evidence, and outstanding questions, so the parent can incorporate the
full history. Do not leave relevant history solely in private conversation.

On interruption, reconcile the current claim, persisted artifacts, actual side
effects, and governing goal before resuming. Transfer ownership explicitly; a
timeout does not prove the prior worker stopped. Reuse external idempotency or
claim facilities when required rather than assuming Markdown locks work.

## Accepted results

For ordinary work, a task's result and evidence links are enough. Use a structured
`evidence/<TASK_ID>/result.json` when a downstream machine consumer or recovery
boundary needs exact identities. Its contract should state the fields consumed
downstream, including task/status, accepted run, inputs, outputs, proof, decisions,
attempts/complications, and gaps. A readable `handoff.md` may link or summarize it;
it must not define competing status or accepted identities.

Publish recoverably: validate and atomically replace the accepted result, write
any derived handoff, then have the coordinator append completion with the result
path/digest and update task status last. After interruption, verify the result
and its evidence and finish missing bookkeeping; do not repeat successful external
effects merely because the index was not updated. Keep run evidence immutable
where later reconstruction depends on it, and preserve superseded runs in history.

A missing or contradictory predecessor result blocks dependent actions, not
unrelated work. A completed task/agent status cannot substitute for evidence that
the requested outcome occurred through the relevant consumer.
