---
name: aggressive-simplification-review
description: "Review a PR or codebase through an aggressive-simplification and invariant-driven lens. Use this skill whenever the user asks for an architectural review, PR review, refinement pass, root-cause audit, parallel review agents, or asks whether a design is the simplest/elegant way to achieve a larger goal. It coordinates four independent review lanes and a synthesis pass, then supports evidence-first refinement without turning the review into a generic checklist."
compatibility: "Works in Codex and other agent harnesses with native subagent/delegation support; GitHub access is needed only when the review includes PR threads or checks."
---

# Aggressive simplification review

Use this skill to ask whether a change is the right solution, the simplest
coherent solution, behaviorally safe under failure, contractually consistent,
and honestly proven. The goal is not to produce four disconnected opinions. It
is to create independent signal, then reduce it to the smallest set of
source-backed invariants and remedies.

## Operating posture

Start with the larger goal and the current architecture, not with individual
lines in the diff. Treat every extra state, registry, queue, retry loop,
authority, fallback, and special case as a design decision that needs a reason.
Prefer deleting machinery or reusing an existing invariant-preserving mechanism
over adding another subsystem.

Keep discovery read-only. Review workers must not edit source, commit, push,
comment, resolve review threads, or change tracker state unless the user has
explicitly asked for an implementation/refinement phase. This separation keeps
independent findings from collapsing into the first plausible patch.

If the target is a stacked PR, establish the exact parent head and intended
ancestry before reviewing the delta. A stale stack can make both bugs and fixes
look real when they are artifacts of the wrong base.

## Default delegation

Use four independent workers, one per review lane, in parallel. Keep synthesis
in the parent/orchestrator after all four reports arrive. Do not split
implementation by layer during discovery.

In Codex, use `gpt-5.6-sol` with `medium` reasoning for every lane and for the
synthesis worker by default. The consistent profile makes reports comparable
and gives each lane enough architectural judgment. An override is allowed when
failure cost, codebase scale, or a worker's evidence justifies it; record the
reason rather than silently changing the route. In another harness, use its
closest consistent medium-depth frontier profile.

Give every worker:

- the exact repository/worktree and review boundary;
- the current commit or PR head, refreshed immediately before dispatch;
- the larger goal and relevant architecture/design sources;
- the shared invariant reference;
- an isolated report path, such as `/tmp/aggressive-review-<run-id>/<lane>.md`;
- an explicit read-only boundary and stop conditions.

Launch all four workers from the same frozen review boundary in one delegation
turn. Give each worker the same context and invariant reference, changing only
the lane question and report path. Wait for all four reports before synthesis;
do not let the first finding become the implementation plan.

Workers should report concrete failure modes, not broad opinions. Each report
must end with `Design decisions autonomously taken`, even when the lane made no
autonomous design choice.

## The four review lanes

### 1. Purpose, architecture, and simplification

Ask whether the change solves the right problem with the smallest coherent
architecture.

Look for:

- a clear user/system goal and the minimum behavior required to achieve it;
- one semantic model for the main thing being operated on;
- one authority per important fact or resource;
- one canonical path for each semantic action;
- unnecessary state, indirection, queues, registries, retries, flags, and
  compatibility branches;
- abstractions that make the design harder to explain or harder to change;
- architecture that conflicts with the larger system's direction;
- opportunities to delete machinery instead of adding another mechanism.

Do not confuse elegance with cleverness. An elegant design has few concepts,
clear ownership, local reasoning, and no special path that quietly changes the
meaning of the operation.

### 2. Behavioral correctness, ownership, and resilience

Ask whether the implementation remains correct across time, concurrency,
failure, retry, cleanup, and restart.

Look for:

- invalid or immortal state combinations;
- explicit ownership of processes, files, records, notifications, and cleanup;
- work that can disappear after being claimed;
- semantic work that can happen twice accidentally;
- publication before durable commit;
- partial work that becomes externally visible too early;
- retries that change identity, reread mutable inputs, or duplicate side effects;
- multiple serialization points for the same race;
- crash windows that leave orphans, duplicates, or unrecoverable state;
- deletion and cleanup that clear durable intent before durable absence.

For every meaningful boundary, ask what happens if the process dies immediately
before and immediately after it. Restart should be an ordinary convergence path,
not a separate best-effort repair story.

### 3. Boundaries, contracts, and trust

Ask whether every boundary agrees and whether invalid or hostile input can create
ambiguity or forge authority.

Look for:

