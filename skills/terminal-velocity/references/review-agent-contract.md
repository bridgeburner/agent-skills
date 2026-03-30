# Review Agent Contract

Template for all review subagents spawned during Terminal Velocity plan review (Phase 1), test strategy review (Phase 2), checklist review (Phase 3), and refinement (Phase 5).

---

## Grounding requirement

Every review agent receives the plan (or draft), project principles/constraints, the user's goal, and relevant specs. No agent reviews in isolation.

## Review topology

Each review iteration spawns 4 agents — 2 Claude subagents and 2 Codex agents — with combined angle pairs:

| # | Model | Angles |
|---|-------|--------|
| 1 | Claude | Alignment + UX **and** Design + Constraints |
| 2 | Claude | Security + Trust **and** Performance + Ops |
| 3 | Codex | Same as #1 |
| 4 | Codex | Same as #2 |

When constructing agent prompts, combine the relevant angle briefs (below) into a single review brief. The agent covers both angles in one pass.

## Contract Template

```markdown
# Review Contract: {review_name}

## Your role
{role description — e.g., "Alignment + Design reviewer" or "Security + Performance reviewer"}

## Context
You are reviewing {what — plan draft / checklist / implementation} for {purpose}.

Read these files for grounding:
- Plan: {plan_path}
- Principles/constraints: {principles_path}
- User goal: {goal_summary}
{additional context files as needed}

## Review focus
{Paste the combined angle briefs from the sections below}

## Unresolved findings from previous iteration
{For iteration 2+: paste the full findings list. Each agent must verify whether each finding was addressed.}

## Output
Write a markdown report to `{run_dir}/{report_filename}` with:
- **Findings** — concrete issues with file/section references
- **Severity** — must-fix / should-fix / nice-to-have
- **Recommendations** — specific, actionable fixes (not vague suggestions)
- **Agreement notes** — what is well-done (brief)

## Review length
Aim for 30–50% of the artifact's line count. Depth should match complexity, not fill a template.

## Rules
- Ground every finding in the plan, specs, or principles. No drive-by opinions.
- Be concrete: cite file paths, line numbers, or section names.
- Distinguish correctness issues from style preferences.
- ALL output files MUST be written to the run directory, not /tmp/.
```

---

## Angle briefs

Use these to populate the review focus section. For combined-angle agents, concatenate both relevant briefs. These briefs are comprehensive — when constructing review prompts, omit items irrelevant to the project type (e.g., DB/API/RLS items for CLI tools, deployment items for libraries).

### Angle 1: Alignment + Elegance + UX

**Alignment:**
- Does the plan align with project principles, architecture, and stated constraints?
- Contradictions between plan and existing specs or established patterns?
- More elegant approach with less complexity? Apply: ETC (easier to change), tracer bullets (thin slice first), good-enough design (reversible over perfect), orthogonality (minimize coupling).

**User experience walkthrough:**
- For each primary flow (happy path, error path, queued/delayed path), walk through end-to-end: what does the user see? How long do they wait? What feedback do they get?
- Flag silent periods >30 seconds with no progress indication.
- For each user role: what triggers involvement? How are they notified? What actions can they take? Any dead-end states?

**Feature completeness:**
- What would a user reasonably expect that isn't covered?
- Are gaps listed in Known Limitations? If no Known Limitations section exists, flag that.

### Angle 2: Design Issues + Constraint Verification

**Design issues:**
- Missing edge cases, coupling risks, unclear boundaries, incorrect assumptions. Cite specific plan sections.
- API endpoints: error responses specified? All status codes documented?
- Database changes: migrations specified? Indexes considered?

**Constraint verification:**
- Enumerate every MUST, invariant, guarantee from the spec.
- For each, trace ALL code paths: happy path, exception/error, race conditions, retry paths.
- Flag constraints stated but not enforced by the design.
- Produce a **Constraint Trace Matrix**:

```markdown
| Constraint ID | Text | Code Paths Checked | Holds? | Evidence |
|---------------|------|--------------------|--------|----------|
| MUST-1 | ... | ... | Yes/No/Partial | F3 |
```

**Error path tracing:**
- For every `await`, activity call, or external invocation: (a) success? (b) transient failure + retry? (c) permanent failure?
- Verify cleanup/finalization runs in ALL paths.
- For every activity that allocates a resource: is it cleaned up if a subsequent activity fails?

**Type/schema completeness:**
- Every field accessed on a type must be declared in its definition. Flag undefined types.
- Field type consistency across all usage sites.

**API consistency:** naming conventions, pagination patterns, error format, idempotency, backwards compatibility.

### Angle 3: Security + Trust Boundary Analysis

**Input tracing (every user-supplied field):**
- Trace from API request through every usage: DB queries, file paths, external APIs, shell commands, tool invocations.
- "If this input were attacker-controlled, what could go wrong?"
- Check for: path traversal, SQL injection, command injection, SSRF, privilege escalation, IDOR.

**Trust boundaries:**
- Identify every crossing: API↔backend, backend↔DB, backend↔workflow engine, worker↔external service, worker↔VM.
- At each: is data validated on the receiving side? Flag unvalidated crossings.

**Auth:** All endpoints protected? Authorization at correct granularity? IDOR possible? RLS applied where required?

**Tool security:** For user-supplied fields reaching external tools: audit for injection, path traversal, command injection. Trace input from API schema through service layer to tool invocation.

### Angle 4: Performance + Operational Readiness

**Performance:**
- DB queries per endpoint — flag >3 queries or N+1 patterns.
- Index coverage for every WHERE, ORDER BY, JOIN condition.
- Long-held resources: connections during streaming, locks across async boundaries.
- Timeouts on every background job, activity, external call. Reasonable?
- Concurrent load: what happens at 10/100/1000 concurrent requests?
- SQL patterns: window functions vs subqueries, tie-breaking correctness.

**Operational readiness:**
- Deployment instructions actionable? Could an SRE create the config from the spec?
- Infrastructure references concrete (Helm values, env vars, secrets) or vague placeholders?
- Every config value: where does it come from? How does it vary across environments?
- Monitoring/alerting for new failure modes?
- Rollback procedure documented? Migrations backward-compatible?

**Scalability:** Resource scaling characteristics? Unbounded operations? Backpressure/rate limiting?

---

## Per-phase variations

- **Phase 1 (plan review):** Full angle briefs as above.
- **Phase 2 (test strategy review):** Focus on strategy alignment with the plan — right seams covered? Critical paths missing? Test levels appropriate?
- **Phase 3 (checklist review):** Focus on checklist alignment with plan and test strategy — faithful coverage? Missing items? Over-scoped items?
- **Phase 5 (refinement):** Agents 1 and 3 (alignment) use Angle 1 brief reframed for code review: instead of checking plan-vs-principles, check implementation-vs-plan — does the code match what the plan prescribed? Are spec constraints honored? Agents 2 and 4 (code review) combine Angles 2, 3, and 4 for code-level review — bugs, regressions, missing tests, security vulnerabilities, performance issues.

## Adaptation for Codex agents

Wrap the contract in a `codex-cli` prompt file:
- Context file with review brief and file references
- Output schema with `status`, `summary`, `output_files`, `issues`, `insights`, `questions`
- The orchestrator maps Codex output to the findings tracker format (tracking IDs, severity, disposition)
- The orchestrator copies Codex output from `/tmp/` into the run directory after retrieval (codex-cli writes to `/tmp/` by convention; the orchestrator is responsible for preserving the output)
