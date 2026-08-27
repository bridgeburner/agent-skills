---
name: better-review
description: "Review a PR or codebase from the root problem through end-to-end system fit, simplicity, elegance, failure modes, and proof. Use this skill for architectural or PR review, refinement, root-cause audit, parallel review, or deciding whether a proposed design can meet its larger goal. It uses a mandatory strategic viability pass, then selects only the independent risk lanes the change needs."
---

# Aggressive simplification review

Use this skill to decide whether a change addresses the root issue, can produce
the desired outcome in the real system, is the simplest and most coherent way
to do so, remains safe under failure, and is honestly proven. Detailed code
correctness is secondary when the proposed mechanism cannot complete the
end-to-end operation.

## Operating posture

Start with the root issue, desired outcome, and complete operating topology, not
with individual lines in the diff or the mechanism named by the author. Treat
every extra state, registry, queue, retry loop, authority, fallback, handoff,
and special case as a design decision that needs a reason. Prefer deleting
machinery or reusing an existing invariant-preserving mechanism over adding
another subsystem.

The strategic questions are mandatory for every non-trivial review:

1. What is the root issue, stated independently of the proposed solution?
2. What observable outcome is required, and for whom?
3. Can the proposed solution produce that outcome at all across its real
   end-to-end path?
4. What is the simplest viable way to produce it, and why is the proposal not
   simpler?
5. What is the most elegant viable way to produce it, and why is the proposal
   not more coherent?
6. How can the outcome fail because of the surrounding architecture on every
   relevant local, CI, development, staging, or production platform?

“Simplest” minimizes concepts, states, authorities, handoffs, and operational
responsibilities. “Elegant” means clear ownership, one canonical path, reliable
local reasoning, and few exceptional semantics. They can point to different
choices; report that tradeoff instead of treating either word as praise.

Inventory effects by blast radius, not only by the API or component that writes
them. A change to process-wide, runtime-wide, host-wide, or otherwise ambient
state can alter consumers that never traverse the intended call path. Give such
effects explicit review ownership even when the writer is the correct authority
for the feature being added.

Keep discovery read-only. Review workers must not edit source, commit, push,
comment, resolve review threads, or change tracker state unless the user has
explicitly asked for an implementation/refinement phase. This separation keeps
independent findings from collapsing into the first plausible patch.

If the target is a stacked PR, establish the exact parent head and intended
ancestry before reviewing the delta. A stale stack can make both bugs and fixes
look real when they are artifacts of the wrong base.

## Freeze the strategic review contract

Before delegation, the parent writes one compact contract from the user's
stated outcome, the actual topology, the PR, and repository-owned requirements.
This is a review boundary, not a new design: if sources disagree or omit a
consequential choice, mark it unproven rather than silently redefining success.
When Architect has already produced a strategic frame, refine that artifact
into this contract instead of creating a second authority for the root issue or
outcome. This contract then satisfies Architect's strategic-framing step.

```markdown
## Review contract
- Root issue: <underlying user or operational problem, not solution-shaped>
- Desired outcome: <terminal observable result and observer; distinguish availability, eligibility, deployment, and live activation when they differ>
- Forbidden outcomes: <the motivating failure in user-visible terms>
- Proposed solution: <mechanism, owner, and claimed scope>
- End-to-end capability path: <trigger principal -> authorizer -> execution/delegated identities -> stores/services -> final observer>
- Capability verdict: <capable | incapable | unproven, with evidence>
- Simplest viable option: <fewest concepts/authorities/handoffs, and comparison with proposal>
- Most elegant viable option: <clearest ownership/canonical path, and comparison with proposal>
- Platform topology: <relevant local/CI/cloud-dev/staging/prod differences; justify omissions>
- Outcome failure map: <where the outcome can fail on each relevant platform and who observes it>
- Semantic delta: <states moving between rejected, accepted, stored, exposed, or acted upon>
- Changed representations: <wire -> parsed -> stored -> loaded -> domain -> UI/response>
- Downstream consumers: <production readers of each changed representation>
- PR claims: <positive, negative, scope, compatibility, retention, and operational claims>
- Required repository artifacts: <applicable PR-template fields, ticket convention, generated docs/checks>
```

