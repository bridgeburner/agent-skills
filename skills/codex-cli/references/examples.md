# Codex CLI examples

## File-backed handoff (default)

Resolve the tracker, then write the prompt into the assigned task's evidence
directory. The prompt names its own output path, so the detail lands beside the
prompt that asked for it:

```markdown
# Task: Review the current authentication diff

## Strategic goal
Keep the release branch safe while completing the authentication migration.
This review is a decision aid for the parent; it does not authorize edits.

## Objective
Find reproducible defects and contract breaks in the current diff. Write the
detail to `~/.sdd/personal/auth-migration/evidence/T7/codex-auth-review-output.md`.

## Context and judgment
- Worktree: `/path/to/repo`; branch: `auth-migration`.
- Read `~/.sdd/personal/auth-migration/goal.md` and the T7 entry in `tasks.md`
  before the current diff.
- Read affected source files in full and treat recorded decisions as context.

## Constraints and authority
- Read-only source review; the assigned output file is the only permitted write.
  Do not edit source, commit, push, comment, or merge.

## Output
Use headings for findings and return metadata pointing to the output file.
```

```bash
EV=~/.sdd/personal/auth-migration/evidence/T7
codex exec \
  --output-schema "$EV/codex-auth-review-schema.json" \
  -o "$EV/codex-auth-review-result.json" \
  -C /path/to/repo \
  "Read $EV/codex-auth-review-prompt.md and follow it exactly. Write the detailed result to the path in the prompt. Return structured JSON metadata per the output schema." \
  </dev/null \
  2>"$EV/codex-auth-review-stderr.txt" &
```

When the run finishes, read the result and output, then link both from the T7
task entry and the dispatch event.

## Direct invocation (throwaway only)

For an answer the parent needs in the current turn and will not need to justify
later, a direct prompt is enough. It still carries the strategic context and
authority:

```bash
codex exec -C /path/to/repo \
  "Strategic goal: keep the release branch safe while completing the authentication migration. Objective: review the current diff for reproducible defects and contract breaks. Context: read the parent goal, child tracker, current diff, and affected source files. Constraints: read-only; do not edit, commit, push, comment, or merge. Return findings with paths, lines, evidence, and recommendations."
```

## Shaping the task

For implementation, name the authorized paths and actions, and grant only the
narrowest permission that covers them — `--add-dir` for one extra writable path,
`-s workspace-write` for edits inside the workspace. For research, state the
required sources, freshness, and citation format. Reach past the sandbox only
with explicit user authorization for that task.
