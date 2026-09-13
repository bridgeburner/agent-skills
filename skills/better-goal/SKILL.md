---
name: better-goal
description: Track long-running goals, coordinate delegated work, and recover progress across sessions with a durable task and event history.
---

# Better Goal

Use a tracker when work spans sessions, agents, or consequential handoffs, or
when the user asks to create, resume, inspect, or archive one. An ordinary answer
or small change does not need a tracker.

## Location and current state

Resolve the worktree's canonical tracker with `scripts/sdd_path.py --cwd <dir>`:
`~/.sdd/<personal|altius|apex>/<worktree>/`. `--create` creates its directories.
Use an explicitly supplied tracker path; if the project cannot be inferred,
resolve that location before creating files. Do not invent repo-local trackers.

- `goal.md`: current strategic objective, why it matters, scope, user decisions,
  constraints, success criteria, and links to governing designs and sub-goals.
- `tasks.md`: work queue, dependencies, status, owner, and accepted result links.
  Future work may be outcome-level; specify inputs and authority when dispatching.
- `events.jsonl`: append-only history of work, decisions, attempts, and outcomes.
- `evidence/`, `designs/`, and UI evidence folders: durable artifacts linked from
  the current state and events. Create additional folders only as needed.

On resume, read the current goal and task state, then the referenced evidence
and relevant event interval. Reconcile drift-prone worktree/branch/PR identities
with current source before acting. Preserve earlier history when updating the
objective; changes to user intent require the user's direction.

## Delegation in strategic context

Every subagent must understand how its task contributes to the tracked strategic
goal. Include the goal path and relevant strategic or tactical sub-goal, the
parent's conclusions and rationale, user preferences, rejected approaches that
matter, and the boundaries of its autonomous decisions. A task title and output
format alone are insufficient. For untracked work, include that context directly
in the assignment.

Use a context fork when accumulated context materially improves the worker's
judgment and the harness supports it. Otherwise supply a concise explicit
handoff. In either case, preserve the critical conclusions and artifact paths
outside conversational context so the task can be recovered. Context inheritance
does not clone live interpreter state or expand the worker's authority.

Before a consequential choice, the worker must reconcile it with the broader
goal and governing decisions. Resolve missing context from the linked sources;
ask the coordinator when the uncertainty could change scope or outcome. Return
new findings that invalidate the plan instead of silently optimizing the local
task at the expense of the larger objective.

The coordinator assigns only ready, unowned work and serializes shared updates
to `tasks.md` and `events.jsonl`. Workers return their action history and results,
and write evidence only in assigned locations. Record the executor and claim
before dispatch. Use `pending`, `in_progress`, `blocked`, `complete`, or `parked`.
Reassignment requires an explicit handoff; elapsed time alone does not authorize
repeating external work. Markdown does not provide atomic claims for independent
coordinators; use an existing atomic facility if that topology is needed.

Read [handoffs and recovery](references/zero-context-task-contracts.md) when
preparing a restart, delegating dependent work, or publishing machine-consumed
results. Expand only the work that is ready; do not fully specify a speculative
queue to satisfy a template.

## Model and effort preferences

Use the selected model family and the active harness's actual controls. Default
most tasks to **Astra / low** (`gpt-6-astra`) or **Fable 5.1 / low**
(`claude-fable-5-1`). Increase effort for ambiguity, consequence, or failed
evidence; being a coordinator does not by itself require escalation.

| Task | Astra | Fable 5.1 |
|---|---|---|
| Most work with clear scope | low | low |
| Substantial judgment or interacting concerns | medium | medium |
| Difficult or consequential reasoning | high | high |
| Hardest work requiring further effort | high | xhigh, then max as justified |

Astra uses low, medium, or high in this workflow. These are user routing
preferences, not claims that effort levels or model capabilities are equivalent.
Use cheaper models only for deliberately bounded work with clear inputs and a
reliable way to check the result. That worker still receives the strategic
context above. Use ordinary commands for deterministic operations.

Record the effective model/effort and consequential routing changes with the
task. Do not claim a model selection the harness cannot express or verify. A
tool name or prose label does not change the model. Keep native agent setup out
of task execution; disclose an unavailable requested route and use an adequate
available route only within the user's constraints.

## Reconstructible history

Keep a complete record of what was done, including failed attempts and resolved
complications. Log work as it happens or at a recoverable checkpoint: assignment,
investigation, edits, commands/checks and their outcomes, decisions and rationale,
user approvals, commits/PR identities, blockers, and changes to the goal or proof.
Routine related actions may share an event if linked evidence preserves their
details. Do not reduce the ledger to milestones or rewrite unsuccessful history.

```json
{"ts":"2026-09-13T12:00:00Z","type":"work.recorded","task_id":"T3","agent":"worker-1","summary":"Inspected both readers, changed the shared resolver, and checked the retained input","artifacts":["evidence/T3/actions.md","evidence/T3/check.log"],"outcome":"passed"}
```

Events should identify the task, actor, affected worktree/branch/PR or revision
when relevant, action, outcome, and durable evidence paths. Decisions also need
their rationale and impact; distinguish user direction from autonomous choices.
Use chronological JSON objects, one per line. Keep raw logs in evidence and link
them rather than copying them into every report. Retain the evidence a later
reader needs to reconstruct previous PRs and worktrees, subject to the project's
data-handling rules; credentials and unauthorized customer data are not evidence
to preserve. Do not rely on temporary files or a private session transcript as
the sole historical record.

When workers run concurrently, their assigned action/evidence files preserve
history until the coordinator incorporates it. Preserve event identifiers when
reconciling a repeated handoff so it does not appear as work performed twice.

## Status and completion

A normal sitrep reports current outcome, progress since the previous report,
blockers, consequential decisions, and next work. Link the detailed record. For
an audit or full-history request, reconstruct all requested tasks and attempts
from events and evidence, including resolved issues. Surface contradictions or
missing evidence. Append the report boundary so the next delta is well defined.

Match acceptance evidence to the goal. A passing tool call, deployed artifact,
or completed agent turn does not establish an unexercised product outcome.
Distinguish tests, retained artifacts, live provider behavior, product/UI paths,
and environment-specific observations. Keep the required acceptance gap open
until it is closed or the user explicitly accepts it. Use better-review when
review is requested or independent judgment would materially protect the work.

Complete the goal only when its success criteria are satisfied. Report accepted
gaps and the disposition of code and artifacts, including uncommitted changes.
Do not invent follow-up work or a document-promotion question to delay completion.

## Archive and resume

At a completed arc or requested archive, copy its tracker and evidence into
`~/.sdd/<pillar>/archive/<worktree>/<timestamp-slug>/`, with a short index naming
the objective, final revisions/PRs, results, gaps, and evidence locations. Verify
links still resolve before retiring any source. Preserve history and evidence
needed to reconstruct the work; archival is not deletion authority.

Keep unfinished tasks with stable IDs in the live tracker and link their archived
prerequisites. Record an archive/reseed event and the next objective; if there is
none, leave a minimal archive pointer. For legacy repo-local trackers, copy only
within the user's authorized source/destination scope and preserve the original.