Trace the operation itself, not one Terraform root, service, process, or code
path in isolation. Different identities or permissions in adjacent stages do
not compose unless the same operation has an explicit, viable handoff. A
proposal that cannot complete the capability path is a primary-goal
contradiction, even if each component is locally valid and tested.

Use `incapable` when the reviewed mechanism omits or contradicts a required
stage in that path. Use `unproven` when the stage is present or credibly claimed
but the available evidence does not establish it. If unseen surrounding code
might supply a missing stage, report both scopes explicitly: the proposal is
incapable as described and the larger system is unproven.

Any previously rejected, absent, or impossible state that becomes admissible is
a semantic delta, even when the diff describes itself as local to one layer. A
changed representation with an uninspected production consumer is an unproven
blocker. Declared PR scope does not turn a contradiction of the desired outcome
into an accepted limitation.

## Adaptive delegation

Do not equate reviewer count with coverage. The parent owns the strategic
contract and synthesis. Delegate an independent **system-fit lane** for every
non-trivial review, then select only the additional risk lanes whose failure
classes are present. Most small reviews need system fit plus evidence. Stateful,
security-sensitive, cross-boundary, or operational changes may need all four
lanes. Record why each lane is included or omitted.

The available lanes are:

1. outcome, system fit, and simplification — always;
2. behavioral correctness, ownership, and resilience — when state, time,
   concurrency, retry, cleanup, or recovery matters;
3. boundaries, contracts, and trust — when data, identity, authority, shared
   resources, or independently maintained components cross a boundary;
4. evidence and operational truth — always.

Run selected workers independently and in parallel from the same frozen review
boundary. Keep synthesis in the parent/orchestrator after every selected report
arrives. Do not split implementation by layer during discovery.

Match ceremony to the review object. For a short immutable design statement,
freeze the quoted statement, record lane inclusion or omission, and allow
compact lane deltas. Use content digests, full PR artifacts, machine-mergeable
schemas, and exhaustive coverage ledgers for mutable code/PR boundaries,
multiple material findings, or high-risk reviews where they improve auditability.
Never lighten the strategic questions themselves.

In Codex, use `gpt-5.6-sol` with `medium` reasoning for every selected lane by
default. The consistent profile makes reports comparable and gives each lane
enough architectural judgment. The parent retains synthesis ownership; it may
use a separate synthesis worker only as an independent critic. An override is
allowed when failure cost, codebase scale, or a worker's evidence justifies it;
record the reason rather than silently changing the route. In another harness,
use its closest consistent medium-depth frontier profile.

Give every worker:

- the exact repository/worktree and review boundary;
- the frozen content identity, refreshed immediately before dispatch: the exact
  commit or PR head when clean, otherwise an immutable snapshot or diff digest
  that includes staged, tracked, and relevant untracked content;
- the frozen strategic review contract, capability path, platform topology,
  failure map, and relevant architecture/design sources;
- the shared invariant reference;
- for PR reviews, the current title/body, repository PR template, and available
  linked-ticket metadata and repository-specific link/close convention;
- an isolated report path, such as `/tmp/aggressive-review-<run-id>/<lane>.md`;
- an explicit read-only boundary and stop conditions.

Launch all selected workers from the same frozen review boundary in one
delegation turn. Give each worker the same context and invariant reference,
changing only the lane question and report path. Wait for all selected reports
before synthesis; do not let the first finding become the implementation plan.

Treat rubric coverage and orchestration completeness as separate failure modes.
A lane cannot find a class of effect its question excludes, while a complete
rubric provides no protection if the final run selectively skips lanes or
reuses stale conclusions. Check both independently.

Workers should report concrete failure modes, not broad opinions. Each report
must end with `Design decisions autonomously taken`, even when the lane made no
autonomous design choice.

## Review lanes

### 1. Outcome, system fit, and simplification

Ask whether the change addresses the root issue, can reach the desired outcome
through the whole system, and is the simplest and most elegant viable design.

Look for:

