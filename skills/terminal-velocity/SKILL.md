---
name: terminal-velocity
description: >-
  Orchestrated multi-agent development workflow. Coordinates Claude and
  Codex subagents through parallel implementation lanes, critique loops,
  and structured reporting — all with TDD discipline.
  Use when: (1) non-trivial features spanning multiple files or modules,
  (2) complex refactors where a plan or checklist already exists,
  (3) work that benefits from parallel implementation lanes,
  (4) tasks where automated critique loops add value over single-pass.
  Do NOT use for simple fixes, single-file edits, when no plan exists yet,
  or when the task is to create/write a plan (use spec-engineering instead).
  Triggers: "terminal velocity", "orchestrate implementation",
  "parallel lanes", "deep implement", "full workflow".
metadata:
  short-description: Orchestrated parallel development with critique loops
---

# Terminal Velocity

Orchestrate multi-agent implementation of a prepared plan through parallel lanes with TDD discipline, automated critique loops, and structured reporting. The orchestrator coordinates Claude and Codex subagents to maximize throughput while maintaining quality through review gates.

***

## Entry modes

Phase 0 always runs first.

| Mode | Trigger | Behavior |
|------|---------|----------|
| **AUTONOMOUS** (default) | User provides a plan | P0–P7 with no user gates. Review phases run `reviews` iterations (default 3) with auto-resolution of findings. |
| **FROM_PLAN** (interactive) | User says "interactive", "with checkpoints", "review with me" | Same phases, but P1 and P2 block on user approval before proceeding. |
| **FROM_CHECKLIST** | User provides ordered tasks / checkboxes | Skip P1–P3, start at P4 after P0. |

### Iteration parameters

```
/terminal-velocity reviews=2 refines=1 workers=4
```

| Parameter | Controls | Default | Range |
|-----------|----------|---------|-------|
| `reviews` | Review-fix iterations for P1 and P2 | 3 | 1–5 |
| `refines` | Refinement iterations in P5 | 2 | 1–3 |
| `workers` | Max concurrent implementation/fix lane workers | 6 | 1–8 |

In AUTONOMOUS mode, `reviews` is a hard cap — iterations may exit early on convergence (see Phase 1). In interactive mode, `reviews` is the maximum before escalating to the user.

Echo parameters back: "Running with reviews=3, refines=2, workers=6 (defaults)."

***

## Skill composition

| Skill | Where used | What to expect |
|---|---|---|
| **tester** | P2 test strategy generation, P4 workers (integration/E2E items) | Test design guidance; workers follow its workflows |
| **architect** | P1 review agents apply these principles: **ETC** (easier to change), **tracer bullets** (end-to-end thin slice first), **good-enough** (reversible decisions over perfect ones), **orthogonality** (minimize coupling) | Principles are inlined in review briefs — agents do not need to load the full skill |
| **spec-engineering** | P0 discovery (MODE=ORIENT), P4 workers (MODE=CHANGE if specs need updating) | Repo orientation and spec maintenance |
| **codex-cli** | All phases where Codex agents are spawned | Structured invocation of headless Codex agents |
| **visual-explainer** | P7 visual report | Dark-theme HTML dashboard from markdown |
| **feedback-loops** | P6 verification | Full verification loop design (not needed by P4 workers — they receive oracle commands directly from Phase 0 discovery) |

***

## Task tracking

Track every phase, agent spawn, and checklist item via `TaskCreate`/`TaskUpdate`. The task list survives context compaction — it is the recovery mechanism.

- **Phases** as parent tasks: `P0: Initialize`, `P1: Plan Review`, etc.
- **Agent spawns** within phases: `P1: Claude alignment review`
- **Checklist items** during implementation: mirror the checklist exactly
- **Fix lanes** during refinement: `P5/iter1/fix: Missing null check`
- Use `addBlockedBy` for phase ordering and intra-lane sequencing

**Recovery:** On compaction or restart, `TaskList` → read run directory path from P0 task → resume from last incomplete task.

***

## Phase 0: Initialize

Gather context, detect entry mode, set up the run.

### Discovery

Gather these inputs — in interactive mode, ask the user directly; in AUTONOMOUS mode, extract from the provided plan and only ask if critical information cannot be inferred:
1. What is the goal? (one sentence)
2. Where is the plan or checklist?
3. Target scope? (files, modules, directories)
4. Constraints? (no breaking changes, test framework, time budget)
5. Autonomy preference? (interactive or autonomous)

