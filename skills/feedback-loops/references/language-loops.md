# Language-Specific Feedback Loop Templates

Drop-in suggestions for configuring the edit→check→fix loop per language.

## TypeScript loop (fast, strict, bounded)
**Goal:** typecheck becomes a frequent oracle; runtime boundaries stay honest.
- `format`: biome or prettier
- `lint`: eslint (or biome)
- `typecheck`: `tsc --noEmit`
- `unit`: vitest/jest
- Boundary validation: Zod (or equivalent) for external IO

**Agent rule:** if runtime data crosses a boundary (HTTP, files, DB), add/confirm schema validation + a unit test for the shape.

## Go loop (high SPT by default)
**Goal:** lean into small packages and `go test` as the oracle.
- `format`: `gofmt` (and/or `goimports`)
- `lint`: golangci-lint (scoped when possible)
- `unit`: `go test ./...` + focus with `-run <TestName>` for locality
- Race checks when relevant: `-race` (slower; use selectively)

**Agent rule:** prefer smaller packages that compile quickly; avoid reflection-heavy magic unless necessary.

## Rust loop (high ceiling, easy to tank SPT)
**Goal:** keep compile errors shallow; constrain complexity.
- `format`: `cargo fmt`
- `lint`: `cargo clippy` (treat warnings seriously)
- `unit`: `cargo test` (prefer small crates/modules)
- Avoid over-generic designs early; stabilize architecture first.

**Agent rule:** if diagnostics balloon, reduce generic surface area, split crates/modules, and simplify trait bounds.

## Python loop (strict, validated)
**Goal:** compensate for dynamic typing with pervasive runtime validation and strict static analysis.
- `format`: `ruff format`
- `lint`: `ruff check`
- `typecheck`: `mypy --strict` (or at minimum `mypy`)
- `unit`: `pytest`
- Validation: Pydantic models for all structured data, not just IO boundaries

**Agent rule:** default to Pydantic models over raw dicts/tuples whenever data has a known shape. Use type hints everywhere. Mypy errors are blockers, not warnings.
