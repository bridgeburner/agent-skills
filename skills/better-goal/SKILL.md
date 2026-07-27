---
name: better-goal
description: Use this skill for durable agent work that should use `~/.sdd` tracking. Trigger when a task is likely to span 3+ meaningful steps, 30+ minutes, multiple turns, multiple files/modules, multiple agents, or a restart/resume boundary; when it involves design decisions, PR/CI refreshes, research spikes, UI/e2e evidence, live-provider validation, migrations, backfills, deployments, coordinated commits, completion audits, or false-completion risk; or when the user invokes/refers to `/goal`, resume, audit, tracker, or completion proof. Do not use for one-shot answers, tiny edits, or single-command checks.
---

# Better Goal

Run significant agent work through the home-level `~/.sdd` protocol. `/goal` is the canonical long-running use case, but the same task ledger, event log, evidence capture, and completion audit apply whenever work must be resumable or proof-driven.

## Trigger Decision

Use `~/.sdd` tracking when any threshold is met:

- 3+ meaningful steps.
- Likely 30+ minutes of work.
- Multiple turns, interruption risk, or resume needed.
- Multiple files, modules, services, agents, or coordinated commits.
- Design decisions, research spikes, PR/CI refreshes, migrations, data backfills, deployments, or live-system proof.
- UI/e2e evidence, live-provider validation, screenshots, browser artifacts, or completion audit needed.
- User mentions `/goal`, resume, audit, tracker, completion proof, or false-completion concerns.

Do not use this skill for one-shot answers, tiny edits, or single-command checks where the final response plus command output is sufficient evidence.

## Setup

1. Resolve the project pillar from the git worktree root:
   - `personal`: paths under `~/dev/personal/` or `~/src/personal/`.
   - `altius`: paths under `~/dev/altius/` or `~/src/altius/`.
   - `apex`: paths under `~/dev/apex/` or `~/src/apex/`.
2. Use the canonical live tracker: `~/.sdd/<project-pillar>/<worktree-name>/`, where `<worktree-name>` is the git root basename. Prefer running `scripts/sdd_path.py --create` from this skill to avoid hand-rolled path inference.
3. If the pillar cannot be inferred, ask the user before creating tracker files. Do not create repo-local `.sdd` directories.
4. Create or update:
   - `goal.md`: current objective, scope, non-goals, success criteria, and any approved objective changes.
   - `tasks.md`: top table of tasks with status, plus linked detail sections as needed.
   - `events.jsonl`: append-only event ledger.
   - `designs/`: non-trivial designs, specs, spike reports, review outputs.
   - `evidence/`: command outputs, generated artifacts, data proofs, and validation bundles grouped by task id or run id.
   - `browser-evidence/` and `screenshots/`: UI/e2e artifacts grouped by task id or run id.
   - Optional domain folders such as `experiments/`, `research/`, `handoffs/`, or `canonical/` when the work naturally needs them.
5. Optionally create `operating-philosophy.md` only when the work needs a local copy or deviations from this skill. Prefer avoiding boilerplate drift.

Use task statuses consistently: `pending`, `in_progress`, `blocked`, `complete`, `parked`.

## Event Ledger

Append one JSON object per meaningful event to `events.jsonl`:

```json
{"ts":"2026-06-08T00:00:00Z","type":"task.completed","task_id":"T3","summary":"Implemented the tracer bullet","commands":["cargo test ..."],"artifacts":["screenshots/T3/thread.png"],"decision":"Kept the API contract unchanged"}
```

Useful event types include `goal.created`, `goal.updated`, `task.created`, `task.started`, `task.completed`, `task.blocked`, `design.created`, `review.completed`, `test.passed`, `test.failed`, `commit.created`, `evidence.captured`, and `gap.recorded`.

## Codex Only: Subagent Model Routing

This section applies only when the active harness is Codex. Other agent
harnesses must ignore these mechanics and use their own native model, reasoning,
and delegation controls.

