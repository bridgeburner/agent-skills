# Shared review invariants

Use these as the cross-lane vocabulary. They are deliberately generalized away
from any one product or implementation.

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

## Proof

- Evidence exercises the boundary named by the claim.
- Failure, restart, concurrency, and compatibility cases are tested where they
  can change the invariant.
- A lower proof tier is labeled as supporting evidence, not upgraded by prose.
