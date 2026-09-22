# Intake

Two modes. Both end the same way: the PR is in the registry, under the watch, with
its inherited state recorded.

## Mode A — the work already has a PR

**Run the admission baseline check before recording acceptance.** A PR admitted from
elsewhere is not a clean slate; it carries state nobody in your queue has looked at.
Admission is the moment you become accountable, so its gaps become yours whether or
not you caused them.

Check, and close or explicitly own each finding:

1. **Checks on the current head — enumerate them, do not trust the rollup.** A check
   that never ran is not a failure, so the rollup reads green. Look for failing,
   pending, and *absent* checks. An external app's check suite can sit queued with
   zero runs for days while everything looks fine.
2. **Review state.** Unresolved threads, unanswered reviewer or bot findings, any
   effective changes-requested. Apply the disposition rule below.
3. **Requested reviewers.** Is a human actually assigned? Is the notification team
   present? A PR with no requested reviewer is invisible and will sit indefinitely.
4. **Ticket association.** Does the body carry the repository's closing syntax? Without
   it nothing auto-closes and the work is untracked.
5. **Base and topology.** Does it target the trunk, or a real open prerequisite whose
   chain reaches trunk? Reject an artificial comparison base.
6. **Mergeability — verified with git, not the badge.** `git merge-tree --write-tree`
   against the live base. The hosting service has reported CONFLICTING for a
   fast-forward descendant and APPROVED for an approval that predates a semantic push.
7. **Age since the last substantive event** — a new head or a submitted review. Not
   since the last comment, and *not* since your own review requests.

Record the findings in the registry entry at admission so inherited state stays
distinguishable from anything you later cause.

## Mode B — a feature that lives in an integration branch

The work exists but has no PR. The job is to carve a reviewable unit out of a larger
branch without dragging the rest along.

1. **Decide the boundary first.** What is the smallest coherent change that delivers
   this feature and can be reviewed on its own? Name what is explicitly excluded.
2. **Choose the base.** Trunk if it stands alone. An existing open PR only if it
   genuinely depends on unlanded work — and then that PR must itself reach trunk.
3. **Create an isolated child worktree and branch.** Use the repository's own worktree
   tooling if it has any, so secrets and submodules are set up the way the project
   expects. Do not copy an entire integration tree to publish one subsystem.
4. **Reconcile only the selected commits there**, and validate the changed product
   path — not just that tests pass.
5. **Create the PR** using the repository's template and ticket syntax. Read the body
   back from the live API after creating it.
6. Then admit it as in Mode A. Your own work does not get less scrutiny for being
   yours; that is exactly when the baseline check gets skipped.

## The disposition rule

What a reviewer left determines what you owe:

- **Comments + approval** → make the fixes worth making, then merge. No re-request owed.
- **Comments only** → make the fixes needed, reply with reasoning to every other raised
  point, and **re-request review**. The re-request is mandatory. A reply is not a
  request; the reviewer will not otherwise know to look again.
- **Changes requested** → as comments-only for the work owed, and additionally blocks
  the gate until *that same reviewer* retracts. Resolving the thread does not retract
  it. Another reviewer approving does not clear it. Only a new review from them does.

Delivery-to-trunk overrides the merge branch of this rule: a stacked child with
comments+approval is not deliverable until its parent lands, so the approval is banked,
not spent.

## The registry is an allowlist

Membership is explicit. Never derive the queue from "all open PRs" — a busy repository
has dozens, and a watcher built on a listing will silently drop members as the count
grows. Keep membership in a file the watcher reads, keyed by PR number, and let
admission be the single act that both accepts custody and starts monitoring.
