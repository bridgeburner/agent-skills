# Gemini Image Generation: Comprehensive Prompting Guide

A research-backed guide for producing high-quality images with Google Gemini's `gemini-3-pro-image-preview` (Nano Banana Pro).

---

## 1. Prompt Structure

### Core Principle: Describe the Scene, Don't List Keywords

Gemini uses deep language understanding. **A narrative, descriptive paragraph produces better, more coherent images than disconnected keywords.** Think of it as briefing a skilled artist, not feeding tokens to a search engine.

### Recommended Prompt Formula

```
[Action phrase] + [Subject] + [Action/Pose] + [Environment/Setting] + [Lighting] + [Style] + [Camera/Composition] + [Mood/Atmosphere] + [Technical specs]
```

**Action phrases** are critical — start with "Create an image of", "Generate a photo of", or similar. Without these, the multimodal model may respond with text instead of an image.

### Component Breakdown

| Component | Purpose | Examples |
|-----------|---------|----------|
| **Subject** | What is depicted | "a weathered fisherman", "a 1967 Mustang Fastback" |
| **Action/Pose** | What the subject is doing | "mending nets on a wooden dock", "drifting on a rain-soaked track" |
| **Environment** | Where the scene takes place | "a misty harbor at dawn", "an abandoned warehouse" |
| **Lighting** | Light quality and direction | "soft golden hour light streaming through a window", "harsh overhead fluorescent" |
| **Style** | Artistic treatment | "oil painting with heavy impasto brushstrokes", "photorealistic" |
| **Camera/Composition** | How the viewer sees it | "85mm portrait lens, shallow depth of field", "wide-angle aerial shot" |
| **Mood/Atmosphere** | Emotional tone | "melancholic and contemplative", "vibrant and energetic" |
| **Technical specs** | Resolution, aspect ratio | "4K resolution", "16:9 aspect ratio" |

### Example: Weak vs. Strong Prompt

**Weak:** "A cool car"

**Strong:** "Generate an image of a 1967 Mustang Fastback drifting sideways on a rain-soaked race track at dusk. The headlights cut through mist and tire smoke. Shot from a low angle with a wide-angle lens. Cinematic lighting with warm amber tones from the setting sun contrasting cool blue shadows. Photorealistic, 4K resolution, 16:9 aspect ratio."

### Step-by-Step for Complex Scenes

For complex compositions, break requests into sequential steps:
"First, create a background of a serene, misty forest at dawn. Then, in the foreground, add a moss-covered ancient stone altar. Finally, place a single, glowing sword resting on top."

---

## 2. Quality Boosters

### Proven Quality Modifiers

**General quality:**
- "high-quality", "highly detailed", "beautiful", "professional"
- "4K", "8K" (uppercase K required — lowercase is rejected by the API)
- "HDR", "high dynamic range"
- "ultra-realistic", "hyper-detailed"

**Photography-specific:**
- "studio photo", "professional photographer"
- "DSLR quality", "medium format film"
- "sharp focus", "tack sharp"
- "depth of field", "bokeh"

**Lighting quality:**
- "cinematic lighting", "dramatic lighting"
- "soft diffused lighting", "rim lighting"
- "three-point softbox setup"
- "volumetric lighting", "god rays"
- "golden hour", "blue hour"
- "chiaroscuro" (strong contrast between light and dark)

**Texture and detail:**
- "fine texture", "intricate details"
- "subsurface scattering" (for skin)
- "specular highlights" (for reflective surfaces)

### Resolution Tiers (CLI `--image-size` flag)

| Tier | Resolution | Best For |
|------|-----------|----------|
| **1K** (default) | 1024x1024 | Quick iterations, social media |
| **2K** | 2048x2048 | High-quality content, web |
| **4K** | 4096x4096 | Professional design, print |

Always use uppercase "K" (e.g., `--image-size 2K`).

---

## 3. Style Descriptors

### Controlling Artistic Style

The key verb in your prompt affects style:
- **"a photo of..."** or **"generate a picture of..."** → photorealistic output
- **"a painting of..."** or **"paint..."** → artistic, handmade look
- **"a sketch of..."** or **"draw..."** → illustration style

### Style Reference Table

| Style | Prompt Keywords |
|-------|----------------|
| **Photorealistic** | "photorealistic", "photo", "DSLR", specific lens/camera references |
| **Oil Painting** | "oil painting", "heavy brushstrokes", "impasto", "matte finish" |
| **Watercolor** | "watercolor painting", "soft washes", "wet-on-wet technique", "paper texture" |
| **Digital Art** | "digital illustration", "concept art", "artstation style" |
| **3D Render** | "3D render", "octane render", "unreal engine", "ray tracing" |
| **Pixel Art** | "pixel art", "16-bit", "retro game style" |
| **Anime/Manga** | "anime style", "manga illustration", "cel-shaded" |
| **Pencil Sketch** | "pencil drawing", "graphite sketch", "cross-hatching" |
| **Pop Art** | "pop art style", "bold colors", "halftone dots" |
| **Minimalist** | "minimalist", "clean lines", "negative space", "simple shapes" |
| **Vintage/Retro** | "vintage photograph", "polaroid", "film grain", "faded colors" |
| **Impressionist** | "impressionist style", "visible brushstrokes", "light and color focus" |
| **Art Nouveau** | "art nouveau", "flowing organic lines", "decorative borders" |
| **Noir** | "film noir", "high-contrast black and white", "harsh shadows" |

### Camera and Lens Vocabulary

