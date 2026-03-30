---
name: tester
description: >-
  Test design skill for writing tests that catch real bugs. Use when writing
  tests for new features, fixing bugs (regression tests), reviewing test
  suites, or deciding what level of test to write. Triggers: "write tests",
  "add test coverage", "why did tests miss this bug", "what tests should I
  write", "test this feature", "review test quality". Teaches spec-derived
  testing, mock boundary discipline, architectural invariant enforcement,
  and cross-component integration testing. Invoke with "/tester reflect"
  after fixing a bug to evaluate whether the skill itself should be
  strengthened based on the failure.
metadata:
  short-description: Write tests that catch real bugs, not tests that confirm them
---

# Tester

Tests exist to catch bugs before users do. A test that cannot catch a bug it was not specifically written for is theater. A test that validates the current implementation instead of the intended behavior is worse than no test -- it provides false confidence.

This skill teaches you to write tests derived from specifications and invariants, not from implementations.

---

## Step 1: Identify What You Are Testing

Before writing any test, classify the work:

### New Feature
**Signals:** Implementing from a spec, ticket, or PRD. The behavior is defined before the code exists.

**--> Start with T1 (Spec-First Assertions).** Write expected values from the specification before touching the implementation.

---

### Bug Fix
**Signals:** A bug was reported or discovered. You need a regression test.

**--> Start with T2 (Regression Test Protocol).** Reproduce the bug as a failing test first, then fix.

---

### Test Suite Review
**Signals:** Reviewing existing tests for quality, investigating why tests missed a shipped bug, improving coverage.

**--> Start with T9 (Anti-Pattern Audit).** Evaluate existing tests against the anti-pattern checklist.

---

### Convention Enforcement
**Signals:** A codebase rule exists (documented in CLAUDE.md, ADRs, or team conventions) but is only enforced by human review.

**--> Start with T7 (Architectural Invariant Tests).** Codify the convention as an automated test.

---

## Test Level Selection

Before writing a test, choose the right level. The wrong level produces coverage without confidence.

```
Is this pure logic with no external dependencies?
  --> Unit test (behavioral, not change-detector)

Does this cross a system boundary (DB, HTTP, filesystem)?
  --> Narrow integration test (one boundary at a time)

Does this involve agreement between independently-developed components?
  --> Contract test (semantic, not just structural)

Is there an invariant that must hold for ALL valid inputs?
  --> Property-based test

Is there a codebase convention that must hold across all code?
  --> Architectural invariant test

Is this a critical user journey (if broken, the product is unusable)?
  --> E2E test (minimal set, critical paths only)
```

**Agent rule:** State your test level choice and why before writing the test. If the choice feels wrong after writing, reconsider -- you may be testing the wrong thing at the wrong level.

### Bug Class to Test Level Mapping

| Bug Class | Best Test Level | Why |
|-----------|----------------|-----|
| Logic errors (off-by-one, wrong conditional) | Unit test | Isolated, fast, precise |
| Interface mismatches (wrong type, missing field) | Contract test, integration test | Each side looks correct alone |
| Data flow errors (value transformed wrong across boundary) | Integration test | Unit tests mock the boundary away |
| Configuration errors (wrong env, missing flag) | Smoke test, architectural test | No config in unit test scope |
| Convention violations (bypassed utility, direct DB commit) | Architectural invariant test | Behavioral tests can't see codebase-wide patterns |
| Semantic misunderstandings (null means "all" vs "none") | Contract test with semantic assertions | Structural checks don't catch meaning |
| State machine violations (invalid transitions) | Property-based test | Example tests only cover happy path |
| Stale mock divergence (mock returns impossible values) | Integration test against real impl | The mock IS the bug |

---

## Core Principles

### T1. Spec-First Assertions
Write the expected value from the specification, never from running the code. A test whose expected value was derived by executing the implementation and copying the output provides zero defect detection.

**Agent rule:** Before writing any assertion, ask: "Where did this expected value come from?" If the answer is "I ran the code and it returned this," the test is worthless. Derive expected values from: the spec, the ticket, domain knowledge, or mathematical identity. Write the assertion BEFORE writing setup or execution code.

**Real-world failure (Bug 3 from drawing capability):** `test_create_drawing_null_enabled_views` asserted `status_code == 404` because that is what the code returned. The specification said `null` means "all views allowed" (should be 200). The test confirmed the bug.

***

