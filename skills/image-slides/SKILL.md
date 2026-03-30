---
name: image-slides
description: >-
  Create stunning, animation-rich HTML presentations with AI-generated images,
  from scratch or by converting PowerPoint files. Uses create-image to produce
  custom visuals matching the selected aesthetic. Helps non-designers discover
  their aesthetic through visual exploration rather than abstract choices.
  Triggers: "create presentation with images", "image slides", "slide deck
  with generated images", "illustrated slides", "make a deck with photos".
---

# Image-Rich Presentations

Create zero-dependency, animation-rich HTML presentations that run entirely in the browser. This skill helps non-designers discover their preferred aesthetic through visual exploration ("show, don't tell"), then generates production-quality slide decks with custom AI-generated images per slide.

## Core Philosophy

1. **Zero Dependencies** — Single HTML files with inline CSS/JS. No npm, no build tools. Generated images live in a companion assets directory.
2. **Show, Don't Tell** — People don't know what they want until they see it. Generate visual previews, not abstract choices.
3. **Distinctive Design** — Avoid generic "AI slop" aesthetics. Every presentation should feel custom-crafted.
4. **Production Quality** — Code should be well-commented, accessible, and performant.
5. **Viewport Fitting (CRITICAL)** — Every slide MUST fit exactly within the viewport. No scrolling within slides, ever. This is non-negotiable.
6. **Images Enhance, Not Dominate** — Generated images serve the content. They set mood, illustrate concepts, and reinforce the aesthetic — they don't replace substance.

## Skill Composition

| Skill | Where used |
|---|---|
| **create-image** | Phase 2 (style preview images), Phase 3 (image planning previews), Phase 4 (image generation) |
| **pixi-animate** | PixiJS Canvas 2D animations, drawn visuals, and interactive widgets on slides. Use for animated diagrams, illustrated processes, live data viz, parameter explorers, and mini-simulations. |

