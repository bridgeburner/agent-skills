# Principle Specifications

Full specifications for the 10 agent-native principles, organized by workflow stage. Read this file when applying a specific principle identified via the catalog in SKILL.md.

Cross-references:
- Directory layouts: `references/layouts.md`
- Quality scoring details: `references/quality-rubric.md`
- Tooling setup: `references/tooling-profiles.md`

---

## Navigate

*Problem: Agent can't find the right files, opens wrong files, wastes context on irrelevant code.*

### N1. Agent Instructions as Decision-Making Context
**Tags:** agent-specific, Tier 1

The agent instructions file (CLAUDE.md, AGENTS.md, or equivalent) is not just a map -- it is the **decision-making context** that enables autonomous work. An agent that knows where files are but doesn't understand the product goals will make locally correct, globally wrong decisions. Good autonomy requires both information AND values.

**The file should contain (in priority order):**

1. **Product/project goals** -- What is this project trying to achieve? What matters most? Not a mission statement; concrete goals that inform tradeoffs. "We're building X for Y because Z. The initial customer needs A by B."

2. **Design philosophy and principles** -- Values for autonomous decision-making when specs are silent. "Prefer simple solutions over configurable ones." "RLS enforcement is non-negotiable." "We optimize for correctness over speed." These are the rules an agent uses to make judgment calls without asking.

3. **Architectural guidelines** -- Key invariants and patterns. Not a full architecture doc, but the 5-10 things that matter most. "Service methods never call commit() directly." "All new tables enforce RLS." Brief -- a sentence each -- with pointers to design docs.

4. **Router / context pointers** -- Where to find more information. Spec topology router (link to specs/INDEX.md or equivalent), key directories, how to run tests. This is the navigational layer.

5. **Workflow instructions** -- How this repo wants agents to operate. Commit conventions, CI requirements, review expectations.

