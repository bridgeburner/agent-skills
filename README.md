# agent-skills

Skills for Claude Code and Codex that make AI-assisted development faster, more structured, and more reliable.

## Quick Start

```bash
git clone https://github.com/<your-handle>/agent-skills
cd agent-skills
./agent-skills install-local   # symlinks skills into ~/.claude/skills and ~/.codex/skills
```

Requires `jq` (`brew install jq`) and Node.js / `npx`.

External skills are installed via the [`skills`](https://github.com/vercel-labs/skills) CLI ([skills.sh](https://skills.sh)):

```bash
npx skills add <owner/repo>        # install from GitHub
npx skills add -g <owner/repo>     # install globally across all agents
```

## What's Included

### Engineering Workflow

| Skill | What it does |
|---|---|
| `architect` | Routes you into the right engineering posture (Building / Exploratory / Debugging) at the start of a task |
| `better-goal` | Runs durable agent work through `~/.sdd` trackers, evidence ledgers, and completion audits |
| `better-review` | Coordinates parallel invariant-driven PR/codebase review through architecture, resilience, boundaries, and evidence lenses |
| `pr-monitor` | Babysits open authored PRs on a cadence: tracker-grounded review disposition, fixes, merge gate, and post-merge cleanup — **Claude Code only** |

### Utilities

| Skill | What it does |
|---|---|
| `codex-cli` | Delegates tasks to a headless OpenAI Codex agent for parallel or cross-model work |
| `gwsctx` | Manages multiple Google Workspace CLI account contexts with explicit aliases |
| `claude-spawn` | Spawns persistent, human-reachable Claude/Codex/shell sessions on a dedicated tmux server |

### Harness compatibility

Most skills here work in any compatible harness. `pr-monitor` is the exception: it hard-depends on Claude Code's `Workflow` tool, `TaskList`/`TaskGet`, per-agent model/effort overrides, and the built-in `loop` skill, so its frontmatter tells other harnesses not to invoke it. Its `references/` files are harness-agnostic procedure if you want to reimplement against them.

## Installing Individual Skills

To install specific skills from this repo without cloning the whole thing:

```bash
npx skills add <repo> --skill <name>
```

## Managing Skills

The `./agent-skills` CLI manages both local and external skills:

```bash
./agent-skills install-local                          # Link local/global skills + config files
./agent-skills add <repo> [--skill <name>]            # Install an external skill and update the lock file
./agent-skills sync                                   # Pull + install missing external skills + link local
./agent-skills list                                   # Show all installed skills
./agent-skills update [--prune] [--yes]               # Update external skills (optionally prune deleted ones)
./agent-skills prune [--dry-run] [--yes]              # Remove skills deleted from their upstream repos
./agent-skills remove <name>                          # Remove an external skill
```

External skills are tracked in `skills-lock.json` and installed under `~/.agents/skills`; `install-local` mirrors them into both Claude and Codex skill views.

Global agent instructions live in `config/AGENTS.md`; `install-local` links that file to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.agents/AGENTS.md`.

`prune` asks each skill's upstream repo (via `npx skills add <source> --list`) whether the skill still exists, and removes any that are gone from the lock files, disk, and symlinks. Detection fails closed — if a repo can't be reached, nothing is pruned from it. By default it previews the deletions and asks for confirmation; pass `--dry-run` to only preview, or `--yes` to skip the prompt. `update --prune` runs the same check after updating.

### Personal Skills

Drop skills into `skills-personal/` for private use. This directory is gitignored but `install-local` will symlink anything in it alongside the public skills.
