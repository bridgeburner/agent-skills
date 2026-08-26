---
name: architect
description: "Engineering posture and execution discipline. Use at the start of any non-trivial task to identify Building, Exploratory, or Debugging/Triage mode; choose a prototype, spike, or tracer bullet; set proof and smoke-test expectations; and route to specs, durable tracking, or testing references only when needed."
---

# Architect

Engineering is not one activity. Applying the wrong principles to the wrong mode is one of the most common sources of wasted effort and poor decisions.

Identify your mode first. Then apply the principles for that mode, keep the feedback loop tight, and route to companion skills or references only when they add concrete value.

---

## Step 1: Identify Your Mode

Read the task carefully and ask: **what kind of work is this?**

### Building
**Signals:**
- You have a spec, ticket, or clear task description
- Success is a defined artifact ("implement X", "add feature Y", "build Z")
- You know what done looks like before you start

**→ Apply Building principles.** Rigor, correctness, and clean design are the right levers.

---

### Exploratory
**Signals:**
- Goal is knowledge, not a deliverable
- "Understand how X works", "Is Y feasible?", "Spike on Z", "Prototype this idea"
- Success criteria are fuzzy — you'll know when you've learned enough
- No clear spec for what you're building yet

**→ Apply Exploratory principles.** Maximize learning per unit of time. Do not apply construction-phase rigor.

---

### Debugging / Triage
**Signals:**
- You have a specific symptom: error message, failing test, unexpected behavior, performance regression
- Something is broken and you need to find out why
- "Fix this bug", "Why is X happening?", "Tests are failing", "What should I tackle first?"
- Triage ("what's wrong here?") is the same mode — a symptom-first, evidence-driven posture

**→ Apply Debugging principles.** Scientific method, not intuition.

---

### Ambiguous cases
- **"Implement X" but X is poorly specified** → treat as Exploratory first; switch to Building once the design is clear
- **Bug in an unfamiliar system** → Exploratory to understand the system, then Debugging to isolate the cause
- **Architectural change with unknowns** → Exploratory spike first, Building for implementation

---

## Skill Routing

After identifying your mode, invoke only the relevant companion skills:

### Building Mode
1. Read the relevant router/docs/code with progressive disclosure; do not bulk-load the repo.
2. State the positive end-to-end outcome and any failure that must not move to a later boundary or widen in scope.
3. If the change alters accepted states, adds or reinterprets a sentinel/fallback, retains source-authored data, shares durable state across versions, or makes a broad data-flow claim, read `references/semantic-change.md` and pass its design gate before coding.
4. Establish the proof path: the smallest cheap oracle for each edit, plus a tracer that carries the exact production representation through every first-order consumer to the final observable outcome and measures failure radius.
5. Build the thinnest production-quality tracer bullet before widening implementation.
6. Update specs/docs only when public contracts, data retention, invariants, rollout behavior, workflows, or operating procedures changed.
7. Before handoff, pass the semantic-change implementation gate when it applies, then carry the outcome, evidence, gaps, and issue identity into the repository's public-decision format without broadening claims.
8. Read `references/testing.md` only for deep test-suite design, regression-test design, mock/fixture concerns, harness gaps, or "why did tests miss this bug?" Semantic changes crossing independently maintained producer/consumer boundaries automatically require its T8 and T12 guidance.

### Exploratory Mode
1. Build a repo map cheaply: find the router, then read only docs/code needed for the question.
2. If the problem is stateful, empirical, and under-specified, prefer an interactive probe surface (REPL/notebook/shell) over script-only exploration (see E7)
3. Build the thinnest vertical slice (tracer bullet — see E5)
4. Record what the probe proved and what smoke/e2e path would validate a real implementation.

### Debugging Mode
1. Find the smallest relevant docs/code path using the repo router, README, architecture docs, and agent instructions.
2. Reproduce the symptom, shrink it, and run one targeted oracle per hypothesis.
3. Read `references/testing.md` only if you need regression-test design, mock/fixture analysis, harness-gap handling, or test-suite review.

---

## Feedback and Proof Discipline

Run the smallest useful oracle after each meaningful edit. Typical order is format, lint, typecheck/build, scoped tests, then broader integration or smoke checks. Do not accumulate a large diff and check everything at the end.

For user-facing behavior, agent behavior, integrations, workflows, deployments, or configuration-sensitive work, smoke/e2e/product-path validation is the acceptance bar. Unit tests, type checks, lint, fixtures, and narrow integration tests are supporting evidence; they do not prove the user-visible behavior by themselves.

