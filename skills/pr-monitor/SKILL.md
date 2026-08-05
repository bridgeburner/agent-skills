---
name: pr-monitor
description: "Claude Code only — needs the `Workflow` tool, `TaskList`/`TaskGet`, per-agent model/effort overrides, and the built-in `loop` skill. Do not invoke from Codex or other harnesses; use their native PR review facility. In Claude Code, runs an autonomous tracker-grounded babysitting loop over open authored PRs the user has explicitly admitted to its registry — it never adopts the open-PR list on its own, and a PR with no known worktree mapping gets a mapping request first. Once admitted it polls review activity and CI on a cadence, disposes each reviewer finding as fix / pushback / insufficient-context grounded in `~/.sdd` trackers, implements and pushes accepted fixes, gates and executes merges, and runs post-merge worktree/branch/tracker cleanup. Trigger on /pr-monitor, 'monitor my PRs', 'babysit my open PRs', 'watch for new review comments', 'keep my PRs moving', or when paired with /loop. Do NOT trigger for a one-off review of a single PR (use /review or /code-review) or for generic gh CLI questions."
---

# pr-monitor — Autonomous Tracker-Grounded PR Babysitting

## Harness requirements

Claude Code only. Hard dependencies, none of which have portable equivalents:

| Dependency | Used for |
|---|---|
| `Workflow` tool | Per-PR disposition fan-out (`workflows/pr-disposition.js`) |
| `TaskList` / `TaskGet` | Confirming whether a PR already has a workflow in flight |
| Per-agent `model` / `effort` overrides | Escalating reasoning only for contested pushback |
| Built-in `loop` skill | The 15-minute cadence |

If the active harness is not Claude Code, stop and say so. Do not emulate the loop with
a shell `while` loop or nested agent invocations — the idempotency guarantee in this
skill comes from `TaskList` being authoritative about in-flight work, and an emulation
without it will double-post comments on other people's PRs.

`references/disposition.md` and `references/merge-cleanup.md` are harness-agnostic
procedure. Another harness may reimplement against them, but must not load this
`SKILL.md` as its driver.

## How to run it

```
/loop 15m /pr-monitor
```

The loop is deliberately in-session and mortal — it dies when the session does. That is
the right trade: the merge gate needs a human approval regardless (see *Approval
dismissal* below), so an always-on cron monitor would buy nothing and would lose the
cross-tick memory this design depends on.

One-shot `/pr-monitor` (no loop) runs a single tick. Use it to inspect state without
committing to a cadence.

### Arguments

Passed through `/pr-monitor <args>`, all optional:

- `--repo <owner/name>` — default: the repo of the current working directory.
- `--pillar <name>` — `~/.sdd` pillar for trackers. Default: inferred by
  `better-goal`'s `scripts/sdd_path.py`.
- `--report-only` — never push, merge, or clean up. Observe and report.
- `--pr <n>[,<n>...]` — restrict the tick to specific PRs. This narrows what is monitored;
  it does not admit anything. An unadmitted PR named here still gets a mapping request
  rather than action.

## The state model

This is the part that makes the rest simple. Two tiers, and the split is deliberate:

**In context (mine, cross-tick, mortal).** Last tick's head SHAs per PR, which findings
I disposed of and how, what I pushed back on and why, which PRs I have already reported
as quiet. This replaces a persisted `(pr, review_id, head_sha)` dedup index. Reasoning
beats hashing here: a hash re-triages when a reviewer merely edits a comment, or when
the head moves for an unrelated reason and every thread re-renders as new.

**Durable (`~/.sdd`, survives everything).** Only two things:

1. The **PR registry** in the parent tracker — the PR → worktree → child-tracker map.
   This is an **allowlist, not a cache**: a PR absent from it is not monitored at all.
2. An **append-only record of outward-facing actions already taken** — comments posted,
   branches pushed, merges executed — in the child tracker's `events.jsonl`.

Tier 2 exists precisely because context is mortal. Forgetting "I already posted this
pushback" means posting it twice on someone else's PR. Everything else can be re-derived
from the provider on the next tick, so do not persist it.

## Trackers

**Parent (`~/.sdd/<pillar>/pr-monitor/`).** Owns cross-PR state. Note this deliberately
breaks `better-goal`'s `~/.sdd/<pillar>/<worktree-name>/` convention: the PR monitor has
no worktree of its own. Do not "fix" this by relocating it.

