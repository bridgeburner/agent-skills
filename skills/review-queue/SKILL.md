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

## Maintain pr-review-queue.md

Keep `pr-review-queue.md` in the project's local tracker, outside implementation
worktrees. Reuse the existing location; otherwise use
`~/.sdd/<project>/review-queue/pr-review-queue.md`. Start from
[the queue template](templates/pr-review-queue.md).

This file owns the tracked PRs, review status, findings, and action history.
Link longer evidence instead of copying it into multiple trackers. The session
coordinator alone updates the queue and publishes external actions. Before taking
over an existing queue, reconcile any pending actions and active workers; do not
run two publishing coordinators against the same queue.

## Review a new PR

Delegate one Astra/low (`gpt-6-astra`, low effort) agent per PR unless the user
selects another model. That PR agent:

1. Reads the PR, relevant specs/tickets, source, and existing discussion. Explains
   the root problem, larger feature, required outcome, and important constraints.
   Establishes the exact head, actual base, and stacked dependencies.
2. Delegates the review to subagents using `better-review`, carrying that context,
   exact source identities, prior findings, and read-only authority into each
   assignment. Split useful independent concerns; one reviewer suffices for a
   small PR. Respect the harness's total concurrency limit and leave room for
   the reviewers rather than filling all slots with coordinators.
3. Reconciles their findings against reachable behavior and affected consumers.
   Removes duplicates and unsupported concerns. Returns issues with severity,
   changed-line location, evidence, minimal remedy, and verification limits.

The session coordinator checks the conclusions, then publishes a top-level
summary and inline comments for new issues. Reuse an existing thread for the
same issue. Only P0/P1 block approval; otherwise approve the reviewed commit
and retain P2/P3 findings. Do not approve your own PR.

Use Git objects for inspection by default. Create an isolated checkout only
when a useful execution check needs it. Run checks proportional to changed
behavior; distinguish source inspection, synthetic probes, tests, CI, and live
product evidence. No `better-goal` dependency or default per-PR worktree.
If required delegation or a selected model is unavailable, report that limit
instead of silently claiming the requested review process ran.

## Check a previously reviewed PR

Fetch its current state, commits, reviews, checks, and discussion since the
recorded review. Keep our approval separate from others' decisions and CI.

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
- No remaining P0/P1: approve the current reviewed commit, replacing our earlier
  changes-requested decision. Unverified fixes remain open.

## Publish any review or follow-up

Before publishing, confirm the PR is still open at the reviewed head. Record
the intended action and target; read back the result and save its ID. A timeout
means unknown outcome: check for success before retrying. Do not duplicate an
unchanged review or reply. Failed reads leave the prior state visibly stale.

## Sweep

When the assigned session receives "sweep", check every active PR in the queue
using the process above. Run independent checks concurrently. Finish authorized
replies, resolutions, approvals, queue updates, and dashboard refresh. Report
meaningful changes, remaining blockers, and anything that could not complete.

## Add or retire PRs

Add PRs explicitly selected by the user, avoiding duplicates. Verify any admission
filters, including direct versus team review requests and approvals by anyone.
Keep approved PRs active until merged or closed. Move merged/closed PRs to the
appropriate history section with findings and final disposition intact; merging
does not prove an issue was fixed. Retire other PRs only at the user's request.
Do not merge, implement fixes, or start scheduled monitoring under this role.

## Create and refresh the dashboard

During setup, create a running dashboard once its location and publication are
authorized. Prefer the user's existing hosting mechanism; record its address and
refresh instructions. Read-only assignments do not authorize creating or
publishing a dashboard. Derive data from `pr-review-queue.md`, never a second
editable queue. A generated JSON snapshot is fine.

Show active PRs, review progress, our approval, outstanding findings, and snapshot
time; show merged history below. Keep CI and other reviewers' decisions separate.
Refresh after queue changes and sweeps. Reuse the existing site and preserve its
audience. Verify deployment and live data before claiming publication; a reserved
URL is not a running dashboard. Keep credentials and raw evidence out of published
assets. The dashboard displays the last sweep, not continuous GitHub monitoring.
