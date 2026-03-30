# Commit Discipline

The commit history should tell a story. Each commit is one logical unit of work.

---

## When to commit

| Phase | Trigger | Granularity |
|-------|---------|-------------|
| P4 (Implement) | After each lane completes | One commit per lane (minimum). Finer: one per checklist item when items are independent. |
| P5 (Refine) | After each fix lane completes | One commit per fix. |
| P1/P2/P3 | After each iteration | No code commits — write consolidated reports to the run directory. |

## Rules

- Stage only the relevant lane's or fix's files. Do not stage unrelated changes.
- Never combine multiple lanes or multiple fixes into a single commit.
- Do not defer commits to the end of a phase — commit as each unit completes.
- Squashing can happen later (e.g., before PR merge) if the user wants cleaner history.

## Commit messages

- Imperative mood: "Add auth middleware" not "Added auth middleware"
- First line summarizes the change concisely
- Reference the checklist item or fix lane when applicable
- Do not reference AI tools or agents

## Why this matters

Granular commits provide: (1) easier bisection if a bug is introduced, (2) clearer code review, (3) the ability to revert a single change without losing other work, (4) a readable narrative of how the implementation was built.
