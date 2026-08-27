# Visual rules

Applies to HTML deliverables, Artifacts, decks, and anything else that renders.
Most de-slop guidance stops at prose. In practice over-decoration destroys more
documents than bad sentences do, because decoration is how a reader is told what
matters, and uniform decoration tells them nothing.

## 1. The decoration budget

The failure is not ugliness. It is that every noun gets a component: a pill, a
chip, a badge, a card, a coloured top-rail, a hatched background, an uppercase
mono eyebrow, a `::after` tag. The page ends up with 600 decorated elements and
180 CSS selectors, and there is no visual difference between the load-bearing
sentence and a passing aside.

Budgets, per 1000 words of body copy:

| Signal | Budget | Why |
| --- | --- | --- |
| Distinct CSS selectors | < 60 total for a document | Each one is a concept the reader decodes |
| Decorated elements | < 40 per 1000 words | Emphasis only works if it is scarce |
| Meaning colours | ≤ 3 + neutrals | Beyond that it is a legend, not a design |
| Font families | 2 | One text face, one mono. Three only with a reason |

**The default element is a paragraph, a list, or a table.** Reach for a
component only when the plain form actually fails to carry the information.
Before adding a card, ask what the card does that a `<h3>` and a paragraph do
not. Usually nothing.

## 2. Colour

Pick a neutral scale with a slight hue bias toward the accent, so it reads as
chosen rather than inherited. Then at most three colours that mean something:

- an accent (links, focus, the one thing under discussion)
- an additive/positive
- a removed/negative

Semantic state colour (good / warning / critical) is separate from the accent
and does not count against it, but only use it where state actually exists.

Do not build a per-subsystem palette. A seven-colour scheme where each service
gets a hue forces the reader to memorise a mapping in order to read prose. Colour
by subsystem belongs inside a diagram that carries its own legend, and even
there, four is plenty.

## 3. Typography

Two roles minimum: a text face and a mono face. Set a scale and stay on it.

Avoid the current defaults, which read as generated because they are:

- Inter or Space Grotesk as the "safe" sans
- warm cream `#F4F1EA` + serif display + terracotta accent
- near-black with a lone acid-green or vermilion pop
- purple-to-blue gradient hero on white
- broadsheet hairline rules with dense columns

Pick something the subject justifies. A technical reference document is well
served by a family designed for it (IBM Plex Sans + Plex Mono, Source Sans +
Source Code, Roboto + Roboto Mono). A pairing from one superfamily is a
deliberate restrained choice, not a lazy one, when the subject is a spec.

Other rules:

- Body text 15–17px, line-height 1.5–1.65, measure 65–80 characters.
- Running text does not go below 13px. Uppercase mono micro-labels at 10px are a
  slop marker and are also unreadable.
- Give headings `text-wrap: balance`.
- `font-variant-numeric: tabular-nums` anywhere digits line up.
- Serif body for a reference document is usually the wrong call. Serif is for
  reading linearly; specs are scanned.

## 4. Layout

- Single column for documents. Sticky TOC on wide screens if there are more than
  six sections.
- Separate content with whitespace and hairline rules. Not with boxes.
- Wide content (tables, code, diagrams) gets `overflow-x: auto` on its own
  container so the body never scrolls sideways.
- Lay out sibling groups with flex/grid `gap`, not per-element margins.
- Watch selector specificity. Type-based and element-based selectors fighting
  over the same padding is how spacing silently breaks.

## 5. Themes

If the surface renders in a viewer's theme (Artifacts do), there are three
states, not two: explicit light, explicit dark, and unstamped system default.

- Define the complete light palette on bare `:root`.
- Redefine only the tokens under
  `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }`.
- Redefine them again under `:root[data-theme="dark"]`.
- Style components through tokens, never with a colour whose only definition
  sits inside a media or `[data-theme]` block.
- Give `body` an explicit token background. A transparent body borrows the host's
  ground and breaks.

Before shipping, grep the stylesheet for any colour declared only inside a media
or `[data-theme]` block. That is the classic unreadable-in-one-theme bug.

## 6. Diagrams

A diagram earns its place when it lets a reader see a mechanism they would
otherwise assemble from prose: where data flows, which components talk, what
changes between two options, what state something moves through.

- **Draw the mechanism, not the name.** A box labelled "cache" says less than
  the prose. The path through it, the two stores it sits between, and the arrow
  that disappears when you remove it say what words cannot.
- **Comparing options? Draw the difference.** Before and after, side by side.
  Separate labelled boxes with nothing connecting them is a restated list.
- **Label the arrows.** `writes`, `invalidates`, `polls every 30s`. An unlabelled
  arrow means "related somehow".
- **One figure, one claim.** Wrap in `<figure>`, give it a `<figcaption>` stating
  the claim, and put the same claim in `role="img"` + `aria-label`.
- Size by `viewBox`; let CSS scale it. Text 11–13px at drawn scale.
- Align to a grid. Even gaps and shared baselines are most of what makes a hand
  diagram read as deliberate.
- **Theme the strokes.** Use `currentColor` for structure and CSS classes bound
  to tokens for the one or two meaning colours. A literal hex inside an SVG is
  invisible in one of the two themes. This is the most common bug in
  hand-authored artifact diagrams.
- Prefer static SVG over a runtime layout engine. A script that measures DOM
  boxes and draws bezier edges will drift, reflow, and break at widths you did
  not test.

If a sentence says it faster, write the sentence.

## 7. Decks specifically

- One claim per slide. The title states the claim; the body supports it.
- No slide is a bulleted restatement of the title.
- Build sequences only where the order carries meaning.
- The same colour and decoration budgets apply, harder — a slide has less room
  to absorb noise.

## 8. Naming the deliverable

For an Artifact or any page with a title: a short noun phrase, two to four
words, specific enough to pick out of a list of twenty. Not a category label
("Technical Documentation"), not a name plus an appended explainer after a dash
or colon. The explanation goes in the description field.
