# Split Pastel

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#f8f4ff` |
| Surface | `#eee8f8` |
| Text Primary | `#2a2535` |
| Text Secondary | `#6b6580` |
| Accent | `#a78bfa` (soft violet) |
| Font Heading | DM Sans, sans-serif |
| Font Body | DM Sans, sans-serif |
| Signature Element | Split-tone backgrounds, generous rounded corners, cheerful pastel gradients |

### Image prompt templates

```yaml
base: >-
  bright cheerful photography, clean pastel palette, soft even lighting,
  friendly and approachable, minimal background, playful composition,
  modern lifestyle aesthetic

backgrounds: >-
  Generate a photo of abstract soft pastel shapes and gradients,
  {base}. Light airy background, pink and blue tones.

heroes: >-
  Generate a photo of {subject}.
  {base}. Bright even lighting, pastel color accent, clean crop.

icons: >-
  Generate a cute minimal illustration of {subject},
  pastel pink and blue palette, rounded shapes, flat design,
  friendly and playful style on white background.
```

### Image CSS treatment

```css
.slide-image {
  filter: brightness(1.03) saturate(0.95);
  border: none;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.slide-bg {
  filter: brightness(0.95) saturate(0.85);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(254, 246, 240, 0.7);
}
```
