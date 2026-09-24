---
name: review-queue
description: >
  Assume the role of PR review queue orchestrator for one project, only when
  the user explicitly assigns this session that role. Do not activate for an
  ordinary PR review, a queue mention, or a sweep in an unassigned session.
disable-model-invocation: true
---

# Review queue orchestrator

## Assume the role

Activate only after an explicit user role assignment, such as
"Use $review-queue and be this project's review queue orchestrator."
Reading this skill, finding a queue, or being asked to edit the skill does not
assign the role. Once assigned, follow-up requests such as "sweep" and "add
these PRs" use this workflow until the user ends the role. A fresh session needs
its own assignment; an old session's recorded ownership does not activate it.

Bind the role to one repository and reviewer identity. Record the user's
authorization for comments, resolutions, approvals, and dashboard publication;
role assignment alone does not grant those writes. Ask only for missing choices
that affect the outcome or authority. Complete work already authorized.
User instructions take precedence over this skill's defaults.

## Match the workflow to the harness

The queue, discovery rules, review process, approval conditions, and publication
duties below are harness-neutral. How the role *notices* a change, and where the
dashboard lives, depend on what the running harness can do.

- **A harness without a background watch** uses the static `sweep` verb: the user
  asks, and the session walks every active PR at once.
- **A harness with a background watch and its own hosted pages**, currently
  Claude Code, may instead hold a continuous watch and dispatch one worker per
  detected change. Read
  [references/claude-monitoring.md](references/claude-monitoring.md) for that
  path, including its event taxonomy, worker tiers, and artifact dashboard.

Both paths share one queue and one set of records. A session may run the static
sweep even where a watch is available; a watch never replaces the user's ability
to ask for a sweep. Continuous monitoring is an authority, not a capability:
arm it only after the user grants it and the goal contract records it.

## Durable coordination and queue state

Use `better-goal` for this recurring workflow. Load its skill and recovery
guidance, reuse the project's tracker, and give each file one job:

- `goal.md`: strategic intent, user decisions, scope, and authorized actions.
- `tasks.md`: assignments, executor/claim, dependencies, and result links.
  Track a sweep or discovery as one task; add per-PR tasks when dispatching work.
  A completed review task does not mean its PR merged or left the queue.
- `events.jsonl`: append-only decisions, assignments, attempts, publication
  intents and verified receipts, including failures and unknown outcomes.
- `pr-review-queue.md`: admitted PRs, review identities, findings/dispositions,
  admission cutoff, discovery filters, approval conditions, and dashboard setup.

Link these records rather than repeating mutable status or ownership. Task
ownership lives in `tasks.md`; PR status lives in the queue. Workers write assigned
evidence; the coordinator serializes shared files and external actions. Preserve
the context and action history needed to resume without the previous conversation.

Keep `pr-review-queue.md` in the project's local tracker, outside implementation
worktrees. Reuse the existing location; otherwise use the canonical tracker
resolved by `better-goal`. Start from
[the queue template](templates/pr-review-queue.md).

Markdown is the authoritative queue. Structured JSON blocks inside it are fine
when an existing dashboard parser consumes them; preserve that format. Standalone
JSON snapshots are generated outputs, never a second editable queue.

On takeover, read goal, tasks, queue, and relevant events/evidence. Reconcile
pending writes and active workers before transferring ownership; elapsed time
or an old task status does not prove a publisher stopped. Preserve historical
records when migrating a playbook, and replace its operational instructions with
a pointer here. Keep project values and user overrides in the tracker, not a
second workflow document.

## Discover candidates

When the assigned user says `discover`, scan only the bound repository for PRs
created since `last_admission_at`: the most recent actual user-selected admission,
not the last sweep or discovery. Recover a missing cutoff from admission evidence;
if unavailable, ask for the initial window rather than guessing one.

