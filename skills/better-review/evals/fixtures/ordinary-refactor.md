# Fixture: ordinary internal refactor

Review boundary: one PR replaces two equivalent parsing helpers with the
existing canonical helper. Inputs, accepted/rejected states, stored values,
public responses, and production readers do not change. The diff adds no
compatibility branch, opaque retained object, fallback, sentinel, or rollout
behavior.

The PR body explains why and what changed, matches every applicable repository
template field, and makes no global or negative retention claim. The
repository has no linked-ticket or closing-syntax requirement for this PR.

Focused parser tests and the existing caller integration test pass. Review the
refactor for a concrete regression or proof gap, but do not manufacture one.
Remain read-only.
