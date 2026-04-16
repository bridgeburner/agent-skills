# Agent Prompt Contract

Template for all worker subagents spawned during Terminal Velocity implementation lanes (Phase 4) and fix lanes (Phase 5).

Copy and adapt this contract when constructing the prompt for each worker subagent.

---

## Contract Template

```markdown
# Worker Contract: {lane_name}

## Your scope
You own these files and responsibilities:
{list of files and/or modules this worker is responsible for}

## Awareness
Other workers are making changes to other files in parallel.
- Do NOT touch files outside your scope
- Do NOT modify shared configuration files unless explicitly assigned
- If you discover a dependency outside your scope, document it in your report — do not edit it

## Assigned tasks
Complete these checklist items in order:
{numbered list of checklist items for this lane}

## Context
Read these files before starting:
- Approved plan: {plan_path}
- Constraint registry: {constraint_registry_path} (plan constraints that are binding — do not stub or omit work that would violate a PROHIBITION or REQUIREMENT)
- Test strategy: {test_strategy_path} (context on WHY test items exist and what seams they target)
- Constraint taxonomy: {constraints_path} (if available — MUST/NEVER/ASK FIRST rules from specs)

## Test strategy context
{For test lanes: paste the relevant TS-ID entries. For implementation lanes: paste the relevant MUST/NEVER constraints verbatim.}

## Verification commands
These were detected during project setup. Use them directly — no need to rediscover.
- Run tests: `{test_command}`
- Lint: `{lint_command}`
- Type check: `{typecheck_command}`

Run the smallest relevant check after each meaningful edit: format → lint → typecheck → unit tests → integration.

## TDD requirement
For every task:
1. **RED:** Write a failing test that defines the expected behavior
2. **GREEN:** Write the minimum implementation to make the test pass
3. **VERIFY:** Run the scoped test suite and confirm all tests pass

If you cannot write a meaningful test for a task, explain why in your report.

## Design principles
Apply these when making implementation decisions:
- **ETC (Easier to Change):** Prefer designs that keep future options open
- **Tracer bullets:** Get an end-to-end thin slice working first, then fill in
- **Good-enough design:** Favor reversible decisions over perfect ones
- **Orthogonality:** Minimize coupling between components

## Output
Write these files to the run directory (`{run_dir}`):

### {lane_name}_report.md (detailed)
- **Files created or modified** — explicit list of every file path touched (the orchestrator uses this for commit staging)
- **Tasks completed** — for each: what was done, tests written, verification results
- **Tasks skipped or blocked** — with reasons
- **Design decisions taken autonomously** — what you decided, why, alternatives considered
- **Dependencies discovered** — files outside your scope that your changes depend on
- **Verification results** — exact commands run, pass/fail, relevant output

### {lane_name}_summary.md (brief)
3–5 bullets: what was implemented, test coverage added, key decisions, blockers or risks.

## Companion skills
Invoke these as appropriate:
- **tester**: for checklist items tagged as integration or E2E tests (items from `test_strategy.md`)
- **spec-engineering**: if you need to understand unfamiliar code (MODE=ORIENT or MODE=ANSWER)

## Rules
- Do NOT commit. The orchestrator handles commits.
- Do NOT modify files outside your scope.
- Do NOT skip TDD. If a test is genuinely impossible, explain why.
- DO surface all autonomous design decisions in your report.
- DO run verification commands and record exact output.
- ALL output files MUST be written to the run directory, not /tmp/ or elsewhere.
```

---

## Adaptation notes

When constructing worker prompts from this template:

1. **Replace all `{placeholders}`** with concrete values from the run context
2. **Scope precisely:** list exact file paths, not vague module names
3. **Include the plan:** attach or reference the approved plan for broader context
4. **Fill verification commands:** use the actual commands detected in Phase 0
5. **Fill test strategy context:** for test lanes, paste specific TS-ID entries; for implementation lanes, paste relevant MUST/NEVER constraints verbatim
6. **For Codex workers:** wrap this contract in a codex-cli prompt file. The contract content goes in the Instructions section.
7. **For fix lanes (Phase 5):** replace "Assigned tasks" with specific must-fix items from `recommended_actions.md`
