# Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Check Early, Check Small**: After each meaningful edit, run the smallest relevant oracle. Order: format → lint → typecheck → unit tests → integration. Never batch up changes and check everything at the end.

# Workflow Routing

Scale planning, durable tracking, delegation, specialized review, and proof
independently. Complexity in one dimension does not automatically require
ceremony in all the others.

- Use `$architect` for non-trivial engineering work to choose Building,
  Exploratory, or Debugging/Triage posture and the smallest proof that matches
  the claim.
- Use `$better-goal` when restart safety, coordination, durable evidence, or a
  completion audit materially protects the outcome. Its protocol owns tracker
  structure and delegation leases; a flat step count alone is not decisive.
- Use `$better-review` when the user requests review or when a consequential
  design or semantic risk warrants independent review. That skill owns review
  lanes and synthesis; do not add a second generic critic loop around it.
- Use `$skill-creator` for skill creation or changes. It owns skill-specific
  evaluation and forward-testing guidance.
- If an owning skill is unavailable, apply its core principle with the least
  local machinery needed; do not reproduce the entire skill in this file.

## Top-level orchestration and delegation

- For a meaningful multi-step goal, remain the top-level orchestrator: preserve
  user intent and accumulated context, choose the decomposition, delegate useful
  bounded work, integrate results, and own final proof and completion.
- Actively delegate where parallelism, specialized capability, independent
  signal, or context isolation improves the outcome. Do not manufacture lanes
  whose coordination cost exceeds their value. The same rule applies recursively
  when a non-leaf child becomes an orchestrator for its bounded subgoal.
- Choose child context deliberately. Use fresh context for independent or leaf
  work. Use a truthful context fork when accumulated parent context materially
  improves nuanced judgment or autonomous discrimination and the runtime really
  supports inheritance. Otherwise pass an explicit static handoff and do not call
  it a fork.
- A task with an assigned model or reasoning effort is intended to be
  self-contained and independently executable, but that assignment is independent
  of context mode. Use a context fork when parent judgment is a material input
  even if the task has a model assignment.
- Before dispatch, verify that the selected model/reasoning and context controls
  are jointly expressible by the active harness. Never silently weaken or
  mislabel either one. Preserve the requirement that matters to the task and
  record the deviation; ask when both are user-required constraints.
- Never imply that a context fork also clones mutable REPL, interpreter,
  application, tool authority, or runtime state unless the runtime explicitly
  guarantees it. A fork inherits only the context the runtime actually serializes,
  not hidden reasoning; pass critical conclusions, live values, and artifacts as
  explicit task inputs.
- Follow the owning skill or repository instructions for audit artifacts. When a
  temporary file is needed, use a collision-safe path such as
  `/tmp/{task-slug}-{short-uid}.{ext}`.

## Corrections and verification

- Record a lesson in `~/.agents/lessons/<repo-name>.md` after a user correction
  only when it reveals a reusable failure pattern. Keep it specific enough to
  prevent recurrence and general enough to apply again.
- After each meaningful edit, diff behavior when relevant and run the smallest
  useful development diagnostic.
- Only a named live-local product-path assertion validates behavioral correctness
  or completeness for a feature, bug fix, integration, workflow, deployment,
  user-visible behavior, or agent behavior. Exercise the real local product
  entry point, services, persisted input, every semantic consumer, and terminal
  result. Assert both the expected positive behavior and each relevant negative
  sink or absence, including drop, omission, quarantine, and wrong attribution.
- Format, lint, type, unit, integration, CI, VM, replay, schema, artifact, and
  deployment checks never validate correctness or completeness; they are
  development diagnostics only. A missing, failed, or empty live-local assertion
  blocks readiness, and cloud or production evidence cannot substitute. If the
  user explicitly changes the acceptance bar, record the exception and do not
  call the result live-local validated.
- If work diverges from its assumptions or a check invalidates the current plan,
  stop, update the plan, and pursue the root cause rather than accumulating fixes.

## Autonomous Bug Fixing
- When given a bug report: fix it autonomously. Find the logs, errors, failing tests — resolve them without asking for hand-holding.
- Fix failing CI tests without being told how.

# World Model

Vishwath maintains a personal LLM wiki that serves as cross-agent durable memory. It is an explicitly requested reference, not ambient session context.

### Location
- Vault root: `/Users/bridgeburner/ObsidianVaults/bridgeburner_obsidian_mobile/`
- Full schema (page types, conventions, operations): the vault's own `CLAUDE.md` — read it when working inside the vault, don't memorize it here

