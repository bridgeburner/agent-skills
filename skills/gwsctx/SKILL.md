---
name: gwsctx
description: "Use when selecting or managing one of the user's Google Workspace CLI account contexts, including account-specific auth, Gmail, Drive, Calendar, Docs, or Sheets commands. Keep each operation on one explicit alias; do not fan out writes across accounts."
---

# GWS context

`gwsctx` manages the selected account and wraps auth or command execution.
The `gws` shim applies the selected account's environment before forwarding to
the real Google Workspace CLI. The runtime is installed by Home Manager:

- [gwsctx.nix](/Users/bridgeburner/nixos-config/home/gwsctx.nix)
- [gwsctx](/Users/bridgeburner/nixos-config/config/scripts/gwsctx)
- [gws shim](/Users/bridgeburner/nixos-config/config/scripts/gws)

## Account state

The registry path is `$GWSCTX_ACCOUNTS_FILE`, then
`$GWSCTX_HOME/accounts.json`, then `~/.config/gwsctx/accounts.json`.
It contains a non-empty `accounts` object. Each account requires
`config_dir`; it may also define `project_id`, `email`, `kind`,
`credentials_file`, and string-valued `env` entries.

The selected alias is stored under `$GWSCTX_HOME/current`. Use
`GWSCTX_ACCOUNT=<alias>` for a one-command override or
`GWSCTX_DEFAULT_ACCOUNT=<alias>` as the fallback. These environment variables
are explicit inputs and should be checked before acting when the account is
not clear.

## Commands

```bash
gwsctx list
gwsctx current
gwsctx use <alias>
gwsctx doctor
gwsctx env [alias]
gwsctx real
gwsctx run -- <command...>
gwsctx exec <alias> -- <command...>
gwsctx auth <setup|login|status|logout> <alias> [args...]
```

Examples:

```bash
gwsctx use personal
gws gmail +triage
GWSCTX_ACCOUNT=altius gws calendar calendarList list
gwsctx exec personal -- gws drive files list
gwsctx auth login personal
```

`use` changes the persistent selection. `GWSCTX_ACCOUNT` and `exec` scope a
single command. `env` prints the exports that would be applied, and `doctor`
checks the registry, selected account, shims, and real `gws` binary.

## Operating rules

- Resolve the user's named account or domain to exactly one alias before a
  command. If the request is ambiguous, ask which alias applies.
- Prefer `GWSCTX_ACCOUNT=<alias> gws ...` for an isolated operation; use
  `gwsctx use <alias>` when the user wants to change the current context.
- Use `gwsctx exec <alias> -- ...` when the command itself should be explicit.
- Run auth commands through `gwsctx auth`, so the account's isolated config and
  credentials environment are used.
- Fan out reads only when requested. Never fan out writes across accounts.

## Runtime checks

Home Manager owns the installed scripts, account aliases, profile directories,
default, and environment values. Use the linked Nix file as the source of
truth, then inspect the live state with `gwsctx list`, `gwsctx current`, or
`gwsctx doctor`; do not rely on a remembered account list. After changing the
Nix configuration, apply it with:

```bash
home-manager switch --flake /Users/bridgeburner/nixos-config#bridgeburner@macbook-home
```

Verify the active path with:

```bash
gwsctx list
GWSCTX_ACCOUNT=personal gws gmail users getProfile --params '{"userId":"me"}'
```

The installed script uses `/usr/bin/env python3`, which may be macOS Python
3.9. Keep changes to that script compatible with Python 3.9; use
`typing.Optional` instead of PEP 604 unions.
