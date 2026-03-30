# Report Template

Minimal HTML template for scrollable long-form content — reports, articles, and tutorials. Prose-first: clean typography, no heavy design components, PixiJS figures embedded naturally in the flow.

For interactive HTML essays (PixiJS figures, per-figure IIFEs), see [html-template.md](html-template.md) instead.

## HTML Shell

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Report Title</title>
  <style>
    /* All styles inline — no external CSS */
  </style>
</head>
<body>
  <article>
    <header>
      <h1>Report Title</h1>
      <p class="subtitle">Subtitle or date line</p>
    </header>

    <!-- Optional: inline TOC for 4+ sections (omit for shorter pieces) -->
    <nav class="toc">
      <ol>
        <li><a href="#s1">First Section</a></li>
        <li><a href="#s2">Second Section</a></li>
      </ol>
    </nav>

    <section id="s1">
      <h2>First Section</h2>
      <!-- prose, figures, tables -->
    </section>

    <section id="s2">
      <h2>Second Section</h2>
    </section>
  </article>

  <!-- Optional: Mermaid (see Mermaid Diagram Integration below) -->
</body>
</html>
```

Key structural rules:
- All content lives inside `<article>` — single column, centered
- TOC is optional inline `<ol>` at the top; omit for pieces with fewer than 4 sections
- No sticky sidebars, no dark mode switching, no CDN font imports
- No external assets except optional Mermaid CDN

## Base CSS

```css
*, *::before, *::after { box-sizing: border-box; }

body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
  line-height: 1.6;
  color: #1a1a2e;
  background: #fafafa;
}

article {
  max-width: 700px;
  margin: 0 auto;
  padding: 2.5rem 1.25rem 4rem;
}

/* Typography */
h1 {
  font-size: clamp(1.75rem, 4vw, 2.25rem);
  font-weight: 700;
  line-height: 1.15;
  letter-spacing: -0.02em;
  margin: 0 0 0.5rem;
}

h2 {
  font-size: clamp(1.25rem, 2.5vw, 1.5rem);
  font-weight: 600;
  line-height: 1.3;
  margin: 2.5rem 0 0.75rem;
}

h3 {
  font-size: clamp(1rem, 2vw, 1.125rem);
  font-weight: 600;
  line-height: 1.4;
  margin: 1.75rem 0 0.5rem;
}

p { margin: 0 0 1rem; }
p + p { margin-top: 0; }

.subtitle {
  font-size: 0.9rem;
  color: #666;
  margin: 0.25rem 0 2rem;
}