- a root issue stated without assuming the proposed mechanism;
- a clear user/system outcome and the minimum behavior required to achieve it;
- an end-to-end capability trace through actual identities, authorities,
  services, stores, handoffs, and final consumers;
- component-level successes that fail to compose into the required operation;
- relevant platform differences in topology, identity, data, configuration, or
  provider behavior, with explicit reasons for excluding irrelevant platforms;
- the simplest viable alternative and its concrete tradeoffs;
- the most elegant viable alternative and its concrete tradeoffs;
- one semantic model for the main thing being operated on;
- one authority per important fact or resource;
- one canonical path for each semantic action;
- state or behavior whose visibility extends beyond its owning component;
- unnecessary state, indirection, queues, registries, retries, flags, and
  compatibility branches;
- abstractions that make the design harder to explain or harder to change;
- architecture that conflicts with the larger system's direction;
- opportunities to delete machinery instead of adding another mechanism.

For a PR, also read its title and body as the public design explanation. Check
that plain language says why the change exists, what behavior changes, what does
not, and what evidence supports it. Reconcile every applicable repository
template section and literal label; implementation bullets do not substitute
for the motivating problem.

Do not confuse elegance with cleverness. An elegant design has few concepts,
clear ownership, local reasoning, and no special path that quietly changes the
meaning of the operation. If the proposal is incapable of meeting the outcome,
say so before discussing refinements to its implementation.

### 2. Behavioral correctness, ownership, and resilience

Ask whether the implementation remains correct across time, concurrency,
failure, retry, cleanup, and restart.

Apply these questions to the complete capability path and every relevant
platform in the strategic contract, not only the changed component.
Establish the platform's real atomicity, idempotency, immutability, retry, and
cleanup semantics before proposing custom records, queues, staging areas,
serialization, or repair machinery.

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
- ambient mutations whose scope or lifetime exceeds one operation, request, or
  owner, including how overlapping users observe installation and restoration;
- teardown that restores a stale snapshot, overwrites an intervening mutation,
  or resurrects an owner that has already stopped;

For every meaningful boundary, ask what happens if the process dies immediately
before and immediately after it. Restart should be an ordinary convergence path,
not a separate best-effort repair story.

When the semantic delta admits a previously rejected, absent, or impossible
value, trace its exact persisted representation through every production reader
until it is consumed, deliberately dropped, or returned. Exercise it alone,
combined with every behaviorally distinct valid class, and through relevant
retry or duplicate forms. Record this table:

| State | Edge result | Stored form | Consumer result | Failure radius | Signal |
|---|---|---|---|---|---|

A thrown exception is not evidence of safe failure merely because it is called
"fail closed." Prove whether its containment boundary is the record, operation,
tenant/facility, or fleet/system, and compare that radius with the forbidden
outcomes in the review contract.

### 3. Boundaries, contracts, and trust

Ask whether every boundary agrees and whether invalid or hostile input can create
ambiguity or forge authority.

Follow identities, authorities, and shared resources across environment and
deployment boundaries. Prove that adjacent permissions and handoffs compose
into the desired operation; do not infer end-to-end authority from separately
valid per-environment configurations. Distinguish who may request the operation,
who authorizes it, who executes each mutation, and who may advance the result
from available to eligible, deployed, or active.

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
- changed semantics for foreign consumers that share a process, runtime,
  namespace, registry, environment, or other ambient dependency without using
  the reviewed feature's public path.

For each sentinel, fallback, `UNKNOWN`, `Other`, null, or lossy normalization,
test it alone and beside each behaviorally distinct recognized state at the
same identity, window, or key. When several source values collapse into one
stored form, identify what remains diagnosable and whether signals distinguish
unknown-only, known-plus-unknown, and conflicting-known states. Compare edge
acceptance, warning, persistence, and every reader's consumption semantics;
layer-local consistency does not excuse cross-layer disagreement.
Missing diagnostic fidelity is a finding only when a stated requirement or a
concrete user/operational harm makes the distinction necessary. Otherwise
record it as an open question or note; do not invent a reporting requirement.

