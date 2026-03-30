---
name: agent-native
description: >-
  Optimize codebases for agentic engineering velocity -- make projects maximally
  legible, navigable, and verifiable by AI agents. Use when: (1) auditing how
  agent-friendly a codebase is, (2) bootstrapping a new project for agent
  development, (3) evolving an existing project toward better agent support,
  (4) diagnosing why agents struggle with a codebase. Triggers: "agent-native",
  "audit this project", "make this agent-native", "why are agents struggling",
  "bootstrap for agents", "agent-friendly", "optimize for agents".
metadata:
  short-description: Optimize codebases for agentic engineering velocity
---

# Agent-Native Project Design

## Mission

Define principles, canonical structures, and tooling configurations that optimize codebases for agentic engineering velocity. Make projects maximally legible, navigable, and verifiable by AI agents so they can develop, maintain, and evolve codebases with minimal human intervention and maximal correctness.

This skill owns **project infrastructure** -- the structural properties of a codebase that make it agent-friendly. How you *work* (feedback loops, test design, spec authoring, engineering posture) belongs to companion skills. This skill owns how the *project is set up*.

---

## Foundational Framing

### Meta-Principle: Enforce Boundaries, Allow Autonomy Locally

Care deeply about boundaries, correctness, and reproducibility. Within those boundaries, allow significant freedom in how solutions are expressed. The resulting code doesn't always match human stylistic preferences -- that's fine as long as it's correct, maintainable, and legible to future agent runs. Human taste is fed back through review comments, refactoring PRs, and rule updates -- eventually promoted from documentation into lint rules and structural tests.

### Agent-Native vs Agent-Amplified

Not all principles here are uniquely agent-native. The distinction matters for prioritization:

- **Agent-specific** principles exist because of agent limitations or workflow patterns. Without them, agents degrade significantly. Examples: agent instructions as decision-making context (agents have no ambient knowledge), filesystem as API (agents navigate by listing directories), structured error output (agents parse error output to decide next actions), ephemeral environments (agents spawn parallel work streams).

- **Agent-amplified** principles are good engineering that becomes dramatically more important with agents. Examples: mechanical rule enforcement (agents drift from documentation over long sessions), quality scoring (agent-generated code accumulates entropy without active management).

The maturity tiers prioritize agent-specific principles first, then layer in agent-amplified ones.

---

## Maturity Tiers

| Tier | Name | Indicators (observable from codebase) | Principles |
|------|------|---------------------------------------|------------|
| 1 | Foundation | Any project, day one | N1, N2 |
| 2 | Structure | 2+ directories under a domain pattern, or ARCHITECTURE.md exists | N3, U3, M1, V4 |
| 3 | Scale | Worktree scripts exist, or CI config references parallel test jobs, or 3+ domain directories with cross-domain imports | M2, V5, I1, I3 |

**How tiers interact with modes:** Audit mode determines the current tier from codebase indicators above and recommends the next step -- not all principles at once. When indicators are ambiguous, default to the lower tier and let Evolve mode recommend advancement. Evolve mode uses the ratchet pattern: once a metric reaches a threshold, it can never regress. New code follows the current target tier's rules; old code migrates domain-by-domain.

