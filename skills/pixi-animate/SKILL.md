---
name: pixi-animate
description: >-
  Build PixiJS Canvas 2D visualizations as self-contained HTML. A pure rendering
  primitive — given a figure spec or ad-hoc request, produces interactive canvas
  figures with parameter sliders, simulations, direct manipulation, scroll-driven
  animations, and animated diagrams. Called by orchestrators (explainer, visual-explainer)
  to render figures; also usable standalone for any PixiJS canvas work. Invoke
  whenever a canvas figure needs to be implemented — whether that's a physics
  simulation, an algorithm step-through, a parameter sweep, an animated diagram,
  or any interactive widget backed by PixiJS. If the user says "animate this",
  "build a canvas widget", "add an interactive figure", "simulate X", "render
  this figure", or "add a PixiJS visualization", trigger this skill.
---

# PixiJS Canvas 2D Renderer

Build self-contained HTML visualizations using PixiJS Canvas 2D. This is a pure rendering skill — given a clear specification of what to visualize, it produces interactive, accessible, performant canvas figures.

## Core Philosophy

1. **PixiJS Canvas 2D Foundation** — All visualizations render via PixiJS with `forceCanvas: true`. One rendering engine, consistent API, no WebGL context limits across multiple figures on a single page.
2. **Self-Contained HTML** — Single HTML file, PixiJS loaded from CDN, everything else inline. The file must work when opened directly in a browser.
3. **Accessibility First** — Respect `prefers-reduced-motion`. Provide keyboard alternatives for every mouse interaction. Include screen-reader descriptions for every visualization.

---

## Output Contract

This skill produces one of two artifacts depending on context:

- **Standalone HTML file** (default for direct invocations): A complete, self-contained `.html` file with the shared block, prose shell, and all figure `<script>` IIFEs inline.
- **Figure snippet** (when called by an orchestrator): A self-contained IIFE written to `$WORKDIR/fig-N.js`. The orchestrator inserts this as a `<script>` tag after the corresponding `<figure>` in the assembled HTML.

When invoked by an orchestrator, it tells you which artifact to produce and where to write it. When invoked standalone, produce the complete HTML file.

---

## Externalized State

**Do not accumulate plans, outlines, or intermediate artifacts in the conversation.** Write them to temporary files and reference those files in subsequent steps. This keeps the context window clean and allows progressive refinement — read a file back, improve it, write it again.

At the start of the workflow, create a unique working directory:

```bash
WORKDIR=$(mktemp -d)
```

Store `$WORKDIR` and use it for all intermediate files: `fig-N.js` per visualization, plus the target HTML file. Each step reads the previous step's output, does its work, and writes the next. Never reproduce a plan inline when you can point to the file.

---

## Input Spec

When invoked by the `explainer` skill (or any orchestrator), expect a per-figure specification. The exact format depends on the orchestrator, but typically includes:

