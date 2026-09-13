---
name: claude-spawn
description: "Use when the user wants to spawn, park, list, attach to, or kill a persistent Claude, Codex, shell, or long-running command in the dedicated `claude-spawn` tmux session. It supports phone or terminal reattachment. Do not use for generic tmux administration, sending keys to an existing window, or short-lived commands."
---

# claude-spawn

The script creates persistent windows in the `claude-spawn` tmux session on the
default tmux socket. It is fire-and-forget; current state comes from tmux.

Use the repository script when inside this skill and
`~/.claude/skills/claude-spawn/scripts/claude-spawn.sh` elsewhere:

```bash
scripts/claude-spawn.sh spawn [--name <slug>] [--cwd <dir>] [--codex] [-- <cmd...>]
scripts/claude-spawn.sh list
scripts/claude-spawn.sh kill <index|name>
scripts/claude-spawn.sh attach-hint [target]
```

## Spawn

With no command override, `spawn` runs `"$SHELL" -lic 'clopus'`; `--codex`
runs `"$SHELL" -lic 'dex'`. Login plus interactive mode is required for the
user's aliases, and the script checks that the shell and alias exist first.
`--codex` cannot be combined with `-- <cmd...>`.

`--cwd <dir>` must name a directory. The script resolves it to an absolute
path before giving it to tmux. A command after `--` is passed directly and
does not receive the alias preflight.

Named windows use `[A-Za-z0-9_-]+` and must contain a non-digit. Without
`--name`, the script generates `spawn-<6hex>`. Duplicate names fail.

Examples:

```bash
scripts/claude-spawn.sh spawn --name morning-triage
scripts/claude-spawn.sh spawn --name codex-review --codex --cwd ~/dev/project
scripts/claude-spawn.sh spawn --name build -- bash -lc './scripts/full-build.sh'
```

The default command forwards only these environment variables when set:
`PATH`, `HOME`, `SHELL`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and
`CLAUDE_CODE_OAUTH_TOKEN`.

## Inspect and clean up

`list` reports each window's index, name, current command, PID, activity time,
dead state, exit status, and start command. Dead windows remain visible for
post-mortem inspection because `remain-on-exit` is set per window.

Run `list` immediately before `kill`. Window indices can change after a kill;
use the fresh name or index, never a stale listing.

`attach-hint` prints a copyable command:

```bash
scripts/claude-spawn.sh attach-hint
scripts/claude-spawn.sh attach-hint morning-triage
```

The normal hints use `tmux attach -t claude-spawn`; a target also selects the
window. A Claude child can register its remote-control channel on startup, so
the user may also reach it from the phone.

## Isolated verification

Set `CLAUDE_SPAWN_SOCKET` (default `default`) and
`CLAUDE_SPAWN_SESSION` (default `claude-spawn`) for a scratch server/session:

```bash
CLAUDE_SPAWN_SOCKET=scratch CLAUDE_SPAWN_SESSION=scratch \
  scripts/claude-spawn.sh spawn -- echo hi
```

This keeps tests away from the user's live session. The script bootstraps the
session as needed and does not track child PIDs; tmux owns the PTY until the
window is killed.
