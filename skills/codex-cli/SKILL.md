---
name: codex-cli
description: "Use from a non-Codex harness, such as Claude Code, to deliberately delegate a bounded task to a headless OpenAI Codex CLI agent. Carry the strategic goal, relevant judgment, and authority constraints into every handoff. Do not use from a Codex harness; use its native agent facility. Do not trigger for a generic subagent request unless a Codex pass is specifically wanted."
---

# Codex CLI

This bridge invokes `codex exec`. Use a direct invocation when the parent only
needs the answer in the current turn. Use a file-backed prompt and structured
result when another process needs to consume the output or a later session must
recover it. Use it when the user explicitly asks for Codex or when an
independent Codex pass is useful. A Codex harness should use its native agent
facility.

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

## Output (when needed)
<Required format. Name a durable output path only when a later consumer needs
one.>
```

Do not dispatch a context-free leaf task. The parent should expand the task
with the current branch or worktree, dependencies, and the reason it serves the
strategic goal. Keep the prompt focused; reference files by path instead of
copying their contents.

When a machine consumer or restart-safe handoff needs structured metadata, use
the canonical schema in
[references/standard-schema.json](references/standard-schema.json) unless the
consumer needs a deliberately different shape. Every object in a custom
OpenAI structured-output schema needs `additionalProperties: false`, and every
property must be required; represent an absent value with an empty string or
array.

## Invoke and retrieve

For a direct result, keep the invocation small:

```bash
codex exec -C /path/to/repo \
  "Strategic goal: <larger outcome and why this task matters>. Objective: <bounded result>. Context: <paths and prior judgment>. Constraints: <allowed and prohibited actions>."
```

For staging a file-backed result, use collision-resistant names such as
`/tmp/codex-<task-slug>-<short-id>-{prompt,schema,result,output,stderr}.*` and
run without interactive stdin:

```bash
codex exec \
  --ephemeral \
  --output-schema /tmp/codex-<slug>-<id>-schema.json \
  -o /tmp/codex-<slug>-<id>-result.json \
  -C /path/to/repo \
  "Read /tmp/codex-<slug>-<id>-prompt.md and follow it exactly. Write the detailed result to the path in the prompt. Return structured JSON metadata per the schema." \
  </dev/null \
  2>/tmp/codex-<slug>-<id>-stderr.txt &
```

Temporary files are staging, not durable history. Before accepting a recoverable
handoff, copy the prompt, schema, result, detailed output, and relevant error logs
to the assigned tracker evidence directory and use those retained paths in the
accepted result. Alternatively, write directly to assigned durable paths.

Do not add `--yolo` by habit. Use it only when the caller has explicitly
authorized full permissions and the task requires them; otherwise preserve the
CLI's normal approval and sandbox boundary. Do not hard-code a model or effort
in this bridge. Choose those at dispatch under the active goal's model policy.

For a structured run, read the result and detailed output when the process
finishes. Use `tail` on stderr for progress or errors; the full file is noisy.
Check schema errors, authentication failures, missing output, and hangs before
retrying. A failed run is not evidence that the task was completed.

When structured output is requested, report `status`, `summary`, `output_files`,
`issues`, `insights`, and `questions`; put detail in the named output file.

## Boundaries

- The parent owns the goal, task assignment, authority, and final acceptance.
- The child owns only the bounded objective described in the handoff.
- A child may read the referenced trackers and sources, but must respect the
  listed paths and prohibited operations.
- A background process is not a durable session. Preserve any result needed for
  recovery in the named output files and, when applicable, the parent tracker.
