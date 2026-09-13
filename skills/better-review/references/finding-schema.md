# Optional finding record

Use this format only when multiple reviewers need stable, mergeable records.
For a single review, concise prose is usually clearer. Keep IDs stable within
one run and link duplicates instead of copying them.

```yaml
id: F-01
focus: outcome | behavior | boundary | evidence | other
severity: P0 | P1 | P2 | P3 | note
status: direct | proactive | integrated | false-positive | accepted | unresolved
title: short invariant-oriented title
invariant: shared invariant name or none
claim_tested: PR/product claim or none
goal_impact: preserves | weakens | contradicts | unrelated
failure_radius: record | operation | tenant/facility | fleet/system | process-only | none
change_ownership: introduced | changed | pre-existing-claim-contradiction | unrelated
proof_tier: source | focused-test | integration-tracer | live-product
location:
  - path: relative/path
    lines: "12-30"
evidence:
  kind: source | test | reproduction | proof-gap | documentation
  detail: source-backed evidence
failure_mode: concrete behavior and impact
minimal_remedy: simplest coherent remedy
proof_needed: test or operational evidence
overlap: []
confidence: high | medium | low
```

Use only the listed enum values. Documentation can be the evidence `kind`, but
inspection of a documentation artifact is proof tier `source`.

## Severity rubric

- `P0`: security-boundary defeat, irreversible broad data loss, or a
  system-wide emergency.
- `P1`: contradicts the primary product outcome, recreates the motivating
  failure, or causes tenant/facility-wide unavailability or data loss.
- `P2`: a real contained and recoverable user or operational failure, including
  rollout staleness.
- `P3`: documentation, process, or maintainability defect without current
  runtime impact.
- `note`: relevant truth that requires no change in this PR.

Severity follows impact and failure radius. A proof gap is a readiness blocker
only when relying on the missing evidence could affect a consequential claim;
describe it as missing proof, not as a demonstrated incident. A pre-existing
observation is not a diff-introduced regression; use
`pre-existing-claim-contradiction` when it invalidates a public claim, and
`unrelated` when it does not.

When merging records, preserve the root issue, required outcome, review
boundary, capability verdict, relevant prior-finding status, evidence limits,
and the smallest useful next action. Add platform, failure, semantic, or
coverage detail when the claim requires it; omit empty sections. This format
does not prescribe a report or separate decision ledger.