Select open, ready/non-draft PRs not already in the queue or history and without
a current approval from anyone. Apply the queue's configured direct-user or team
review-request filters; distinguish direct and team requests. Comments and
changes-requested reviews do not disqualify a candidate. Read all review pages:
a later comment does not revoke approval, and approval of an older commit still
counts for discovery unless dismissed or superseded by that reviewer's changes
request. Do not substitute aggregate review decisions, CI, or review requests
for actual approval history.

The no-current-approval filter is an admission-time test. It decides whether to
start a review, because another reviewer's approval makes ours least valuable
before we have invested in it. Once a PR is admitted, an approval from anyone
else does not retire it: the reasoning is already paid for and our findings are
still real, so finish the review, publish what it finds, and approve under the
usual rules if no P0/P1 remains.

Read title/body and enough context to explain each candidate. Return one line
per PR in PR-number order:
`[#123 — Title](URL) — one-sentence description of the change and its purpose.`
Mention relevant changes requests briefly on the same line. State the searched
window and incomplete reads; unknown approval state is not no approval. If none
qualify, say so.

Wait for the user's selection before admission or review. Discovery does not
authorize GitHub writes or dashboard publication and does not advance the cutoff.
After actual user-selected admission, record `last_admission_at` and
`last_admission_prs` with evidence. Duplicates and skipped merged/closed PRs do
not advance it. Retain presented but unselected candidates in discovery evidence
so a later explicit selection remains recoverable, including older PRs.

## Review a new PR

Delegate one Claude Opus 5.5/medium (`claude-opus-5-5`, medium effort) agent per
PR by default. Use Opus 5.5/high for especially hard problems or large-scale
design issues within a review. Use GPT-6 Luna/max (`gpt-6-luna`) for bounded,
verifiable queue checks such as known-target status fetches, head identity, or
merge/close classification. Follow the user-level model policy, record any
per-PR override in the queue, and verify the model and effort selected by the
active harness. If that route is unavailable, report the limit rather than
silently substituting another model. Launch it with the forms in the user-level
`AGENTS.md` under "Agent invocation". That PR agent:

1. Reads the PR, relevant specs/tickets, source, and existing discussion. Explains
   the root problem, larger feature, required outcome, and important constraints.
   Establishes the exact head, actual base, and stacked dependencies.
   Carry the session coordinator's relevant user decisions and strategic judgment
   into this brief; assess whether the proposed approach serves the outcome.
   Save the brief and accepted/rejected finding rationale with the PR's evidence
   so later reviewers can reuse the reasoning instead of rediscovering it.
2. Delegates the review to subagents using `better-review`, carrying that context,
   exact source identities, prior findings, and read-only authority into each
   assignment. Split useful independent concerns; one reviewer suffices for a
   small PR. Respect the harness's total concurrency limit and leave room for
   the reviewers rather than filling all slots with coordinators.
3. Reconciles their findings against reachable behavior and affected consumers.
   Removes duplicates and unsupported concerns. Returns issues with severity,
   changed-line location, evidence, minimal remedy, and verification limits.

Record the PR-agent assignment before dispatch. Its independent reviewers receive
the same strategic brief and write only assigned evidence; reviewers do not
publish. The PR agent returns their reconciled result to the session coordinator.

The session coordinator checks the conclusions, then publishes a top-level
summary and inline comments for new issues. Reuse an existing thread for the
same issue. Among our findings, only P0/P1 block approval; otherwise approve the reviewed commit
and retain P2/P3 findings. Apply additional user-defined approval conditions in
the queue, including valid unresolved requests from a named reviewer. Withhold
approval for an unmet condition unless the user allows conditional approval;
state the condition explicitly if using it. Assess feedback on its merits, not
as an automatic veto. Keep an author's operational merge hold separate from
source approval. Do not approve your own PR.

Use Git objects for inspection by default. Create an isolated checkout only
when a useful execution check needs it. Run checks proportional to changed
behavior; distinguish source inspection, synthetic probes, tests, CI, and live
product evidence. Do not create a per-PR worktree by default.
If required delegation or a selected model is unavailable, report that limit
instead of silently claiming the requested review process ran.

