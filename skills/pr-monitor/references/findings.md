# Disposing a single finding

Governs how one reviewer or bot finding becomes **fix**, **pushback**, or
**insufficient context**. The disposition rule in `intake.md` says what you owe a
reviewer overall; this says what you do with each thing they raised.

## Ground first, classify second

Before classifying, establish what the PR is actually for, what it declared out of
scope, and what was already tried or deliberately decided against. Wherever that
history lives — a tracker, the PR body, earlier review threads, the commit series —
read it. Classifying without it produces reflex, not judgement.

**Verify the claim at source before accepting or rejecting it.** Findings are
plausible, not proven. Do not change code to satisfy a wrong report, and do not
dismiss one that happens to be right about a line you did not read.

## Three verdicts

### fix

Any one of these is sufficient:

- A reproducible defect — you can write a test that fails before and passes after.
- A contract or API break, a silent failure, a swallowed error, an unsafe fallback.
- A security or data-exposure issue.
- A spec violation you can cite.
- Wrong behaviour for an input the code explicitly claims to handle.
- **Cheap and clarifying.** If the fix is smaller than the argument against it, make it.
  Naming, a missing guard, a clearer message, a test they want — relitigating costs more
  than complying. A shepherd that argues over trivia is worse than one that over-complies.

### pushback

Permitted only when **all three** hold:

1. One of these grounds applies:
   - The premise is factually wrong and you can demonstrate it — the code does not do
     what the reviewer believes.
   - Already handled elsewhere, and you can cite file and line.
   - Genuinely outside this PR's declared scope, **and** you record a tracked follow-up.
   - Speculative with no concrete failure case.
   - It would regress a deliberate decision whose rationale still holds.
2. You can name the specific evidence — file, line, commit, test.
3. It is not merely a preference. "I'd rather not" is not a ground.

### insufficient context

When you cannot honestly reach either:

- Nothing on record covers the area and the code alone cannot settle it.
- It needs a product, design or policy decision.
- It depends on environment, credentials or infrastructure you cannot inspect.

**Absence of evidence yields insufficient context, never pushback.** This is the rule
that matters most. A pushback grounded in nothing is refusal wearing evidence's
clothes. Escalate with the specific question instead.

## Whatever the verdict, reply

A finding the source disproves still needs a recorded, reasoned reply. "Disproved" is
not "ignorable", and silence is not disposition — the next baseline pass will surface
it again as unanswered, and the reviewer will never learn why you disagreed.

Avoid duplicate adequate replies. If an earlier disposition already answers a re-raised
point, say so and link it rather than re-arguing.

## Spend reasoning unevenly

A **fix** is cheap to be wrong about — you make a small change you did not strictly
need. A **pushback** is expensive to be wrong about: you have told a reviewer they are
mistaken, and if you are wrong you have both kept the defect and spent their goodwill.
Weight your effort accordingly. When genuinely balanced, fix.

## Bots are not approvers

A bot finding deserves a reasoned answer and never constitutes approval. Expect each
push to trigger a fresh automated review; that loop terminates when it stops finding
real things. Fix what is genuine, reply to the rest, and stop engaging when a round
produces only style and repeats — churning the head has a real cost when you are
waiting on a human approval.
