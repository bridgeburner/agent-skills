# Futuristic Engineering (New Preset)

### Visual identity

| Property | Value |
|---|---|
| Background | `#0e1117` |
| Surface | `#161b22` |
| Primary text | `#d4dae0` |
| Accent | `#58a6ff` (tech blue) |
| Secondary accent | `#3fb950` (status green) |
| Tertiary | `#6e7681` (muted gray) |
| Heading font | 'SF Mono', 'Consolas', 'Courier New', monospace |
| Body font | -apple-system, system-ui, sans-serif |
| Signature elements | Thin grid lines, technical labels, status indicators, data readouts |

### Layout notes

- Background: subtle dot grid pattern (`radial-gradient` repeating)
- Slide borders: thin `1px` line with tech blue, slightly inset
- Heading treatment: monospace, uppercase, letter-spacing `0.1em`, with a thin rule below
- Data callouts: small monospace labels with green/blue indicators
- Corner elements: coordinate-style labels (e.g., `SEC.01 // OVERVIEW`)

### Image prompt templates

```yaml
base: >-
  clean sci-fi engineering aesthetic, brushed metal surfaces, cool blue
  accent lighting, technical precision, blueprint-like clarity,
  advanced technology, sterile futuristic environment

backgrounds: >-
  Generate a photo of abstract technical schematic, circuit board
  patterns and clean geometric lines on dark background,
  {base}. Top-down view, even cool lighting.

heroes: >-
  Generate a photo of {subject}.
  {base}. Clinical even lighting, sharp focus, neutral background.

icons: >-
  Generate a holographic wireframe icon of {subject},
  glowing blue lines on dark charcoal background,
  minimal technical illustration, blueprint style.
```

### Image CSS treatment

```css
.slide-image {
  filter: saturate(0.8) contrast(1.15) brightness(0.95);
  border: 1px solid rgba(88, 166, 255, 0.3);
  border-radius: 2px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.4);
}

.slide-bg {
  filter: brightness(0.25) saturate(0.7) contrast(1.1);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background:
    linear-gradient(rgba(88,166,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(88,166,255,0.03) 1px, transparent 1px);
  background-size: 40px 40px;
}
```
