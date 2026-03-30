# Figure Specifications

How to write figure specifications that renderer skills can execute. A figure spec is the contract between the explainer (content architect) and the renderer (implementation skill).

## The Spec Format

Every figure spec includes these fields:

```yaml
figure_id: fig-01
title: "Hash function distribution"
concept: What abstract concept this figure visualizes
metaphor: What concrete visual representation is used (from metaphor-design.md)
renderer: pixi-animate | create-image | inline-diagram
placement: Where in the narrative this figure appears and what prose surrounds it

# What the reader experiences
reader_sees: What is visible on screen (shapes, colors, labels, layout)
reader_does: What interactions are available (drag, slider, click, scroll, observe)
reader_learns: What insight this figure produces — the "so what"

# For pixi-animate (interactive figures)
interaction_patterns:
  - pattern_name (from pixi-animate pattern index)
animation_patterns:
  - pattern_name (from pixi-animate pattern index)
composition_pattern: pattern_name (explain-then-explore, scrollytelling, etc.)
controls:
  - name: "Parameter name"
    type: slider | toggle | button | select
    range: [min, max] or [option_a, option_b]
    default: value
    label: "Human-readable label"

# For inline-diagram (static diagrams — written directly by explainer)
diagram_format: html-svg | mermaid
diagram_type: flowchart | architecture | comparison | timeline | annotated
elements: List of key elements to include
annotations: Labels, callouts, and highlights

# For create-image (generated images)
prompt_subject: What the image depicts
prompt_style: Aesthetic and mood guidance
aspect_ratio: "16:9" | "1:1" | "4:3" | "3:2"
image_role: hero-background | inset-illustration | icon | editorial

# Cross-figure dependencies
builds_on: [fig-XX] — figures that must be seen first
establishes_for: [fig-XX] — figures that build on this one
shared_visual_language: Colors, shapes, or metaphors that must match other figures
```

## Good Specs vs Bad Specs

### Example 1: Interactive figure (pixi-animate)

**Bad spec:**
```yaml
figure_id: fig-02
title: "Load balancer"
concept: Load balancing
renderer: pixi-animate
reader_sees: A load balancer visualization
reader_does: Interact with it
reader_learns: How load balancing works
```

This spec is useless. The renderer has no idea what to build. "A load balancer visualization" could be anything. "Interact with it" specifies no controls. "How load balancing works" does not identify a specific insight.

**Good spec:**
```yaml
figure_id: fig-02
title: "Request distribution under different algorithms"
concept: How load balancing algorithms distribute incoming requests across servers
metaphor: >
  Requests are colored particles falling from a spawn point at the top.
  Servers are rectangular boxes at the bottom with health bars (fill level = current load).
  The load balancer is a distribution point where particles split toward server boxes.
  Particle color indicates request type (blue = fast, orange = slow).
renderer: pixi-animate
placement: >
  After prose explaining that different algorithms make different tradeoffs.
  Before the consolidation paragraph that summarizes when to use each algorithm.

reader_sees: >
  5 server boxes at the bottom with health bar fills. Particles spawn at the top
  and animate toward servers. One server is configured as "slow" (processes particles
  at half speed). Distribution changes visibly when algorithm is switched.
reader_does: >
  Toggle between round-robin, least-connections, and random algorithms.
  Adjust request rate with a slider (1-100 RPS). Observe how the slow server
  becomes a bottleneck under round-robin but not under least-connections.
reader_learns: >
  Round-robin ignores server health, causing slow servers to accumulate load.
  Least-connections routes away from overloaded servers automatically.
  The difference only matters under load — at low RPS, all algorithms look similar.

interaction_patterns:
  - toggle-switch (algorithm selector)
  - parameter-slider (request rate)
animation_patterns:
  - flow-token-animation (request particles)
  - physics-simulation (particle movement)
composition_pattern: explain-then-explore
controls:
  - name: algorithm
    type: select
    range: [round-robin, least-connections, random]
    default: round-robin
    label: "Algorithm"
  - name: rps
    type: slider
    range: [1, 100]
    default: 20
    label: "Requests/sec"

builds_on: []
establishes_for: [fig-03]
shared_visual_language: >
  Server boxes use the same color scheme as fig-01 (architecture diagram).
  Blue = healthy, orange = degraded, red = overloaded.
```

### Example 2: Static diagram (inline-diagram)

**Bad spec:**
```yaml
figure_id: fig-01
title: "System architecture"
renderer: inline-diagram
diagram_type: architecture
elements: The system components
```

