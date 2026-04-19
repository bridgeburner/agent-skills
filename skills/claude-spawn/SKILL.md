---
name: claude-spawn
description: "Spawn, list, or kill persistent Claude/Codex/shell sessions on a dedicated tmux server (socket: claude-spawn). Use this whenever the user wants to launch, start, spawn, park, or background an agent session they can attach to later from their phone (via the auto-registered remote-control channel) or locally via tmux attach — even if they say 'start a clopus session', 'spawn a codex session' (pass --codex, which uses the user's dex alias), or 'run this in the background so I can come back to it'. Also use it to list or kill previously-spawned sessions. Do NOT use for generic tmux admin (pane splits, the user's normal tmux server, tmux config debugging)."
---

# claude-spawn — Persistent Human-Reachable Agent Sessions

## Quick reference

```
scripts/claude-spawn.sh spawn [--name <slug>] [--codex] [-- <cmd...>]
  # default (no flags): $SHELL -lic 'exec clopus'
  # --codex:            $SHELL -lic 'exec dex'
  # -- <cmd...>:        run <cmd...> directly (mutually exclusive with --codex)
scripts/claude-spawn.sh list
scripts/claude-spawn.sh kill <index|name>
scripts/claude-spawn.sh attach-hint [target]
```

Invoke via the absolute path `~/.claude/skills/claude-spawn/scripts/claude-spawn.sh` when running from outside the skill directory.

## What this is

Spawn a long-lived child process (Claude, Codex, shell, or any command) into a window on a dedicated tmux server, then walk away. The tmux socket is `claude-spawn` — separate from the user's normal tmux, so spawns never collide with their working sessions. Every spawned Claude child auto-registers a remote-control channel on startup, so the user can reach it from their phone; locally, `tmux -L claude-spawn attach` works too. The spawning agent is fire-and-forget: it does not track PIDs or message the child. State is always derived fresh from `tmux list-windows`.

## When to use

- User wants a Claude/Codex/clopus session they can come back to later from phone or terminal
- User wants to park a long-running command (build, watcher, scraper) in a reattachable window
- User asks "spawn", "launch a background agent", "start a persistent session", "list spawned sessions", "kill the spawned X"

## When NOT to use

- Generic tmux administration (splits, layouts, the user's normal tmux server)
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
attach: tmux -L claude-spawn attach -t claude-spawn \; select-window -t claude-spawn:spawn-a7f3bc
running: /bin/zsh -lic 'exec clopus'
```

Key behaviors:
- Default command is `"$SHELL" -lic 'exec clopus'` — the extra shell layer is required so the `clopus` alias resolves. Default path preflights the shell (bash/zsh/sh) and alias availability, failing fast instead of leaving a dead pane.
- `--codex` swaps the default to `"$SHELL" -lic 'exec dex'` (same preflight). Mutually exclusive with `-- <cmd>`.
- Overridden commands (anything after `--`) run as direct argv with no preflight.
- `--name` must be a shell-safe slug matching `[A-Za-z0-9_-]+` and must include at least one non-digit. Duplicate name → exit 3.
- Without `--name`, auto-generates `spawn-<6hex>`.
- Forwards a small env whitelist into the window (see below).

### `list`

Prints one row per live window with index, name, current command, PID, last-activity time, dead flag, exit status, and the start command. Empty output + exit 0 if no server is running.

```
IDX  NAME           CMD    PID    LAST_ACTIVITY  DEAD  EXIT  START_CMD
0    spawn-a7f3bc   zsh    41302  1739820001     0     -     /bin/zsh -lic 'exec clopus'
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
tmux -L claude-spawn attach -t claude-spawn

$ scripts/claude-spawn.sh attach-hint spawn-a7f3bc
tmux -L claude-spawn attach -t claude-spawn \; select-window -t claude-spawn:spawn-a7f3bc
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

`CLAUDE_SPAWN_SOCKET` and `CLAUDE_SPAWN_SESSION` override the defaults. Use them for isolated verification without touching the user's live `claude-spawn` socket:

```
CLAUDE_SPAWN_SOCKET=scratch CLAUDE_SPAWN_SESSION=scratch scripts/claude-spawn.sh spawn -- echo hi
```

In normal use, leave them unset.

## How persistence works

tmux owns the PTY for each window, so the child keeps running regardless of whether anyone is attached. When the child is a Claude session, it auto-registers its remote-control channel on startup — meaning the user can drive it from their phone without any extra setup. Locally, `tmux -L claude-spawn attach` (or the exact line from `attach-hint`) drops them into the session. `remain-on-exit on` is set so dead windows stay visible in `list` until explicitly killed, which makes post-mortem debugging possible.
