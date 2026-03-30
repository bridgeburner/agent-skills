# Story Decomposition Methodology

How to decompose a product spec and design doc into implementation stories organized by phase and stream. Stories are the unit of work that execution tools consume — beads (`bd create -f`) for tracking and dependency management, terminal-velocity for agent orchestration.

The spec-engineering skill owns the decomposition thinking. Execution tracking (status, parallelization, verification cadence) belongs to the tools that consume the stories.

For the stories template, see [`spec-templates.md`](spec-templates.md).

---

## Story Format

Stories follow a consistent structure that is both human-readable and importable by `bd create -f`:

```markdown
#### P1-S03: Implement workstation acquire and release activities

| Field | Value |
|-------|-------|
| **Type** | feature |
| **Priority** | P1 |
| **Dependencies** | P1-S01 |

**Description**: The core locking mechanism for workstation allocation. `acquire_workstation`
uses `FOR UPDATE SKIP LOCKED` with tag/property filtering. `release_workstation` unlocks and
calls daemon cleanup. These are Temporal activities.

**Acceptance Criteria**:
- [ ] `acquire_workstation` activity returns `Optional[WorkstationLock]` or `None`
- [ ] SQL uses `FOR UPDATE SKIP LOCKED` with tag array containment
- [ ] `release_workstation` calls cleanup on daemon, then marks workstation `available`
- [ ] Activities use `ActivityRLSSession(organization_id)` for DB access
- [ ] Unit tests verify acquire, release, and concurrent acquisition
```

### Story ID Convention

`P<phase>-S<seq>` — e.g., P1-S01, P1-S02, P2-S04. Phase prefix makes cross-phase dependencies visually obvious. Within a phase, sequence numbers are assigned by stream order but don't imply execution order — dependencies govern that.

Epics use `P<phase>-E<seq>` — e.g., P1-E01. One epic per phase as the parent for all stories in that phase.

### Story Fields

| Field | Required | Purpose |
|-------|----------|---------|
| **Type** | Yes | `epic`, `feature`, `task`, `bug`, `chore` — maps to beads issue types |
| **Priority** | Yes | `P0`-`P4` — maps to beads priority |
| **Dependencies** | Yes | Other story IDs this story is blocked by, or `None` |
| **Existing bead** | If exists | Reference to an existing bead (avoids duplicates on import) |
| **Description** | Yes | What this story delivers and why. Enough context for an agent to implement it without reading the full spec. |
| **Acceptance criteria** | Yes | Checkboxes. Each is independently verifiable. Together they define "done." |

### What Makes Good Acceptance Criteria

Each criterion should be:
- **Verifiable by an agent**: "RLS policy enforces org-scoped access" is testable. "Code is clean" is not.
- **Specific about the mechanism**: "Uses `FOR UPDATE SKIP LOCKED`" not "handles concurrency."
- **Inclusive of error cases**: not just happy path. "Returns 404 if directory does not exist (idempotent)."
- **Self-contained**: doesn't require reading another story to understand what's expected.
- **Traceable to spec requirements**: criteria should map back to R# requirements, even if not explicitly tagged.

---

## Story Sizing

Each story should be completable by a single agent in a single context window, producing a committable and testable increment.

### Sizing Signals

| Signal | Too Large | Right Size | Too Small |
|--------|-----------|------------|-----------|
| Files touched | >5 files across multiple modules | 1-4 files in a cohesive area | Sub-file edit ("add import") |
| Acceptance criteria | >10 criteria, multiple concerns | 3-8 criteria, one concern | 1 trivial criterion |
| Description | Requires multiple paragraphs with sub-sections | 1-2 paragraphs | Single sentence |
| Agent behavior | Produces placeholders, forgets constraints | Completes fully in one session | Trivial, not worth tracking |
| Dependency fan-in | Blocked by 5+ stories | Blocked by 0-3 stories | N/A |

### Signs a Story Needs Splitting

- Description covers multiple unrelated concerns (e.g., "implement model AND add API endpoints AND write tests")
- Acceptance criteria span different architectural layers with no cohesion
- An agent would need to read >60% of its context window just to understand the story + relevant spec sections + code
- The story has both "build the thing" and "wire the thing in" — those are usually separate stories

### Splitting Strategies

- **By architectural layer**: model + migration as one story, service as another, router as another. Preferred for foundational work.
- **By feature slice**: one R# per story, cutting through all layers. Preferred for feature work where integration risk matters.
- **By concern**: happy path as one story, error handling as another, observability as another. Preferred for hardening phases.
- **By file ownership**: stories that share files must be sequenced via dependencies. Stories with disjoint files can parallelize naturally.

---

## Dependency Identification

### Four Dependency Types

