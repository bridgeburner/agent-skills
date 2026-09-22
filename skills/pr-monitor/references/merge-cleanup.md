# Merge and cleanup

## The gate

Verify **immediately before merging**, live. Not from a snapshot taken minutes ago.

- Non-draft, and the base is the trunk — never another feature branch.
- Conflict-free, verified with git rather than the badge.
- **Human approval at the current head.** Automated reviews and green checks are not
  approval. Compare the approving review's commit to the head; an approval that predates
  a *semantic* change is not an approval. A purely mechanical conflict resolution does
  not stale it — see **Approval and mechanical reconciliation** below.
- Required checks complete and passing on that head — enumerated, not rollup-trusted.
  **A suite with zero runs is not passing.** "Absent is not failed" describes the
  rollup's blindness, not your disposition: a never-run check blocks this gate exactly
  as a failure does. Re-trigger it and wait for a real result. If it cannot be made to
  run, that is a named blocker you surface — never a gap you own into a merge. If you
  cannot tell which checks are *required*, read the base branch's protection rules;
  failing that, treat every context that ran on comparable recently-merged PRs as
  required.
- No outstanding actionable feedback, and no effective changes-requested.
- Whatever product proof the work required.

Then: expected-head guard pinned to the exact SHA, the repository's permitted merge
method, one merge at a time. Never an admin bypass, never a review dismissal, never
auto-merge on a head you have not inspected. Verify merged state, commit and timestamp
before treating it as delivered or merging anything downstream.

**Stacked PRs often reject the ordinary merge endpoint.** Try the ordinary merge first
and let it tell you — GitHub returns HTTP 403 "Merging stacked PRs via this endpoint is
not supported" when the PR has children. Do not reach for the asynchronous endpoint
pre-emptively; wait for that 403, because the right call depends on repository shape you
cannot see from here. On the 403:

    PUT /repos/{owner}/{repo}/pulls/{n}/merge-async
        sha=<exact head>  merge_method=merge  merge_action=direct_merge
    then poll GET /repos/{owner}/{repo}/pulls/{n}/merge-async/{uuid}

`merge_action` must be `direct_merge` — not `merge_queue`, not `default`. `merge_method`
is whatever the repository permits; the async endpoint does not relax that policy.

## Approval and mechanical reconciliation

A conflict resolution that faithfully preserves both intents is **mechanical, not
semantic**. The approval still applies to the work that was reviewed, so resolve, push
and merge. Do not stop for renewed review merely because the head moved — that
converts the approval from a means into the objective and stalls delivery.

"Mechanical" is your own claim, and your own claims get the same scepticism as a
delegate's. Record what you kept from each side and why no behavioural choice arose. If
you cannot write that down in two sentences, it was not mechanical.

Do stop when resolution demands a **new behavioural decision** — when two changes
genuinely cannot both hold and someone must choose what the system should now do.
That is semantic, it belongs to a human, and it is the one case worth the delay.

## Working a stacked chain

Only a PR based on trunk can merge, so the chain collapses one at a time. After each
merge the next child auto-retargets and usually becomes dirty, because the base it was
measured against is gone. Expect conflict counts to vary wildly between links — the
number tells you how much the parent disturbed, not how bad the child is.

Re-measure each child against trunk *after* its parent lands. Conflicts predicted
earlier are often stale in both directions.

**When the parent's head moves and it has not merged yet.** This is the common case,
and you will cause it yourself the first time you push a review fix to a parent. If the
child's base really is the parent's branch, the child updates on its own and there is
nothing to do — check that before acting. If it does not, merge the parent branch into
the child. Merge it; do not rebase, because rebasing a pushed branch needs a force push
and you do not force-push. Tell the child's reviewers what landed underneath them, since
their diff just changed without the author touching anything.

**Deciding whether content actually changed.** After a rebase or a parent merging, you
need to know whether a head move is new work or the same work on a new base. Settle it
by comparing **blob hashes** for the files in question — the contents API returns a
`sha` per path, and identical blobs mean the file did not move, which no amount of base
movement can make untrue.

Do not settle it by hashing the two diffs. A diff is a function of the base as well as
the head, so when the base moves the hunks change while the files do not — and a child
stacked on a parent that just merged fails that comparison on *every* file the two
touched in common. You then send a worker to review files nobody edited, and it has to
talk you out of your own false positive.

Read `behind_by` before believing any comparison. A parent advancing without the child
rebasing makes the merge base fall back, so the delta swells with the parent's own
commits; a child rebasing onto a merged parent makes it shrink sharply. Neither is
evidence about the change. And never hand a worker commit *titles* as evidence of what
changed — a rebase rewrites every commit, so old work carries fresh timestamps.

Check the response size before trusting any of this: a failed fetch returns empty, which
hashes exactly like a change that deleted everything.

## Cleanup, when a PR merges

Trigger on **the PR merging**, not on you merging it. A human may merge it while your
agent is mid-flight, and sessions and worktrees leak if the trigger is ownership.

Order matters — verify, then destroy:

1. **Confirm the commits are in trunk**, with `git merge-base --is-ancestor`, not the
   PR's merged flag.
2. **Confirm nothing is running** in the worktree, and that the agent has finished.
3. **Inspect anything untracked before forcing a removal.** Untracked content may be a
   nested checkout with unique work. Check its head, its dirty state, and whether an
   identical copy exists elsewhere. That inspection is what justifies `--force`; do not
   assume disposability.
4. **Close the agent session.**
5. **Remove the worktree and branches**, and prune stale remote-tracking refs.
6. **Archive this PR's record** — the per-item brief, lease and result, not the
   queue-wide tracker, which outlives every individual PR. Write a durable summary:
   delivery pins, what was removed, where the substantive record now lives, and any
   deferred follow-up. Verify the archive exists, *then* delete the evidence, never the
   reverse. Say plainly in the summary that those files are gone so nobody cites them
   as available. Leave a retired pointer at the old path so links resolve, and drop the
   PR from the active allowlist so the watch stops carrying it.
7. **Reclaim scratch build directories.** Long builds leave large caches, often outside
   the worktree. They survive the cleanup that should have taken them and accumulate
   until the disk fills. Verify nothing holds them — count matching processes properly,
   because a careless shell test reports false positives — then remove.
8. **Check the ticket closed.** Closing syntax usually auto-closes on merge; confirm
   rather than assume, and never close a ticket whose PR is still open.

## Handing off

If another owner integrates delivered changes or performs cleanup, write the handoff
and retain custody until they acknowledge. If cleanup is yours, do it immediately —
a merged PR whose worktree lingers is how disks fill and stale branches multiply.
