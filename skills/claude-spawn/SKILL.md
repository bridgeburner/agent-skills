---
name: claude-spawn
description: "Spawn, list, or kill persistent Claude/Codex/shell sessions as windows inside a `claude-spawn` tmux session on the user's default tmux server (socket `default`). Use this whenever the user wants to launch, start, spawn, park, or background an agent session they can attach to later from their phone (via the auto-registered remote-control channel) or locally via `tmux attach -t claude-spawn` — even if they say 'start a clopus session', 'spawn a codex session' (pass --codex, which uses the user's dex alias), or 'run this in the background so I can come back to it'. Also use it to list or kill previously-spawned sessions. Do NOT use for generic tmux admin (pane splits, arbitrary session management, tmux config debugging)."
---

# claude-spawn — Persistent Human-Reachable Agent Sessions

## Quick reference

```
scripts/claude-spawn.sh spawn [--name <slug>] [--cwd <dir>] [--codex] [-- <cmd...>]
  # default (no flags): $SHELL -lic 'clopus'
  # --codex:            $SHELL -lic 'dex'
  # --cwd <dir>:        start the tmux window in <dir> (so clopus/dex starts there)
  # -- <cmd...>:        run <cmd...> directly (mutually exclusive with --codex)
scripts/claude-spawn.sh list
scripts/claude-spawn.sh kill <index|name>
scripts/claude-spawn.sh attach-hint [target]
```

Invoke via the absolute path `~/.claude/skills/claude-spawn/scripts/claude-spawn.sh` when running from outside the skill directory.

## What this is

Spawn a long-lived child process (Claude, Codex, shell, or any command) into a window inside the `claude-spawn` tmux session on the user's default tmux server (socket `default`), then walk away. Spawned sessions therefore show up in the user's regular `tmux ls` and are reachable with plain `tmux attach -t claude-spawn`. Every spawned Claude child auto-registers a remote-control channel on startup, so the user can also reach it from their phone. The spawning agent is fire-and-forget: it does not track PIDs or message the child. State is always derived fresh from `tmux list-windows`.

## When to use

- User wants a Claude/Codex/clopus session they can come back to later from phone or terminal
- User wants to park a long-running command (build, watcher, scraper) in a reattachable window
- User asks "spawn", "launch a background agent", "start a persistent session", "list spawned sessions", "kill the spawned X"

## When NOT to use

- Generic tmux administration (splits, layouts, unrelated sessions on the default socket)
- Sending keystrokes or prompts into an existing session (no `send-keys` / `peek` in v1)
- Short-lived tasks that should complete and exit (use Bash directly)

## Operations

All operations use a single script: `scripts/claude-spawn.sh`.

**Rule for autonomous use**: before `kill`, always run `list` in the same turn. Killing a window renumbers others, so indices and names from a previous turn may be stale. Do not kill based on stale list output.

### `spawn [--name <slug>] [-- <cmd...>]`

Launches a new window on the `claude-spawn` session. Bootstraps the server if needed.

```
$ scripts/claude-spawn.sh spawn
spawned: spawn-a7f3bc (index 0)
attach: tmux attach -t claude-spawn \; select-window -t claude-spawn:spawn-a7f3bc
running: /bin/zsh -lic 'clopus'
```

