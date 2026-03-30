---
name: spec-engineering
description: >-
  Spec authoring, codebase navigation, and story decomposition skill. Use when:
  "write a spec", "design this feature", "plan the implementation",
  "break this into tasks", "break this into stories", "create execution plan",
  "understand the codebase", "explore the architecture", "where is X defined",
  "how does Y work", "implement a feature", "fix a bug", "refactor code",
  "make changes safely", "update specs after changes", "how should I build this",
  or "what's the right approach". Also use when navigating an unfamiliar codebase,
  deciding whether a code change requires spec updates, or decomposing a designed
  feature into implementation stories for agent execution. Provides structured
  ORIENT/ANSWER/CHANGE/AUTHOR/PLAN workflows for specification authoring, story
  decomposition, efficient repository navigation with progressive disclosure,
  and minimal spec updates.
---

# Spec Engineering

## Mission

Enable reliable, low-token, low-regression work by:
1. **Spec authoring** (three-doc topology, constraint taxonomy, testable requirements)
2. **Progressive disclosure** (router → minimal docs → code)
3. **Spec updates by impact only**

Treat repo topology as guidance, not a requirement. Adapt to what exists.

### Reference files (load on demand, not upfront)

| Reference | Load when |
|-----------|-----------|
| [`references/agent-principles.md`](references/agent-principles.md) | Authoring or reviewing any spec document (MODE=AUTHOR, MODE=PLAN) |
| [`references/spec-templates.md`](references/spec-templates.md) | Creating new specs (MODE=AUTHOR) or stories (MODE=PLAN) |
| [`references/plan-methodology.md`](references/plan-methodology.md) | Decomposing a design into implementation stories (MODE=PLAN) |
| [`references/advanced-topology.md`](references/advanced-topology.md) | Project needs more structure than the Pareto 4 |

The `examples/` directory contains one example per mode (orient, answer, change, author, plan) showing the expected response shape.

---

## 0) Operating Rules (non-negotiable)

### R0 — MODE gate (choose one)
Before reading, set exactly one:
- **MODE=ORIENT**: build a map of the repo with minimal reading
- **MODE=ANSWER**: answer a specific question using minimal specs/docs/code
- **MODE=CHANGE**: make code changes safely and update specs if (and only if) required
- **MODE=AUTHOR**: create or extend specifications (product spec, design doc) for a feature
- **MODE=PLAN**: break a designed feature into implementation stories (phases, streams, dependencies)

If the user request includes "change/implement/fix/refactor/add/remove", default **MODE=CHANGE**.
If it includes "write spec/design/document the feature", default **MODE=AUTHOR**.
If it includes "break into tasks/create plan/execution plan/task breakdown/plan the implementation", default **MODE=PLAN**.
If it includes "understand/architecture/where is/how does", default **MODE=ORIENT**.
If it includes a single concrete question, default **MODE=ANSWER**.

### R1 — Progressive disclosure caps
- Start from a **router/index** doc if one exists. This saves tokens — the router tells you where to look so you don't read irrelevant files.
- Read the **minimum** needed to answer or verify in code/tests.

### R2 — Trust and staleness discipline
For any claim affecting correctness, compatibility, security, performance, or availability:
- Verify via **code, tests, configs, or runtime behavior**; treat docs without freshness signals as stale. Specs drift from reality — code is the ground truth.

### R3 — Spec updates are gated by impact
Do **not** update specs "just in case". Unnecessary spec churn creates merge conflicts and erodes trust in the documents.
Only update specs when the **Impact Classifier** (Section 4) triggers.

### R4 — Response guidance
Include these elements in responses (adapt format to context, not mandatory structure):
- **Answer / Plan**: what you found or propose
- **Consulted**: files/docs/code opened
- **Verification**: what was checked / commands to run
- **Spec impact**: update needed? which files? why?
- **Confidence**: High/Medium/Low (+ why)

### R5 — Agent-consumable writing
When authoring or reviewing any spec document, apply the principles in [`references/agent-principles.md`](references/agent-principles.md). Key: number everything (P1), tables over prose (P3), inline verification (P5), machine-parseable structure (P11), spec quality as primary lever (P12).

---

## 1) Router Discovery (topology-agnostic)

