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

For a stacked PR, carry the boundary through the parent merge. If the parent is
squash-merged, rebuild the child on the actual post-parent default branch;
retargeting is not proof. Before approval, verify patch identity with
`git range-diff` or a stable `patch-id`, the exact final file/resource scope,
and fresh CI plus plan evidence where applicable. Flag handoffs that say only
"retarget" and leave the rebuild and proof implicit.

## Freeze the strategic review contract

Before delegation, freeze one compact contract from the user's outcome, actual
topology, PR, and repository requirements. Also ledger every prior finding or
proof gap from the task, tracker, corrections, earlier reports/comments, and
retained reproductions, with affected consumer, disposition, and closing evidence
or explicit user acceptance. Scope cannot erase it: re-find, source-disprove,
user-accept, or keep it blocking. This is a review boundary, not a new design;
source disagreement or omission stays unproven. Reuse Architect's frame, not
another authority.

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
- Changed representations / downstream consumers: <wire/first resolver -> stored form -> every loader/re-reader/duplicate resolver/ledger/API/UI -> terminal observer>
- Prior findings: <finding -> consumer/boundary -> re-found | disproved | user-accepted | blocking, with evidence>
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

A semantic delta includes any fact newly accepted, rejected, selected, resolved,
normalized, attributed, or reclassified. Trace its first resolver, persisted
form, and every loader, re-reader, duplicate resolver or attribution step,
ledger, API, UI, and terminal consumer. The first resolver is not authoritative
by position; each later independent ruling is a second authority until it reuses
the canonical ruling or is proven equivalent. An ordinal orders only its declared
namespace: never compare batch-, request-, file-, or run-local positions across
namespaces without a cross-scope key or a proven single-namespace invariant.
Any uninspected consumer or unresolved authority mismatch is an unproven blocker;
declared scope cannot waive a contradiction of the desired outcome.

## Adaptive delegation

Lane selection and worker count are separate decisions. Parent owns the strategic contract, assignment, and synthesis; select risk lanes first,
then choose one to four review agents based on review size, context isolation,
conflict risk, and failure cost. Never add an agent merely to mirror a selected
lane, and never reduce lane coverage because one agent handles several lanes.

The available lanes are:

1. outcome, system fit, and simplification — always;
2. behavioral correctness, ownership, and resilience — when state, time,
   concurrency, retry, cleanup, or recovery matters;
3. boundaries, contracts, and trust — when data, identity, authority, shared
   resources, or independently maintained components cross a boundary;
4. evidence and operational truth — always.

- A small or manageable review may use one agent for all selected lanes,
  including all four, with distinct lane sections; do not call them independent
  worker reports.
- A larger or higher-risk review may shard across two to four agents when
  parallel exploration, context isolation, conflict risk, or failure cost
  justifies it. Related lanes may share an agent; a lane needing genuine
  independence gets its own.
- Record the lane set, agent count, assignments, and reason; the parent verifies
  coverage and synthesizes every lane.

Dispatch chosen workers from one frozen boundary. Parallelize only with multiple
workers; with one agent, preserve distinct lane sections and have the parent
synthesize and verify coverage. Do not split implementation by layer.

Match ceremony to the review object: use compact lane deltas for short immutable
statements; use digests, full artifacts, mergeable schemas, and coverage ledgers
for mutable or high-risk boundaries. Never lighten the strategic questions.

In Codex, default delegated review agents to `gpt-5.6-sol` with `medium`
reasoning; in another harness, use its closest consistent medium-depth frontier
profile. The parent may use a separate synthesis critic. Override for failure
cost, codebase scale, or worker evidence, and record the reason.

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
- an isolated report path, such as `/tmp/aggressive-review-<run-id>/<agent>.md`;
- an explicit read-only boundary and stop conditions.

Launch chosen workers in one delegation turn with the same context and
invariants, adding only assigned questions and report paths. Wait for all reports
before synthesis; the first finding never becomes the implementation plan.

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

For every semantic delta, exercise the exact persisted form alone, with each
behaviorally distinct valid class, and through retries or duplicates. A mixed
case for resolution or attribution must reach every resolver. Record one row per
resolver or consumer, including its ordering namespace and negative sink:

| State/input | Resolver + namespace | Ruling/authority | Stored/result form | Terminal positive result | Drop/omission/quarantine/wrong-attribution signal | Failure radius |
|---|---|---|---|---|---|---|

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

For machine-principal, binding, route, or protected-resource changes, build the
smallest principal-by-route allow/deny matrix at the composition boundary.
Component token/auth tests do not prove route-level confinement. Sweep directly
coupled inventories, IAM docs, comments, outputs, and runbooks for stale
`only`, `no binding`, or `sole invoker` claims; keep the sweep limited to
artifacts that name the changed boundary.

