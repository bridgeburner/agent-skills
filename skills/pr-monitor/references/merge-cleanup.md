# Merge and cleanup

## The gate

Verify **immediately before merging**, live. Not from a snapshot taken minutes ago.

- Non-draft, and the base is the trunk — never another feature branch.
- Conflict-free, verified with git rather than the badge.
- **Human approval at the current head.** Automated reviews and green checks are not
  approval. Compare the approving review's commit to the head; a stale approval is not
  an approval.
- Required checks complete and passing on that head — enumerated, not rollup-trusted.
- No outstanding actionable feedback, and no effective changes-requested.
- Whatever product proof the work required.

Then: expected-head guard pinned to the exact SHA, the repository's permitted merge
method, one merge at a time. Never an admin bypass, never a review dismissal, never
auto-merge on a head you have not inspected. Verify merged state, commit and timestamp
before treating it as delivered or merging anything downstream.

**Stacked PRs often reject the ordinary merge endpoint.** GitHub returns HTTP 403
"Merging stacked PRs via this endpoint is not supported" when the PR has children. The
documented fallback is the asynchronous endpoint:

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
