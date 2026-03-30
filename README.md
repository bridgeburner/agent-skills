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
| `spec-engineering` | Writes specs, navigates unfamiliar code, decomposes features into stories |
| `feedback-loops` | Optimizes the edit → check → fix loop — language selection, CI setup, test architecture |
| `tester` | TDD discipline and test design that catches real bugs |
| `agent-native` | Audits and improves codebases for AI agent legibility and navigability |
| `terminal-velocity` | Orchestrates parallel Claude subagent lanes with critique loops for large implementations |

### Creative & Visual

| Skill | What it does |
|---|---|
| `explainer` | Creates explanatory content in any format — articles, tutorials, presentations, interactive HTML essays |
| `pixi-animate` | Generates self-contained PixiJS canvas visualizations from a figure spec |
| `image-slides` | Creates animation-rich HTML presentations, optionally from PowerPoint files |
| `create-image` | Generates images from text prompts via Google Gemini |

### Utilities

| Skill | What it does |
|---|---|
| `codex-cli` | Delegates tasks to a headless OpenAI Codex agent for parallel or cross-model work |
| `gwsctx` | Manages multiple Google Workspace CLI account contexts with explicit aliases |

## Installing Individual Skills

To install specific skills from this repo without cloning the whole thing:

```bash
npx skills add <repo> --skill <name>
```

## Managing Skills

The `./agent-skills` CLI manages both local and external skills:

```bash
./agent-skills install-local                          # Link local skills + config files
./agent-skills add <repo> [--skill <name>]            # Install an external skill and update the lock file
./agent-skills sync                                   # Pull + install missing external skills + link local
./agent-skills list                                   # Show all installed skills
./agent-skills update                                 # Update external skills
./agent-skills remove <name>                          # Remove an external skill
```

External skills are tracked in `skills-lock.json` so they stay consistent across machines.

### Personal Skills

Drop skills into `skills-personal/` for private use. This directory is gitignored but `install-local` will symlink anything in it alongside the public skills.
