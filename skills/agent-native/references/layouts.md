# Reference Layouts

Directory structures referenced by principles N3 (Filesystem as API) and U3 (Documentation Architecture). Not all projects need all layers -- adapt to the project's shape while preserving the invariants (semantic paths, domain directories, explicit public APIs).

---

## TypeScript Reference Layout

```
src/
  domains/
    <domain>/                  # e.g., billing, auth, onboarding
      types.ts                 # Domain types -- depends only on other types
      schemas.ts               # Boundary parsers -- depends on types
      repo.ts                  # Data access -- depends on types
      service.ts               # Business logic -- depends on types, repo
      ui/                      # UI components (if applicable)
      __tests__/               # Tests mirror the layer they cover
      index.ts                 # Public API of this domain
  providers/                   # Cross-cutting concerns (auth, telemetry, feature-flags)
    connectors/                # Third-party service wrappers
  utils/                       # Shared pure utilities (no domain knowledge)
  api/
    generated/                 # Auto-generated clients (never hand-edited)
    routes/                    # API handlers (thin -- delegate to domain services)
  app/                         # Entry points, wiring, top-level config
```

## Python Reference Layout

```
src/<project>/
  domains/
    <domain>/
      __init__.py              # Public API
      types.py                 # Domain types (dataclasses, TypedDict, NamedTuple)
      schemas.py               # Boundary parsers (Pydantic models)
      repo.py                  # Data access (SQLAlchemy, etc.)
      service.py               # Business logic
      tests/
        test_service.py
  providers/
    connectors/
  utils/
  api/
    generated/
    routes/
```

## Documentation Architecture Layout

From U3. Required files are AGENTS.md and ARCHITECTURE.md. Everything in `docs/` is created as needed -- do not scaffold empty files.

### core-beliefs.md

Referenced by M1 (enforcement escalation level 1) and Bootstrap mode. Lives at `docs/core-beliefs.md`. Format:

```markdown
# Core Beliefs

Project-specific agent-native principles. Each entry references a principle ID from the agent-native skill.

## Active Principles

### N2: Cohesive, Well-Scoped Files
- Review trigger: 500 lines in application code
- Overrides: `generated/` files excluded

### M1: Mechanical Rule Enforcement
- Lint: ruff (format + check)
- Types: mypy strict
- CI: all checks block merge

### V4: Structured Error Output
- All lint/test/build errors include remediation guidance

<!-- Add principles as the project adopts them. Reference by ID. -->
```

```
CLAUDE.md (or AGENTS.md)           # Agent instructions: goals, philosophy, principles, router (see N1)
ARCHITECTURE.md                    # Stable map of system shape, boundaries, key choices
docs/
  design-docs/                     # Problem, options, tradeoffs, decisions, risks, validation
  exec-plans/
    active/                        # Current plans with status, owners, milestones, blockers
    completed/                     # Archived outcomes including what shipped and deferred
  generated/                       # Non-authoritative generated artifacts with regen provenance
  product-specs/                   # Product intent and requirements driving implementation
  references/                      # Canonical standards, templates, contracts, notes
  DESIGN.md                        # Cross-cutting design rationale and decision summaries
  PLANS.md                         # Plan index: catalog of active and completed plans
  PRODUCT_SENSE.md                 # Product-value framing and prioritization context
  QUALITY_SCORE.md                 # Quality/risk scoring rubric and release-readiness gates (auto-generated, see I3)
  RELIABILITY.md                   # SLO/SLA envelopes, failure modes, runbooks
  SECURITY.md                      # Threat model, trust boundaries, authz/authn, secret handling
```
