# Explanatory Prose Guide

How to write explanatory prose that serves the content. Every sentence exists to move the reader closer to understanding.

## Narrative Arc Templates

### Tutorial Arc

```
Hook: Why should the reader care? What can they do after reading this?
   ↓
Foundation: Establish the minimum vocabulary and context (keep it short)
   ↓
First contact: Simplest possible example. Reader observes.
   ↓
Guided exploration: Reader begins to manipulate. Complexity increases.
   ↓
Aha moment: The key insight lands. Reader sees the concept work (or break).
   ↓
Consolidation: Restate the insight in formal terms. Connect to the big picture.
   ↓
Extension: Where does this lead? What should the reader explore next?
```

### Report / Analysis Arc

```
Thesis: State the finding up front. No suspense — the reader needs the conclusion first.
   ↓
Context: What question was being asked? What prompted this analysis?
   ↓
Evidence 1: First supporting data point / figure + interpretation
   ↓
Evidence 2-N: Additional supporting evidence, each with figure + interpretation
   ↓
Counter-evidence: What complicates the finding? What are the limitations?
   ↓
Synthesis: How do all the evidence points combine? What is the complete picture?
   ↓
Implications: What should the reader do with this knowledge?
```

### Presentation Arc

```
Title slide: One sentence that captures the entire talk
   ↓
Hook slide: Why this matters. A question, a surprising fact, a problem statement.
   ↓
Context slides (1-2): Just enough background for the audience to follow
   ↓
Core content (60-70% of deck): The argument, evidence, or tutorial content
   ↓
Key insight slide: The single most important takeaway (design this slide to be screenshot-worthy)
   ↓
Implications / next steps: What the audience should do or think about
   ↓
Closing slide: Mirrors title treatment. Call to action or memorable closing line.
```

### Paper / Article Arc

```
Opening: Draw the reader in. Establish the question or problem.
   ↓
Background: What the reader needs to know to follow the argument.
   ↓
Setup: Frame the specific angle this piece takes.
   ↓
Body sections (each): Claim → evidence → interpretation → transition
   ↓
Climax: The central insight, fully supported by preceding sections.
   ↓
Implications: What this means for the reader's work or thinking.
   ↓
Closing: Return to the opening question. Show how it has been answered.
```

## Transition Patterns

Transitions between prose and figures are the connective tissue of an explanation. Poor transitions cause the reader to lose the thread.

### Prose → Figure

Set up what the reader is about to see. Prime their attention for the relevant detail.

**Good patterns:**
- "To see why [claim], look at [what the figure shows]."
- "Here is [concept] in action. [Brief instruction — drag, observe, compare]."
- "The figure below shows [exactly what it shows]. Notice [the specific thing to pay attention to]."
- "What happens when [parameter] changes? Try it:"

**Bad patterns:**
- "Here is a figure:" (no setup, no attention priming)
- "As we can see in Figure 3..." (refers to figure before the reader has seen it)
- "The following visualization illustrates the concept we have been discussing." (vague, no specificity)

### Figure → Prose (Consolidation)

After a figure, consolidate what it demonstrated. Restate the insight in words. This is where understanding solidifies.

**Good patterns:**
- "What you just saw is [restate the mechanism in words]. This means [implication]."
- "Notice how [specific observation from figure]. This is because [explanation]."
- "The key takeaway: [one sentence summary of what the figure proved]."
- "When you [interaction], [result] happened. This is [concept name] in action."

**Bad patterns:**
- Moving immediately to the next topic without consolidation
- Restating the figure's content without adding interpretation
- "As the figure shows..." (the reader just saw it — add something new)

### Section → Section

Bridge paragraphs connect ideas across sections. They look backwards and forwards simultaneously.

**Good patterns:**
- "Now that we understand [previous concept], we can tackle [next concept]."
- "[Previous concept] explains the *what*. But *why* does it happen? That requires [next concept]."
- "So far, we have assumed [simplification]. Let us relax that assumption."
- "This works well for [simple case]. But what about [harder case]?"

## Opening Hooks

The first 2-3 sentences determine whether the reader continues. Match the hook to the content mode.

### For Tutorials

Appeal to capability — what will the reader be able to do?

