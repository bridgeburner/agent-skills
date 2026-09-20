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

Track a candidate by an eligibility fingerprint, not a one-shot ledger. A PR
opened minutes ago often carries no review request yet, so a filter that checks
once and records the number as seen will suppress it permanently, including at
the moment it becomes admissible. Record the inputs the filters actually read,
such as the configured review requests and the review count, and emit again when
those change. An unchanged ineligible PR then stays quiet without going blind to
the change that would qualify it.

Separate terminal exclusions from recoverable ones. A PR that has picked up an
approval can no longer qualify under a no-current-approval filter, so drop it
from tracking rather than re-emitting each time its review count moves. A missing
review request is recoverable, because one can be added at any time, so keep
watching that. Filtering the terminal cases in the poll and leaving the
judgement calls to the coordinator keeps the event stream worth reading. Keep the
watch's own admission cutoff in step with the queue metadata, or discovery
silently re-proposes PRs already decided.

That cutoff gates new proposals only. A candidate already surfaced stays watched
whatever the cutoff later becomes, because every admission advances it past PRs
whose eligibility you are still waiting on, and dropping them there would end the
watch at exactly the moment a review request might arrive. Keep a tracked
candidate until it is terminally excluded, closed or admitted, not until it falls
out of the window.

Announce every exit from tracking, whatever causes it. A candidate you surfaced
to the user disappears through more paths than merging: it can close, pick up an
approval that makes it permanently ineligible, or go back to draft. Each of those
leaves them believing it is still pending. Rather than patching the paths one at
a time as you find them, record a reason whenever a tracked candidate is about to
be dropped and report all of them together at the end of the cycle. The rule is
that nothing leaves the tracked set silently.

Reconcile after a busy batch. Several events can arrive together, and acting on
the prominent ones while quietly dropping a quieter one is a coordinator failure
the watch cannot catch: detection worked, the follow-through did not. After any
batch carrying more than two or three events, re-read the tracked candidates and
confirm none has become eligible without being admitted. It costs one pass and
it is the only check that catches an event you read and then forgot.

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
  the source: whether a finding still applies at a new head, merge and close
  classification.

Settle rebase equivalence yourself before delegating it. Compare the two heads
by content, not by diff. Take the changed files at the new head and compare each
one's git blob hash to the same path at the previously reviewed head, which the
contents API returns as `sha`. Identical blobs mean the file did not move, and no
amount of base movement can make that answer wrong.

Do not settle it by hashing the two three-dot diff payloads. A diff is a function
of the base as well as the head, so when the base moves the hunks change while the
file does not, and the comparison reports files as changed that are byte-identical.
That failure is not rare: a PR stacked on a parent that merges will fail it on
every file the two touched in common. When it fires you delegate a review of files
nobody edited, and the worker then has to talk you back out of your own false
positive. Blob hashes cost one request per changed file and cannot drift this way.

Whichever read you make, check the response size before trusting it: a failed or
timed-out fetch returns empty, which hashes exactly like a change that deleted
everything, so a transient network error can otherwise read as a wholesale
reversion. Retry the read rather than acting on the empty one.

Read `behind_by` before interpreting any comparison. When a stacked parent
advances without the child being rebased, the merge base falls back and the
three-dot delta swells to include the parent's own commits, so file counts and
line totals change for reasons that have nothing to do with the PR. That state is
stale-and-awaiting-rebase, not changed, and reporting it as new work would send a
reviewer hunting for edits the author never made. The mirror case is a parent that
merges and a child that rebases onto it: the delta then shrinks sharply, often by
dozens of files, because the parent's work now lives in main rather than in the
branch. Neither the swelling nor the shrinking is evidence about the change.

When you do delegate a rebase reassessment, tell the worker what you already
established and hand it only the files that genuinely moved. State plainly in the
brief that finding nothing is a valid and expected outcome, or you invite a
reviewer to justify its run by manufacturing a finding. Delegating it
to a reasoning model costs minutes and returns a verdict that still needs
interpreting, because a strict reading calls any changed context a change even
when the payload is untouched. Check `reviewDecision` too: when the provider
still counts the existing approval at the new head, re-publishing adds noise to
the PR without changing anything. Reserve the deterministic tier for what a hash
cannot answer.
- **Review and judgment** work: assessing author pushback, reassessing findings
  against changed behavior, deciding whether a concern survives.

Sandbox policy is the user's call, and on some machines an unsandboxed run is the
only one that works, because a read-only Codex sandbox also cuts the network the
worker needs to read the PR. When the user has authorized running without a
sandbox, the boundary stops being enforced by the runtime and has to be carried
in the handoff instead. Say plainly in the prompt that the worker assesses only:
no repository edits, commits, pushes, comments, reviews, approvals, or thread
resolutions, whatever credentials it happens to inherit. A worker running without
a sandbox holds the same provider credentials as the coordinator, so the rule
that the coordinator owns every external write is now a prompt-level instruction
rather than a wall. Check the returned result against that boundary instead of
assuming it held.

Every handoff carries the queue contract, that PR's saved brief and prior
dispositions, the exact old and new commit identities, and the open findings with
their thread IDs.

Name the outcome to assess, not the verdict. A brief that declares what counts as
blocking will get that verdict back: a reviewer told "a gate that reports but does
not block reproduces the problem" will rank an unenforced check as a blocker even
when the PR cannot fix it, the author disclosed it, and someone already raised it.
Describe what the change claims and where a defect would hurt, then let severity
follow from what is found. When a returned finding cites the brief as its reason,
treat that as the brief marking its own homework and re-decide it on the merits. A worker told only "PR #123 changed" will rediscover reasoning
the queue already paid for, and may reopen a concern the user already settled.

## The coordinator still publishes

The worker assesses and writes its assigned evidence. The session coordinator
posts the reply, resolves our own thread, renews or withholds approval, reads the
result back, and appends the event.

Then refresh the watch baseline for that PR. Our own review, comment or
resolution changes the same counts the watch compares, so without this the next
cycle reports our publication back to us as if the author had acted. Re-seed the
PR's entry from live state after every write, and treat an event that exactly
matches something just published as an echo to verify rather than a change to
act on. This is the same serialization rule the main
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
