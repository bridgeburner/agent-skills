# Bold Signal

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#111111` |
| Surface | `#1a1a1a` |
| Text Primary | `#ffffff` |
| Text Secondary | `#999999` |
| Accent | `#ff4444` (signal red) |
| Font Heading | Bebas Neue, sans-serif |
| Font Body | Inter, sans-serif |
| Signature Element | High-contrast cards, bold offset shadows, strong graphic borders |

### Image prompt templates

```yaml
base: >-
  bold graphic style, high saturation, strong contrast, vivid colors,
  dramatic lighting with deep shadows, editorial photography,
  confident and impactful composition

backgrounds: >-
  Generate a photo of abstract bold shapes and dramatic lighting,
  {base}. Deep black shadows with vivid color accents.

heroes: >-
  Generate a photo of {subject}.
  {base}. Low angle, powerful composition, rim lighting.

icons: >-
  Generate a bold graphic icon of {subject}, flat design with vivid red
  and orange on pure black background, high contrast, minimal detail.
```

### Image CSS treatment

```css
.slide-image {
  filter: contrast(1.2) saturate(1.3) brightness(0.95);
  border: 3px solid #ff3b30;
  border-radius: 0;
  box-shadow: 8px 8px 0 rgba(255, 59, 48, 0.3);
}

.slide-bg {
  filter: brightness(0.25) contrast(1.3) saturate(1.2);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255,59,48,0.15) 0%, transparent 50%);
}
```
