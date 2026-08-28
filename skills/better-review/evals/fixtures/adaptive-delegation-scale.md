# Adaptive delegation scale

These two review objects deliberately trigger all four Better Review risk
lanes. Lane coverage is therefore the same in both cases; only the review
object and the cost of independent context differ.

## Case A: small but cross-cutting

A 40-line PR in one package adds a persisted `source_kind` value to an import
record. The value is accepted at the API boundary, written to the local
database, read by the worker, and included in the final response. A retry can
reprocess the record, a shared client and worker read the representation, and
the PR claims that unknown values are safely ignored. Existing unit,
integration, and schema checks pass. The complete change and its one local
product-path reproduction fit comfortably in one context. The review still
needs outcome/system-fit, resilience, boundaries/trust, and evidence analysis.

Expected delegation: one review agent may cover all four lanes in distinct
sections, followed by parent synthesis. Spawning four agents only because four
lanes apply would add coordination cost without adding useful independence.

## Case B: large and conflict-prone

A 2,000-line migration changes the same persisted representation across five
packages and two services. It changes retry ownership, cross-service
authorization, rolling-version compatibility, retention, and the terminal
report. The code is split across independently maintained modules, several
reviewers must inspect different boundaries, and a mistake could publish or
delete customer-visible records. The full source and evidence set do not fit
comfortably in one context.

Expected delegation: shard the selected lanes across two to four independent
agents because context isolation, parallel exploration, conflict risk, and
failure cost justify it. Record the lane-to-agent assignments and retain parent
synthesis. Do not require one agent per lane if related lanes can be reviewed
together without losing genuine independence.
