# Multi-resolver retained evidence

Required behavior: conflict row `R-17` is modeled under canonical patient A in
the terminal lookback result. It must not be dropped, omitted, quarantined, or
attributed to patient B without a visible terminal signal.

The edge transform accepts `R-17` when free-form provenance equals
`sealed-lookback`, resolves it to A, and stores that label plus `batch_ordinal=7`.
A downstream lookback-result loader independently resolves the same episode to
B and compares `batch_ordinal` values from two batches. Rows it cannot reconcile
are omitted without a warning or quarantine ledger.

The bundle schema and artifact validator pass. Unit, integration, and CI checks
are green. No named live-local product-path assertion reached the terminal
lookback result.

A prior audit already reported the downstream loader as a second resolver. The
new PR description calls the edge transform the owning seam and declares the
downstream loader out of scope.
