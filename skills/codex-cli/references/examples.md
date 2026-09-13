# Codex CLI examples

For an answer needed only by the parent in the current turn, a direct prompt is
enough. It still carries the strategic context and authority:

```bash
codex exec -C /path/to/repo \
  "Strategic goal: keep the release branch safe while completing the authentication migration. Objective: review the current diff for reproducible defects and contract breaks. Context: read the parent goal, child tracker, current diff, and affected source files. Constraints: read-only; do not edit, commit, push, comment, or merge. Return findings with paths, lines, evidence, and recommendations."
```

Use a prompt file and the canonical schema only when a later consumer needs a
durable or machine-readable handoff:

```markdown
# Task: Review the current authentication diff

## Strategic goal
Keep the release branch safe while completing the authentication migration.
This review is a decision aid for the parent; it does not authorize edits.

## Objective
Find reproducible defects and contract breaks in the current diff. Write the
detail to `/tmp/codex-auth-review-a1b2c3-output.md`.

## Context and judgment
- Worktree: `/path/to/repo`; branch: `auth-migration`.
- Read the parent goal and child tracker before the current diff.
- Read affected source files in full and treat recorded decisions as context.

## Constraints and authority
- Read-only review. Do not edit, commit, push, comment, or merge.

## Output
Use headings for findings and return metadata pointing to the output file.
```

```bash
codex exec \
  --ephemeral \
  --output-schema /tmp/codex-auth-review-a1b2c3-schema.json \
  -o /tmp/codex-auth-review-a1b2c3-result.json \
  -C /path/to/repo \
  "Read /tmp/codex-auth-review-a1b2c3-prompt.md and follow it exactly. Write the detailed result to the path in the prompt. Return structured JSON metadata per the output schema." \
  </dev/null \
  2>/tmp/codex-auth-review-a1b2c3-stderr.txt &
```

For implementation, name the authorized paths and actions. For research, state
the required sources, freshness, and citation format. Add a stronger permission
flag only when that authority was granted for the task.
