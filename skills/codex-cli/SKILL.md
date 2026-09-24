---
name: codex-cli
description: "Use from a non-Codex harness, such as Claude Code, to deliberately delegate a bounded task to a headless OpenAI Codex CLI agent. Carry the strategic goal, relevant judgment, and authority constraints into every handoff. Do not use from a Codex harness; use its native agent facility. Do not trigger for a generic subagent request unless a Codex pass is specifically wanted."
---

# Codex CLI

This bridge invokes `codex exec`. Use it when the user explicitly asks for Codex
or when an independent Codex pass is useful. A Codex harness should use its
native agent facility.

Default to a file-backed handoff written into the active goal's tracker: the
prompt, the schema, the structured result, the detailed output, and the error
log all live in the tracker's evidence directory. A dispatch that exists only in
a shell argument disappears with the session, so a later reader cannot tell what
was asked, what authority was granted, or whether the result was accepted.

Drop to a direct inline invocation only for a throwaway question whose answer is
needed in the current turn and leaves nothing worth keeping.

## Prepare the handoff

Every delegated handoff must carry the purpose and judgment behind its bounded
task, whether those sections are inline or in a prompt file:

```markdown
# Task: <short outcome>

## Strategic goal
<The larger goal this task advances, and why this task matters to it.>

## Objective
<The bounded result to produce.>

## Context and judgment
<Relevant files, trackers, prior decisions, assumptions, and current state.>

## Constraints and authority
<Allowed paths and actions, prohibited changes, safety boundaries, and any
approval the parent already has.>

## Output
<Required format and the durable output path.>
```

Do not dispatch a context-free leaf task. The parent should expand the task
with the current branch or worktree, dependencies, and the reason it serves the
strategic goal. Keep the prompt focused; reference files by path instead of
copying their contents.

For the structured result, use the canonical schema in
[references/standard-schema.json](references/standard-schema.json) unless a
consumer needs a deliberately different shape. Every object in a custom OpenAI
structured-output schema needs `additionalProperties: false`, and every property
must be required; represent an absent value with an empty string or array.

## Invoke and retrieve

Resolve the tracker before dispatching, per `better-goal`
(`scripts/sdd_path.py --cwd <dir>`), and stage every file under the assigned
task's evidence directory:

```
<tracker>/evidence/<task-id>/codex-<slug>-{prompt.md,schema.json,result.json,output.md,stderr.txt}
```

Write the prompt file first, then run without interactive stdin:

```bash
EV=~/.sdd/<pillar>/<worktree>/evidence/<task-id>
codex exec --yolo -m <model> -c model_reasoning_effort=<effort> \
  --output-schema "$EV/codex-<slug>-schema.json" \
  -o "$EV/codex-<slug>-result.json" \
  -C /path/to/repo \
  "Read $EV/codex-<slug>-prompt.md and follow it exactly. Write the detailed result to the path in the prompt. Return structured JSON metadata per the schema." \
  </dev/null \
  2>"$EV/codex-<slug>-stderr.txt" &
```

Omit `--ephemeral` so the session stays resumable with `codex exec resume`; add
it only when the session itself must not be persisted, and then the evidence
files are the only record. Record the dispatch and the accepted result in
`tasks.md` and `events.jsonl`, linking the retained paths.

When no tracker exists and the work does not warrant one, stage under the
harness scratchpad directory and treat those files as disposable; nothing then
survives for a later session.

For a direct invocation, carry the same context in the argument:

```bash
codex exec --yolo -m <model> -c model_reasoning_effort=<effort> -C /path/to/repo \
  "Strategic goal: <larger outcome and why this task matters>. Objective: <bounded result>. Context: <paths and prior judgment>. Constraints: <allowed and prohibited actions>."
```

Read the result and detailed output when the process finishes. Use `tail` on
stderr for progress or errors; the full file is noisy. Check schema errors,
authentication failures, missing output, and hangs before retrying. A failed run
is not evidence that the task was completed.

When structured output is requested, report `status`, `summary`, `output_files`,
`issues`, `insights`, and `questions`; put detail in the named output file.

## Permissions and model

Launch with `--yolo`, a hidden alias of
`--dangerously-bypass-approvals-and-sandbox`, per the "Agent invocation" section
of the user-level `AGENTS.md`. A sandboxed `codex exec` cannot answer its own
network or out-of-workspace write prompts, so it stalls or fails on ordinary
worker tasks. With no mechanical boundary, the handoff's "Constraints and
authority" section is the only limit, so name prohibited actions there
explicitly. Do not add `--dangerously-bypass-hook-trust`; `--yolo` already
covers what workers need.

Do not hard-code a model or reasoning effort in this bridge. Choose them at
dispatch under the active goal's model policy, with `-m <model>` and
`-c model_reasoning_effort=<effort>`.

## Boundaries

- The parent owns the goal, task assignment, authority, and final acceptance.
- The child owns only the bounded objective described in the handoff.
- A child may read the referenced trackers and sources, but must respect the
  listed paths and prohibited operations.
- A background process is not a durable session. Preserve any result needed for
  recovery in the named output files and, when applicable, the parent tracker.
