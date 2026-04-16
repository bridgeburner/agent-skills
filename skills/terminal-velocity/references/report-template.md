# Final Report Template

Template for the Phase 7 report. The orchestrator generates two artifacts:
1. `final_report.md` — structured markdown in the run directory (data source)
2. A visual HTML page via the `visual-explainer` skill (presentation layer)

---

## Markdown report template

```markdown
# Terminal Velocity — Final Report

**Run ID:** {RUN_ID}
**Date:** {date}
**Goal:** {one-line goal from Phase 0}
**Entry mode:** {FROM_PLAN | FROM_CHECKLIST | AUTONOMOUS}

---

## 0. Reviewer's guide

### Where to focus
- {Highest-risk area and why — e.g., "The auth middleware changes touch the trust boundary between API and database. Review the input validation carefully."}
- {Second-highest-risk area and why}

### What NOT to worry about
- {Areas with high confidence and why — e.g., "The utility functions have 100% branch coverage and were reviewed by both models."}

### Deployment notes
- {Migration steps, if any}
- {Environment variable changes, if any}
- {Rollback procedure, if applicable}
- {Feature flags or gradual rollout considerations}

---

## 1. What changed

What behavior, features, or capabilities were added or modified.

For each change, include:
- **What**: one-line description of the change
- **Why**: what user need or plan item it addresses
- **Where**: files/modules touched
- **Scope**: new feature / enhancement / bugfix / refactor

### Summary table
| Change | Type | Files | Lane |
|--------|------|-------|------|
| {description} | new / enhanced / fixed / refactored | {file list} | {lane_name} |

### Checklist completion
- Total items: {N}
- Completed: {N}
- Skipped/deferred: {N} (see Section 4)

---

## 2. How we know it works

Evidence that the changes are correct: what was tested, why those tests are the right ones, and what quality checks passed.

### Tests
For each test area, explain **why this test matters** — not just pass/fail, but what it proves.

| Test | What it proves | Command | Result |
|------|---------------|---------|--------|
| {test name/scope} | {what correctness property this validates} | `{command}` | PASS / FAIL |

### Quality checks
| Tool | Command | Result |
|------|---------|--------|
| {linter} | `{lint_command}` | PASS / FAIL |
| {typechecker} | `{typecheck_command}` | PASS / FAIL |

### File audit
- Files changed: {N}
- Expected: {list}
- Unexpected: {list or "none"}

### Test strategy coverage
Cross-reference the approved `test_strategy.md` against implemented tests:

| Strategy item | Test level | Implemented? | Test file/name | Notes |
|---------------|-----------|-------------|----------------|-------|
| {what it tests} | integration / E2E / invariant | YES / NO / PARTIAL | `{test file}` | {any deviations or notes} |

- **Planned:** {N} tests in strategy
- **Implemented:** {N}
- **Missing/partial:** {N} (with rationale)

### Confidence assessment
Brief statement: what is well-covered, and where is residual risk (areas not fully testable, integration boundaries, etc.).

---

## 3. Design decisions

Choices agents made autonomously where the plan or checklist was underspecified. These are choices within the plan's latitude — they do not contradict any registered plan constraint.

### Strategic decisions
Decisions that materially affect the outcome or constrain future work.

| Decision | Rationale | Alternatives considered | Impact | Worker |
|----------|-----------|------------------------|--------|--------|
| {what} | {why} | {options} | {how this shapes the outcome} | {lane} |

### Tactical decisions
Implementation-level choices that don't materially change the overall outcome.

| Decision | Rationale | Worker |
|----------|-----------|--------|
| {what} | {why} | {lane} |

---

## 3b. Plan deviations

Places where the implementation diverged from explicit plan constraints. Sourced from PLAN_OVERRIDE findings in the findings tracker. These are not design decisions — they are acknowledged scope reductions or constraint violations.

If there are no PLAN_OVERRIDE findings, state "None — implementation honored all registered plan constraints" and omit the table.

| Constraint ID | Constraint text | What was done instead | Justification | Consequences |
|---|---|---|---|---|
| {PC-N} | {verbatim from constraint registry} | {what actually happened} | {why the constraint could not be honored} | {downstream impact} |

---

## 4. Interesting insights

Non-obvious observations from the implementation process: unexpected complexity, surprising interactions, patterns discovered in the codebase, things that worked better or worse than expected.

- {insight}

---

## 5. Learnings

Takeaways that improve future iterations — of this project, this type of feature, or this workflow.

### Project-specific
- {learning about this specific codebase or domain}

### Feature-type patterns
- {learning applicable to similar features in any project}

### Workflow improvements
- {learning about the terminal-velocity process itself}

---

## 6. Skill adherence

### Iteration counts
| Phase | Prescribed | Actual | Notes |
|-------|-----------|--------|-------|
| P1: Plan Review | reviews={N} | {actual} | {early convergence, user override, etc.} |
| P2: Test Strategy | reviews={N} | {actual} | — |
| P5: Refine | refines={N} | {actual} | — |

### Agent topology per phase
| Phase | Iteration | Prescribed Agents | Actual Agents | Deviations |
|-------|-----------|-------------------|---------------|------------|
| P1 | each iter | 4 review (2 Claude + 2 Codex) | {actual} | {None or explanation} |
| P2 | each iter | 1 gen + 2 review (1 Claude + 1 Codex) | {actual} | {None or explanation} |
| P3 | — | 1 gen + 2 review (1 Claude + 1 Codex) | {actual} | {None or explanation} |
| P4 | — | {N lanes, max 4 concurrent} | {actual} | {None or explanation} |
| P5 | each iter | 4 review (2 Claude + 2 Codex) | {actual} | {None or explanation} |

### Deviations
{List any deviations from prescribed topology with explanation. If fully adherent, state "None — all phases followed prescribed agent topology."}

---

## Appendix

### Commit list
| Hash | Message | Scope |
|------|---------|-------|
| `{short_hash}` | {commit message} | {files or lane} |

### Open risks and deferred items
| Item | Source | Severity | Deferral rationale |
|------|--------|----------|--------------------|
| {description} | {Phase 4 iter N} | should-fix / nice-to-have | {why deferred} |

### Artifacts
All artifacts are in `.agents/terminal-velocity/runs/{RUN_ID}/`:
- `plan_final.md` — approved plan
- `test_strategy.md` — approved test strategy
- `test_strategy_review.md` — test strategy review findings
- `checklist_final.md` — execution checklist
- `impl_*_report.md` — per-lane implementation reports
- `refine_iter*_report.md` — refinement iteration reports
- `recommended_actions.md` — triage output
- `verify_report.md` — verification results
- `final_report.md` — this report
```

