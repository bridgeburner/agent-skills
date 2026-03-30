# Deeper Topology Derivation Recipes

How projects earn more structure beyond the Pareto 4. Use these patterns only when justified by complexity.

## When to Add Component Cards

**Trigger:** 3+ meaningful components/modules or frequent cross-area changes.

**Pattern:**
- `specs/components/<component>.md` (or `docs/components/...`)

Each card should include:
- responsibilities
- key invariants
- interfaces (links)
- where code lives (paths)
- how to test changes
- common failure modes

## When to Add ADRs (Decision Records)

**Trigger:** Repeated "why is it like this?" questions, or sharp constraints.

**Pattern:**
- `specs/adrs/ADR-XXXX-<title>.md`

Keep ADRs short and immutable; link from router.

## When to Add Ops Runbooks / SLOs

**Trigger:** Production system, oncall, incident response.

**Pattern:**
- Runbooks for top failure modes
- SLOs for budgets + alerts

Link from router and workflows.

## When to Split Interfaces

**Trigger:** Heavy schemas/events.

**Pattern:**
- `interfaces/api.md`
- `interfaces/events.md`
- `interfaces/db.md`

Router links to each.
