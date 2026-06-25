---
name: senna
description: >-
  Push, pull, and sync files between vish's local Mac and "Senna" — his Apex
  cloud dev VM — over Teleport SSH + rsync. Handles the Teleport quirk that the
  only allowed principal is `apexhq`, with the real dev user being `vish`
  reached via `sudo -iu vish`, and supports explicit bidirectional union sync
  semantics for gitignored dev artifacts. Safe default: never overwrite existing
  destination files without an explicit user request; if the user asks for
  "overwrite on conflict", dry-run first, then perform a union merge that
  overwrites changed destination files and never deletes extras.

  Trigger when the user mentions "Senna" (the cloud dev VM), or asks to
  push/pull/sync/copy/send/grab/fetch files to or from senna, run a command on
  senna, or ssh into senna. Also trigger on phrases like "move .env to senna",
  "bring back .tv from senna", "sync .sdd to senna", or any operational task
  involving the senna host. Do NOT trigger for generic SSH/rsync questions
  unrelated to Senna, or for setting up Teleport itself.
---

# Senna — Apex cloud dev VM transfer & access helper

Senna is vish's cloud dev machine for Apex work. This skill handles the connection plumbing (Teleport quirks, sudo escalation), path inference, and bidirectional union syncs for gitignored dev artifacts. The default mode is conservative and does not overwrite conflicts; an explicit "overwrite on conflict" request means "merge both trees, overwrite changed files on the destination, and never delete destination-only files."

For broader context (what Senna is, why it exists), the durable knowledge layer is the wiki page `wiki/projects/Senna Dev VM.md` in the personal Obsidian vault. Use the `wiki-query` skill if you need more than the operational details below.

## Connection facts (single source of truth)

- **Host alias:** `senna`
- **Teleport login (only allowed):** `apexhq` — direct `tsh ssh vish@senna` does NOT work
- **Real dev user:** `vish`, home `/home/vish`
- **Interactive shell as vish:** `tsh ssh apexhq@senna` then `sudo -iu vish`
- **Non-interactive ops as vish (rsync, one-shot commands):** invoke as `apexhq` with `sudo -u vish <cmd>` on the remote side

## Pre-flight (run before any transfer)

```bash
tsh status                                  # verify session is alive
tsh ssh apexhq@senna echo ok                # verify connectivity
```

If `tsh status` shows the session expired, **ask the user to run `tsh login`** — never run `tsh login` autonomously (it can prompt for SSO, MFA, etc.).

## Path inference (local → Senna)

Derive the remote destination from the local source path:

| Local prefix | Remote mapping |
|---|---|
| `~/dev/apex/<rest>` | `/home/vish/src/apex/<rest>` |
| `~/dev/personal/<rest>` | `/home/vish/src/personal/<rest>` |
| anything else | **ASK** the user. Optionally probe `tsh ssh apexhq@senna sudo -u vish ls /home/vish/src/{apex,personal}/` to suggest matches. |

The whole point of the auto-mapping is that vish mirrors his local `~/dev/{apex,personal}/...` tree under `~/src/{apex,personal}/...` on Senna. Don't invent destinations under other paths without asking.

## Worktree parent artifacts

Some Apex repos keep shared dev artifacts one level above individual worktrees.
For example:

- Local worktree: `~/dev/apex/morpheos/niobe-2d-drawing/`
- Local canonical `.sdd`: `~/dev/apex/morpheos/.sdd/`
- Senna canonical `.sdd`: `/home/vish/src/apex/morpheos/.sdd/`

When the user asks to sync `.sdd` from inside a Morpheos/Niobe worktree, first check `../.sdd/`.
If it exists, treat it as canonical and use it instead of `./.sdd/`. Do not create or sync
`./.sdd/` inside the worktree unless the user explicitly names that path.

## Direction and conflict mode

- **Default: push** (local → Senna). Most common case.
- **Pull** only when the user explicitly says "pull", "fetch", "bring back", "grab from senna", "copy from senna", or similar.
- **Default conflict mode: skip**. Copy new files only; do not overwrite destination files.
- **Explicit overwrite mode:** if the user says "overwrite on conflict", "overwrite conflicts", "overwrite all", or otherwise clearly asks for destination conflicts to be replaced, still dry-run first and summarize counts, then execute regular rsync without `--ignore-existing`. This is a union merge: it updates/adds files but does not delete destination-only files.

## What to sync — presets

Most of vish's project trees flow via GitHub. This skill is for the **gitignored dev artifacts** that don't go through git. Recognize these preset names:

