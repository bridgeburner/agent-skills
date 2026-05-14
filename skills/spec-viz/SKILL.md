---
name: spec-viz
description: >-
  Build an interactive, annotatable browser visualization of a multi-file markdown
  spec — product specs, design docs, RFCs, architecture sketches, or any directory
  of related `.md` files with shared vocabulary. Produces a static HTML viz with
  sidebar nav, hoverable cards/rows, per-block 👍/👎/❓/💬 reactions and inline
  notes, edit mode, light/dark theme, and markdown export of all annotations.
  A runtime renderer parses the `.md` source at page load, and the agent picks
  from a vocabulary of pre-built components (card grids, requirement grids with
  Given/When/Then, shape tables, tier stacks, state lists, matrices, deferred
  callouts, hand-authored SVG diagrams) for each spec section. Use this skill
  whenever the user mentions "visualize this spec", "build a viz for these
  designs/RFCs/specs", "make these docs annotatable / clickable / browseable /
  reviewable", "I want to leave reactions on each requirement", "interactive
  design doc", "spec walkthrough I can comment on", or has a directory of
  related markdown files they want to navigate and react to per-block — even
  if they don't use the word "viz". Also use whenever the user has been working
  on a multi-file spec (spec.md / design.md / spikes.md / RFC.md pattern) and
  wants a shareable browser view.
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

```bash
cp ~/.claude/skills/spec-viz/templates/spec-shell.html <spec-dir>/viz/<page>.html
```

For each page:

1. Set `<title>`, the topbar brand, the nav links, and `<body data-viz-page="..." data-viz-storage-key="...">`. The page slug namespaces `data-anno-id`s — typically the source filename without extension. The storage key namespaces localStorage so distinct specs on the same origin don't collide.
2. Write the sidebar anchors matching the H2 sections you plan to render.
3. In `<main>`, place one `<div data-component="…" data-source="<file>.md#<slug>">` per H2 section, in source order. Use hand-authored HTML for the page lede, the hero block, and any bespoke diagrams.

**Path resolution.** `data-source` paths are resolved relative to the HTML page. With the default layout (`<spec-dir>/spec.md` and `<spec-dir>/viz/spec.html`), use `../spec.md`. If you put the viz directory elsewhere, adjust accordingly.

**Slug check.** Before declaring done, sanity-check each placeholder's slug against the source: `grep -E "^##\s" <spec-dir>/*.md | sort` shows every H2 heading. The slug is the heading lowercased with non-alphanumerics replaced by hyphens (GitHub style). `## Open Questions` → `#open-questions`.

The shell should typically be 60–120 lines per page. If yours is longer, you're likely under-using components — look for opportunities to drop a multi-table section into a single placeholder.

### Step 5 — Verify

Start a local HTTP server and load each page. Pick a port that's free (`ss -tln | grep :87` to check; 8765 is the default; use 8766/8767 if busy):

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

## See also

- [references/components.md](references/components.md) — Full component vocabulary with options and source-shape expectations.
- [references/annotation-contract.md](references/annotation-contract.md) — Data-attribute contract for annotatable blocks.
- [references/authoring-walkthrough.md](references/authoring-walkthrough.md) — Worked example: turning a 3-file spec into a viz.
- [templates/spec-shell.html](templates/spec-shell.html) — Starter HTML shell with all the chrome wired up.

The v0 produces static annotation UI. Interactive controls (sliders, toggles that re-render dependent components reactively) and cross-doc comment syncing are natural follow-ups that layer on top of the existing component model. Don't implement them speculatively; propose the design when the user asks.