---

## Visual report

After generating `final_report.md`, invoke the `visual-explainer` skill to produce a visual HTML page.

### Explainer brief

```
Generate a visual HTML report from the final_report.md at {run_dir}/final_report.md.

Requirements:
- Dark theme only (no light theme toggle)
- Dashboard-style layout
- Sections map to the report sections:
  0. Reviewer's guide — prominent callout boxes for focus areas, safe areas, and deployment notes
  1. What changed — cards or tiles per change, grouped by type
  2. How we know it works — test results as status indicators, confidence callout
  3. Design decisions — two-tier display: strategic (prominent) vs tactical (collapsible)
  3b. Plan deviations — amber/warning cards for PLAN_OVERRIDE items (omit section if none)
  4. Interesting insights — highlighted callouts
  5. Learnings — grouped by category (project / feature-type / workflow)
  6. Skill adherence — compact compliance checklist with pass/fail indicators per phase
- Appendix items (commits, deferred items, artifacts) in collapsible sections
- Hero section with run ID, date, goal, and key stats (items completed, tests passed, decisions made)

Write to: {run_dir}/report.html
```

### Design guidance for the visual page
- **Hero/KPI bar**: run ID, date, goal, completion stats (items done / total, tests pass rate)
- **Reviewer's guide**: prominent callout boxes — "Where to focus" in amber/warning style, "What NOT to worry about" in green/safe style, "Deployment notes" in blue/info style. This section should appear first and be visually distinct to catch the reviewer's eye immediately.
- **What changed**: card grid — one card per change, color-coded by type (new=green accent, fix=amber, refactor=blue)
- **How we know it works**: status table with colored indicators + a confidence callout box
- **Design decisions**: strategic tier shown as prominent cards, tactical tier collapsed under `<details>`
- **Plan deviations**: if any PLAN_OVERRIDE findings exist, render as amber/warning cards with constraint ID, what was overridden, and consequences. Visually distinct from design decisions — these are acknowledged deviations, not choices
- **Insights**: styled blockquote callouts
- **Learnings**: three-column grid grouped by category
- **Skill adherence**: compact compliance checklist — each phase shown as a row with pass/fail indicator (green check or red X) comparing prescribed vs actual iteration counts and agent topology. Deviations highlighted inline. This should read as a quick audit: "did the orchestrator follow the skill?"
- **Appendix**: all in `<details>/<summary>` — commits table, deferred items, artifact list

---

## Usage notes

- Replace all `{placeholders}` with actual values from the run
- Omit sections with no content (e.g., no insights, no deferred items)
- Keep the markdown report factual — the visual layer handles presentation
- The visual report reads from `final_report.md` — generate markdown first, then HTML
- Learnings should be concrete and actionable, not vague platitudes