For each tracker task that may be delegated, record one Codex model/reasoning
combination in `tasks.md`. Choose the lowest-cost combination that is still
adequate for the task:

- `gpt-5.6-luna`: bounded, reversible, high-volume, or mechanical work with an
  exact oracle, such as file inventories, deterministic checks, and routine
  transformations.
- `gpt-5.6-terra`: normal implementation, testing, reconciliation, review, and
  codebase exploration where moderate judgment is required.
- `gpt-5.6-sol`: ambiguous architecture, cross-system diagnosis, causal
  analysis, optimization, or consequential decisions where frontier capability
  materially reduces risk.
- `medium`: balanced default for clear tasks.
- `high`: complex multi-step work, edge cases, or critical review.
- `xhigh`: difficult root-cause analysis, optimization, or integration with
  several competing hypotheses.
- `max`: reserve for the hardest quality-first task where failure is costly and
  additional latency and token use are justified.

Do not assign every task the strongest combination. Escalate only when the
task's ambiguity, consequence, or failed evidence warrants it. Reassign the
tracker row if the task becomes materially harder or simpler.

### Custom-agent bootstrap

If the required presets do not exist, create `~/.codex/agents/` and add one
standalone TOML file per combination. The recommended reusable matrix is
`{sol,terra,luna}_{medium,high,xhigh,max}`. For example,
`~/.codex/agents/terra_high.toml` contains:

```toml
name = "terra_high"
description = "GPT-5.6 Terra with high reasoning for careful implementation and review."
model = "gpt-5.6-terra"
model_reasoning_effort = "high"
developer_instructions = """
Execute the delegated task within its stated scope. Preserve the parent agent's
constraints, return concrete evidence, and make autonomous decisions only where
the task permits.
"""
```

For the other presets, change `name`, `description`, `model`, and
`model_reasoning_effort` consistently. Valid model values for this matrix are
`gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna`; effort values are `medium`,
`high`, `xhigh`, and `max`. Omit sandbox and tool settings unless a role needs a
deliberate restriction so the agent inherits the parent session's controls.
Custom-agent registries may be loaded at session start, so restart Codex after
adding presets when the active spawn tool does not expose them.

To spawn with the recorded combination:

1. Use Codex's native `spawn_agent`; do not invoke nested `codex exec`.
2. Prefer explicit `model` and `model_reasoning_effort` spawn fields when the
   active tool schema exposes them.
3. Otherwise select a custom agent whose name encodes the combination, such as
   `luna_medium`, `terra_high`, or `sol_xhigh`. Personal custom agents live in
   `~/.codex/agents/`; project-scoped agents live in `.codex/agents/`.
4. Pass the custom agent through the tool's actual agent-role/type selector.
   A `task_name` or prose instruction does not select a model.
5. If the active spawn schema exposes neither model/effort fields nor an agent
   selector, exact routing is unavailable in that session. Do not claim
   otherwise. Restart after installing custom agents if needed, or record that
   the task used the session default.
6. When exact routing matters, verify runtime evidence shows the selected role
   and effective model/reasoning combination; keep that evidence with the task.

## Operating Loop

Repeat until the tracked work is genuinely complete:

1. Pick the most impactful next task, with architectural risk reduction before demo momentum unless the user says otherwise.
2. Investigate with real data and live code where possible. Prefer spikes and prototypes over theory when the uncertainty is empirical.
3. For implementation, favor tracer bullets: the thinnest end-to-end slice that crosses the necessary layers and produces a real output.
4. Test early. After meaningful edits, run the smallest relevant oracle; after a slice touches product behavior, run an e2e path that resembles the user flow.
5. For user/UI-facing behavior, use the actual UI and `agent-browser` when available. Store screenshots or browser artifacts under the goal folder.
6. Commit actual repo-tracked work early and often when the repo policy and user direction allow it. `~/.sdd` artifacts are planning/evidence and stay outside the repo by default, but code, tests, specs, docs, migrations, generated API clients, and other tracked deliverables should be committed at coherent checkpoints after the relevant checks pass. Do not leave a large completed implementation uncommitted unless the user asked you not to commit, the repo policy forbids it, or the checkpoint is still knowingly unstable.
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

