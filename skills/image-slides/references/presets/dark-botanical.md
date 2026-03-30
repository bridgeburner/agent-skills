# Dark Botanical

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#0a1f14` |
| Surface | `#122a1c` |
| Text Primary | `#e8e0d4` |
| Text Secondary | `#a89f90` |
| Accent | `#c4a35a` (warm gold) |
| Font Heading | Playfair Display, serif |
| Font Body | Lora, serif |
| Signature Element | Botanical vignettes, warm earthy undertones, soft radial overlays |

### Image prompt templates

```yaml
base: >-
  soft natural lighting, warm earth tones, shallow depth of field,
  botanical elegance, organic textures, muted green and gold palette,
  premium editorial photography style

backgrounds: >-
  Generate a photo of lush botanical foliage with soft bokeh,
  {base}. Dark background, leaves catching warm light.

heroes: >-
  Generate a photo of {subject}.
  {base}. Intimate close-up, warm side-lighting.

icons: >-
  Generate a photo of a single {subject} on dark earth-toned background,
  soft directional light, shallow depth of field, botanical still life.
```

### Image CSS treatment

```css
.slide-image {
  filter: contrast(1.05) saturate(0.9) brightness(0.95);
  border: 2px solid rgba(139, 154, 107, 0.3);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  mix-blend-mode: luminosity;
}

.slide-bg {
  filter: brightness(0.3) saturate(0.8);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at center, transparent 40%, rgba(26,26,26,0.7) 100%);
}
```