### T2. Regression Test Protocol
When fixing a bug, write the test first. The test must fail against the current (buggy) code and pass after the fix. This proves the test actually detects the bug.

**Agent rule:** For every bug fix: (1) write a test that reproduces the bug (it must fail), (2) fix the code, (3) verify the test passes. If you cannot write a failing test first, you do not understand the bug well enough to fix it. Name the test after the bug, not the fix: `test_null_enabled_views_allows_all_drawings` not `test_fix_enabled_views_check`.

***

### T3. Mock at Boundaries, Not Within Them
Mocks trade fidelity for speed. Every mock is a bet that the real thing behaves the way the mock does. Use the highest-fidelity test double available.

**Fidelity hierarchy (prefer higher):**
1. **Real implementation** -- default choice unless speed/determinism prevents it
2. **Fake** -- lightweight real behavior (in-memory DB, test clock). Must be owned and tested by the API owner.
3. **Stub** -- hard-coded return values. Use sparingly to reach specific states.
4. **Mock** (interaction verification) -- last resort. Only when state testing is impossible.

**Agent rule:** Never mock what you own. If you wrote the class, use the real thing or a fake you also own and test. Mock only at architectural boundaries (the HTTP client, not the service; the DB driver, not the repository). After writing a mock-based test, ask: "If the real implementation changed its return type, would this test still pass?" If yes, the mock is hiding a potential bug.

**Real-world failure (Bug 4 from drawing capability):** Tests overrode `get_rls_db` with an in-memory session that had no RLS policies. In production, `db.commit()` cleared `SET LOCAL` RLS context, causing all subsequent queries to fail. The test session had no RLS to clear, so the production failure mode was invisible.

***

### T4. Test Fixtures Must Reflect Production Reality
Test data that is structurally valid but semantically unrealistic creates a false sense of coverage. If your test database has no RLS policies, your test cannot catch RLS bugs. If your test server has no API proxy, your test cannot catch proxy routing bugs.

**Agent rule:** For each fixture/test double, ask: "What production behavior does this NOT reproduce?" Document the gap. If the gap covers a bug class that matters (see the mapping table above), write a separate integration test that uses a higher-fidelity environment. When a shipped bug reveals a fixture/production divergence, close the gap permanently.

**Real-world failures:** Bug 2 (frontend tests ran locally where `/api/v1/...` works directly; the k8s proxy path was never exercised). Bug 4 (test DB had no RLS policies, so commits did not break anything).

***

### T5. Behavioral Tests, Not Change-Detector Tests
Test what the code produces (outputs, state changes, side effects), not how it produces it (method calls, internal sequences). A test that breaks when you refactor internals without changing behavior is a change-detector -- it punishes good engineering.

**Agent rule:** Every assertion should be on a return value, a visible state change, or an observable side effect. Never assert that an internal method was called with specific arguments unless there is no other way to verify the behavior. The litmus test: "If I delete the implementation and rewrite it from scratch to satisfy the requirements, would this test still be valid?" If not, you are testing implementation, not behavior.

```python
# BAD: Change-detector -- tests HOW, not WHAT
def test_process_order(mock_repo, mock_notifier):
    service.process_order(order)
    mock_repo.save.assert_called_once_with(order)
    mock_notifier.send.assert_called_once_with("order_processed", order.id)

# GOOD: Behavioral -- tests WHAT the system produces
def test_fulfilled_order_is_persisted_and_customer_notified():
    order = create_order(items=[available_item])
    service.process_order(order)
    saved = repo.find_by_id(order.id)
    assert saved.status == "fulfilled"
    assert len(notifier.sent_messages) == 1
    assert notifier.sent_messages[0].type == "order_processed"
```

***

### T6. Test One Behavior Per Test
Name each test after the behavior it verifies, using the pattern: "given [context], when [action], then [expected outcome]." A test named `test_process_order` that asserts five unrelated things is five tests crammed into one -- when it fails, you do not know which behavior broke.

**Agent rule:** If a test name does not describe a specific scenario, split it. Each test should have one reason to fail. Name tests as behavior descriptions: `test_order_with_out_of_stock_item_is_backordered`, not `test_process_order`. The test name IS the specification.

***

### T7. Architectural Invariant Tests
Codebase conventions that are only enforced by human review will be violated. Write tests that inspect code structure, imports, AST, or metadata to enforce invariants mechanically.