| Preset | Expands to (in current project / cwd) |
|---|---|
| `env` | `.env`, `.env.local`, `.env.*` (whichever exist) |
| `sdd` | `../.sdd/` when present; otherwise `.sdd/` |
| `tv` | `.tv/` |
| `claude-local` | `.claude/settings.local.json`, `.claude/<dir>.local.md` if any |
| `dev-artifacts` | union of all the above (the "everything I care about that's gitignored" bundle) |

If the user names explicit paths instead of a preset, use those. If a preset expands to zero existing paths in the cwd, tell the user before doing anything.

## THE CORE SAFETY CONTRACT — union sync, never delete silently

This is the most important section. Syncs are always union-style by default: files that exist only on the destination are preserved. Existing destination files are never overwritten unless the user explicitly asks for overwrite-on-conflict behavior for that invocation or approves specific conflicts after the dry-run.

### Step 1 — Dry-run with itemize-changes

```bash
rsync -avzn --itemize-changes \
  -e "tsh ssh" \
  --rsync-path="sudo -u vish rsync" \
  <local-sources...> apexhq@senna:<remote-dest>/
```

Note the `n` in `-avzn` (dry-run) and `--itemize-changes` (per-file change codes).

### Step 2 — Parse the itemized output

Each line looks like `YXcstpoguax path` (11 status chars + space + path). For our purposes:

- **`>f+++++++++ path`** — NEW file, will be created on remote. Safe.
- **`>f.<anything>... path`** (3rd char is `.`, not `+`) — EXISTING file would be MODIFIED. **CONFLICT.**
- **`cd+++++++++ path`** — new directory. Safe (rsync creates it).
- **`.d..t...... path`** or similar — directory exists, only metadata changes. Usually safe; surface only if user asked for verbose.

### Step 3 — Report and resolve

Show the user a clean summary. If the user already explicitly requested overwrite-on-conflict, treat that as the conflict resolution and proceed after the summary unless the dry-run reveals an unexpectedly broad or suspicious change set.

> **Push plan:**
> - **N new files** to copy: `<list, or first 10 + "...and X more">`
> - **M existing files would be overwritten:**
>   - `path/a` (local: 4.2KB, remote: 3.8KB — modified)
>   - `path/b` (local: 1.1KB, remote: 1.1KB — content differs)
>
> How should I handle the conflicts?
> - `skip` — copy only the new files, leave remote conflicts untouched (default)
> - `overwrite all` — overwrite all conflicts
> - `overwrite <path>` — overwrite specific files (you can list multiple)
> - `diff <path>` — show me the difference for a file before deciding
> - `cancel` — don't transfer anything

If the user picks `diff <path>`, run:

```bash
tsh ssh apexhq@senna sudo -u vish cat <remote-path> | diff - <local-path>
```

Then re-prompt for the resolution.

### Step 4 — Execute the resolved plan