a { color: #0072b2; }
a:hover { text-decoration: none; }

code {
  font-family: 'SF Mono', Consolas, 'Liberation Mono', monospace;
  font-size: 0.85em;
  background: #f0f4f8;
  padding: 1px 5px;
  border-radius: 3px;
}

pre {
  font-family: 'SF Mono', Consolas, 'Liberation Mono', monospace;
  font-size: 0.825rem;
  line-height: 1.55;
  background: #f0f4f8;
  border: 1px solid #dde3ea;
  border-radius: 6px;
  padding: 1rem 1.25rem;
  overflow-x: auto;
  margin: 1.25rem 0;
}

pre code { background: none; padding: 0; }

ul, ol { padding-left: 1.5rem; margin: 0 0 1rem; }
li { margin-bottom: 0.25rem; }

/* Sections */
section { margin-bottom: 2.5rem; }

/* TOC */
.toc {
  margin: 0 0 2.5rem;
  padding: 1rem 1.25rem;
  background: #f0f4f8;
  border-radius: 6px;
  font-size: 0.875rem;
}

.toc ol { margin: 0; padding-left: 1.25rem; }
.toc li { margin-bottom: 0.125rem; }
.toc a { color: #0072b2; text-decoration: none; }
.toc a:hover { text-decoration: underline; }

/* Figures with embedded PixiJS canvas */
figure {
  margin: 2rem -1.25rem;
  position: relative;
}

figure canvas { display: block; width: 100%; }

.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  padding: 0.5rem 1.25rem;
  font-size: 0.875rem;
}

.controls label { display: flex; align-items: center; gap: 0.5rem; }
.controls input[type="range"] { width: 120px; }

figcaption {
  font-size: 0.8rem;
  color: #666;
  text-align: center;
  padding: 0.375rem 1.25rem 0.25rem;
}

/* Callouts */
.callout {
  background: #f0f4f8;
  border-left: 3px solid #0072b2;
  border-radius: 0 5px 5px 0;
  padding: 0.75rem 1rem;
  margin: 1.25rem 0;
  font-size: 0.9rem;
}

.callout--warn { border-left-color: #d97706; }
.callout--error { border-left-color: #ef4444; }
.callout strong { font-weight: 600; }

/* Data tables */
.table-wrap {
  overflow-x: auto;
  margin: 1.25rem 0;
  border: 1px solid #dde3ea;
  border-radius: 6px;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

th {
  background: #f0f4f8;
  font-weight: 600;
  text-align: left;
  padding: 0.625rem 0.875rem;
  border-bottom: 1px solid #dde3ea;
  white-space: nowrap;
}

td {
  padding: 0.625rem 0.875rem;
  border-bottom: 1px solid #eef1f5;
  vertical-align: top;
}

tr:last-child td { border-bottom: none; }
td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

/* Responsive */
@media (max-width: 600px) {
  article { padding: 1.5rem 1rem 3rem; }
  figure { margin-left: -1rem; margin-right: -1rem; }
}
```

## Components

### Callout

```html
<div class="callout">
  <strong>Note:</strong> This covers the recommended approach.
</div>

<div class="callout callout--warn">
  <strong>Warning:</strong> Breaking change in v3.0.
</div>
```

### Data Table

```html
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Description</th>
        <th class="num">Count</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><code>auth-service</code></td>
        <td>Handles authentication and JWT issuance</td>
        <td class="num">247</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Embedded PixiJS Figure

When a tutorial or article includes interactive or animated figures, use the `<figure>` + `<script>` pattern from [html-template.md](html-template.md). Add the PixiJS CDN import and shared script block to the `<head>`, then slot each figure in the natural prose flow:

```html
<!-- In <head>: -->
<script src="https://pixijs.download/v7.3.2/pixi-legacy.min.js"></script>

<!-- In prose flow: -->
<figure id="fig-1">
  <canvas></canvas>
  <div class="controls"><!-- sliders, buttons --></div>
  <figcaption>Figure 1: ...</figcaption>
</figure>
<script>
;(() => {
  const el = document.getElementById('fig-1');
  const sim = new Simulation({ element: el.querySelector('canvas').parentElement });
  observeVisibility(sim);
})();
</script>
```

See [html-template.md](html-template.md) for the full `Simulation` class, `observeVisibility`, shared utilities, and per-figure IIFE architecture.

## Mermaid Diagram Integration

### Setup

Mermaid v11 ESM from CDN. Always `theme: 'base'` to stay neutral against the page palette.

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    look: 'classic',
    themeVariables: {
      primaryColor: '#f0f4f8',
      primaryBorderColor: '#0072b2',
      primaryTextColor: '#1a1a2e',
      secondaryColor: '#f0fdf4',
      secondaryBorderColor: '#059669',
      secondaryTextColor: '#1a1a2e',
      lineColor: '#9ca3af',
      fontSize: '15px',
      fontFamily: 'system-ui, -apple-system, sans-serif',
    }
  });
</script>
```

For complex graphs needing better layout, add ELK:

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  import elkLayouts from 'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk/dist/mermaid-layout-elk.esm.min.mjs';
  mermaid.registerLayoutLoaders(elkLayouts);
  mermaid.initialize({ startOnLoad: true, layout: 'elk', /* themeVariables as above */ });
</script>
```

### Diagram wrapper

```html
<div class="mermaid-wrap">
  <pre class="mermaid">
    graph TD
      A[Request] --> B{Authenticated?}
      B -->|Yes| C[Load Dashboard]
      B -->|No| D[Login Page]
  </pre>
</div>
```

```css
.mermaid-wrap {
  margin: 1.25rem 0;
  background: #fff;
  border: 1px solid #dde3ea;
  border-radius: 6px;
  padding: 1.5rem 1rem;
  overflow-x: auto;
}
```

### Gotchas

- **Never define `.node` as a page-level CSS class.** Mermaid uses `.node` internally on SVG `<g>` elements. Page-level `.node` styles leak into diagrams and break layout.
- **Never set `color:` in `classDef` or per-node `style` directives.** Use semi-transparent fills for node backgrounds: `classDef highlight fill:#0072b233,stroke:#0072b2,stroke-width:2px`
- **`stateDiagram-v2` cannot handle special characters in labels.** Use `flowchart` for labels with colons, parentheses, or HTML entities.
- **Max 15-20 nodes per diagram.** Beyond that, readability collapses. Use `subgraph` blocks or split into multiple diagrams.
- **Sequence diagram messages must be plain text.** Curly braces, square brackets, angle brackets, and `&` silently break the parser.

### Writing Valid Mermaid

Quote labels with special characters:
```
A["handleRequest(ctx)"] --> B["DB: query users"]
```

Keep IDs simple, put readable names in the label:
```
userSvc["User Service"] --> authSvc["Auth Service"]
```

Use `subgraph` for grouping:
```
subgraph Auth
  login --> validate --> token
end
subgraph API
  gateway --> router --> handler
end
Auth --> API
```

Arrow style semantics: solid (`-->`) = primary flow, dotted (`.->`) = optional/async, thick (`==>`) = critical path, cross (`--x`) = rejected/blocked.