Auto-detect from the project: language(s), framework(s), test runner commands, lint/format tools, existing specs (`.sdd/`, `.tv/`, `docs/`, `specs/`), git state.

### Codex availability check

Run `which codex` (or equivalent). If Codex CLI is available, all phases use Codex agents as prescribed — this is non-negotiable. If unavailable, warn the user prominently:

> "Codex CLI not found. Substituting with Claude agents using a contrarian prompt. Install Codex for genuine independent-model perspective — this fallback is a degraded mode."

Log the detection result. When in fallback mode, substitute each prescribed Codex agent with a Claude subagent whose system prompt emphasizes devil's-advocate critique: challenge assumptions, find counterexamples, question necessity.

### Input classification

Classify the user's artifact:
- **Execution plan** (verification checklist, deployment ordering, concrete steps) → proceed
- **Design doc** (architecture decisions, no execution ordering) → suggest `spec-engineering MODE=AUTHOR` first
- **Product spec** (requirements, no design decisions) → suggest `spec-engineering MODE=AUTHOR` first

When a three-document topology is detected (spec + design + plan), surface all three to review agents — the constraint taxonomy (MUST/NEVER) and testable requirements (Given/When/Then) are high-value grounding.

### Run directory

```
.agents/terminal-velocity/runs/<YYYYMMDD-HHMMSS>/
├── plan_review_report.md      (P1)
├── plan_final.md              (P1)
├── test_strategy.md           (P2)
├── test_strategy_review.md    (P2)
├── checklist_final.md         (P3)
├── checklist_review_report.md (P3)
├── impl_<lane>_report.md      (P4, per lane)
├── impl_<lane>_summary.md     (P4, per lane)
├── refine_iter<N>_report.md   (P5, per iteration)
├── recommended_actions.md     (P5)
├── verify_report.md           (P6)
└── final_report.md            (P7)
```

Create phase tasks, set dependencies, include run directory path in P0 description.

***

## Phase 1: Plan Review

**Input:** plan draft. **Output:** `plan_final.md`, `plan_review_report.md`.

### Review topology — 4 agents per iteration

Each iteration spawns 4 review agents in parallel — 2 Claude subagents and 2 Codex agents. The Codex agents provide an independent model perspective that Claude cannot substitute for, which is why they exist. Both Codex agents are spawned via the `codex-cli` skill.

| # | Model | Review angles |
|---|-------|--------------|
| 1 | Claude | Alignment + Elegance + UX **combined with** Design Issues + Constraint Verification |
| 2 | Claude | Security + Trust Boundary **combined with** Performance + Operational Readiness |
| 3 | Codex | Same brief as #1 |
| 4 | Codex | Same brief as #2 |

Each agent receives the full review brief for its angle pair from the [review agent contract](references/review-agent-contract.md). All agents are grounded in: the plan, project principles, user prompt, and existing specs. No tunnel-vision reviews.

**Review length guidance:** Each review should be proportionate to the plan — aim for 30–50% of the plan's line count. Depth should match complexity, not fill a template.

### Consolidation

The orchestrator reads all 4 reports and produces `plan_review_report.md`:
- Agreement points (multiple agents flagged)
- Unique findings (one agent only)
- Contradictions (agents disagree — flag for resolution)
- Prioritized recommendations

Supporting-doc gaps (findings that belong in the spec, not the plan) get a `SUPPORTING_DOC_GAP` tag — surfaced as recommendations but not counted as plan defects.

### Findings tracker

Every finding gets a tracking ID (`F1`, `F2`, ...) and severity (must-fix / should-fix / nice-to-have). No finding may silently disappear between iterations. See the [findings tracker protocol](references/findings-tracker.md) for the full state machine and iteration rules.

### Interactive mode

The user approves, requests changes, or rejects. All must-fix items must be RESOLVED, DEFERRED, or DOWNGRADED before approval — no OPEN must-fix items.

### Autonomous mode

Runs up to `reviews` iterations with no user gates. The orchestrator auto-accepts all findings and applies them to the plan.

**Early convergence:** If an iteration produces zero must-fix findings AND zero new should-fix findings, remaining iterations are skipped. This applies from iteration 1 onward — a clean first pass means the plan is solid and verification iterations add no value. Log convergence rationale to the run directory.

Auto-resolution follows the quality rules in the [findings tracker protocol](references/findings-tracker.md) — resolutions must be as specific as findings, and "too complex" is not valid deferral.

After the final iteration, save `plan_final.md` and proceed.

***

## Phase 2: Test Strategy

