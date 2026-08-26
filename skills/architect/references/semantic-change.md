# Semantic-Change Gate

Use this reference only when a change can alter the meaning or reach of a production representation. The purpose is to prevent a local success from merely relocating failure to a later consumer.

## Trigger

Run both gates when any answer is yes:

- Does rejected/invalid input become accepted or stored, or the reverse?
- Is a sentinel, fallback, tombstone, default, empty value, or value such as `UNKNOWN`, `OTHER`, or `NONE` introduced or reinterpreted?
- Can old and new values coexist in one aggregate, request, row set, window, replay, or retry?
- Does source-authored or customer-controlled data gain a response, persistence, UI, log, metric, or audit destination?
- Will old and new binaries read or write the same durable state during rollout?
- Does the design make a broad claim such as "never", "only", "no raw values", or "fail closed per item"?

Do not run this protocol for an internal refactor whose accepted states, durable representations, consumers, retention, and rollout behavior are unchanged.

## Design Gate — Before Implementation

### 1. Fix the outcome boundary

Write four lines:

```text
User outcome: [positive final behavior]
Forbidden relocation: [failure or denial that must not reappear later]
Maximum failure radius: [field | row | item | request | tenant | facility | system]
Final observable: [what a user, operator, or source sees]
```

A local success response, write, or render is not completion if a first-order consumer can turn the new state into the forbidden failure or a larger failure radius. If the intended disposition is unclear—bucket, drop item, warn, retry, or reject—surface that product decision before coding.

### 2. Enumerate semantic states

List only combinations that can take different branches; do not build a ceremonial Cartesian product. For sentinel changes, begin with:

| Dimension | Minimum cases |
|---|---|
| membership | known only; sentinel only; known + sentinel |
| companion/fallback field | absent; recognized; generic/other; misleading recognized value |
| aggregation | separate keys/windows; same key/window |
| lifecycle | first write; replay/update |
| version, when compatible state is shared | new/new; old->new; new->old |

For each retained row, record ingress decision, canonical stored representation, each first-order consumer decision, final outcome, and failure radius. Collapse rows only after showing that they take the same branch.

### 3. Map first-order consumers and retention

Trace the production representation, not merely the concept:

```text
source field
  -> canonicalizer/validator
  -> persisted field plus conflict/update rule
  -> every direct reader of that field/type/sentinel
  -> reader validation/grouping/fallback logic
  -> response/UI/job/API final effects
```

Search both writers and readers for the concrete literal, enum, field, column, and type. For source-authored data, add explicit allowlists:

```text
May reach: [...]
Must not reach: [...]
Existing exceptions: [...]
```

Inventory retained response fields individually and reconcile them with retention/privacy docs. A bound or access control does not prove that every retained field matches the documented contract. A broad negative claim is allowed only with repo-scoped search evidence and named exceptions; otherwise narrow it to what the change actually proves.

### 4. Model rollout coexistence

When versions share durable state or a compatibility path remains, record:

| writer/read order | durable result | visible result | refusal/retry behavior |
|---|---|---|---|
| old only | ... | ... | ... |
| new only | ... | ... | ... |
| old then new | ... | ... | ... |
| new then old | ... | ... | ... |

Classify a swallowed refusal as safe no-op, retryable loss, or stale visible state. Stale visible state needs an explicit rollout contract, deploy note/monitor, or a design change; request success alone does not make it harmless.

### 5. Select the first-consumer tracer

Choose the thinnest production-quality tracer that carries an exact new representation through the first independently maintained consumer and reaches the final observable. Record:

| Claim | Cheap oracle | Acceptance oracle |
|---|---|---|
| ingress accepts and reports it | route/contract test | real source-facing response |
| canonical state survives storage | DB integration | owner API/read path |
| downstream does not widen failure | consumer contract | containing operation remains successful |
| retained fields match contract | projection/bounds test | allowed read surface |
| rolling coexistence is safe | version-pair integration | staged smoke or explicit accepted gap |

If producer and consumer are independently maintained, read `testing.md` T8 and T12. Use an overlapping contract/wiring test; isolated unit tests on both sides do not prove the seam.

Stop before implementation if any new representation has an uninspected first-order consumer; final disposition or maximum radius is ambiguous; a materially distinct mixed/fallback state lacks an oracle; rollout can alter visible state without a contract; retention conflicts with its allowlist/docs; or a broad claim lacks scoped evidence.

## Implementation Gate — Before Completion

Rerun the state, consumer, retention, and rollout maps against the effective diff. Then run the selected tracer with production-shaped data.

The tracer must assert both:

1. the changed item's explicit disposition and final signal; and
2. success of the containing operation at the declared maximum failure radius.

Reject completion when the new representation is accepted only at the producer, a later consumer still rejects it, the containing operation can fail more broadly, mixed states are unproved, retained destinations exceed the contract, or rolling-version behavior is unproved and unaccepted. If the product-path harness cannot measure the radius, invoke the Harness Gap Protocol in `testing.md`; do not relabel a lower proof tier.

## Handoff Hygiene

Generate the handoff from the outcome contract:

```text
Why: the user or operational problem in simple English.
What: the end-to-end behavior change in simple English.
Evidence: each claim -> its oracle, with explicit proof tiers and gaps.
Issue: carry the issue identity using repository-defined linking/closing conventions.
Public decision: preserve required repository sections; distinguish removed from avoided and write "none" rather than blending them.
```

Keep every public claim no broader than the recorded evidence. Repository instructions, not this reference, define exact PR templates, ticket syntax, and outward-write authorization.