**What it is NOT:**
- Not a README (that's for humans onboarding)
- Not an architecture doc (link to one instead)
- Not exhaustive (link to deeper docs; keep it loadable in one read)

**Tool-agnostic:** The specific filename depends on the tooling ecosystem (CLAUDE.md for Claude Code, AGENTS.md for broader compatibility, .cursorrules for Cursor). The content pattern matters, not the filename. Use whatever your primary agent tool loads automatically.

**Layering pattern:**
- Per-repo agent instructions: product goals, philosophy, design principles, guidelines, mini-router
- User-level agent instructions (via skill repos or global config): cross-repo workflow instructions, skill invocation rules, commit conventions
- If the ecosystem expects a specific file (AGENTS.md) that you don't use as primary, add a one-line pointer to your primary file

**Cross-references:** Serves as the router entry point that spec-engineering's discovery protocol searches for. Agent-native defines what the entry point should contain; spec-engineering defines how agents navigate from it.

---

### N2. Cohesive, Well-Scoped Files
**Tags:** agent-specific, Tier 1

Files should have **one clear reason to exist**. The goal is cohesion, not a line count. A 400-line file with one well-defined class is better than three 130-line files that artificially split a cohesive unit.

**Why cohesion matters for agents:**
- **Navigation cost**: In a 1000-line file containing 5 unrelated classes, the agent wastes tokens scanning irrelevant code to find what it needs.
- **Edit precision**: Larger files with mixed concerns make it harder for edit tools to find unique match points.
- **Parallel work**: Two agents can't modify the same file without conflict. Files with multiple responsibilities create artificial serialization points.
- **Change blast radius**: A file with multiple responsibilities means unrelated changes produce merge conflicts.

**Split signals (when a file should be broken up):**
- You need two sentences to describe what the file does → probably two files
- The file has multiple public classes/components with independent consumers
- Different parts of the file change for different reasons (single responsibility violation)
- The file mixes layers (data access + business logic + API handling in one file)

**Review trigger:** Files over 500 lines in application code are worth examining for split opportunities. This is not a hard rule -- some files (generated code, test fixtures, schema registries, comprehensive model definitions) legitimately exceed this. The question is always "does this file have one cohesive responsibility?" not "is it under N lines?"

**Agent rule:** Before splitting a file, ask: "Are these pieces independently meaningful, or am I just making the file shorter?" Only split when the pieces have independent reasons to exist and independent consumers.

---

### N3. Filesystem as API
**Tags:** agent-specific, Tier 2

The filesystem is the primary interface agents use to navigate a codebase. Treat directory structure and file naming with the same care as any public API.

**Invariants:**
- Paths are semantic: `billing/invoices/compute` communicates more than `utils/helpers`
- Each domain gets its own directory subtree
- Each domain directory has an explicit public API (index/barrel file or equivalent)
- Directory nesting reflects logical containment, not arbitrary grouping

**Reference layouts:** See `references/layouts.md` for TypeScript and Python directory structures.

Not all projects need all layers. A CLI tool may have no repo or UI layer. A library may have no API layer. The invariants apply universally; the specific layers adapt to the project's shape.

---

## Understand

*Problem: Agent misunderstands intent, architecture, constraints, or data shapes.*

### U3. Documentation Architecture
**Tags:** agent-amplified, Tier 2

Documentation is structured for progressive disclosure: agents start with the agent instructions file (N1) and follow pointers to deeper sources of truth. Plans and design decisions are checked into the repo as versioned artifacts, not in external wikis or ephemeral docs.

**Reference layout:** See `references/layouts.md` for the canonical documentation structure.

**Required vs optional docs:** An agent instructions file (CLAUDE.md / AGENTS.md) is always required. ARCHITECTURE.md is recommended for non-trivial projects. Everything in docs/ is created as needed -- do not scaffold empty files.

**The progressive disclosure chain:**
```
Agent instructions file (N1)        -- decision context, router
  → ARCHITECTURE.md                 -- system shape, boundaries, key choices
  → specs/INDEX.md                  -- feature spec router (see spec-engineering)
    → specs/<feature>/spec.md       -- product spec
    → specs/<feature>/design.md     -- design doc with constraints
    → specs/<feature>/plan.md       -- execution plan
  → docs/conventions/               -- coding patterns, database patterns
```

**Relationship to spec-engineering:** Agent-native defines the physical documentation structure (where files live). Spec-engineering defines the navigation protocol (how agents discover and traverse the structure) and the spec authoring patterns (three-doc topology, constraint taxonomy).

**Documentation CI (automatable checks only):**
- All internal links resolve (dead link checker)
- Required files exist (agent instructions file, ARCHITECTURE.md if expected)
- Format validation (execution plans have required frontmatter)
- Generated docs are up-to-date (e.g., DB schema matches actual schema)

Freshness detection: co-locate docs near code, flag docs not updated in N commits when adjacent code has changed via git blame analysis.

---

## Modify

*Problem: Agent makes a change that breaks something non-obvious or violates architectural rules.*

### M1. Mechanical Rule Enforcement
**Tags:** agent-amplified, Tier 2

Encode architectural rules as machine-checked constraints. Documentation alone is insufficient -- agents read it once at context-load time and may drift during a long implementation session. Lints and structural tests catch violations at the point of failure.

**Enforcement escalation ladder:**
1. Documented in agent instructions / CLAUDE.md (soft -- agents read it as guidance)
2. Warned by linter (medium -- agents see the warning in output)
3. Blocked by CI (hard -- cannot merge without fixing)

Promote rules upward as confidence grows. New rules start at level 1; proven rules graduate to level 3.

**Connection to spec-engineering:** The MUST/NEVER/ASK FIRST constraint taxonomy in design docs (spec-engineering) provides the content that feeds this escalation pipeline. Every MUST constraint should eventually graduate from spec → structural test → CI check.

**Enforcement catalog:**

| Rule | Mechanism | Error output |
|------|-----------|-------------|
| Layer dependency direction | Structural test or import linter | Names the illegal import, which boundary it violates, and the allowed alternative |
| Naming conventions | Lint rule | Shows expected pattern with example |
| Structured logging | Lint rule (ban unstructured output) | Points to the project's logging utility |
| Type coverage | Strict mode + CI check | Names the untyped boundary |
| Import restrictions | Language-specific import linter | Names the banned import and the allowed alternative |

**Error message design:** All enforcement errors should follow the structured error schema defined in V4. The remediation field is critical -- it turns an error from "something is wrong" into "do this specific thing to fix it."

**Ecosystem specifics:** See `references/tooling-profiles.md` for language-specific tool configuration.

---

### M2. Cross-Domain Communication Patterns
**Tags:** agent-amplified, Tier 3

When domain A needs data or behavior from domain B, the allowed patterns must be explicit. Without this, agents make inconsistent wiring decisions -- one agent imports the repo directly, another goes through the service, a third uses an event.

**Allowed patterns** (choose a primary pattern per project; exceptions must be documented in ARCHITECTURE.md and mechanically enforced):

1. **Direct service import** (simplest, recommended for most projects): Domain A imports domain B's public service API. B's repo/types/internals are never imported directly.
   ```
   ALLOWED:  import { getUserById } from '../auth/service'
   ILLEGAL:  import { usersTable } from '../auth/repo'
   ```

2. **Event-based decoupling** (for high-independence domains): Domains communicate through typed events on a shared event bus. No direct imports between domains.

3. **Shared provider** (for truly cross-cutting data): Data needed by many domains lives in a provider, not in any single domain.

The project's ARCHITECTURE.md should declare which pattern is in use. Mechanical enforcement (M1) should validate it.

---

## Verify

*Problem: Agent can't tell if its change is correct, or can't see the running system.*

### V4. Structured Error Output
**Tags:** agent-specific, Tier 2

Every error surface the agent encounters should be designed for machine consumption. This is "prompt injection at the point of failure" -- the error message directly shapes the agent's next action. A lint error saying `Layer dependency violation at billing/service.ts:42 — Import from 'auth/service' instead of 'auth/repo'` immediately tells the agent what to do. A generic `ImportError` does not.

**Error surfaces that need structure:**
- Lint/format violations (most tools already do this well)
- Type checker errors (usually structured; ensure remediation is clear)
- Test failures: include the assertion context, expected vs actual, and which test file/line
- Build errors: include the failing module and suggested fix
- Runtime exceptions: structured JSON with stack trace, context data, and likely cause
- Migration failures: include the failing migration, the error, and rollback instructions
- CI check failures: include what failed, why, and the command to reproduce locally

**Universal error schema:**
```json
{
  "error": "Layer dependency violation",
  "location": "src/domains/billing/service.ts:42:1",
  "rule": "no-cross-domain-repo-import",
  "remediation": "Import from 'auth/service' instead of 'auth/repo'. Cross-domain access must go through the service layer.",
  "docs": "docs/core-beliefs.md#layered-architecture"
}
```

Not all error surfaces can produce this exact schema (compiler errors are what they are). The goal is to improve every surface you control, and wrap the ones you don't with better messages where feasible (custom lint error messages, test reporter plugins, build script wrappers).

---

### V5. Tiered Observability
**Tags:** agent-specific, Tier 3

Make the running application directly legible to agents. Agents can read structured output programmatically but cannot glance at a Grafana dashboard. The system must expose its state through text interfaces agents can query.

**Observability Tier 1 -- Structured logs + seed scripts (start here):**
- All application output is structured JSON, one event per line, written to a JSONL file
- Queryable with `jq`, `grep`, or any JSON-aware tool
- Log schema enforced by lint (ban unstructured output)
- Minimum fields: timestamp (ISO8601), level, event name, data payload
- **Seed scripts**: commands to quickly set up and inspect development state
  - `make seed-<feature>` -- create representative data for a feature area
  - `make inspect-<entity> ID=xxx` -- show full state of an entity (status, relationships, artifacts)
  - These scripts use the app's own service layer, not raw SQL

```json
{"ts": "2026-03-05T12:00:00Z", "level": "info", "event": "invoice.created", "data": {"invoice_id": "inv_123", "amount": 4999}}
```

**Observability Tier 2 -- Health endpoints + local metrics:**
- `/healthz` or `/health/detailed` returns structured JSON: boot status, dependency health, version, queue depths
- Agents can verify "service is healthy" and "performance is within budget" programmatically
- Metrics endpoint (Prometheus-compatible or simple JSON) for key indicators

```json
{
  "status": "ok",
  "database": "ok",
  "temporal": "ok",
  "external_service": "unreachable",
  "worker": {"pods": 1, "queue_depth": 3},
  "version": "abc123"
}
```

**Observability Tier 3 -- Full observability stack:**
- OpenTelemetry traces to local collector (per-worktree, ephemeral)
- Queryable log store (Loki or equivalent) and metrics (PromQL or equivalent)
- Browser automation for UI verification (Playwright MCP, agent-browser, or equivalent)
  - Start dev server → navigate to page → take screenshot → verify output
  - Critical for frontend changes where the only true verification is visual
- Agents can run queries like "show me all errors in the billing domain in the last 5 minutes"

Most projects should start at Observability Tier 1 and get enormous benefit.

---

## Iterate

*Problem: Agent can't recover from failure, can't work in parallel with other agents, or entropy accumulates over time.*

### I1. Ephemeral + Concurrent Environments
**Tags:** agent-specific, Tier 3

Agents spawn many parallel work streams. Each needs a fully isolated, instantly available dev environment.

**Bootstrap contract:**
```
Command:  new-feature <name>

Steps (in order):
  1. git worktree add .worktrees/<name> -b <name> [base-branch]
  2. Copy environment template, fill worktree-specific values
  3. Install dependencies (cached -- target <5s if lockfile unchanged)
  4. Allocate isolated resources:
     - DB: scoped name (e.g., <project>_<name>)
       PostgreSQL: CREATE DATABASE ... TEMPLATE
       SQLite: copy file
       No DB: skip
     - Ports: deterministic from worktree name (hash to range) or dynamic allocation
     - Cache/queue namespaces: prefixed with worktree name
  5. Smoke test: verify the environment boots and core health check passes
  6. Ready signal

Teardown:  rm-feature <name>
  - Drop scoped database
  - Remove worktree
  - Release allocated ports/caches

Isolation invariant:
  Any two worktrees running simultaneously have zero shared mutable state.
  Secrets and credentials are scoped per worktree (unique tokens, no shared API keys).
  Teardown verification includes confirming no credential material persists.
```

---

### I3. Quality Scoring + Entropy Management
**Tags:** agent-amplified, Tier 3

Technical debt compounds. Without active management, agent-generated code accumulates stylistic drift, dead code, and pattern inconsistencies even when each individual PR looks fine. Quality scoring makes drift visible; entropy sweeps fix it.

**Full rubric and process:** See `references/quality-rubric.md` for the scoring dimensions, composite grade formula, regression rule, and entropy sweep process.
