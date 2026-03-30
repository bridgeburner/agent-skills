---
name: create-image
description: "Generate images from text prompts using Google Gemini. Use when you need to generate an image, create image, make a picture, do image generation, generate a photo, create visual, make an icon, design graphic, produce an illustration, create a mockup, or generate artwork."
---

# Create Image

Generate images from text prompts using Google Gemini (Nano Banana Pro or Fast). Outputs PNG files.

## How to Invoke

Run from anywhere using `--directory`:

```bash
uv run --directory /path/to/create-image/scripts python main.py "<prompt>" -o /absolute/path/to/output.png
```

Or run from the scripts directory:

```bash
cd /path/to/create-image/scripts
uv run python main.py "<prompt>" -o path/to/image.png
```

`uv run` handles dependency installation automatically. The first run may take a moment to set up the virtual environment.

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `prompt` (positional) | *required* | Text description of the image |
| `-o`, `--output` | `output.png` | Output file path (`.png` added if missing) |
| `--fast` | off | Use Nano Banana Fast instead of Pro |
| `--aspect-ratio` | none | `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `9:16`, `16:9`, `21:9` |
| `--image-size` | none | `1K`, `2K`, `4K` (uppercase K required) |
| `--env-file` | `.env` | Path to env file with API key |

## Prerequisites

Set `GEMINI_API_KEY` or `GOOGLE_API_KEY` in a `.env` file or as an environment variable. Get one at [Google AI Studio](https://aistudio.google.com/apikey).

## Prompting Rules

1. **Always start with an action phrase** ("Generate an image of", "Create a photo of") -- without one, the model returns text instead of an image.
2. **Describe, don't list** -- "A weathered fisherman mending nets on a dock at dawn, soft golden light" beats a keyword list.
3. **Specify style via verb** -- "a photo of..." = photorealistic; "a painting of..." = artistic; "a sketch of..." = illustration.
4. **Use positive descriptions** -- say what the scene IS, not what it ISN'T.
5. **Keep text rendering short** -- max ~25 characters per text element, wrap exact text in quotes.

## Model Selection

| Model | Flag | Best for |
|-------|------|----------|
| **Nano Banana Pro** (default) | *(none)* | Quality, 4K, precise text rendering (`gemini-3-pro-image-preview`) |
| **Nano Banana Fast** | `--fast` | Speed, high-volume, low-latency (`gemini-3.1-flash-image-preview`) |

## Reference Files

| File | Contents |
|------|----------|
| [references/prompting-guide.md](references/prompting-guide.md) | Detailed prompt templates, style descriptors, camera vocabulary, quality boosters, aspect ratio guidance |

## Input Spec

When invoked by the `explainer` skill, expect:

- **Subject description and visual metaphor** -- what to depict and the conceptual analogy it serves
- **Style/mood requirements** -- artistic treatment, lighting, color palette, emotional tone
- **Aspect ratio** -- matched to the target layout dimensions
- **Output path** -- absolute path for the generated PNG file
