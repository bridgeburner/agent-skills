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

**And read the remote, not your checkout.** Your local tree is the branch as of the last
pull, and in a busy repository that drifts fast — a checkout can fall hundreds of commits
behind in a day. It is also the cheapest thing to read, so it is what you reach for on
exactly the questions that end up in a published reply: does this caller still exist, is
this path ignored, does that test cover this.

    gh api -H "Accept: application/vnd.github.raw" "repos/O/R/contents/PATH?ref=main"
    git fetch origin main -q && git show origin/main:PATH

Read a PR head the same way, at `?ref=<head sha>`. **The tell is easy to miss:** when
your local read contradicts the author, the instinct is to doubt the author. Doubt the
checkout first — they are looking at what they just changed, and you are probably
looking at a stale file.

## Three verdicts

### fix

Any one of these is enough. They are common cases, not a closed list — if a comment is
simply right and you have no ground to push back, fix it. "It matches no bullet" is not
a reason to argue with a reviewer who is correct.

- A reproducible defect — you can write a test that fails before and passes after.
- A contract or API break, a silent failure, a swallowed error, an unsafe fallback.
- A security or data-exposure issue.
- A spec violation you can cite.
- Wrong behaviour for an input the code explicitly claims to handle.
- **Cheaper than the argument.** If the change costs less than the discussion about it,
  make it — even when you think their version is slightly worse. Naming, a missing
  guard, a clearer message, a test they want. A shepherd that argues over trivia is
  worse than one that over-complies, and a two-line rename is never worth a round trip.

### pushback

Permitted only when **all three** hold:

1. One of these grounds applies:
   - The premise is factually wrong and you can demonstrate it — the code does not do
     what the reviewer believes.
   - Already handled elsewhere, and you can cite file and line.
   - Genuinely outside this PR's declared scope, **and** you record a follow-up
     somewhere durable. If you are not authorised to write to the issue tracker, record
     it in the PR thread and queue the tracker text for the user — the point is that it
     survives, not which system holds it. Do not push back with "later" and no record.
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
real things. Fix what is genuine and reply to the rest. When a round turns up only
style notes and things you have already answered, stop **changing code** — the replies
still go out. What costs you is moving the head while a human approval is pending, not
the words. A reply moves nothing.