### 1.1 Find the project's spec router entrypoint
Search in this priority order (stop at first good hit):
1. `specs/INDEX.md`, `specs/README.md`, `specs/index.md`
2. `docs/README.md`, `docs/architecture/README.md`, `docs/architecture.md`
3. `ARCHITECTURE.md`, `DESIGN.md`, `CONTRIBUTING.md`
4. top-level `README.md` sections: "Architecture", "Design", "Docs", "Development"
5. repo-level agent instructions: `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`

If multiple exist, prefer the one that **acts like a router** (links outward, describes where things live). If no router exists, treat top-level README + code layout as the temporary router.

### 1.2 The Pareto Topology Baseline (guidance, not requirement)
If these four can be identified, the result is the "Pareto 4":
1. **Router/Map**: where things live + pointers
2. **Architecture Overview**: system shape + invariants/boundaries
3. **Interfaces/Contracts**: APIs/events/schemas + compatibility
4. **Workflows**: dev/test/build/deploy + validation

If the repo has a different naming scheme, map the nearest equivalents.

---

## 2) MODE=ORIENT protocol (build a map cheaply)

1. Find the router entrypoint (Section 1).
2. Read the minimum docs to answer: components, flows, invariants/boundaries, workflows.
3. If interfaces/contracts exist, read the minimal relevant summary.

Output: repo map, Pareto entrypoints, commands (run/test/lint/build).

---

## 3) MODE=ANSWER protocol (answer surgically)

1. Identify the question type (architecture, interface, workflow, behavior, ownership).
2. Use the router to select candidate docs/files.
3. If an implementation exists, verify in code (types, routes, schemas, configs).

---

## 4) MODE=CHANGE protocol (make changes + keep specs correct)

### 4.1 Pre-change: establish the validation loop
Before coding, identify:
- the smallest validating tests
- where behavior is defined (paths, key modules)
- whether public contracts/invariants are impacted

### 4.2 Impact Classifier (strict gate)
Given intended change and/or diff, classify impact:

**A) Interface / Contract impact (triggers spec update)**
Public APIs/schemas/auth, events, DB schema/migrations, CLI flags/outputs, versioning.

**B) Invariant / Trust boundary impact (triggers spec update)**
AuthZ/authN, permissions, data boundaries, consistency/transactions, rate limits/retries/idempotency/ordering, performance budgets/SLOs, safety constraints.

**C) Workflow / Ops impact (triggers spec update)**
Build/test/run/deploy, env vars/secrets/config, oncall/runbook, observability changes.

**D) Internal-only refactor (does NOT trigger spec update by default)**
No external behavior/contract change (refactor, naming, formatting, local perf without budget changes).

### 4.3 Minimal spec update selection
If the classifier triggers, update only the relevant docs. Avoid touching unrelated spec topology.

### 4.4 Post-change: verification and reporting
Run the smallest validating tests. Ensure spec changes match implementation.

---

## 4.5) MODE=PLAN protocol (decompose design into implementation stories)

### When to invoke
- A product spec and design doc exist (or are being authored alongside)
- User asks to "plan the implementation", "break this into stories/tasks", "create an execution plan"
- Downstream consumers: beads (`bd create -f`) for tracking, terminal-velocity for agent orchestration