- **Skip all conflicts:** re-run with `--ignore-existing` (only files that don't exist on remote are copied).
  ```bash
  rsync -avzP -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
    --ignore-existing <sources...> apexhq@senna:<dest>/
  ```
- **Overwrite all:** re-run without `--ignore-existing` (regular rsync). This still preserves destination-only files because `--delete` is not used.
  ```bash
  rsync -avzP -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
    <sources...> apexhq@senna:<dest>/
  ```
- **Selective overwrite:** two-phase.
  1. Copy new files only: `rsync ... --ignore-existing ...`
  2. Build a `--files-from=-` list of just the to-overwrite paths, run a second rsync that targets only those files (without `--ignore-existing`).
  ```bash
  printf '%s\n' path/a path/b | rsync -avzP \
    -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
    --files-from=- ./ apexhq@senna:<dest>/
  ```

After execution, show a 1-2 line summary: how many files copied, how many skipped, how many overwritten.

## Pull (Senna → local)

Same flow, source/dest reversed:

```bash
rsync -avzn --itemize-changes \
  -e "tsh ssh" \
  --rsync-path="sudo -u vish rsync" \
  apexhq@senna:<remote-source-paths...> <local-dest>/
```

Apply the **same union semantics** — don't clobber LOCAL files without per-conflict approval. Same dry-run, parse, report, resolve flow.

For pull, the parse logic flips: `<f+++++++++` (note `<` instead of `>`) is a new local file, `<f.` is a modification of an existing local file (= conflict).

## Hard rules (do not violate)

1. **NEVER** use `--delete` (or any of `--delete-during`, `--delete-after`, `--delete-excluded`) without **explicit user approval per call**. Even with approval, default off.
2. **NEVER** run `tsh login` or modify Teleport credentials autonomously. If auth is expired, ask vish.
3. **ALWAYS** dry-run first for any directory transfer or any preset expanding to >1 path. Single-file scalar copies can skip dry-run only if the file is new on the destination (still pre-flight check existence).
4. **ALWAYS** surface conflicts in the dry-run summary before overwriting. Default resolution = skip unless the invocation already explicitly requested overwrite-on-conflict.
5. **ALWAYS** mention trailing-slash semantics in the dry-run preview when relevant (see below).
6. If the remote destination directory does not exist, do `tsh ssh apexhq@senna sudo -u vish mkdir -p <path>` first and tell the user it's being created.

## Trailing-slash refresher

- `rsync src/  dest/` — copies CONTENTS of `src` into `dest`. Result: `dest/file1`, `dest/file2`, ...
- `rsync src   dest/` — copies `src` AS A SUBDIR of `dest`. Result: `dest/src/file1`, ...

Default for directory presets (`sdd`, `tv`): use trailing slash on source so contents merge into the existing remote directory.

## Common workflows (concrete recipes)

### Push the env file from current project

```bash
# In ~/dev/apex/morpheos/prod-fixes
# Remote target: /home/vish/src/apex/morpheos/prod-fixes/

# 1. Dry-run
rsync -avzn --itemize-changes -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
  .env apexhq@senna:/home/vish/src/apex/morpheos/prod-fixes/

# 2. Parse, surface conflicts, resolve, execute as above.
```

### Push .sdd/ planning artifacts

```bash
# From a worktree whose parent owns the shared .sdd:
rsync -avzn --itemize-changes -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
  ../.sdd/ apexhq@senna:/home/vish/src/apex/<proj>/.sdd/
# (then resolve conflicts, then execute)
```

### Pull parent-level .sdd/ planning artifacts

```bash
# From a worktree whose parent owns the shared .sdd:
rsync -avzn --itemize-changes -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
  apexhq@senna:/home/vish/src/apex/<proj>/.sdd/ ../.sdd/
# (then resolve conflicts, then execute)
```

### Pull .tv/ artifacts back from Senna after a remote run

```bash
rsync -avzn --itemize-changes -e "tsh ssh" --rsync-path="sudo -u vish rsync" \
  apexhq@senna:/home/vish/src/apex/<proj>/.tv/ ./.tv/
# (then resolve conflicts, then execute)
```

### One-off file transfer (path not under ~/dev/{apex,personal})

Ask the user where on Senna it should go. Don't guess.

### Just SSH into Senna interactively

If the user just wants a shell:

```bash
# Tell the user to run themselves (interactive auth/sudo prompts):
tsh ssh apexhq@senna
# then on the remote prompt:
sudo -iu vish
```

If the user wants you to run a one-shot command:

```bash
tsh ssh apexhq@senna sudo -u vish <command>
```

## Edge cases & known quirks

- **rsync over `tsh ssh` argument parsing:** modern Teleport's `tsh ssh` is a drop-in for `ssh`, so `-e "tsh ssh"` works. If a transfer ever fails with weird argument errors, fall back to a wrapper script (`#!/usr/bin/env bash\nexec tsh ssh "$@"`) and `-e /path/to/wrapper`. Don't go there unless needed.
- **Permissions on push:** with `--rsync-path="sudo -u vish rsync"`, files land owned by `vish`. Without it, they'd land owned by `apexhq` and vish couldn't read/edit them — that's the footgun. Always use the `--rsync-path` flag for vish-owned destinations.
- **Compression:** `-z` is default; for already-compressed files (videos, archives) it's wasted CPU but harmless.
- **Big transfers:** add `--partial` to allow resume on interruption (`-P` already includes this + progress).
- **Stale Teleport session mid-transfer:** rsync will fail. Re-auth with `tsh login`, then re-run — `--partial` makes resumption cheap.

## When this skill is NOT the right tool

- Generic SSH/rsync questions unrelated to Senna → answer normally without invoking this skill.
- Setting up or troubleshooting Teleport itself → out of scope; user handles auth.
- In-place edits to remote files (not file transfer) → just `tsh ssh apexhq@senna sudo -u vish <cmd>`, no rsync needed.
- Syncing git-tracked code → use git/GitHub instead. This skill is for the gitignored stuff.
