# Findings Tracker Protocol

Every review finding gets a tracking ID and follows a defined lifecycle. The purpose: no finding silently disappears between iterations.

---

## Finding lifecycle

```
                ┌──────────┐
   New finding  │   OPEN   │
                └────┬─────┘
                     │
        ┌────────────┼────────────┬──────────────┐
        ▼            ▼            ▼              ▼
   ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐
   │RESOLVED │ │ DEFERRED │ │DISMISSED │ │DOWNGRADED  │
   └─────────┘ └──────────┘ └──────────┘ └────────────┘
```

| Status | Meaning | Who decides |
|--------|---------|-------------|
| **OPEN** | Not yet addressed | — |
| **RESOLVED** | Fixed in the plan/code. Cite the specific change as evidence. | Orchestrator or user |
| **DEFERRED** | Accepted risk — requires info the orchestrator lacks or infrastructure that doesn't exist. | User (interactive) or orchestrator (autonomous) |
| **DISMISSED** | Orchestrator disagrees with the finding. Requires written rationale. | Orchestrator |
| **DOWNGRADED** | Severity reduced (e.g., must-fix → should-fix). Requires user rationale. | User only |

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

## Supporting-doc gaps

Findings that belong in supporting documents (product spec, design doc) rather than the plan get a `SUPPORTING_DOC_GAP` tag. These are surfaced as recommendations to enrich the spec topology but do not block plan approval and are not counted as must-fix plan defects.
