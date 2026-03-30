# Quality Scoring Rubric

From I3 (Quality Scoring + Entropy Management). Used in Audit and Evolve modes to measure and track codebase health. Quality scores are computed per domain, per layer, and stored in `docs/QUALITY_SCORE.md` (auto-generated, never hand-edited).

---

## Quality Score Dimensions

| Dimension | Weight | Measurement | A | B | C | D |
|-----------|--------|-------------|---|---|---|---|
| Branch coverage | 25% | Coverage tool | >= 95% | >= 80% | >= 60% | < 60% |
| Lint violations | 20% | Lint runner | 0 errors | 0 errors, < 5 warnings | < 10 errors | >= 10 errors |
| File cohesion | 15% | Responsibility audit | All files single-responsibility | < 5 multi-responsibility files | < 15 | >= 15 |
| Type coverage | 20% | Type checker strict mode | 0 `any`/untyped boundaries | < 5 | < 20 | >= 20 |
| Doc freshness | 5% | Binary check | Agent instructions + ARCHITECTURE.md updated within last 30 days | Within 60 days | Within 90 days | > 90 days |
| Dead code | 15% | Unused export detection | 0 unused exports | < 5 | < 20 | >= 20 |

### File Cohesion Assessment

File cohesion replaces a rigid line-count threshold. Assessment method:

- **Automated heuristic:** Files over 500 lines in application code (excluding generated files, fixtures, schema registries) are flagged for manual cohesion review.
- **Manual assessment (Audit mode):** For each flagged file, ask: "Does this file have one clear responsibility?" Files with multiple unrelated classes, mixed layers, or changes-for-different-reasons are scored as multi-responsibility.
- **Scoring:** Count of files identified as multi-responsibility across the domain.

## Composite Grade

Weighted average of dimension scores mapped to letter grades:

| Grade | Threshold |
|-------|-----------|
| A | >= 90 |
| B | >= 75 |
| C | >= 60 |
| D | < 60 |

Numeric mapping for averaging: A=100, B=80, C=70, D=40.

---

## Regression Rule

**Per-domain grades cannot decrease on merge.** If a PR would lower a domain's grade, CI blocks it. The author must either fix the regression or file a temporary waiver (see below).

**Overall project grade is tracked but not gated** -- it is informational. This avoids false blocks when well-covered code is legitimately deleted or a new domain is added at low initial coverage.

**Temporary waivers:** A PR may include a `docs/quality-waiver.md` with: owner, scope (which domain/dimension), reason, and expiry date (max 14 days). CI allows the regression for the specified scope. Expired waivers block merge until removed or renewed. Waivers are reviewed in entropy sweeps.

---

## Entropy Sweep Process

```
Cadence: weekly (or configurable)

Sweep agents check:
  - Files with mixed responsibilities (cohesion review)
  - Duplicated logic across domains
  - Unused exports / dead code
  - Patterns contradicting agent instructions or core-beliefs.md
  - Quality score regressions since last sweep

Output:
  - PR with targeted fixes (auto-mergeable if tests pass and quality improves)
  - Issue filed for items requiring human judgment
  - Updated QUALITY_SCORE.md
```

---

## Golden Principles Location

```
Agent instructions file (CLAUDE.md)  # Decision-making context + high-level principles
docs/core-beliefs.md                 # Detailed agent-native principles for this project
Lint configs                         # Machine-enforced subset
scripts/audit/                       # Sweep scripts that check for drift
```

Human taste is fed back continuously through review comments, refactoring PRs, and rule updates -- eventually promoted from documentation into lint rules and structural tests. The taste-encoding pipeline should itself be automated: recurring sweep agents detect deviations, open targeted PRs, and update quality scores.