When an ideal smoke/e2e path is unavailable, say what proof tier you reached, why the higher-fidelity path was unavailable, and what gap remains. Do not relabel lower-tier evidence as full proof.

## Conditional Semantic-Change Gate

Use `references/semantic-change.md` only when the Building route triggers it. The gate has two stops:

- **Before implementation:** reject a design if the new representation has an uninspected first-order consumer, an ambiguous final disposition or failure radius, an uncovered materially distinct state, or unexplained retention/rolling-version behavior.
- **Before completion:** reject handoff if the first-consumer tracer does not carry the exact representation to the final observable, assert both item disposition and containing-operation success, and show that the forbidden failure neither moved nor widened.

This is an architecture boundary check, not a generic PR checklist. Repository instructions own exact ticket-closing syntax and PR-template policy; Architect supplies the why, what, issue identity, claim-to-oracle evidence, and explicit gaps they need.

## Repo Orientation and Specs

Use progressive disclosure. Start from the first useful router, then read only the docs/code needed for the current question:

1. `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`
2. `README.md`, `ARCHITECTURE.md`, `DESIGN.md`, `CONTRIBUTING.md`
3. `specs/INDEX.md`, `specs/README.md`, `docs/README.md`, `docs/architecture.md`
4. Relevant routes, schemas, configs, migrations, tests, and entrypoints

Treat docs as maps, not proof. For correctness, compatibility, security, performance, or availability claims, verify against code, tests, configs, runtime behavior, or live product paths.

Only write or update specs when they reduce ambiguity for non-trivial work or when the change affects a public contract, invariant/trust boundary, workflow, operation, or validation path. Do not churn docs for internal-only refactors.

When a spec/design is needed, keep it minimal and agent-consumable:

- Number requirements and constraints.
- Use Given/When/Then for behavior.
- Capture MUST, ASK FIRST, and NEVER constraints; for NEVER, include the correct approach.
- Record design decisions with rationale when an agent might otherwise "improve" them away.
- Include acceptance checks, especially the smoke/e2e path that proves user-visible behavior.
- Follow existing repo doc layout before proposing a new one.

## Parallel Agent Guardrails

Use subagents to increase independent signal, not to front-load implementation in separate layers. Good parallel tasks include repo reconnaissance, design alternatives, root-cause hypotheses, critique, spike comparison, and independent smoke/e2e validation.

Do not split implementation into frontend/backend/data/model "lanes" before a tracer bullet exists and the smoke oracle is known. The parent agent owns synthesis, sequencing, and final proof.

Each subagent should have one question or outcome, write an audit artifact when the repo instructions require it, and report concrete failure modes rather than broad opinions.

## Testing Reference

Use `references/testing.md` as a reference, not a default process. Load it only when the task genuinely needs deeper test design: writing or reviewing substantial tests, investigating why tests missed a bug, choosing mock boundaries, designing a wiring test, or handling a missing harness.

## Meta-Principle: Easier to Change (ETC)

The principle behind good design. When choosing between designs, prefer the one that is easier to change later. Decoupled components, clear interfaces, single responsibility, and no hidden dependencies all serve ETC.

**Agent rule:** When choosing between designs, prefer the one that's easier to change later. When unsure, keep things isolated and explicit.

---

## Building Principles

### B1. One Primitive, Many Roles
Prefer one general mechanism over separate mechanisms per role. If two things look structurally similar, they should be the same thing with different configuration, not different implementations.

**Agent rule:** Before adding a new abstraction, ask: "Does something that already exists cover this case with different configuration?"

***

### B2. Prove It Works, Then Ship It
No capability is complete without a concrete test exercising a real scenario. Equally, know when to stop — ship when requirements are met, not when code is "perfect."

**Agent rule:** Before marking any task done, run proof that matches the claim. For user-facing or integration behavior, that means a smoke/e2e/product-path check whenever practical. When tempted to add "one more improvement," ask: "Does this address a stated requirement or prevent a real problem?" If not, stop.

When a change accepts a state that was previously rejected, carry the exact stored representation through its first-order consumers and prove that the forbidden failure did not move or widen.

***

### B3. Type Safety
Prefer structured typed contracts (Pydantic, dataclasses, ADTs) over ad-hoc dicts whenever data crosses a boundary.

**Agent rule:** If data passes between functions, classes, or modules as a raw dict or tuple, replace it with a typed struct.

***

### B4. Don't Repeat Yourself
DRY is about knowledge duplication, not code duplication. Two functions can look identical but represent different knowledge — merging them creates coupling where none should exist. True violations: business rules defined in multiple places, schemas duplicated without sync, validation logic repeated across layers.