- **Figure element ID** — The HTML `id` for the `<figure>` element this visualization targets (e.g., `fig-gradient-descent`).
- **Concept and visual metaphor** — What the figure visualizes and the concrete visual metaphor to use (e.g., "gradient descent as a ball rolling downhill on a loss surface").
- **Interaction patterns** — Which patterns to implement from the [Pattern Index](#pattern-index) (e.g., "direct manipulation + parameter slider").
- **Animation patterns** — Which animation patterns to use (e.g., "trajectory tracing + continuous deformation").
- **Controls and parameter ranges** — What controls to provide, their labels, min/max/step values, and defaults (e.g., "learning rate slider: 0.001–1.0, step 0.001, default 0.1").
- **Aha moment** — What the figure should demonstrate; the single insight the viewer walks away with (e.g., "high learning rate overshoots, low learning rate crawls — there's a sweet spot").

If the spec format differs from the above, extract the equivalent information and proceed. The key inputs are: *what to visualize*, *how the user interacts*, *what they should understand*.

**Standalone usage:** When invoked directly without a formal spec, clarify the visualization goal before implementing. Ask: what concept? what interaction? what should the viewer walk away understanding?

---

## Workflow

### Step 1: Implement

**Write the file in chunks, not all at once.** Each chunk should be a complete, testable increment. Use the per-figure `<script>` architecture (see [templates/tutorial-page.html](templates/tutorial-page.html)) — each figure gets its own `<script>` tag with an IIFE, not one monolithic block.

The template has `CUSTOMIZE` markers indicating where to fill in content:
- `CUSTOMIZE: Topic` in `<title>` and `<h1>` — replace with the actual topic
- `CUSTOMIZE: prose introducing this figure` — replace with the figure's setup sentence
- `fig-NAME` — replace with the actual figure element ID
- Controls `<div>` — replace with actual HTML controls (or remove if no controls)
- `figcaption` text — replace with a useful description of what the figure shows

1. **Chunk 1**: Copy `templates/tutorial-page.html`. Replace all CUSTOMIZE sections (title, prose, figure placeholders). The shared block and base styles are ready to use.
2. **Chunk 2**: First visualization (simplest — establishes the visual language). Write as a self-contained IIFE in a `<script>` after its `<figure>`.
3. **Chunk 3+**: Each additional visualization as a separate `<script>` IIFE after its `<figure>`. Each can be written and tested independently.

**When to add GSAP:** Use GSAP for deterministic sequences the user scrubs through (timeline-based step-through, algorithm traces). Skip for real-time simulations. When needed, add CDN scripts after PixiJS:
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/PixiPlugin.min.js"></script>
```
See [references/pixijs-recipes.md](references/pixijs-recipes.md) section 7 for GSAP integration patterns.

**Parallelization with subagents:** For pages with 3+ figures, use subagents to implement visualizations in parallel. Write the HTML shell (Chunk 1) first, then spawn one subagent per figure. Each subagent receives:
- The figure's element ID and spec (as a file, not inline)
- A reference to `pixijs-recipes.md` and the relevant pattern reference file
- Instructions to write a self-contained IIFE to `$WORKDIR/fig-N.js`

After all subagents complete, insert each `fig-N.js` as a `<script>` tag after its corresponding `<figure>` in the HTML. This assembly is mechanical — each IIFE is self-contained, so no merging or deconflicting is needed. Do a coherence pass to verify: consistent use of `PALETTE` colors (no hardcoded hex values that don't match `PALETTE`), no duplicate global variable names leaking out of IIFEs, and that the `observeVisibility(sim)` call appears in every figure script.

Follow the [PixiJS Foundation](#pixijs-foundation) principles for every canvas. Load [references/pixijs-recipes.md](references/pixijs-recipes.md) for implementation patterns.

### Step 2: Refine

- Test every interaction (sliders at extremes, drag to edges, rapid input)
- Verify keyboard navigation works for all controls
- Check `prefers-reduced-motion` behavior (show final/static state, not blank canvas)
- Confirm off-screen canvases are paused (IntersectionObserver)
- Verify consistent color palette across all figures (everything references `PALETTE`)

---

## Pattern Index

Use this table to select the right pattern combination for the figure spec. Full implementation details are in the reference files — load them when implementing the chosen patterns.

### Interaction Patterns

| Pattern | Best For | Reference |
|---------|----------|-----------|
| Parameter slider | Continuous variables, cause-and-effect relationships, mathematical functions | [interaction-patterns.md §1](references/interaction-patterns.md) |
| Temporal scrubber | Fixed-sequence processes, algorithm traces, memory allocation steps | [interaction-patterns.md §2](references/interaction-patterns.md) |
| Step-through playback | Algorithms where each step must be understood before proceeding | [interaction-patterns.md §3](references/interaction-patterns.md) |
| Direct manipulation | Spatial reasoning, geometry, physics intuition | [interaction-patterns.md §4](references/interaction-patterns.md) |
| Scroll-driven progression | Data narratives, guided tours, linear explanations | [interaction-patterns.md §5](references/interaction-patterns.md) |
| Toggle/switch | Comparing representations, enabling/disabling visual layers | [interaction-patterns.md §6](references/interaction-patterns.md) |
| Hover-to-reveal | Dense visualizations, detail-on-demand | [interaction-patterns.md §7](references/interaction-patterns.md) |
| Linked multi-view | Multiple representations of the same system | [interaction-patterns.md §8](references/interaction-patterns.md) |
| Sandbox/playground | Open-ended exploration after guided learning | [interaction-patterns.md §9](references/interaction-patterns.md) |
| Prediction commitment | Counterintuitive results, "you draw it" engagement | [interaction-patterns.md §10](references/interaction-patterns.md) |

### Animation Patterns

| Pattern | Best For | Reference |
|---------|----------|-----------|
| Physics simulation | Emergent behavior, load balancing, system dynamics | [animation-patterns.md §1](references/animation-patterns.md) |
| Algorithmic expansion | BFS, flood fill, wavefront algorithms | [animation-patterns.md §2](references/animation-patterns.md) |
| Continuous deformation | Bezier curves, activation functions, morphing shapes | [animation-patterns.md §3](references/animation-patterns.md) |
| Flow/token animation | Request processing, data pipelines, filter chains | [animation-patterns.md §4](references/animation-patterns.md) |
| Progressive assembly | Architecture walkthroughs, layered system construction | [animation-patterns.md §5](references/animation-patterns.md) |
| Trajectory tracing | Gradient descent, vehicle routes, parameter exploration | [animation-patterns.md §6](references/animation-patterns.md) |
| Smooth state transitions | Data updates, sorting, chart reconfiguration | [animation-patterns.md §7](references/animation-patterns.md) |
| Color-field shifts | Heatmaps, scalar fields, convergence regions | [animation-patterns.md §8](references/animation-patterns.md) |
| Propagation waves | Radio signals, event propagation, network broadcasts | [animation-patterns.md §9](references/animation-patterns.md) |
| Synchronized multi-view | Dual representations, linked equation and graph | [animation-patterns.md §10](references/animation-patterns.md) |

---

## PixiJS Foundation

Every visualization must satisfy these constraints. Full recipes and boilerplate in [references/pixijs-recipes.md](references/pixijs-recipes.md).

- **CDN**: `pixi.js-legacy` v7.3.2 (Canvas renderer). Pin the version: `https://pixijs.download/v7.3.2/pixi-legacy.min.js`
- **`forceCanvas: true`** — no WebGL, avoids context limits with many figures on one page
- **`backgroundAlpha: 0`** — transparent, blends with page background
- **`autoStart: false`** — manual ticker control; start only when simulation is ready
- **IntersectionObserver** pauses off-screen tickers (critical for multi-figure pages)
- **`prefers-reduced-motion`** check before any animation; show final/static state as fallback — never a blank canvas
- **Native HTML controls** (`<input type="range">`, `<button>`, `<select>`) — never canvas-rendered; placed as siblings of or overlaid on the canvas (check z-index if layered over canvas)
- **`resizeTo: element`** + `ResizeObserver` for responsive layout; `autoDensity: true` for retina

---

## Cross-Cutting Principles

Six rules that apply to every visualization. Full descriptions with examples in [references/composition-patterns.md](references/composition-patterns.md) under "Cross-Cutting Principles".

1. **Gradient of Agency** — Guided first (play/observe), parameter tweaking second (sliders), sandbox last. Match the viewer's growing confidence — don't drop them into an unconstrained playground immediately.
2. **Immediacy** — Feedback within one frame (~16ms). Decouple heavy computation from rendering — show partial results instantly, refine async. Update on `input`, not `change`.
3. **Reversibility** — Every interaction undoable. Reset buttons on every figure. The viewer must feel safe exploring.
4. **Object Constancy** — Same entity keeps same color/position/shape across state changes. When sorting or transitioning, interpolate — don't redraw from scratch.
5. **Minimal Chrome** — Direct manipulation over control panels. Controls sit adjacent to the visual region they affect. The visualization IS the interface.
6. **Progressive Complexity** — Simple first. Controls appear as the viewer scrolls deeper or opts in via "Advanced" toggles.

---

## Reference Files

Load on demand — not all are needed for every visualization.

| File | Load When |
|------|-----------|
| [templates/tutorial-page.html](templates/tutorial-page.html) | Starting a new page (Chunk 1) — copy and replace CUSTOMIZE sections |
| [references/pixijs-recipes.md](references/pixijs-recipes.md) | Writing any PixiJS code (boilerplate, entity pattern, controls, GSAP, color utilities, physics) |
| [references/interaction-patterns.md](references/interaction-patterns.md) | Implementing user controls (sliders, drag, scrubbers, toggles) |
| [references/animation-patterns.md](references/animation-patterns.md) | Implementing motion, simulation, or transitions |
| [references/composition-patterns.md](references/composition-patterns.md) | Deciding how to structure prose + visualization on the page |

---

## Troubleshooting

**Laggy interactions:** Never create new `Graphics` objects every frame — reuse and call `.clear()` then redraw. Never debounce visual updates; if computation is expensive, run it async and show intermediate state immediately.

**Controls unresponsive:** HTML controls must be siblings of or overlaid on the canvas, not inside it. Check z-index if positioned over the canvas. Use `pointer-events: none` on the canvas container if controls need to overlay it.

**Mobile/touch:** Use `pointerdown`/`pointermove`/`pointerup` (not mouse events). Touch targets must be at least 44×44px. Disable canvas drag interactions during scroll to prevent gesture conflicts.

**Blank canvas on reduced motion:** `prefers-reduced-motion` means skip animation, not skip the visual. Always show a meaningful static state — the final frame, a representative snapshot, or a static layout with labels.

**Multiple figures fighting for resources:** Verify `observeVisibility(sim)` is called for every figure. Each figure should start its ticker only when intersecting — the shared block's `observeVisibility` utility handles this. Do not call `sim.start()` directly unless you intentionally want it to run off-screen.

**PixiJS v7 event API:** Use `obj.eventMode = 'static'` (not `obj.interactive = true`, which is v6 API). The `globalpointermove` event is required for drag — `pointermove` only fires when the pointer is over the object.
