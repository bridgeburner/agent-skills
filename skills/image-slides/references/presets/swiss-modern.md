# Swiss Modern

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#ffffff` |
| Surface | `#f5f5f5` |
| Text Primary | `#1a1a1a` |
| Text Secondary | `#666666` |
| Accent | `#ff0000` (Swiss red) |
| Font Heading | Helvetica Neue, Arial, sans-serif |
| Font Body | Inter, sans-serif |
| Signature Element | Strict grid alignment, geometric shapes, black/white/red palette, Bauhaus precision |

### Image prompt templates

```yaml
base: >-
  flat geometric minimal style, clean sharp edges, primary color palette,
  Bauhaus-inspired composition, precise grid alignment, modern graphic
  design, no gradients, no textures

backgrounds: >-
  Generate an abstract geometric composition of rectangles and circles,
  {base}. Red blue and yellow on white, asymmetric grid layout.

heroes: >-
  Generate a flat graphic illustration of {subject}.
  {base}. Bold outlines, minimal detail, strong composition.

icons: >-
  Generate a geometric icon of {subject},
  single primary color on white background, Bauhaus style,
  bold simple shape, no gradients.
```

### Image CSS treatment

```css
.slide-image {
  filter: none;
  border: 2px solid #1a1a1a;
  border-radius: 0;
  box-shadow: none;
}

.slide-bg {
  filter: brightness(0.95) contrast(1.05);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.8);
}
```
