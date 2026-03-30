# Paper & Ink

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#1c1a18` |
| Surface | `#2a2622` |
| Text Primary | `#e8e0d0` |
| Text Secondary | `#a09888` |
| Accent | `#c8a882` (aged ink gold) |
| Font Heading | Cormorant Garamond, serif |
| Font Body | EB Garamond, serif |
| Signature Element | Ink-wash textures, brush-stroke dividers, textured paper feel, multiply blending |

### Image prompt templates

```yaml
base: >-
  ink wash illustration style, textured handmade paper, flowing
  brushstrokes, literary and contemplative, warm off-white and
  dark ink tones, hand-drawn quality, Japanese sumi-e influence

backgrounds: >-
  Generate an ink wash painting of abstract flowing forms,
  {base}. Minimal, meditative, textured paper background.

heroes: >-
  Generate an ink wash illustration of {subject}.
  {base}. Expressive brushwork, atmospheric, thoughtful composition.

icons: >-
  Generate an ink stamp illustration of {subject},
  single dark ink on cream paper, simple brushstroke style,
  literary and minimal.
```

### Image CSS treatment

```css
.slide-image {
  filter: sepia(0.1) contrast(1.1) brightness(0.98);
  border: none;
  border-radius: 0;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  mix-blend-mode: multiply;
}

.slide-bg {
  filter: brightness(0.88) sepia(0.1) contrast(1.05);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(250, 245, 235, 0.75);
}
```
