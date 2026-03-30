---
name: explainer
description: >-
  Design and create high-quality explanatory content in any format — tutorials,
  reports, presentations, articles, visual essays. Owns audience analysis,
  narrative arc, visual metaphor selection, aha-moment design, figure planning,
  and prose structure. Orchestrates renderer skills (pixi-animate, create-image)
  and handles static diagrams inline via HTML/SVG/Mermaid. Use this skill
  whenever the user wants to explain, teach, or communicate a concept in any
  medium — even if they phrase it as "write an article", "make slides", or
  "walk me through X". This skill is the content architect; it decides the
  format and delegates rendering.
  Triggers: "explain X", "create a report/tutorial/presentation on X",
  "make slides about X", "write an explainer/article/paper about X",
  "teach/walk me through/break down X", "how does X work",
  "build a visual essay about X", "deep dive into X", "demystify X",
  "summarize X visually", "design a lesson on X",
  "create an explainer on X", "I want to present X to my team".
---

# Explainer — Content Architect

Design and create explanatory content that makes readers *understand* something they did not understand before. Own the *what* and *why* of explanation. Delegate the *how* of rendering to specialized renderer skills.

## Skill Boundaries

This skill is the **content architect**. It decides the format, narrative, and figure strategy, then coordinates other skills to implement.

- **pixi-animate** — renders interactive and animated canvas figures. Invoke it with a detailed figure spec. For interactive HTML essays, pixi-animate implements all canvas figures; explainer assembles them into the prose shell.
- **create-image** — generates AI images for heroes, illustrations, and mood-setting. Invoke it with a prompt.

Explainer handles the full range of explanatory output: documents with embedded visuals (tutorial, report, article, slides) *and* standalone interactive HTML essays. The format is a content decision — pick it in Step 1 based on what the audience needs, not what sounds impressive.

---

## Core Philosophy

1. **Comprehension Over Coverage** — The goal is not to mention every fact. It is to change how someone thinks about a concept. Cut everything that does not serve understanding.
2. **Design the Aha Moment First** — Work backwards from the key insight. The aha moment is the destination; every paragraph, figure, and interaction is a step toward it.
3. **Prose and Visuals Are Inseparable** — Text introduces, visuals demonstrate, text consolidates. A figure without context is decoration. Prose without demonstration is hand-waving.
4. **Right Medium, Right Concept** — Match the representation to the concept. Some ideas need animation; others need a careful prose analogy; some need a static diagram; a few are clearest as a table. Resist defaulting to interactive because it feels impressive.
5. **Progressive Disclosure** — Start with the simplest version. Layer complexity through interaction, narrative, and visual detail. The reader earns each new piece.
6. **Every Figure Earns Its Place** — A figure must do work that prose alone cannot. If you can say it clearly in two sentences, do not make a chart.
7. **Know the Audience** — Vocabulary, assumed knowledge, and visual complexity all calibrate to who is reading. An expert and a beginner need different explanations of the same concept.

---

## Externalized State

**Do not accumulate plans, outlines, or intermediate artifacts in the conversation.** Write them to temporary files and reference those files in subsequent steps.

At the start of the workflow, create a unique working directory:

```bash
WORKDIR=$(mktemp -d)
```

Store `$WORKDIR` and use it for all intermediate files:

| Step | File | Contents |
|------|------|----------|
| 1 | `$WORKDIR/scope.md` | Concept, audience, format, thesis, aha moment |
| 2 | `$WORKDIR/aha-design.md` | Misconception, aha strategy, experience design |
| 3 | `$WORKDIR/visual-strategy.md` | Per-point visual decisions, renderer assignments |
| 4 | `$WORKDIR/plan.md` | Full structure, figure list with specs, prose outline |
| 5 | `$WORKDIR/draft-*.md` | Prose drafts, figure scripts, assembled output |
| 6 | `$WORKDIR/review.md` | Refinement notes, cut list |

Each step reads the previous step's file, does its work, and writes the next. Never reproduce a full plan inline — summarize and point to the file. Subagents read these files directly.

---