`tasks.md` carries the registry as its top table:

| PR | Title | Head SHA | Branch | Worktree | Child tracker | Status |
|---|---|---|---|---|---|---|

`Status` is one of `active`, `drift` (an admitted PR whose worktree guard failed or whose
mapping became ambiguous — observed but never edited), `awaiting-approval` (fixes pushed,
auto-merge armed), `archived`. A PR that is not a row in this table is **unadmitted** and is
not monitored — see §3.

`drift` is a registry status; `--report-only` is a run flag that suppresses all writes for
every PR. They are unrelated.

**Child (`~/.sdd/<pillar>/<worktree-name>/`).** One per PR-owning worktree — usually
already exists from the work that created the PR. This is the grounding source: what was
tried, what was decided, what was deliberately not done. It is what lets a pushback be
evidence-based rather than a reflex.

On first run, if the parent tracker is absent, create it via `better-goal` with an **empty**
registry. Do not seed it from the first provider read — that would auto-admit every open
PR, which is precisely what §3 forbids. The first tick's job is to discover open PRs and
ask which ones to admit.

## The tick

Most ticks are no-ops. Keep this path cheap — **do not load either reference file unless
its branch is actually reached.**

### 1. Check what is already in flight

`TaskList` for running `pr-disposition` workflows. Any PR with one in flight is skipped
entirely this tick. This is the whole idempotency mechanism: one in-flight workflow per
PR, keyed by PR number. There is nothing to deduplicate because a second cycle is never
started.

Never reason about whether a workflow is probably done. Ask.

### 2. One batched provider read (discovery only)

```bash
gh pr list --author @me --state open --repo <repo> \
  --json number,title,headRefName,headRefOid,isDraft,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,url,updatedAt
```

### 3. Admission — the registry is an allowlist

**Never adopt the open-PR list as the monitored set.** `gh pr list` is *discovery*. The
registry is *admission*. Only PRs that are rows in the registry, with a mapping the user
provided or confirmed, are monitored.

For every discovered open PR that is not already a registry row:

1. It is **unadmitted**. Take no action on it — no disposition, no workflow, no edit, no
   comment, no merge, not even a read of its review threads.
2. **Requesting the mapping is the first step.** Surface the PR to the user and ask which
   worktree owns it. Do not proceed on that PR until they answer.
3. To make the request concrete, you may derive a *candidate* worktree by matching
   `headRefName` against `git worktree list --porcelain` (the primary checkout counts — a
   branch checked out in the main working directory is a legitimate owner). Present it as
   a proposal to confirm. **A derived candidate is never an admission.** Deriving a
   plausible mapping and proceeding on it is exactly the failure this rule exists to stop.
4. On the user's answer, write the row into the registry and monitor it from the next tick.

This is why the rule matters: an authored open PR is not necessarily work you want an
autonomous loop touching. Drafts, spikes, experiments, long-parked branches, and PRs owned
by a different machine all show up in `gh pr list`. Admission is the user's decision, made
once per PR, and it is cheap.

Never run `git worktree add` on your own initiative. Creating a worktree requires the user
asking for it in that tick; once created, record the mapping and proceed normally.

For PRs **already admitted**, a mapping that no longer resolves — or resolves ambiguously
to two or more worktrees — is drift, not a re-admission opportunity. Set status `drift`,
surface it, and do not repair the mapping by guessing.

### 4. Guard every mapping before any edit

```bash
git -C <worktree> rev-parse --abbrev-ref HEAD   # must equal headRefName
git -C <worktree> status --porcelain            # unexpected dirt → status drift
```

A registry entry can rot: the worktree may have been removed or repurposed to another
branch. Without this guard a fix for PR A lands on branch B. On mismatch, demote to
status `drift` and report it — do not repair the mapping by guessing.

### 5. Diff against last tick, then branch

Compare each PR's head SHA, `reviewDecision`, check rollup, and review/comment set
against what you remember.

Only admitted PRs reach this step.

- **Nothing changed, nothing mergeable** → emit one compact status line and end the
  tick. This is the common case. Stop here.
- **New review activity** → read `references/disposition.md`, then dispatch the
  workflow (§6).