When a diff makes a response, request, event, diagnostic, JSON/blob, or
"verbatim if small" object durable, recursively inventory the actual
source-authored fields in normal and truncation paths. Check bounds,
authorization, redaction, UI exposure, deletion/retention, and documentation
claims. Do not stop at the headline field that motivated storage.

Adapters may translate between boundaries, but they must not create a second
semantic interpretation of the same operation.

Audit authority and compatibility independently. Authority asks who is allowed
to mutate a fact or resource. Compatibility asks whether every affected
consumer still observes the semantics it relies on. Proving the first does not
prove the second, and an intended API contract does not bound an effect whose
actual visibility is wider.

### 4. Evidence and operational truth

Ask whether the tests, documentation, and operating behavior actually prove the
claims being made.

Map every desired-outcome and failure-map claim to evidence at the platform
where it matters. When local and cloud paths differ, local proof cannot close a
cloud capability or failure claim.

Look for:

- tests that exercise a nearby fixture instead of the real boundary;
- missing failure injection at persistence, process, transport, cleanup, and
  restart boundaries;
- tests that prove a result but not ownership, idempotence, or absence of leaks;
- isolated tests that cannot reveal interference with concurrent or unrelated
  consumers of shared ambient state;
- migration and backward-compatibility gaps;
- observability that cannot distinguish retry, recovery, and duplicate work;
- platform-specific behavior claimed without platform-specific evidence;
- docs, launchers, schemas, and error descriptions that overclaim runtime
  behavior;
- operational paths whose proof stops at unit tests when a product/integration
  path is required.

If the diff adds or retains a compatibility overload, fallback, optional field,
or best-effort write, require a rolling-version table rather than the vague
claim "backward compatible":

| Writer/reader ordering | Durable winner | User-visible result | Recovery/convergence |
|---|---|---|---|

Include old-writer/new-reader, new-writer/old-reader, concurrent old/new writers,
and retry ordering when applicable. Name swallowed refusals and stale UI/API
state explicitly. Mark any cell whose winner, user-visible result, or
convergence mechanism is not established by evidence as `unproven`; never fill
the matrix by assuming conventional overwrite or retry semantics.

Classify every material fact as introduced, changed, a pre-existing
contradiction of a PR claim, or unrelated. Pre-existing behavior is not a
regression, but it can invalidate a global claim such as "never," "only," or
"no source data persists." For PR reviews, reconcile each body claim and
applicable template field with evidence. Verify repository-specific ticket
syntax when the repository requires it, and classify omissions as process
findings rather than runtime defects. First establish that the PR is linked,
that the convention applies to this PR lifecycle stage, and that merge is meant
to close the ticket. Missing operands are an open question, not a defect.

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
- Every newly admissible representation has a deliberate downstream meaning
  and a proven containment boundary.
- Durable source-authored data is inventoried and described truthfully.
- Ambient mutations are scoped to the narrowest valid lifetime, compose safely
  under concurrency, and remain compatible with every consumer in their real
  visibility domain. Cleanup removes only its owned effect; out-of-order
  teardown converges to the state for the remaining live owners, or the original
  state when none remain.

## Worker report contract

For full code/PR reviews and multi-worker finding merges, use
[`references/finding-schema.md`](references/finding-schema.md) for the report
shape, severity rubric, and enum values. A compact design review may omit empty
sections and schema fields when no material finding needs cross-worker
reconciliation, but it must still state the strategic verdict, source-backed
evidence, open limits, and `Design decisions autonomously taken`.

Do not promote a vague concern to a finding. A finding needs a source-backed
failure mode or a clearly demonstrated proof gap. If two findings violate the
same invariant through the same root cause, link them and let synthesis merge
them.

For a proof-gap finding, severity reflects the consequence of relying on the
unproven claim, not proof that the runtime defect has occurred. Say explicitly
`readiness blocker due to proof gap` when that is the evidence; do not describe
it as a demonstrated incident or regression.

For an ambient effect, make the evidence and proof spell out its actual
visibility domain and lifetime, affected foreign consumers, cleanup ownership,
and behavior under overlap or concurrency. Do not accept feature-local tests as
compatibility proof when the mutation is observable outside that feature. Test
both teardown orders, partial installation, duplicate cleanup, and a foreign
observer at each transition when those states are reachable.

