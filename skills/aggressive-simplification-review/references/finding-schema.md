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

The consolidated report should additionally include:

- the larger goal and review boundary;
- a one-paragraph architecture summary;
- one merged finding table;
- confirmed protections;
- accepted limitations and unproven claims;
- cross-lane interactions;
- prioritized refinement recommendations;
- `Design decisions autonomously taken`.
