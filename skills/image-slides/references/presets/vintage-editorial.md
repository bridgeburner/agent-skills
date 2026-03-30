# Vintage Editorial

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#f5f0eb` |
| Surface | `#ebe4db` |
| Text Primary | `#2a2420` |
| Text Secondary | `#6b5e52` |
| Accent | `#b5543b` (terracotta) |
| Font Heading | Libre Baskerville, serif |
| Font Body | Source Serif 4, serif |
| Signature Element | Sepia photo treatments, editorial pull-quotes, muted film-grain overlays |

### Image prompt templates

```yaml
base: >-
  muted retro photography style, desaturated warm tones, film grain
  texture, vintage editorial look, natural soft lighting,
  1970s magazine photography aesthetic

backgrounds: >-
  Generate a photo of a vintage still life scene,
  {base}. Muted earth tones, soft window light, editorial composition.

heroes: >-
  Generate a photo of {subject}.
  {base}. Portrait-style, natural light, editorial crop.

icons: >-
  Generate a vintage illustration of {subject},
  muted color palette, retro print style, textured paper look,
  1960s editorial illustration.
```

### Image CSS treatment

```css
.slide-image {
  filter: sepia(0.15) saturate(0.8) contrast(1.05);
  border: 1px solid #d4c9b8;
  border-radius: 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.slide-bg {
  filter: brightness(0.85) sepia(0.2) saturate(0.7);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(245, 240, 230, 0.7);
}
```
