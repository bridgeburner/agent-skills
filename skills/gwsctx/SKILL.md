---
name: gwsctx
description: "Manage multiple Google Workspace CLI account contexts with explicit aliases. Use when you need per-account gws auth setup, account selection, or reliable single-account execution for Gmail, Drive, Calendar, Docs, or Sheets."
---

# GWS Context

Manage multiple `gws` account contexts with explicit account aliases, while keeping existing `gws-*` skills unchanged.

The runtime implementation now lives in your Nix/Home Manager config, not in this skill repo:

- [gwsctx.nix](/Users/bridgeburner/nixos-config/home/gwsctx.nix)
- [gwsctx script](/Users/bridgeburner/nixos-config/config/scripts/gwsctx)
- [gws shim](/Users/bridgeburner/nixos-config/config/scripts/gws)

This skill is now documentation-only. It explains the command contract that the runtime must satisfy.

## Why Use It

Use this skill when:

- you have multiple Google identities and want one alias per account
- you want `gws auth setup` / `gws auth login` isolated per account
- you want agents to target exactly one account by default
- you want optional convenience state similar to `kubectx`

## Reliability Model

There are two runtime commands:

1. `gwsctx`
   This manages account state and wrapped auth commands.

2. `gws`
   This is a shim that reads the selected alias and forwards to the real `gws` binary with the correct environment.

Because these commands are now provided by Home Manager in `~/.local/bin`, fresh shells and agents can keep calling bare `gws ...` without local activation steps.

## Account Registry

`gwsctx` reads accounts from:

```bash
$GWSCTX_ACCOUNTS_FILE
```

or, if unset:

```bash
$GWSCTX_HOME/accounts.json
```

or, by default:

```bash
~/.config/gwsctx/accounts.json
```

See [examples/accounts.json.example](examples/accounts.json.example) for the expected shape.

Each account should usually define:

- `config_dir`: isolated `gws` config directory for that account
- `project_id`: optional GCP project for helper commands such as Gmail watch
- `email`: optional display field
- `kind`: optional display field such as `gmail` or `workspace`
- `credentials_file`: optional override for `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE`
- `env`: optional extra environment variables to inject for that account

## Commands

### List accounts

```bash
gwsctx list
```

### Show current account

```bash
gwsctx current
```

### Select a current account

```bash
gwsctx use altius
```

### Check the setup

```bash
gwsctx doctor
```

### Print shell exports for an account

```bash
gwsctx env altius
```

or for the current account:

```bash
gwsctx env
```

### Execute a command against the current account

```bash
gwsctx run -- /path/to/real-command
```

### Execute a command against one explicit account

```bash
gwsctx exec personal -- gws gmail +triage
gwsctx exec altius -- gws calendar calendarList list
```

### Wrapped auth setup and login per account

```bash
gwsctx auth setup personal
gwsctx auth login personal
gwsctx auth status personal
```

Any extra arguments after the alias are passed through to `gws auth <subcommand>`.

### One-shot override without changing current context

```bash
GWSCTX_ACCOUNT=altius gws gmail +triage
```

## Agent Usage Rules

- Default to exactly one alias per operation.
- If the user names an account or domain, resolve to that alias and either:
  - run `gwsctx use <alias>` first, then call bare `gws`, or
  - use `GWSCTX_ACCOUNT=<alias>` for one command.
- If the prompt is ambiguous, ask which alias to use.
- Only fan out across multiple accounts when the user explicitly asks.
- Never fan out writes across accounts.

## Bootstrap Flow

1. Create `accounts.json` from the example.
2. For each alias, run:

```bash
gwsctx auth setup <alias>
gwsctx auth login <alias>
```

3. Select an alias and use normal `gws` commands:

```bash
gwsctx use <alias>
gws gmail +triage
```

## Current Accounts

The Home Manager runtime currently provisions two accounts:

- `personal` -> `vishwath.mohan@gmail.com`
- `altius` -> `vish@getaltius.ai`

The fallback default is `personal`, so bare `gws ...` uses that alias until you explicitly switch with `gwsctx use <alias>`.

## Files

| File | Purpose |
|------|---------|
| [gwsctx.nix](/Users/bridgeburner/nixos-config/home/gwsctx.nix) | Home Manager wiring for scripts, env vars, accounts, and default |
| [gwsctx script](/Users/bridgeburner/nixos-config/config/scripts/gwsctx) | Account-aware launcher |
| [gws shim](/Users/bridgeburner/nixos-config/config/scripts/gws) | Shim that routes bare `gws` through the current context |
