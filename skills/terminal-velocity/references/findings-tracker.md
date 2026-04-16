# Findings Tracker Protocol

Every review finding gets a tracking ID and follows a defined lifecycle. The purpose: no finding silently disappears between iterations.

---

## Finding lifecycle

```
                ┌──────────┐
   New finding  │   OPEN   │
                └────┬─────┘
                     │
        ┌────────────┼────────────┬──────────────┬───────────────┐
        ▼            ▼            ▼              ▼               ▼
   ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ ┌───────────────┐
   │RESOLVED │ │ DEFERRED │ │DISMISSED │ │DOWNGRADED  │ │PLAN_OVERRIDE  │
   └─────────┘ └──────────┘ └──────────┘ └────────────┘ └───────────────┘
```

| Status | Meaning | Who decides |
|--------|---------|-------------|
| **OPEN** | Not yet addressed | — |
| **RESOLVED** | Fixed in the plan/code. Cite the specific change as evidence. | Orchestrator or user |
| **DEFERRED** | Accepted risk — requires info the orchestrator lacks or infrastructure that doesn't exist. | User (interactive) or orchestrator (autonomous) |
| **DISMISSED** | Orchestrator disagrees with the finding. Requires written rationale. | Orchestrator |
| **DOWNGRADED** | Severity reduced (e.g., must-fix → should-fix). Requires user rationale. | User only |
| **PLAN_OVERRIDE** | Finding contradicts a registered plan constraint. Deviation acknowledged. | User (interactive) or orchestrator (autonomous) |

## First iteration

1. Assign each unique finding a tracking ID: `F1`, `F2`, ...
2. Classify severity: must-fix / should-fix / nice-to-have
3. List all findings in the consolidated report

## Subsequent iterations

1. Pass the full unresolved findings list to every review agent as part of their brief
2. Each agent verifies whether each prior finding was addressed
3. During consolidation, cross-reference every prior finding:
   - Addressed → mark `RESOLVED` with evidence (cite the specific change)
   - Not addressed → mark `OPEN`
   - Orchestrator disagrees → mark `DISMISSED` with rationale
4. The `Unresolved Must-Fix Items` section lists all `OPEN` findings with must-fix severity

## Gate constraints

### Interactive mode
The user cannot approve while must-fix items remain `OPEN`. They must either:
- Confirm the item is addressed (→ `RESOLVED`)
- Acknowledge and defer (→ `DEFERRED` with rationale)
- Override the severity (→ `DOWNGRADED` with rationale)

### Autonomous mode
The orchestrator auto-resolves all findings. Quality rules:
- Resolutions must be as specific as findings. "Missing error handling for X" → add error handling for X, not a vague note.
- Must-fix items may only be `DEFERRED` if they require information the orchestrator lacks or infrastructure that doesn't exist. "Too complex" is not valid deferral.
- Self-check after applying: "For each RESOLVED finding, does the new plan text actually prevent the issue?"

### Plan constraint cross-reference

When the orchestrator DEFERs or DISMISSes any must-fix finding, it must cross-reference the finding against `constraint_registry.md`. If the finding's subject matches a registered plan constraint, DEFERRED and DISMISSED are invalid dispositions — the finding must be either:
- **RESOLVED** — fix the plan, checklist, or code to honor the constraint
- **PLAN_OVERRIDE** — acknowledge the deviation explicitly

PLAN_OVERRIDE requires three fields:
1. **Constraint ID** — the specific registry entry being overridden (e.g., PC-1)
2. **Justification** — why the constraint cannot be honored in this run. Must be concrete and honest. "Deployment-time concern" or "will validate later" are not valid when the plan says otherwise. The test is: would the plan author agree this is a legitimate reason to deviate?
3. **Consequences** — what downstream impact the override has (scope reduction, missing capability, deferred risk)

In autonomous mode, PLAN_OVERRIDE is permitted — the run continues. But it cannot be hidden. PLAN_OVERRIDE findings are surfaced in the final report under a dedicated "Plan Deviations" section, separate from design decisions.

In interactive mode, PLAN_OVERRIDE blocks until the user approves the deviation.

The purpose of this mechanism: the orchestrator (Claude) has a structural incentive to dismiss findings that make implementation harder. When a reviewer (especially Codex) flags that the implementation drifts from explicit plan constraints, the orchestrator cannot rationalize the finding away with DEFERRED/DISMISSED. It must either fix the problem or own the deviation visibly.

## Supporting-doc gaps

Findings that belong in supporting documents (product spec, design doc) rather than the plan get a `SUPPORTING_DOC_GAP` tag. These are surfaced as recommendations to enrich the spec topology but do not block plan approval and are not counted as must-fix plan defects.