For full reports, use only the finding schema's enum values; a PR body or other
documentation artifact has evidence kind `documentation` and proof tier
`source`. Severity follows actual goal impact and failure radius, not the layer
where the defect happens.

## Synthesis and refinement

After all selected lanes finish, the parent reads every report and produces one
consolidated ledger. It should:

1. state the root issue and desired outcome independently of the proposal;
2. give a source-backed `capable`, `incapable`, or `unproven` verdict for the
   proposal's end-to-end capability path;
3. compare the proposal with the simplest and most elegant viable options;
4. merge duplicates by violated invariant and root cause;
5. preserve the strongest evidence and the clearest reproduction;
6. separate direct review issues from proactive findings and accepted limits;
7. identify interactions where individually safe changes compose unsafely;
8. trace effects that escape the intended call path to every consumer in their
   actual visibility domain; contract narrowing cannot dismiss those effects;
9. reconcile the outcome failure map across every relevant platform;
10. rank findings by user impact, recoverability, security, and proof confidence;
11. prefer a deletion, a single owner, or an existing mechanism over a new
   subsystem;
12. state what is already protected and what remains unproven.

Before completing synthesis, build a coverage ledger for the desired outcome,
capability path, platform failure map, every semantic delta, and every
PR/template claim in the frozen contract. Mark each `proven`, `contradicted`,
or `unproven`, with evidence. Completion is blocked when an entry is missing or
merely assumed. In particular:

- `goal_impact: contradicts` cannot be accepted only because the PR declares
  the affected consumer out of scope;
- every global or negative claim (`never`, `only`, `lossless`, `fail-closed`,
  `no source ...`) needs matching evidence or narrower wording;
- rank primary-goal contradictions and wider failure radii before elegance or
  declared scope;
- keep `pre-existing-claim-contradiction` separate from diff-introduced
  regressions while still requiring the public claim to become truthful.

If the user asks for implementation, turn selected findings into red tests or
reproductions before changing production behavior. Keep refinement ownership
separate from discovery ownership when possible. Focused lane reruns are useful
while iterating, but they are not the completion review. After the final change,
freeze the final content identity, rebuild the strategic contract from actual
final topology, and rerun every selected lane independently from scratch,
followed by a fresh synthesis against that same boundary. Reconsider lane
selection if the final diff added a new risk class. For a clean or published PR,
this identity is the exact final head. For an authorized but uncommitted
refinement, it must be an immutable snapshot or digest that includes the actual
changed content. Do not inherit selective earlier conclusions as proof that
unrelated side effects are absent.

## Completion boundary

The review is complete when the consolidated report can answer all of these:

- What is the root issue, stated without assuming this solution?
- What is the observable desired outcome?
- Can this proposal produce that outcome through the complete operating path?
- Is it the simplest viable solution? If not, why not?
- Is it the most elegant viable solution? If not, why not?
- How can the outcome fail in the surrounding architecture on every relevant
  local and cloud deployment platform?
- What are the authoritative owners and canonical paths?
- Which effects escape their intended call path, what is their true visibility
  and lifetime, and are foreign consumers compatible with them?
- What invalid, duplicate, orphaned, or unrecoverable outcomes are impossible?
- What happens at each meaningful crash, retry, cleanup, and restart boundary?
- Do all contracts and trust boundaries agree?
- Does the evidence match the claims, including platform and product-path limits?
- Is every semantic delta and repository-required PR artifact proven,
  contradicted, or explicitly unproven?
- Which findings are fixed, accepted, false positives, or still blocked?

The completion answers must come from the fresh strategic contract and all
selected independent lanes reviewing one frozen final content identity, named
and verified by every worker and synthesis. Use the exact final head whenever
the reviewed state is committed. Narrowing the intended feature contract cannot
close an unrelated effect on ambient state; only source-backed proof that the
effect is contained or compatible can do so.

Do not call a design complete merely because a focused test passes. Do not make
external PR, tracker, commit, or deployment changes unless the user has
explicitly authorized them.