For agent behavior parity work, `live-ui-provider` is the default proof standard, not an optional polish step. Build the parity matrix around live UI plus live provider scenarios first, then add fixtures and scripted tests as supporting checks. Drive as many parity checks as possible through the live UI with a real provider because this is the only tier that directly tests the user's product experience rather than an agent's assumption about a fixture or harness. Fixture, scripted-product, and live-provider-only tests can narrow bugs and protect contracts, but they do not prove the user-facing agent behavior by themselves.

If tracked work uses weaker evidence for an agent behavior claim, record the explicit reason: user scoped out the live path, UI path is irrelevant to that feature, credentials/environment are unavailable, or the task is only a pre-parity tracer bullet. Mark the resulting claim as partial and keep the live UI/provider gap visible in `tasks.md`, `events.jsonl`, and the completion audit. Do not use deterministic fake-agent output as sufficient proof for parity unless the user explicitly limited the claim to that lower evidence tier.

## Archiving

When tracked work reaches a meaningful milestone or the user asks to archive the current tracker, rotate the live tracker instead of leaving the completed arc as the default resume point.

1. Create `~/.sdd/<project-pillar>/archive/<worktree-name>/<timestamp-slug>/`.
2. Copy the completed tracker surfaces into that archive: `goal.md`, `tasks.md`, `events.jsonl`, completion audits, relevant `designs/`, and any evidence indexes needed to understand the arc.
3. Add `SUMMARY.md`: a compact but readable summary of what was accomplished, important decisions, final metrics, artifacts, verification, remaining gaps, and the recommended next starting point.
4. Add `manifest.md`: a minified entry point that links to `SUMMARY.md`, lists archived files, names the final commit/artifacts, and gives the shortest useful status snapshot.
5. Reset the live `goal.md`, `tasks.md`, and `events.jsonl` to a fresh starting point that links back to the archive and waits for the next objective.
6. Keep archives under `~/.sdd`; do not move them into the repo unless the user explicitly asks.

This gives progressive disclosure: `manifest.md` for orientation, `SUMMARY.md` for context, and the raw tracker files for audit.

## Legacy Tracker Archiving

When the user points at a legacy repo-local `.sdd` location, treat it as historical material and archive it into the new home-level layout. Do not upgrade it into the live tracker, and do not copy anything without explicit human approval of the source and destination.

1. Identify the project pillar from the legacy path or nearby git worktree.
2. Present the proposed copy plan: each legacy tracker source and its destination `~/.sdd/<project-pillar>/archive/<legacy-tracker-name>/legacy-import-<timestamp>/`.
3. Wait for explicit human approval before copying.
4. Never move or delete the legacy source. Never overwrite an existing archive.
5. Add `import-manifest.md` with source path, destination path, import timestamp, copied top-level entries, skipped entries, and assumptions.
6. Leave `~/.sdd/<project-pillar>/<worktree-name>/` untouched unless the user separately asks to start or resume live work.

## Completion

Before marking tracked work complete:

1. Audit `goal.md` success criteria against `tasks.md`.
2. List remaining gaps and classify them as closed, accepted, parked, or blocking.
3. Summarize commits and durable artifacts. If tracked repo changes remain uncommitted, call that out explicitly and explain whether the user asked for that, repo policy required it, or the work is intentionally still unstable.
4. Report e2e tests and evidence paths.
5. List documents in `designs/` and ask the user which, if any, should graduate into repo-tracked specs or docs.

Never mark work complete because the context is long, the work is tiring, or only low-tier tests passed. Completion means the stated objective is achieved or the user has explicitly accepted the remaining gaps.
