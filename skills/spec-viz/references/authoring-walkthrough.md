# Authoring walkthrough

Worked example: turning a three-file spec into a viz.

## Setup

Assume this layout:

```
specs/
  my-feature/
    spec.md       # goals, requirements, constraints, open questions
    design.md     # principles, resource model, shapes, risks
    spikes.md     # spike list
    README.md     # overview, doc map
```

## Step 1 — Inventory each `.md`

Open each file and list the `##` sections. For each, decide:

- **Glossary** → `glossary-table`
- **Goals / Non-goals / Principles / Constraints / Open questions / Risks / Dependencies** → `card-grid` with an appropriate `data-card-type`
- **Requirements** (with Given/When/Then columns) → `req-grid`
- **Shape tables** (Model shape, ServingEndpoint shape, etc.) → `shape-table`
- **Tiered metadata** → `tier-stack`
- **State machine** → `state-list`
- **Endpoint resolution policies** (Policy / Behavior / Failure) → `policy-table` (shape-table alias)
- **Authority/compatibility matrix** → `matrix`
- **Spike crosswalk** (Q → S → Unlock) → `crosswalk` (shape-table alias)
- **Future / deferred callouts** → `details-block`
- **Hero / page lede / hand-drawn SVG** → hand-authored HTML

If a section's table has unusual columns (e.g. a wide "JSON shape" with notes alongside), reach for hand-authored HTML instead of forcing a component fit.

## Step 2 — Create the viz directory

```bash
mkdir -p specs/my-feature/viz
cp ~/.claude/skills/spec-viz/scripts/viz.css specs/my-feature/viz/
cp ~/.claude/skills/spec-viz/scripts/viz.js  specs/my-feature/viz/
```

## Step 3 — Author `index.html`

Start from `templates/spec-shell.html`. Set:

- `<title>My Feature — overview</title>`
- `<body data-viz-page="index" data-viz-storage-key="my-feature-viz:state" data-viz-page-order="index,spec,design,spikes">`
- Topbar brand text + nav links matching the pages you plan to create.

The overview page typically has:

- A hero block (hand-authored, with the project name, a one-line lede, and maybe an inline SVG of the overall flow).
- A doc map (`card-grid` reading the README.md doc-map table, or hand-authored).
- A supported-loops grid (`card-grid` or hand-authored).
- Any scope / assumptions tables (`card-grid`).

For each section, drop a `<div data-component="…" data-source="…">…</div>` placeholder.

## Step 4 — Author `spec.html`

```html
<main class="main">
  <h1>My Feature — Product Spec</h1>
  <p class="lede">One-line description of the spec…</p>

  <h2 id="glossary">Glossary</h2>
  <div data-component="glossary-table" data-source="../spec.md#glossary"></div>

  <h2 id="goals">Goals</h2>
  <div data-component="card-grid" data-source="../spec.md#goals"
       data-card-type="goal" data-cols="2"></div>

  <h2 id="nongoals">Non-goals</h2>
  <div data-component="card-grid" data-source="../spec.md#non-goals"
       data-card-type="nongoal" data-cols="2"></div>

  <h2 id="requirements">Requirements</h2>
  <div data-component="req-grid" data-source="../spec.md#requirements"
       data-cols="2"></div>

  <h2 id="constraints">Constraints</h2>
  <div data-component="card-grid" data-source="../spec.md#constraints"
       data-card-type="constraint" data-cols="2"></div>

  <h2 id="questions">Open questions</h2>
  <div data-component="card-grid" data-source="../spec.md#open-questions"
       data-card-type="question" data-cols="2"></div>
</main>
```

## Step 5 — Author `design.html` and `spikes.html`

Same pattern, different `data-source` files and component choices. `design.html` typically has the most variety (cards, shape tables, tier stacks, state lists, matrices). `spikes.html` usually mixes a custom dependency diagram (hand-authored SVG) with `card-grid`s for the spike cards and a `shape-table` for the crosswalk.

## Step 6 — Serve and verify

```bash
cd specs/my-feature/viz
python3 -m http.server 8765
```

Open `http://localhost:8765/` and check each page:

- Every `<div data-component>` placeholder fills with content (no `No table at #…` messages).
- Hovering cards/rows reveals the 👍 👎 ❓ 💬 gutter.
- Reactions persist after reload.
- Theme toggle and edit mode work.
- Export produces a clean markdown grouping by page.

If a placeholder is empty, check the JS console for the warning. Common fixes:

- `#section-slug` doesn't match a real heading — check the slug rules (lowercase, hyphens, alphanumerics only).
- The first table at the section isn't the one you want — move the placeholder content or restructure the source.
- The column shape doesn't match the component — switch to `card-grid` or `shape-table` for a more permissive fit.

## Step 7 — Iterate

When the user updates a spec:

- **Reword content** → edit the `.md`, refresh the browser. Done.
- **Add a new requirement / goal / row** → edit the `.md`, refresh. The component re-renders the whole grid.
- **Add a new section** → add a new `<div data-component>` placeholder in the shell HTML, then refresh.
- **Change layout** (cols, card type) → adjust `data-*` attributes in the shell. No JS edits.
- **Add a bespoke section** → drop in hand-authored HTML between the placeholders.

Annotations survive content edits as long as the row IDs don't change. If you renumber requirements (e.g. delete R3, leaving R4–R10 unchanged), the annotations on the surviving requirements stay; annotations on the deleted R3 become orphaned (still in localStorage, but no element on the page to attach to).

If you want to start clean, click the ⌫ button in the topbar.