**Agent rule:** Before extracting "duplicate" code, ask: "If one changes, must the other change too?" If no, leave them separate. If yes, extract it so the rule lives in one place.

***

### B5. Orthogonality
Unrelated components must not affect each other. A change on one axis must not ripple along another.

**Agent rule:** After making a change, count the files touched. If more than expected, ask whether boundaries are drawn correctly.

***

### B6. Eliminate Accidental Complexity
Separate complexity intrinsic to the problem (essential) from complexity introduced by implementation choices (accidental), and aggressively remove the latter.

**Agent rule:** When a design feels hard to explain, ask: "Is this hard because the problem is hard, or because of how I've structured the solution?"

***

### B7. State is the Enemy
Minimize mutable state; make state transitions explicit. Most bugs result from state not being what the programmer assumes.

**Agent rule:** Default to immutable data. When state must be mutable, make every transition visible and named.

***

### B8. Make Illegal States Unrepresentable
Model data so the type system makes invalid combinations impossible to construct. Eliminate whole classes of runtime validation.

**Agent rule:** When writing a validator, ask: "Can I reshape the type so this invalid case can't be constructed at all?"

***

### B9. Fail Noisily and Early
When invalid state is detected, fail immediately and loudly. A loud early failure is always cheaper than a silent late one.

**Agent rule:** Prefer exceptions over returning None or empty values for error cases. Validate at system entry points, not deep in call stacks.

***

### B10. Data Structures Determine Architecture
Get the data structures right and the algorithms become obvious. Poor data models produce complex code solving simple problems.

**Agent rule:** Before writing algorithm code, sketch the data structures. If the algorithm feels complicated, the data model is probably wrong.

***

### B11. Reversibility
Avoid irreversible decisions; abstract what might change. Wrap third-party APIs in your own interface, keep core logic independent of infrastructure, and prefer standards over proprietary formats.

**Agent rule:** When integrating an external dependency, wrap it. When making an architectural decision, ask: "How hard would this be to reverse?"

---

## Exploratory Principles

### E1. Immediate Connection to Creation
Every action must produce visible feedback without delay. Any gap between action and visible effect breaks the discovery loop.

**Agent rule:** Run or eval after every meaningful change. Don't write 50 lines without executing something.

***

### E2. See the Whole Before Naming the Parts
Make something tangible and observable before reaching for abstractions. Premature naming forecloses what you might find.

**Agent rule:** Resist creating new abstractions until you've seen at least two concrete cases of the pattern you're abstracting.

***

### E3. Start With Data, Not Abstractions
Drive exploration from concrete data instances. Let the shape of real data determine your code, not hypothesized models.

**Agent rule:** Find or create a real data sample first. Write code that processes that sample. Generalize only after the concrete case works.

***

### E4. Know When to Throw Away vs Iterate
Prototypes and tracer bullets serve different purposes. Prototypes are throwaway code to learn feasibility — they can ignore edge cases. Tracer bullets are real, thin, production-quality code that stays and proves the architecture works. Clarify which you're doing before you start.

**Agent rule:** If exploring feasibility, build a prototype and discard it. If building a feature, use a tracer bullet. Never let prototype code drift into production without a conscious rewrite.

***

### E5. Smallest Vertical Slice First (Tracer Bullet)
Prefer a thin complete path (input to visible output) over wide shallow coverage. Build a minimal end-to-end skeleton that touches all layers — this is your tracer bullet. It proves the architecture works and provides a scaffold for features.

**Agent rule:** Before building breadth, ask: "What's the thinnest path through the entire system that produces a real output?" Do that first. The slice ends at the final consumer-visible outcome, not the changed service; include the containing operation so the tracer measures failure radius.

***

### E6. Design It Twice Before Committing
Before settling on any design reached during exploration, generate at least one alternative and compare explicitly.

**Agent rule:** After the first viable design emerges, spend time articulating one alternative before building. The better choice is usually obvious once you have two options in front of you.

***

### E7. Use Interactive Probes for Stateful Empirical Spikes
For zero-to-one features and investigative spikes, an interactive REPL/notebook/shell is high leverage when the work is **stateful, empirical, and under-specified**: live domain objects matter, the next question depends on intermediate observations, and raw data needs to be inspected as it flows through transformations.

Treat the REPL as a microscope, not the artifact. Keep production-shaped objects loaded for rapid probing, then promote durable findings into importable modules, tests, replayable scripts, ledgers, and docs.

