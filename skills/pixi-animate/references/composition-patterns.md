# Composition Patterns & Design Principles

How prose and visualization relate on the page. Select a composition pattern for structure, then apply cross-cutting principles to refine interaction design.

## Table of Contents

- [Composition Patterns](#composition-patterns)
  - [1. Explain-then-Explore](#1-explain-then-explore)
  - [2. Inline Reactive Text](#2-inline-reactive-text)
  - [3. Narrative Parallax (Scrollytelling)](#3-narrative-parallax-scrollytelling)
  - [4. Annotation Overlay](#4-annotation-overlay)
  - [5. Progressive Formalization](#5-progressive-formalization)
  - [6. Challenge-Response](#6-challenge-response)
- [Cross-Cutting Principles](#cross-cutting-principles)
- [Named Composites](#named-composites)

---

## Composition Patterns

### 1. Explain-then-Explore

Prose introduces a concept, then an interactive visualization immediately follows. The default pattern when nothing else fits better.

**When to use:** The concept can be stated in words first and made tangible through manipulation. Most tutorials, concept explainers, technical walkthroughs.

**HTML structure:**

```html
<article>
  <section class="explanation">
    <h2>How Binary Search Works</h2>
    <p>Prose describing the concept...</p>
  </section>
  <figure class="interactive" id="binary-search-sim">
    <canvas></canvas>
    <div class="controls"><!-- buttons, sliders --></div>
    <figcaption>Click any element to bisect the array.</figcaption>
  </figure>
  <!-- Repeats: section, figure, section, figure -->
</article>
```

Structural rule: `<section>` then `<figure>`, alternating down the page.

**JS wiring:** IntersectionObserver lazy-inits each simulation on scroll-in and pauses off-screen tickers.

```js
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting && !e.target.dataset.init) {
      initSimulation(e.target);
      e.target.dataset.init = "1";
    }
  });
}, { threshold: 0.2 });
document.querySelectorAll('.interactive').forEach(el => obs.observe(el));
```

**Example:** Binary search — paragraph describes the algorithm, then an interactive sorted array lets the user click to bisect, watching the search space shrink per step.

---

### 2. Inline Reactive Text

Interactive values embedded directly in running prose. Dragging a number in a sentence updates computed values elsewhere. The text IS the interface.

**When to use:** Mathematical relationships, financial models — any explanation where the insight is "change X, watch Y respond" and the relationship fits in a sentence.

**HTML structure:**

```html
<p>
  At <span class="reactive-value" data-param="rate" data-min="1" data-max="15">5</span>%
  over <span class="reactive-value" data-param="years" data-min="1" data-max="30">10</span> years,
  $1000 grows to
  <span class="computed-value" data-formula="1000*(1+rate/100)**years">$1628.89</span>.
</p>
```

No separate visualization region. The document is the interactive surface.

**JS wiring:** `pointerdown`/`pointermove` on `.reactive-value` spans for horizontal scrubbing. Each change recomputes all `.computed-value` spans synchronously.

```js
el.addEventListener('pointerdown', (e) => {
  const onMove = (ev) => {
    el.textContent = clamp(original + (ev.clientX - e.clientX) * step, min, max);
    recomputeAll();
  };
  document.addEventListener('pointermove', onMove);
  document.addEventListener('pointerup', () =>
    document.removeEventListener('pointermove', onMove), { once: true });
});
```

**Example:** Bret Victor's Tangle — "Tax the top bracket at `<scrub>`70`</scrub>`% and revenue is `<computed>`$X trillion`</computed>`."

---

### 3. Narrative Parallax (Scrollytelling)

Prose scrolls past a pinned visualization. Each prose section triggers a visualization state change. Scroll position drives the narrative.

**When to use:** Data stories, sequential transformations, any explanation that unfolds as a journey at the reader's pace.

**HTML structure:**

```html
<div class="scroll-container">
  <div class="viz-sticky"><canvas id="main-viz"></canvas></div>
  <div class="scroll-narration">
    <div class="narration-step" data-state="intro"><p>In 2010, the distribution looked like this.</p></div>
    <div class="narration-step" data-state="shift"><p>By 2020, everything moved right.</p></div>
    <div class="narration-step" data-state="outliers"><p>But three cities bucked the trend.</p></div>
  </div>
</div>
```

```css
.viz-sticky { position: sticky; top: 0; height: 100vh; z-index: 1; }
.scroll-narration { position: relative; z-index: 2; pointer-events: none; }
.narration-step { min-height: 80vh; padding: 2rem; pointer-events: auto; }
```

**JS wiring:** IntersectionObserver on `.narration-step` elements fires state transitions.

```js
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => { if (e.isIntersecting) transitionViz(e.target.dataset.state); });
}, { threshold: 0.5 });
document.querySelectorAll('.narration-step').forEach(s => obs.observe(s));
```

**Example:** The Pudding's "Film Dialogue" — a bar chart stays pinned as paragraphs scroll past, each highlighting a different genre's speaking-time breakdown.

---

### 4. Annotation Overlay

Labels, arrows, and callouts placed directly on the visualization. Eliminates the need to mentally map between prose and visual.

**When to use:** Complex diagrams, system architecture, anatomy — anywhere the reader would otherwise play "find the part I'm reading about."

**HTML structure:**

```html
<figure class="annotated-viz">
  <canvas id="system-diagram"></canvas>
  <div class="annotation" style="--x:35%;--y:20%;" data-highlight="load-balancer">
    <span class="annotation-line"></span>
    <span class="annotation-label">Load balancer distributes across 3 pools</span>
  </div>
</figure>
```

```css
.annotated-viz { position: relative; }
.annotation { position: absolute; left: var(--x); top: var(--y); transform: translate(-50%,-100%); }
.annotation-line { display: block; width: 1px; height: 2rem; background: var(--accent); margin: 0 auto; }
```

**JS wiring:** Hover an annotation to highlight the corresponding visual element. Use color-matched terms (blue label = blue highlight on the element).

```js
annotation.addEventListener('pointerenter', () => { vizElements[annotation.dataset.highlight].tint = HIGHLIGHT; });
annotation.addEventListener('pointerleave', () => { vizElements[annotation.dataset.highlight].tint = DEFAULT; });
```

**Example:** Ciechanowski's GPS explainer — radio wave visualization has inline labels showing signal travel time, color-matched to each satellite.

---

### 5. Progressive Formalization

Start with interactive intuition-building, then introduce formal notation only after the reader has a felt sense. Concrete manipulation earns the abstraction.

**When to use:** Mathematical concepts, formal systems — anything where the formula is scary but the idea is simple.

**HTML structure:**

```html
<section class="intuition-phase">
  <p>Drag the arrows to see how they combine.</p>
  <figure class="interactive" id="vector-playground"><canvas></canvas></figure>
</section>
<section class="bridge-phase">
  <p>Notice: the result always lands at the same point, regardless of order.</p>
</section>
<section class="formal-phase">
  <div class="math-block" role="math">a + b = b + a</div>
  <figure class="interactive" id="vector-formal">
    <canvas></canvas>
    <div class="coord-readout"></div>
  </figure>
</section>
```

Three phases: intuition (hands-on, no notation), bridge (observation in words), formal (notation + same interactive with numbers shown).

**JS wiring:** Intuition and formal interactives share the same simulation class with a `showCoords` toggle.

```js
new VectorSim(document.getElementById('vector-playground'), { showCoords: false });
new VectorSim(document.getElementById('vector-formal'), { showCoords: true });
```

**Example:** Setosa's eigenvectors — drag data points to see the principal axis rotate, then reveal the eigenvalue equation that describes what you just felt.

---

### 6. Challenge-Response

Pose a question, provide an interactive workspace for the reader to commit to an answer, then reveal the truth. The prediction-reality gap creates memorable learning.

**When to use:** Counterintuitive results, common misconceptions, surprising data. Key signal: "most people guess wrong."

**HTML structure:**

```html
<section class="challenge">
  <h2>How much of the ocean floor is mapped?</h2>
  <figure class="interactive" id="guess-workspace">
    <canvas></canvas>
    <div class="guess-readout">Your guess: <span id="guess-value">50%</span></div>
    <button id="reveal-btn" disabled>Lock in & reveal</button>
  </figure>
</section>
<section class="response hidden" id="response-panel">
  <div class="result-comparison">
    <span class="your-guess"></span> <span class="actual-answer">23%</span>
  </div>
  <p>Explanation...</p>
</section>
```

**JS wiring:** Enable reveal only after user interaction (commitment). On reveal, animate from guessed to actual value.

```js
canvas.addEventListener('pointerup', () => { revealBtn.disabled = false; });
revealBtn.addEventListener('click', () => {
  responsePanel.classList.remove('hidden');
  animateComparison(userGuess, actualValue);
});
```

**Example:** The Pudding's "You Draw It" — reader draws a line predicting trend data, then the actual trend animates in, exposing where intuition diverged.

---

## Cross-Cutting Principles

Apply regardless of composition pattern.

### 1. Gradient of Agency

Start guided (scroll, click next), build to parameter tweaking (sliders), end with sandbox (open exploration). Match the reader's growing confidence.

- **Do this:** First section uses step-through buttons. Middle adds sliders. Final section is an open playground.
- **Not this:** Drop the reader into an unconstrained sandbox on page load.

### 2. Immediacy

Feedback within one frame (~16ms). Decouple heavy computation from rendering -- show partial results instantly, refine async.

- **Do:** Slider redraws canvas on the same `requestAnimationFrame`.
- **Not:** 200ms debounced recompute causing visible lag.

### 3. Reversibility

Every action undoable. The reader must feel safe exploring.

- **Do:** Dragging a point lets you drag it back. Reset button restores initial state.
- **Not:** "Run" button with no way to return to starting configuration.

### 4. Object Constancy

Same entity maintains visual identity across transitions -- same color, position trajectory, label.

- **Do:** Sorting a bar chart -- bars slide to new positions with interpolation.
- **Not:** Chart redraws from scratch, bars flicker.

### 5. Minimal Chrome

The visualization IS the interface. Controls sit adjacent to the visual region they affect.

- **Do:** Drag a node directly. Inline scrubber beside the value it controls.
- **Not:** Sidebar of 8 sliders labeled "Parameter A" through "H" controlling a distant chart.

### 6. Progressive Complexity

Simplest version first. Additional controls appear as the reader scrolls or opts in.

- **Do:** First viz has play/pause only. "Advanced" toggle reveals more sliders later.
- **Not:** First viz presents 5 sliders, 3 toggles, and a dropdown simultaneously.

---

## Named Composites

Characteristic pattern combinations from notable creators. Use as templates.

**The Ciechanowski Pattern** (3D museum exhibit)
Explain-then-explore + annotation overlay + progressive formalization. Dozens of small interactives per article, each building toward formal understanding.

**The Red Blob Games Pattern** (interactive textbook)
Explain-then-explore + annotation overlay. Every diagram is interactive. Hover reveals data, click changes state. Interactives every 2-3 paragraphs.

**The Nicky Case Pattern** (playable essay)
Challenge-response + progressive formalization + explain-then-explore. Starts with a game that builds intuition, then layers in systemic explanation. The essay is played, not read.

**The Pudding Pattern** (scroll-driven data story)
Narrative parallax + challenge-response. Pinned visualization driven by scroll with "you draw it" commitment moments. Data-journalism framing.

**The samwho.dev Pattern** (technical visual essay)
Explain-then-explore with two sub-modes: (a) GSAP timeline scrubbing for deterministic sequences (memory allocation), (b) real-time physics simulation for emergent behavior (load balancing). Progressive complexity -- early figures are static, sliders appear mid-article, full playground at the end.

**The Bret Victor Pattern** (reactive document)
Inline reactive text + annotation overlay. Numbers in prose are scrubable. Multiple linked representations update simultaneously. No separation between text and visualization.
