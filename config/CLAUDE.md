# Workflow Orchestration
### 1. Plan Mode Default
- Enter plan mode for non-trivial tasks (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
- When a real plan or checklist already exists and the work can be split into independent lanes, use `terminal-velocity`; do not use it to author the plan

### 2. Subagent and Teammate Terminology
- **"subagent"** = a fire-and-forget child agent. One task, one context window, done.
  - If Claude Code: `Task` tool (with or without `run_in_background`). No persistent identity, no messaging.
- **"teammate"** = a named, persistent agent that coordinates with others across multiple turns.
  - If Claude Code: `TeamCreate` + `Task` with `team_name`. Has a name, persistent identity, sends/receives messages via `SendMessage`.
- When the user says "spawn a teammate":
  - If Claude Code: ALWAYS use `TeamCreate` first, then `Task` with `team_name`. Never substitute a plain subagent.
- When the user says "spawn a subagent":
  - If Claude Code: use `Task` (with or without `run_in_background`). No team needed.

### 2a. Subagent and Task Tracking Strategy
- Use subagents aggressively to keep main context window clean
  - If Claude Code: Create Tasks for each item that a subagent or teammate will work on
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- ONE task per subagent for focused execution, ensuring that the task can fit within a SINGLE context window for the agent.
  - If Claude Code: teammates offer the opportunity to work on sets of tasks, or larger arcs, with individual tasks still delegatable to their own subagents (meaning we can hand them larger tasks). Apportion work accordingly in those cases.
  - Subagents MUST output to files (usualy temporary files unless explicitly asked to otherwise) in addition to any output sent back to the top-level agent. These files serve as audit trail and the ability to dive deeper into subagent output in detail. The file output MUST contain a section on design decisions that were autonomously taken - ie: underspecified in the request and/or resources.
- To pass context to subagents, use temporary files for anything non-trivial (more than a few lines of context) and allow subagents to decide what to look into and when. 

### 2b. Context Window Management
- AGGRESSIVELY preserve context window for strategic work and coordination. Delegate as much and by default to subagents over doing work yourself.
- When passing files for subagents to look at, do not waste your context window reading the same file.
- Ensure that prompts/messages to subagents include sufficient context into the names of temporary files, what they contain, and instructions on how to send context back (similarly preferring temporary files for larger outputs).

### 2c. Temp File Naming
- **All temp files MUST use the pattern:** `/tmp/{task-slug}-{short-uid}.{ext}`
  - `task-slug`: kebab-case description of the task (e.g., `design-proposal`, `rls-audit`, `test-plan`)
  - `short-uid`: first 8 chars of a UUID or `$(date +%s%N | shasum | head -c 8)` — generated once per task, reused for all files in that task
  - Example: `/tmp/design-proposal-a7f3bc01.md`, `/tmp/rls-audit-e2d914ab-context.md`
- When a task produces multiple files, use the same slug+uid prefix with a suffix: `/tmp/{task-slug}-{short-uid}-{file-role}.{ext}` (e.g., `-context.md`, `-output.md`, `-result.json`)
- For workflows that produce many intermediate files, prefer `mktemp -d` to create an isolated directory: `/tmp/{task-slug}-{short-uid}/`
- When delegating to a subagent, the **parent generates the uid** and passes it in the task prompt. This ensures the parent knows where to find the output without the subagent having to communicate it back.
- NEVER use bare descriptive names like `/tmp/analysis.md` or `/tmp/claude-output.txt` — these will collide when agents run in parallel.

### 3. Self-Improvement Loop
- After ANY correction from the user: update `~/.agents/lessons/<repo-name>.md` with the pattern (for repos with a numeric suffix, drop the suffix eg: my-project-2 -> ~/.agents/lessons/my-project.md)
- The lesson should not be so general it is not actionable, or so specific it cannot apply to other instances
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification
- Never mark a task complete without proving it works
- Where possible, spawn a subagent to act as critic - task it with finding issues with the code/spec in question. It should surface issues as concrete failure modes with examples - no vague descriptions of problems. When the subagent returns, use YAGNI to decide which of the issues surfaced should be resolved. Repeat until convergence.
- Diff behavior between the parent branch and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness
- For each issue found ask the question "Are we solving symptoms, or are we solving ROOT problems in the architecture design/decision?". For each answer that is 'symptom', create a Task to find the proper root cause that needs solving instead. Run these Tasks in the background.

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

# Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Check Early, Check Small**: After each meaningful edit, run the smallest relevant oracle. Order: format → lint → typecheck → unit tests → integration. Never batch up changes and check everything at the end.

## Skill Invocation
- architect: at the start of any non-trivial task — identify your mode (Building, Exploratory, or Debugging/Triage), apply the right principles, and route to companion skills
- spec-engineering: when navigating unfamiliar code (ORIENT), answering architectural questions (ANSWER), authoring specs (AUTHOR), or updating specs after changes (CHANGE)
- agent-native: when bootstrapping a project for agents, auditing agent-friendliness, or diagnosing why agents struggle — also invoked reactively when project structure or isolation is limiting performance
- feedback-loops: when setting up a new project's toolchain/CI, choosing a language stack, or diagnosing agent thrash (repeated regressions, large speculative rewrites)
- tester: when writing tests, reviewing test quality, or investigating why tests missed a bug. Default to TDD discipline (RED→GREEN→VERIFY) during implementation — surface rationale when skipping.
- terminal-velocity: when a non-trivial implementation already has a plan/checklist and parallel lanes plus critique loops are worth the overhead

## Spec-Based Development
- Follow `spec-engineering` progressive disclosure: router/index → minimal docs → code
- See `spec-engineering` MODE=CHANGE for when and how to update specs
- `.sdd/` and `.tv` directories contain working design documents and are intentionally gitignored
- Do not attempt to commit files in these dirs, or remove them from `.gitignore`
- These files are local planning artifacts, not tracked project history

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