Key behaviors:
- Default command is `"$SHELL" -lic 'clopus'` — the login+interactive shell is required so the `clopus` alias resolves (zsh's `exec` builtin does not expand aliases, so `exec clopus` would die with 127). Default path preflights the shell (bash/zsh/sh) and alias availability, failing fast instead of leaving a dead pane.
- `--codex` swaps the default to `"$SHELL" -lic 'dex'` (same preflight). Mutually exclusive with `-- <cmd>`.
- `--cwd <dir>` sets the tmux window's start-directory. Validated with `[ -d <dir> ]`, resolved to an absolute path, then passed via `tmux new-window -c <abs>` (or the equivalent on `new-session` / `respawn-window`). The spawned shell — and therefore clopus/dex — starts in that directory, with no flag passed to the agent itself. Applies to all spawn modes (default, `--codex`, `--`).
- Overridden commands (anything after `--`) run as direct argv with no preflight.
- `--name` must be a shell-safe slug matching `[A-Za-z0-9_-]+` and must include at least one non-digit. Duplicate name → exit 3.
- Without `--name`, auto-generates `spawn-<6hex>`.
- Forwards a small env whitelist into the window (see below).

### `list`

Prints one row per live window with index, name, current command, PID, last-activity time, dead flag, exit status, and the start command. Empty output + exit 0 if no server is running.

```
IDX  NAME           CMD    PID    LAST_ACTIVITY  DEAD  EXIT  START_CMD
0    spawn-a7f3bc   zsh    41302  1739820001     0     -     /bin/zsh -lic 'clopus'
```

Live windows show `-` in the `EXIT` column; dead windows show their exit code.

Note: tmux does not track per-window creation time. `LAST_ACTIVITY` is the last time the pane produced output.

### `kill <index|name>`

Kills a single window. Numeric target → index. Otherwise → name (must be unique; duplicates → exit 3, use index instead).

```
$ scripts/claude-spawn.sh kill spawn-a7f3bc
killed: spawn-a7f3bc (index 0)
```

If no server is running, exits with an error — nothing to kill.

### `attach-hint [target]`

Prints the exact tmux command the user can copy-paste to attach. With no target, attaches to the session. With a target (name or index), also selects that window.

```
$ scripts/claude-spawn.sh attach-hint
tmux attach -t claude-spawn

$ scripts/claude-spawn.sh attach-hint spawn-a7f3bc
tmux attach -t claude-spawn \; select-window -t claude-spawn:spawn-a7f3bc
```

## Usage patterns

**Spawn a default clopus session:**
```
scripts/claude-spawn.sh spawn --name morning-triage
```

**Spawn a named codex session (uses the `dex` alias):**
```
scripts/claude-spawn.sh spawn --name codex-review --codex
```

**Spawn clopus/dex in a specific project directory:**
```
scripts/claude-spawn.sh spawn --name altius-triage --cwd ~/dev/altius
scripts/claude-spawn.sh spawn --name nixos-dex --codex --cwd ~/nixos-config
```

**Park a long-running build:**
```
scripts/claude-spawn.sh spawn --name big-build -- bash -lc 'cd ~/dev/monorepo && ./scripts/full-build.sh'
```

**List, then kill a stale window:**
```
scripts/claude-spawn.sh list
scripts/claude-spawn.sh kill big-build
```

## Environment variables forwarded

The following vars are passed through to the spawned process if set in the current environment:

- `PATH`
- `HOME`
- `SHELL`
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `CLAUDE_CODE_OAUTH_TOKEN`

Anything not set is silently skipped. Nothing else is forwarded.

## Socket override (testing)

`CLAUDE_SPAWN_SOCKET` (default: `default`) and `CLAUDE_SPAWN_SESSION` (default: `claude-spawn`) override the defaults. Use them for isolated verification without touching the user's live tmux server:

```
CLAUDE_SPAWN_SOCKET=scratch CLAUDE_SPAWN_SESSION=scratch scripts/claude-spawn.sh spawn -- echo hi
```

In normal use, leave them unset.

## How persistence works

tmux owns the PTY for each window, so the child keeps running regardless of whether anyone is attached. When the child is a Claude session, it auto-registers its remote-control channel on startup — meaning the user can drive it from their phone without any extra setup. Locally, `tmux attach -t claude-spawn` (or the exact line from `attach-hint`) drops them into the session. `remain-on-exit on` is set on the `claude-spawn` session so dead windows stay visible in `list` until explicitly killed, which makes post-mortem debugging possible.
