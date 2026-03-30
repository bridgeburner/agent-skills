# Animation Patterns

Ten motion patterns for interactive explanatory content. All PixiJS Canvas 2D ticker-driven. Static fallbacks required for reduced-motion.

## Table of Contents

1. [Physics Simulation](#1-physics-simulation)
2. [Algorithmic Expansion](#2-algorithmic-expansion)
3. [Continuous Deformation](#3-continuous-deformation)
4. [Flow/Token Animation](#4-flowtoken-animation)
5. [Progressive Assembly](#5-progressive-assembly)
6. [Trajectory Tracing](#6-trajectory-tracing)
7. [Smooth State Transitions](#7-smooth-state-transitions)
8. [Color-Field Shifts](#8-color-field-shifts)
9. [Propagation Waves](#9-propagation-waves)
10. [Synchronized Multi-View](#10-synchronized-multi-view)

Code examples below use `lerpColor()` from [pixijs-recipes.md](pixijs-recipes.md) (section 8: Color Utilities). Do not redefine it — import from the shared recipe.

---

## 1. Physics Simulation

**What it is:** Continuous motion via simulated forces — gravity, springs, collisions. Euler integration per frame.

**When to use:** Emergent behavior, load balancing, system dynamics. Pairs with: parameter slider, sandbox/playground.

```js
function update(delta) {
  for (const e of entities) {
    e.vy += gravity * delta;
    e.vx *= friction; e.vy *= friction;
    e.x += e.vx * delta; e.y += e.vy * delta;
    if (e.y > floor) { e.y = floor; e.vy *= -bounce; }
    e.gfx.position.set(e.x, e.y);
    e.age += delta;
    const t = Math.min(1, e.age / maxAge);
    e.gfx.clear().beginFill(lerpColor(0x4CAF50, 0xF44336, t)).drawCircle(0, 0, r).endFill();
  }
}
```

**Encoding:** Color-age green-to-red for latency. Shrink `scale` as work completes. Alpha fadeout for departing entities.

**Reduced-motion:** Show entities at final positions. Skip integration; use layout solver. Keep color encoding.

---

## 2. Algorithmic Expansion

**What it is:** Wavefront grows step-by-step across a grid/graph. The temporal order IS the insight.

**When to use:** BFS, Dijkstra, flood fill. Pairs with: step-through playback, linked multi-view.

```js
const frontier = [startCell]; const visited = new Set();
function update(delta) {
  for (let i = 0; i < stepsPerFrame && frontier.length; i++) {
    const cell = frontier.shift();
    if (visited.has(cell.id)) continue;
    visited.add(cell.id);
    cell.gfx.clear().beginFill(0x2196F3).drawRect(0, 0, cellSize, cellSize).endFill();
    for (const n of cell.neighbors) if (!visited.has(n.id)) frontier.push(n);
  }
}
```

**Encoding:** Color by discovery order via `lerpColor(0x2196F3, 0x0D47A1, step/total)`. Frontier ring in accent (0xFFC107). Cost as text inside cells.

**Reduced-motion:** Show completed heatmap colored by discovery order. Display step count as text.

---

## 3. Continuous Deformation

**What it is:** Shapes morph smoothly as parameters change — curves bend, surfaces warp.

**When to use:** Bezier curves, activation functions, parameter-to-shape mappings. Pairs with: parameter slider, direct manipulation.

```js
function update(delta) {
  curve.clear().lineStyle(2, 0xFFFFFF);
  curve.moveTo(p0.x, p0.y);
  curve.bezierCurveTo(cp1.x, cp1.y, cp2.x, cp2.y, p1.x, p1.y);
  for (const cp of [cp1, cp2]) {
    curve.lineStyle(1, 0x888888).moveTo(cp.anchor.x, cp.anchor.y).lineTo(cp.x, cp.y);
    curve.beginFill(0xFFC107).drawCircle(cp.x, cp.y, 5).endFill();
  }
}
```

**Encoding:** Thin lines (alpha 0.3) for construction geometry. Thick lines for the result. Enlarge control points on hover (5px to 7px) to signal interactivity.

**Reduced-motion:** Redraw instantly on parameter change. User-driven deformation already works — skip interpolation frames only.

---

## 4. Flow/Token Animation

**What it is:** Discrete objects moving through a pipeline or system graph, source to destination.

**When to use:** Request processing, data pipelines, filter chains. Pairs with: parameter slider (flow rate), toggle/switch (algorithm).

```js
function update(delta) {
  for (const tk of tokens) {
    const dx = tk.target.x - tk.x, dy = tk.target.y - tk.y;
    const dist = Math.hypot(dx, dy);
    if (dist < 2) { onArrive(tk); continue; }
    tk.x += (dx / dist) * tk.speed * delta;
    tk.y += (dy / dist) * tk.speed * delta;
    tk.gfx.position.set(tk.x, tk.y);
  }
}
```

**Encoding:** Token color = status (green healthy, amber queued, red rejected). Size = payload weight. Stack tokens vertically at gates to show queue depth.

**Reduced-motion:** Show tokens at destinations. Static flow diagram with counts at each stage.

---

## 5. Progressive Assembly

**What it is:** Components appear one at a time, snapping into place to build a complete system.

**When to use:** Architecture walkthroughs, mechanism construction, layered systems. Pairs with: step-through playback, scroll-driven progression.

```js
function revealNext() {
  const part = parts[currentStep++];
  part.gfx.alpha = 0; part.gfx.y = part.targetY - 20;
  container.addChild(part.gfx);
  part.entering = true; part.frame = 0;
}
function update(delta) {
  for (const p of parts.filter(p => p.entering)) {
    p.frame += delta;
    const t = Math.min(1, p.frame / 20);
    p.gfx.alpha = t; p.gfx.y = p.targetY - 20 * (1 - t);
    if (t >= 1) p.entering = false;
  }
}
```

**Encoding:** Dim placed parts (alpha 0.6) while new part enters at full opacity. Accent color on active part. Draw connectors as parts attach.

**Reduced-motion:** Place parts at final position instantly (alpha 1). Keep sequential reveal on user action — the ordering is pedagogical.

---

## 6. Trajectory Tracing

**What it is:** Persistent path drawn behind a moving point. Compresses temporal info into a spatial trail.

**When to use:** Gradient descent, vehicle routes, parameter exploration. Pairs with: parameter slider, temporal scrubber.

```js
const history = [];
function update(delta) {
  const pos = computePosition(params);
  history.push(pos);
  trail.clear();
  for (let i = 1; i < history.length; i++) {
    trail.lineStyle(2, 0x2196F3, (i / history.length) * 0.8);
    trail.moveTo(history[i - 1].x, history[i - 1].y);
    trail.lineTo(history[i].x, history[i].y);
  }
  trail.beginFill(0xFFFFFF).drawCircle(pos.x, pos.y, 4).endFill();
}
```

**Encoding:** Fade alpha old-to-new for direction. Color gradient along trail encodes a second variable (velocity, loss). Thicken where point moved slowly.

**Reduced-motion:** Show complete trail as static path with numbered waypoints and start/end labels.

---

## 7. Smooth State Transitions

**What it is:** Animated interpolation between discrete states with easing. Maintains object constancy so viewers track what changed.

**When to use:** Data updates, chart reconfiguration, sorting. Pairs with: toggle/switch, step-through playback.

```js
function transitionTo(newState) {
  for (const it of items) {
    it.from = { x: it.x, y: it.y }; it.to = newState[it.id]; it.t = 0;
  }
}
function update(delta) {
  for (const it of items) {
    if (it.t >= 1) continue;
    it.t = Math.min(1, it.t + delta / frames);
    const e = 1 - Math.pow(1 - it.t, 3); // ease-out-cubic
    it.x = it.from.x + (it.to.x - it.from.x) * e;
    it.y = it.from.y + (it.to.y - it.from.y) * e;
    it.gfx.position.set(it.x, it.y);
  }
}
```

**Encoding:** Consistent ease-out-cubic. Stagger start times by 1-2 frames for sequential effect. Brief white-outline flash on changed items.

**Reduced-motion:** Snap to end state (set `t = 1`). Object constancy holds without interpolation.

---

## 8. Color-Field Shifts

**What it is:** Heatmaps or gradient fields where color encodes value. Position stays fixed; color responds to parameters.

**When to use:** Convergence regions, influence maps, scalar fields over 2D. Pairs with: parameter slider, hover-to-reveal.

```js
function update(delta) {
  for (const cell of cells) {
    const value = computeField(cell.r, cell.c, params); // 0..1
    const target = lerpColor(0x1A237E, 0xF44336, value);
    cell.color = lerpColor(cell.color, target, 0.1 * delta); // smooth
    cell.gfx.clear().beginFill(cell.color).drawRect(0, 0, cellW, cellH).endFill();
  }
}
```

**Encoding:** Diverging palette (blue-white-red) for fields with a midpoint. Sequential (single hue) for monotonic. Overlay contour lines at thresholds. Always add a color legend.

**Reduced-motion:** Set `cell.color = target` directly (skip lerp). Ensure palette works under color vision deficiencies. Add value-on-hover text.

---

## 9. Propagation Waves

**What it is:** Expanding rings radiating from a source. Communicates influence or signal spreading outward.

**When to use:** Radio waves, event propagation, network broadcasts. Pairs with: direct manipulation (place source), parameter slider (speed).

```js
function emit(x, y) {
  const gfx = new PIXI.Graphics();
  container.addChild(gfx);
  waves.push({ x, y, radius: 0, maxR: 200, gfx });
}
function update(delta) {
  for (let i = waves.length - 1; i >= 0; i--) {
    const w = waves[i];
    w.radius += speed * delta;
    const t = w.radius / w.maxR;
    if (t >= 1) { container.removeChild(w.gfx); w.gfx.destroy(); waves.splice(i, 1); continue; }
    w.gfx.clear().lineStyle(2, 0x42A5F5, 1 - t).drawCircle(w.x, w.y, w.radius);
  }
}
```

**Encoding:** Thickness = signal strength. Overlapping rings with additive alpha show interference. Color-code sources. Even spacing for periodic, single ring for impulse.

**Reduced-motion:** Show concentric static rings at fixed radii. Label each ring with distance/time value.

---

## 10. Synchronized Multi-View

**What it is:** Multiple visualizations animate in lockstep from shared state. The synchronization itself teaches the relationship.

**When to use:** Dual representations (time + frequency domain), linked equation and graph. Pairs with: linked multi-view, parameter slider.

```js
const shared = { value: 0.5 };
const views = [
  { container: viewA, render: renderTimeDomain },
  { container: viewB, render: renderFreqDomain },
];
function update(delta) {
  for (const v of views) v.render(v.container, shared, delta);
}
function renderTimeDomain(ctr, state, delta) {
  const gfx = ctr.children[0];
  gfx.clear().lineStyle(2, 0x4CAF50);
  for (let x = 0; x < width; x++) {
    const y = compute(x, state.value);
    x === 0 ? gfx.moveTo(x, y) : gfx.lineTo(x, y);
  }
}
```

**Encoding:** Shared accent color marks "current" element across views. Connector lines between corresponding elements on hover. Align layouts on a shared axis.

**Reduced-motion:** Update all views instantly (no transition animation). Synchronization still works. Add ARIA labels describing panel relationships.