- **Mergeable** → read `references/merge-cleanup.md` and run the gate.
- **Merged since last tick** → read `references/merge-cleanup.md` and run cleanup.

For per-PR review detail:

```bash
gh pr view <n> --repo <repo> --json reviews,comments,latestReviews
```

Unresolved *thread* state needs GraphQL:

```bash
gh api graphql -f owner=<owner> -f repo=<name> -F pr=<n> -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{ isResolved isOutdated path line
          comments(first:20){ nodes{ author{login} body createdAt } } } } } } }'
```

### 6. Dispatch the disposition workflow

One workflow per PR with new activity, launched with the absolute script path:

```
Workflow({
  scriptPath: "~/.claude/skills/pr-monitor/workflows/pr-disposition.js",
  args: { pr, repo, worktree, childTracker, headSha, findings, reportOnly }
})
```

Expand `~` to the real home path — `scriptPath` is not shell-expanded.

The workflow triages each finding, adversarially verifies any `pushback` verdict at
higher effort, implements accepted fixes, runs tests, commits, and pushes. It returns a
structured verdict. **It does not merge.** Record its returned verdict and actions in the
child tracker when it completes.

### 7. Report

One block per tick, in this order:

1. **Awaiting admission** — every discovered open PR that is not in the registry, with its
   candidate worktree if one was derived, phrased as a direct question: which worktree owns
   this, or should it stay unmonitored? Put this first. It is the only part of the report
   that needs the user to act, and an unanswered mapping request means real work is sitting
   untouched.
2. **Admitted PRs** — number, title, short head SHA, worktree, CI, review state,
   mergeability, and what you did or why you did nothing.
3. **Drift** — any admitted PR newly moved to `drift`, and why.

If a mapping request has gone unanswered for several ticks, say so once rather than
repeating the full request every tick.

## Reason vs. check

The rule that keeps this safe. Getting it backwards is the failure mode.

| Question | Mode |
|---|---|
| Is this reviewer finding actually new? | **Reason** |
| Is the reviewer correct? | **Reason**, grounded in the child tracker |
| Is this objection already answered by prior recorded work? | **Reason** |
| Is this PR admitted to the registry? | **Check** — never infer admission from a derivable worktree |
| Is a workflow in flight for this PR? | **Check** (`TaskList`) |
| Is this the current head SHA? | **Check**, immediately before acting |
| Are required checks green? | **Check** |
| Does the worktree HEAD match the PR branch? | **Check**, before every edit |
| Did the merge actually land on protected main? | **Check**, before any cleanup |

Judgment about content → reason. Preconditions on irreversible acts → verify, every
time, no matter how confident you feel.

## Approval dismissal — the one structural constraint

On these repos a push dismisses existing approvals, and the merge gate requires an
approval. So `fix → push → merge` **cannot** complete in a single cycle: the push
invalidates the approval the merge needs.

Two paths, both autonomous:

- **Nothing needed fixing** (approved, green, current head, no open findings) → merge
  now. No push, no dismissal.
- **Findings needed fixing** → push, request re-review, then arm auto-merge:

  ```bash
  gh pr merge <n> --repo <repo> --auto --squash --delete-branch
  ```

  GitHub lands it the moment a human approves — even after this session is gone. Set the
  registry status to `awaiting-approval`. This is strictly more autonomous than holding
  the loop open waiting for a re-review.

Never resolve this by trying to preserve or re-apply a dismissed approval.

## Ownership boundary

- **Workflow** owns: triage, pushback verification, fixes, tests, commit, push. Ends at
  "verdict returned."
- **This skill (agent)** owns: cadence, cross-PR state, the merge gate, the merge, and
  cleanup.

Merge and cleanup are the agent's because the gate needs a fresh readback *at the moment
of merge* — workflow-start state is minutes stale — and because cleanup is a sequential
safety checklist with no fan-out, where spawning a workflow would add risk and no speed.

## References

Load only when the tick reaches the relevant branch:

- `references/disposition.md` — the fix / pushback / insufficient_context rubric, the
  grounding requirement, and how to write a pushback that will survive a reviewer's
  reply.
- `references/merge-cleanup.md` — the merge gate readback and the post-merge cleanup
  checklist, including the destructive-step preconditions.
