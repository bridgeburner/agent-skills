---
name: codex-cli
description: "Invoke headless OpenAI Codex CLI agents for delegated tasks: code reviews, design analysis, research, file transformations, or any work that benefits from a second model's perspective. Use when you want to delegate a self-contained task to a Codex agent running in the background, especially for parallel work, cross-model analysis, or tasks where structured handoff is valuable. Triggers on: 'run codex', 'ask codex', 'delegate to codex', 'use codex for', 'codex review', 'codex analyze', or when the user explicitly requests Codex CLI invocation."
---

# Codex CLI — Headless Agent Invocation

Delegate self-contained tasks to a headless Codex CLI agent (`codex exec`) running in the background. The agent reads context from temp files, writes detailed output to temp files, and returns structured metadata (summary, questions, insights, output file paths) via `--output-schema`.

## Invocation Pattern

Every codex invocation follows this sequence:

1. **Prepare context** → write prompt + context to a temp file
2. **Write output schema** → copy canonical schema or create task-specific one
3. **Invoke `codex exec`** → run as background Bash task
4. **Monitor / retrieve** → tail stderr to check progress, read output when done

### 1. Prepare the Context File

Write a markdown temp file with everything the agent needs. Structure it as a self-contained brief:

```
/tmp/codex-{task-slug}-{short-id}-prompt.md
```

Template:

```markdown
# Task: {one-line description}

## Objective
{What to accomplish. Be specific.}

## Context
{List file paths the agent should read. Do NOT inline file contents.}

## Instructions
{Step-by-step procedure. Be explicit about what to produce.}

## Output
Write your detailed analysis/results to: `/tmp/codex-{task-slug}-{short-id}-output.md`

Structure the output file with clear markdown headers. Include code snippets, file paths with line numbers, and concrete recommendations.

Your structured JSON response (returned via --output-schema) should summarize the output file — not duplicate it.
```

**Guidelines for the context file:**
- **Keep the prompt file small.** It is a brief, not a data dump. Reference files by path and instruct the agent to read them — never inline file contents. The agent has full filesystem access via `-C`.
- Specify the output file path explicitly so you know where to find detailed results.
- Keep the objective and instructions unambiguous — the agent has no way to ask clarifying questions.
- Frame work as actions, not analysis: say *"Read X and write Y"* not *"Analyze X and consider Y"*. Codex models are trained for action bias and planning-style prompts can cause premature stopping.

### 2. Write the Output Schema

Create the metadata schema at `/tmp/codex-{task-slug}-{short-id}-schema.json`.

A canonical schema is available at [references/standard-schema.json](references/standard-schema.json). For most tasks, copy it to the task's schema path:

```bash
cp {skill-dir}/references/standard-schema.json /tmp/codex-{slug}-{id}-schema.json
```

If the task requires additional fields, add them to the copy — but follow the schema rules below.

**Canonical schema:**

```json
{
  "type": "object",
  "properties": {
    "status": {
      "type": "string",
      "enum": ["success", "partial", "failed"],
      "description": "Overall task outcome"
    },
    "summary": {
      "type": "string",
      "description": "2-4 sentence summary of findings or work done"
    },
    "output_files": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": { "type": "string" },
          "description": { "type": "string" }
        },
        "required": ["path", "description"],
        "additionalProperties": false
      },
      "description": "Files created by the agent with descriptions"
    },
    "issues": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Problems, bugs, or concerns found"
    },
    "insights": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Non-obvious observations or recommendations"
    },
    "questions": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Unresolved questions requiring human input"
    }
  },
  "required": ["status", "summary", "output_files", "issues", "insights", "questions"],
  "additionalProperties": false
}
```

Adapt the schema when the task calls for it (e.g., add `risk` field for security reviews, `score` for quality assessments). Keep `status`, `summary`, and `output_files` as the stable core.

**OpenAI Structured Output schema rules (violations cause immediate rejection):**

- `additionalProperties: false` must be set on **every** object, including nested objects inside `items`.
- `required` must list **every** property key in `properties` — OpenAI does not support optional properties. To model optional data, have the agent return an empty array `[]` or empty string `""`.
- Maximum **5 levels** of nesting depth, **100 properties** total.

### 3. Invoke Codex