## Content Modes

Select the mode that best serves the audience and purpose. Hybrid modes are valid — a tutorial can contain interactive figures, a report can include slides.

### Tutorial
Teach a concept progressively. Reader starts knowing nothing (or knowing wrong things) and builds understanding step by step. Heavy use of figures and interaction. Gradient of agency: observe → tweak → explore.

**Use when:** The reader needs to *learn* something. There is a skill or mental model to build.

### Report / Analysis
Present findings with evidence. Thesis up front, supporting evidence in sequence, conclusions at the end. Figures serve as proof — they show the data, not just decorate.

**Use when:** The reader needs to be *convinced* of something. There are claims backed by evidence.

### Presentation / Slides
Slide-based delivery for live or async viewing. Each slide is one idea. Viewport-locked (no scrolling within slides). Content density limits apply strictly — see [references/slide-layouts.md](references/slide-layouts.md) for per-layout maximums.

**Use when:** The content will be presented live, shared as a deck, or needs a high-level overview format.

**Deck rhythm:** Alternate content density (heavy → light → heavy). Never place two consecutive hero-background slides. Insert a section divider every 4-6 content slides for decks longer than 8 slides. Bookend the deck — closing slide mirrors title treatment.

### Paper / Article
Long-form explanatory writing. Sustained argument or narrative. Figures punctuate but prose carries the load. Section-based structure with clear transitions.

**Use when:** The reader needs depth. The subject rewards extended engagement and cannot be reduced to a deck.

### Interactive HTML Essay
A self-contained HTML page where prose and interactive PixiJS figures coexist in a single scrollable column. The aesthetic is minimal — clean typography, no heavy design components, figures that feel native to the text. Think: a well-formatted article with live visualizations embedded, not a dashboard.

**Use when:** The deliverable is a standalone HTML file; the concept benefits from interaction or animation; the reader browses at their own pace rather than following a live presentation.

