# Shared review invariants

Use these as common vocabulary when the change touches more than one concern.
Apply only the invariants relevant to the actual claim.

## Outcome and system fit

- The root issue and desired outcome are stated independently of the proposed
  mechanism.
- The mechanism can complete the real operation through its identities,
  authorities, stores, services, and terminal consumer.
- The design uses no more concepts, state, authority, or handoffs than the
  outcome requires.
- Each outcome-threatening failure has an owner, signal, containment boundary,
  and matching acceptance evidence.

## Authority, paths, and state

- One authoritative owner exists for each important fact, resource, and side
  effect.
- One canonical semantic path exists for each operation; adapters translate
  but do not create alternate meaning.
- Invalid states are impossible or immediately recoverable.
- Claimed work has an owner until durable handoff or cleanup acknowledgement;
  semantic work does not disappear or duplicate accidentally.

## Durability and recovery

- Durable state precedes public effects.
- Retries preserve logical identity and owned input custody.
- A crash between meaningful boundaries leaves state that restart can interpret
  and converge.
- Cleanup clears durable intent only after durable absence is established.

## Boundaries and contracts

- Limits apply before unbounded parsing, allocation, or persistence.
- Untrusted input cannot forge identity, authority, or public metadata.
- Schema, runtime, storage, clients, documentation, and tests agree on the
  contract.
- Every newly admissible representation has a deliberate meaning in each
  affected reader and a known containment boundary.

## Proof

- Evidence exercises the boundary named by the claim.
- Failure, restart, concurrency, and compatibility cases receive evidence when
  they can change the invariant.
- A lower proof tier is labeled as supporting evidence, not upgraded by prose.
