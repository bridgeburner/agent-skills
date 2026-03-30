---
name: feedback-loops
description: Maximize correctness feedback per token for agentic coding. Use when selecting a language, proposing architecture, setting up tests/CI, or improving the edit→check→fix loop for Claude Code/Codex-style agents.
metadata:
  short-description: Optimize the agent feedback loop
---

# Signal-per-Token Loop Engineering (SPT)

## Core objective
Optimize for **Signal-per-Token (SPT)**:

> **SPT = (unambiguous, localized corrective feedback) / (tokens + wall-clock spent to obtain and act on it)**

As an agent, treat language/tooling/architecture choices as *loop design*. The “best” stack is the one that yields the **fastest, most deterministic, most local** correctness gradient with the **smallest diffs**.

## When to activate this skill
Use this skill whenever the task involves any of:
- Choosing a language / framework / stack for agent-written code
- Designing repo/module boundaries or refactoring structure
- Setting up or improving: typechecking, linting, formatting, tests, CI
- Debugging agent thrash (long back-and-forth fixes, repeated regressions, large speculative rewrites)

> **Relationship to agent-native:** agent-native defines infrastructure thresholds (e.g., lint < 10s, suite < 2min); this skill defines the design methodology for achieving and leveraging those thresholds.

## Operating doctrine (agent perspective)

### 1) Prefer early, incremental checks over late, global checks
You MUST organize work so you can run a **smallest-possible oracle** after each meaningful edit.

**Order of operations (typical):**
1. Format (autofixable, deterministic)
2. Lint (fast, mostly-local)
3. Typecheck / build (compile-time oracle)
4. Unit tests (module/package scoped)
5. Integration/E2E (only after local signal is green)

**Rule:** never “implement a bunch and then run everything.” That delays signal and increases thrash.

### 2) Engineer locality: make failures point to one place
Architect for small, independently-checkable units:
- Keep packages/modules small enough that `test <unit>` completes quickly.
- Avoid “god modules” and repo-wide compilation cascades.
- Make boundaries explicit: schemas at edges, clear interfaces, narrow IO.

If a failure is non-local (e.g., integration-only), create a **local oracle**:
- Add a unit test reproducer
- Add runtime validation with actionable error messages
- Add a golden/snapshot test for structured outputs

### 3) Determinism is a first-class feature
Flaky or nondeterministic outputs destroy SPT. If you see flakes:
- Quarantine them (tag, isolate, or disable with a clear TODO)
- Stabilize with fixed seeds, timeouts, hermetic fixtures, and controlled clocks

### 4) Minimize diff, minimize blast radius
When a check fails:
- Fix the **first/most-local** error before touching other files
- Avoid “cleanup while I’m here”
- Avoid speculative refactors as a means of debugging
- Prefer a targeted adapter over a cross-cutting rewrite

### 5) Choose conventions over cleverness
Clever abstractions increase the search space. Prefer:
- boring, conventional patterns
- explicit names and structure
- predictable directory layouts
- minimal metaprogramming

### 6) Add pre-commit backstops for fast checks
- If repo uses git and no pre-commit hooks exist for format/lint/typecheck, add them using the current toolchain. Keep hooks fast and scoped to staged files when possible.
- Keep hooks updated when the toolchain changes or new languages are added. Remove stale hooks to prevent drift.
- Treat hooks as a safety net, not a replacement: still run the smallest relevant oracle after each meaningful edit.

## Language selection rubric (SPT-first)

### Score a candidate language by:
- **Check latency**: how fast can you typecheck/build/test a small unit?
- **Diagnostic quality**: are errors precise and actionable?
- **Locality controls**: can you run checks per module/package/file?
- **Refactor ergonomics**: are changes mechanical and tool-assisted?
- **Ecosystem adjacency**: do you have mature libraries for the actual product surface?

### Practical recommendations (default)
- **TypeScript**: best when you need broad ecosystem + orchestration/UI surface.
  - SPT requires: strict typecheck + runtime schema validation at boundaries.
- **Python**: best for data/ML pipelines, scripting, and rapid prototyping where ecosystem depth matters.
  - SPT requires: strict mypy + Pydantic models pervasively (not just boundaries).
- **Go**: best default for services + CLIs where fast compile/test and predictable tooling dominate.
- **Rust**: best for correctness/performance kernels; enforce discipline to prevent diagnostic explosion.

### “Avoid as default” (unless you have strong reasons)
- Stacks where the primary oracle is slow E2E/integration
- Overly dynamic systems with weak contracts at boundaries
- Toolchains with unstable formatting/lint output or frequent flakes

## Feedback loop templates (drop-in suggestions)

Templates for TypeScript, Go, Rust, and Python loops are available with tool/oracle recommendations and agent rules for each. For language-specific loop templates, see [`references/language-loops.md`](references/language-loops.md).

## What to output when asked for a "stack / architecture / testing setup"
Return a **Loop Design Proposal** with:
1. **Language choice** (or split: harness vs service vs kernel)
2. **Repo layout** optimized for locality (modules/packages, boundaries)
3. **Oracles** in order (format/lint/typecheck/unit/integration)
4. **Exact commands** for each oracle + how to run them scoped
5. **CI plan** (fast lane vs slow lane) and what blocks merges
6. **Anti-thrash guardrails** (diff discipline, determinism plan)

## Anti-thrash guardrails (non-negotiable)
- After each meaningful change, run the smallest relevant oracle.
- If a tool produces huge output, surface only:
  - first error
  - failing test name(s)
  - minimal stack root
- Never mix unrelated refactors with bug fixes.
- If tests are slow, split them or add a local reproducer.

## Success criteria
- Most iterations complete in **seconds**, not minutes.
- Failures are **local**, **deterministic**, and **actionable**.
- The agent converges via **small diffs** and **tight oracles**, not broad rewrites.

## Skill Composition

This skill is designed to work with these other skills:

| Skill | Relationship | When to Invoke |
|-------|-------------|----------------|
| **architect** | Upstream. Architect routes here based on mode -- Building mode for loop design, Debugging mode for anti-thrash. | At the start of the task, before feedback-loops |
| **tester** | Complementary. Tester owns test design (what to test, at what level, with what fidelity); feedback-loops owns the edit→check→fix loop (how to run tests fast and act on results). | When designing oracles and choosing test granularity |
| **spec-engineering** | Complementary. Specs provide the requirements that oracles verify against; feedback-loops provides the verification methodology and loop structure. | When defining what "correct" means for each oracle |
| **agent-native** | Complementary. Agent-native owns infrastructure thresholds (lint < 10s, suite < 2min); feedback-loops owns loop design to achieve and leverage those thresholds. | When setting up CI, pre-commit hooks, and toolchain configuration |