| Focal Length | Effect | Use Case |
|-------------|--------|----------|
| **10-24mm** (wide-angle) | Expansive, dramatic distortion | Landscapes, architecture |
| **24-35mm** | Natural perspective, slight width | Environmental portraits, street |
| **50mm** | Human-eye perspective | General purpose, documentary |
| **85mm** | Flattering compression, bokeh | Portraits |
| **60-105mm macro** | Extreme close-up detail | Products, nature details |
| **100-400mm telephoto** | Compression, isolation | Wildlife, sports, motion |

**Camera effects:** "motion blur", "soft focus", "bokeh", "tilt-shift", "long exposure", "fast shutter speed", "film grain", "lens flare"

**Camera angles:** "low-angle", "high-angle", "bird's-eye view", "Dutch angle", "over-the-shoulder", "worm's-eye view"

---

## 4. What to Avoid

### Common Pitfalls

**1. Vague, underspecified prompts**
- Bad: "A cool car"
- Good: "A 1967 Mustang Fastback drifting on a race track, cinematic lighting, low angle"

**2. Keyword salad / prompt overloading**
- Bad: "cinematic, volumetric lighting, 35mm, f/1.4, 8k, hyperreal, artstation, trending, masterpiece, best quality"
- Good: "A cinematic portrait shot on 35mm film at f/1.4, with soft volumetric lighting creating an intimate, hyperreal atmosphere"

Gemini responds to natural language, not comma-separated token lists. Long keyword dumps cause the model to average constraints rather than satisfying any of them well.

**3. Conflicting style instructions**
- Bad: "Pixel art and 4k photorealistic" (contradictory)
- Good: Pick one style and commit to it

**4. Negative prompts phrased as instructions**
- Bad: "no red car", "don't include people" (paradoxically makes these appear)
- Good: "an empty, deserted street with no signs of traffic" (describe what you DO want)

**5. Ignoring aspect ratio**
- Faces get cropped when posting without dimension planning
- Always specify your target aspect ratio for the intended platform

**6. Copying prompts from other models**
- Prompts designed for Midjourney (`--stylize`, `--ar`, `--v`) or Stable Diffusion do not translate to Gemini
- Write fresh prompts in natural language

**7. Expecting perfection on the first attempt**
- Gemini excels at iterative refinement — generate, evaluate, adjust the prompt, regenerate

**8. Text rendering overload**
- Keep rendered text to ~25 characters maximum per text element
- Use 2-3 distinct text phrases maximum
- Wrap exact text in quotation marks in your prompt

---

## 5. Aspect Ratio Guidance

### Supported Aspect Ratios

| Aspect Ratio | Orientation | Best For |
|-------------|-------------|----------|
| **1:1** | Square | Social media posts, profile pictures, icons |
| **2:3** | Portrait | Pinterest pins, book covers |
| **3:2** | Landscape | Standard photography, blog headers |
| **3:4** | Portrait | Posters, cards, portrait displays |
| **4:3** | Landscape | Presentations, film/media |
| **4:5** | Portrait | Instagram portrait posts |
| **5:4** | Landscape | Print photography |
| **9:16** | Tall portrait | Stories, Reels, TikTok |
| **16:9** | Widescreen | YouTube thumbnails, desktop wallpapers |
| **21:9** | Ultra-wide | Cinematic banners, ultra-wide displays |

---

## 6. Gemini-Specific Differences

Key differences from other image generation models:

1. **No parameter flags**: Unlike Midjourney (`--ar`, `--stylize`) or Stable Diffusion (cfg_scale, steps, sampler), Gemini is controlled through natural language and API config only.
2. **No negative prompt field**: Use positive/semantic descriptions instead. Say what the scene IS, not what it is NOT.
3. **Natural language over keywords**: Gemini's language model processes full sentences — narrative descriptions consistently outperform keyword lists.
4. **Resolution via API config**: Specify `--image-size 2K` rather than embedding resolution in the prompt (though quality keywords like "4K" in the prompt can help).

---

## 7. Prompt Templates

### Photorealistic Portrait
```
Generate a close-up portrait of [subject description] illuminated by soft golden
hour light streaming through a window, highlighting fine skin texture and
catching the edges of their hair. Shot on an 85mm portrait lens with shallow
depth of field and warm bokeh in the background. Photorealistic, 4K resolution,
3:4 aspect ratio.
```

### Product Mockup
```
Create a high-resolution product photo of [product description] on a [surface
material] background. Three-point softbox lighting setup, shot from an elevated
45-degree angle with sharp focus on the product label. Ultra-realistic,
studio-quality, square 1:1 aspect ratio, 4K.
```

### Stylized Illustration
```
Generate a kawaii-style sticker illustration of [subject] with bold black outlines,
cel-shading, vibrant pastel colors, and a clean white background. Cute,
expressive features with a slight head tilt. Simple, flat design suitable for
die-cut printing.
```

### Cinematic Scene
```
Create a cinematic wide-angle shot of [scene description]. Dramatic volumetric
lighting with [light source] casting long shadows across [environment].
Film grain, muted color grading with [color tone] highlights and [color tone]
shadows. Anamorphic lens flare. 21:9 ultra-wide aspect ratio, 4K.
```

### Text-Heavy Design (Poster/Ad)
```
Create a modern minimalist poster for [brand/event]. Feature the text "[EXACT TEXT]"
in clean, bold sans-serif font, centered on a [color] gradient background.
Below, add "[SECONDARY TEXT]" in a smaller, lighter weight. Include a simple
stylized icon of [subject] above the main text. Professional graphic design
quality, 2:3 aspect ratio, 4K.
```

### Minimalist / Negative Space
```
Generate a single [subject] positioned in the bottom-right third of the frame
against a vast, off-white canvas. Soft diffused overhead lighting casting a
subtle shadow. Expansive empty space suitable for text overlay. Clean, minimal,
contemplative. 16:9 landscape aspect ratio.
```
