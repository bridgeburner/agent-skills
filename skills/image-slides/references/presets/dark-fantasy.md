# Dark Fantasy (New Preset)

### Visual identity

| Property | Value |
|---|---|
| Background | `#0f0d15` |
| Surface | `#1a1525` |
| Primary text | `#e0dce8` |
| Accent | `#9b6dff` (arcane purple) |
| Secondary accent | `#e8a838` (golden fire) |
| Tertiary | `#3a6b8a` (deep teal) |
| Heading font | Georgia, 'Palatino Linotype', serif (weight: 700) |
| Body font | 'Segoe UI', system-ui, sans-serif |
| Signature elements | Cinematic gradients, magical glow accents, stone/rune textures |

### Layout notes

- Background: deep gradient from near-black to dark purple
- Dividers: thin gradient lines that fade from accent color to transparent
- Heading treatment: serif, slightly larger, with subtle text-shadow glow
- Feature callouts: stone-textured cards with subtle inner glow
- Ambient elements: faint radial gradient glows placed asymmetrically

### Image prompt templates

```yaml
base: >-
  epic dark fantasy atmosphere, dramatic volumetric lighting, mystical
  and ancient, rich deep colors, cinematic scale, magical ambient glow,
  painterly quality

backgrounds: >-
  Generate a cinematic painting of a vast dramatic landscape,
  storm clouds and magical light breaking through,
  {base}. Wide angle, epic scale, moody atmosphere.

heroes: >-
  Generate a cinematic painting of {subject}.
  {base}. Wide angle, epic scale, dramatic rim lighting.

icons: >-
  Generate a painting of a carved stone emblem depicting {subject},
  with faint magical glow, on dark obsidian background,
  ancient mystical artifact, dramatic lighting.
```

### Image CSS treatment

```css
.slide-image {
  filter: contrast(1.15) saturate(1.1) brightness(0.95);
  border: 1px solid rgba(155, 109, 255, 0.2);
  border-radius: 8px;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.5),
    0 0 30px rgba(155, 109, 255, 0.1);
}

.slide-bg {
  filter: brightness(0.3) contrast(1.2) saturate(1.1);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at 30% 50%, rgba(155,109,255,0.08) 0%, transparent 60%);
}
```
