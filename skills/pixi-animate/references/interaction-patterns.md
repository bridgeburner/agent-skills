# Interaction Patterns

10 patterns for user control of interactive explanatory content. PixiJS Canvas 2D rendering, native HTML controls.

## Table of Contents

1. [Parameter Slider](#1-parameter-slider)
2. [Temporal Scrubber](#2-temporal-scrubber)
3. [Step-Through Playback](#3-step-through-playback)
4. [Direct Manipulation](#4-direct-manipulation)
5. [Scroll-Driven Progression](#5-scroll-driven-progression)
6. [Toggle/Switch](#6-toggleswitch)
7. [Hover-to-Reveal](#7-hover-to-reveal)
8. [Linked Multi-View](#8-linked-multi-view)
9. [Sandbox/Playground](#9-sandboxplayground)
10. [Prediction Commitment](#10-prediction-commitment)

## Universal Rules

- Native HTML controls (`<input type="range">`, `<button>`) — keyboard/screen-reader support for free
- Respect `prefers-reduced-motion: reduce` — skip animations, show final states
- All interactions reversible — no destructive state changes
- Feedback within one frame (~16ms); update on `input`, not `change`
- `autoStart: false` on PixiJS app; start ticker only when simulation is ready

---

## 1. Parameter Slider

Sweep a continuous variable; visualization updates live on every input event.

**When to use:** Mathematical relationships, physical properties, cause-and-effect where user needs to feel the derivative.

**Key properties:** Continuous feedback. Deterministic (same value = same visual). Low commitment.

```html
<label>Altitude: <input type="range" id="param" min="200" max="36000" value="400">
  <span id="val">400 km</span></label>
<canvas id="sim"></canvas>
```
```js
slider.addEventListener('input', () => {
  sim.setState({ altitude: +slider.value });
  app.render();
});
```

**Subtypes:** Inline scrubber (draggable number in prose, Bret Victor style). Dedicated track (standard labeled slider). 2D parameter pad (canvas overlay, X/Y mapped to two params via `pointermove` + `pointerdown` guard).

**Pairs with:** Animation: continuous deformation, color-field shifts. Composition: inline reactive text, explain-then-explore.

---

## 2. Temporal Scrubber

Scrub forward/backward through a pre-computed timeline. User controls time position via slider.

**When to use:** Fixed-sequence processes — memory allocation steps, algorithm traces, mechanical sequences.

**Key properties:** Deterministic addressable states. Pre-computed (no simulation cost during scrub). Supports continuous drag and discrete snap.

```html
<canvas id="sim"></canvas>
<input type="range" id="timeline" min="0" max="1" step="0.001" value="0">
```
```js
const tl = gsap.timeline({ paused: true });
tl.to(entity, { x: 300, duration: 1 }).to(entity, { alpha: 0, duration: 0.5 });

scrubber.addEventListener('input', () => { tl.progress(+scrubber.value); app.render(); });
// Keyboard: ArrowRight/Left for fine scrub
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight') tl.progress(Math.min(1, tl.progress() + 0.01));
  if (e.key === 'ArrowLeft')  tl.progress(Math.max(0, tl.progress() - 0.01));
});
```

**Subtypes:** Continuous (smooth intermediate states). Snap-to-step (tick marks at key boundaries, snaps to nearest).

**Pairs with:** Animation: smooth state transitions, progressive assembly. Composition: narrative parallax.

---

## 3. Step-Through Playback

Discrete states with play/pause/prev/next controls.

**When to use:** Algorithms, sequential processes where each step must be understood before proceeding.

**Key properties:** Finite bounded states. User-paced (comprehension governs speed). Supports auto-play with pause.

```html
<canvas id="sim"></canvas>
<button id="prev">&#x25C0;</button>
<button id="play">&#x25B6;</button>
<button id="next">&#x25B6;|</button>
<span id="step-label">Step 1 / 12</span>
```
```js
let step = 0, playing = false, elapsed = 0;
const steps = buildSteps(); // array of render functions
const interval = 60; // frames between auto-advance

function goTo(i) {
  step = Math.max(0, Math.min(steps.length - 1, i));
  steps[step](app.stage);
  stepLabel.textContent = `Step ${step + 1} / ${steps.length}`;
  app.render();
}
nextBtn.onclick = () => goTo(step + 1);
prevBtn.onclick = () => goTo(step - 1);
playBtn.onclick = () => { playing = !playing; };
app.ticker.add((delta) => {
  if (playing && (elapsed += delta) > interval) { goTo(step + 1); elapsed = 0; }
});
```

**Pairs with:** Animation: algorithmic expansion, progressive assembly. Composition: explain-then-explore.

---

## 4. Direct Manipulation

Click-drag objects within the visualization. User moves, reshapes, or places entities on canvas.

**When to use:** Spatial reasoning, geometry, pathfinding endpoints, anything leveraging physical intuition.

**Key properties:** Strongest agency. Requires PixiJS hit-testing. Must feel physically responsive.

```js
function makeDraggable(obj, onMove) {
  obj.eventMode = 'static';
  obj.cursor = 'grab';
  let dragging = false, offset = { x: 0, y: 0 };
  obj.on('pointerdown', (e) => {
    dragging = true; obj.cursor = 'grabbing';
    const pos = e.data.getLocalPosition(obj.parent);
    offset = { x: obj.x - pos.x, y: obj.y - pos.y };
  });
  obj.on('globalpointermove', (e) => {
    if (!dragging) return;
    const pos = e.data.getLocalPosition(obj.parent);
    obj.x = pos.x + offset.x; obj.y = pos.y + offset.y;
    onMove(obj.x, obj.y);
  });
  obj.on('pointerup', () => { dragging = false; obj.cursor = 'grab'; });
  obj.on('pointerupoutside', () => { dragging = false; obj.cursor = 'grab'; });
}
```

**Subtypes:** Point repositioning (Bezier handles, pathfinding endpoints). Freeform drawing (capture pointer path). Brush/selection (drag defines a region).

**Pairs with:** Animation: continuous deformation, trajectory tracing, physics simulation. Composition: progressive formalization.

---

## 5. Scroll-Driven Progression

Scroll position drives visualization state. Most natural web interaction for narrative content.

**When to use:** Data narratives, guided tours, linear explanations where reading flow should not be interrupted.

**Key properties:** Zero learning curve. Preserves reading context. Requires pinned canvas + scroll listener.

```html
<div class="scrolly-container">
  <div class="scrolly-canvas" style="position:sticky;top:0;height:100vh">
    <canvas id="sim"></canvas>
  </div>
  <div class="scrolly-steps">
    <div class="step" data-step="0" style="min-height:80vh"><p>First...</p></div>
    <div class="step" data-step="1" style="min-height:80vh"><p>Then...</p></div>
  </div>
</div>
```
```js
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) sim.transitionTo(+e.target.dataset.step);
  });
}, { threshold: 0.5 });
document.querySelectorAll('.step').forEach(s => observer.observe(s));
```

**Subtypes:** Scrollytelling (pinned canvas, prose scrolls past). Scroll-triggered animation (canvas scrolls with page, animates at waypoints). Scroll-as-spatial-metaphor (position maps to depth/altitude/distance).

**Pairs with:** Animation: smooth state transitions, color-field shifts. Composition: narrative parallax, annotation overlay.

---

## 6. Toggle/Switch

Discrete controls switching between alternative views, representations, or modes.

**When to use:** Comparing representations (coordinate systems, algorithms), toggling overlays, enabling/disabling visual layers.

**Key properties:** Binary or small-N states. Highlights what changes vs. what stays the same. Instant switching.

```html
<div role="radiogroup" aria-label="View mode">
  <button role="radio" aria-checked="true" data-mode="cartesian">Cartesian</button>
  <button role="radio" aria-checked="false" data-mode="polar">Polar</button>
</div>
```
```js
document.querySelectorAll('[data-mode]').forEach(btn => {
  btn.onclick = () => {
    document.querySelectorAll('[data-mode]').forEach(b => b.setAttribute('aria-checked', 'false'));
    btn.setAttribute('aria-checked', 'true');
    sim.setMode(btn.dataset.mode);
    app.render();
  };
});
```

**Subtypes:** Binary toggle (on/off). Radio group (N mutually exclusive). Checkbox set (N independent layers).

**Pairs with:** Animation: smooth state transitions, synchronized multi-view. Composition: explain-then-explore.

---

## 7. Hover-to-Reveal

Mouseover reveals additional detail without click. Detail-on-demand without cluttering the default view.

**When to use:** Dense visualizations (grids, graphs, heatmaps), contextual glossary terms in prose.

**Key properties:** Zero commitment. Must degrade to tap-to-toggle on touch. Tooltip must not occlude the inspected element.

```js
entity.eventMode = 'static';
entity.on('pointerover', () => {
  tooltip.visible = true; tooltip.text = entity.label;
  highlight.visible = true; highlight.position.copyFrom(entity.position);
  app.render();
});
entity.on('pointerout', () => {
  tooltip.visible = false; highlight.visible = false; app.render();
});
entity.on('pointertap', () => { tooltip.visible = !tooltip.visible; app.render(); }); // touch
```

**Pairs with:** Animation: color-field shifts, propagation waves. Composition: annotation overlay.

---

## 8. Linked Multi-View

Interacting with one view updates all others simultaneously. The synchronization IS the teaching tool.

**When to use:** Multiple representations of the same system (time + frequency domain, code + visualization, map + chart).

**Key properties:** Shared state model (one source of truth). Bidirectional linking. Object constancy across views.

```js
const state = { frequency: 440, amplitude: 0.8 };
const views = [new WaveformView(app1), new SpectrumView(app2)];

function updateAll(patch) {
  Object.assign(state, patch);
  views.forEach(v => v.render(state));
}
slider.addEventListener('input', () => updateAll({ frequency: +slider.value }));
```

Each view class implements `render(state)` drawing into its own PixiJS app. Any view's controls call `updateAll()`.

**Pairs with:** Animation: synchronized multi-view, smooth state transitions. Composition: progressive formalization.

---

## 9. Sandbox/Playground

Open-ended exploration space after guided learning. User becomes the author.

**When to use:** End of a guided sequence, when reader can form their own questions.

**Key properties:** Transfers ownership from author to reader. Composes patterns #1, #4, #6. Needs reset button + presets for interesting configurations.

```html
<canvas id="sim"></canvas>
<button id="reset">Reset</button>
<select id="presets">
  <option value="default">Default</option>
  <option value="edge-case">Edge Case</option>
</select>
```
```js
const PRESETS = {
  default: { param1: 50, param2: 0.5 },
  'edge-case': { param1: 0, param2: 1.0 },
};
function loadPreset(name) {
  Object.assign(simState, structuredClone(PRESETS[name]));
  syncControlsToState();
  sim.rebuild(simState);
  app.render();
}
resetBtn.onclick = () => loadPreset('default');
presetSelect.onchange = () => loadPreset(presetSelect.value);
```

**Pairs with:** Animation: physics simulation, algorithmic expansion. Composition: explain-then-explore, challenge-response.

---

## 10. Prediction Commitment

User commits to an answer before the system reveals truth. The gap between prediction and reality is the teaching moment.

**When to use:** Counterintuitive results, statistical reasoning, "You Draw It" engagement where user misconception IS the lesson.

**Key properties:** Cognitive investment. Must capture input before reveal. Reveal animation makes the gap visceral. Irreversible within one attempt (offer retry).

```html
<p>Draw what you think happens next:</p>
<canvas id="sim"></canvas>
<button id="reveal" disabled>Show Answer</button>
```
```js
let userPath = [], committed = false;
canvas.addEventListener('pointermove', (e) => {
  if (!committed && e.buttons === 1) {
    userPath.push({ x: e.offsetX, y: e.offsetY });
    drawUserPath(userPath);
    revealBtn.disabled = false;
  }
});
revealBtn.onclick = () => {
  committed = true; revealBtn.disabled = true;
  const truth = computeTruth();
  let t = 0;
  app.ticker.add((delta) => {
    t = Math.min(1, t + delta / 60);
    drawTruthPath(truth, t); // progressive reveal alongside user line
    if (t >= 1) app.ticker.stop();
  });
};
```

**Pairs with:** Animation: trajectory tracing, smooth state transitions. Composition: challenge-response, explain-then-explore.
