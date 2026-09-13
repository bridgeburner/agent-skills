# Visual guidance

Use this for HTML artifacts, decks, diagrams, and other rendered deliverables.
Visual design should help a reader see the claim and its relationships. It
should not turn every noun into a component.

## Hierarchy and layout

- Let paragraphs, lists, tables, and whitespace carry ordinary information.
- Add a card, badge, rail, or other component only when it makes a distinction
  that plain content cannot.
- Keep a small, coherent type system. Use a readable text face and a distinct
  monospaced face only where code or aligned data needs it.
- Use a single column for documents unless a wider layout clearly serves a
  table or diagram. Give wide content its own horizontal scroll area.
- Use whitespace and simple rules to separate ideas. Avoid boxes around every
  paragraph.

## Color and themes

Choose a neutral base and a small set of semantic colors. A reader should be
able to understand what a color means without memorizing a palette for every
subsystem. Keep emphasis scarce enough that it still signals priority.

Define the light palette on the base selector, then override tokens for dark
themes. Give the page an explicit body background and avoid literal colors in
components that need to work in both themes.

## Diagrams

Draw a mechanism, flow, state change, or comparison that prose would make harder
to see. A box labelled “cache” is less useful than the stores, paths, and
invalidations around it. Label relationships such as `writes`, `reads`, or
`polls`.

Give each figure one claim, a caption, and an accessible label. Size SVGs with a
`viewBox`, align related elements, use theme tokens or `currentColor`, and test
both light and dark presentation. Prefer a static diagram when a runtime layout
engine adds failure modes without adding information.

## Decks

Put one claim in each slide title and use the body to support it. Build a
sequence only when order carries meaning. Apply the same restraint to color,
components, and decoration; slides have little room for visual noise.
