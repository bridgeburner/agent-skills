# Creative Voltage

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#1a1410` |
| Surface | `#2a2218` |
| Text Primary | `#f5f0e8` |
| Text Secondary | `#a09880` |
| Accent | `#ff9b2e` (electric orange) |
| Font Heading | Clash Display, sans-serif |
| Font Body | DM Sans, sans-serif |
| Signature Element | Diagonal textures, retro print grain, offset card rotations |

### Image prompt templates

```yaml
base: >-
  energetic retro-modern aesthetic, vibrant color palette, textured
  backgrounds, dynamic diagonal compositions, vintage print feel
  with modern boldness, grainy film texture

backgrounds: >-
  Generate a photo of abstract colorful geometric shapes with
  retro print texture, {base}. Diagonal energy, layered colors.

heroes: >-
  Generate a photo of {subject}.
  {base}. Dynamic angle, high energy, warm saturated light.

icons: >-
  Generate a retro-modern illustration of {subject},
  bold outlines, vintage color palette, screen-print texture,
  on textured paper background.
```

### Image CSS treatment

```css
.slide-image {
  filter: saturate(1.2) contrast(1.1) brightness(0.95);
  border: 2px solid rgba(255, 200, 50, 0.4);
  border-radius: 4px;
  box-shadow: 4px 4px 0 rgba(0, 0, 0, 0.2);
  transform: rotate(-1deg);
}

.slide-bg {
  filter: brightness(0.3) saturate(1.2) contrast(1.1);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    -45deg, transparent, transparent 3px, rgba(0,0,0,0.03) 3px, rgba(0,0,0,0.03) 6px
  );
}
```
