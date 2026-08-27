# Zero-context task contracts

Use this reference when seeding any task for zero-context delegation, preparing
a restart boundary, or repairing a tracker whose tasks depend on conversation
context.

## Design principle

An executor should be able to start safely when given only:

1. the canonical tracker root; and
2. one task ID.

This is a recovery guarantee, not a requirement that every live dispatch use
fresh context. Follow the global child-context policy: model or reasoning-effort
assignment does not decide context mode, but the selected controls must be
jointly supported by the active harness. Preserve a complete task contract even
when the live dispatch truthfully inherits parent context. Never imply that
context inheritance clones mutable REPL, interpreter, application, or tool state;
pass critical conclusions, live values, and artifacts explicitly.

Progressive disclosure keeps this compact. Store shared, slow-changing context
once in `designs/executor-bootstrap.md`; require each task to link it and name
only its task-specific predecessor artifacts and
contracts. The task table remains an index, not the execution specification.

## Shared executor bootstrap template

```markdown
# Executor bootstrap

Assume no conversation history.

The canonical bootstrap is the first link in every task's ordered
`Required context`. After reading it, return to the assigned task section and
continue with the next unvisited link. The task's list is the sole read order.

## Canonical locations and authority
- tracker, worktree, repository, and branch locations
- authorized external systems or hosts
- explicit exclusions and protected user-owned state
- rule for resolving stale or conflicting identities

## Per-task evidence and handoff
- `evidence/<TASK_ID>/result.json`
- `evidence/<TASK_ID>/handoff.md`
- event and task-status update requirements

## Cold-start preflight
- predecessor artifacts present
- exact allowed scope known
- prohibitions known
- outputs and proof known
- stop conditions known
- downstream consumer known
```

Use `tasks.md` and the exact task heading as the universal discovery entry
point; do not require an optional handoff or design before the task links it.
Adapt the remaining names, but retain the semantics. If sources disagree, require the
executor to stop before mutation and record the contradiction.

## Task detail template

```markdown
## T3 — Outcome-oriented title

**Required context:** Links to the shared bootstrap, governing design, and exact
predecessor `evidence/<ID>/handoff.md` and `result.json` files.

**Ready when:** Machine-checkable dependency and approval conditions.

**Transfer / recovery policy:** Immutable conditions under which the coordinating
agent may transfer or recover the task's table-owned lease. Do not duplicate the
mutable owner or claim timestamp from the scheduling table here.

**Inputs:** Exact artifacts, refs, identifiers, approved decisions, and
preconditions. State which drift-prone identities must be re-resolved.

**Authority and boundaries:** Repositories, branches, external surfaces, and
mutations allowed; explicit prohibitions and user-controlled gates.

**Actions:** Bounded execution steps and autonomous decision authority.

**Required outputs:** Canonical task artifacts plus
`evidence/T3/result.json` and `evidence/T3/handoff.md`. State what exact values
the handoff must give downstream tasks.

**Proof:** Commands, tests, evidence tier, artifact properties, and settlement
required to claim the outcome.

**Stop conditions:** Ambiguities, identity drift, missing inputs, destructive
boundaries, or failures that require user direction rather than improvisation.
```

Existing task prose may combine authority, actions, proof, and stop conditions,
but the required context, inputs, and canonical outputs must remain visibly
findable.

## Canonical predecessor pattern

Each completed task should leave two stable entry points:

- `result.json`, the authoritative machine record, with at least `task_id`,
  `status`, `accepted_run`, `inputs`, `outputs`, `proof`, `decisions`,
  `complications`, and `gaps`. The task contract defines the names and types of
  every `outputs` field consumed downstream.
- `handoff.md`, a human-readable projection that links to `result.json` and
  does not define competing status or machine identities.

`tasks.md` is the scheduling/ownership index. `events.jsonl` is append-only
audit history. Neither supersedes the accepted identities in `result.json`.

Publish completion recoverably: validate and atomically replace `result.json`;
write its derived `handoff.md`; append `task.completed` with the result path and
digest; update the task-table status last. After interruption, a valid result
whose proof still checks authorizes finishing the missing bookkeeping. Repair
the projection/history/index instead of escalating a false contradiction.

Immutable run directories may hold bulky evidence. The stable files should
index the accepted run rather than forcing the next executor to choose among
timestamped directories. A missing required predecessor file blocks the
consumer task.

## Cold-start audit

Audit every pending or in-progress task before it is delegated. For a large set,
one audit may cover a recorded equivalence class only when the tasks share the
same contract template, authority boundary, dependency shape, output schema,
and proof path; check every task-specific substitution mechanically. Verify a
context-free executor can answer:

1. What must already exist before the task starts?
2. What exact code and external surfaces may it touch?
3. What must it never touch?
4. What actions may it take without asking?
5. What files and machine-readable identities must it produce?
6. What observation proves completion at the claimed evidence tier?
7. What conditions force a stop?
8. Where does the next task read the accepted result?

Use a fresh agent or thread when practical. Give it only the tracker path and a
task ID, ask for an execution-readiness report without mutations, and repair
every inferred or missing answer. Do not leak the intended answers in the audit
prompt.

## Dispatch and interruption semantics

- `pending`: dispatch only when `Ready when` is true and the owner is unclaimed.
- `in_progress`: owned. Another executor stops unless an explicit transfer event
  or handoff releases the lease.
- `blocked` and `parked`: not dispatchable.
- `complete`: read-only; consumers use the accepted `result.json`.

The coordinating agent is the sole dispatcher and lease writer. It records the
executor identity, claim ID, and timestamp in the task table before delegation.
The executor verifies that supplied claim against the table before its first
mutation, then appends `task.started`; it never self-claims. A resumed executor
must prove the coordinator transferred or released the prior lease. Elapsed
time alone does not grant ownership of external-system work. If several
independent coordinators must dispatch concurrently, Markdown is insufficient;
use an atomic claim primitive rather than read-then-write self-claims.