**Input:** `plan_final.md`, `plan_review_report.md`. **Output:** `test_strategy.md`, `test_strategy_review.md`.

### Generation

A Claude subagent produces the test strategy by invoking the `tester` skill (classification: New Feature, starting at T1):

1. **Extract testable requirements** from the spec (Given/When/Then → candidate tests, mapped to unit/integration/E2E)
2. **Map integration seams** — cross-component boundaries needing integration tests
3. **Identify critical user journeys** for E2E coverage (happy path, error path, edge cases)
4. **Enumerate architectural invariants** — ordering guarantees, uniqueness, idempotency, state machine rules
5. **Determine test pyramid shape** with rationale for deviations

Derive tests from Phase 1 findings: RESOLVED findings need regression tests, DEFERRED findings need monitoring tests, security findings need negative tests.

Each test entry: Test ID (TS-N), what it tests, origin (technique or finding ID), test level, target seam/journey, key assertions, suggested file path, modules under test.

### Review — 2 agents

1. **Claude subagent:** Are the right seams covered? Critical paths missing? Test levels appropriate?
2. **Codex agent:** Independent review. Spawned via `codex-cli`.

### Mode behavior

Same pattern as Phase 1 — interactive mode blocks on user approval, autonomous mode runs up to `reviews` iterations with early convergence.

***

## Phase 3: Checklist

**Input:** `plan_final.md`, `test_strategy.md`, `plan_review_report.md`. **Output:** `checklist_final.md`, `checklist_review_report.md`.

A Claude subagent converts the plan into an execution-ordered checklist:
1. Enforce single-context-window task sizing (split oversized items)
2. Attach TDD contract per task: RED → GREEN → VERIFY
3. Identify file ownership per task
4. Flag file overlaps (these cannot run in parallel)
5. Include integration/E2E tests from `test_strategy.md` as first-class items
6. Create documentation tasks for DEFERRED findings

### Review — 2 agents

1. **Claude subagent (alignment):** Does the checklist faithfully cover the plan and test strategy?
2. **Codex agent (alignment):** Independent alignment check. Spawned via `codex-cli`.

### Mode behavior

In interactive mode, present the checklist for user approval before proceeding to P4. In AUTONOMOUS mode, proceed directly after review.

### FROM_CHECKLIST adaptation

In FROM_CHECKLIST mode, P1–P3 are skipped entirely. The user's checklist is used as `checklist_final.md`. P4 workers receive the user's original checklist as their context document in place of the approved plan; `test_strategy.md` is not available and test-related placeholders in the agent contract are omitted.

***

## Phase 4: Implement

**Input:** `checklist_final.md`. **Output:** per-lane reports and summaries.

### Lane assignment

Group checklist items into independent lanes with no file overlap. Items sharing files go in the same lane, executed sequentially — overlap is transitive (if A and B share a file, and B and C share a different file, all three go in the same lane). Maximum `workers` concurrent workers. Integration/E2E tests crossing lane boundaries go in a dedicated test lane that runs after its dependencies complete.

The overlap rule applies to write conflicts, not read/import dependencies.

### Worker execution

Each worker receives the [agent contract](references/agent-contract.md) with:
- Its assigned checklist items (in order)
- The approved plan for context
- `test_strategy.md` for test intent
- **Phase 0 discovery results** — test commands, lint commands, type-check commands (workers use these directly for verification, no need to re-discover)
- Constraint taxonomy (MUST/NEVER) when a three-document topology exists

Each worker follows TDD: RED (failing test) → GREEN (implement) → VERIFY (tests pass). No exceptions — if a test is genuinely impossible, the worker explains why in its report.

### After each lane completes

1. Verify tests pass for that lane's scope
2. Review the lane summary
3. **Commit immediately** — one logical commit per lane, only that lane's files staged. Do not wait for other lanes.
4. Mark checklist tasks completed

If overlap is detected: pause the later lane, read both reports, re-scope, respawn. If a worker fails entirely (crash, timeout, no output), retry once. If the retry also fails, mark the lane's tasks as blocked, note the gap, and continue with other lanes.

***

## Phase 5: Refine

**Input:** implemented code. **Hard limit:** `refines` iterations (default 2).

### Each iteration — 4 agents

| # | Model | Focus |
|---|-------|-------|
| 1 | Claude | Alignment: implementation vs plan, specs, principles |
| 2 | Claude | Code review: bugs, regressions, missing tests, security |
| 3 | Codex | Independent alignment perspective |
| 4 | Codex | Independent code review perspective |