Look for:

- disagreement between schema, runtime validation, clients, and storage;
- provenance or source text used to authorize accept/reject/quarantine/fail-open.
  Provenance may describe a ruling; authorization is a typed/shared capability
  with one owner and aligned callers, defaults, and serialized forms;
- ordinals compared outside their declared batch/request/file/run namespace
  without a cross-scope key or proven single-namespace invariant;
- error codes or phases that are open-ended in one layer and closed in another;
- implicit defaults, falsy coercion, or compatibility behavior that changes the contract;
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

Map each desired-outcome and failure-map claim to evidence where it matters.
Local proof cannot establish a distinct cloud capability or failure claim.

Apply the global live-local validation bar. Only a named assertion through the
real local product entry point, services, persisted input, all semantic
consumers, and terminal result validates behavioral correctness or completeness.
Assert the expected positive result and each relevant negative sink or absence,
including drop, omission, quarantine, and wrong attribution. A missing, failed,
or empty live result blocks readiness.

Unit/integration tests, CI, VMs, schemas, replays, artifacts, and deployments are
development diagnostics only. Structural success never proves the affected fact
survived, retained its canonical ruling, or reached the terminal observer.

Look for:

- tests that exercise a nearby fixture instead of the real boundary;
- missing failure injection at persistence, process, transport, cleanup, and
  restart boundaries;
- proof of a result without ownership, idempotence, absence of leaks, or
  interference with concurrent and foreign consumers;
- migration, rolling-version, observability, or retry/recovery gaps;
- platform claims without platform evidence; and
- docs, launchers, schemas, or error descriptions that overclaim behavior.

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

Classify every material fact as introduced, changed, a pre-existing claim
contradiction, or unrelated. Pre-existing behavior is not a regression but can
invalidate global claims such as "never," "only," or "no source data persists."
Reconcile each PR claim and required template field with evidence. Treat missing
ticket syntax as a process finding only after proving the PR is linked, the
convention applies at this lifecycle stage, and merge should close the ticket;
missing operands remain an open question.

For each PR-named source/config contract, trace `source of truth -> exact expected
value -> assertion -> workflow/job invocation -> required check`. A direct local
pass is not CI enforcement. Presence-only assertions do not prove a value
contract. For a negative or absence claim, verify that the inspected scope
contains every path that could violate it; otherwise the test may pass vacuously.

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
4. reconcile each prior finding as re-found, source-disproved, user-accepted, or blocking;
5. merge duplicates by violated invariant and root cause;
6. preserve the strongest evidence and distinguish direct, proactive, and accepted items;
7. identify interactions where individually safe changes compose unsafely;
8. trace effects that escape the intended call path to every consumer in their
   actual visibility domain; contract narrowing cannot dismiss those effects;
9. reconcile the outcome failure map across every relevant platform;
10. rank findings by user impact, recoverability, security, and proof confidence;
11. prefer a deletion, a single owner, or an existing mechanism over a new
   subsystem;
12. state what is already protected and what remains unproven.

Before completing synthesis, reconcile the prior-findings and semantic-authority
traces, then build a coverage ledger for the desired outcome, capability path,
failure map, every semantic delta, PR/template claim, required review/check, and
the named live-local assertion. Mark each `proven`, `contradicted`, or
`unproven`, with evidence. A failed, empty, malformed, or non-terminal required
result is missing evidence, never approval; it blocks readiness. In particular:

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

- What root issue and terminal outcome exist independently of this proposal?
- Can the proposal produce it through the full path, and is it the simplest and
  most elegant viable option?
- How can it fail on each relevant platform, and who owns each canonical path?
- Which effects escape that path, and what happens to invalid, duplicate,
  orphaned, or unrecoverable work at crash, retry, cleanup, and restart?
- Do all contracts and trust boundaries agree, including typed authorization,
  descriptive provenance, and ordering namespaces?
- Did every semantic decision reach every resolver, store, loader, re-reader,
  ledger, API/UI, and terminal consumer under one canonical ruling?
- Did the named live-local assertion prove the positive terminal result and the
  relevant drop/omission/quarantine/wrong-attribution negatives?
- Is every prior finding, semantic delta, PR artifact, and required check proven,
  contradicted, user-accepted, or still blocking, with a real terminal result?
- Which findings are fixed, accepted, false positives, or still blocked?

The answers must come from the fresh contract and every selected lane reviewing
one verified frozen final identity. Use the exact final head when committed.
Contract narrowing cannot close an ambient effect; only source-backed proof of
containment or compatibility can.

Do not call a design complete merely because a focused test passes. Do not make
external PR, tracker, commit, or deployment changes unless the user has
explicitly authorized them.
