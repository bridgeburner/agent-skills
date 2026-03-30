# PixiJS Canvas 2D Recipes

Reusable rendering patterns for interactive explainers. All recipes target **PixiJS v7** (`pixi.js-legacy`) with Canvas 2D rendering.

> **Note:** The assembled shared block (Simulation, Entity, observeVisibility, lerpColor, PALETTE) lives in `../templates/tutorial-page.html`. Sections below explain the design rationale and provide patterns for per-figure implementation.

## Table of Contents

1. [Application Setup](#1-application-setup) — includes Per-Figure IIFE Pattern, Cross-Figure State
2. [Off-Screen Pausing](#2-off-screen-pausing)
3. [Reduced Motion](#3-reduced-motion)
4. [Responsive Sizing](#4-responsive-sizing)
5. [Entity Pattern](#5-entity-pattern)
6. [Controls Creation](#6-controls-creation)
7. [GSAP Timeline Integration (Optional)](#7-gsap-timeline-integration-optional)
8. [Color Utilities](#8-color-utilities)
9. [Movement and Physics](#9-movement-and-physics)
10. [HTML-as-DSL Pattern](#10-html-as-dsl-pattern)

## 1. Application Setup

Canvas 2D avoids WebGL context limits when a page has many simulations.

```js
// PIXI is a global from the CDN script tag. No import needed.
class Simulation extends PIXI.Application {
  constructor({ element }) {
    super({
      backgroundAlpha: 0,       // transparent -- blends with page
      resizeTo: element,        // size to container, not window
      antialias: true,
      autoDensity: true,        // scale for retina
      resolution: window.devicePixelRatio || 1,
      forceCanvas: true,        // Canvas 2D, never WebGL
      autoStart: false,         // manual ticker control
    });
    element.appendChild(this.view);
    this.element = element;
    this.ticker.add((delta) => this.update(delta));
  }

  update(delta) { /* override -- per-frame logic */ }
  start() { this.ticker.start(); }
  stop() { this.ticker.stop(); }
}
```

Each simulation container should include a CSS loading spinner that the constructor replaces with the canvas. This avoids a blank space flash before JS initializes:

```html
<div class="simulation" style="height:300px">
  <div class="loading-spinner"></div>
</div>
```
```css
.loading-spinner { display: flex; justify-content: center; align-items: center;
  height: 100%; color: #999; }
.loading-spinner::after { content: ""; width: 32px; height: 32px; border: 3px solid #ddd;
  border-top-color: #666; border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
```

The `element.appendChild(this.view)` in the constructor automatically pushes the spinner down. To fully replace it:

```js
// In Simulation constructor, after super() and appendChild:
const spinner = element.querySelector('.loading-spinner');
if (spinner) spinner.remove();
```

### Per-Figure IIFE Pattern

Each figure gets its own `<script>` tag after its `<figure>` element. Wrap in an IIFE to prevent namespace pollution between figures:

```js
;(() => {
  const el = document.getElementById('fig-1');
  const sim = new Simulation({ element: el });
  // ... figure-specific entities, controls, ticker logic
  observeVisibility(sim);
})();
```

Place the `Simulation` class, `observeVisibility`, `lerpColor`, `PALETTE`, and other shared utilities in a single `<script id="shared">` block before all figures. Per-figure scripts read from these globals but create no new ones.

### Cross-Figure State

When figures need to communicate (e.g., a slider in figure 1 affects figure 3), use a shared `EventTarget`:

```js
// In <script id="shared">:
const shared = new EventTarget();
shared.set = (key, val) => {
  shared[key] = val;
  shared.dispatchEvent(new CustomEvent('change', { detail: { key, val } }));
};

// Figure 1 (publisher):
slider.addEventListener('input', () => shared.set('frequency', +slider.value));

// Figure 3 (subscriber):
shared.addEventListener('change', (e) => {
  if (e.detail.key === 'frequency') sim.setFrequency(e.detail.val);
});
```

## 2. Off-Screen Pausing

Pause the ticker when the simulation scrolls out of view. Critical on pages with multiple simulations to avoid burning CPU on invisible canvases.

```js
function observeVisibility(simulation) {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          simulation.ticker.start();
        } else {
          simulation.ticker.stop();
        }
      }
    },
    { threshold: 0 } // any pixel visible = start
  );
  observer.observe(simulation.element);
  return observer;
}
```

Usage -- replace manual `start()` with observer-driven lifecycle:

```js
const sim = new Simulation({ element });
observeVisibility(sim); // ticker starts/stops automatically
```

## 3. Reduced Motion

Respect `prefers-reduced-motion`. For educational content, "reduced motion" means showing the final state instantly rather than skipping the visual entirely.

```js
const prefersReducedMotion =
  window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// In animation code: jump to end state instead of animating
function animateEntity(entity, targetX, targetY, duration) {
  if (prefersReducedMotion) {
    entity.x = targetX;
    entity.y = targetY;
    return;
  }
  // ... normal animation logic
}
```

For GSAP timelines, jump to completion:

```js
if (prefersReducedMotion) {
  timeline.progress(1); // show final state
}
```

For CSS transitions on controls or overlays, pair with a media query:

```css
@media (prefers-reduced-motion: reduce) {
  .simulation-control, .annotation {
    transition: none !important;
  }
}
```

## 4. Responsive Sizing

Use `resizeTo: element` so the canvas fills its container. Recalculate layout-dependent values when the container resizes.

```js
class Simulation extends PIXI.Application {
  constructor({ element, columns = 16 }) {
    super({ resizeTo: element, forceCanvas: true, /* ... */ });
    this.columns = columns;
    this.recalcLayout();
  }

  recalcLayout() {
    const w = this.screen.width;
    const h = this.screen.height;
    this.cellSize = Math.floor(w / this.columns) - 1;
    this.rows = Math.floor(h / (this.cellSize + 2));
    // Reposition all entities...
  }
}
```

Listen for container resize and recalculate:

```js
new ResizeObserver(() => simulation.recalcLayout()).observe(element);
```

`autoDensity: true` + `resolution: window.devicePixelRatio` handles retina automatically -- CSS pixel dimensions stay the same while the internal buffer renders at device density.

## 5. Entity Pattern

Each entity extends `PIXI.Graphics`, draws itself, and exposes `update(delta)` for per-frame logic.

```js
class Entity extends PIXI.Graphics {
  constructor(simulation) {
    super();
    this.simulation = simulation;
    this.destroyed = false;
  }
  update(delta) { /* override */ }
  remove() {
    this.destroyed = true;
    if (this.parent) this.parent.removeChild(this);
    this.destroy();
  }
}

class Request extends Entity {
  constructor(simulation, { x, y, radius = 8, color = 0x04bf8a }) {
    super(simulation);
    this.beginFill(color);
    this.drawCircle(0, 0, radius);
    this.endFill();
    this.x = x;
    this.y = y;
  }
  update(delta) { /* movement, color changes, etc. */ }
}
```

Add entity collection management to the Simulation class from section 1:

```js
// In constructor: this.entities = [];
addEntity(entity) { this.entities.push(entity); this.stage.addChild(entity); }
update(delta) {
  this.entities = this.entities.filter((e) => !e.destroyed);
  for (const entity of this.entities) entity.update(delta);
}
```

## 6. Controls Creation

Controls are native HTML elements positioned beside or above the canvas. Native elements give you accessibility and keyboard support for free.

```js
function createControl(tag, attrs) {
  const el = document.createElement(tag);
  Object.assign(el, attrs);
  return el;
}

function createSlider({ label, min, max, value, step = 1, onChange }) {
  const wrap = createControl("div", { className: "sim-control" });
  const lbl = createControl("label", { textContent: label });
  const val = createControl("span", { className: "sim-control-value", textContent: value });
  const input = createControl("input", { type: "range", min, max, step, value });
  input.addEventListener("input", (e) => {
    const v = parseFloat(e.target.value);
    val.textContent = v;
    onChange(v);
  });
  lbl.appendChild(val);
  wrap.append(lbl, input);
  return wrap;
}

function createSelect({ label, options, value, onChange }) {
  const wrap = createControl("div", { className: "sim-control" });
  const lbl = createControl("label", { textContent: label });
  const sel = createControl("select", {});
  for (const opt of options) {
    const o = createControl("option", { value: opt.value, textContent: opt.label });
    if (opt.value === value) o.selected = true;
    sel.appendChild(o);
  }
  sel.addEventListener("change", (e) => onChange(e.target.value));
  wrap.append(lbl, sel);
  return wrap;
}
```

Attach controls to a simulation:

```js
const controls = createControl("div", { className: "sim-controls" });
controls.appendChild(createSlider({
  label: "Speed: ", min: 1, max: 20, value: 5,
  onChange: (v) => { simulation.speed = v; },
}));
element.parentNode.insertBefore(controls, element.nextSibling);
```

## 7. GSAP Timeline Integration (Optional)

Use GSAP for **deterministic sequences** the user scrubs through (step-by-step algorithm execution). Skip for real-time simulations where state depends on live parameters.

```html
<!-- Add GSAP CDN scripts after PixiJS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/PixiPlugin.min.js"></script>
```
```js
// In your inline <script>, register the plugin:
gsap.registerPlugin(PixiPlugin);
PixiPlugin.registerPIXI(PIXI);
```

Build a timeline, then map a slider to `timeline.progress()`:

```js
const tl = gsap.timeline({ paused: true });
tl.to(byteGraphic, { pixi: { tint: 0x04bf8a, alpha: 1 }, duration: 0.3 });
tl.to(labelText, { pixi: { alpha: 1 }, duration: 0.2 }, "<"); // simultaneous

slider.addEventListener("input", (e) => {
  tl.progress(parseFloat(e.target.value));
  simulation.ticker.update(); // render the frame
});
```

Add tick marks at step boundaries using `<datalist>`:

```js
const datalist = document.createElement("datalist");
datalist.id = `ticks-${simId}`;
slider.setAttribute("list", datalist.id);
for (const p of stepBoundaries) {
  const o = document.createElement("option");
  o.value = p;
  datalist.appendChild(o);
}
element.appendChild(datalist);
```

## 8. Color Utilities

### lerpColor (Hex Color Blending)

Linearly interpolate two hex colors by ratio (0 = colorA, 1 = colorB). Operates on packed integer hex values for direct use with PixiJS `tint`. Referenced by animation patterns.

```js
function lerpColor(colorA, colorB, ratio) {
  const r1 = (colorA >> 16) & 0xff;
  const g1 = (colorA >> 8) & 0xff;
  const b1 = colorA & 0xff;
  const r2 = (colorB >> 16) & 0xff;
  const g2 = (colorB >> 8) & 0xff;
  const b2 = colorB & 0xff;
  const r = Math.round(r1 + (r2 - r1) * ratio);
  const g = Math.round(g1 + (g2 - g1) * ratio);
  const b = Math.round(b1 + (b2 - b1) * ratio);
  return (r << 16) | (g << 8) | b;
}
```

### Color Aging

Encode entity age as a green-to-red color shift. Common for request latency, queue wait time, etc.

```js
const COLOR_HEALTHY = 0x04bf8a; // green
const COLOR_DANGER  = 0xf22233; // red

function ageColor(ageMs, thresholdMs = 10000) {
  return lerpColor(COLOR_HEALTHY, COLOR_DANGER, Math.min(1, ageMs / thresholdMs));
}

// In entity update:
this.age += this.simulation.ticker.elapsedMS;
this.tint = ageColor(this.age);
```

### Default Palette (Colorblind-Friendly)

```js
const PALETTE = {
  green:  0x04bf8a,  // healthy, available, success
  red:    0xf22233,  // danger, dropped, error
  blue:   0x0072b2,  // informational, size labels
  orange: 0xd55e00,  // warning, allocated
  yellow: 0xe69f00,  // highlight, usable
  grey:   0xdddddd,  // inactive, background
  dark:   0x555555,  // strong/powerful
};
```

## 9. Movement and Physics

### Linear Movement Toward Destination

Constant speed toward a target point. Uses `atan2` for direction, distance threshold for arrival.

```js
// In entity update(delta):
const dx = this.destX - this.x;
const dy = this.destY - this.y;
const dist = Math.sqrt(dx * dx + dy * dy);

if (dist < this.speed * delta) {
  this.x = this.destX;
  this.y = this.destY;
  this.onArrival();
  return;
}

const angle = Math.atan2(dy, dx);
this.x += Math.cos(angle) * this.speed * delta;
this.y += Math.sin(angle) * this.speed * delta;
```

### Simple Gravity (Dropped Elements)

Falling animation for rejected/dropped entities. Random initial velocity adds visual variety.

```js
// In constructor:
this.vx = (Math.random() - 0.5) * 2;
this.vy = (Math.random() - 0.5) * 2;

// In update(delta):
this.vy += 0.5 * delta; // gravity
this.x += this.vx;
this.y += this.vy;
if (this.y > this.simulation.screen.height + 20) this.remove();
```

### Visual Work Indicator (Shrinking)

Shrink proportionally to remaining work. Communicates processing without a progress bar.

```js
const progress = request.cost / request.initialCost;
request.scale.set(progress, progress);
```

## 10. HTML-as-DSL Pattern

Define simulation sequences declaratively in HTML. The article content IS the simulation definition.

### Parsed Custom Tags

HTML uses non-standard tags as inert data. JavaScript parses them into simulation state.

```html
<div class="simulation" data-bytes="32">
  <malloc size="4" addr="0x0"></malloc>
  <malloc size="5" addr="0x4"></malloc>
  <free addr="0x0"></free>
</div>
```

Parser walks DOM children and converts to a command list:

```js
function parseSimulation(element) {
  return [...element.children].map((child) => {
    const tag = child.tagName.toLowerCase();
    const attrs = Object.fromEntries(
      [...child.attributes].map((a) => [a.name, a.value])
    );
    return { type: tag, ...attrs };
  });
}
// => [{ type: "malloc", size: "4", addr: "0x0" }, { type: "free", addr: "0x0" }, ...]
```

### Config-Object Alternative

For parameterized simulations (real-time, user-tunable), skip the DSL and pass a config object:

```js
new Simulation({
  element: document.getElementById("sim-1"),
  numServers: 3,
  rps: 5,
  algorithm: "round-robin",
  showRpsSlider: true,
  showAlgorithmSelector: true,
});
```

### When to Use Which

| Approach | Use when | Example |
|----------|----------|---------|
| HTML-as-DSL | Author controls the exact sequence of events | Memory allocation steps, algorithm trace |
| Config object | User controls live parameters, state is emergent | Load balancer, physics sandbox |
| Web components | Reusable across posts, needs encapsulation | `<hash-map>`, `<bloom-filter>` |
