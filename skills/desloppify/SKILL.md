---
name: desloppify
description: "Write or rewrite prose and visual deliverables so they read as human technical communication rather than LLM output. Use for ANY document, artifact, deck, report, README, design doc, PR body, memo, or web page you are about to produce or have just produced, and whenever the user says content is slop, bloated, unreadable, over-designed, hard to skim, or 'sounds like AI'. Also use before publishing an Artifact and before handing over a written deliverable. Covers both the prose layer (cadence, structure, punctuation) and the visual layer (colour budget, decoration ratio, typography, diagrams)."
compatibility: "Harness-agnostic. The audit script needs bash, python3, and grep. Visual rules apply to HTML/CSS deliverables; prose rules apply everywhere."
---

# Desloppify

Slop is not a style. It is a set of statistically popular patterns that models
reach for because they are common, not because they are good. Readers have been
trained to spot them, and once spotted they stop reading. That is the actual
cost: not that it sounds like AI, but that the content underneath stops
arriving.

This skill is the counter-protocol. It has two layers, and both matter.
Most de-slop advice covers only prose. In practice, over-decoration destroys
more documents than bad sentences do, because it removes the reader's ability
to tell what is important.

## When to run

- Before producing any written deliverable that another human will read.
- Before publishing an Artifact or a deck.
- After producing one, as an audit pass, if you did not write it under this skill.
- When the user calls something slop, bloated, unreadable, or over-designed.

Do not run this on code, commit messages, log lines, or chat replies. It is for
deliverables.

## The core loop

1. **Establish the spine first.** What is the document's claim, who reads it,
   what do they do next? Write that in one sentence before writing anything else.
   Slop grows in the gap where the spine should be.
2. **Draft the content.** Facts, structure, order. No styling, no headings
   polish, no decoration.
3. **Run the prose pass.** Read `references/prose.md`. Apply it.
4. **Run the visual pass** if the deliverable renders. Read `references/visual.md`.
   Apply it.
5. **Run the audit.** `scripts/slopcheck.sh <file>`. Fix what it flags, or
   justify each exception explicitly. Do not ship a red audit silently.
6. **Read the first screen as a stranger.** If you cannot tell within ten
   seconds what this is, who it is for, and what it wants, the top is wrong.

For a rewrite of existing material, run 3–6 against the existing file and keep
every fact. De-slopping is a presentation change; losing content is a different,
worse failure.

## Non-negotiables

These are the rules that catch the most damage per unit effort. The reference
files explain why and give replacements.

**Prose**

1. **Vary cadence deliberately.** Uniform rhythm is the tell that survives
   longest. Do not let three consecutive sentences share a shape.
2. **No tricolons as structure.** "X, Y, and Z" as a heading, deck, or summary
   line is the single most recognisable pattern. Once per document, at most,
   and only when the three things are genuinely a set.
3. **No slogans.** A heading names its subject. It does not sell it, rhyme,
   or land a point. "UI done right" is a slogan; "UI release lane" is a name.
4. **One heading, not heading plus deck.** A subtitle earns its place only by
   carrying a fact the heading does not. Restating the heading in different
   words is pure noise, and doing it on every section is the strongest
   structural tell there is.
5. **Never "It's not X, it's Y."** Nor "not merely", "more than just",
   "isn't about X — it's about Y". State the thing.
6. **Punctuation budget.** Em dashes: at most 1 per 500 words. Arrows (`→`) and
   middots (`·`) belong in diagrams and notation, not in prose. Use periods,
   commas, colons, parentheses.
7. **No anthropomorphism for systems.** Postgres does not "own" anything and a
   clock does not "ask". Say what the code does.
8. **Structural devices must encode information.** Numbered markers only for
   real sequences. No emoji section markers. No decorative eyebrows.

**Visual**

9. **Three meaning colours, maximum**, plus a neutral scale. Every additional
   hue costs the reader a legend entry they must hold in memory.
10. **Decoration ratio.** Under ~40 decorated elements per 1000 words. Pills,
    chips, badges, cards, rails, hatching and tags all count. If everything is
    emphasised, nothing is.
11. **Let plain things be plain.** The default element is a paragraph, a list,
    or a table. Reach for a component only when the plain form actually fails.
12. **Diagrams show mechanism.** If a sentence says it faster, write the sentence.

## Measuring

`scripts/slopcheck.sh <file.md|file.html>` reports the mechanical signals:
punctuation density, tricolon and slogan candidates, banned constructions,
heading-plus-deck pairs, CSS selector count, decoration ratio, and colour count.

It is a smoke detector, not a judge. A clean report does not mean the writing is
good, and a flagged line is sometimes correct. But an unexamined red report
always means something is wrong.

## References

- `references/prose.md` — the prose rules, banned patterns, and replacements.
- `references/visual.md` — colour, type, layout, decoration, diagrams, themes.
- `references/audit.md` — how to read the audit output and what each signal means.
- `scripts/slopcheck.sh` — the mechanical pass.
