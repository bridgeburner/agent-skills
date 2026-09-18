# Continuous monitoring (Claude Code)

This supplements [SKILL.md](../SKILL.md) for a Claude Code session that the user
has authorized to watch the queue instead of waiting for a `sweep`. Everything
not covered here is unchanged: the queue files, discovery rules, review process,
severity and approval conditions, and publication duties all still govern.

Do not arm a watch on capability alone. The goal contract must record the
authority, because a later session reads that contract to decide what this role
may do. If the contract still prohibits monitoring, amend it with the user's
decision first.

## Hold the watch

Use the `Monitor` tool with a polling script over the repository's PRs. One
stdout line is one event, so the script must print only changes worth acting on.

Baseline every comparison against the identities already recorded per PR in
`pr-review-queue.md`: `head_sha`, `base_sha`, and `reviewed_sha`. A change is
"new" when it differs from what we actually reviewed, not from whatever the
previous poll happened to see. That keeps the watch correct across re-arms,
session restarts, and a missed interval.

- Poll no faster than sixty seconds. Remote API limits, not freshness, set this.
- Tolerate transient failures (`|| true`) so one bad response cannot end the watch.
- Keep a small state file of already-reported events so a re-arm does not refire
  the same commit or comment. Treat it as a cache; the queue remains the truth.
- A monitor expires at its deadline. Re-arm it, and treat an unexpectedly silent
  expiry as a reason to widen the filter, never as proof the queue was quiet.
- Record arming, expiry, and re-arming in `events.jsonl`. A watch that no one can
  reconstruct is not durable coordination.

## What counts as an event

Emit for any of these, naming the PR and what changed:

| Signal | Why it matters |
|---|---|
| New head commit | Possible new behavior against our findings, or a rebase to verify |
| Base change | Our reviewed merge base may no longer hold |
| New review by anyone | Kept separate from our own approval |
| New comment or author reply | Often pushback on an open finding, which we must assess on merits |
| Resolution of a thread we opened | Resolution alone is not proof of a fix |
| Merged or closed | Moves to history with findings and disposition intact |
| Check conclusion change | Reported separately from our decision, never as a substitute for it |

Also watch for PRs newly matching the queue's configured discovery filters.
Surface them to the user. A surfaced candidate is not an admission and does not
advance `last_admission_at`.

## Dispatch one worker at a time per PR

An event names the PR to look at. It does not define the job: the worker assesses
that PR's current state, so several events arriving close together are one piece
of work rather than several. Never let an event trigger a whole-queue pass.

Hold at most one worker in flight per PR, and enforce it with a lock rather than
with attention. A push and a reply landing in consecutive cycles otherwise put
two workers on one PR, and two workers can reach different conclusions about the
same finding, which the coordinator would then publish onto the same thread.

- Before dispatching, check for that PR's lock in the watch state directory. If
  one exists, append the event to the PR's pending list and dispatch nothing.
- Write the lock with the worker's identifier and start time, so a later session
  can tell a running worker from an abandoned one.
- When the worker returns and its result is published, clear the lock. If events
  accumulated meanwhile, dispatch once against the PR's current state, not once
  per queued event.
- Treat a lock whose worker is no longer running as releasable, and say so in the
  event ledger when releasing one. A dead worker must not wedge a PR forever.

Delegate through the `codex-cli` skill under the queue's recorded model policy.
Verify an unfamiliar model identifier against the harness's own model listing or
current vendor documentation before the first dispatch of a session. A slug
recalled from memory can be confidently wrong, and a rejected model surfaces as a
failed run rather than as a fallback, which the main skill already requires you to
report rather than paper over. A tiered policy routes by the kind of work, not by
PR size:

- **Deterministic and verifiable** work, where the answer can be checked against
  the source: patch-equivalence of a rebase, whether a finding's lines moved,
  merge and close classification.
- **Review and judgment** work: assessing author pushback, reassessing findings
  against changed behavior, deciding whether a concern survives.

Give the worker a read-only sandbox. It inspects Git objects and the PR; it does
not need write authority, and withholding it removes a whole class of accident.

Every handoff carries the queue contract, that PR's saved brief and prior
dispositions, the exact old and new commit identities, and the open findings with
their thread IDs. A worker told only "PR #123 changed" will rediscover reasoning
the queue already paid for, and may reopen a concern the user already settled.

## The coordinator still publishes

The worker assesses and writes its assigned evidence. The session coordinator
posts the reply, resolves our own thread, renews or withholds approval, reads the
result back, and appends the event. This is the same serialization rule the main
skill states, and a watch makes it matter more: concurrent events on one PR would
otherwise race on the same thread.

## Dashboard as an artifact

Where the harness publishes private pages, build the dashboard with the
`Artifact` tool rather than an external site. Derive it from
`pr-review-queue.md`, exactly as before; a generated JSON snapshot embedded in
the page is fine, and a second editable queue is still forbidden.

Republish to the same URL by passing that artifact's `url`, so the address the
user has kept stays valid. Read the artifact before republishing when this
session did not publish it. Keep credentials and raw evidence out of the page,
and keep the audience as narrow as the user set it.

Refresh after any event that changes queue state, not on a timer. Say plainly
that the page reflects the last observed event.

## Know the boundary

A watch lives in the session that armed it. It stops when that session ends, and
it is not a scheduled job. Tell the user this rather than leaving them believing
the queue is covered while nothing is running. On takeover, a previous session's
recorded watch does not mean a watch is live now; confirm or re-arm.