```bash
codex exec \
  --yolo \
  --ephemeral \
  --output-schema /tmp/codex-{slug}-{id}-schema.json \
  -o /tmp/codex-{slug}-{id}-result.json \
  -C {working-directory} \
  "Read /tmp/codex-{slug}-{id}-prompt.md and follow the instructions exactly. Write detailed output to the file path specified in the prompt. Return structured JSON metadata per the output schema." \
  2>/tmp/codex-{slug}-{id}-stderr.txt
```

**Run this as a background Bash task** so the invoking agent remains responsive. The agent can continue other work and check results later.

**Flag reference:**
- `--yolo` — full permissions, no approval prompts, no sandbox
- `--ephemeral` — no session persistence (clean invocation)
- `--output-schema` — constrains the final JSON response to match the schema
- `-o` — writes the final structured JSON to a file
- `-C` — sets the working directory for the agent
- `2>` — redirects stderr (thinking, tool calls, token usage) to a log file

### 4. Retrieve Results

When the background task completes:

1. **Read the structured result** from `-o` path — parse as JSON for status, summary, issues, etc.
2. **Read the detailed output** from the path specified in the prompt file — this has the full analysis
3. **Optionally check stderr** for token usage (last line) or debugging

```bash
# Check if task is done (non-blocking)
# Use TaskOutput with block=false

# Read structured metadata
cat /tmp/codex-{slug}-{id}-result.json

# Read detailed output
cat /tmp/codex-{slug}-{id}-output.md
```

## Monitoring Long-Running Tasks

Codex tasks can take several minutes for complex analysis. Monitor progress without polluting your context window:

```bash
# Quick progress check — fixed small read
tail -5 /tmp/codex-{slug}-{id}-stderr.txt
```

**What to look for in stderr:**
- **Tool call lines** (e.g., `read_file`, `shell`) — agent is actively working.
- **`ERROR:` prefix** — API-level failure (schema rejection, auth error). Read the error immediately; the task has likely failed.
- **Token usage on last line** — agent has finished.
- **No new output for >3 minutes** — agent may be hung. Check `TaskOutput` with `block=false` and consider killing the task.

**Do not** read the full stderr file — it is extremely noisy (thinking steps, rollout metadata, MCP startup logs). Always use `tail`.

## Error Handling

| Failure | Detection | Recovery |
|---|---|---|
| **Schema validation error** | Exit code 1, `ERROR:` in stderr with `invalid_json_schema` | Fix schema per rules in step 2, rerun |
| **Auth / API error** | Exit code 1, `ERROR:` in stderr with `401` or rate limit message | Check `CODEX_API_KEY`, wait and retry |
| **Empty output file** | `-o` file exists but is empty or contains `""` | Check stderr for premature exit; simplify prompt or break into smaller task |
| **Agent timeout / hang** | Task running >5 min with no new stderr output | Kill background task, break into smaller subtask |
| **Output file missing** | Output `.md` file not created by agent | Agent may have misread the path; check stderr for what it actually did, rerun with clearer output path |

**On any failure:** always check stderr first (`tail -20 /tmp/codex-{slug}-{id}-stderr.txt`). The error message is almost always there.

## Task Naming Convention

Use a consistent naming pattern for temp files:

```
/tmp/codex-{task-slug}-{short-id}-{file-type}.{ext}
```

- `task-slug`: kebab-case description (e.g., `code-review`, `design-analysis`, `research`)
- `short-id`: 4-6 char identifier to avoid collisions (e.g., first 6 chars of a UUID, or a timestamp fragment)
- `file-type`: one of `prompt`, `schema`, `result`, `output`, `stderr`

## Practical Considerations

- **Token budget**: Codex uses its own token budget (billed to the OpenAI key). A typical task with file reads + structured output uses 20k-50k tokens.
- **Stderr is noisy**: Codex emits thinking steps, tool calls, and rollout errors to stderr. This is normal — only check stderr via `tail` for progress or debugging.
- **Intermediate JSON on stderr**: Codex may emit draft/placeholder JSON to stderr during reasoning. Only the final `-o` file is schema-validated.
- **Working directory matters**: `-C` determines what files the agent can see. Set it to the repo root for code tasks.
- **No interactivity**: The agent cannot ask clarifying questions. Front-load all context via file path references and be explicit about expectations.

## Example: Code Review

See [references/examples.md](references/examples.md) for complete worked examples including code review, design analysis, and research tasks.
