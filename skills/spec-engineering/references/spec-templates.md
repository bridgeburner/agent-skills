# Spec Templates

Lightweight templates for the three-document topology. These are scaffolds, not straitjackets -- adapt sections to the feature's needs. Skip sections that don't apply.

**Exemplar:** The morpheos drawing capability specs demonstrate this topology at production quality. When in doubt, follow that pattern.

For agent-consumable writing principles, see [`agent-principles.md`](agent-principles.md). For execution plan methodology (task sizing, dependencies, sequencing), see [`plan-methodology.md`](plan-methodology.md).

---

## Product Spec Template

```markdown
# <Feature Name> -- Product Spec

> **Related documents:**
> - [Design Doc](<feature>_design.md) -- Architecture, data model, constraints
> - [Execution Plan](<feature>_plan.md) -- Migration plan, verification checklist

<One paragraph summary: what this feature does, who it's for, and what problem it solves.>

## Related Specs
| Spec | Relevance |
|------|-----------|
| [Existing Spec](link) | How it relates |

## Problem
<Why this feature needs to exist. What's painful today. Quantify if possible.>

## Goals
| # | Goal |
|---|------|
| G1 | ... |

## Non-Goals
| # | Non-Goal | Notes |
|---|----------|-------|
| NG1 | ... | Why deferred, where tracked |

## Glossary
| Term | Definition |
|------|-----------|
| ... | ... |

## Requirements

Each requirement is independently verifiable via Given/When/Then.

### <Requirement Group>

**R1. <Requirement name>.**
- GIVEN <precondition>
- WHEN <action>
- THEN <expected outcome>

**R2. <Requirement name>.**
- GIVEN ...
- WHEN ...
- THEN ...

## <Domain Model / State Machine / API> (as applicable)

### State Machine (if applicable)

| From | To | Trigger | Guard |
|------|-----|---------|-------|
| ... | ... | ... | ... |

### API Contracts (if applicable)

#### Endpoint / Interface
Summary, parameters, behavior steps.

##### Error Codes
| Status | Code | Condition | Response Body |
|--------|------|-----------|---------------|
| 409 | CONFLICT | ... | `{error: "...", code: "..."}` |
| 422 | VALIDATION | ... | `{error: "...", detail: [...]}` |

### Authorization (if applicable)
| Endpoint | Minimum Role |
|----------|-------------|
| ... | ... |

## Phase 2 / Roadmap (deferred items)
| Item | Description |
|------|-------------|
| ... | ... |

## Status
<Not started | In progress | Shipped>
```

---

## Design Doc Template

```markdown
# <Feature Name> -- Design Doc

> **Related documents:**
> - [Product Spec](<feature>_spec.md) -- Requirements, API contracts
> - [Execution Plan](<feature>_plan.md) -- Migration plan, verification checklist

This document covers architectural decisions, data model, workflow implementation,
and constraints. For product requirements, see the Product Spec.

## Context / Background
<Why this design is needed now. How it fits in the larger system. Link to product spec
problem statement. No longer than 2 paragraphs + 1 diagram.>

## Architecture & System Topology

### Component Summary
| Component | Responsibility |
|-----------|---------------|
| ... | ... |

### System Topology Diagram
```
(ASCII or mermaid diagram)
```

### Data Flow (Happy Path)
```
Step  Actor    Action                    Data Store
----  -----    ------                    ----------
 1    User     ...                       -> ...
```

## <Core Implementation Section>

<The main technical content. Name this section after what it describes:
"Temporal Workflow", "Event Pipeline", "Processing Engine", etc.
Include code sketches where they clarify architecture.>

## Data Model

<Tables, schemas, relationships. Include field-level detail for non-obvious fields.>

### <Model Name>
```python
class ModelName(Base):
    ...
```

#### Field Properties
| Field | Purpose | Set By | Notes |
|-------|---------|--------|-------|

## File Organization
```
app/
  feature/
    models.py
    schemas.py
    service.py
    router.py
```

## Constraints

All rules for this feature live here. Other sections cross-reference rather than restate.

### MUST (always, no exceptions)
| # | Constraint |
|---|-----------|
| C1 | ... |

### ASK FIRST (requires human approval)
| # | Constraint |
|---|-----------|
| A1 | ... |

### NEVER
| # | Constraint | Correct Approach |
|---|-----------|-----------------|
| N1 | ... | ... |

## Design Decisions
| ID | Decision | Rationale |
|----|---------|-----------|
| D1 | ... | ... |

## Alternatives Considered
| # | Alternative | Pros | Cons | Why Rejected |
|---|-------------|------|------|--------------|
| Alt1 | ... | ... | ... | ... |

## Cross-Cutting Concerns
| Concern | Approach | Notes |
|---------|----------|-------|
| Security | ... | ... |
| Observability | ... | ... |
| Performance | ... | ... |
| Backward compatibility | ... | ... |
```

---

## Implementation Stories Template