**Good spec:**
```yaml
figure_id: fig-01
title: "Request lifecycle through the load balancer"
concept: The path a request takes from client to server and back
metaphor: >
  Left-to-right flow diagram. Client on the left, load balancer in the center,
  server pool on the right. Arrows show request and response paths.
renderer: inline-diagram
placement: >
  Opening figure. Establishes the architecture before the interactive figures
  let the reader manipulate individual components.

diagram_format: html-svg
diagram_type: architecture
elements:
  - Client (browser icon, left side)
  - Load balancer (central box, highlighted — this is the focus)
  - Server pool (3 server boxes, right side, labeled A/B/C)
  - Request arrow (client → LB, blue)
  - Distribution arrows (LB → each server, dashed, showing the selection point)
  - Response arrow (server → client, green, return path)
annotations:
  - Callout on distribution arrows: "Algorithm decides which server"
  - Label on server B: "Slow server (half speed)"

reader_sees: The full request lifecycle in one static view
reader_learns: Where the load balancer sits in the architecture and what decision it makes

builds_on: []
establishes_for: [fig-02, fig-03]
shared_visual_language: >
  Server colors: blue = healthy, orange = degraded.
  These colors carry through to fig-02 (interactive) and fig-03 (comparison).
```

### Example 3: Generated image (create-image)

**Bad spec:**
```yaml
figure_id: fig-00
title: "Hero image"
renderer: create-image
prompt_subject: A load balancer
```

**Good spec:**
```yaml
figure_id: fig-00
title: "Opening hero — the sorting hat of the internet"
concept: Visual metaphor establishing that a load balancer is a decision-maker routing traffic
metaphor: >
  A glowing control tower at a crossroads, with streams of light (requests)
  flowing in from one direction and splitting into multiple paths toward
  distant server buildings.
renderer: create-image
placement: >
  Hero image at the very top of the piece, before any text.
  Sets the mood and establishes the metaphor that will be refined
  into concrete diagrams in subsequent figures.

prompt_subject: >
  A glowing control tower at a neon-lit crossroads at night. Streams of
  blue light flow from the left toward the tower, then split into three
  paths heading toward three distinct buildings on the right. The scene
  is atmospheric, cinematic, and slightly futuristic.
prompt_style: >
  Cinematic digital art, dark background with strong blue and purple neon
  accents, volumetric lighting, slight fog, depth of field
aspect_ratio: "16:9"
image_role: hero-background

reader_sees: An atmospheric image that primes the "traffic routing" mental model
reader_learns: Nothing technical yet — this is mood-setting and metaphor-priming

builds_on: []
establishes_for: [fig-01]
shared_visual_language: >
  Blue color for incoming traffic carries forward to all subsequent figures.
```

## Cross-Figure Dependencies

Figures in a multi-figure explanation are not independent. They build on each other. Specify dependencies explicitly so that:

1. **Visual language is consistent.** If fig-01 uses blue for "healthy server," fig-03 must use the same blue. Specify shared colors, shapes, and metaphors in `shared_visual_language`.

2. **Conceptual dependencies are clear.** If fig-03 only makes sense after seeing fig-01 and fig-02, list them in `builds_on`. The renderer can then include a brief recap or visual anchor connecting back to those figures.

3. **Parallelization is safe.** Subagents implementing figures in parallel need to know what visual language to reuse. The `shared_visual_language` field is the contract — define it in the first figure and reference it in subsequent ones.

### Dependency patterns

**Linear chain:** fig-01 → fig-02 → fig-03. Each builds on the previous. Common in tutorials.

**Hub and spoke:** fig-01 (architecture overview) establishes the visual language. fig-02, fig-03, fig-04 each zoom into one component. Common in system explanations.

**Parallel then synthesis:** fig-01 and fig-02 show two approaches independently. fig-03 compares them side by side. Common in comparison pieces.

**Progressive zoom:** fig-01 shows the big picture. fig-02 zooms into one area. fig-03 zooms into a detail within that area. Common in spatial explanations.

## Spec Completeness Checklist

Before passing a spec to a renderer, verify:

- [ ] `concept` states what abstract idea is being visualized (not just "the system")
- [ ] `metaphor` describes concrete visual mapping (not just "a visualization")
- [ ] `reader_sees` describes specific visual elements (shapes, colors, layout)
- [ ] `reader_does` lists specific interactions or states "observe only"
- [ ] `reader_learns` identifies a specific insight (not "how it works")
- [ ] `controls` have concrete ranges and defaults (no open-ended parameters)
- [ ] `shared_visual_language` is specified if this figure shares a visual system with others
- [ ] `placement` describes what prose comes before and after
