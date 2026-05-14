# Component vocabulary

Each component is a JS function registered under a name. The shell HTML invokes one by writing a placeholder:

```html
<div data-component="<name>"
     data-source="<file.md>#<section-slug>"
     data-<option>="..."></div>
```

At runtime, `viz.js` fetches the markdown, parses it, locates the section by slug, picks the first table in that section, and renders annotatable HTML into the placeholder. Each rendered row/card gets `class="block"` plus auto-generated `data-anno-id` / `data-anno-label` so the annotation gutter attaches without manual markup.

**Section slug.** Lowercase, alphanumerics and hyphens only. GitHub-style: `## Open Questions` → `#open-questions`, `## Manta v0 Minimum Vertical Slice` → `#manta-v0-minimum-vertical-slice`.

**Source file path.** Resolved relative to the viz HTML page (i.e. `../spec.md` if the viz lives one directory below the spec). For sibling layouts (`<spec-dir>/spec.md` and `<spec-dir>/viz/spec.html`), use `../spec.md`.

---

## `glossary-table`

Term → definition table.

| Option | Default | Effect |
|---|---|---|
| (none) | — | Renders the first table at the slug as-is, with one annotatable row per term. |

**Expected source shape:** any 2+ column table where the first column is the term name (often bolded with `**`).

```html
<div data-component="glossary-table" data-source="../spec.md#glossary"></div>
```

---

## `card-grid`

Generic card grid. Each table row becomes one card.

| Option | Default | Effect |
|---|---|---|
| `data-card-type` | `""` | CSS class applied for color/style — one of `goal`, `nongoal`, `principle`, `constraint`, `risk`, `question`, `dep`, `policy`, `spike`, `req`, `deferred`. |
| `data-cols` | `"2"` | Grid columns: `2`, `3`, or `4`. |
| `data-body-col` | `"2"` | Column index used as the card body. Columns after this become `card-meta` key/value pairs. Special value `"none"` skips the body entirely — col 1 stays as the title, columns 2+ become `card-meta`. Use when the source table is `ID \| Title \| Verification` (or similar) and there's no separate body column. |

**Expected source shape:** `| ID | Title | Body | …meta cols (optional) |`. The first column is the card-id pill (e.g. `G1`, `D3`, `RP2`), the second is the card title, the third is the body. Remaining columns render as labeled meta rows under the body using the column headers as labels.

```html
<div data-component="card-grid"
     data-source="../spec.md#goals"
     data-card-type="goal"
     data-cols="2"></div>
```

---

## `req-grid`

Requirements grid with Given / When / Then layout. Falls back to `card-grid` behavior if the source table has fewer than 5 columns.

| Option | Default | Effect |
|---|---|---|
| `data-cols` | `"2"` | Grid columns. |

**Expected source shape:** `| ID | Requirement | Given | When | Then | Verification (optional) |`.

```html
<div data-component="req-grid"
     data-source="../spec.md#requirements"
     data-cols="2"></div>
```

---

## `shape-table`

Plain annotatable table. Use for "Field / Required / Purpose" or similar field-shape tables where the first column is a stable identifier.

| Option | Default | Effect |
|---|---|---|
| `data-id-prefix` | section slug | Prefix for `data-anno-id`s (e.g. `mv` → `mv-id`, `mv-version`). |

**Expected source shape:** any table; first column is treated as the row identifier for anno-id generation.

```html
<div data-component="shape-table"
     data-source="../design.md#modelversion-shape"
     data-id-prefix="mv"></div>
```

**Aliases:** `policy-table`, `crosswalk` — same renderer, different semantic intent. Use whichever name best describes what the section represents.

---

## `tier-stack`

Vertical stack of tiered rows with name / fields / behavior columns. Each row gets a colored left border (5 tier colors cycle for rows 1–5+).

| Option | Default | Effect |
|---|---|---|
| (none) | — | Always renders the first table; row order = tier order. |

