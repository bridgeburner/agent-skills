---
name: better-goal
description: Use this skill for durable agent work that should use `~/.sdd` tracking. Trigger when a task is likely to span 3+ meaningful steps, 30+ minutes, multiple turns, multiple files/modules, multiple agents, or a restart/resume boundary; when it involves design decisions, PR/CI refreshes, research spikes, UI/e2e evidence, live-provider validation, migrations, backfills, deployments, coordinated commits, completion audits, or false-completion risk; or when the user invokes/refers to `/goal`, resume, sitrep, audit, tracker, or completion proof. Do not use for one-shot answers, tiny edits, or single-command checks.
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
- User mentions `/goal`, resume, sitrep, audit, tracker, completion proof, or false-completion concerns.

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

Useful event types include `goal.created`, `goal.updated`, `task.created`, `task.started`, `task.completed`, `task.blocked`, `design.created`, `decision.recorded`, `review.completed`, `test.passed`, `test.failed`, `commit.created`, `evidence.captured`, `gap.recorded`, and `sitrep.reported`.

Record every autonomous decision when it happens so later sitreps do not have to infer intent from edits. Include `task_id`, `agent`, `decision`, `rationale`, `impact`, and whether the decision is `reversible`.

Likewise, record every complication, blocker, failed approach, unexpected issue, and changed expectation when encountered, plus later disposition changes. Use the most specific event type, such as `task.blocked`, `test.failed`, or `gap.recorded`, and retain resolved items in the append-only history.

## Harness-Specific Subagent Model Routing

The routing guidance below is harness-specific. Apply only the section matching
the active harness; do not transfer another harness's model, reasoning, or
delegation mechanics by analogy. Additional harness-specific sections may be
added here as their routing conventions are established.

### Shared five-tier model ladder

Classify the task once, then select the route from the column for the active
harness. Every tier has one Codex route and one Claude route; these are
harness-local defaults, not cross-harness alternatives.

| Tier | Use for | Codex route | Claude route |
|---|---|---|---|
| 1 — bounded | Mechanical, reversible work with an exact oracle | `gpt-5.6-luna / high` | `claude-sonnet-5 (non-reasoning) / high` |
| 2 — routine judgment | Straightforward implementation, testing, and review | `gpt-5.6-luna / xhigh` | `claude-opus-5 / low` |
| 3 — substantive | Multi-step reasoning, reconciliation, and non-trivial review | `gpt-5.6-luna / max` | `claude-opus-5 / medium` |
| 4 — complex | Ambiguous, consequential, or cross-system work | `gpt-5.6-sol / high` | `claude-opus-5 / high` |
| 5 — frontier | Hardest quality-first work where failure is costly | `gpt-5.6-sol / xhigh` | `claude-opus-5 / xhigh` |

Apply the ladder as follows:

1. Choose the lowest tier whose task profile is adequate.
2. In a Codex harness, use only the Codex route. In a Claude harness, use only
   the Claude route.
3. Do not use the other harness's route as a fallback, and do not substitute a
   different model merely because its name or effort label sounds equivalent.
4. Treat Tier 1's Claude route as mechanical-only; use Tier 2 or higher when
   the task requires meaningful judgment.
5. Reserve `gpt-5.6-sol / max` and `claude-opus-5 / max` for an explicit
   quality escalation above Tier 5. Use them only when Tier 5 failed or the
   cost of failure justifies the extra token use, and record the reason in
   `tasks.md`.

This is benchmark-informed guidance, not a claim that model scores or effort
labels are interchangeable. Benchmark scores, pricing, model availability,
and harness controls can change; re-check the routes when those inputs change.

### Codex: Subagent Model Routing

This section applies only when the active harness is Codex. Other agent
harnesses must use their own native model, reasoning, and delegation controls
or the unlisted-harness fallback below.

When the shared ladder applies, its exact route overrides the generic model and
effort descriptions below. Use the generic descriptions only when documenting
an explicit same-harness exception or when no ladder tier applies.

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
- `medium`: balanced effort for clear tasks when a same-harness exception or
  non-ladder task calls for it; it is not a default route in the shared ladder.
- `high`: complex multi-step work, edge cases, or critical review.
- `xhigh`: difficult root-cause analysis, optimization, or integration with
  several competing hypotheses.
