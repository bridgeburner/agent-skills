# Pastel Geometry

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#faf8ff` |
| Surface | `#f0eef8` |
| Text Primary | `#2d2b3a` |
| Text Secondary | `#6e6b80` |
| Accent | `#7c6bef` (soft purple) |
| Font Heading | Poppins, sans-serif |
| Font Body | DM Sans, sans-serif |
| Signature Element | Soft geometric shapes, rounded pastel cards, clean even lighting |

### Image prompt templates

```yaml
base: >-
  bright clean photography, soft pastel accents, geometric framing,
  friendly and approachable, well-organized composition, light
  airy background, modern product photography feel

backgrounds: >-
  Generate a photo of abstract pastel geometric shapes,
  {base}. Soft gradients, clean edges, light background.

heroes: >-
  Generate a photo of {subject}.
  {base}. Even lighting, clean crop, pastel accent elements.

icons: >-
  Generate a flat geometric icon of {subject},
  pastel color palette, rounded shapes, clean minimal design
  on white background.
```

### Image CSS treatment

```css
.slide-image {
  filter: brightness(1.02) saturate(0.9);
  border: none;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.slide-bg {
  filter: brightness(0.92) saturate(0.85);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.65);
}
```