**Principles in companion skills (not duplicated here):**
Feedback loop speed, test determinism, coverage policy, type safety at boundaries, layered architecture, and reversibility are important for agent-native codebases but are owned by companion skills. See [Skill Composition](#skill-composition) for routing.

---

## Principle Catalog

| ID | Name | Tier | Stage | One-liner |
|----|------|------|-------|-----------|
| N1 | Agent Instructions as Decision-Making Context | 1 | Navigate | Goals, philosophy, principles, and router in the agent instructions file |
| N2 | Cohesive, Well-Scoped Files | 1 | Navigate | One clear responsibility per file; split by cohesion, not line count |
| N3 | Filesystem as API | 2 | Navigate | Semantic paths, domain directories, explicit public APIs |
| U3 | Documentation Architecture | 2 | Understand | Progressive disclosure from agent instructions to deep docs |
| M1 | Mechanical Rule Enforcement | 2 | Modify | Encode rules as lint/CI checks, not just docs |
| M2 | Cross-Domain Communication | 3 | Modify | Explicit allowed patterns for inter-domain wiring |
| V4 | Structured Error Output | 2 | Verify | Machine-readable errors with remediation field |
| V5 | Tiered Observability | 3 | Verify | Structured logs, health endpoints, seed scripts, browser access |
| I1 | Ephemeral Environments | 3 | Iterate | Zero shared mutable state between worktrees |
| I3 | Quality Scoring | 3 | Iterate | Composite grade per domain; entropy sweeps |

For full principle specifications, read `references/principles.md`.

---

## Operational Modes

### Audit Mode

**Triggers:** "audit this project", "how agent-native is this codebase", "what should I improve"

**Process:**
1. Detect language/framework, test runner, linter, existing docs
2. Check each principle applicable to the project's current tier
3. Compute quality scores per domain (read `references/quality-rubric.md`)
4. Produce a structured report

**Output format:** `docs/audit-report.md` (or temp file if user prefers)

```markdown
# Agent-Native Audit Report

## Current Tier: [Foundation | Structure | Scale]
## Overall Grade: [A-D]

## Principle Assessment
| ID | Principle | Status | Details |
|----|-----------|--------|---------|
| N1 | Agent Instructions | PASS/FAIL/PARTIAL | ... |
| N2 | Cohesive Files | PASS/PARTIAL | 3 files with mixed responsibilities: ... |
| ... | ... | ... | ... |

## Companion Skill Checks
| Concern | Status | Recommendation |
|---------|--------|----------------|
| Feedback loop speed | ... | See feedback-loops |
| Test coverage/quality | ... | See tester |
| Type safety at boundaries | ... | See architect B4 |

## Quality Scores by Domain
| Domain | Coverage | Lint | Cohesion | Types | Docs | Dead Code | Grade |

## Recommended Next Actions (prioritized by impact/effort)
1. [action] -- [rationale] -- [effort: low/medium/high]

## Current Tier -> Next Tier Gap
[What's needed to advance to the next maturity tier]
```

---

### Bootstrap Mode

**Triggers:** "set up a new project", "make this agent-native from scratch", "scaffold"

**Process:**
1. Detect or ask for: language/framework, project type (web app, CLI, library, API), planned domains
2. Scaffold Tier 1 in priority order (MVP = steps 1-4):
   1. Create agent instructions file with project goals, philosophy, and run commands (N1)
   2. Configure linter (M1) -- read `references/tooling-profiles.md`
   3. Create ARCHITECTURE.md skeleton (U3)
   4. Create spec topology router if applicable (see spec-engineering skill)
   --- MVP complete: run Audit to verify Tier 1 compliance ---
   5. Create directory layout (N3) -- read `references/layouts.md` for ecosystem reference
   6. Create core-beliefs.md with applicable principles (M1) -- see `references/layouts.md` for format
3. For Tier 2+ (if requested): add domain directories, structural tests, enforcement rules

**Output:** Actual file changes (directory structure, configs, docs). Committed or staged for user review.

---

### Evolve Mode

**Triggers:** "what should I improve next", "make this more agent-native", "evolve toward tier 2"

**Process:**
1. Run Audit (above) to establish baseline
2. Identify current tier and the gap to the next tier
3. Prioritize changes by impact-to-effort ratio:
   - Low effort, high impact first (add agent instructions, configure linter)
   - High effort, high impact next (restructure into domains, add structural tests)
   - Low impact items deferred unless trivially easy
4. Produce a diff of recommended changes, prioritized and sequenced
5. Apply changes with user approval gates

**Ratchet rules:**
- Once coverage reaches a threshold, the CI config is updated to enforce it -- never goes back down
- Once a lint rule is enabled, it stays enabled
- Once a domain is restructured, new code in that domain must follow the new structure
- Old code migrates domain-by-domain, not all at once

**Output:** Actual file changes (config updates, new lint rules, doc scaffolding, structural tests). Each change is a separate commit with clear rationale. Read `references/quality-rubric.md` for scoring methodology.

---

### Diagnose Mode

**Triggers:** "my agents keep failing at X", "why is the agent struggling", "agents are slow"

**Process:**
1. Ask what symptoms the user observes
2. Map symptoms to principles or companion skills:
   - "Opens wrong files, can't find things" → Navigate (check N1, N2, N3)
   - "Misunderstands architecture" → Understand (check U3) + architect skill
   - "Breaks things non-obviously" → Modify (check M1, M2) + tester skill T7
   - "Can't tell if change is correct" → Verify (check V4) + feedback-loops + tester
   - "Slow iteration" → feedback-loops (feedback loop speed) + I1 (environments)
   - "Poor test quality" → tester skill
   - "Entropy / quality drift" → I3 (quality scoring)
3. Run targeted checks for the identified stage (read relevant principles from `references/principles.md`)
4. Recommend specific fixes

**Output:** Targeted report with diagnosis and recommended actions.

---

## Skill Composition

This skill is invoked periodically for project-level structural work, not on every task. Day-to-day feature work uses the companion skills.

| Skill | Relationship | When to Invoke |
|-------|-------------|----------------|
| **architect** | Complementary. Architect = how to think while working. Agent-native = how to structure the project. Architect routes to agent-native for project structure decisions. | Architect routes here; agent-native for audit/bootstrap/evolve |
| **spec-engineering** | Complementary. Agent-native defines physical doc structure (N1, U3). Spec-engineering defines navigation protocol and spec authoring patterns. The agent instructions file is the shared entry point. | Spec-engineering for navigating/authoring docs; agent-native for creating/auditing doc structure |
| **feedback-loops** | Complementary. Signal-per-token owns feedback loop design methodology. Agent-native provides the structural enablers (V4 structured errors, V5 observability). | Signal-per-token for individual change efficiency; agent-native for project-wide infrastructure |
| **tester** | Complementary. Tester owns test design methodology (T1-T11). Agent-native provides structural enforcement (M1 mechanical rules, I3 quality ratchet). Tester T7 (architectural invariant tests) is the mechanism; M1 is the escalation ladder. | Tester for writing tests; agent-native for test infrastructure policy |
| **terminal-velocity** | Downstream. Terminal-velocity's parallel worktree lanes assume the isolation described in I1. Agent-native Audit could serve as prerequisite check. | Run agent-native audit before terminal-velocity parallel execution |

### Principles in Companion Skills

These concerns are important for agent-native codebases but are owned by companion skills to avoid duplication:

| Concern | Companion Skill | Principle/Section |
|---------|----------------|-------------------|
| Feedback loop speed | feedback-loops | Section 1 (early, incremental checks) |
| Test determinism | feedback-loops | Section 3 (determinism) |
| Coverage policy | tester | T11 (test pyramid discipline) |
| Type safety at boundaries | architect | B4 (type safety) |
| Layered architecture | architect | B6 (orthogonality) |
| Reversibility | architect | B11 (reversibility) |

---

## Reference Files

Read these files on-demand based on the current mode and task:

| File | When to Read |
|------|-------------|
| `references/principles.md` | When applying a specific principle (look up by ID from the catalog above) |
| `references/quality-rubric.md` | In Audit or Evolve mode, when computing or interpreting quality scores |
| `references/tooling-profiles.md` | In Bootstrap mode, or when configuring lint/CI enforcement for a specific language |
| `references/layouts.md` | In Bootstrap mode, or when applying N3 (Filesystem as API) or U3 (Documentation Architecture) |
