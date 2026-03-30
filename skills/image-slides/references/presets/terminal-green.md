# Terminal Green

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#0a0f0a` |
| Surface | `#0f170f` |
| Text Primary | `#00ff41` (phosphor green) |
| Text Secondary | `#4a7a4a` |
| Accent | `#00ff41` (terminal green) |
| Font Heading | JetBrains Mono, monospace |
| Font Body | Fira Code, monospace |
| Signature Element | CRT phosphor glow, scanline overlays, blinking cursor accents |

### Image prompt templates

```yaml
base: >-
  monochrome green terminal aesthetic, phosphor CRT glow, dark
  background with bright green elements, retro computing feel,
  scanlines, matrix-style digital atmosphere

backgrounds: >-
  Generate a photo of a retro CRT monitor displaying green code
  on black, {base}. Close-up, shallow depth of field, green glow.

heroes: >-
  Generate a photo of {subject}.
  {base}. Lit only by green monitor glow, dark surroundings.

icons: >-
  Generate a pixel art icon of {subject}, bright green on black
  background, retro terminal aesthetic, minimal 8-bit style.
```

### Image CSS treatment

```css
.slide-image {
  filter: saturate(0) brightness(0.9) contrast(1.2);
  border: 1px solid rgba(0, 255, 65, 0.3);
  border-radius: 0;
  box-shadow: 0 0 10px rgba(0, 255, 65, 0.15);
  /* Green tint via mix-blend-mode on a wrapper div */
}

.slide-bg {
  filter: brightness(0.25) saturate(0) contrast(1.3);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(0, 255, 65, 0.05);
}
```
