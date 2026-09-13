---
name: pr-monitor
description: "Claude Code only. Use with `/pr-monitor` or `/loop` when the user wants an autonomous cadence for their admitted open PRs: review activity, CI, fixes, merge gating, and post-merge cleanup. The registry is an explicit allowlist, and an unknown PR or worktree mapping needs the user's answer. Do not trigger for a one-off review or generic `gh` help."
---

# pr-monitor

This skill routes a Claude Code tick over PRs the user has admitted to a
tracker-backed registry. It coordinates review disposition, merge gating, and
cleanup. The detailed review rubric and destructive merge checklist are loaded
only when their branches are reached:

- [references/disposition.md](references/disposition.md) for review findings.
- [references/merge-cleanup.md](references/merge-cleanup.md) for merge and cleanup.

## Harness and invocation

Claude Code is required. The driver depends on its `Workflow` and `TaskList`
tools plus the built-in `loop` skill. The workflow script sets its own internal
effort values; it does not require `TaskGet` or a separate per-agent model or
effort override. If another harness is active, stop. Do not emulate this with a
shell loop or nested agents; `TaskList` is the in-flight idempotency check.

```text
/loop 15m /pr-monitor
```

Run `/pr-monitor` once for a single tick. Optional arguments:

```text
--repo <owner/name>       repository (default: current repository)
--pillar <name>           .sdd pillar (default: better-goal inference)
--pr <n>[,<n>...]         admitted PRs to narrow the tick
--report-only             observe; suppress every write and destructive action
```

`--pr` narrows the read; it does not admit a PR. `--report-only` also covers
the cleanup path: no edits, commits, pushes, comments, merges, auto-merge
arming, worktree or branch removal, tracker archive/reset, or `TaskStop`.

## Authority and durable state

The parent tracker is `~/.sdd/<pillar>/pr-monitor/`. Its `tasks.md` registry is
an allowlist, not a cache:

```text
PR | title | head SHA | branch | worktree | child tracker | status | incomplete | armed SHA
```

Only a row with a user-provided or user-confirmed mapping may be monitored.
Never adopt the open PR list, infer admission from a matching branch, or run
`git worktree add` without the user asking for it. A missing or ambiguous
mapping is reported for the user to resolve.

The child tracker at `~/.sdd/<pillar>/<worktree-name>/` records the PR's scope,
decisions, evidence, and outward actions. If an admitted PR has no child
tracker, create it through `better-goal` from the PR body and history before
dispatching a workflow. An empty tracker permits grounding but gives no basis
for pushback.

Keep these distinctions:

- In-session context remembers the last head, review disposition, and quiet
  status. It is allowed to disappear across sessions.
- Durable state stores the registry and append-only outward actions in
  `events.jsonl` so comments, pushes, merges, and cleanup can be reconstructed
  and deduplicated after interruption.
- `drift` is a recoverable registry status. Re-evaluate its cause each tick;
  return to `active` with an incomplete count of zero when the mapping or
  working tree is healthy again. Report standing drift on a decay schedule.

For each outward action, append an `*.attempting` event before calling the
provider or deleting anything, then append `*.completed` with the result. A
returned workflow verdict, commit, push, comment, merge, or cleanup result that
is not recorded cannot reliably survive compaction.

## Tick

Most ticks should be cheap. Keep this order.

1. **Check in-flight work.** Query `TaskList` for `pr-disposition` workflows.
   Skip a PR with a workflow already running. Do not infer completion.

2. **Discover and reconcile.** Read authored open PRs once:

   ```bash
   gh pr list --author @me --state open --repo <repo> \
     --json number,title,headRefName,headRefOid,isDraft,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,url,updatedAt
   ```

   Reconcile every non-archived registry row. Query a row missing from the open
   list with `gh pr view <n> --json state,mergedAt,mergeCommit`; send merged PRs
   through the merge-cleanup reference and archive closed-unmerged PRs without
   destructive cleanup. Check `awaiting-approval` rows for landing and compare
   their current head with `armed SHA`; head drift disables auto-merge and
   returns the row to `active` for a fresh gate.

3. **Admit new PRs.** For each discovered PR absent from the registry, take no
   review or provider-thread action. Ask which worktree owns it, optionally
   showing a branch-matched candidate. After the user answers, verify:

   ```bash
   git -C <worktree> rev-parse --abbrev-ref HEAD   # equals headRefName
   git -C <worktree> rev-parse --git-common-dir    # belongs to this repo
   ```

   Add the verified row with `incomplete` zero. A mismatch remains unadmitted.

4. **Guard admitted mappings.** Before every edit, verify the worktree exists,
   its branch equals `headRefName`, and `git status --porcelain` is empty. On a
   mismatch or unexpected dirt, set `drift`, make no edit, and report it. Never
   repair a mapping by checking out a branch or guessing a path.

5. **Compare and route.** For admitted PRs, compare the current head, review
   state, checks, and human review set with the last tick. Filter out the PR
   author's comments and bot comments. Read review threads only for admitted
   PRs. A prior incomplete workflow is retried even when provider state did not
   change; increment `incomplete`, stop after three consecutive incomplete
   cycles, and escalate as `drift`. A complete workflow with
   `awaitingAuthor` waits for an answer and does not count as a failure.

   - New review activity → load `references/disposition.md` and dispatch one
     workflow.
   - Mergeable state → load `references/merge-cleanup.md` and run its fresh gate.
   - Merged PR → load the same reference and run verified cleanup.
   - No change and a complete prior cycle → report a compact status line.

6. **Dispatch only guarded work.** Use the installed absolute script path and
   pass all load-bearing identity fields:

   ```js
   Workflow({
     scriptPath: "/Users/<you>/.claude/skills/pr-monitor/workflows/pr-disposition.js",
     args: {
       pr, repo, branch, worktree, childTracker, parentTracker,
       headSha, findings, reportOnly,
     },
   })
   ```

   `branch`, `worktree`, `childTracker`, and `headSha` are required. Render
   findings as `{author, path, line, body}` or a plain string; do not pass raw
   provider nodes into a public comment. One PR owns one worktree, so never fan
   out its editing phase. The workflow grounds findings in the trackers,
   classifies them, verifies pushback, applies accepted fixes, tests, commits,
   pushes, responds once, and records its outward actions. It does not merge.

7. **Report.** Begin every report with:

   ```text
   N admitted · N unadmitted (awaiting your mapping) · N drift · N awaiting your answer · N awaiting approval
   ```

   Then list mapping requests, open questions, admitted PR status and actions,
   and drift with its cause. Surface an unanswered mapping once rather than
   repeating it on every tick.

## Ownership and merge boundary

The disposition workflow owns grounding, triage, pushback verification, fixes,
tests, commits, pushes, and its one response. This driver owns cadence,
cross-PR registry state, the fresh merge gate, merge, and cleanup. A push can
dismiss the approval needed by the gate, so after a fix the workflow requests
review and arms auto-merge; it does not pretend that the old approval remains.
The merge and cleanup reference is authoritative for every provider read and
destructive precondition.
