# Steampunk (New Preset)

### Visual identity

| Property | Value |
|---|---|
| Background | `#1c1610` |
| Surface | `#2a2118` |
| Primary text | `#e8dcc8` |
| Accent | `#c8922a` (brass gold) |
| Secondary accent | `#8b6914` (aged bronze) |
| Tertiary | `#6b3a2a` (copper rust) |
| Heading font | Georgia, 'Palatino Linotype', serif |
| Body font | 'Segoe UI', system-ui, sans-serif |
| Signature elements | Gear dividers, ornate borders, brass rivets, leather texture |

### Layout notes

- Slide borders: double-rule with brass-colored lines
- Dividers between sections: gear/cog SVG ornament (inline SVG, no external file)
- Corner accents: small brass rivet dots at slide corners
- Heading treatment: small-caps with letter-spacing

### Image prompt templates

```yaml
base: >-
  Victorian steampunk aesthetic, brass and copper tones, clockwork
  mechanisms, warm amber lighting, aged metal textures, ornate
  industrial machinery, sepia-toned atmosphere

backgrounds: >-
  Generate a photo of intricate brass clockwork mechanism,
  interlocking gears and copper pipes, warm amber backlighting,
  {base}. Close-up macro detail, shallow depth of field.

heroes: >-
  Generate a photo of {subject}.
  {base}. Dramatic warm side-lighting, rich textures, aged patina.

icons: >-
  Generate a photo of an engraved brass medallion depicting {subject},
  on dark leather background, warm directional light, antique still life.
```

### Image CSS treatment

```css
.slide-image {
  filter: sepia(0.3) contrast(1.1) brightness(0.9);
  border: 2px solid #8b6914;
  border-radius: 4px;
  box-shadow:
    0 4px 16px rgba(0, 0, 0, 0.5),
    inset 0 0 20px rgba(139, 105, 20, 0.1);
}

.slide-bg {
  filter: brightness(0.35) sepia(0.4) contrast(1.1);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at center, transparent 30%, rgba(28,22,16,0.8) 100%);
}
```
