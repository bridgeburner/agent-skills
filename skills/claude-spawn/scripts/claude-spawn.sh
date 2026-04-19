#!/usr/bin/env bash
set -euo pipefail

SOCKET="${CLAUDE_SPAWN_SOCKET:-claude-spawn}"
SESSION="${CLAUDE_SPAWN_SESSION:-claude-spawn}"
ENV_WHITELIST="PATH HOME SHELL ANTHROPIC_API_KEY OPENAI_API_KEY CLAUDE_CODE_OAUTH_TOKEN"

usage() {
  cat <<'EOF'
claude-spawn - manage persistent background agent sessions on a dedicated tmux server

Usage:
  claude-spawn.sh spawn [--name <slug>] [--codex] [-- <cmd...>]
  claude-spawn.sh list
  claude-spawn.sh kill <index|name>
  claude-spawn.sh attach-hint [target]
  claude-spawn.sh -h | --help

Default command: "$SHELL" -lic 'exec clopus'
With --codex:    "$SHELL" -lic 'exec dex'
All tmux ops run against socket "claude-spawn" (never the user's normal tmux).
EOF
}

die() {
  printf 'claude-spawn: %s\n' "$1" >&2
  exit "${2:-1}"
}

gen_uid() {
  # Portable on macOS bash 3.2; 6 hex chars. Use hexdump to avoid the
  # /dev/urandom -> tr -> head pipeline (SIGPIPE trips pipefail).
  LC_ALL=C hexdump -n 3 -e '3/1 "%02x"' /dev/urandom
}

server_up() {
  tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null
}

validate_window_name() {
  local name="$1"
  case "$name" in
    '') die "window name must not be empty" 2 ;;
    *[!A-Za-z0-9_-]*) die "window name must match [A-Za-z0-9_-]+ (got: $name)" 2 ;;
  esac
  case "$name" in
    *[!0-9]*) ;;
    *) die "window name must include at least one non-digit (got: $name)" 2 ;;
  esac
}

build_env_flags() {
  # NUL-delimit so values with spaces, =, or newlines survive into tmux argv.
  local key val
  for key in $ENV_WHITELIST; do
    eval "val=\${$key-__UNSET__}"
    if [ "$val" != "__UNSET__" ]; then
      printf '%s\0%s\0' '-e' "$key=$val"
    fi
  done
}

window_name_exists() {
  local name="$1"
  server_up || return 1
  tmux -L "$SOCKET" list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null \
    | grep -Fxq "$name"
}

resolve_name_to_index() {
  local name="$1"
  tmux -L "$SOCKET" list-windows -t "$SESSION" -F '#{window_index} #{window_name}' 2>/dev/null \
    | awk -v n="$name" '$2 == n {print $1}'
}

build_alias_shell_command() {
  # Serialize "$SHELL -lic 'exec <alias>'" after preflighting shell + alias.
  # Used by default (clopus) and --codex (dex) paths so the alias resolves.
  local alias_name="$1"
  local default_shell="${SHELL:-/bin/bash}"
  case "${default_shell##*/}" in
    bash|zsh|sh) ;;
    *) die "default spawn requires bash/zsh/sh for -lic (got: $default_shell); pass -- <cmd...> explicitly" 2 ;;
  esac
  if ! "$default_shell" -lic "command -v $alias_name >/dev/null 2>&1" >/dev/null 2>&1; then
    die "default spawn failed: '$alias_name' is not defined in $default_shell -lic" 127
  fi
  printf '%q ' "$default_shell" -lic "exec $alias_name"
}

