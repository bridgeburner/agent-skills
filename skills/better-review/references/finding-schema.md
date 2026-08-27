# Finding and synthesis schema

Use this schema when a review result will be merged across workers. Keep IDs
stable within one review run and link duplicates rather than copying them.

```yaml
id: ARCH-01
lane: architecture | resilience | boundaries | evidence
severity: P0 | P1 | P2 | P3 | note
status: direct-review | proactive | integrated | false-positive | accepted
title: short invariant-oriented title
invariant: shared invariant name
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
inspection of a documentation artifact is proof tier `source`; `documentation`
is not a proof-tier value.

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

Severity follows demonstrated impact. A pre-existing observation is not a
diff-introduced regression; use `pre-existing-claim-contradiction` when it
invalidates a public PR claim, and `unrelated` when it does not.

For `evidence.kind: proof-gap`, severity reflects the consequence of relying on
the unproven claim. Label it as a readiness blocker due to missing proof; do not
present it as a demonstrated runtime incident or regression.

The consolidated report should additionally include:

- the root issue, desired outcome, and review boundary;
- the proposed solution's end-to-end capability verdict;
- comparison with the simplest and most elegant viable options;
- the relevant platform topology and outcome failure map;
- a one-paragraph architecture summary;
- one merged finding table;
- confirmed protections;
- accepted limitations and unproven claims;
- cross-lane interactions;
- an outcome, capability, failure-map, semantic-delta, and PR/template-claim
  coverage ledger, with every entry marked `proven`, `contradicted`, or
  `unproven` and linked to evidence;
- prioritized refinement recommendations;
- `Design decisions autonomously taken`.
