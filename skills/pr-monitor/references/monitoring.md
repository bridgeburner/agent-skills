# Monitoring

Event-driven, not polled. Most of this file is failure modes, because **on a watch,
correctness failures do not announce themselves — they produce silence, or a
plausible smaller number.** Read it before building anything.

## What to watch

Four streams. Fold them into one process if your harness limits concurrent watches.

1. **PR state deltas.** One query per poll covering the whole allowlist. Track: state,
   draft, mergeable, review decision, base, head, check rollup, comment/review/thread
   counts, and **requested reviewers**. Emit only changed fields.
2. **Staleness digest.** Once a day, for anything unchanged past a threshold.
3. **Work inbox**, if producers hand you work by writing a file.
4. **Your delegated agents** — see `delegation.md`. This is the one people forget, and
   agents then sit finished and unnoticed.

## Gotchas that break naive watches

**Silence is the default failure signature.** A dead fetch and a healthy quiet queue
produce identical output. So: a transport failure must **emit** rather than exit or
pass silently. Verify liveness periodically by checking that state files are still
being rewritten, not by observing that nothing was reported.

**A change-watcher can tell you nothing changed; it can never tell you nothing is
wrong.** Anything already unsettled when you arm the watch emits no event, ever. Pair
arming with a one-time baseline reconciliation, and keep a staleness digest so a PR
blocked on an unresponsive human resurfaces instead of looking healthy.

**Your own writes echo.** Every reply, push and reviewer change you make comes back as
a delta. Record the mutation you expect when you close a lease and discard the match,
or you will dispatch discovery onto your own actions.

**Your own bookkeeping corrupts staleness.** Measure age from *substantive* events —
a new head, a submitted review. Not from review requests, which you generate yourself;
counting those lets your own admin hide a stalled PR.

**Keep volatile fields out of the staleness signature.** `mergeable` flips when trunk
moves or the host recomputes. Include it and an unrelated push resets the clock on
your longest-waiting PR, dropping it out of the very digest meant to surface it.

**A rate limiter must be driven by the report, not the check.** Stamp the suppression
window only when the digest actually reports something. Stamp it on an empty check and
one quiet window silently eats the next real signal.

**Never edit a watcher while its monitor is running.** The live process keeps computing
the old format against your new state file, rewrites the store into its own stale
shape, and destroys the data. Stop the watch, migrate script and state together,
re-arm. A schema change and a running reader must not overlap — and the corruption
looks like well-formed data, so nothing errors.

**Exercise rare branches before arming.** A syntax check will not catch an invalid
expansion inside a once-a-day branch; it fires long after arming and silently kills the
watch. Seed the conditions and make the branch run.

**A test whose pass condition is silence tests nothing.** If a watcher is quiet because
its state file already exists, "no output" and "completely broken" are the same
observation. Test against throwaway state so it must speak.

**Re-arm, and expect the watch to die with your session.** If your harness caps monitor
lifetime, re-arming is your job; note that there is a blind window between expiry and
re-arm. File-backed state makes that window harmless — the next poll still diffs
against the stored snapshot — which is the main reason to keep state on disk.

## Hosting-service traps

- **A never-run check reads green.** Absent is not failed, so the rollup ignores it.
  Enumerate contexts; look for zero-run suites, especially from external apps.
- **The badge can contradict the gate.** `APPROVED` persists across a semantic push.
  Compare the approval's commit to the current head yourself.
- **Mergeability can be wrong.** Verify with `git merge-tree --write-tree` against the
  live base before believing either a conflict or a clean state.
- **A review clears the reviewer request.** Every time someone reviews, the request —
  including a notification team — is removed. Re-assert it, or a PR that later needs
  renewed review becomes invisible. Expect this constantly.
- **CI usually tests the synthetic merge**, not your branch. A child's own green CI does
  not mean the stack is green, and a parent's fix can break a child nobody touched.
- **Children auto-retarget when a parent merges** — and then may conflict, because the
  base they were measured against no longer exists.