**What to test:**
- "All API calls use `getApiBaseUrl()`, not hardcoded paths"
- "No service method calls `commit()` or `rollback()` directly"
- "All DateTime columns use `timezone=True`"
- "All list endpoints accept pagination parameters"
- "All Temporal activities are registered in `worker.py`"
- "No module in `app/` imports from `tests/`"
- "All environment variables are accessed through the settings module"

**Agent rule:** When you encounter a documented convention (in CLAUDE.md, ADRs, linter configs, or code comments saying "always do X"), check whether an architectural test enforces it. If not, write one. These tests are cheap to write and prevent entire categories of bugs. Use `ast.parse`, `inspect`, `glob`, or framework introspection to verify invariants programmatically.

**Real-world failures:** Bug 2 (no test enforced "all API calls use `getApiBaseUrl()`" -- new code silently bypassed the convention). Bug 4 (CLAUDE.md stated "service methods must NEVER call `commit()`" but no test enforced it).

```python
# Example: Enforce "no direct commit in services"
def test_services_never_call_commit():
    service_files = glob("app/**/service*.py", recursive=True)
    for filepath in service_files:
        source = Path(filepath).read_text()
        tree = ast.parse(source)
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                func = node.func
                if isinstance(func, ast.Attribute) and func.attr in ("commit", "rollback"):
                    pytest.fail(
                        f"{filepath}: calls {func.attr}() directly. "
                        f"Only DB dependencies should manage transactions."
                    )
```

***

### T8. Cross-Component Integration Seams
When data flows across multiple boundaries (UI -> Router -> State -> API -> Backend), unit testing each piece in isolation can pass while the full flow is broken. Test at the integration seams -- the handoff points between components -- using overlapping integration tests.

**The overlapping chain pattern:**
1. UI -> Router: "Clicking the tab navigates to the correct URL with all required params"
2. Router -> State: "Navigating to the URL dispatches the correct state action"
3. State -> API: "The state action calls the correct API endpoint"
4. API -> Backend: Contract test on request/response shape and semantics
5. Backend -> State: "The API response correctly populates the state"
6. State -> UI: "When the state has data, the component renders it"

Each test covers one seam. Together they form a chain where any break is caught.

**Agent rule:** When adding a feature that spans multiple components, map the data flow as a chain of boundaries. Write at least one test per boundary. If you find yourself writing an E2E test, ask: "Which specific boundary am I actually worried about?" and write a targeted integration test for that boundary instead.

**Real-world failure (Bug 1):** No integration test verified that clicking a sidebar tab preserved URL state. Unit tests mocked `onNavigate`, so the test never checked what arguments were passed or what URL resulted. The seam between "sidebar click" and "URL update" was untested.

***

