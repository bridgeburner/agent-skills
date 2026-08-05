# Merge Gate and Post-Merge Cleanup

Loaded only when a PR looks mergeable, or has merged since the last tick. Every
precondition here is a **check**, never an inference. Both phases are irreversible.

## `--report-only` halts this entire file

If the run was started with `--report-only`, **every phase below is observation only**.
Do not merge. Do not arm auto-merge. Do not remove a worktree, delete a branch, archive or
reset a tracker, or stop a task. Evaluate the gate, report what *would* happen, and stop.

This is stated here at the top rather than inside one phase because cleanup is reachable
without passing through the merge gate at all — the tick routes a PR that merged since the
last tick straight to Phase 4 — so a guard placed only before Phase 3 does not cover the
destructive half.

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
2. `mergeable == "MERGEABLE"` **and `mergeStateStatus == "CLEAN"`.** Require `CLEAN`
   explicitly rather than excluding a blocklist of bad values: `mergeable` is still
   `MERGEABLE` when `mergeStateStatus` is `BLOCKED`, so an exclusion list that omits
   `BLOCKED` lets a PR through on a repo without branch protection to reject it.
   `CLEAN` is GitHub's own affirmative verdict; anything else fails.
3. **Required checks pass — established by asking GitHub, not by re-deriving it.** Run:

   ```bash
   gh pr checks <n> --repo <repo> --required
   ```

   Any row not in a passing or skipped state fails this condition.

   **"No required checks reported" is satisfied, not failed.** `gh pr checks --required` exits
   non-zero on a repo with no required contexts configured, which is common — `agent-skills`,
   the repo hosting this skill, has branch protection with zero required checks. Treating that
   exit code as a gate failure wedges the merge path permanently and silently on every such
   repo. Distinguish the two cases:

   ```bash
   out=$(gh pr checks <n> --repo <repo> --required 2>&1); rc=$?
   case "$out" in
     *"no required checks"*) echo "satisfied: no required contexts configured" ;;
     *) [ $rc -eq 0 ] || echo "FAIL: required checks not green" ;;
   esac
   ```

   When no required contexts exist, `mergeStateStatus == "CLEAN"` (condition 2) is the only
   check-related signal available, and it is sufficient — it is GitHub's own verdict.

   Do **not** try to satisfy this by scanning `statusCheckRollup` for
   `conclusion == "SUCCESS"` on every entry. That formulation is wrong three ways and will
   permanently wedge the merge path:

   - The rollup carries no `isRequired` field, so requiredness cannot be read from it at
     all — only inferred, which this file forbids.
   - `SKIPPED` is not `SUCCESS`, but GitHub treats a conditionally-skipped required check as
     satisfied. Path-filtered and `if:`-conditioned jobs report `SKIPPED` routinely, so an
     all-`SUCCESS` test is false on healthy PRs.
   - Check *names repeat* when a check has been re-run. A per-entry test fails whenever any
     superseded run concluded non-success, even though the latest run passed.

   `mergeStateStatus == "CLEAN"` from Phase 1 is GitHub's own aggregate verdict that
   required checks and approvals are satisfied. Treat it as the authoritative signal and
   `gh pr checks --required` as the human-readable detail for the report. If the two
   disagree, do not merge — report the disagreement.
4. **An approval exists.** `reviewDecision == "APPROVED"` satisfies this.

   On a repo that does not *require* reviews, `reviewDecision` is `""` rather than `APPROVED`
   even when the PR is approved and `mergeStateStatus` is `CLEAN` — so testing only for
   `APPROVED` fails permanently on every unprotected repo. When it is empty, accept the
   condition only if `mergeStateStatus == "CLEAN"` **and** `latestReviews` contains at least one
   `APPROVED` state with no later `CHANGES_REQUESTED` from the same reviewer. An empty
   `reviewDecision` with no approving review at all is still a failure — never merge work no
   human has approved just because the repo does not force it.
5. The approving review is at or after `headRefOid`. If the approval predates the current
   head, it is stale — usable only after you have reconciled the current head and every
   newer review submission against your last disposition.
6. No unresolved review thread maps to an unaddressed actionable finding. Fixed threads are
   resolved by the disposition cycle (`disposition.md` fix loop step 6), so a still-open
   thread here means either a live pushback, an open question, or something genuinely
   unhandled — evaluate it on that basis rather than assuming memory of a past fix.
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

