---
name: desloppify
description: "Use when revising a human-facing document, report, README, PR body, deck, HTML artifact, or other visual deliverable to make it clearer and less formulaic. Apply it selectively to deliverables where reader comprehension matters; do not use it for source code, logs, routine commit messages, or chat replies."
---

# Desloppify

Desloppify is a clarity pass for deliverables. It removes stock phrasing,
repeated structure, vague claims, and decoration that hides the important
content. It does not change the underlying facts. The guidance is
harness-agnostic; the optional audit script needs bash, python3, and grep.

Use a light pass:

1. State the document's claim, audience, and next decision or action.
2. Draft or revise the facts and structure before polishing presentation.
3. For prose, use [references/prose.md](references/prose.md) when the document
   needs more guidance. For a rendered artifact, also consult
   [references/visual.md](references/visual.md).
4. Run `scripts/slopcheck.sh <file>` when a mechanical second opinion is useful.
   Inspect its flags; they are signals for judgment, not reasons to rewrite a
   correct sentence mechanically.
5. Preserve all facts when rewriting. Read the opening as a new reader and make
   sure the subject, audience, and requested action are clear quickly.

Useful defaults:

- Vary sentence and paragraph shape where the prose has become monotonous.
- Use concrete subjects, checkable facts, and headings that name their subject.
- Remove slogans, filler, stock marketing language, and title-plus-subtitle
  repetition unless the subtitle adds information.
- Use lists or tables for parallel facts and numbered steps only when order or
  citation matters.
- In visual work, keep color, type, components, and decoration purposeful. A
  paragraph, list, table, or plain diagram is often the clearest element.
- Draw a diagram only when it shows a mechanism, flow, or comparison that prose
  would make harder to see; label relationships and make it usable in both
  light and dark themes.

The audit details live in [references/audit.md](references/audit.md). The
script is a smoke detector, not a quality score. A flagged threshold deserves
inspection; it does not override the reader, the subject, or the document's
purpose.