### T9. Anti-Pattern Audit
When reviewing tests (yours or others'), check for these anti-patterns. Each one is a test that provides false confidence.

| Anti-Pattern | Detection Question | Fix |
|-------------|-------------------|-----|
| **Test confirms the bug** | "Did the expected value come from the spec or from running the code?" | Re-derive expected values from spec |
| **Change-detector** | "Would this test break if I refactored internals without changing behavior?" | Assert outputs, not method calls |
| **Stale mock** | "If the real implementation changed, would this test still pass?" | Use real impl or owned fake |
| **God fixture** | "Does this test create only the data it needs?" | Factory functions with minimal overrides |
| **Fixture-production divergence** | "What production behavior does this fixture NOT reproduce?" | Document and close gaps |
| **Over-mocked** | "Am I mocking something I own?" | Use real implementation |
| **Snapshot without review** | "Was the snapshot output verified against the spec when accepted?" | Review every snapshot update |
| **Hard-coded time** | "Will this test fail next year?" | Inject clock, use relative times |
| **No failure verification** | "Did I verify this test actually fails when the bug exists?" | Mutate the code, confirm red |

**Agent rule:** After writing a test suite, run through this table for every test. If a test matches any anti-pattern, fix it before considering the test complete. For existing test suites, use this table to prioritize what to fix first -- "test confirms the bug" and "fixture-production divergence" are the highest priority because they provide active false confidence.

***

### T10. Property-Based Testing for Invariants
When a function has an invariant that must hold for ALL valid inputs (not just specific examples), use property-based testing. Example-based tests are biased by the developer's imagination; property-based tests explore the input space systematically.

**Common property patterns:**
- **Round-trip:** `deserialize(serialize(x)) == x`
- **Idempotency:** `f(f(x)) == f(x)`
- **Invariant preservation:** "After any operation, balance is never negative"
- **Oracle:** "Optimized implementation matches naive implementation"
- **Hard to prove, easy to verify:** "Sorted output has same elements as input, each <= next"

**When to use:**
- Serialization/deserialization (round-trip)
- Data transformations and parsers (oracle, round-trip)
- Pagination logic (invariant preservation)
- State machines (no invalid transitions)
- Any function with a clear mathematical property

**When NOT to use:**
- UI rendering
- Simple CRUD with no complex logic
- Tests requiring slow I/O setup per case

**Agent rule:** For any function that transforms data or enforces constraints, ask: "Is there a property that must hold for ALL valid inputs?" If yes, write a property-based test using Hypothesis (Python) or fast-check (TypeScript). This is especially important for serialization, pagination, and data validation code.

```python
from hypothesis import given, strategies as st

@given(
    total=st.integers(min_value=0, max_value=10000),
    limit=st.integers(min_value=1, max_value=200),
    offset=st.integers(min_value=0, max_value=10000),
)
def test_pagination_invariants(total, limit, offset):
    result = paginate(items=range(total), limit=limit, offset=offset)
    assert len(result.items) <= limit
    assert result.total == total
    assert result.has_more == (offset + limit < total)
```

***

### T11. The Test Pyramid and When to Deviate
The default ratio is 70% unit / 20% integration / 10% E2E. But the ratio should shift based on your system's architecture and failure modes.

**Deviate toward more integration tests when:**
- Your system is primarily glue code connecting external services
- Most bugs are at integration boundaries, not in logic
- You have fast, reliable test infrastructure (in-memory DBs, Docker)

**Deviate toward more E2E tests when:**
- Critical user journeys are complex multi-step flows
- Integration between frontend and backend is the primary risk
- The system is small enough that E2E tests run in < 2 minutes

**Watch for the hourglass anti-pattern:** Many unit tests + many E2E tests + few integration tests. Teams feel covered ("we have both!") while integration bugs slip through the gap. The missing middle is where interface mismatches, serialization bugs, and data flow errors live.

**Agent rule:** After writing tests for a feature, assess the pyramid shape. If you have unit tests and E2E tests but no integration tests, you likely have a gap where the most insidious bugs live. Add at least one integration test per system boundary the feature crosses.

---

## Workflow: Writing Tests for a New Feature

1. **Read the specification.** Identify the behaviors, not the methods. Each behavior is a "given X, when Y, then Z."
2. **List the bug classes at risk** (use the mapping table). A data transformation? Property test. An API endpoint? Contract test. A service coordinating repositories? Integration test.
3. **Write assertions first.** Before any setup code, write what you expect. Derive values from the spec.
4. **Choose mock fidelity.** Default to real implementations. Only introduce mocks when speed or determinism demands it, and only at architectural boundaries.
5. **Check for conventions.** Does this feature involve any codebase conventions? If so, does an architectural test enforce them? If not, write one.
6. **Map the data flow.** If the feature crosses component boundaries, identify the seams. Write overlapping integration tests at each seam.
7. **Run the anti-pattern audit** (T9 table) on every test before considering it complete.
8. **Verify the test catches bugs.** Introduce a likely bug (wrong return value, off-by-one, missing null check). Confirm the test fails. If it does not, the test is not testing what you think.

---

## Workflow: Investigating Why Tests Missed a Shipped Bug

1. **Classify the bug** using the bug class taxonomy.
2. **Identify the test level** that should have caught it.
3. **Find the closest existing test.** Did a test exist for this behavior? If yes, why did it pass?
4. **Check for anti-patterns.** Usually one of: test confirms the bug (T1), mock hides the seam (T3), fixture diverges from production (T4), or no architectural test enforces the convention (T7).
5. **Write the missing test** that would have caught it.
6. **Close the systemic gap.** If the bug was caused by a fixture/production divergence or missing architectural test, fix the infrastructure so this class of bug cannot recur.

---

## Workflow: Test-First Implementation (TDD)

The RED→GREEN→VERIFY cycle is the default implementation discipline. It turns each unit of work into a verifiable, atomic step.

### The cycle

1. **RED — Write a failing test first.**
   - The test defines the expected behavior, derived from the spec (T1: Spec-First Assertions).
   - The test MUST fail before you write implementation code. If it passes immediately, either the behavior already exists or the test is wrong.
   - One behavior per test (T6). Name describes the scenario.

2. **GREEN — Write the minimum implementation to pass the test.**
   - Minimum means: make the test pass, nothing more. No refactoring, no optimization, no "while I'm here" improvements.
   - If you find yourself writing more code than the test demands, stop. Either the test is too broad (split it) or you are gold-plating.

3. **VERIFY — Run the scoped test suite.**
   - Confirm the new test passes AND no existing tests broke.
   - If something broke, fix it before moving on. Do not accumulate failures.

4. **Repeat.** Each behavior is one RED→GREEN→VERIFY cycle. A checklist item with 3 behaviors = 3 cycles.

**Agent rule:** Never skip the RED step. If you write implementation code before seeing a failing test, you have no proof the test detects anything. When you catch yourself coding before testing, stop, delete the implementation, write the failing test, then proceed.

### When to apply TDD

- **Always:** New feature implementation, bug fixes (reinforces T2 — failing test reproduces the bug), any checklist item with defined expected behavior.
- **Skip when:** Exploratory prototyping (you do not know what "correct" looks like yet), pure refactors with existing test coverage (tests already define correctness), infrastructure/config changes with no behavioral contract (e.g., updating a CI config).
- **When skipping, state why.** The rationale must be explicit — "I skipped TDD because..." is required in the worker report.

### Decomposing a task into testable increments

A task like "Add user preferences API endpoint" is too large for a single RED→GREEN→VERIFY cycle. Decompose:
1. Identify the distinct behaviors (e.g., "returns 200 with preferences", "returns 404 for unknown user", "validates input schema", "persists changes").
2. Order them by dependency (cannot test persistence without the basic endpoint).
3. Each behavior = one cycle. The tests accumulate; the implementation grows incrementally.

**Agent rule:** Before starting implementation, list the behaviors you will test — one per line, each a concrete "given/when/then." This list IS your implementation plan. If you cannot list the behaviors, you do not understand the feature well enough to build it.

### Relationship to other tester workflows

- **TDD is the implementation discipline** — it governs *when* you write tests relative to code.
- **T1–T11 are the test design principles** — they govern *what* tests to write and *how* to design them well.
- During RED, apply the relevant T-principles: T1 (spec-first assertions), T3 (mock boundaries), T6 (one behavior per test), T7 (architectural invariants).
- TDD does not replace the "Writing Tests for a New Feature" workflow — it complements it. Use that workflow to plan which tests to write, then use TDD to write them.

---

## Workflow: Reflect (`/tester reflect`)

A self-improvement loop for the skill itself. Invoke after fixing a bug to evaluate whether the skill's principles, anti-patterns, or workflows should be strengthened.

**When to invoke:** After discovering a bug that tests should have caught -- whether you have already fixed it or are still triaging it.

### Step 1: Gather Context

Determine the bug from whatever is available. Two entry points:

**From a fix (post-fix):**
1. Run `git diff HEAD~1..HEAD` (or a wider range if the fix spans multiple commits) to identify changed files.
2. Read the failing test(s) and the fix.
3. Identify: *What was the bug?* *What test existed (if any)?* *Why did the existing test not catch it?*

**From conversation (mid-triage):**
1. Review the conversation history for the bug description, reproduction steps, and any diagnosis so far.
2. Read the relevant source files and existing tests mentioned in the conversation.
3. Identify: *What is the bug?* *What tests exist for this area?* *Why didn't they catch it?*

If the user provides a specific commit range, file, or bug description, use that as the primary source.

### Step 2: Classify the Bug

Using the **Bug Class to Test Level Mapping** table:
1. Assign the bug a class (logic error, interface mismatch, data flow error, etc.).
2. Identify the correct test level that should have caught it.
3. Determine which principle(s) (T1-T11) are most relevant to preventing this class of failure.

### Step 3: Trace Through the Skill

For each relevant principle, ask:
- **Does the principle already cover this failure mode?** If the principle, followed correctly, would have prevented the bug -- the skill is fine; the issue was application, not coverage.
- **Is there a gap in the principle?** The principle covers the general area but misses a specific nuance exposed by this bug.
- **Is there a missing principle?** No existing principle addresses this failure mode at all.

Also check:
- Does the **Anti-Pattern Audit** (T9) have a row that would have flagged the test deficiency?
- Does the **Bug Class to Test Level Mapping** table include this bug class?
- Do the **Workflows** cover the investigation path that was actually needed?

### Step 4: Propose a Skill Edit

Based on the analysis, propose exactly ONE of:

| Finding | Proposal |
|---------|----------|
| Existing principle covers it (application gap) | No skill change needed. Report which principle should have been applied and how. |
| Principle exists but misses a nuance | Add a "Real-world failure" callout to the principle, or refine the "Agent rule" to cover the nuance. Show the exact text to add. |
| Anti-pattern table is missing a row | Add a new row to the T9 table. Show the detection question and fix. |
| Bug class table is incomplete | Add a new row to the Bug Class to Test Level Mapping. |
| No existing principle covers this | Propose a new principle (T12, T13, ...) with the same structure: description, agent rule, real-world failure callout. |
| Workflow has a gap | Add or modify a step in the relevant workflow. |

### Step 5: Present and Wait

Present the analysis to the user as a structured report:

```
## Reflect: [Bug summary in one line]

**Bug class:** [from taxonomy]
**Correct test level:** [from mapping table]
**Relevant principles:** [T1, T3, etc.]

### Analysis
[1-3 sentences: why the existing skill did or did not cover this]

### Proposed change
[Exact text to add/modify, with location in the skill file]

### No change needed?
[If the skill already covers this, explain which principle should have been applied]
```

**Do not edit the skill file until the user approves.** The user may:
- **Approve**: Apply the edit to the SKILL.md file.
- **Modify**: Adjust the proposal, then apply.
- **Reject**: No change; the skill is fine as-is.

---

## Quick Reference

| ID | Principle | One-liner |
|----|-----------|-----------|
| T1 | Spec-First Assertions | Expected values from the spec, never from running the code |
| T2 | Regression Test Protocol | Failing test first, then fix; prove the test detects the bug |
| T3 | Mock at Boundaries, Not Within | Highest fidelity double available; never mock what you own |
| T4 | Fixtures Must Reflect Production | Document and close fixture/production divergences |
| T5 | Behavioral, Not Change-Detector | Assert outputs and state, not method calls |
| T6 | One Behavior Per Test | Each test has one reason to fail; name describes the scenario |
| T7 | Architectural Invariant Tests | Codify conventions as automated tests; enforce mechanically |
| T8 | Cross-Component Integration Seams | Overlapping tests at every handoff point in the data flow |
| T9 | Anti-Pattern Audit | Run the checklist on every test before it ships |
| T10 | Property-Based Testing | Invariants for ALL inputs, not just developer-imagined examples |
| T11 | Test Pyramid Discipline | 70/20/10 default; deviate intentionally with stated rationale |

---

## Skill Composition

This skill is designed to work with these other skills:

| Skill | Relationship | When to Invoke |
|-------|-------------|----------------|
| **architect** | Upstream. Architect's mode (Building/Exploratory/Debugging) determines which tester workflows apply. Building mode triggers the "new feature" workflow; Debugging mode triggers the "regression test" workflow. | At the start of the task, before tester |
| **spec-engineering** | Complementary. Spec-engineering ensures the specification exists and is current (MODE=AUTHOR for spec creation, Given/When/Then requirements); tester derives test assertions from that specification. | When writing T1 (Spec-First Assertions) -- the spec must exist first |
| **feedback-loops** | Complementary. Signal-per-token guides what to communicate; tester ensures test names and failure messages carry maximum signal. | When naming tests and writing failure messages (T6) |
| **architect** | Upstream. DRY (B4), orthogonality (B5), and tracer bullet (E5) principles inform test design -- factory functions over god fixtures, one concern per test. | When designing test infrastructure (factories, helpers) |

---

## References

### Sources

- Google SWE Book Ch. 12-14 (Unit Testing, Test Doubles, Larger Testing)
- Google Testing Blog: "Change-Detector Tests" (2015), "Increase Test Fidelity by Avoiding Mocks" (2024), "Just Say No to More End-to-End Tests" (2015)
- Martin Fowler: "The Practical Test Pyramid" (2018), "ContractTest"
- James Shore: "Testing Without Mocks" (2023)
- Kent Beck: "Test Desiderata" (testdesiderata.com)
- matklad: "How to Test" (2021)
- Drawing capability bug analysis (4 bugs that shipped despite ~2500 passing tests)
