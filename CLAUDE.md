# agent-skills

This repo manages skills for Claude Code (and compatible agents like Codex). It tracks both locally-authored skills and externally-sourced skills via a lock file, with an install script that creates the necessary symlinks.

## What lives where

| Path | Purpose |
|---|---|
| `skills/` | Locally-authored skills. Each subdirectory is one skill with a `SKILL.md` inside. |
| `skills-lock.json` | Lock file tracking externally-installed skills (sources, hashes). Managed by the `agent-skills` CLI. |
| `config/CLAUDE.md` | Global agent instructions symlinked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.agents/AGENTS.md`. Edit this to change system-wide agent behavior. |
| `agent-skills` | CLI for managing skills: add, remove, sync, update, export, install-local. |
| `skills-personal/` | Gitignored personal skills. Symlinked by `install-local` but not committed. |
| `tests/` | Shell scripts for testing the `agent-skills` CLI. |

## Local skills

These live in `skills/` and are symlinked into `~/.claude/skills/` and `~/.codex/skills/` by `install-local`:

**Engineering workflow:** `architect`, `spec-engineering`, `feedback-loops`, `tester`, `agent-native`, `terminal-velocity`

**Creative / visual:** `pixi-animate`, `image-slides`, `explainer`, `create-image`

**Utilities:** `codex-cli`, `gwsctx`

## External skills

Installed via `npx skills` and tracked in `skills-lock.json`. Run `./agent-skills list` to see what's currently installed.

## Keeping docs current

**When you add, remove, or rename a skill:** update `README.md` — specifically the skills table in the "What's Included" section.

**When you change the repo structure** (new directories, renamed files, changed CLI commands): update both this file and `README.md`.

**When you change `install-local` behavior** (new symlink targets, new directories created): update the "Quick Start" section of `README.md`.

Never leave docs describing structure or commands that no longer exist.