**Expected source shape:** `| Tier | Field examples | Behavior |`.

```html
<div data-component="tier-stack" data-source="../design.md#compatibility-metadata-tiers"></div>
```

---

## `state-list`

Grid of state cards with transitions.

**Expected source shape:** `| State | Meaning | Allowed next states |`.

```html
<div data-component="state-list" data-source="../design.md#servingendpoint-state-machine"></div>
```

---

## `matrix`

Matrix table with auto-colored cells. Cell text drives coloring: `✓ / yes / allowed` → green; `✗ / no / rejected` → red; `? / maybe / conditional / future` → amber; empty / `- / — / n/a` → muted.

```html
<div data-component="matrix" data-source="../design.md#authority-matrix"></div>
```

---

## `keyvalue-card`

Renders a section whose body is a 2-column Field/Value table as a single card. The section title becomes the card title; each table row becomes a labeled paragraph (`<strong>Field.</strong> Value`) inside the card body. The last row is automatically pulled out as `card-meta` if its key matches `blocks` / `verify` / `verification` / `next`.

| Option | Default | Effect |
|---|---|---|
| `data-card-type` | `"spike"` | CSS class for color (typically `spike`, but any `card-grid` type works). |
| `data-id` | `""` | If set, becomes the card's `id=` (for direct anchoring) and the `card-id` pill. |

**Expected source shape:** a section whose first content is a 2-column `\| Field \| Value \|` table. Useful for sections like `## S1. ONets Model Metadata Extraction` (a Goal/Inputs/Procedure/Acceptance/Blocks shape).

```html
<div data-component="keyvalue-card"
     data-source="../spikes.md#s1-onets-model-metadata-extraction"
     data-id="S1"
     data-card-type="spike"></div>
```

If the section's first table has more or fewer than 2 columns, the renderer falls back to rendering the full table inside the card body.

---

## `details-block`

Collapsed "future / deferred" callout. Renders a summary card at the top and a `<details>` element below with the remaining paragraphs, tables, and code blocks in the section.

| Option | Default | Effect |
|---|---|---|
| `data-label` | `"Future"` | Label shown on the summary card-id pill. |

```html
<div data-component="details-block"
     data-source="../design.md#future-external-hosted-endpoint-handling"
     data-label="Future"></div>
```

---

## `diagram-inline`

Marker for hand-authored inline SVG. The component itself doesn't render anything — it just adds the `diagram-wrap` class and wires the fullscreen-on-click handler. The shell author writes the SVG directly inside the placeholder.

```html
<div data-component="diagram-inline" class="diagram-wrap">
  <svg viewBox="0 0 460 280" xmlns="http://www.w3.org/2000/svg" aria-label="...">
    <!-- hand-authored SVG -->
  </svg>
  <div class="diagram-caption">Caption text.</div>
</div>
```

---

## Hand-authored HTML islands

For sections that don't fit any component (the page hero, an inline JSON example with notes, a custom callout), write the HTML directly and add `class="block" data-anno-id="<page>:<slug>" data-anno-label="<label>"` to each block you want annotatable.

The annotation system picks up any `.block[data-anno-id]` on the page, regardless of how it got there.

---

## Adding a new component

1. Write a renderer in `viz.js`:
   ```js
   function renderMyComponent(el, md, anchor, pSlug) {
     const t = firstTable(md, anchor);
     if (!t) return renderEmpty(el, `No table at #${anchor}`);
     const { table } = t;
     // … build HTML with class="block" data-anno-id="..." on each row …
     el.innerHTML = html;
   }
   ```
2. Register it: `COMPONENT_REGISTRY["my-component"] = renderMyComponent;`.
3. Add CSS in `viz.css` if needed.
4. Document the option set in this file.

Renderers must produce DOM with the annotation contract — `class="block"` + `data-anno-id` + `data-anno-label` — on each annotatable element. The init flow attaches gutters and the side pane based on those markers; the renderer doesn't need to add the gutter itself.
