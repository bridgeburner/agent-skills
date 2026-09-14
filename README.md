# agent-skills

Skills for Claude Code and Codex: durable goals, focused review, writing guidance, and concrete tool workflows.

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
| `better-goal` | Coordinates work in `~/.sdd` with strategic context, a compact frontier model ladder, and reconstructible event/evidence history |
| `better-review` | Reviews the intended outcome and concrete risks, loading specialized checks only where relevant |
| `pr-monitor` | Babysits open authored PRs on a cadence: tracker-grounded review disposition, fixes, merge gate, and post-merge cleanup — **Claude Code only** |

### Utilities

| Skill | What it does |
|---|---|
| `codex-cli` | Delegates tasks to a headless OpenAI Codex agent for parallel or cross-model work |
| `gwsctx` | Manages multiple Google Workspace CLI account contexts with explicit aliases |
| `claude-spawn` | Spawns persistent, human-reachable Claude/Codex/shell sessions on the default tmux server |
| `desloppify` | Improves written and visual deliverables with clear prose and restrained presentation |

### External Skills

The selected external packages are tracked in [skills-lock.json](skills-lock.json).
Removing a skill removes its instructions and bundled resources, not the underlying tool.

| Area | Retained skills |
|---|---|
| Browser and structural search | `agent-browser`, `ast-grep` |
| Frontend guidance | `frontend-design`, `vercel-react-best-practices`, `web-design-guidelines` |
| Authoring and retrieval | `skill-creator`, `qmd`, `visual-explainer` |
| Database guidance | `supabase-postgres-best-practices` |
| Google Workspace | `gws-shared`, `gws-drive`, `gws-calendar`, `gws-gmail`, `gws-docs`, `gws-sheets`, `gws-slides`, `gws-gmail-watch` |

### Harness compatibility

Most skills here work in any compatible harness. `pr-monitor` requires Claude Code's `Workflow` and `TaskList` tools plus the built-in `loop` skill. Its workflow sets effort internally; it does not require `TaskGet` or separate model/effort overrides. Other harnesses must not invoke it, but its `references/` files provide procedures for a separate implementation.

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
