# Neon Cyber

### Visual identity

| Property | Value |
|----------|-------|
| Background | `#0a0e1a` |
| Surface | `#111827` |
| Text Primary | `#e0e7ff` |
| Text Secondary | `#7c8baa` |
| Accent | `#00ffcc` (neon cyan) |
| Font Heading | JetBrains Mono, monospace |
| Font Body | Space Grotesk, sans-serif |
| Signature Element | Neon glow borders, CRT scanlines, clipped polygon frames |

### Image prompt templates

```yaml
base: >-
  cyberpunk aesthetic, neon-lit environment, dark atmosphere with
  electric blue and magenta lighting, futuristic urban setting,
  rain-slicked surfaces, holographic elements, high-tech noir

backgrounds: >-
  Generate a photo of a futuristic cityscape at night with neon signs,
  {base}. Wide angle, moody atmosphere, reflective wet surfaces.

heroes: >-
  Generate a photo of {subject}.
  {base}. Dramatic neon backlighting, shallow depth of field.

icons: >-
  Generate a holographic neon icon of {subject}, glowing cyan and magenta
  wireframe on dark navy background, futuristic minimal design.
```

### Image CSS treatment

```css
.slide-image {
  filter: saturate(1.4) contrast(1.15) brightness(1.05);
  border: 1px solid rgba(0, 240, 255, 0.5);
  border-radius: 2px;
  box-shadow:
    0 0 15px rgba(0, 240, 255, 0.2),
    0 0 30px rgba(0, 240, 255, 0.1);
  clip-path: polygon(0 4%, 4% 0, 96% 0, 100% 4%, 100% 96%, 96% 100%, 4% 100%, 0 96%);
}

.slide-bg {
  filter: brightness(0.3) saturate(1.3) hue-rotate(-10deg);
}
.slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background:
    repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,240,255,0.03) 2px, rgba(0,240,255,0.03) 4px);
}
```