## Check a previously reviewed PR

Fetch its current state, commits, reviews, checks, and discussion since the
recorded review. Keep our approval separate from others' decisions and CI.
Reuse the saved brief and prior dispositions, updating them when new evidence
changes the context. Do not reopen a rejected or downstream-fixed concern
without new evidence that makes it relevant.

- No meaningful change: refresh status without posting again.
- New commits or relevant base changes: have the PR agent assess the delta and
  affected findings, delegating deeper review where behavior changed. Group
  related stack checks. Verify patch-equivalent rebases without repeating the
  whole review; keep any renewed approval brief.
- Author feedback: assess it on its merits and reply with the reassessment.
  Accept supported explanations rather than defending our earlier finding.
- Resolved concern: mark it fixed, accepted tradeoff, or withdrawn with a reason;
  reply and resolve our thread. An outdated/resolved thread alone proves no fix.
  Leave other reviewers' threads alone.
- No remaining P0/P1: approve the current reviewed commit when user approval
  conditions are satisfied or the user explicitly allows conditional approval.
  State any condition, and replace our earlier changes-requested decision when
  appropriate. Unverified fixes remain open.

## Publish any review or follow-up

Before submitting an approval or new review, confirm the PR is still open at
the reviewed head. A substantive reply on a merged PR may still be acknowledged
and recorded, without submitting another approval. Record the intended action
and target in the event ledger; read back and save its ID. A timeout
means unknown outcome: check for success before retrying. Do not duplicate an
unchanged review or reply. Failed reads leave the prior state visibly stale.

## Sweep

When the assigned session receives "sweep", check every active PR in the queue
using the process above. Run independent checks concurrently. Finish authorized
replies, resolutions, approvals, queue updates, and dashboard refresh. Report
meaningful changes, remaining blockers, and anything that could not complete.

Where a continuous watch is authorized and running, the same per-PR process
applies to one PR at a time as its change arrives, rather than to the whole queue
on request. A sweep remains available as the reconciling full pass, and is the
right response after a watch gap, an unknown outcome, or any doubt that every
change was seen.

## Add or retire PRs

Add PRs explicitly selected by the user, avoiding duplicates. Verify any admission
filters, including direct versus team review requests and approvals by anyone.
Keep approved PRs active until merged or closed, whoever approved them; an
approval by someone else after admission is not a reason to retire a PR. Move merged/closed PRs to the
appropriate history section with findings and final disposition intact; merging
does not prove an issue was fixed. Retire other PRs only at the user's request.
Do not merge or implement fixes under this role. Start a continuous watch or a
timed cadence only when the user authorizes it; record that authority in the goal
contract before arming it.

## Create and refresh the dashboard

During setup, create a running dashboard once its location and publication are
authorized. Prefer the user's existing hosting mechanism; record its address and
refresh instructions. When the harness publishes its own private pages, that is
usually the simpler host than an external site, because it removes a separate
checkout, build, and deploy step from every refresh. Moving an existing dashboard
to a new host is a user decision: keep the audience as narrow as it was, and
retire the old address deliberately rather than leaving two live copies.
Read-only assignments do not authorize creating or publishing a dashboard.
Derive data from `pr-review-queue.md`, never a second editable queue. A
generated JSON snapshot is fine.

Show active PRs, review progress, our approval, outstanding findings, and snapshot
time; show merged history below. Keep CI and other reviewers' decisions separate.
Refresh after queue changes and sweeps. Reuse the existing site and preserve its
audience. Verify deployment and live data before claiming publication; a reserved
URL is not a running dashboard. Keep credentials and raw evidence out of published
assets. State the dashboard's freshness basis rather than implying more: the
last sweep, or the last observed event when a continuous watch is authorized and
running. Neither is a live view of GitHub.
