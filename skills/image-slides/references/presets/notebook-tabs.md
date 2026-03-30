# Notebook Tabs

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#faf8f5` |
| Surface | `#f0ebe4` |
| Text Primary | `#2c2825` |
| Text Secondary | `#7a7068` |
| Accent | `#d4874e` (warm amber) |
| Font Heading | Merriweather, serif |
| Font Body | Nunito, sans-serif |
| Signature Element | Paper-textured surfaces, colored tab dividers, soft warm shadows |

### Image prompt templates

```yaml
base: >-
  warm neutral editorial photography, clean composition, soft natural
  light, muted warm palette, professional lifestyle photography,
  magazine-quality, approachable and organized

backgrounds: >-
  Generate a photo of a clean workspace or organized flat lay,
  {base}. Top-down view, warm natural light, muted tones.

heroes: >-
  Generate a photo of {subject}.
  {base}. Soft directional light, warm tones, clean background.

icons: >-
  Generate a simple warm-toned illustration of {subject},
  clean lines, muted orange and cream palette, friendly minimal style.
```

### Image CSS treatment

```css
.slide-image {
  filter: contrast(1.02) saturate(0.95);
  border: 1px solid #e8e0d8;
  border-radius: 8px;
  box-shadow:
    0 2px 8px rgba(0, 0, 0, 0.06),
    0 1px 3px rgba(0, 0, 0, 0.04);
}

.slide-bg {
  filter: brightness(0.9) saturate(0.85);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(250, 248, 245, 0.75);
}
```