**Agent rule:** If the spike requires repeated inspection of in-memory state or real data pathologies, start with an interactive probe surface. As soon as a behavior matters, move it into versioned code with a replay command and a small oracle.

---

## Debugging / Triage Principles

### D1. Reproduce It First, Theorize Second
Do not form hypotheses until you can trigger the failure reliably. An unreproducible bug cannot be confirmed fixed.

**Agent rule:** Before reading any code, write the reproduction case. If you can't reproduce it, find out why before proceeding.

***

### D2. Shrink the Input to the Minimum
Reduce to the smallest input still triggering the bug. Every element removed narrows the search space.

**Agent rule:** After reproducing, systematically remove inputs and steps until removal breaks the reproduction. That boundary is where the bug lives.

***

### D3. One Hypothesis at a Time
Formulate a single falsifiable hypothesis, run the smallest experiment to test it, then update. Testing two simultaneously makes results unattributable.

**Agent rule:** State the hypothesis explicitly before running the test: "I believe X is causing Y because Z." Run one thing. Update belief. Repeat.

***

### D4. Confirm Assumptions Explicitly
Every "I know this works" is a hypothesis. Verify actual behavior, especially in components you believe aren't involved.

**Agent rule:** When stuck, list your assumptions about system state. Pick the one you're most confident about and verify it first — bugs often live at the boundary between what was verified and what was assumed.

***

### D5. Ask Why Five Times
When a proximate cause is found, keep asking why that condition arose until you reach something structurally fixable. A symptom fix recurs; a root fix does not.

**Agent rule:** After finding the line that's wrong, ask "why is this value wrong?" at least twice more before writing a fix.

***

### D6. Fix the Root, Not the Symptom
Resist patches that suppress the visible failure without addressing the defective state that caused it.

**Agent rule:** Before committing a fix, ask: "Does this make the system correct, or does it just make the test pass?" If only the latter, keep digging.

---

## Quick Reference

| Mode | Trigger signals | Core discipline | Start with |
|------|----------------|-----------------|------------|
| **Building** | Clear spec, known deliverable | Correctness, clean design, tracer bullet, smoke proof | router/docs if needed → proof path → tracer bullet |
| **Exploratory** | Knowledge goal, fuzzy success | Fast feedback, concrete data, live state when useful | repo map → interactive probe if stateful → tracer bullet |
| **Debugging** | Specific symptom, known breakage | Reproduce → shrink → hypothesize → verify | relevant docs/code → targeted oracle |

| Code | Principle | One-liner |
|------|-----------|-----------|
| ETC | Easier to Change | Meta-principle: prefer designs easier to change later |
| B1 | One Primitive, Many Roles | Same thing with different config, not different implementations |
| B2 | Prove It Works, Then Ship It | No capability complete without a test; no gold-plating |
| B3 | Type Safety | Typed contracts at every boundary, not raw dicts |
| B4 | Don't Repeat Yourself | Duplicate knowledge is a violation; duplicate code may not be |
| B5 | Orthogonality | Changes on one axis must not ripple along another |
| B6 | Eliminate Accidental Complexity | Remove implementation-introduced complexity aggressively |
| B7 | State is the Enemy | Minimize mutable state; name every transition |
| B8 | Make Illegal States Unrepresentable | Invalid combinations impossible to construct |
| B9 | Fail Noisily and Early | Loud early failures beat silent late ones |
| B10 | Data Structures Determine Architecture | Right data model → obvious algorithm |
| B11 | Reversibility | Abstract what might change; wrap external dependencies |
| E1 | Immediate Connection to Creation | Eval constantly; no gap between action and feedback |
| E2 | See the Whole Before Naming Parts | Tangible before abstract; premature naming forecloses discovery |
| E3 | Start With Data, Not Abstractions | Real data first; generalize after the concrete case works |
| E4 | Know When to Throw Away vs Iterate | Prototypes discard; tracer bullets stay |
| E5 | Smallest Vertical Slice (Tracer Bullet) | End-to-end thin path before breadth |
| E6 | Design It Twice Before Committing | One alternative makes the better choice obvious |
| D1 | Reproduce It First, Theorize Second | Reliable reproduction before any hypothesis |
| D2 | Shrink the Input to the Minimum | Smallest reproducing case = narrowest search space |
| D3 | One Hypothesis at a Time | State it, test it, update — never two at once |
| D4 | Confirm Assumptions Explicitly | "I know this works" is a hypothesis; verify it |
| D5 | Ask Why Five Times | Proximate cause → structural cause |
| D6 | Fix the Root, Not the Symptom | Correct system, not passing test |
