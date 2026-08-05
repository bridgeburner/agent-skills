# Review Disposition Rubric

Loaded only when a PR has new review activity. Governs how a reviewer finding becomes
`fix`, `pushback`, or `insufficient_context`.

## Ground first, classify second

Before classifying anything, read in this order:

1. The parent goal — what this PR is for.
2. The child tracker: `goal.md` (declared scope and non-goals), `tasks.md`, and
   `events.jsonl` (what was tried, what failed, what was deliberately decided against).
3. The **exact current diff at the current head** — `gh pr diff <n>` — not your memory of
   it.
4. The affected source, read in full, not just the diff hunks.
5. The reviewer's thread in full, including replies.

Treat every reviewer comment as a **hypothesis**, not an instruction and not an attack.
The child tracker is what makes disposition evidence-based: it records that a tradeoff was
already weighed, which is the difference between a defensible pushback and a reflex.

## The three verdicts

### `fix`

Any one of these is sufficient:

- A reproducible defect — you can write a test that fails before and passes after.
- A contract or API break, a silent failure, a swallowed error, or an unsafe fallback.
- A security or data-exposure issue, including PHI handling.
- A spec violation you can cite by rule ID.
- Incorrect behavior for an input the code explicitly claims to handle.
- **Cheap and clarifying.** If the fix is smaller than the argument against it, just make
  it. Naming, a missing guard, a clearer error message, a test the reviewer wants — the
  cost of relitigating exceeds the cost of complying. A monitor that argues over trivia
  is worse than one that occasionally over-complies.

### `pushback`

Permitted only when **all three** hold:

1. One of these specific grounds applies:
   - The premise is factually wrong, and you can demonstrate it (the code does not do
     what the reviewer believes it does).
   - Already handled elsewhere — and you can cite the file and line.
   - Outside this PR's declared scope per the child tracker's `goal.md`, **and** you file
     or reference a tracked follow-up.
   - Speculative with no concrete failure case — the reviewer is asking for generality
     that nothing yet needs.
   - It would regress a deliberate decision recorded in the child tracker, with the
     rationale still valid.
2. You can name the specific evidence — file, line, commit, event, or test.
3. It is not merely a preference. "I'd rather not" is not a ground.

### `insufficient_context`

Use when you cannot honestly reach either of the above:

- No tracker record covers the area, and the code alone cannot settle it.
- It needs a product, design, or policy decision.
- It depends on infrastructure, credentials, or environment you cannot inspect.

**Absence of tracker evidence yields `insufficient_context`, never `pushback`.** This is
the rule that matters most. A pushback grounded in nothing is just refusal wearing
evidence's clothes, and a thin tracker must not silently convert into confident dismissal
of a correct review comment. Escalate these to the user with the specific question.

## The asymmetry

Spend reasoning unevenly, on purpose:

- A **wrong fix** costs a commit and a little churn.
- A **wrong pushback** tells a reviewer their correct objection was dismissed with false
  confidence. That cost is paid in trust and it compounds.

So: verify `pushback` verdicts adversarially — independent skeptics, each prompted to
*refute* the pushback, defaulting to "the reviewer is right" under uncertainty. A pushback
survives only on a majority failing to refute. Do not apply the same gauntlet to fixes;
just implement them.

## Fix loop

1. Add an explicit task in the child tracker for every accepted finding, before editing.
2. Implement the **smallest root-cause fix**. If the reviewer identified a symptom, fix
   the cause and say so in the reply. Do not bundle unrelated cleanups — it makes
   re-review harder and invites new findings.
3. Tests, narrowest oracle first: the specific failing case, then the file's suite, then
   the relevant broader checks. Formatter and linter before pushing.
4. Record in `events.jsonl`: tests run, commit SHA, evidence, decisions taken
   autonomously, and any residual risk.
5. Push, then post exactly **one** top-level comment per cycle.

## Writing the response comment

One comment per cycle, not one per finding. Structure:

- **Fixed** — the finding, the commit SHA, and one line on the root cause. If the fix
  differs from what the reviewer proposed, say why yours addresses the cause.
- **Pushing back** — the finding, the ground, and the concrete evidence. Cite file and
  line. Frame it as information, not defense; invite correction explicitly, because you
  may be the one who is wrong.
- **Needs your call** — anything `insufficient_context`, stated as a specific question.

Then request re-review.

Never post a comment that only says work is in progress. Never post before the push
lands, or reviewers will read the comment against the old diff.

## Anti-patterns

- **Capitulation.** Accepting every suggestion because the reviewer outranks you. If the
  tracker says a tradeoff was weighed, say so.
- **Reflexive pushback.** Reaching for "out of scope" because the fix is inconvenient.
  Scope is what `goal.md` says, not what is currently annoying.
- **Scope creep via review.** A reviewer suggestion is not authorization to widen the PR.
  Accept it as a follow-up and record it.
- **Duplicate posting.** Before commenting, check the child tracker's `events.jsonl` for
  an outward-facing action already recorded against this finding at this head.
- **Stale-diff disposition.** Classifying against a remembered diff instead of the current
  head. Re-read the diff every cycle.
