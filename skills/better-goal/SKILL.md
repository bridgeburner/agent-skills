---
name: better-goal
description: Use this skill for long-running `/goal` work, goal-command planning, or sustained implementation/debugging sessions that need durable tracking across turns. Apply it when the user starts, refines, resumes, audits, or asks how to run a goal; when work needs `.sdd` persistence, task ledgers, event logs, design spikes, design-review gauntlets, tracer bullets, e2e UI evidence, or completion audits; and when preventing false completion claims matters.
---

# Better Goal

Run `/goal` work as a durable, auditable loop. Treat the goal as a stable commitment: persist intent, track tasks and evidence, reduce architectural risk early, and only claim completion from appropriate proof.

## Setup

1. Find the canonical goal folder for the current worktree: nearest repo root's `.sdd/<worktree-folder-name>/`. If the repo/worktree mapping is ambiguous, ask the user to confirm.
2. Create the folder if needed. Do not commit `.sdd` artifacts unless the repo explicitly wants them committed.
3. Create or update:
   - `goal.md`: current objective, scope, non-goals, success criteria, and any approved changes to the objective.
   - `tasks.md`: top table of tasks with status, plus linked detail sections as needed.
   - `events.jsonl`: append-only event ledger.
   - `designs/`: non-trivial designs, specs, spike reports, review outputs.
   - `screenshots/` or `browser-evidence/`: UI/e2e evidence grouped by task id.
4. Optionally create `operating-philosophy.md` only when the goal needs a local copy or deviations from this skill. Prefer avoiding boilerplate drift.

Use task statuses consistently: `pending`, `in_progress`, `blocked`, `complete`, `parked`.

## Event Ledger

Append one JSON object per meaningful event to `events.jsonl`:

```json
{"ts":"2026-06-08T00:00:00Z","type":"task.completed","task_id":"T3","summary":"Implemented the tracer bullet","commands":["cargo test ..."],"artifacts":["screenshots/T3/thread.png"],"decision":"Kept the API contract unchanged"}
```

Useful event types include `goal.created`, `goal.updated`, `task.created`, `task.started`, `task.completed`, `task.blocked`, `design.created`, `review.completed`, `test.passed`, `test.failed`, `commit.created`, `evidence.captured`, and `gap.recorded`.

## Operating Loop

Repeat until the goal is genuinely complete:

1. Pick the most impactful next task, with architectural risk reduction before demo momentum unless the user says otherwise.
2. Investigate with real data and live code where possible. Prefer spikes and prototypes over theory when the uncertainty is empirical.
3. For implementation, favor tracer bullets: the thinnest end-to-end slice that crosses the necessary layers and produces a real output.
4. Test early. After meaningful edits, run the smallest relevant oracle; after a slice touches product behavior, run an e2e path that resembles the user flow.
5. For user/UI-facing behavior, use the actual UI and `agent-browser` when available. Store screenshots or browser artifacts under the goal folder.
6. Commit actual repo-tracked work early and often when the repo policy and user direction allow it. `.sdd` artifacts are planning/evidence and stay local by default, but code, tests, specs, docs, migrations, generated API clients, and other tracked deliverables should be committed at coherent checkpoints after the relevant checks pass. Do not leave a large completed implementation uncommitted unless the user asked you not to commit, the repo policy forbids it, or the checkpoint is still knowingly unstable.
7. Update `tasks.md`, append `events.jsonl`, and record open gaps before moving to the next task.

## Design Review Gauntlet

Use this for non-trivial architecture, contract, or subsystem decisions.

1. Spawn or otherwise prepare a design pass that writes the proposed design into `designs/`.
2. Run up to four design-review rounds. In each round, ask a reviewer: "Can we do better? Better means simpler, more elegant, or more powerful without over-engineering. What gaps or failure modes remain?"
3. Have the reviewer update the design document directly or produce a patchable review artifact.
4. Exit early when the reviewer says no material improvements remain.
5. Treat unreviewed contract changes as gaps requiring human approval.

When using subagents for design or review, request high-rigor/high-thinking execution where the agent surface supports it. Require review outputs to name concrete failure modes, not vague concerns.

## Evidence Rules

Do not collapse evidence tiers. Record what was actually proven:

- `fixture`: deterministic unit or fixture proof.
- `scripted-product`: product API/UI path with scripted or fake model behavior.
- `live-provider`: real model/provider path without full UI exercise.
- `live-ui`: actual UI exercise, ideally with `agent-browser`.
- `live-ui-provider`: actual UI plus real provider/model path.
- `manual`: user-confirmed manual verification.

Functionality counts as working only when the evidence tier matches the claim. Prefer `live-ui-provider` for as many product and agent-behavior claims as practical: it tests the real product surface, real provider decisions, streaming/readback, and user-visible behavior together. Anything short of that is still useful, but it is evidence about a fixture, script, or partial product path and must be labeled that way.

For agent behavior parity goals, `live-ui-provider` is the default proof standard, not an optional polish step. Build the parity matrix around live UI plus live provider scenarios first, then add fixtures and scripted tests as supporting checks. Drive as many parity checks as possible through the live UI with a real provider because this is the only tier that directly tests the user's product experience rather than an agent's assumption about a fixture or harness. Fixture, scripted-product, and live-provider-only tests can narrow bugs and protect contracts, but they do not prove the user-facing agent behavior by themselves.

If a goal uses weaker evidence for an agent behavior claim, record the explicit reason: user scoped out the live path, UI path is irrelevant to that feature, credentials/environment are unavailable, or the task is only a pre-parity tracer bullet. Mark the resulting claim as partial and keep the live UI/provider gap visible in `tasks.md`, `events.jsonl`, and the completion audit. Do not use deterministic fake-agent output as sufficient proof for parity unless the user explicitly limited the claim to that lower evidence tier.

## Completion

Before marking a goal complete:

1. Audit `goal.md` success criteria against `tasks.md`.
2. List remaining gaps and classify them as closed, accepted, parked, or blocking.
3. Summarize commits and durable artifacts. If tracked repo changes remain uncommitted, call that out explicitly and explain whether the user asked for that, repo policy required it, or the work is intentionally still unstable.
4. Report e2e tests and evidence paths.
5. List documents in `designs/` and ask the user which, if any, should graduate into repo-tracked specs or docs.

Never mark a goal complete because the context is long, the work is tiring, or only low-tier tests passed. Completion means the stated objective is achieved or the user has explicitly accepted the remaining gaps.