All agents grounded in the plan, test strategy, and findings registry. In FROM_CHECKLIST mode, P5 agents ground in the user's original checklist and the implemented code; test strategy and findings registry references are omitted.

### Findings

P5 findings are one-shot per iteration — they do not carry tracking IDs across iterations like P1 findings. Each iteration's triage starts fresh because the fixes are code-level (verifiable by re-running tests), not plan-level.

### Triage

Deduplicate findings, then classify:

**Must-fix** (real issues blocking shipping): correctness bugs, security vulnerabilities, test failures, performance regressions on critical paths, API contract violations, data integrity issues, constraint violations.

**Defer** (preferences, not blockers): style opinions, "while we're here" refactors, speculative abstractions, nice-to-have logging, alternative approaches that aren't demonstrably better.

Write `recommended_actions.md` with must-fix items only.

### Fix lanes

Turn must-fix items into fix lanes (max `workers` workers), same TDD discipline as Phase 4. After each fix: verify tests, **commit immediately** (one commit per fix), mark tasks completed.

### Convergence

If iteration 1 produces zero must-fix items, skip remaining iterations. After the final iteration, report remaining items and proceed regardless.

***

## Phase 6: Verify

Confirm correctness before reporting.

1. **Targeted tests** for changed areas (full suite only if fast)
2. **Quality checks** — auto-detected tools (ruff, mypy, eslint, cargo clippy, etc.)
3. **File audit** — `git diff --name-only` against base, flag unexpected changes
4. **Artifact audit** — all expected files exist in the run directory
5. **Test strategy compliance** — every test in `test_strategy.md` has a corresponding implementation

Output: `verify_report.md` with pass/fail per check and exact commands.

***

## Phase 7: Report

Generate `final_report.md` using the [report template](references/report-template.md), then invoke the `visual-explainer` skill for a dark-theme HTML dashboard.

The report covers: what changed, how we know it works, design decisions (strategic vs tactical), insights, and learnings. Appendix: commits, deferred items, artifacts.

For deferred must-fix items, offer to create GitHub issues (`gh issue create`). In AUTONOMOUS mode, auto-create them.

***

## Agent contracts

- **Workers** (P4, P5 fix lanes): [agent-contract.md](references/agent-contract.md)
- **Reviewers** (P1, P2, P3, P5): [review-agent-contract.md](references/review-agent-contract.md)

Read the relevant contract when constructing agent prompts.

***

## Commit discipline

See [commit-discipline.md](references/commit-discipline.md) for the full protocol. The key principle: **each commit is one logical unit of work.** Commit after each lane (P4) or each fix (P5). Never batch multiple lanes into one commit.

***

## Rules

These are the authoritative constraints. Phase descriptions above provide context — these resolve ambiguity.

1. **Codex agents are non-negotiable.** When Codex CLI is available, every prescribed Codex agent must be spawned. The independent model perspective is the reason this workflow exists as more than a single-agent loop. When Codex is unavailable, the fallback (contrarian Claude) runs automatically — but it is degraded mode, not equivalent. If a Codex agent fails to spawn, retry once, then proceed with available reports and note the gap.
2. **P1 and P5 use 4 review agents per iteration** (2 Claude + 2 Codex, combined angle pairs). P2 and P3 use 2 review agents (1 Claude + 1 Codex). These topologies are fixed.
3. **All final artifacts to the run directory.** Every report, summary, and review output belongs in `.agents/terminal-velocity/runs/<RUN_ID>/`. Transient invocation files (codex-cli prompt/schema files in `/tmp/`) are fine — but the orchestrator must copy Codex output into the run directory after retrieval.
4. **TDD is the contract.** RED → GREEN → VERIFY for every implementation task. Workers that skip tests are failing the contract.
5. **No file overlap between parallel lanes.** If detected, stop and re-scope.
6. **Max `workers` concurrent workers** (default 6). Implementation or fix lanes.
7. **Granular commits throughout.** One commit per lane or fix. See [commit discipline](references/commit-discipline.md).
8. **Findings never disappear.** Every finding gets a tracking ID and disposition. See [findings tracker](references/findings-tracker.md).
9. **Task tracking is mandatory.** Every phase, spawn, and checklist item is tracked. This is the crash recovery mechanism.
10. **No plan creation.** This skill receives plans — it does not write them.
11. **Subagents only.** Use the Task tool. No TeamCreate, no persistent teammates.
12. **Design decisions documented.** Every worker report includes autonomous decisions with rationale.