- `max`: reserve for the hardest quality-first task where failure is costly and
  additional latency and token use are justified.

Do not assign every task the strongest combination. Escalate only when the
task's ambiguity, consequence, or failed evidence warrants it. Reassign the
tracker row if the task becomes materially harder or simpler.

#### Codex custom-agent bootstrap

If the required presets do not exist, create `~/.codex/agents/` and add one
standalone TOML file per combination. The recommended reusable matrix is
`{luna}_{high,xhigh,max}` plus `{terra,sol}_{medium,high,xhigh,max}`. For example,
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
   `luna_high`, `terra_high`, or `sol_xhigh`. Personal custom agents live in
   `~/.codex/agents/`; project-scoped agents live in `.codex/agents/`.
4. Pass the custom agent through the tool's actual agent-role/type selector.
   A `task_name` or prose instruction does not select a model.
5. If the active spawn schema exposes neither model/effort fields nor an agent
   selector, exact routing is unavailable in that session. Do not claim
   otherwise. Restart after installing custom agents if needed, or record that
   the task used the session default.
6. When exact routing matters, verify runtime evidence shows the selected role
   and effective model/reasoning combination; keep that evidence with the task.

### Claude: Subagent Model Routing

This section applies only when the active harness is Claude. Use Claude's native
delegation and model/effort controls to select the exact Claude route from the
shared ladder. Do not apply Codex spawn fields, custom-agent TOML, or Codex
model names to a Claude task.

For each delegated tracker task, record the requested Claude model/effort
combination in `tasks.md`. If the Claude harness cannot expose or verify the
exact route, use its session default only when it is adequate, and record both
the routing limitation and the effective model/effort. Do not claim exact
routing and do not silently switch to a Codex model.

### Unlisted harness fallback

If the active harness is not covered by a section above, use appropriate
judgment to select the model, reasoning level, and skill combination that best
fits the task and the harness's native capabilities. Prefer the lowest-cost
combination that is adequate, record the selected combination in `tasks.md`,
and state when exact routing or runtime identity could not be verified. Do not
infer or apply the Codex matrix to an unlisted harness.

## Sitrep

When the user asks for a `sitrep`, report the current goal state from the canonical live tracker. Read `goal.md`, `tasks.md`, `events.jsonl`, and relevant recent evidence or handoffs before answering; do not rely on conversational memory when the durable record can resolve the state.

Use this structure:

### Tasks

- Include every tracker task exactly once, preserving tracker order. Put each task on one physical line in the form: ``- `T1` — <one or two concise sentences describing the task> — Model: `<model / reasoning>` — Status: `<status>` ``.
- Report the model/reasoning combination actually recorded for the task. If exact routing was unavailable or was changed, say so rather than inferring a model from the task type.

### Complications and changed expectations

- List every recorded blocker, complication, failed approach, unexpected issue, and material difference from the original expectation, including resolved items.
- State the consequence and current disposition: open, mitigated, superseded, accepted, or resolved. Say `None recorded` when there are none; do not invent a complication to fill the section.

### Autonomous decisions

- Explain every decision agents made without contemporaneous user direction. Name the agent/task, decision, rationale, effect on scope, design, sequencing, evidence, or risk, and whether it remains reversible.
- Use `decision.recorded` events and structured decision fields as evidence; never infer intent from an edit alone. Distinguish an autonomous decision from a user-approved decision. If there are no decision records, say `No autonomous decisions recorded`; when the ledger predates this requirement or otherwise lacks complete decision coverage, also state that the decision history is incomplete rather than implying that no autonomous decisions occurred.

### Since the last check-in

- Summarize other noteworthy progress, evidence, commits, status changes, new gaps, and the current or next gate strictly after the most recent `sitrep.reported` event and through the current report timestamp.
- If no prior sitrep is recorded, say that this is the baseline sitrep and summarize the recorded work to date.

Keep the sitrep concise but complete. Surface stale, missing, or contradictory tracker data explicitly, and update the tracker before reporting when current evidence resolves the contradiction. Before yielding the finalized report to the user, append a `sitrep.reported` event with the reporting timestamp, window start, and a compact summary so the next sitrep has a durable boundary.

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