| Type | Description | Example |
|------|-------------|---------|
| **Data** | Story needs a table/column/schema created by another story | Migration (P1-S01) before Model (P1-S02) |
| **Interface** | Story needs an API shape, type, or protocol defined by another story | Transport abstraction (P1-S15a) before activities that use it |
| **Resource** | Stories modify the same files or shared infrastructure | Two stories editing the same module — sequence them |
| **Knowledge** | Story benefits from understanding gained in a spike or exploration | Soft — note in description, don't encode as dependency |

### Dependency Rules

- Data, interface, and resource dependencies are hard — encode in the Dependencies field
- Knowledge dependencies are soft — mention in the description ("uses patterns established in P1-S01")
- Stories with no dependencies form the parallelization frontier — beads swarm identifies these automatically
- Minimize cross-phase dependencies. If P2-S04 depends on P1-S01, the phase boundary must account for that

---

## Phase Structure

### Phase Format

Each phase has a goal and a set of stories organized into streams:

```markdown
## Phase 1 — Single Workstation E2E

**Goal**: Wire up the full pipeline with stubs at PLM and orchestrator boundaries.
Retire integration risk. Single workstation, serial execution.

---

### Stream 1: Workstation Service

#### P1-S01: Create workstation database model and migration
...

#### P1-S02: Implement workstation CRUD service and admin API
...

### Stream 2: Daemon Endpoints

#### P1-S05: Add file upload endpoint to daemon-rs
...
```

### Phase Boundary Criteria

Split into a new phase when any of these apply:

| # | Trigger | Description |
|---|---------|-------------|
| 1 | **Deployment required** | Phase N must be deployed before Phase N+1 can start |
| 2 | **Risk profile change** | Phase shifts from stubs to real implementations, or from known to uncertain work |
| 3 | **Shippable increment** | Phase delivers demonstrable, testable value independently |
| 4 | **External dependency** | Phase waits on hardware, third-party access, or another team |
| 5 | **Scope boundary** | Phase maps to a distinct milestone or deadline |

Do NOT split phases arbitrarily. Each boundary should satisfy at least one criterion above.

### Streams Within Phases

Streams group stories by functional area or component. Stories within a stream are often sequentially dependent. Stories across streams can often parallelize. The stream structure makes parallelization opportunities visible without explicit DAG notation — beads swarm handles the actual scheduling.

Name streams after what they deliver, not what layer they touch:
- "Workstation Service" not "Database Layer"
- "Daemon Endpoints" not "Rust Code"
- "Drawing Execution Workflow" not "Temporal Activities"

### Common Phasing Patterns

| Pattern | When to Use | Structure |
|---------|-------------|-----------|
| **Stubs-first** (recommended for new systems) | Novel architecture, integration risk | P1: Stubs + E2E wiring -> P2: Real implementations -> P3: Polish + hardening |
| **Expand-and-contract** | Migrations with live traffic | P1: Add new alongside old -> P2: Migrate consumers -> P3: Remove old |
| **Feature-flag-driven** | Risky features, gradual rollout | P1: Flag + inert code -> P2: Build behind flag -> P3: Gradual rollout -> P4: Flag removal |
| **Walking skeleton** | High uncertainty | P0: Thinnest E2E path -> P1-N: Widen each area |

---

## Sequencing Strategy

Within and across phases, sequence stories by these priorities (in order):

1. **Risk-first.** Stories where the approach is uncertain come before stories where it's known. Spikes and walking skeletons are always early. Shape Up's "uphill before downhill" principle.
2. **Data-layer-first.** Within a phase: migrations and models before services, services before API. Foundation before structure.
3. **Integration-points-early.** If two components must work together, build one thin slice through both before widening either. Integration bugs found late are expensive.
4. **Critical-path-aware.** The longest dependency chain determines minimum duration. Stories not on it have float and are parallelization candidates.

---

## Re-Planning Signals

### When to Stop and Re-Plan

| Signal | Action |
|--------|--------|
| A story's implementation reveals architectural mismatch with design | Stop. Update design doc. Re-decompose affected phase. |
| New requirement surfaces mid-implementation | Add stories, update spec, re-assess dependencies |
| A dependency was wrong (story can proceed without it, or needs a new one) | Update dependencies in beads |
| A phase's scope has grown >50% beyond original stories | The phase boundary was wrong — split it |
| Multiple stories are blocked on the same unplanned prerequisite | Extract the prerequisite as a new story, add dependencies |

### When to Push Through

- Minor issues discoverable by lint or type checking
- Documentation gaps that can be backfilled
- Non-blocking suggestions from code review
- Cosmetic improvements that don't affect acceptance criteria

---

## Sources

- Morpheos drawing pipeline stories (production exemplar of this pattern)
- Pocock (aihero.dev): vertical slices, `/prd-to-issues` decomposition skill
- Shape Up (basecamp.com/shapeup): uphill/downhill work, phase boundaries, scoping
- HumanLayer RPI (humanlayer.dev): context utilization targets for agent-sized tasks
- Huntley (ghuntley.com/specs/): one file per concern, specs formed through conversation
