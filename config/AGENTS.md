# Working principles

- Prefer the simplest change that achieves the user's outcome; reuse existing mechanisms and avoid unrelated work.
- Use a tracer bullet when integration is uncertain: prove the thinnest complete path from real input to the final observable result before widening it.
- Investigate the root cause and consider a simpler viable approach when the evidence challenges the proposed solution.
- Check changes early with the smallest relevant diagnostic. Keep permanent tests focused on observable behavior and credible regressions; use test-first work when it clarifies an interface or reproduces a defect, without requiring a test per function or deleting code to enforce an order.
- Complete authorized work. Make routine reversible decisions independently; ask only when missing information changes the outcome or new authority is needed.

## Skills and delegation

- Use better-goal for work that needs durable coordination or recovery, and better-review for requested reviews or consequential independent judgment.
- Use skill-creator for skill changes. Load other skills when their specific knowledge or tools help the task.
- Delegate useful independent work while retaining responsibility for the final outcome. Every worker receives the broader goal/sub-goal, relevant parent judgment and user decisions, and its authorized scope; a context-free task title is insufficient.
- Prefer an inherited context when it materially improves judgment and the harness supports it; otherwise provide an explicit handoff. Pass required artifacts and live values explicitly, and never claim a context fork clones mutable runtime state or changes the selected model.

## Model and effort routing

- Use GPT-6 Luna (`gpt-6-luna`) at `max` as the workhorse for most tasks, especially bounded or verifiable work, online searches, known-target searches, and fetching requested updates.
- Use Claude Opus 5.5 (`claude-opus-5-5`) at `medium` for reviews, triage, open-ended investigations, and harder design problems.
- Raise Opus 5.5 to `high` for especially hard problems and large-scale design issues.
- Use the active harness's actual model and effort controls. Verify that the chosen route is available; do not claim a selection the harness cannot express, and do not silently substitute a different model when a requested route is unavailable. User instructions may override these defaults.

## Evidence and continuity

- Define acceptance at the boundary of the claim. For end-to-end product behavior, exercise the real entry point and relevant persisted inputs/consumers through the terminal result, including the failure that must remain absent.
- Distinguish diagnostic tests, artifacts, live provider/product paths, and environment-specific evidence. Do not claim a broader outcome than was exercised; required missing or failed acceptance remains open unless the user accepts it.
- Preserve user decisions and reconstructible work history in the active tracker and evidence. Update the plan when evidence invalidates it.
- After a user correction that reveals a reusable failure pattern, record a specific lesson in `~/.agents/lessons/<repo-name>.md`.
- `~/.sdd/<project-pillar>/<worktree-name>/` and `.tv/` are local planning artifacts; do not commit them or remove `.tv/` from `.gitignore`.

## Product naming

Use **Morpheos** in prose and `morpheos` in identifiers. Preserve literal external names, paths, APIs, and historical evidence rather than blindly renaming them.

## Linear

Before any Linear write, show the exact proposed content and obtain explicit confirmation. This includes comments, assignments, status/field changes, issues, and relations. Reads require no confirmation.

## Commits and PRs

- Keep commits and PRs about the changes; omit references to agentic tools.
- Read the intended base's PR template and applicable instructions. Preserve required sections and literal labels, answer each field, and explain why the change is needed, what changed, and the required outcome.
- Check the task/tracker and available hosting-service ticket links or bot state. Use the repository's exact association/closing syntax; distinguish final work from partial work. If that distinction is unresolved, ask rather than guessing. Direct Linear writes still need confirmation.
- Keep claims within the evidence. Distinguish existing behavior removed by the diff from new complexity avoided; do not claim one as the other.
- After writing a PR, read its live body back and check it against the template and ticket requirement. Include a manual testing plan only when required.

## Python

Keep imports at the top except rarely used paths. Follow repository tooling; use ruff and ty where configured and complete required checks before committing. Prefer public interfaces over cross-class private-method calls.