- "By the end of this tutorial, you will understand why [surprising fact] and be able to [practical skill]."
- "Every time you [common action], [concept] is happening behind the scenes. Here is how it works."
- "[Concept] sounds complicated. It is not. It is just [simple reframing]."

### For Reports / Analysis

Lead with the finding — do not bury it.

- "[Surprising conclusion]. Here is the evidence."
- "We analyzed [scope] and found [key result]. This has implications for [relevant area]."
- "The conventional wisdom about [topic] is wrong. [Data point] proves it."

### For Presentations

First slide hook — one idea, maximum impact.

- A single question the audience does not yet know the answer to
- A surprising statistic or fact
- A brief story that illustrates the problem

Do NOT open with: the agenda, your name, "Today I will talk about...", or a table of contents.

### For Papers / Articles

Establish the stakes — why does this matter?

- Start with a concrete scenario, then zoom out to the general principle
- Pose the central question directly
- Open with a counterintuitive claim, then promise to justify it

## Progressive Vocabulary

Match language complexity to the reader's growing understanding. This is not about dumbing down — it is about respecting the sequence of learning.

**Early in the piece:**
- Use plain language and concrete examples
- Define terms on first use (but do not make definitions the focus — weave them into the narrative)
- Prefer analogy over abstraction
- Short sentences. Simple structure.

**Middle of the piece:**
- Begin using the terminology defined earlier
- Introduce precision — replace analogies with correct terms
- Sentences can grow longer as the reader builds context
- Start connecting concepts: "This is related to [earlier concept] because..."

**Late in the piece:**
- Use technical vocabulary fluently — the reader has earned it
- Abstract freely — the reader has the concrete foundation
- Connect to external concepts and further reading
- The reader is now a peer, not a student

## Presentation-Specific Prose

Slides demand a different prose style than long-form writing. Every word must earn its place.

### Slide text rules

- **One idea per slide.** If you have two ideas, make two slides.
- **Headline as sentence.** The slide heading should be a complete thought, not a topic label. "Cache invalidation causes 60% of production incidents" not "Cache Invalidation."
- **Bullet points are not sentences.** Keep bullets to 1-2 lines. No periods. No sub-bullets deeper than one level.
- **Speaker notes carry the detail.** The slide is the headline; the speaker (or reader's inner voice) provides the context. If the slide can only be understood with speaker notes, that is fine for a live talk. For async decks, add one sentence of context below the heading.

### Slide type prose patterns

| Slide Type | Prose Pattern |
|------------|---------------|
| Title | [Topic]: [Promise or question] |
| Hook | [Surprising fact or question] |
| Context | [Minimum viable background in 3-5 bullets] |
| Evidence | [Heading states the claim] + [Figure/data proves it] |
| Insight | [The one takeaway in large text] + [One sentence elaboration] |
| Comparison | [Two options side by side] + [Why one wins or when each applies] |
| Section divider | [Section name] + [One sentence preview] |
| Closing | [Call to action or memorable restatement] |

### Content density limits

Internalize these limits. If content exceeds them, split into multiple slides. Never reduce font size or remove spacing to fit.

| Slide Type | Maximum Content |
|------------|-----------------|
| Title slide | 1 heading + 1 subtitle + optional tagline |
| Content slide | 1 heading + 4-6 bullet points OR 1 heading + 2 paragraphs |
| Feature grid | 1 heading + 6 cards maximum (2x3 or 3x2 grid) |
| Code slide | 1 heading + 8-10 lines of code maximum |
| Quote slide | 1 quote (max 3 lines) + attribution |
| Image slide | 1 heading + 1 image (max 60vh height) |
| Hero image slide | Full-bleed background image + 1 heading + 1 subtitle (overlaid) |

### Structuring a deck narrative

Presentations are not documents read aloud. They are a sequence of moments. Design for rhythm:

- **Vary content density:** Heavy slide → light slide → heavy slide
- **Use visual breaks:** Section dividers every 4-6 content slides
- **Build to a peak:** The most important insight should come at roughly 60-70% through the deck
- **End with energy:** The closing slide should leave the audience with a clear next step or a resonant idea. Do not end with "Questions?" — end with your message.
