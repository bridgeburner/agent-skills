# Annotation contract

The annotation overlay attaches to any element matching the contract below. Component renderers generate this markup automatically; you only need to write it by hand for HTML islands.

## Contract

```html
<element class="block"
         data-anno-id="<page-slug>:<item-id>"
         data-anno-label="<short human label>">
  …content…
</element>
```

- **`class="block"`** — required. Hooks the element to the gutter and side-pane wiring.
- **`data-anno-id`** — required. Globally unique key for this annotation. Format is `<page-slug>:<item-id>`. The page slug comes from `<body data-viz-page="…">`. The item-id is the source ID (e.g. `G1`, `R7`) or a slugified title.
- **`data-anno-label`** — required. Short human-readable label shown in the right-side annotations pane. Should be unique and descriptive (e.g. `G1 · question→answer`).

## Where it applies

The contract works on:

- **Block-level elements** — `<div>`, `<section>`, `<article>` — the gutter mounts as a child element absolutely positioned in the top-right.
- **Table rows** — `<tr>` — the gutter mounts inside the last `<td>` and shows on row hover.

If the rendered structure puts the `.block` inside a flow that prevents `position: relative` from anchoring the gutter (e.g. inside a flex/grid cell with `overflow: hidden`), wrap the block in a positioning context.

## Multi-page namespacing

All pages of one viz share localStorage. `data-anno-id` must therefore include the page slug to keep IDs unique across pages.

The export feature (top-bar Export button) groups annotations by page slug, so consistent prefixes matter for the exported `.md` to be navigable.

## Editable spans (edit mode)

Inside a `.block`, mark spans of text that should become editable when edit mode is toggled:

```html
<span class="editable" data-edit-id="<unique within block>">Some text</span>
```

- `data-edit-id` must be unique within the block. Edits are stored under `state.blocks[annoId].edits[editId]`.
- When the user toggles edit mode (✎ button in the topbar), the span becomes `contenteditable`; on blur, any change is persisted with `{ original, current }`.

## Storage namespace

Annotations are stored in `localStorage` under the key from `<body data-viz-storage-key="…">` (default: `spec-viz:state`).

Use a unique key per spec so multiple viz instances on the same origin don't share annotations.

```html
<body data-viz-page="spec"
      data-viz-storage-key="manta-viz:state"
      data-viz-page-order="index,spec,design,spikes">
```

- `data-viz-storage-key` — the localStorage key. Pick a name keyed on the spec/project.
- `data-viz-page-order` (optional) — comma-separated list of page slugs in the order they should appear in the exported markdown.

## What the gutter does

Hovering a `.block` reveals four buttons:

| Button | Effect |
|---|---|
| 👍 | Toggles `reactions.like`. The block gains an inset green border + tinted background. |
| 👎 | Toggles `reactions.dislike`. Red. |
| ❓ | Toggles `reactions.question`. Amber. |
| 💬 | Opens an inline note input. Persists `note` text on save. |

Likes and dislikes on the same block both light up combine to render as a question color (amber) — a visual cue that the block is contested.

## Side pane

The right-side `<aside class="annotations-pane" id="ann-pane">` lists every annotated block on the current page. Each card shows the block's `data-anno-label`, its reactions, edit count, and note. Clicking a card scrolls the block into view and briefly outlines it.

## Export format

The Export button in the topbar opens a modal with a markdown summary of all annotations across all pages, grouped by page slug. The export is purely informational — it doesn't modify the spec source.

```markdown
# Spec annotations — 2026-05-14

## spec.md

### G1 · question→answer  `spec:G1`
**👍 like**

> This is great — covers the e2e plumbing in one sentence.

### R7 · Model identity and aliasing  `spec:R7`
**❓ question**

> Where does the alias namespace live? Does R7 mean a future ModelAlias resource or just Model.name + ModelVersion.id?
```
