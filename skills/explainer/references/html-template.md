# HTML Template

Each explanation is a single self-contained HTML file. Figures are isolated via per-figure `<script>` tags to keep each visualization independently editable.

## Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Concept] — Interactive Explanation</title>
  <script src="https://pixijs.download/v7.3.2/pixi-legacy.min.js"></script>
  <style>/* Base styles below, then per-figure styles */</style>
</head>
<body>
  <article>
    <h1>[Concept]</h1>

    <!-- Shared utilities: Simulation class, observeVisibility, lerpColor, PALETTE, cross-figure state -->
    <script id="shared">
      // See pixijs-recipes.md for full implementations
      const prefersReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
      const PALETTE = { green: 0x04bf8a, red: 0xf22233, blue: 0x0072b2, /* ... */ };

      class Simulation extends PIXI.Application { /* ... */ }
      function observeVisibility(sim) { /* ... */ }
      function lerpColor(a, b, t) { /* ... */ }

      // Cross-figure reactive state (if figures need to communicate)
      const shared = new EventTarget();
      shared.set = (key, val) => {
        shared[key] = val;
        shared.dispatchEvent(new CustomEvent('change', { detail: { key, val } }));
      };
    </script>

    <p>Opening prose...</p>

    <figure class="interactive" id="fig-1">
      <canvas></canvas>
      <div class="controls"><!-- sliders, buttons --></div>
      <figcaption>Figure 1: ...</figcaption>
    </figure>
    <script>
    ;(() => {
      const el = document.getElementById('fig-1');
      const sim = new Simulation({ element: el.querySelector('canvas').parentElement });
      // ... figure-specific setup, entities, controls
      observeVisibility(sim);
    })();
    </script>

    <p>Connecting prose...</p>

    <figure class="interactive" id="fig-2">
      <canvas></canvas>
      <div class="controls"></div>
      <figcaption>Figure 2: ...</figcaption>
    </figure>
    <script>
    ;(() => {
      const el = document.getElementById('fig-2');
      const sim = new Simulation({ element: el.querySelector('canvas').parentElement });
      // ... figure-specific setup
      observeVisibility(sim);
    })();
    </script>

    <!-- More prose + figure + script triplets -->
  </article>
</body>
</html>
```

## Architecture

- **Shared `<script id="shared">`**: One block defining `Simulation`, utilities, `PALETTE`, and optional cross-figure state. Placed before all figures. All figure scripts depend on it.
- **Per-figure `<script>`**: Each `<figure>` is immediately followed by a `<script>` containing a self-contained IIFE. The IIFE uses globals from the shared block but creates no new globals.
- **Cross-figure state**: When a slider in figure 1 must affect figure 3, use the `shared` EventTarget. Figure 1 calls `shared.set('param', val)`, figure 3 subscribes with `shared.addEventListener('change', ...)`.

This structure means editing figure N requires reading only that figure's `<figure>` + `<script>` pair and the shared block — not the entire file.

## Base Styles

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, -apple-system, sans-serif;
  line-height: 1.6; color: #1a1a2e; background: #fafafa; }
article { max-width: 700px; margin: 0 auto; padding: 2rem 1rem; }
h1, h2, h3 { line-height: 1.2; }
figure.interactive { margin: 2rem -1rem; position: relative; }
figure.interactive canvas { display: block; width: 100%; }
.controls { display: flex; flex-wrap: wrap; gap: 0.75rem; padding: 0.5rem 1rem;
  font-size: 0.875rem; }
.controls label { display: flex; align-items: center; gap: 0.5rem; }
.controls input[type="range"] { width: 120px; }
figcaption { font-size: 0.8rem; color: #666; text-align: center; padding: 0.25rem; }
@media (prefers-reduced-motion: reduce) {
  .controls, .annotation { transition: none !important; }
}
```
