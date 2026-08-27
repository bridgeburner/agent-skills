# Shared review invariants

Use these as the cross-lane vocabulary. They are deliberately generalized away
from any one product or implementation.

## Outcome and system fit

- The root issue and desired outcome are stated independently of the proposed
  mechanism.
- The proposed mechanism can complete the end-to-end operation through the
  actual identities, authorities, stores, services, and final consumer.
- The chosen design uses no more concepts, state, authority, or operational
  handoffs than the outcome requires.
- Relevant local and cloud platform differences are explicit, and each
  outcome-threatening failure has an owner, signal, containment boundary, and
  acceptance oracle.

## Authority and paths

- One authoritative owner exists for each important fact, resource, and side
  effect.
- One canonical semantic path exists for each operation; adapters translate but
  do not create alternate meaning.

## State and ownership

- Invalid state combinations are impossible or immediately recoverable.
- Every claimed resource has an owner until a durable handoff or cleanup ack.
- No claimed work disappears; no semantic work duplicates accidentally.
- Incomplete work remains private and has an explicit durable meaning.

## Durability and recovery

- Durable state precedes public effects.
- Retries preserve logical identity and owned input custody.
- A crash between any two meaningful boundaries leaves a state that restart can
  interpret and converge.
- Cleanup clears durable intent only after durable absence is established.

## Boundaries and contracts

- Limits apply before unbounded parse, allocation, or persistence.
- Untrusted input cannot forge identity, authority, or public metadata.
- Schema, runtime, storage, clients, docs, and tests agree on the contract.
- Public output never exposes private implementation state accidentally.
- Every newly admissible representation has a deliberate meaning in every
  production reader and a proven failure-containment boundary.
- Durable source-authored data is recursively inventoried, bounded,
  authorized, and described truthfully.

## Ambient effects

- An effect is reviewed across its actual visibility domain, not only the
  writer's intended API or ownership boundary.
- Correct authority to mutate shared state does not imply semantic
  compatibility for every consumer that can observe it.
- Process-wide or otherwise ambient mutations use the narrowest valid lifetime,
  compose safely under overlap, and remove only the effect owned by each cleanup
  operation. Out-of-order teardown cannot overwrite an intervening mutation or
  resurrect a stopped owner.
- Foreign consumers remain correct even when they bypass the feature's intended
  call path but share the mutated dependency.

## Proof

- Evidence exercises the boundary named by the claim.
- Failure, restart, concurrency, and compatibility cases are tested where they
  can change the invariant.
- A lower proof tier is labeled as supporting evidence, not upgraded by prose.
- Completion evidence comes from a fresh strategic contract and every selected
  independent lane reviewing one frozen final content identity: the exact final
  head when committed, or an immutable snapshot/digest that includes the actual
  refinements when uncommitted. Selective earlier lane results support iteration
  but do not close the review.
