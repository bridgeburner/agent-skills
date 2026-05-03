# Language-Specific Feedback Loop Templates

Drop-in suggestions for configuring the edit→check→fix loop per language.

## TypeScript loop (fast, strict, bounded)
**Goal:** typecheck becomes a frequent oracle; runtime boundaries stay honest.
- `format`: biome or prettier
- `lint`: eslint (or biome)
- `typecheck`: `tsc --noEmit`
- `unit`: vitest/jest
- Boundary validation: Zod (or equivalent) for external IO
- Interactive probes: Node REPL for plain JS, `tsx`/`ts-node` for TS modules, browser devtools for UI state, notebooks when the project already supports them

**Agent rule:** if runtime data crosses a boundary (HTTP, files, DB), add/confirm schema validation + a unit test for the shape.

**Probe rule:** use interactive probes for live object/state inspection, then capture useful probes as tests, fixtures, or small replay scripts.

## Go loop (high SPT by default)
**Goal:** lean into small packages and `go test` as the oracle.
- `format`: `gofmt` (and/or `goimports`)
- `lint`: golangci-lint (scoped when possible)
- `unit`: `go test ./...` + focus with `-run <TestName>` for locality
- Race checks when relevant: `-race` (slower; use selectively)
- Interactive probes: no first-class native REPL; prefer small `go test -run` probes, `go test` examples, temporary scratch commands under ignored/local paths, or Delve for live debugging

**Agent rule:** prefer smaller packages that compile quickly; avoid reflection-heavy magic unless necessary.

**Probe rule:** for Go, approximate REPL benefits by keeping package-scoped fixtures/harnesses tiny and rerunnable rather than relying on long-lived mutable state.

## Rust loop (high ceiling, easy to tank SPT)
**Goal:** keep compile errors shallow; constrain complexity.
- `format`: `cargo fmt`
- `lint`: `cargo clippy` (treat warnings seriously)
- `unit`: `cargo test` (prefer small crates/modules)
- Avoid over-generic designs early; stabilize architecture first.
- Interactive probes: weaker than Python/TypeScript; use small examples, focused tests, `dbg!`, and narrow crates/modules

**Agent rule:** if diagnostics balloon, reduce generic surface area, split crates/modules, and simplify trait bounds.

## Python loop (strict, validated)
**Goal:** compensate for dynamic typing with pervasive runtime validation and strict static analysis.
- `format`: `ruff format`
- `lint`: `ruff check`
- `typecheck`: `mypy --strict` (or at minimum `mypy`)
- `unit`: `pytest`
- Validation: Pydantic models for all structured data, not just IO boundaries
- Interactive probes: IPython/Jupyter/plain Python REPL are excellent for data-heavy and stateful investigation; use `%autoreload` or explicit `importlib.reload` when editing modules during a live probe

**Agent rule:** default to Pydantic models over raw dicts/tuples whenever data has a known shape. Use type hints everywhere. Mypy errors are blockers, not warnings.

**Probe rule:** keep the live session rooted in production-shaped objects, and promote any stable finding into an importable function plus a focused pytest.
