# agent-skills

This repo manages skills for Claude Code (and compatible agents like Codex). It tracks both locally-authored skills and externally-sourced skills via a lock file, with an install script that creates the necessary symlinks.

## What lives where

| Path | Purpose |
|---|---|
| `skills/` | Locally-authored skills. Each subdirectory is one skill with a `SKILL.md` inside. |
| `skills-lock.json` | Lock file tracking externally-installed skills (sources, hashes). Managed by the `agent-skills` CLI. |
| `config/CLAUDE.md` | Global agent instructions symlinked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.agents/AGENTS.md`. Edit this to change system-wide agent behavior. |
| `agent-skills` | CLI for managing skills: add, remove, sync, update, prune, export, install-local. |
| `skills-personal/` | Gitignored personal skills. Symlinked by `install-local` but not committed. |
| `tests/` | Shell scripts for testing the `agent-skills` CLI. |

## Local skills

These live in `skills/` and are symlinked into `~/.claude/skills/` and `~/.codex/skills/` by `install-local`:

**Engineering workflow:** `architect`, `spec-engineering`, `spec-viz`, `feedback-loops`, `tester`, `agent-native`, `terminal-velocity`, `better-goal`

**Creative / visual:** `pixi-animate`, `image-slides`, `explainer`, `create-image`

**Utilities:** `codex-cli`, `gwsctx`

## External skills

Installed via `npx skills`, stored under `~/.agents/skills`, and tracked in `skills-lock.json`. `install-local` mirrors them into both `~/.claude/skills` and `~/.codex/skills`. Run `./agent-skills list` to see what's currently installed.

## Operating philosophy for goal commands

Goal commands are for sustained, outcome-oriented work where the agent should preserve intent across many turns and interruptions. Treat a goal as a durable commitment, not a loose task label.

- Keep the objective explicit and stable. If new information changes the objective, say so and reframe it before continuing.
- Prefer architectural risk reduction before demo momentum when the goal is exploratory or strategic; prefer the thinnest working vertical slice when the goal is implementation.
- Maintain an auditable trail of decisions, tests, blockers, and known gaps so the user can inspect progress without reconstructing the session.
- Do not claim goal completion from partial evidence. Separate fixture tests, scripted tests, live-provider tests, UI tests, live UI plus provider tests, and manual verification. For agent behavior parity, build the parity matrix around live UI plus live provider scenarios first and drive as many checks as practical through that path. Weaker tests are supporting evidence, not proof of user-facing parity, unless the user explicitly scopes the live path out; keep any missing live UI/provider coverage visible in the tracker and completion audit.
- When a user correction exposes a bad assumption, update the relevant lesson or tracker before moving on.
- Stop and re-plan when the current path starts solving symptoms, drifting from the requested design, or accumulating unreviewed contract changes.
- Mark a goal complete only when the stated objective is genuinely achieved and the remaining gaps are either closed or explicitly accepted by the user.

## Keeping docs current

**When you add, remove, or rename a skill:** update `README.md` — specifically the skills table in the "What's Included" section.

**When you change the repo structure** (new directories, renamed files, changed CLI commands): update both this file and `README.md`.

**When you change `install-local` behavior** (new symlink targets, new directories created): update the "Quick Start" section of `README.md`.

Never leave docs describing structure or commands that no longer exist.
