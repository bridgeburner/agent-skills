# Electric Studio

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#0f0f14` |
| Surface | `#1a1a24` |
| Text Primary | `#f0f0f5` |
| Text Secondary | `#8888a0` |
| Accent | `#6366f1` (electric indigo) |
| Font Heading | Satoshi, sans-serif |
| Font Body | Space Grotesk, sans-serif |
| Signature Element | Soft gradient glows, clean studio-lit card shadows, subtle top-down light |

### Image prompt templates

```yaml
base: >-
  sleek modern studio photography, clean white and cool gray tones,
  professional commercial lighting, sharp focus, minimal background,
  polished and contemporary

backgrounds: >-
  Generate a photo of abstract studio lighting with soft gradients,
  {base}. Cool tones, clean geometric shadows.

heroes: >-
  Generate a photo of {subject}.
  {base}. Three-quarter angle, studio strobes, clean background.

icons: >-
  Generate a minimal studio product shot of {subject},
  white background, soft shadow, commercial quality.
```

### Image CSS treatment

```css
.slide-image {
  filter: contrast(1.05) brightness(1.02);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.slide-bg {
  filter: brightness(0.3) contrast(1.1);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(0,0,0,0.4) 0%, transparent 40%);
}
```