**Always pass `--match-head-commit <headRefOid>`**, using the exact SHA Phase 1 read and
Phase 2 verified. Without it, the merge is not bound to the state you checked: the gate takes
tens of seconds to evaluate, and a force-push inside that window means GitHub merges a commit
that was never reviewed or CI-verified. With it, GitHub rejects the call instead — which is
the correct outcome, and turns an unbounded race into a retry on the next tick.

**Nothing pushed this cycle** — approval is intact and current:

```bash
gh pr merge <n> --repo <repo> --squash --delete-branch --match-head-commit <headRefOid>
```

**Fixes pushed this cycle** — the approval is now dismissed; arm auto-merge instead:

```bash
gh pr merge <n> --repo <repo> --auto --squash --delete-branch --match-head-commit <headRefOid>
```

Pinning the `--auto` arm is cheap and harmless, but be clear about what it does **not** buy:
`expectedHeadOid` is an *arming-time* precondition only. GitHub disables auto-merge just when
someone **without** write access pushes, so a teammate with write access leaves it armed and
GitHub lands whatever the head is once requirements are met. The pin does not force re-arming.

What actually protects this path is approval dismissal on push — which is repo configuration,
not a guarantee. So the real mitigation lives in the tick: record the armed SHA in the registry
and re-check it every tick, disarming and re-gating if the head moved. See `SKILL.md` §2.

**`--delete-branch` deletes the local branch too, not just the remote.** Phase 5 §6 accounts
for this; do not treat the local branch's later absence as an error.

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
git -C <main-repo> merge-base --is-ancestor <mergeCommitOid> origin/main
```

Use `merge-base --is-ancestor` — it exits 0 only if the commit really is an ancestor of
`origin/main`. Do **not** use `branch --contains <oid> -r | grep -q 'origin/main'`: that
substring match also succeeds on `origin/main-backup`, `origin/mainline`, or
`origin/release/main`, and this is the gate on every destructive step that follows.

If either fails — including `--auto` armed but not yet landed — the PR is not merged.
Leave everything in place and report. Never delete a worktree, branch, or evidence while
the PR is open, conflicted, or unverified on protected main.

## Phase 5 — Cleanup

In this order. The ordering is load-bearing.

### 0. Guard against touching your own worktree — before anything else

```bash
SESSION_ROOT=$(cd "$(git rev-parse --show-toplevel)" && pwd -P)
TARGET=$(cd <worktree> && pwd -P)
MAIN_ROOT=$(cd <main-repo> && pwd -P)
if [ "$TARGET" = "$MAIN_ROOT" ]; then
  echo "PRIMARY CHECKOUT — skip steps 4 and 5, continue 6-8"
elif [ "$TARGET" = "$SESSION_ROOT" ]; then
  echo "SELF — STOP HERE"
else
  echo "OK — proceed through all steps"
fi
```

**The order is deliberate and the branches are mutually exclusive.** Primary-checkout is tested
first and wins, *even when the target is also the session root* — which is the most ordinary
setup there is: the user on a branch in the main checkout, a PR opened from it, and the loop
started from that directory. With independent `&&` tests both fired and gave contradictory
instructions ("stop before any step" vs "do steps 1–3 then continue"), and an agent taking the
louder SELF instruction stopped without recording or archiving, leaving the row
`awaiting-approval` — which reconciliation then retried every 15 minutes forever, making no
progress and never escalating, because the 3-strikes counter tracks *workflow* cycles and not
cleanup attempts.

Primary-checkout wins safely because that path attempts nothing destructive on the target: it
skips both the worktree removal and the branch delete.

Compare **resolved** physical paths via `pwd -P`, not raw strings. A worktree under `/tmp`
resolves to `/private/tmp/...` on macOS while the registry may hold `/tmp/...`, so a plain
string equality is a false negative on exactly the case the guard exists to catch.

If the session is running inside the worktree slated for removal, stop **before any step
below runs**. Not after recording, not after archiving — before. `git worktree remove` fails
from inside anyway, and forcing it strands the session in a deleted directory.

**If the mapping is the primary checkout** (the main working tree, which §3 of `SKILL.md`
explicitly permits as an owner), there is no worktree to remove and its branch is checked
out, so neither `git worktree remove` nor `git branch -d` can apply. Do steps 1–3, then skip
steps 4 and 5, note in the report that the primary checkout was left in place with its branch
still checked out, and continue with steps 6–8. Never switch the user's main working tree to
another branch to make the deletion possible.

This guard is first because the steps that follow are mutating. Running it late means a
self-worktree case still gets its live tracker reset and its evidence moved, while the
registry is never updated — leaving a half-cleaned PR that later grounding reads as having
no tracker at all, which in turn suppresses that PR's ability to push back on anything.

Report the situation and let the user relocate. For every other case, `cd` to the main repo
root and continue.

### 1. Record outcomes

Parent tracker: merge commit SHA, final head, tests run, review outcomes, delivery status.
Child tracker: mark tasks complete, record final autonomous decisions.

Record before destroying anything, so a failure mid-cleanup leaves an accurate trail.

### 2. Extract in-worktree evidence before removal

`~/.sdd` trackers live outside the repo and survive worktree deletion. Anything *inside*
the worktree does not — `.tv/`, local logs, generated artifacts:

```bash
mkdir -p <child-tracker>/evidence/<pr>-tv
if [ -d <worktree>/.tv ]; then
  cp -R <worktree>/.tv/. <child-tracker>/evidence/<pr>-tv/ || exit 1
  # prove it landed before anything deletes the source
  diff -rq <worktree>/.tv <child-tracker>/evidence/<pr>-tv