cmd_spawn() {
  local name=""
  local user_cmd_given=0
  local codex_mode=0
  local -a user_cmd=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)
        [ $# -ge 2 ] || die "--name requires an argument" 2
        name="$2"
        shift 2
        ;;
      --codex)
        codex_mode=1
        shift
        ;;
      --)
        user_cmd_given=1
        shift
        while [ $# -gt 0 ]; do
          user_cmd+=("$1")
          shift
        done
        ;;
      -h|--help)
        usage; exit 0 ;;
      *)
        die "unknown arg to spawn: $1" 2 ;;
    esac
  done

  if [ "$codex_mode" -eq 1 ] && [ "$user_cmd_given" -eq 1 ]; then
    die "--codex is mutually exclusive with -- <cmd>" 2
  fi

  if [ -z "$name" ]; then
    name="spawn-$(gen_uid)"
  fi
  validate_window_name "$name"

  # Build shell_command: serialize once via printf %q so tmux gets a single argv string.
  local shell_command
  if [ "$user_cmd_given" -eq 1 ] && [ "${#user_cmd[@]}" -gt 0 ]; then
    shell_command="$(printf '%q ' "${user_cmd[@]}")"
  elif [ "$codex_mode" -eq 1 ]; then
    shell_command="$(build_alias_shell_command dex)"
  else
    shell_command="$(build_alias_shell_command clopus)"
  fi

  # Collect env flags into a bash 3.2-compatible array (NUL-delimited).
  local -a env_flags=()
  local line
  while IFS= read -r -d '' line; do
    env_flags+=("$line")
  done < <(build_env_flags)

  # Bootstrap branch is race-tolerant: if a concurrent spawn beat us to the
  # session, fall through to the new-window path.
  local bootstrapped=0
  if ! server_up; then
    if tmux -L "$SOCKET" new-session -d -s "$SESSION" -n "$name" 'sleep 999999' 2>/dev/null; then
      bootstrapped=1
      tmux -L "$SOCKET" set-option -g remain-on-exit on >/dev/null
    elif ! server_up; then
      die "failed to bootstrap tmux session $SESSION"
    fi
  fi

  if [ "$bootstrapped" -eq 1 ]; then
    if [ "${#env_flags[@]}" -gt 0 ]; then
      tmux -L "$SOCKET" respawn-window -k -t "$SESSION:$name" "${env_flags[@]}" "$shell_command"
    else
      tmux -L "$SOCKET" respawn-window -k -t "$SESSION:$name" "$shell_command"
    fi
  else
    if window_name_exists "$name"; then
      die "window name already exists: $name" 3
    fi
    if [ "${#env_flags[@]}" -gt 0 ]; then
      tmux -L "$SOCKET" new-window -d -t "$SESSION:" -n "$name" "${env_flags[@]}" "$shell_command" >/dev/null
    else
      tmux -L "$SOCKET" new-window -d -t "$SESSION:" -n "$name" "$shell_command" >/dev/null
    fi
  fi

  local idx
  idx="$(resolve_name_to_index "$name")"
  [ -n "$idx" ] || die "spawned but could not resolve window index for $name"

  printf 'spawned: %s (index %s)\n' "$name" "$idx"
  printf 'attach: tmux -L %s attach -t %s \\; select-window -t %s:%s\n' \
    "$SOCKET" "$SESSION" "$SESSION" "$name"
  printf 'running: %s\n' "$shell_command"
}

cmd_list() {
  server_up || exit 0

  local fmt='#{window_index}	#{window_name}	#{pane_current_command}	#{pane_pid}	#{t:window_activity}	#{pane_dead}	#{?pane_dead,#{pane_dead_status},-}	#{pane_start_command}'
  local rows
  rows="$(tmux -L "$SOCKET" list-windows -t "$SESSION" -F "$fmt" 2>/dev/null || true)"

  local header
  printf -v header 'IDX\tNAME\tCMD\tPID\tLAST_ACTIVITY\tDEAD\tEXIT\tSTART_CMD'

  if command -v column >/dev/null 2>&1; then
    { printf '%s\n' "$header"; printf '%s\n' "$rows"; } | column -t -s "$(printf '\t')"
  else
    printf '%s\n' "$header"
    printf '%s\n' "$rows"
  fi
}

cmd_kill() {
  [ $# -ge 1 ] || die "kill requires <index|name>" 2
  local target="$1"

  server_up || die "no claude-spawn server running"

  local resolved_name="" resolved_idx=""
  case "$target" in
    ''|*[!0-9]*)
      # Treat as name.
      local matches
      matches="$(tmux -L "$SOCKET" list-windows -t "$SESSION" -F '#{window_index} #{window_name}' 2>/dev/null \
                  | awk -v n="$target" '$2 == n {print $1}')"
      local count
      count="$(printf '%s\n' "$matches" | grep -c . || true)"
      if [ "$count" -eq 0 ]; then
        die "no window named '$target'"
      fi
      if [ "$count" -gt 1 ]; then
        die "duplicate windows named '$target'; use the index instead" 3
      fi
      resolved_name="$target"
      resolved_idx="$matches"
      ;;
    *)
      # Treat as index.
      resolved_idx="$target"
      resolved_name="$(tmux -L "$SOCKET" list-windows -t "$SESSION" -F '#{window_index} #{window_name}' 2>/dev/null \
                        | awk -v i="$target" '$1 == i {print $2}')"
      if [ -z "$resolved_name" ]; then
        die "no window at index $target"
      fi
      ;;
  esac

  tmux -L "$SOCKET" kill-window -t "$SESSION:$resolved_idx"
  printf 'killed: %s (index %s)\n' "$resolved_name" "$resolved_idx"
}

cmd_attach_hint() {
  if [ $# -eq 0 ]; then
    printf 'tmux -L %s attach -t %s\n' "$SOCKET" "$SESSION"
  else
    printf 'tmux -L %s attach -t %s \\; select-window -t %s:%s\n' \
      "$SOCKET" "$SESSION" "$SESSION" "$1"
  fi
}

main() {
  [ $# -ge 1 ] || { usage; exit 2; }
  local sub="$1"; shift
  case "$sub" in
    spawn)       cmd_spawn "$@" ;;
    list)        cmd_list "$@" ;;
    kill)        cmd_kill "$@" ;;
    attach-hint) cmd_attach_hint "$@" ;;
    -h|--help)   usage ;;
    *)           usage; exit 2 ;;
  esac
}

main "$@"
