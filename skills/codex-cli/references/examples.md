# Codex CLI — Worked Examples

## Code Review

### Prompt file (`/tmp/codex-code-review-a1b2c3-prompt.md`)

```markdown
# Task: Review Python changes on current branch

## Objective
Review all uncommitted changes in the niobe/ directory for bugs, design issues, and test gaps.

## Context
This is the Niobe SDK — an agentic AI framework with a kernel, tool broker, and plugin system.
Key architectural rules:
- Async-first with AsyncSession
- Frozen dataclasses for value objects, mutable only where state tracking requires it
- ToolBroker protocol must be the sole tool execution path in REPL_GOVERNED mode
- No private method access from outside the owning class

Run `git diff` in the niobe/ directory to see the changes under review.

## Instructions
1. Run `git diff -- niobe/` to get the full diff
2. For each changed file, read enough surrounding context to understand the change
3. Categorize findings as: bug, design-issue, test-gap, nit
4. For each finding, include the file path, line number, and a concrete fix suggestion

## Output
Write your detailed review to: `/tmp/codex-code-review-a1b2c3-output.md`

Format each finding as:
### [category] file_path:line_number
**Issue**: description
**Suggestion**: concrete fix

Your structured JSON response should summarize counts and highlight the most critical issues.
```

### Custom schema (adds `severity` counts)

```json
{
  "type": "object",
  "properties": {
    "status": { "type": "string", "enum": ["success", "partial", "failed"] },
    "summary": { "type": "string" },
    "output_files": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": { "type": "string" },
          "description": { "type": "string" }
        },
        "required": ["path", "description"]
      }
    },
    "issues": { "type": "array", "items": { "type": "string" } },
    "insights": { "type": "array", "items": { "type": "string" } },
    "questions": { "type": "array", "items": { "type": "string" } },
    "finding_counts": {
      "type": "object",
      "properties": {
        "bug": { "type": "integer" },
        "design_issue": { "type": "integer" },
        "test_gap": { "type": "integer" },
        "nit": { "type": "integer" }
      }
    }
  },
  "required": ["status", "summary", "output_files"],
  "additionalProperties": false
}
```

### Invocation

```bash
codex exec \
  --yolo \
  --ephemeral \
  --output-schema /tmp/codex-code-review-a1b2c3-schema.json \
  -o /tmp/codex-code-review-a1b2c3-result.json \
  -C /path/to/repo \
  "Read /tmp/codex-code-review-a1b2c3-prompt.md and follow the instructions exactly. Write detailed output to the file specified in the prompt. Return structured JSON metadata per the output schema." \
  2>/tmp/codex-code-review-a1b2c3-stderr.txt
```

---

## Design Analysis

### Prompt file (`/tmp/codex-design-analysis-x7y8z9-prompt.md`)

```markdown
# Task: Analyze Phase 0 implementation plan for gaps

## Objective
Review the Phase 0 implementation plan and identify missing dependencies, underspecified tasks, or architectural risks.

## Context
Read these files:
- `.agents/repl_first_niobe/repl_first_impl_phase0.json` — task definitions with dependencies
- `.agents/repl_first_niobe/repl_first_impl_phase0.md` — full implementation spec

This is a 9-task plan for adding REPL-first execution to an agentic AI kernel.

## Instructions
1. Read both files completely
2. Build the dependency graph and verify it is a DAG (no cycles)
3. For each task, check: are all referenced files/types from dependencies actually produced?
4. Identify any implicit dependencies not declared in dependsOn
5. Flag tasks where the testFirst section doesn't cover the implement section
6. Assess whether the doneWhen gates are sufficient to catch regressions

## Output
Write your analysis to: `/tmp/codex-design-analysis-x7y8z9-output.md`

Organize by: Dependency Graph Validation, Coverage Gaps, Risk Assessment.
```

---

## Research

### Prompt file (`/tmp/codex-research-q4r5s6-prompt.md`)

```markdown
# Task: Research Python sandbox isolation approaches

## Objective
Survey approaches for sandboxing Python exec() in an agentic runtime. Compare: subprocesses, containers, WASM (e.g., pywasm/pyodide), seccomp/landlock, and nsjail.

## Context
We have a NodeRuntime that runs exec() in-process with a shared namespace. Phase 1 needs to isolate this for security. Constraints:
- Must preserve persistent namespace across calls (state survives between exec_python invocations)
- Must support numpy/pandas in the sandbox
- Latency for a simple exec_python('1+1') should be <100ms after warm-up
- Linux and macOS support required

## Instructions
1. Use web search to find current (2025-2026) approaches and benchmarks
2. For each approach, document: isolation strength, namespace persistence support, library compatibility, latency characteristics, platform support
3. Recommend a top choice with rationale
4. Include links to relevant projects/docs

## Output
Write your research to: `/tmp/codex-research-q4r5s6-output.md`

Use a comparison table and a recommendation section.
```

### Invocation with web search enabled

```bash
codex exec \
  --yolo \
  --ephemeral \
  --search \
  --output-schema /tmp/codex-research-q4r5s6-schema.json \
  -o /tmp/codex-research-q4r5s6-result.json \
  -C /path/to/repo \
  "Read /tmp/codex-research-q4r5s6-prompt.md and follow the instructions exactly. Write detailed output to the file specified in the prompt. Return structured JSON metadata per the output schema." \
  2>/tmp/codex-research-q4r5s6-stderr.txt
```

Note the `--search` flag — enables web search for research tasks.
