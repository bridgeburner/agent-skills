# Tooling Profiles

Language-specific and language-agnostic tooling configurations that enforce agent-native principles. Referenced from SKILL.md in Bootstrap mode and when configuring mechanical enforcement (M1).

---

## Tooling Configuration Summary

| Concern | Language-Agnostic Mechanism | TypeScript | Python |
|---------|---------------------------|------------|--------|
| Type safety | Strict mode, semantic type names, parse at boundaries | `strict: true`, Zod/valibot, branded types | mypy strict, Pydantic, NewType |
| Architecture enforcement | Structural tests for layer dependencies, import restrictions | dependency-cruiser, ESLint no-restricted-imports | import-linter, ruff custom rules |
| Code quality | Auto-fix formatters + linters, cohesion checks, naming checks | Biome/ESLint + Prettier | ruff (format + lint) |
| Coverage | Branch coverage threshold in CI, diff-coverage for new code | c8/istanbul with branch threshold | pytest-cov with branch |
| Logging | Structured JSON enforced by lint, ban unstructured output | Ban console.log, use structured logger | Ban print(), use structlog |
| Environments | Worktree script, scoped DB/ports/caches | node_modules cached, ports from hash | venv per worktree, ports from hash |
| Documentation | Link checker in CI, required file check, format validation | markdownlint + custom checks | same |
| Quality scoring | Automated script computing composite grade from tool outputs | Custom script aggregating c8 + ESLint + loc | Custom script aggregating pytest-cov + ruff + loc |

---

## TypeScript Setup Notes

- **Type parsing:** Zod, io-ts, or valibot at every external boundary. OpenAPI codegen for API types. Kysely/Drizzle/Prisma for typed DB access.
- **Branded types** for semantic distinction: `type UserId = string & { __brand: 'UserId' }`.
- **Layer enforcement:** dependency-cruiser validates import graph against allowed layer dependencies. ESLint `no-restricted-imports` for quick bans.
- **Logging:** Ban `console.log` via lint rule; use a structured logger that outputs JSONL.
- **File cohesion:** Custom ESLint rule or script flagging files over 500 lines for cohesion review. Files annotated `agent-native:large-file` (generated, fixtures) are excluded. The check is a review trigger, not a hard limit.
- **Coverage:** c8 or istanbul with `--check-coverage --branches 80` (or current ratchet value).

## Python Setup Notes

- **Type parsing:** Pydantic models at every external boundary. Dataclasses/TypedDict/NamedTuple for domain types. SQLAlchemy typed models for DB access.
- **Semantic types** via `NewType`: `UserId = NewType('UserId', str)`.
- **Layer enforcement:** import-linter with contracts defining allowed dependency directions. ruff custom rules for import restrictions.
- **Logging:** Ban `print()` via ruff rule; use structlog or stdlib logging with JSON formatter.
- **File cohesion:** ruff or custom script flagging files over 500 lines for cohesion review. Files annotated `agent-native:large-file` (generated, fixtures) are excluded.
- **Coverage:** pytest-cov with `--cov-fail-under` set to ratchet value. Use `--cov-branch` for branch coverage.
- **Strict typing:** mypy or pyright in strict mode. Zero `Any` at boundaries.

## Go Setup Notes

- **Enforcement:** go vet, staticcheck, custom structural tests parsing import graphs.
- **Coverage:** `go test -coverprofile` with threshold checks.

## Rust Setup Notes

- **Enforcement:** clippy lints. Crate boundaries naturally enforce layering.
- **Coverage:** cargo-tarpaulin or llvm-cov.