fi
```

Never suppress this with `2>/dev/null || true`. A swallowed copy failure followed by
`git worktree remove` destroys the evidence permanently, and the silence makes success
indistinguishable from loss. If the copy or the verification fails, that is information:
stop cleanup and report, exactly as you would for a refused `worktree remove`.

Take only what is worth keeping. This is also the moment to delete bulky evidence from the
child tracker, per the archive policy.

### 3. Archive the child tracker

Follow `better-goal`'s archiving protocol: copy the surfaces to
`~/.sdd/<pillar>/archive/<worktree-name>/<timestamp-slug>/`, add `SUMMARY.md` and
`manifest.md`, then reset the live child tracker with a pointer back to the archive.
Preserve the `goal.md` / `tasks.md` summary; drop the bulk.

### 4. Remove the worktree

```bash
git -C <main-repo> worktree remove <worktree>
```

No `--force`. If it refuses, something is uncommitted or the path is unexpected — that is
information, not an obstacle. Investigate and report rather than overriding.

### 5. Delete the local branch — only if it still exists

`gh pr merge --delete-branch` deletes the **local and remote** branch, so on the direct-merge
path the local branch is usually already gone. Check before acting:

```bash
if git -C <main-repo> show-ref --verify --quiet refs/heads/<branch>; then
  git -C <main-repo> branch -d <branch>
else
  echo "local branch already deleted by --delete-branch — nothing to do"
fi
```

**A missing branch is success, not failure.** Running `branch -d` unconditionally yields
`error: branch '<branch>' not found`, and reading that as "the branch is not fully merged"
halts cleanup before the registry update — every single time the direct-merge path is taken,
leaving a stale `active` row and an un-pruned worktree while reporting that a merged branch
is unmerged.

When the branch *does* exist: `-d`, never `-D`. Git itself refuses an unmerged branch, so the
safety check is the tool rather than your judgment. A refusal there is real — stop and report.

Branch deletion must follow worktree removal; git will not delete a branch checked out in a
worktree.

### 6. Remote branch

`--delete-branch` on the merge normally handles this. Verify, and only if it survived:

```bash
git -C <main-repo> push origin --delete <branch>
```

### 7. Prune and update the registry

```bash
git -C <main-repo> worktree prune
```

In the parent tracker: set status `archived`, replace the active worktree mapping with a
compact archive pointer, and leave the PR row as history. Merged PRs are retained as
history; only open PRs are monitored.

### 8. Stop PR-scoped work

`TaskStop` any monitor or task scoped solely to that PR. Do not stop anything shared.

## Never

- Run any of this under `--report-only`.
- Merge without `--match-head-commit` bound to the SHA the gate verified.
- Merge with required checks failing or unexpectedly pending, or when
  `gh pr checks --required` and `mergeStateStatus` disagree.
- Merge on a stale approval without reconciling the current head and all newer reviews.
- Merge when a review arrived after your last disposition.
- Delete a worktree, branch, or evidence before the protected-main readback passes.
- Use `git worktree remove --force` or `git branch -D` to get past a refusal.
- Touch the worktree the session is running in — check this before step 1, not after.
- Suppress an evidence-copy failure, or delete a source before verifying the copy landed.