> **Locating sibling skills:** create-image and pixi-animate are sibling skill directories. At the start of the workflow, resolve their absolute paths (e.g., via `find` or by navigating from this skill's directory to `../create-image` or `../pixi-animate`). Store those paths and use them for every invocation. All image output paths (`-o`) must also be absolute.

### PixiJS Canvas on Slides

Invoke the **pixi-animate** skill for pattern selection and PixiJS implementation. Two usage tiers:

**Animations & drawn visuals** — use liberally. Animated diagrams, illustrated processes, data visualizations rendered via PixiJS Canvas 2D. These replace static images or CSS-only effects with richer, more precise visuals. No user interaction required; they animate on slide entry like any other entrance effect.

**Interactive widgets** — use selectively (tunable per deck). Parameter sliders, simulations, direct manipulation. These demand user attention and break the passive viewing flow. Default to 1-2 per deck unless the user requests more interactivity.

Both tiers share these constraints within viewport-locked slides:

- **Canvas height**: max `55vh` to leave room for heading, text, and any controls
- **Controls** (interactive tier only): positioned below the canvas, within the slide's `overflow: hidden` boundary
- **Off-screen pausing**: required (IntersectionObserver), same as pixi-animate prescribes
- **Reduced motion**: static fallback must still convey the concept

During style discovery (Phase 2), ask: *"How much interactivity? Animated visuals only, a few interactive moments, or highly interactive throughout?"* and calibrate accordingly.

---

## CRITICAL: Viewport Fitting Requirements

**This section is mandatory for ALL presentations. Every slide must be fully visible without scrolling on any screen size.**

### The Golden Rule

```
Each slide = exactly one viewport height (100vh/100dvh)
Content overflows? → Split into multiple slides or reduce content
Never scroll within a slide.
```

### Content Density Limits

To guarantee viewport fitting, enforce these limits per slide:

| Slide Type | Maximum Content |
|------------|-----------------|
| Title slide | 1 heading + 1 subtitle + optional tagline |
| Content slide | 1 heading + 4-6 bullet points OR 1 heading + 2 paragraphs |
| Feature grid | 1 heading + 6 cards maximum (2x3 or 3x2 grid) |
| Code slide | 1 heading + 8-10 lines of code maximum |
| Quote slide | 1 quote (max 3 lines) + attribution |
| Image slide | 1 heading + 1 image (max 60vh height) |
| Hero image slide | Full-bleed background image + 1 heading + 1 subtitle (overlaid) |

**If content exceeds these limits → Split into multiple slides**

### Required CSS Architecture

See [references/base-css.md](references/base-css.md) for the complete base CSS that MUST be included in every presentation. Key `:root` custom properties:

- `--title-size`, `--h2-size`, `--h3-size` — Typography scale (all `clamp()`)
- `--body-size`, `--small-size` — Body text scale
- `--slide-padding`, `--content-gap`, `--element-gap` — Spacing scale
- `.slide-bg`, `.slide-image`, `.slide-figure` — Image treatment classes
- Responsive breakpoints for heights 700px, 600px, 500px and width 600px
- Reduced-motion media query

### Overflow Prevention Checklist

Before generating any presentation, mentally verify:

1. ✅ Every `.slide` has `height: 100vh; height: 100dvh; overflow: hidden;`
2. ✅ All font sizes use `clamp(min, preferred, max)`
3. ✅ All spacing uses `clamp()` or viewport units
4. ✅ Content containers have `max-height` constraints
5. ✅ Images have `max-height: min(50vh, 400px)` or similar
6. ✅ Grids use `auto-fit` with `minmax()` for responsive columns
7. ✅ Breakpoints exist for heights: 700px, 600px, 500px
8. ✅ No fixed pixel heights on content elements
9. ✅ Content per slide respects density limits
10. ✅ Background images use `.slide-bg` with preset filter (not raw unfiltered `<img>`)

### When Content Doesn't Fit

If you find yourself with too much content:

**DO:**
- Split into multiple slides
- Reduce bullet points (max 5-6 per slide)
- Shorten text (aim for 1-2 lines per bullet)
- Use smaller code snippets
- Create a "continued" slide

**DON'T:**
- Reduce font size below readable limits
- Remove padding/spacing entirely
- Allow any scrolling
- Cram content to fit

### Testing Viewport Fit

After generating, recommend the user test at these sizes:
- Desktop: 1920×1080, 1440×900, 1280×720
- Tablet: 1024×768, 768×1024 (portrait)
- Mobile: 375×667, 414×896
- Landscape phone: 667×375, 896×414

---

## Externalized State

**Do not accumulate plans, outlines, or intermediate artifacts in the conversation.** Write them to temporary files and reference those files in subsequent steps. This keeps the context window clean and allows progressive refinement — read a file back, improve it, write it again.

At the start of the workflow, create a unique working directory:

```bash
WORKDIR=$(mktemp -d)
```

Store `$WORKDIR` and use it for all intermediate files:

| Phase | File | Contents |
|-------|------|----------|
| 1 | `$WORKDIR/outline.md` | Slide-by-slide outline: slide number, layout, heading, content summary, image needed (y/n) |
| 2 | `$WORKDIR/style.md` | Selected preset, depth/motion choices, interactivity level, font/color notes |
| 3 | `$WORKDIR/image-plan.md` | Image prompt table: slide number, type, aspect ratio, full prompt |
| 5 | Target HTML file | Assembled output (written in chunks, not all at once) |

Each phase reads the previous phase's file, does its work, and writes the next file. Never reproduce the full outline or image plan inline in the conversation — summarize and point to the file. Subagents read these files directly.

---

## Phase 0: Detect Mode

First, determine what the user wants:

**Mode A: New Presentation**
- User wants to create slides from scratch
- Proceed to Phase 1 (Content Discovery)

**Mode B: PPT Conversion**
- User has a PowerPoint file (.ppt, .pptx) to convert
- Proceed to Phase 6 (PPT Extraction)

**Mode C: Existing Presentation Enhancement**
- User has an HTML presentation and wants to improve it
- Read the existing file, understand the structure, then enhance

---

## Phase 1: Content Discovery (New Presentations)

Before designing, understand the content. Ask via AskUserQuestion:

### Step 1.1: Presentation Context

**Question 1: Purpose**
- Header: "Purpose"
- Question: "What is this presentation for?"
- Options:
  - "Pitch deck" — Selling an idea, product, or company to investors/clients
  - "Teaching/Tutorial" — Explaining concepts, how-to guides, educational content
  - "Conference talk" — Speaking at an event, tech talk, keynote
  - "Internal presentation" — Team updates, strategy meetings, company updates

**Question 2: Slide Count**
- Header: "Length"
- Question: "Approximately how many slides?"
- Options:
  - "Short (5-10)" — Quick pitch, lightning talk
  - "Medium (10-20)" — Standard presentation
  - "Long (20+)" — Deep dive, comprehensive talk

**Question 3: Content**
- Header: "Content"
- Question: "Do you have the content ready, or do you need help structuring it?"
- Options:
  - "I have all content ready" — Just need to design the presentation
  - "I have rough notes" — Need help organizing into slides
  - "I have a topic only" — Need help creating the full outline

If user has content, ask them to share it (text, bullet points, images, etc.).

Once the outline is established, write it to `$WORKDIR/outline.md` with one entry per slide: slide number, layout type, heading, content summary, and whether an image is needed. This file is the source of truth for all subsequent phases.

---

## Phase 2: Style Discovery (Visual Exploration)

**CRITICAL: This is the "show, don't tell" phase.**

Most people can't articulate design preferences in words. Instead of asking "do you want minimalist or bold?", we generate mini-previews and let them react.

### How Users Choose Presets

Users can select a style in **two ways**:

**Option A: Guided Discovery (Default)**
- User answers mood questions
- Skill generates 3 preview files based on their answers
- User views previews in browser and picks their favorite
- This is best for users who don't have a specific style in mind

**Option B: Direct Selection**
- If user already knows what they want, they can request a preset by name
- Example: "Use the Bold Signal style" or "I want something like Dark Botanical"
- Skip to Phase 3 immediately

**Available Presets:**
| Preset | Vibe | Best For | Image Style |
|--------|------|----------|-------------|
| Bold Signal | Confident, high-impact | Pitch decks, keynotes | Bold, saturated, graphic |
| Electric Studio | Clean, professional | Agency presentations | Sleek, modern, studio-lit |
| Creative Voltage | Energetic, retro-modern | Creative pitches | Vibrant, textured, dynamic |
| Dark Botanical | Elegant, sophisticated | Premium brands | Soft light, warm tones, shallow DoF |
| Notebook Tabs | Editorial, organized | Reports, reviews | Warm neutral editorial photography |
| Pastel Geometry | Friendly, approachable | Product overviews | Bright, clean, geometric |
| Split Pastel | Playful, modern | Creative agencies | Bright, cheerful, clean |
| Vintage Editorial | Witty, personality-driven | Personal brands | Muted retro photography |
| Neon Cyber | Futuristic, techy | Tech startups | Cyberpunk, neon-lit, dark |
| Terminal Green | Developer-focused | Dev tools, APIs | Terminal-style, monochrome green |
| Swiss Modern | Minimal, precise | Corporate, data | Flat, geometric, minimal |
| Paper & Ink | Literary, thoughtful | Storytelling | Ink wash, textured, hand-drawn feel |
| Steampunk | Industrial, ornate, Victorian | Creative pitches | Brass/copper machinery, warm amber, clockwork |
| Futuristic Engineering | Technical, precise, sci-fi | Dev tools, APIs | Clean industrial, blueprint-like, metallic |
| Dark Fantasy | Mythic, atmospheric, epic | Storytelling, games | Dramatic landscapes, magical lighting, moody |

Full image prompt templates and CSS treatments for each preset are in [references/presets/](references/presets/) (one file per preset).

### Step 2.0: Style Path Selection

First, ask how the user wants to choose their style:

**Question: Style Selection Method**
- Header: "Style"
- Question: "How would you like to choose your presentation style?"
- Options:
  - "Show me options" — Generate 3 previews based on my needs (recommended for most users)
  - "I know what I want" — Let me pick from the preset list directly

**If "Show me options"** → Continue to Step 2.1 (Mood Selection)

**If "I know what I want"** → Show the full preset table, then ask:

**All 15 Presets:**

| # | Preset | Theme | Vibe |
|---|--------|-------|------|
| | **Dark themes** | | |
| 1 | Bold Signal | Dark | Confident, high-impact — saturated cards on black |
| 2 | Electric Studio | Dark | Clean, professional — sleek studio lighting |
| 3 | Creative Voltage | Dark | Energetic, retro-modern — vibrant textures |
| 4 | Dark Botanical | Dark | Elegant, sophisticated — soft light, warm tones |
| 5 | Neon Cyber | Dark | Futuristic, techy — cyberpunk neon glow |
| 6 | Terminal Green | Dark | Developer-focused — monochrome green terminal |
| 7 | Paper & Ink | Dark | Literary, thoughtful — ink wash, hand-drawn feel |
| 8 | Steampunk | Dark | Industrial, ornate — brass clockwork, warm amber |
| 9 | Futuristic Engineering | Dark | Technical, precise — blueprint-like, metallic |
| 10 | Dark Fantasy | Dark | Mythic, atmospheric — dramatic landscapes, magical lighting |
| | **Light themes** | | |
| 11 | Notebook Tabs | Light | Editorial, organized — paper look with colorful tabs |
| 12 | Pastel Geometry | Light | Friendly, approachable — bright pastels, geometric |
| 13 | Split Pastel | Light | Playful, modern — cheerful split-tone layouts |
| 14 | Vintage Editorial | Light | Witty, personality-driven — muted retro photography |
| 15 | Swiss Modern | Light | Minimal, precise — flat geometric, corporate-clean |

**Question: Pick a Preset**
- Header: "Preset"
- Question: "Which style would you like to use? (enter the name)"
- Options: (free text — match against preset names above)

(If user picks one, skip to Step 2.5. If unsure, proceed to guided discovery.)

### Step 2.1: Mood Selection (Guided Discovery)

**Question 1: Feeling**
- Header: "Vibe"
- Question: "What feeling should the audience have when viewing your slides?"
- Options:
  - "Impressed/Confident" — Professional, trustworthy, this team knows what they're doing
  - "Excited/Energized" — Innovative, bold, this is the future
  - "Calm/Focused" — Clear, thoughtful, easy to follow
  - "Inspired/Moved" — Emotional, storytelling, memorable
- multiSelect: true (can choose up to 2)

### Step 2.2: Generate Style Previews

Based on their mood selection, generate **3 distinct style previews** as mini HTML files in a temporary directory. Each preview should be a single title slide showing:

- Typography (font choices, heading/body hierarchy)
- Color palette (background, accent, text colors)
- Animation style (how elements enter)
- Overall aesthetic feel
- **A sample generated image** matching the preset's aesthetic — generate via:
  ```bash
  cd {create-image-dir} && uv run python scripts/main.py "<aesthetic-prompt>" \
    -o {absolute-path-to-preview-assets}/preview-{style-name}.png --fast
  ```

**Preview Styles to Consider (pick 3 based on mood):**

| Mood | Style Options |
|------|---------------|
| Impressed/Confident | "Bold Signal", "Electric Studio", "Dark Botanical", "Futuristic Engineering" |
| Excited/Energized | "Creative Voltage", "Neon Cyber", "Split Pastel", "Steampunk" |
| Calm/Focused | "Notebook Tabs", "Paper & Ink", "Swiss Modern" |
| Inspired/Moved | "Dark Botanical", "Vintage Editorial", "Pastel Geometry", "Dark Fantasy" |

**IMPORTANT: Never use these generic patterns:**
- Purple gradients on white backgrounds
- Inter, Roboto, or system fonts
- Standard blue primary colors
- Predictable hero layouts

**Instead, use distinctive choices:**
- Unique font pairings (Clash Display, Satoshi, Cormorant Garamond, DM Sans, etc.)
- Cohesive color themes with personality
- Atmospheric backgrounds (gradients, subtle patterns, depth)
- Signature animation moments

### Step 2.3: Present Previews

Create the previews in: `.claude-design/slide-previews/`

```
.claude-design/slide-previews/
├── style-a.html   # First style option
├── style-b.html   # Second style option
├── style-c.html   # Third style option
└── assets/        # Preview images (generated with --fast)
```

Each preview file should be:
- Self-contained (inline CSS/JS)
- A single "title slide" showing the aesthetic, with a sample generated image
- Animated to demonstrate motion style
- ~50-100 lines, not a full presentation

Present to user:
```
I've created 3 style previews for you to compare:

**Style A: [Name]** — [1 sentence description]
**Style B: [Name]** — [1 sentence description]
**Style C: [Name]** — [1 sentence description]

Open each file to see them in action:
- .claude-design/slide-previews/style-a.html
- .claude-design/slide-previews/style-b.html
- .claude-design/slide-previews/style-c.html

Take a look and tell me:
1. Which style resonates most?
2. What do you like about it?
3. Anything you'd change?
```

Then use AskUserQuestion:

**Question: Pick Your Style**
- Header: "Style"
- Question: "Which style preview do you prefer?"
- Options:
  - "Style A: [Name]" — [Brief description]
  - "Style B: [Name]" — [Brief description]
  - "Style C: [Name]" — [Brief description]
  - "Mix elements" — Combine aspects from different styles

If "Mix elements", ask for specifics.

### Step 2.5: Depth & Motion (Universal — both paths)

**Ask this after the preset is confirmed, regardless of whether the user took the guided or direct path.**

Canvas 2D atmosphere (floating particles, wireframes) is a natural fit for some presets and feels forced on others. Default based on the preset:

**Dark/tech presets — Canvas 2D is ON by default (ask to opt out):**

| Preset | Default effect |
|--------|---------------|
| Futuristic Engineering | Floating blue particles, title + closing slides |
| Neon Cyber | Cyan/magenta particle starfield, title + closing slides |
| Terminal Green | Slow green dot rain, title slide only |
| Dark Fantasy | Drifting ember particles, title + closing slides |
| Bold Signal | Subtle white particles, title slide only |
| Creative Voltage | Fast colored sparks, title slide only |
| Steampunk | Slow rising smoke particles, title slide only |

For these, ask:

**Question: Depth & Motion**
- Header: "Particles"
- Question: "Canvas 2D particles are recommended for [Preset Name] — subtle floating effect on the title and closing slides. Include them?"
- Options:
  - "Yes, add particles (recommended)" — Canvas 2D on title + closing (2 slides max)
  - "Skip particles" — CSS entrance animations only

**All other presets — Canvas 2D is OFF by default (ask to opt in):**

**Question: Depth & Motion**
- Header: "Motion"
- Question: "Would you like subtle Canvas 2D atmosphere (floating particles or wireframes) on the title slide?"
- Options:
  - "Keep it flat (recommended)" — CSS animations only; cleaner for this style
  - "Add subtle particles" — Atmospheric Canvas 2D on title slide only

**If Canvas 2D is confirmed**, the [3D & Canvas Enhancements](#3d--canvas-enhancements) decision framework activates during Phase 5 generation.

> **Note on Three.js:** Three.js (textured 3D models, advanced shaders, ~660KB) is never added by default. It requires an explicit user request (e.g., "add a rotating 3D globe" or "I want a Three.js background"). If the user requests it, confirm the zero-dependency trade-off before proceeding.

Write all style decisions to `$WORKDIR/style.md`: preset name, depth/motion choice, interactivity level, font pairing, color palette.

---

## Phase 3: Plan Images

For each slide in the outline, decide what images to generate. This phase runs after style selection and before HTML generation.

**Image budget by deck length:**

| Slides | Generated images | Hero backgrounds | Inset images |
|--------|-----------------|------------------|-------------|
| 5-8    | 3-5             | 1-2              | 2-3          |
| 9-15   | 5-8             | 2-3              | 3-5          |
| 16-25  | 8-12            | 3-5              | 5-7          |

Not every slide needs a generated image. Let text, whitespace, and layout do the work.

### Does this slide need a generated image?

| Slide type | Image? | Rationale |
|---|---|---|
| Title slide | Yes | Hero image sets the tone |
| Section divider | Yes | Visual break, reinforces theme |
| Feature/concept highlight | Yes | Illustrates the point |
| Bullet list | Maybe | Only if bullets are sparse and a visual adds clarity |
| Code/data slide | No | Code and data are the visual |
| Quote slide | Maybe | Background image can enhance mood |

### Image type per slide

| Type | Class | Aspect ratio | Use |
|---|---|---|---|
| **Hero background** | `.slide-bg` | 16:9 | Full-bleed behind text with dark/light overlay |
| **Inset illustration** | `.slide-image` | 1:1 or 4:3 | Beside or below text content |
| **Scene/photo** | `.slide-image` | 16:9 or 3:2 | Standalone visual with caption |
| **Icon** | `.slide-image` | 1:1 | Small decorative element |

### Draft Gemini Prompts

For each image, compose the prompt by combining:
1. The **slide-specific subject** (what the image depicts)
2. The **preset's base prompt modifier** (aesthetic, lighting, mood — from [presets/{preset}.md](references/presets/))
3. The **image-type template** (backgrounds, heroes, icons — from [presets/{preset}.md](references/presets/))

Write the full prompt list as a table:

```
| Slide | Type | Aspect | Prompt |
|-------|------|--------|--------|
| 1     | hero-bg | 16:9 | Generate a photo of ... |
| 3     | inset   | 1:1  | Create an image of ... |
```

Write the full image plan to `$WORKDIR/image-plan.md`. Present a summary to the user for approval before generating. Subagents and Phase 4 read this file directly.

---

## Phase 4: Generate Images

After the user approves the image plan, generate all images using create-image.

### Setup

Create an assets directory alongside where the presentation HTML will be saved:

```
{presentation-name}-assets/
├── slide-01-hero.png
├── slide-03-concept.png
└── ...
```

### Generation

For each image in the plan, invoke create-image using the absolute path resolved during setup (see [Skill Composition](#skill-composition)):

```bash
cd {create-image-dir} && uv run python scripts/main.py "<prompt>" \
  -o {absolute-path-to-assets-dir}/slide-{NN}-{description}.png \
  --aspect-ratio {ratio}
```

Where:
- `{create-image-dir}` — absolute path to the `create-image` sibling skill directory
- `{absolute-path-to-assets-dir}` — absolute path to the presentation's `{name}-assets/` directory

#### Model selection

| Context | Flag | Rationale |
|---|---|---|
| Style previews (Phase 2) | `--fast` | Speed; user is comparing aesthetics |
| Preview / iteration | `--fast` | Speed; user is reviewing compositions |
| Final generation | *(default — Pro)* | Quality; final output |

#### Naming convention

`slide-{NN}-{description}.png` where:
- `{NN}` is the zero-padded slide number
- `{description}` is a short kebab-case label (e.g., `hero`, `concept-diagram`, `team-photo`)

### Error handling

- If generation fails, retry once. If it fails again, note the slide and continue with remaining images.
- After all images are generated, report any failures to the user and offer to retry or skip.

**If image generation fails:**
1. Retry once with a simplified prompt (remove style modifiers, keep subject only)
2. If still failing, substitute with a CSS-only alternative:
   - For hero backgrounds: use a CSS `linear-gradient` matching the preset's color palette
   - For inset images: skip the image and use the text-only variant of the layout
3. Never leave a broken `<img>` tag — always remove or replace
4. Note the failure in the delivery summary so the user can regenerate manually

---

## 3D & Canvas Enhancements

Most 3D in presentations is gimmicky. A rotating cube does not make revenue numbers more compelling. Use Canvas 2D atmosphere for dark/tech presets (default on — see Step 2.5); use Three.js only when the user explicitly requests it.

### Tier System

| Tier | What | Cost | Rule |
|------|------|------|------|
| **1: CSS 3D Transforms** | Parallax depth, card flips, layer separation | Zero JS | Use freely |
| **2: Canvas 2D** | Particles, wireframes, dot-globe | ~30-80 lines JS | Use strategically |
| **3: Three.js CDN** | Textured models, advanced shaders | ~660KB, breaks zero-dependency | Explicit user opt-in only |

### Decision Framework

| Slide Type | 3D Treatment |
|---|---|
| Title slide | Floating particles OR starfield (atmospheric) |
| Section divider | Rotating wireframe (one-off, thematic) |
| Architecture slide | CSS 3D layer separation |
| Geographic data | Dot-globe (Canvas 2D) |
| Data/charts | **NEVER 3D.** Always flat 2D. |
| Content slide | No 3D. Let content breathe. |
| Closing slide | Match title slide for bookend effect |

### Critical Constraints

- **Visibility-aware animation:** IntersectionObserver to pause Canvas animations on non-visible slides. Non-negotiable.
- **30fps throttling:** Canvas 2D effects throttled to 30fps. Presentations are not games.
- **Reduced motion:** Check `prefers-reduced-motion` before any animation. No animation if set.
- **Static fallback for every effect:** CSS gradient or AI-generated image. Every 3D effect must degrade gracefully.
- **JS budget:** Max ~200 lines total for a full deck using particles + wireframe + globe.
- **Reserve for impact:** Never use 3D on every slide. 2-3 slides per deck maximum.

See [references/3d-effects.md](references/3d-effects.md) for complete Canvas 2D implementations.

---

### Presentation Design Rules

Apply these during slide planning (Phase 3) and generation (Phase 5).

**Rhythm and sequencing:**
- Alternate content density: heavy slide → light slide → heavy slide
- Never place two consecutive hero-background slides
- Insert a section divider every 4-6 content slides for decks longer than 8 slides
- Bookend the deck: closing slide mirrors the title slide treatment
- No more than 2 consecutive slides sharing the same layout type

**Visual consistency anti-patterns — never do these:**
- Mix image styles within a deck (e.g., photographic on one slide, illustrated on the next)
- Use more than 3 colors in the palette (background, text, accent)
- Center-align bullet lists (left-align always)
- Apply heavy drop shadows on text or cards
- Add animated slide transitions (wipes, spins, 3D flips) — only subtle fades or slides
- Place more than one accent-colored element per slide
- Use more than 3 font sizes on a single slide (title, subhead, body)

### Visual Hierarchy & Image Overlays

**Text-over-image overlays** — when text overlays a background image, apply one of these (preference order):

| Technique | CSS | Best for |
|-----------|-----|----------|
| Floor fade | `linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.4) 40%, transparent 70%)` | hero-bottom |
| Full dim | `background: rgba(0,0,0,0.4)` over image | Universal fallback |
| Frosted panel | `backdrop-filter: blur(12px); background: rgba(0,0,0,0.3)` behind text | hero-center, modern feel |
| Color block | Solid/semi-transparent accent rectangle behind text | Editorial, bold |
| Text shadow | `text-shadow: 0 2px 20px rgba(0,0,0,0.8)` | Light overlays only |

**Hard rule:** NEVER place text directly on an unprocessed background image. Every hero layout must apply at least `brightness(0.5)` on the background.

**Font-size discipline:** Max 3 sizes per slide — `--title-size`, `--h3-size`, `--body-size`. Do not invent ad-hoc sizes.

**Color discipline:** Only ONE accent-colored element per slide (`var(--accent)`). Everything else uses `--text-primary` or `--text-secondary`.

**Weight hierarchy:** 700-800 headlines, 500-600 subheads, 400 body. Use opacity (0.6-0.7) for de-emphasis rather than adding font sizes.

**Whitespace:** Heading-to-content gap = `var(--content-gap)`. Item-to-item gap = `var(--element-gap)`.

**Reading patterns:** Left-align text on content/bullet slides (F-pattern). Center only on title/statement slides (Z-pattern).

**Utility classes:** `.glass` (frosted panel) and `.gradient-text` (accent gradient on text) are defined in [references/base-css.md](references/base-css.md).

---

## Phase 5: Generate Presentation

Read these externalized state files — do not rely on conversation history:
- `$WORKDIR/outline.md` — slide-by-slide content plan (Phase 1)
- `$WORKDIR/style.md` — preset, depth/motion, interactivity choices (Phase 2)
- `$WORKDIR/image-plan.md` — image prompts and generated file paths (Phase 3-4)

### File Structure

For single presentations:
```
presentation.html    # Self-contained presentation
presentation-assets/ # Generated images
```

For projects with multiple presentations:
```
[presentation-name].html
[presentation-name]-assets/
```

### Output Strategy

Never generate the entire HTML file in a single Write call. Split into chunks:

1. **Write the shell** — `<!DOCTYPE html>` through `</style>`, closing with a placeholder comment `<!-- SLIDES -->` and the closing `</script></body></html>`. This establishes the CSS and JS framework.

2. **Write slides in batches** — Use Edit to insert 3-5 slides at a time, replacing the `<!-- SLIDES -->` placeholder (or appending before `</main>`). Each batch is one Edit call.

3. **Verify** — After all slides are inserted, read the file to verify it's well-formed HTML.

This prevents hitting the 32,000 output token limit. A 20-slide deck with full CSS typically requires 15,000-25,000 tokens if written at once.

### HTML Architecture

Single HTML file with inline CSS/JS, viewport-locked slides, and scroll-snap navigation. Assets (generated images) live in a companion `{name}-assets/` directory.

See [references/html-template.md](references/html-template.md) for the complete template including:
- `:root` theme variables (colors, typography, spacing, animation easing)
- Base styles, slide container, and image treatment classes
- Responsive breakpoints and animation triggers
- Slide markup patterns (hero background, inset image, text-only)
- `SlidePresentation` controller scaffold

### Slide Layouts

Every slide must use one of the 20 named layout classes. See [references/layouts.md](references/layouts.md) for complete CSS class definitions and HTML structure.

| Group | Layout | Purpose | Density |
|-------|--------|---------|---------|
| **Foundation** | `title` | Opening slide, hero background | Minimal |
| | `section-divider` | Chapter break with large number/keyword | Minimal |
| | `content` | Standard left-aligned bullet content | Medium |
| | `statement` | Single bold sentence, centered | Minimal |
| | `end` | Closing slide / CTA | Minimal |
| **Image-Forward** | `hero-bottom` | Full-bleed image, text at bottom (floor fade) | Low |
| | `hero-center` | Full-bleed image, centered text (frosted scrim) | Very Low |
| | `hero-left` | Full-bleed image, text in left sidebar | Low |
| | `split-50-50` | Balanced half image, half text | Medium |
| | `split-60-40` | Image-dominant split | Low-Medium |
| | `split-40-60` | Text-dominant split | Medium |
| | `image-gallery` | 2-4 images in asymmetric mosaic | Low |
| **Data & Metrics** | `big-number` | Single huge statistic with label | Very Low |
| | `stats-row` | 2-4 metrics side by side | Low |
| | `comparison` | Two-column with visual divider | Medium |
| **Structured** | `grid-cards` | 2x2 or 2x3 icon+title+description cards (max 6) | Medium |
| | `timeline` | 3-5 horizontal connected steps | Medium |
| | `quote` | Large blockquote with decorative mark | Very Low |
| | `team-grid` | Headshots with names/roles | Low |
| | `logo-wall` | Partner/client logo grid | Very Low |

#### Content-to-Layout Decision Tree

```
Is the core message a number or metric?
  YES → big-number (single stat) or stats-row (2-4 stats)
  NO →
    Is it a quote or testimonial?
      YES → quote
      NO →
        Is there a strong visual to show?
          YES →
            Should the visual dominate the whole slide?
              YES → hero-bottom, hero-center, or hero-left
              NO →
                How much text?
                  < 30 words  → split-60-40 (image dominant)
                  30-50 words → split-50-50 (balanced)
                  50+ words   → split-40-60 (text dominant)
          NO →
            Is it a list of items or features?
              > 4 items with descriptions → grid-cards
              3-5 sequential steps       → timeline
              2 alternatives to compare  → comparison
              Simple bullet list         → content
            Is it a transition point?
              YES → section-divider or statement
```

#### Layout-to-Image Aspect Ratio Mapping

| Layout Category | Layouts | Image Aspect Ratio |
|---|---|---|
| Hero / background | `title`, `hero-bottom`, `hero-center`, `hero-left`, `end` | 16:9 |
| Split layouts | `split-50-50`, `split-60-40`, `split-40-60` | 3:4 or 4:3 |
| Inset images | `content` (with optional image) | 4:3 or 1:1 |
| Team portraits | `team-grid` | 1:1 |
| Gallery | `image-gallery` | mixed |
| Logo images | `logo-wall` | varies (rendered via `object-fit: contain`) |

### Required JavaScript Features

Every presentation should include:

1. **SlidePresentation Class** — Main controller
   - Keyboard navigation (arrows, space)
   - Touch/swipe support
   - Mouse wheel navigation
   - Progress bar updates
   - Navigation dots

2. **Intersection Observer** — For scroll-triggered animations
   - Add `.visible` class when slides enter viewport
   - Trigger CSS animations efficiently

3. **Optional Enhancements** (based on style):
   - Custom cursor with trail
   - Particle system background (canvas)
   - Parallax effects
   - 3D tilt on hover
   - Magnetic buttons
   - Counter animations

### Code Quality Requirements

**Comments:**
Every section should have clear comments explaining:
- What it does
- Why it exists
- How to modify it

```javascript
/* ===========================================
   CUSTOM CURSOR
   Creates a stylized cursor that follows mouse with a trail effect.
   - Uses lerp (linear interpolation) for smooth movement
   - Grows larger when hovering over interactive elements
   =========================================== */
class CustomCursor {
    constructor() {
        // ...
    }
}
```

**Accessibility:**
- Semantic HTML (`<section>`, `<nav>`, `<main>`, `<figure>`, `<figcaption>`)
- Keyboard navigation works
- ARIA labels where needed
- Reduced motion support
- Every `<img>` has a descriptive `alt` attribute derived from the generation prompt

```css
@media (prefers-reduced-motion: reduce) {
    .reveal {
        transition: opacity 0.3s ease;
        transform: none;
    }
}
```

**Responsive & Viewport Fitting (CRITICAL):**

**See the "CRITICAL: Viewport Fitting Requirements" section above for complete CSS and guidelines.**

Quick reference:
- Every `.slide` must have `height: 100vh; height: 100dvh; overflow: hidden;`
- All typography and spacing must use `clamp()`
- Respect content density limits (max 4-6 bullets, max 6 cards, etc.)
- Include breakpoints for heights: 700px, 600px, 500px
- When content doesn't fit → split into multiple slides, never scroll

---

## Phase 6: PPT Conversion

This skill supports converting PowerPoint (.ppt/.pptx) files to HTML presentations. The conversion extracts text, images, and notes via `python-pptx`, confirms the structure with the user, then proceeds through style selection (Phase 2), image planning (Phase 3), and HTML generation (Phase 5).

See [references/ppt-conversion.md](references/ppt-conversion.md) for the complete extraction script and step-by-step conversion workflow.

---

## Phase 7: Delivery

### Final Output

When the presentation is complete:

1. **Clean up temporary files**
   - Delete `.claude-design/slide-previews/` if it exists

2. **Open the presentation**
   - Use `open [filename].html` to launch in browser

3. **Provide summary**
```
Your presentation is ready!

- File: [filename].html
- Assets: [filename]-assets/ ([N] generated images)
- Style: [Style Name]
- Slides: [count]

**Navigation:**
- Arrow keys (← →) or Space to navigate
- Scroll/swipe also works
- Click the dots on the right to jump to a slide

**To customize:**
- Colors: Look for `:root` CSS variables at the top
- Fonts: Change the Fontshare/Google Fonts link
- Animations: Modify `.reveal` class timings
- Images: Replace files in the assets directory, or ask me to regenerate

Would you like me to make any adjustments?
```

### Iteration options

After delivery, the user can request:
- **Regenerate an image** — rerun create-image for a specific slide with a modified prompt
- **Change preset** — regenerate all images with a different aesthetic (re-run Phases 3–5)
- **Edit content** — modify slide text and regenerate HTML only (Phase 5)
- **Add/remove slides** — update the outline and regenerate as needed

---

## Style Reference: Effect → Feeling Mapping

Use this guide to match animations to intended feelings:

### Dramatic / Cinematic
- Slow fade-ins (1-1.5s)
- Large scale transitions (0.9 → 1)
- Dark backgrounds with spotlight effects
- Parallax scrolling
- Full-bleed images

### Techy / Futuristic
- Neon glow effects (box-shadow with accent color)
- Particle systems (canvas background)
- Grid patterns
- Monospace fonts for accents
- Glitch or scramble text effects
- Cyan, magenta, electric blue palette

### Playful / Friendly
- Bouncy easing (spring physics)
- Rounded corners (large radius)
- Pastel or bright colors
- Floating/bobbing animations
- Hand-drawn or illustrated elements

### Professional / Corporate
- Subtle, fast animations (200-300ms)
- Clean sans-serif fonts
- Navy, slate, or charcoal backgrounds
- Precise spacing and alignment
- Minimal decorative elements
- Data visualization focus

### Calm / Minimal
- Very slow, subtle motion
- High whitespace
- Muted color palette
- Serif typography
- Generous padding
- Content-focused, no distractions

### Editorial / Magazine
- Strong typography hierarchy
- Pull quotes and callouts
- Image-text interplay
- Grid-breaking layouts
- Serif headlines, sans-serif body
- Black and white with one accent

---

## Animation Patterns Reference

See [references/animations.md](references/animations.md) for complete implementations. Reduced-motion-first: all motion is wrapped in `@media (prefers-reduced-motion: no-preference)`.

- **Entrance:** `.reveal`, `.reveal-scale`, `.reveal-left`, `.reveal-right`, `.reveal-blur`, `.reveal-clip-up`, `.reveal-clip-left`, `.reveal-bounce`
- **Stagger:** `.stagger-children` (80ms steps), `[data-delay="100..500"]`
- **Image:** `.ken-burns`, `.image-unblur`, `.image-mono-to-color`, `.parallax-float`
- **Background:** `.gradient-bg`, `.noise-bg`, `.grid-bg`
- **Timing:** Uses `--ease-out-expo`, `--ease-out-back`, `--ease-in-out-smooth`, `--duration-fast/normal/slow` custom properties

---

## Troubleshooting

### Common Issues

**Fonts not loading:**
- Check Fontshare/Google Fonts URL
- Ensure font names match in CSS

**Animations not triggering:**
- Verify Intersection Observer is running
- Check that `.visible` class is being added

**Scroll snap not working:**
- Ensure `scroll-snap-type` on html/body
- Each slide needs `scroll-snap-align: start`

**Mobile issues:**
- Disable heavy effects at 768px breakpoint
- Test touch events
- Reduce particle count or disable canvas

**Performance issues:**
- Use `will-change` sparingly
- Prefer `transform` and `opacity` animations
- Throttle scroll/mousemove handlers

**Generated images too large/slow:**
- Use `--fast` flag during iteration
- Use appropriate `--aspect-ratio` (don't generate 16:9 for a 1:1 inset)

**Image doesn't match aesthetic:**
- Check that the prompt includes the preset's base modifier from presets/{preset}.md
- Try more specific descriptions ("a photo of" vs "an illustration of")
- Regenerate with a modified prompt

---

## Related Skills

- **create-image** — Image generation engine used by this skill
- **frontend-design** — For more complex interactive pages beyond slides

---

## Example Session Flow

1. User: "I want to create a pitch deck for my AI startup with custom images"
2. Skill asks about purpose, length, content
3. User shares their bullet points and key messages
4. Skill asks about desired feeling (Impressed + Excited)
5. Skill generates 3 style previews (each with a sample generated image)
6. User picks Style B (Neon Cyber), asks for darker background
7. Skill asks Step 2.5: "Canvas 2D particles are recommended for Neon Cyber — include them?" → User confirms yes
8. Skill plans images for each slide, presents the prompt table
9. User approves the image plan
10. Skill generates all images via create-image
11. Skill generates full presentation with Canvas 2D particles on title + closing slides
12. Skill opens the presentation in browser
13. User requests tweaks to specific slides or image regeneration
14. Final presentation delivered

---

## Conversion Session Flow

1. User: "Convert my slides.pptx to a web presentation with generated images"
2. Skill extracts content and images from PPT
3. Skill confirms extracted content with user
4. Skill asks about desired feeling/style
5. Skill generates style previews
6. User picks a style
7. Skill asks Step 2.5: depth & motion (Canvas 2D default based on preset)
8. Skill plans which slides need generated images (in addition to extracted PPT images)
9. User approves the image plan
10. Skill generates images and HTML presentation
11. Final presentation delivered

---

## Image Generation Rules

These rules govern image generation specifically. They complement the slide-making rules above.

1. **Images via create-image only.** All generated images use the create-image skill CLI. No other image generation tools.
2. **Preset-consistent prompts.** Every image prompt includes the preset's base modifier from [presets/{preset}.md](references/presets/). No freeform prompts that ignore the aesthetic.
3. **User approves image plan.** Phase 3 outputs a prompt table; generation does not start until the user confirms.
4. **Accessible alt text.** Every `<img>` tag has a descriptive `alt` attribute derived from the prompt.
5. **Asset directory, not inline.** Images are files in the assets directory, not base64-encoded inline. This keeps the HTML file manageable.
6. **Viewport fitting still applies.** Images must respect `max-height: min(50vh, 400px)` for inset and `object-fit: cover` for backgrounds. Generated images do not get special exemptions from the viewport rules.
