# Merge Gate and Post-Merge Cleanup

Loaded only when a PR looks mergeable, or has merged since the last tick. Every
precondition here is a **check**, never an inference. Both phases are irreversible.

## Phase 1 — Fresh readback

Workflow-start state is minutes stale. Re-read immediately before deciding, in one call:

```bash
gh pr view <n> --repo <repo> --json \
  number,state,isDraft,mergeable,mergeStateStatus,headRefOid,reviewDecision,latestReviews,statusCheckRollup,autoMergeRequest
```

Plus unresolved threads (see the GraphQL query in `SKILL.md` §5).

## Phase 2 — The gate

Merge only if **every** condition holds. Any failure ends the merge attempt for this tick.

1. `state == "OPEN"` and `isDraft == false`.
2. `mergeable == "MERGEABLE"` and `mergeStateStatus` is not `DIRTY` (conflicted) or
   `BEHIND` where the branch protection requires up-to-date.
3. Every required check has `conclusion == "SUCCESS"` **for `headRefOid`**. Pending is not
   green. A success recorded against an older SHA is not green.
4. `reviewDecision == "APPROVED"`.
5. The approving review is at or after `headRefOid`. If the approval predates the current
   head, it is stale — usable only after you have reconciled the current head and every
   newer review submission against your last disposition.
6. No unresolved review thread maps to an unaddressed actionable finding.
7. Every actionable current-head finding is either fixed or explicitly pushed back, with
   the pushback posted.
8. **No review arrived since your last disposition.** If one did, abort the merge, load
   `references/disposition.md`, and route it through disposition instead. This is the
   condition most easily lost to optimism — check the newest review timestamp against
   your recorded disposition, do not assume.

If `--report-only` is set, stop here and report that the gate passed.

## Phase 3 — Merge

Which command depends on whether you pushed during this cycle, because a push dismisses
the approval the gate just verified:

**Nothing pushed this cycle** — approval is intact and current:

```bash
gh pr merge <n> --repo <repo> --squash --delete-branch
```

**Fixes pushed this cycle** — the approval is now dismissed; arm auto-merge instead:

```bash
gh pr merge <n> --repo <repo> --auto --squash --delete-branch
```

Set the registry status to `awaiting-approval` and stop. GitHub lands it the instant a
human approves, including long after this session ends. Do not hold the loop open waiting,
and never try to preserve or re-apply a dismissed approval.

Record the merge in the child tracker's `events.jsonl` **before** moving on — it is an
outward-facing action, and context is mortal.

## Phase 4 — Verify the merge landed

Cleanup is destructive. Do not run any of it until both checks pass:

```bash
gh pr view <n> --repo <repo> --json state,mergedAt,mergeCommit   # state must be MERGED
git -C <main-repo> fetch origin main --quiet
git -C <main-repo> branch --contains <mergeCommitOid> -r | grep -q 'origin/main'
```

If either fails — including `--auto` armed but not yet landed — the PR is not merged.
Leave everything in place and report. Never delete a worktree, branch, or evidence while
the PR is open, conflicted, or unverified on protected main.

## Phase 5 — Cleanup

In this order. The ordering is load-bearing.

### 1. Record outcomes first

Parent tracker: merge commit SHA, final head, tests run, review outcomes, delivery status.
Child tracker: mark tasks complete, record final autonomous decisions.

Record before destroying anything, so a failure mid-cleanup leaves an accurate trail.

### 2. Extract in-worktree evidence before removal

`~/.sdd` trackers live outside the repo and survive worktree deletion. Anything *inside*
the worktree does not — `.tv/`, local logs, generated artifacts:

```bash
cp -R <worktree>/.tv <child-tracker>/evidence/<pr>-tv 2>/dev/null || true
```

Take only what is worth keeping. This is also the moment to delete bulky evidence from the
child tracker, per the archive policy.

### 3. Archive the child tracker

Follow `better-goal`'s archiving protocol: copy the surfaces to
`~/.sdd/<pillar>/archive/<worktree-name>/<timestamp-slug>/`, add `SUMMARY.md` and
`manifest.md`, then reset the live child tracker with a pointer back to the archive.
Preserve the `goal.md` / `tasks.md` summary; drop the bulk.

### 4. Guard against removing your own worktree

```bash
git rev-parse --show-toplevel   # if this equals <worktree>, STOP
```

If the session is running inside the worktree slated for removal, do not remove it.
`git worktree remove` fails from inside, and forcing it strands the session in a deleted
directory. Report it and let the user relocate. For every other case, `cd` to the main repo
root before proceeding.

### 5. Remove the worktree

```bash
git -C <main-repo> worktree remove <worktree>
```

No `--force`. If it refuses, something is uncommitted or the path is unexpected — that is
information, not an obstacle. Investigate and report rather than overriding.

### 6. Delete the local branch

```bash
git -C <main-repo> branch -d <branch>
```

`-d`, never `-D`. Git itself refuses an unmerged branch, so the safety check is the tool
rather than your judgment. If it refuses, the branch is not fully merged — stop and report.

Branch deletion must follow worktree removal; git will not delete a branch that is checked
out in a worktree.

### 7. Remote branch

`--delete-branch` on the merge normally handles this. Verify, and only if it survived:

```bash
git -C <main-repo> push origin --delete <branch>
```

### 8. Prune and update the registry

```bash
git -C <main-repo> worktree prune
```

In the parent tracker: set status `archived`, replace the active worktree mapping with a
compact archive pointer, and leave the PR row as history. Merged PRs are retained as
history; only open PRs are monitored.

### 9. Stop PR-scoped work

`TaskStop` any monitor or task scoped solely to that PR. Do not stop anything shared.

## Never

- Merge with required checks failing, unexpectedly pending, or green only against an
  obsolete head.
- Merge on a stale approval without reconciling the current head and all newer reviews.
- Merge when a review arrived after your last disposition.
- Delete a worktree, branch, or evidence before the protected-main readback passes.
- Use `git worktree remove --force` or `git branch -D` to get past a refusal.
- Remove the worktree the session is running in.