**Gradient of agency:** Structure the page so the reader moves from passive (prose + autoplay animation) to guided (sliders, step-through) to free (sandbox/playground). See [Cross-Cutting Principles for Interactive Output](#cross-cutting-principles-for-interactive-output).

**Focused vs. full-coverage mode:** When the source material is large, the user may want to focus on ONE concept for the interactive essay. Present 3-5 candidate concepts ranked by how much interactivity would help, and let them choose. Full-coverage interactive essays are also valid — they just require more figures and careful narrative sequencing.

---

## Workflow

### Step 1: Understand

Establish what is being explained, to whom, and in what form. A misidentified audience or wrong format choice cascades through everything — do not skip or rush this step.

- **What concept?** — Identify the core subject. If the source material covers many topics, decide: does the user want full coverage, or should this explainer focus on the single most impactful concept? For interactive HTML essays, lean toward focus — ask the user to choose from 3-5 candidates ranked by how much interactivity would help. For reports, tutorials, and papers, full coverage is often correct.
- **Who is the audience?** — Their existing knowledge. What vocabulary is safe. What can be assumed versus must be built up.
- **What format fits?** — Select a content mode (tutorial, report, presentation, paper, interactive HTML essay) based on purpose and delivery context.
- **What is the thesis?** — The one sentence the entire piece serves. If there is no clear thesis, the explanation is not ready.
- **What is the aha moment?** — The single insight the reader walks away with. State it concretely: "The reader will understand that X because they saw Y."

If source content is provided, analyze it. Extract the core argument, identify what is hard to understand statically, and note where visuals could do work that prose cannot.

If no source content is provided, help structure it. Ask what the user knows, what they want the audience to understand, and what evidence or examples exist.

Write scoping decisions to `$WORKDIR/scope.md`.

### Step 2: Design the Aha Moment

This is the step most explanations skip. They present information in order and hope understanding follows. Instead, work backwards from the insight.

Three questions to answer:
- **What misconception exists?** — What does the reader currently believe that is wrong or incomplete? The aha moment is the destruction of this misconception.
- **What experience creates understanding?** — Can the reader see a simulation break when a parameter crosses a threshold? Can a before/after comparison make the difference visceral? Can a well-chosen analogy do it in prose?
- **What is the minimum viable demonstration?** — The simplest possible thing the reader can see or do that produces the aha moment. Start here, then embellish only if needed.

Write the aha design as a concrete experience statement:

```
Misconception: [what the reader currently thinks]
Aha moment:    [what the reader will understand after]
Experience:    [what the reader sees/does that creates the shift]
Medium:        [interactive figure / static visual / narrative progression / data comparison]
```

This drives everything downstream. The figure list, prose structure, and renderer selection all serve this moment. Write to `$WORKDIR/aha-design.md`.

### Step 3: Select Visual Strategy

For each key point in the explanation, decide whether it needs a figure, and if so, what kind. Not every point needs a visual — sometimes clear prose is the best tool.

**Decision process per point:**

1. Can this be said clearly in 1-2 sentences? → Prose only.
2. Does this involve temporal processes, emergent behavior, or parameter sensitivity? → Animated canvas figure (pixi-animate), interactive or autoplay.
3. Does the reader need to manipulate or explore this? → Interactive figure (pixi-animate) with controls.
4. Does this need animated demonstration without user input? → Autoplay canvas figure (pixi-animate) — looping animation, scroll-driven, or one-shot playback.
5. Is this a static relationship, architecture, or flow? → Inline diagram (HTML/SVG/Mermaid, written directly by explainer).
6. Does this need photorealistic imagery, artistic illustration, or mood-setting? → Generated image (create-image).
7. Is this a comparison, before/after, or data presentation? → Choose based on whether animation adds value.

Use the [Renderer Capability Index](#renderer-capability-index) to assign each figure to a renderer. Use the [Selection Heuristics](#selection-heuristics) to map explanation types to renderer + pattern combinations.

Write per-figure visual decisions to `$WORKDIR/visual-strategy.md`. For each figure, specify: what it shows, which renderer, what visual metaphor, and what the reader should see or do.

See [references/metaphor-design.md](references/metaphor-design.md) for the process of mapping abstract concepts to concrete visual representations.

### Step 4: Plan the Structure

Assemble the full content plan. This is the blueprint that subagents and subsequent steps execute against.

**For all modes:**
- Define the narrative arc: opening hook → buildup → aha moment → consolidation → extension
- Write the figure list with per-figure specs (see [references/figure-specs.md](references/figure-specs.md) for the spec format)
- Outline each prose section: topic sentence, what it establishes, what figure follows, transition to next section

**Mode-specific structure:**

**Tutorial:** Follow the gradient of agency — opening is passive (prose + simple animation, reader observes), middle is guided (step-through, parameter sliders, reader tweaks), end is free (sandbox/playground, reader explores). Target 3-6 figures for a focused explanation.

**Report/Analysis:** Thesis → Evidence 1 (figure + interpretation) → Evidence 2 → ... → Synthesis → Implications. Figures are proof artifacts. Each figure is followed by a consolidation paragraph explaining what it proves.

**Presentation:** Slide-by-slide outline: slide number, layout name (from [references/slide-layouts.md](references/slide-layouts.md)), heading, content summary, whether a figure/image is needed. Apply deck rhythm rules and content density limits per layout. Plan image prompts for generated images. Target the image budget:

| Slides | Generated images | Hero backgrounds | Inset images |
|--------|-----------------|------------------|-------------|
| 5-8    | 3-5             | 1-2              | 2-3          |
| 9-15   | 5-8             | 2-3              | 3-5          |
| 16-25  | 8-12            | 3-5              | 5-7          |

**Paper/Article:** Section outline with per-section thesis, key evidence, figures, and transitions. Introduction establishes the question. Body sections build the argument. Conclusion synthesizes and points forward.

Write the full plan to `$WORKDIR/plan.md`. Present a summary to the user for approval before implementing. The plan file is the source of truth — subagents read it directly.

### Step 5: Implement

Execute the plan. Write prose first (the backbone), then add figures by invoking renderer skills.

**Prose first:** Write all text sections as drafts to `$WORKDIR/draft-prose.md`. Focus on:
- Opening hook (see [references/prose-guide.md](references/prose-guide.md))
- Transition sentences between figures ("Now that you've seen X, notice how Y...")
- Consolidation paragraphs after each figure (summarizing what it demonstrated)
- Progressive vocabulary (match language to the reader's growing understanding)

**Then figures:** For each figure in the plan, write a figure spec and invoke the appropriate renderer skill. See [references/figure-specs.md](references/figure-specs.md) for the complete spec format and examples.

**Mode-specific implementation:**

**Tutorial:** For tutorials with interactive or animated figures, use the HTML shell from [references/html-template.md](references/html-template.md) — it has the per-figure IIFE architecture, shared utilities, and minimal base styles. For text-heavy tutorials with simple embedded figures, use [references/report-template.md](references/report-template.md). Alternate prose and figures in both cases. Populate figures via pixi-animate after the prose backbone is stable.

**Interactive HTML Essay:** Use [references/html-template.md](references/html-template.md) as the shell. Write the full prose backbone first (all `<p>`, `<h2>`, `<figure>` placeholders). Then invoke pixi-animate for each canvas figure — pass the figure spec and receive the IIFE implementation. Insert each returned IIFE as a `<script>` immediately after its `<figure>`. Do not implement PixiJS inline; all canvas rendering goes through pixi-animate. Apply the [Cross-Cutting Principles for Interactive Output](#cross-cutting-principles-for-interactive-output) throughout.

**Report/Analysis:** Use the report template for the HTML shell. Write the full narrative with figure placeholders, then generate figures. Use card depth tiers for visual hierarchy — hero cards for key findings, default cards for evidence sections, collapsible sections for appendix material. Caption each figure with what it shows and what to notice.

**Presentation:** The explainer IS the slide renderer — it writes the final HTML/CSS deck directly, slotting in assets from renderer skills.
1. Write the HTML shell using [references/slide-template.md](references/slide-template.md) — viewport-fitting CSS, responsive typography, SlidePresentation controller.
2. Choose a layout per slide from [references/slide-layouts.md](references/slide-layouts.md) — 19 named layouts with content limits.
3. Add entrance animations from [references/slide-animations.md](references/slide-animations.md) — reduced-motion-first, per-layout recommendations.
4. Generate images via create-image and animations via pixi-animate, then slot them into the appropriate slides.
5. Verify viewport fitting: every slide must fit exactly in `100vh`/`100dvh` with no scrolling.

**Paper/Article:** Use the report template for the HTML shell. Write the full draft with section navigation. Insert figure references inline. Generate figures after the prose is stable. Use Mermaid diagrams for architecture and flow diagrams (see report template's Mermaid integration guide).

**Parallelizing figures with subagents:** For content with 3+ figures, spawn subagents to implement figures in parallel. Each subagent needs exactly:
- The path to `$WORKDIR/plan.md` with instructions to read their figure's spec from it
- The figure ID and where it appears in the narrative
- Which renderer skill to invoke and with what spec
- Where to write output: `$WORKDIR/fig-N.{ext}`

The main agent waits for all subagents, then assembles the final output by inserting figures into the prose backbone. The plan file is the single source of truth — do not reproduce the full spec in the subagent message, point to the file.

### Step 6: Refine

Review the assembled output. The goal is not to add more — it is to cut what is not earning its place and fix what is misleading.

**Key questions:**
- Does the opening hook create urgency? Would a cold reader keep reading?
- Does each figure earn its place — or could a well-written paragraph do the same job?
- Does the aha moment land? Is the reader adequately prepared for it by what came before?
- Does vocabulary stay calibrated to the audience's growing understanding throughout?
- Are transitions between sections genuinely bridging ideas, or just announcing topic changes?

**Mode-specific checks:**

**Tutorial:** Test every interaction. Verify the gradient of agency works. Confirm off-screen canvases are paused.

**Presentation:** Verify every slide fits the viewport (`100vh`/`100dvh`, `overflow: hidden`). Check content density limits per layout (see [references/slide-layouts.md](references/slide-layouts.md)). Confirm deck rhythm. Verify responsive breakpoints (700px, 600px, 500px height; 768px, 600px width).

**Report/Analysis:** Verify claims are supported by the figures cited. Check that evidence is presented before conclusions.

**Paper/Article:** Read the introduction and conclusion back-to-back — do they frame the same argument?

Write refinement notes to `$WORKDIR/review.md`. Iterate.

---

## Renderer Capability Index

Consult this table when deciding which renderer to use for a figure. Renderer skills (pixi-animate, create-image) handle implementation details — this skill specifies *what* to render, not *how*. Inline diagrams are written directly by the explainer.

| Renderer | Skill / Method | Strengths | Use When |
|----------|----------------|-----------|----------|
| PixiJS Canvas (interactive) | pixi-animate | Real-time simulation, drag interaction, parameter sweep, step-through, scroll-driven animation | Reader needs to *feel* the concept through manipulation; temporal processes; emergent behavior; algorithm step-throughs |
| PixiJS Canvas (animated) | pixi-animate | Autoplay animations, looping demos, scroll-driven sequences, animated diagrams, one-shot playbacks | Concept benefits from motion but not user input; showing a process unfold; animated comparisons; visual rhythm in a piece |
| AI-generated images | create-image | Photorealistic scenes, artistic illustrations, icons, mockups, mood-setting visuals | Visual metaphors that cannot be diagrammed; concrete imagery for abstract concepts; presentation hero images; editorial illustrations |
| Inline diagram | explainer (direct) | Flowcharts, architecture overviews, ER diagrams, annotated static visuals, data tables | Spatial relationships, structure, one-shot understanding; no animation needed; static comparison. Written as HTML/SVG or Mermaid directly in the output — no separate skill invocation. |
| No figure | — | Clear prose | The point can be stated in 1-2 sentences; adding a visual would slow the reader down; the concept is already intuitive |

**Combining renderers in a single piece:** Most tutorials and reports use 2-3 renderer types. A typical tutorial might open with a generated image (mood-setting), use pixi-animate for the core interactive and animated figures, and include inline diagrams for architecture context. A presentation might use generated images for hero slides and pixi-animate for one key animated or interactive moment.

---

## Selection Heuristics

Map what you are explaining to which renderer and pattern combination. These heuristics are starting points — combine them when multiple apply.

| Explanation Type | Renderer | Pattern Combination |
|-----------------|----------|-------------------|
| Sequential process (algorithm steps, pipelines) | pixi-animate | Step-through playback + progressive assembly |
| Constraint/filtering system (firewalls, query planners) | pixi-animate | Flow/token animation + parameter slider |
| Emergent behavior (flocking, cellular automata, markets) | pixi-animate | Physics simulation + sandbox/playground |
| Architecture/layers (network stack, compilers) | pixi-animate (animated) or inline diagram | Animated layer-by-layer assembly, or static annotated diagram if motion adds nothing |
| Algorithm comparison (sorting, pathfinding) | pixi-animate | Linked multi-view + algorithmic expansion |
| Spatial/geographic (signal propagation, mapping) | pixi-animate | Direct manipulation + propagation waves |
| Mathematical relationship (functions, transforms) | pixi-animate | Parameter slider + continuous deformation + inline reactive text |
| Temporal process (scheduling, event loops) | pixi-animate | Temporal scrubber + trajectory tracing |
| Data narrative (trends, distributions, stories) | pixi-animate | Scroll-driven progression + narrative parallax + color-field shifts |
| System dynamics (load balancing, feedback loops) | pixi-animate | Physics simulation + linked multi-view |
| Structural overview (API surface, type hierarchy) | inline diagram | Annotated HTML/SVG or Mermaid diagram |
| Abstract concept (justice, entropy, technical debt) | create-image + prose | Visual metaphor image + explanatory prose |
| Mood/context setting (opening a presentation or article) | create-image | Hero image or editorial illustration |
| Comparison/before-after | pixi-animate | Animated toggle or side-by-side with transition |
| Process with branching (decision trees, routing) | pixi-animate (animated) or inline diagram | Animated path-highlight walkthrough, or static flowchart if branching is simple |

When multiple heuristics apply, combine them. A load balancer explanation might use pixi-animate for the core simulation (physics simulation + parameter slider + linked multi-view), an inline diagram for the architecture overview, and create-image for the opening hero image.

---

## Cross-Cutting Principles for Interactive Output

When the output format is an interactive HTML essay or a tutorial with interactive figures, these six rules apply to every canvas figure. Full descriptions with do/don't examples in pixi-animate's `references/composition-patterns.md`.

1. **Gradient of Agency** — Guided first, parameter tweaking second, sandbox last. The reader earns each new level of control.
2. **Immediacy** — Feedback within one frame (~16ms). No perceptible delay between interaction and visual response.
3. **Reversibility** — Every interaction undoable. Reset buttons on every figure.
4. **Object Constancy** — Same entity keeps same color, position, and shape across state changes.
5. **Minimal Chrome** — Direct manipulation over control panels. The visualization IS the interface.
6. **Progressive Complexity** — Simple first. Controls appear as the reader scrolls deeper into the piece.

## PixiJS Rendering Constraints

When output is an interactive HTML essay or tutorial with PixiJS figures, every canvas must satisfy:

- **CDN**: `pixi.js-legacy` v7.3.2 (`https://pixijs.download/v7.3.2/pixi-legacy.min.js`). Pin the version.
- **`forceCanvas: true`** — no WebGL; avoids context limits with multiple figures on one page.
- **`backgroundAlpha: 0`** — transparent canvas, blends with page background.
- **`autoStart: false`** — manual ticker control; start only when the simulation is ready.
- **IntersectionObserver** pauses off-screen tickers (critical for multi-figure pages).
- **`prefers-reduced-motion`** — check before any animation; show final state as static fallback.
- **Native HTML controls** (`<input type="range">`, `<button>`, `<select>`) — never canvas-rendered.
- **`resizeTo: element`** + `ResizeObserver` for responsive layout; `autoDensity: true` for retina.

Implementation boilerplate for all of the above is in [references/html-template.md](references/html-template.md) (shared `Simulation` class and `observeVisibility` function). The explainer does not implement these directly — it specifies figures and delegates to pixi-animate.

---

## Reference Files

Load on demand — not all are needed for every explanation.

| File | Load When | Contents |
|------|-----------|----------|
| [references/metaphor-design.md](references/metaphor-design.md) | Designing visual metaphors (Step 3) | Process for mapping abstract concepts to concrete visuals; metaphor families; anti-patterns |
| [references/prose-guide.md](references/prose-guide.md) | Writing explanatory prose (Steps 4-5) | Narrative arc templates; transition patterns; opening hooks; progressive vocabulary; presentation-specific prose rules |
| [references/figure-specs.md](references/figure-specs.md) | Specifying figures for renderers (Steps 4-5) | Spec format; good vs bad spec examples; cross-figure dependency patterns; completeness checklist |
| [references/html-template.md](references/html-template.md) | Building interactive HTML essays or tutorials with PixiJS figures (Step 5) | Minimal HTML shell; per-figure IIFE architecture; shared Simulation class and utilities; base styles |
| [references/report-template.md](references/report-template.md) | Building reports, articles, and text-heavy tutorials (Step 5) | Minimal prose-first HTML shell; single-column article layout; data tables; callout boxes; Mermaid integration |
| [references/slide-template.md](references/slide-template.md) | Building slide decks (Step 5, Presentation mode) | HTML shell; base CSS; viewport fitting; SlidePresentation controller |
| [references/slide-layouts.md](references/slide-layouts.md) | Choosing slide layouts (Steps 4-5, Presentation mode) | 19 named layouts with HTML, CSS, and content limits |
| [references/slide-animations.md](references/slide-animations.md) | Adding slide animations (Step 5, Presentation mode) | Entrance animations; stagger; image animations; reduced-motion-first authoring |