- disagreement between schema, runtime validation, clients, and storage;
- stringly typed values where a structured contract is needed;
- error codes or phases that are open-ended in one layer and closed in another;
- implicit defaults, falsy-value coercion, and compatibility behavior that changes
  the contract;
- route/catalog or identity mismatches that create two authorities;
- private paths, metadata, or diagnostics leaking into public output;
- untrusted transport text being treated as authoritative metadata;
- limits applied after parsing or allocation rather than at ingress;
- malformed/corrupt data being accepted, misclassified, or allowed to bypass
  authorization.

Adapters may translate between boundaries, but they must not create a second
semantic interpretation of the same operation.

### 4. Evidence and operational truth

Ask whether the tests, documentation, and operating behavior actually prove the
claims being made.

Look for:

- tests that exercise a nearby fixture instead of the real boundary;
- missing failure injection at persistence, process, transport, cleanup, and
  restart boundaries;
- tests that prove a result but not ownership, idempotence, or absence of leaks;
- migration and backward-compatibility gaps;
- observability that cannot distinguish retry, recovery, and duplicate work;
- platform-specific behavior claimed without platform-specific evidence;
- docs, launchers, schemas, and error descriptions that overclaim runtime
  behavior;
- operational paths whose proof stops at unit tests when a product/integration
  path is required.

Lower-fidelity evidence can support a claim, but it must not be presented as
proof of a higher-fidelity behavior.

## Shared invariants

All lanes use these invariants as common vocabulary. A new invariant may be
added when it captures a genuinely new failure class, not merely another
implementation-specific example.

- There is one authoritative owner for each important fact or resource.
- There is one canonical semantic path for each operation.
- Invalid states are impossible or immediately recoverable.
- Claimed work cannot disappear and semantic work cannot happen twice by
  accident.
- No public effect precedes durable ownership and commit.
- Incomplete work remains private until it is complete and validated.
- Retries preserve logical identity and owned custody.
- Limits are enforced before unbounded allocation or persistence.
- Crash and restart converge to the same intended outcome.
- Public output cannot be forged from private or untrusted data.
- Schema, runtime, documentation, and tests describe the same contract.

## Worker report contract

Each worker writes a report with this shape:

```markdown
# <lane> review

## Executive summary
<what the lane believes about the design>

## Findings
### <ID>: <short invariant-oriented title>
- Severity: P0 | P1 | P2 | P3 | note
- Status: direct-review | proactive | integrated | false-positive | accepted
- Invariant: <which shared invariant is involved>
- Evidence: <source path, lines, test, reproduction, or explicit absence>
- Failure mode: <what can happen and why it matters>
- Smallest remedy: <prefer deletion or reuse of an existing mechanism>
- Proof needed: <test or evidence that would establish the remedy>
- Overlap: <other finding IDs, or none>

## Confirmed protections
<things checked and found sound>

## Open questions / limits
<anything that needs user context or stronger proof>

## Design decisions autonomously taken
<list decisions, or "None">
```

Do not promote a vague concern to a finding. A finding needs a source-backed
failure mode or a clearly demonstrated proof gap. If two findings violate the
same invariant through the same root cause, link them and let synthesis merge
them.

## Synthesis and refinement

After all lanes finish, the parent reads every report and produces one
consolidated ledger. It should:

1. merge duplicates by violated invariant and root cause;
2. preserve the strongest evidence and the clearest reproduction;
3. separate direct review issues from proactive findings and accepted limits;
4. identify interactions where individually safe changes compose unsafely;
5. rank findings by user impact, recoverability, security, and proof confidence;
6. prefer a deletion, a single owner, or an existing mechanism over a new
   subsystem;
7. state what is already protected and what remains unproven.

If the user asks for implementation, turn selected findings into red tests or
reproductions before changing production behavior. Keep refinement ownership
separate from discovery ownership when possible, then rerun the relevant lane
and the synthesis pass against the new frozen head.

## Completion boundary

The review is complete when the consolidated report can answer all of these:

- What is the larger goal, and is this change the smallest coherent way to meet
  it?
- What are the authoritative owners and canonical paths?
- What invalid, duplicate, orphaned, or unrecoverable outcomes are impossible?
- What happens at each meaningful crash, retry, cleanup, and restart boundary?
- Do all contracts and trust boundaries agree?
- Does the evidence match the claims, including platform and product-path limits?
- Which findings are fixed, accepted, false positives, or still blocked?

Do not call a design complete merely because a focused test passes. Do not make
external PR, tracker, commit, or deployment changes unless the user has
explicitly authorized them.
