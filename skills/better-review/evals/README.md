# Evaluation intent

`evals.json` contains qualitative review prompts, not a published benchmark.
The cases check whether the skill preserves strategic context, chooses review
depth proportionately, finds concrete source-backed failures, and matches
evidence to the claim.

Cases 4 and 5 are the ambient-effect positive and request-local control. Cases
6 and 9 exercise semantic authorities, retained evidence, ordering namespaces,
and prior-finding continuity. Case 8 checks an end-to-end release failure that
separate environment permissions cannot solve. Case 10 checks that a failed or
empty required product-path result remains missing evidence. Case 11 checks
that independent reviewers are used when context or consequence warrants them,
without equating concern count with worker count. Case 12 checks exact
configuration values, route-level machine identity confinement, coupled
identity documentation, and squash-safe stacked-PR handling.

The prompts should judge outcomes and evidence, not the presence of a named
section, lane, matrix, tracker, or report ceremony. A triggered reference may
still require detailed analysis; an ordinary refactor should not receive
specialized findings merely because the reference exists.

These cases are coverage guards, not proof that the revised wording improves
model performance. Establish an improvement claim with repeated matched runs,
using the same tasks and model settings, and report both quality and cost or
latency variance.