### Architecture (summary)
- `vish/` — Human-owned sources (journals, notes, conversation extracts). Do not rewrite without permission.
- `wiki/` — Agent-maintained synthesis. Structured pages with wikilinks, frontmatter, TLDRs. The LLM owns this layer.
- `projects/` — Shared collaborative workspaces (design docs, agent configs, plans).
- `wiki/index.md` — Content catalog (~100 lines). Always cheap to scan first.

### Access policy — explicit opt-in
- **Default**: Do not inspect, search, index, or modify `wiki/`, `vish/`, `projects/`, or `wiki/index.md`. A topic being durable or personal is not permission to access the vault.
- **Read**: Invoke `$wiki-query` / `wiki-query` only after the user explicitly asks to search or read the wiki or vault, such as `/wiki-query` or "search my wiki".
- **Write**: Invoke `$wiki-import` / `wiki-import` or `$wiki-maintain` / `wiki-maintain` only after the user explicitly asks for an import or maintenance operation. `wiki-query` is read-only and must not file answers or edit pages.
- **No side effects**: Never run a wiki read, `qmd` freshness or embedding command, conversation extraction, import, maintenance pass, or wiki edit as a consequence of an ordinary task or because a session is ending.
- If wiki context would help but the user has not opted in, proceed without it. Ask the user to opt in when the missing context blocks the task.

### Relationship to Auto-Memory
- Auto-memory (`MEMORY.md`) = L1 cache. Fast, lightweight, per-project. Session-to-session continuity within a project context.
- Wiki = L2 store. Durable, synthesized, cross-project. Strategic state, decision history, knowledge that compounds across all sessions.
- They coexist. If something is only relevant to the current project, auto-memory is fine. If it's durable personal knowledge, it belongs in the wiki.

## Spec-Based Development
- `~/.sdd/<project-pillar>/<worktree-name>/` and `.tv/` directories are local planning artifacts.
- Do not commit files from these dirs or remove `.tv/` from `.gitignore`; `.sdd` trackers live outside repos by default.

# Linear
- ALWAYS confirm with the user before ANY write to Linear — comments, assignments, status/field/description changes, new issues, relations. Show the exact content and get an explicit yes first. Reads need no confirmation. Writes are outward-facing and post under the user's own account/name.

# Commits and PRs
When creating or updating commits or pull requests:
- Focus only on the changes being committed. Do not include references to
  agentic tools such as Claude Code or Codex in commit messages or PR bodies.
- Before drafting a PR body, read the repository's PR template and applicable
  repository instructions from the intended current base. Preserve every
  required section and exact literal label, and answer every required field.
  Repository requirements override the generic preferences below.
- Write in plain English. State **Why** the change is needed and the
  user/operational harm being fixed, **What** behavior changed, and the
  **Required outcome**, including the evidence that would establish it. Do not
  hide the reason behind implementation terminology.
- When a template asks what was removed or avoided, distinguish them
  explicitly: **Removed** means existing code, state, dependency, or
  operational responsibility deleted by this diff (`None` is valid); **Avoided**
  means a new concept deliberately not introduced. Never claim an avoidance as
  a removal.
- Before drafting, check the task, durable tracker, user context, and available
  hosting-service link or bot state for an associated ticket. If a ticket is
  found, use the repository's exact association or closing syntax. Distinguish
  final work (`Fixes ...`) from partial work (`Part of ...`) according to that
  repository's rules. A bot link or comment proves association, not closing
  semantics. Never claim there is no ticket without checking linked-app or bot
  state. If final-versus-partial is not established by the task, tracker, or
  user, ask before choosing it. Direct Linear writes still require the
  confirmation rule above.
- Keep retention, leakage, security, deployment, product-behavior, absence,
  and other claims at their evidence boundary. Name the exact data classes,
  sinks, environment, and proof tier checked. Do not turn "not observed",
  "not added by this diff", or a lower-tier test into "never", "impossible",
  or live-product proof.
- After creating or editing a PR, read the live current body back from the
  hosting service and compare it with the current base's template and ticket
  requirement. Do not declare the body compliant from draft text, a previous
  read, or memory.
- Do not add a manual testing plan unless the repository template or
  instructions require one. When they do, complete it exactly as requested.

# Python
- Put imports at the top of the file unless only used in a rarely accessed code path
- Use ruff, ty and ensure all checks pass before committing
- If accessing a private method (prefixed with `_`) from outside its class, this indicates a design issue:
   - The method should be promoted to the public interface (add to base class/protocol)
   - Or the functionality should be exposed through a different public method
   - Consult the user when the best path forward is unclear