For the methodology behind this template (story sizing, dependencies, sequencing, phasing), see [`plan-methodology.md`](plan-methodology.md).

```markdown
# <Feature Name> -- Implementation Stories

> **Source**: [<feature>_spec.md](<feature>_spec.md), [<feature>_design.md](<feature>_design.md)
> **Created**: <date>
> **Status**: Draft

---

## Phase 1 — <Name>

**Goal**: <1-2 sentences: what shippable increment this phase delivers. What risk it retires.>

---

### P1-E01: Phase 1 Epic — <Name>

| Field | Value |
|-------|-------|
| **Type** | epic |
| **Priority** | P1 |

**Description**: <What this phase delivers end-to-end. Parent for all Phase 1 stories.>

**Acceptance Criteria**:
- [ ] <Phase-level criterion 1>
- [ ] <Phase-level criterion 2>
- [ ] All Phase 1 stories completed and merged

---

### Stream 1: <Functional Area>

#### P1-S01: <Story title>

| Field | Value |
|-------|-------|
| **Type** | task |
| **Priority** | P1 |
| **Dependencies** | None |

**Description**: <What this story delivers and why. Enough context for an agent to implement
it without reading the full spec. Reference spec sections where helpful.>

**Acceptance Criteria**:
- [ ] <Specific, verifiable criterion>
- [ ] <Specific, verifiable criterion>
- [ ] <Error case or edge case criterion>

#### P1-S02: <Story title>

| Field | Value |
|-------|-------|
| **Type** | feature |
| **Priority** | P1 |
| **Dependencies** | P1-S01 |

**Description**: ...

**Acceptance Criteria**:
- [ ] ...

---

### Stream 2: <Functional Area>

#### P1-S03: <Story title>
...

---

## Phase 2 — <Name>

**Goal**: ...

(same structure as Phase 1)

---

## Known Limitations
| Limitation | Current Behavior | Future Resolution |
|-----------|-----------------|------------------|
| ... | ... | ... |
```

---

## Spec Index Template

```markdown
# Spec Index

## Active Specs
| Feature | Status | Spec | Design | Plan |
|---------|--------|------|--------|------|
| Feature A | In Progress | [spec](feature-a/spec.md) | [design](feature-a/design.md) | [plan](feature-a/plan.md) |
| Feature B | Shipped | [spec](feature-b/spec.md) | -- | -- |

## Shipped / Archived
| Feature | Shipped | Spec | Design |
|---------|---------|------|--------|
| ... | ... | ... | ... |
```

---

## Section Guidance

### What makes a good Product Spec
- Requirements are **testable**: each R# can be converted to a test case
- Requirements are **numbered** (R#): enables cross-reference from design and plan docs (see P1)
- Requirements are **behavioral, not implementational**: "only one active request per part" not "use a partial unique index"
- Requirements cover **error cases**: for every happy-path R#, a corresponding error R# (e.g., R3a success, R3b duplicate rejection)
- Non-goals are **explicit**: prevents scope creep and sets agent boundaries
- API contracts include **error code tables**: agents need to know what 409/422/404 means and when each triggers
- State machines use **table format** (`| From | To | Trigger | Guard |`): more parseable than prose or ASCII-only diagrams
- Glossary defines **every domain term**: agents have no ambient domain knowledge

### What makes a good Design Doc
- Constraints section is **complete**: every invariant that matters is listed
- NEVER constraints include **Correct Approach**: tells agents what to do instead
- Design decisions include **rationale**: prevents agents from "improving" intentional choices
- Data model includes **field-level notes**: non-obvious fields explained (who sets them, when, why)
- Cross-references to the spec: "See [Product Spec: R8](spec.md#review-workflow)" for requirement traceability
- **Alternatives Considered** is substantive: 2+ alternatives with genuine pros/cons, explicit selection rationale referencing goals
- **Cross-cutting concerns** are explicitly addressed: security, observability, performance (short sections are fine if minimal surface)
- **Context/Background** explains what changed to trigger this design

### What makes good Implementation Stories
- Stories are **agent-sized**: completable in a single context window, producing a committable increment (see [plan-methodology.md](plan-methodology.md))
- Stories are organized into **phases and streams**: phases are sequential milestones, streams are parallel tracks within a phase
- Each story has a **description with enough context** for an agent to implement without reading the full spec
- **Acceptance criteria are verifiable**: each criterion is testable by an agent, not subjective
- **Dependencies are explicit**: encoded in the Dependencies field, not implied by ordering
- Phase boundaries satisfy **at least one criterion** from the phase boundary criteria
- Stories are **importable by `bd create -f`**: metadata table + description + acceptance criteria format
- Known limitations are **explicit**: prevents agents from trying to fix deferred items
- Known limitations **link to design decisions**: "No retry -- see D2 in design doc"

### When NOT to write specs
- Simple bug fixes (just fix it)
- Minor refactors with no contract changes
- One-line configuration changes
- Anything where the code change is simpler than the spec would be