### 4.5.1 Prerequisites
1. Confirm product spec exists (requirements R#, API contracts, state machine)
2. Confirm design doc exists (data model, constraints C#/N#, design decisions D#, file organization)
3. If either is missing or incomplete, switch to MODE=AUTHOR first

### 4.5.2 Story Decomposition
1. Identify implementation phases using phase boundary criteria (see [`references/plan-methodology.md`](references/plan-methodology.md))
2. Within each phase, identify streams (parallel functional areas)
3. Decompose each stream into stories using `P<phase>-S<seq>` format
4. Size stories so each is completable in a single agent context window
5. Write descriptions with enough context for independent implementation
6. Write acceptance criteria that are specific, verifiable, and include error cases
7. Identify dependencies between stories (data, interface, resource, knowledge)
8. Add a phase-level epic with acceptance criteria for each phase

### 4.5.3 Quality Checklist
Before delivering the stories, verify:
- [ ] Every R# in the spec is covered by acceptance criteria across stories
- [ ] Every story has a description sufficient for an agent to implement without reading the full spec
- [ ] Acceptance criteria are verifiable (an agent can test each one)
- [ ] Dependencies form a DAG (no cycles)
- [ ] Stories are agent-sized (completable in one context window)
- [ ] Story format is importable by `bd create -f`

Output: implementation stories document following the template in [`references/spec-templates.md`](references/spec-templates.md).

---

## 5) MODE=AUTHOR protocol (create or extend specifications)

### When to invoke
- Starting a feature without specs
- User asks to "write a spec", "design this", "plan the implementation"
- A ticket/PRD/requirement exists but no structured spec documents

### 5.1 Detect existing layout
Before creating files, check what already exists:
1. Run Router Discovery (Section 1) -- is there an existing spec layout?
2. If specs exist in any layout (even unconventional), **follow the existing conventions**. Write new specs where existing specs live, using the same naming patterns.
3. If no specs exist, propose the canonical layout (Section 6).

### 5.2 The Three-Document Topology

Every non-trivial feature should have up to three documents. Use judgment on how many:

| Documents | When |
|-----------|------|
| **1 doc** (design only) | Clear requirements, moderate complexity, no migration concerns |
| **2 docs** (spec + design) | Complex requirements OR significant architecture decisions |
| **3 docs** (spec + design + plan) | Multi-step migration, deployment ordering, verification matrix, multiple reviewers |

**Document roles:**

| Document | Answers | Key Sections |
|----------|---------|-------------|
| **Product Spec** | "What should this do and why?" | Problem, Goals/Non-Goals, Glossary, Requirements (Given/When/Then), API contracts, State machine |
| **Design Doc** | "How should I build it?" | Architecture, Data model, Workflow implementation, Constraints (MUST/NEVER/ASK FIRST), Design decisions with rationale |
| **Implementation Stories** | "In what order, and how do I prove it works?" | Phases, Streams, Stories (P#-S##), Dependencies, Acceptance criteria, Known limitations |

Cross-reference between documents. Each doc links to the others at the top:
```markdown
> **Related documents:**
> - [Product Spec](feature_spec.md)
> - [Design Doc](feature_design.md)
> - [Implementation Stories](feature_plan.md)
```

For detailed section templates, see [`references/spec-templates.md`](references/spec-templates.md). For agent-consumable writing principles, see [`references/agent-principles.md`](references/agent-principles.md). For story decomposition methodology, see [`references/plan-methodology.md`](references/plan-methodology.md).

### 5.3 The Constraint Taxonomy

Design docs MUST include a constraints section with three tiers. This is the single highest-leverage pattern for preventing agent mistakes.

**MUST** (always, no exceptions):
```markdown
| # | Constraint |
|---|-----------|
| C1 | All child records MUST copy organization_id from parent. |
```

**ASK FIRST** (requires human approval):
```markdown
| # | Constraint |
|---|-----------|
| A1 | Adding new Python dependencies beyond pyproject.toml. |
```

**NEVER** (hard prohibition -- always include "Correct Approach"):
```markdown
| # | Constraint | Correct Approach |
|---|-----------|-----------------|
| N1 | Service methods MUST NEVER call commit() directly | Use get_db/get_rls_db dependency injection |
```

The three-tier pattern maps directly to agent behavior:
- MUST → agent verifies after every change
- ASK FIRST → agent stops and asks before proceeding
- NEVER → agent must not generate code that violates; the "Correct Approach" column tells it what to do instead

### 5.4 Testable Requirements (Given/When/Then)

Requirements in the product spec should be independently verifiable. Each requirement gets a number and a Given/When/Then:

```markdown
**R1. Single-part creation.**
- GIVEN a project with 'drawing' in enabled_views
- WHEN a user POSTs a valid DrawingRequestCreate to /drawings
- THEN a DrawingRequest row is created with status = 'creating'...
```

This format:
- Is mechanically convertible to test cases (bridges to tester skill T1)
- Makes coverage gaps visible (each R# should have at least one test)
- Eliminates ambiguity about expected behavior

### 5.5 Design Decisions with Rationale

Number design decisions and include rationale. This prevents agents from "improving" intentional choices:

```markdown
| ID | Decision | Rationale |
|----|---------|-----------|
| D1 | Phase transitions are coarse-grained, not individual tool steps | Meaningful UX without coupling to internals |
| D2 | No retry on execution failure | Avoids state cleanup complexity |
```

### 5.6 Spec Index / Router Maintenance

When authoring specs, maintain a router at `specs/INDEX.md`:

```markdown
# Spec Index

| Feature | Status | Spec | Design | Plan |
|---------|--------|------|--------|------|
| 2D Drawing | In Progress | [spec](drawing/spec.md) | [design](drawing/design.md) | [plan](drawing/plan.md) |
| Tool Registry | Shipped | [spec](tool_registry_spec.md) | -- | -- |
```

If the project has an existing router (README, ARCHITECTURE.md), add links there instead.

---

## 6) Canonical Layout

### For new repos or features (recommended default)

```
specs/
  INDEX.md                          # Router: feature inventory
  <feature-name>/                   # Feature directory
    spec.md                         # Product specification
    design.md                       # Design document
    plan.md                         # Execution plan
```

Alternative (flat, for smaller repos or when matching existing conventions):
```
specs/
  INDEX.md
  <feature>_spec.md
  <feature>_design.md
  <feature>_plan.md
```

### Why `specs/` not `docs/`

`specs/` contains specification documents -- the source of truth for what to build and how.
`docs/` contains general documentation -- guides, runbooks, onboarding, API references.
Different purpose, different audience. Specs are consumed by implementing agents. Docs are consumed by everyone.

A repo can have both. Neither is mandatory for the other.

---

## 7) Legacy Interop

### Principle: adapt to what exists, never force restructuring

| Scenario | Navigation | Authoring | Migration |
|----------|-----------|-----------|-----------|
| **No specs exist** | MODE=ORIENT infers from code (Section 2) | MODE=AUTHOR proposes canonical layout | Start with INDEX.md |
| **Specs in different layout** (`docs/design/`, flat PRDs, etc.) | Topology-agnostic discovery (Section 1) | Follow existing conventions -- write where specs already live, match naming patterns | Opt-in and gradual (see below) |
| **Specs in canonical layout** | Works naturally | Works naturally | Already done |

### Gradual migration path (opt-in, never blocking)

When the user wants to adopt the canonical layout in an existing repo:

1. **Phase 0: Add a router.** Create `specs/INDEX.md` that points to existing docs wherever they live. This is a net addition -- nothing moves, nothing breaks.
2. **Phase 1: Adopt the constraint taxonomy.** Add MUST/NEVER/ASK FIRST sections to existing design docs in-place. The content pattern works regardless of file location.
3. **Phase 2: Restructure on rewrite.** When a spec is due for a rewrite (outdated, major version change), write the new version in the canonical layout. Update the router. Old specs can remain as historical artifacts or be archived.

Never block work on migration. The three-doc pattern and constraint taxonomy are valuable in ANY file layout.

---

## 8) Deeper topology (when projects need more structure)

See [`references/advanced-topology.md`](references/advanced-topology.md) for Component Cards, ADRs, Ops Runbooks, SLOs, or split Interfaces.

---

## 9) Fallback behavior (no router, no specs)

If the repo lacks any spec topology:
1. Use top-level README as the temporary router.
2. Infer the Pareto 4 from code (entrypoints, routes/schemas/migrations, workflows).
3. For non-trivial changes, propose a minimal router + workflows doc (do not block progress).

---

## 10) Skill Composition

| Skill | Relationship | When |
|-------|-------------|------|
| **architect** | Upstream. Architect identifies mode; spec-engineering is invoked in Building mode (author/navigate) and Debugging mode (answer/orient). | Architect routes here |
| **tester** | Downstream. Given/When/Then requirements (Section 5.4) feed directly into tester T1 (Spec-First Assertions). Constraint taxonomy feeds T7 (Architectural Invariant Tests). | After authoring, when writing tests |
| **feedback-loops** | Complementary. Signal-per-token guides the feedback loop; spec-engineering ensures the spec exists to derive tests from. | Parallel concern during implementation |
| **agent-native** | Complementary. Agent-native defines doc structure requirements (N1 AGENTS.md, U3 Doc Architecture). Spec-engineering defines navigation protocol over it and authoring content patterns. | Agent-native for structure; spec-engineering for content |
| **terminal-velocity** | Downstream. MODE=PLAN produces implementation stories that terminal-velocity consumes for orchestrated implementation. Stories are also importable by beads (`bd create -f`) for tracking and dependency management. | After planning, when orchestrating parallel implementation |
