---
name: spec-viz
description: >-
  Build an interactive, annotatable visualization of a multi-file markdown spec
  (product specs, design docs, RFCs, architecture sketches). Produces a static
  HTML viz with sidebar nav, hoverable cards/rows, per-block like/dislike/question
  reactions and inline notes, an edit mode, dark/light theme, and export-to-markdown.
  The agent picks from a vocabulary of pre-built components for each spec section
  and can hand-author HTML islands for bespoke layouts. Invoke when the user asks
  to "visualize this spec", "build a viz for these design docs", "make these RFCs
  browseable", "create an annotatable design doc viewer", or wants per-block
  reactions/notes/annotations on a spec.
---

# spec-viz — annotatable spec visualization

Produce a browseable, annotatable static-HTML viz of a multi-file markdown spec. The viz reads the source `.md` files at runtime in the browser, renders structured components (card grids, shape tables, tier stacks, etc.), and overlays a uniform annotation UI so the user can leave reactions and notes on every block.

The output is a self-contained directory of static HTML + CSS + JS files that can be served with any web server (or opened over `file://` if the markdown files are colocated and `fetch()` works in that context — use a local server for reliability).

---

## When to use

Trigger on:

- "Visualize this spec / RFC / design doc."
- "Make these docs annotatable / clickable / browseable."
- "Build a viz I can react to per requirement / per goal / per principle."
- "Give me sliders/levers/controls for this design." (future-facing; v0 produces static annotation UI, see [Future-Facing Capabilities](#future-facing-capabilities).)
- The user has a directory of related `.md` files (spec, design, spikes, README, etc.) that share vocabulary.

Do **not** use when:

- The user just wants Markdown rendered (use a markdown viewer).
- The user wants a single-page interactive widget (use `pixi-animate` or `explainer`).
- The spec is one file with no sub-pages (consider direct HTML or `explainer`).

---

## Output contract

A `viz/` directory next to the source markdown files, containing:

```
<spec-dir>/
  spec.md, design.md, …          # source markdown (canonical, untouched)
  viz/
    index.html                   # overview/hero page
    spec.html, design.html, …    # one page per source .md (or merged)
    viz.css                      # styles, copied from this skill
    viz.js                       # renderer + annotator, copied from this skill
```

Each HTML page is a thin shell (~60–120 lines) containing:

1. A `<head>` linking `viz.css`.
2. A topbar with brand + nav + control buttons (theme/edit/export/reset).
3. A sidebar with section anchors.
4. A `<main>` with `<div data-component="…" data-source="spec.md#section-slug">` placeholders, interleaved with any hand-authored HTML islands (especially for bespoke SVG diagrams).
5. An annotations side pane.
6. A `<script src="viz.js"></script>` tag.

`viz.js` fetches each referenced `.md`, parses it once, then renders each placeholder into annotatable HTML. After rendering, it attaches the annotation gutter and side pane.

---

## Workflow

### Step 1 — Inventory the source

Read every `.md` file in the spec directory. For each `## heading` section, identify:

- Does it have a table? What columns? How many rows?
- Is it descriptive prose (a lede or rationale paragraph)?
- Is there a code block (JSON schema example, etc.)?
- Are there bespoke needs (a hand-drawn SVG diagram, a callout)?

Sketch a mapping: section → component. Use [references/components.md](references/components.md) for the vocabulary.

### Step 2 — Choose components per section

The component vocabulary covers ~95% of spec patterns:

| Component | Use when the section contains… |
|---|---|
| `glossary-table` | Term / Definition rows. |
| `card-grid` | Items with ID + Title + Body (+ optional Meta). Pick `data-card-type` based on color semantics. |
| `req-grid` | Requirements with Given / When / Then / (Verification) columns. |
| `shape-table` | Field / Required / Purpose (and similar) shape tables. |
| `tier-stack` | Tiered semantics with a Field-Examples / Behavior split (e.g. compatibility tiers). |
| `state-list` | States + transitions. |
| `policy-table` | Policy / Behavior / Failure rows. |
| `matrix` | 2D grid with allowed/rejected/conditional cells. |
| `crosswalk` | Multi-column linkage (Q→Spike, requirement→test, etc.). |
| `details-block` | "Future" or "Deferred" callouts with collapsed detail. |
| `diagram-inline` | Placeholder for hand-authored SVG (skill provides the wrapper, you write the SVG). |

When a section needs something genuinely bespoke (a non-standard layout, a custom visualization, the page hero), **drop into hand-authored HTML**. The annotation system attaches to anything with `class="block" data-anno-id="page:slug" data-anno-label="…"` regardless of whether it was rendered by a component or hand-written.

See [references/components.md](references/components.md) for each component's source-shape expectations and configurable options.

### Step 3 — Vendor the skill assets

Copy `scripts/viz.css` and `scripts/viz.js` into the viz directory:

```bash
mkdir -p <spec-dir>/viz
cp ~/.claude/skills/spec-viz/scripts/viz.css <spec-dir>/viz/
cp ~/.claude/skills/spec-viz/scripts/viz.js  <spec-dir>/viz/
```

(Adjust the source path if the skill is installed elsewhere — `~/.claude/skills/spec-viz/` is the default symlink target. Use `find ~/.claude/skills ~/.codex/skills -maxdepth 2 -name spec-viz -type d 2>/dev/null` to locate it.)

### Step 4 — Author the shell pages

Start from [templates/spec-shell.html](templates/spec-shell.html). For each source `.md`:

1. Copy the template to `<spec-dir>/viz/<page>.html`.
2. Set `<title>`, the topbar brand, the nav links, and `<body data-viz-page="...">` (the page slug is used to namespace `data-anno-id`s — typically the source filename minus extension).
3. Write the sidebar anchors matching the H2 sections you plan to render.
4. In `<main>`, place one `<div data-component="…" data-source="<file>.md#<slug>">` per H2 section, in source order. Use hand-authored HTML for the page lede, the hero block, and any bespoke diagrams.

The shell should typically be 60–120 lines per page. If it gets longer than that, you're likely under-using components.

### Step 5 — Verify

Start a local HTTP server and load each page:

```bash
cd <spec-dir>/viz && python3 -m http.server 8765
```

Open `http://localhost:8765/` in a browser and check:

- Every section renders (no empty placeholders).
- Hovering a card/row shows the 👍 👎 ❓ 💬 gutter.
- Clicking a reaction persists across reload.
- Theme toggle, edit mode, export all work.
- Dark/light both look right.

Hit the JS console for errors. Common failures:

- **Empty section** — the slug in `data-source` doesn't match the H2 (check `slugify` rules: lowercase, hyphens, alphanumeric only).
- **Wrong column mapping** — the source table doesn't have the columns the component expects (see [references/components.md](references/components.md)).
- **No annotation gutter** — the rendered HTML is missing `class="block"` or `data-anno-id` (this should be auto-generated by components; check for component-renderer bugs).

### Step 6 — Iterate

When the user wants changes:

- **Re-word a card** → edit the source `.md`, refresh the browser.
- **Reorder sections** → reorder the placeholders in the shell HTML.
- **Change card layout** → swap `data-component` or adjust `data-cols` / `data-card-type`.
- **Add a bespoke section** → drop in hand-authored HTML with `class="block"` markers.

**Never edit the rendered HTML in the browser as ground truth.** Source of truth is the `.md`. The viz is a view.

---

## Annotation contract

Anything with these data attributes becomes annotatable:

```html
<div class="block"
     data-anno-id="<page-slug>:<item-id>"
     data-anno-label="<short human label shown in the side pane>">
  …content…
</div>
```

- `<page-slug>` should match the page's `data-viz-page`.
- `<item-id>` is typically the ID column from the source table (R1, G1, D1, etc.) or a slug derived from the title.
- `data-anno-label` should be unique and human-readable; it's shown in the side pane when the block is annotated.

For editable text spans (used in edit mode), add `class="editable" data-edit-id="<unique>"` inside a block.

Component renderers generate these attributes automatically; you only need them when writing HTML islands by hand.

Full details: [references/annotation-contract.md](references/annotation-contract.md).

---

## Storage and isolation

Annotations are stored in `localStorage` under a key set on `<body data-viz-storage-key="…">`. Use a unique key per spec so different viz instances on the same origin don't collide (e.g. `manta-viz:state`, `niobe-viz:state`).

---

## Future-facing capabilities

The v0 produces static annotation UI. Two natural follow-ups, **not implemented yet**:

1. **Interactive controls/levers** — A spec section can declare `<div data-component="control" data-target="opt-batch-size" data-type="slider" data-min="1" data-max="256">` and the renderer would produce a control that re-renders dependent components reactively. Useful for "see the spec under different option settings."

2. **Cross-doc commenting** — Annotations could sync to a Git-backed store via a small server so multiple reviewers can see each other's notes.

Both layer on top of the existing component model without breaking changes. If the user asks for either, propose the design before implementing.

---

## See also

- [references/components.md](references/components.md) — Full component vocabulary with options and source-shape expectations.
- [references/annotation-contract.md](references/annotation-contract.md) — Data-attribute contract for annotatable blocks.
- [references/authoring-walkthrough.md](references/authoring-walkthrough.md) — Worked example: turning a 3-file spec into a viz.
- [templates/spec-shell.html](templates/spec-shell.html) — Starter HTML shell with all the chrome wired up.
