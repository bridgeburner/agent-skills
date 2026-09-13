---
name: better-review
description: "Review a PR or codebase against its strategic goal, real system behavior, simplicity, failure modes, and evidence. Use for architectural or PR review, refinement, root-cause audits, or consequential design decisions."
---

# Better review

Review the change against the strategic goal and the required terminal outcome.
Start with the root problem, the actual operating path, the simplest viable
design, and evidence that matches the claim. Treat extra state, authority,
indirection, and operational responsibility as costs that need a reason. Prefer
deletion, reuse, or one clear owner over another mechanism.

Every reviewer needs the surrounding judgment, not only a leaf task. The brief
for a review or delegated pass should include the overarching goal, relevant
strategic or tactical subgoal, parent judgment, worktree/branch or PR boundary,
user constraints, authority to act, prohibited changes, and the result the
review must decide. A context-free task is incomplete: state what cannot be
decided from the available context instead of inventing a new objective.

Keep discovery read-only. Do not edit source, commit, push, comment, resolve
review threads, or change tracker state unless the user has explicitly asked
for an implementation or refinement phase.

## Reviewer brief

Before detailed findings, capture a short brief in prose or bullets:

- the goal or subgoal, root issue, required outcome, and forbidden outcome;
- the exact code, PR, worktree, or system boundary under review and the
  relevant parent or branch identity;
- the proposed behavior and public claims, including compatibility, retention,
  security, deployment, or operational claims;
- the real path from trigger and authority through stores and services to the
  terminal observer, when the change affects behavior;
- relevant prior findings, accepted limits, and available evidence.

The brief is a decision aid, not a required tracker or fixed form. Keep it
small when the change is small. Preserve prior findings that still bear on the
same outcome; account for them as re-found, disproved, accepted, or unresolved
when the review depends on them.

## Review the change

Address outcome and system fit first. State the root issue independently of the
proposed mechanism, then ask:

1. What observable result is required, and who observes it?
2. Can this change complete the real path through its identities, authorities,
   stores, services, handoffs, and final consumer?
3. What is the smallest viable design, and does the proposal add unnecessary
   concepts, state, authorities, fallbacks, retries, or operational owners?
4. Which surrounding platform, deployment, or failure conditions could prevent
   the outcome?

Then select only the additional questions the change triggers:

- state, time, concurrency, retry, cleanup, or restart: inspect ownership,
  atomicity, duplicate work, crash windows, and convergence;
- data, identity, schema, public output, or shared-resource boundaries: inspect
  contract agreement, authorization, compatibility, and foreign consumers;
- environment, machine access, configuration, or stacked PR boundaries: read
  [`references/release-boundaries.md`](references/release-boundaries.md);
- newly admitted values, moved resolutions, attribution, or ordering metadata:
  read [`references/semantic-boundaries.md`](references/semantic-boundaries.md);
- durable responses, source-authored data, version overlap, or rolling
  compatibility: read
  [`references/retention-compatibility.md`](references/retention-compatibility.md);
- process-wide, runtime-wide, host-wide, registry, singleton, or environment
  mutation: read
  [`references/ambient-effects.md`](references/ambient-effects.md).

Use [`references/invariants.md`](references/invariants.md) as shared vocabulary
when a review spans multiple concerns. Do not run a checklist whose trigger is
absent. A manageable change may receive one focused review; use an independent
reviewer when consequence, uncertainty, or context size makes independent
signal useful. Concern coverage and worker count are separate choices.

For a stacked PR, establish the actual parent and ancestry before treating its
delta as final. A retargeted branch or a green component check does not by
itself establish the resulting change.

## Findings and evidence

Report concrete source-backed failure modes or proof gaps. Each material
finding should say where the evidence is, what behavior follows, who or what it
affects, the violated goal or invariant, the smallest coherent remedy, and the
proof needed. Distinguish these cases:

- a demonstrated defect or contradiction in the required outcome;
- a readiness blocker because evidence does not establish a consequential
  claim, without presenting the unproven behavior as an incident;
- a note, accepted limitation, false positive, or pre-existing contradiction of
  a public claim.

Severity follows actual impact and failure radius. Do not turn a vague concern,
an author's scope label, or a lower-tier check into a finding without a
specific consequence. Prefer a deletion or existing mechanism when recommending
a fix.

Match evidence to the claim and its boundary. Source inspection can establish a
source fact. Focused tests can establish the behavior they exercise. A replay,
artifact, CI result, deployment check, or cloud observation may support a
different claim, but prose cannot upgrade it. An integrated behavior claim
needs a named path through the real entry point, persisted input, affected
consumers, and terminal result, with relevant negative sinks such as drop,
omission, quarantine, or wrong attribution. A source, design, documentation,
or bounded local claim may need no live product run. Label what remains
unproven.

When a change is iterated, review the actual final content identity and do not
carry stale conclusions over changed behavior. Rerun the affected questions
and evidence; request a fresh independent pass when the consequence or changed
scope warrants it. A universal full rerun is unnecessary for a small change.

## Delegation and synthesis

The coordinator owns the review brief, boundary, assignments, and synthesis.
Give every delegated reviewer the same goal context, exact content identity,
relevant constraints, read-only boundary, and expected decision. A reviewer may
cover several concerns; do not create one worker per checklist item. Use the
model and effort selected for the run. If Better Goal supplies its small model
ladder, follow that selection; this skill does not impose a model default or
require a tracker.

Use concise prose for a single review. Use
[`references/finding-schema.md`](references/finding-schema.md) only when
multiple reports need stable, mergeable finding records. The schema is an
optional interchange format, not a required answer shape.

At synthesis:

- decide whether the proposal can reach the required outcome and state the
  smallest useful next fix or proof;
- merge duplicate findings by root cause and preserve the strongest evidence;
- account for relevant prior findings and accepted limits;
- distinguish fixed, introduced, pre-existing, accepted, and unresolved items;
- state evidence limits and any cross-concern interaction that changes impact.

Do not require empty sections or a fixed report process when they add no signal.
Do not call a design complete merely because a focused check passes, and do not
make external PR, tracker, commit, or deployment changes without explicit
authorization.
