# Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Check Early, Check Small**: After each meaningful edit, run the smallest relevant oracle. Order: format → lint → typecheck → unit tests → integration. Never batch up changes and check everything at the end.

# Workflow Orchestration
### 1. Plan Mode Default
- Enter plan mode for non-trivial tasks (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
- When a real plan or checklist already exists and the work can be split into independent lanes, use `terminal-velocity`; do not use it to author the plan

### 2. Subagent and Teammate Terminology
- **"subagent"** = fire-and-forget child. `Task` tool (with or without `run_in_background`). No persistent identity, no messaging.
- **"teammate"** = named, persistent agent. `TeamCreate` first, then `Task` with `team_name`. Has identity, sends/receives messages via `SendMessage`.
- Never substitute a plain subagent when the user asks for a teammate.

### 2a. Subagent Delegation Strategy
- Use subagents aggressively to keep main context window clean. Delegate by default over doing work yourself.
- Offload research, exploration, and parallel analysis to subagents. For complex problems, throw more compute at it.
- ONE task per subagent for focused execution. Teammates can handle larger arcs with tasks delegatable to their own subagents.
- Subagents MUST output to files (usually temporary files unless explicitly asked otherwise) in addition to any output sent back to the top-level agent. These files serve as audit trail. The file output MUST contain a section on design decisions that were autonomously taken.
- When passing files for subagents to look at, do not waste your context window reading the same file. Include sufficient context in prompts: names of temporary files, what they contain, and instructions on how to send context back (preferring temporary files for larger outputs).

### 2b. Temp File Naming
- **Pattern:** `/tmp/{task-slug}-{short-uid}.{ext}` — e.g., `/tmp/design-proposal-a7f3bc01.md`
- Multiple files from one task: same prefix with suffix — e.g., `-context.md`, `-output.md`, `-result.json`
- Many intermediate files: prefer `mktemp -d` for an isolated directory: `/tmp/{task-slug}-{short-uid}/`
- When delegating, the **parent generates the uid** and passes it in the task prompt.
- NEVER use bare names like `/tmp/analysis.md` — these collide when agents run in parallel.

### 3. Self-Improvement Loop
- After ANY correction from the user: update `~/.agents/lessons/<repo-name>.md` with the pattern (for repos with a numeric suffix, drop the suffix eg: my-project-2 -> ~/.agents/lessons/my-project.md)
- The lesson should not be so general it is not actionable, or so specific it cannot apply to other instances
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for relevant project

### 4. Verification
- Never mark a task complete without proving it works
- Where possible, spawn a subagent to act as critic - task it with finding issues with the code/spec in question. It should surface issues as concrete failure modes with examples - no vague descriptions of problems. When the subagent returns, use YAGNI to decide which of the issues surfaced should be resolved. Repeat until convergence.
- Diff behavior between the parent branch and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness
- For each issue found ask the question "Are we solving symptoms, or are we solving ROOT problems in the architecture design/decision?". For each answer that is 'symptom', create a Task to find the proper root cause that needs solving instead. Run these Tasks in the background.
- For non-trivial changes, consider whether there's a more elegant approach before presenting.

### 5. Autonomous Bug Fixing
- When given a bug report: fix it autonomously. Find the logs, errors, failing tests — resolve them without asking for hand-holding.
- Fix failing CI tests without being told how.

# World Model

Vishwath maintains a personal LLM wiki that serves as cross-agent durable memory. Every session has access to this knowledge base — use it.

### Location
- Vault root: `/Users/bridgeburner/ObsidianVaults/bridgeburner_obsidian_mobile/`
- Full schema (page types, conventions, operations): the vault's own `CLAUDE.md` — read it when working inside the vault, don't memorize it here

### Architecture (summary)
- `vish/` — Human-owned sources (journals, notes, conversation extracts). Do not rewrite without permission.
- `wiki/` — Agent-maintained synthesis. Structured pages with wikilinks, frontmatter, TLDRs. The LLM owns this layer.
- `projects/` — Shared collaborative workspaces (design docs, agent configs, plans).
- `wiki/index.md` — Content catalog (~100 lines). Always cheap to scan first.

### Read Path — when to query the wiki
- **Trigger**: The conversation touches durable personal knowledge — projects, people, goals, past decisions, life domains, systems, schedule, priorities. The signal is "does this draw on or produce knowledge that persists across sessions?"
- **Concrete triggers**: References to known projects (Niobe, Altius, Morpheos, bridgeOS, etc.), people, life domains (work, self, family, home, finances), goals, workflows, or schedule
- **Non-triggers**: Pure technical work ("fix this TypeScript error"), generic questions ("how does React context work"), ephemeral tasks
- **Mechanism**: Use the `wiki-query` skill. On a fresh session the first lookup bootstraps awareness — pages and wikilinks seen tell you what the wiki covers for follow-up queries.

### Write Path — when to deposit into the wiki
- **Trigger**: The conversation produces durable value — decisions made, design rationale articulated, new insights, corrections to existing understanding, personal information worth preserving.
- **Mechanism**: Use the `wiki-import` skill. It handles mode selection (inline updates, conversation extraction, file import) internally.
- Apply editorial judgment — decisions, rationale, and corrections compound; ephemeral debugging does not. Use `wiki-maintain` for periodic health checks.

### Relationship to Auto-Memory
- Auto-memory (`MEMORY.md`) = L1 cache. Fast, lightweight, per-project. Session-to-session continuity within a project context.
- Wiki = L2 store. Durable, synthesized, cross-project. Strategic state, decision history, knowledge that compounds across all sessions.
- They coexist. If something is only relevant to the current project, auto-memory is fine. If it's durable personal knowledge, it belongs in the wiki.

## Spec-Based Development
- `.sdd/` and `.tv` directories are local planning artifacts, intentionally gitignored.
- Do not commit files in these dirs or remove them from `.gitignore`.

# Commits and PRs
When creating commits or pull requests:
- Focus only on the changes being committed
- Do not include references to agentic tools like Claude Code or Codex in commit messages or PR bodies
- PR bodies should summarize changes only; do not include manual testing plans (only add/run automated tests)

# Python
- Put imports at the top of the file unless only used in a rarely accessed code path
- Use ruff, ty and ensure all checks pass before committing
- If accessing a private method (prefixed with `_`) from outside its class, this indicates a design issue:
   - The method should be promoted to the public interface (add to base class/protocol)
   - Or the functionality should be exposed through a different public method
   - Consult the user when the best path forward is unclear
