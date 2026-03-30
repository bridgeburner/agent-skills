# Slide Animations

Reduced-motion-first animation catalog for slide presentations. Static by default; motion is opt-in via `prefers-reduced-motion: no-preference`.

## Timing Custom Properties

```css
:root {
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);
  --ease-in-out-smooth: cubic-bezier(0.65, 0, 0.35, 1);
  --duration-fast: 300ms;
  --duration-normal: 600ms;
  --duration-slow: 1000ms;
  --stagger-step: 80ms;
}
```

## Reduced-Motion-First Authoring

All transform/clip-path transitions and `@keyframes` live inside the motion media query. Outside it, elements use opacity-only fades.

```css
/* Base: no motion — elements fade in without movement */
.reveal, .reveal-scale, .reveal-left, .reveal-right,
.reveal-blur, .reveal-clip-up, .reveal-clip-left, .reveal-bounce { opacity: 0; }
.visible .reveal, .visible .reveal-scale, .visible .reveal-left, .visible .reveal-right,
.visible .reveal-blur, .visible .reveal-clip-up, .visible .reveal-clip-left,
.visible .reveal-bounce { opacity: 1; transition: opacity var(--duration-fast) ease-out; }

@media (prefers-reduced-motion: no-preference) {
  /* Entrance Animations, Stagger Pattern, and Image Animations go here */
}
```

Everything in the Entrance Animations, Stagger Pattern, and Image Animations sections below is wrapped inside that `@media (prefers-reduced-motion: no-preference)` block.

## Entrance Animations

```css
.reveal { opacity: 0; transform: translateY(20px);
  transition: opacity var(--duration-normal) var(--ease-out-expo), transform var(--duration-normal) var(--ease-out-expo); }
.visible .reveal { opacity: 1; transform: translateY(0); }

.reveal-scale { opacity: 0; transform: scale(0.95);
  transition: opacity var(--duration-normal) var(--ease-out-expo), transform var(--duration-normal) var(--ease-out-expo); }
.visible .reveal-scale { opacity: 1; transform: scale(1); }

.reveal-left { opacity: 0; transform: translateX(-30px);
  transition: opacity var(--duration-normal) var(--ease-out-expo), transform var(--duration-normal) var(--ease-out-expo); }
.visible .reveal-left { opacity: 1; transform: translateX(0); }

.reveal-right { opacity: 0; transform: translateX(30px);
  transition: opacity var(--duration-normal) var(--ease-out-expo), transform var(--duration-normal) var(--ease-out-expo); }
.visible .reveal-right { opacity: 1; transform: translateX(0); }

.reveal-blur { opacity: 0; filter: blur(8px);
  transition: opacity var(--duration-slow) var(--ease-out-expo), filter var(--duration-slow) var(--ease-out-expo); }
.visible .reveal-blur { opacity: 1; filter: blur(0); }

.reveal-clip-up { clip-path: inset(100% 0 0 0);
  transition: clip-path var(--duration-slow) var(--ease-in-out-smooth); }
.visible .reveal-clip-up { clip-path: inset(0 0 0 0); }

.reveal-clip-left { clip-path: inset(0 100% 0 0);
  transition: clip-path var(--duration-slow) var(--ease-in-out-smooth); }
.visible .reveal-clip-left { clip-path: inset(0 0 0 0); }

.reveal-bounce { opacity: 0; transform: translateY(20px);
  transition: opacity var(--duration-normal) var(--ease-out-back), transform var(--duration-normal) var(--ease-out-back); }
.visible .reveal-bounce { opacity: 1; transform: translateY(0); }
```

## Stagger Pattern

```css
/* Auto-stagger direct children (up to 6) */
.stagger-children > *:nth-child(1) { transition-delay: 0ms; }
.stagger-children > *:nth-child(2) { transition-delay: calc(var(--stagger-step) * 1); }
.stagger-children > *:nth-child(3) { transition-delay: calc(var(--stagger-step) * 2); }
.stagger-children > *:nth-child(4) { transition-delay: calc(var(--stagger-step) * 3); }
.stagger-children > *:nth-child(5) { transition-delay: calc(var(--stagger-step) * 4); }
.stagger-children > *:nth-child(6) { transition-delay: calc(var(--stagger-step) * 5); }

/* Explicit delay attributes for finer control */
[data-delay="100"] { transition-delay: 100ms; }
[data-delay="200"] { transition-delay: 200ms; }
[data-delay="300"] { transition-delay: 300ms; }
[data-delay="400"] { transition-delay: 400ms; }
[data-delay="500"] { transition-delay: 500ms; }
```

## Image Animations

```css
/* Ken Burns — slow pan/zoom on background images (15s loop) */
.ken-burns { overflow: hidden; }
.ken-burns img {
  animation: kenburns 15s var(--ease-in-out-smooth) infinite alternate; will-change: transform; }
@keyframes kenburns {
  from { transform: scale(1) translate(0, 0); }
  to   { transform: scale(1.08) translate(-2%, -1.5%); } }

/* Unblur reveal — image develops into focus */
.image-unblur img { opacity: 0; filter: blur(12px); transform: scale(1.03);
  transition: opacity var(--duration-fast) ease-out, filter var(--duration-slow) var(--ease-out-expo),
              transform var(--duration-slow) var(--ease-out-expo); }
.visible .image-unblur img { opacity: 1; filter: blur(0); transform: scale(1); }

/* Monochrome to color transition */
.image-mono-to-color img { filter: grayscale(1) brightness(1.1);
  transition: filter 1200ms var(--ease-out-expo); }
.visible .image-mono-to-color img { filter: grayscale(0) brightness(1); }

/* Gentle floating oscillation */
.parallax-float img { animation: float 6s ease-in-out infinite alternate; }
@keyframes float {
  from { transform: translateY(0); }
  to   { transform: translateY(-8px); } }
```

## Background Effects

```css
/* Accent gradient — use the deck's accent color for the rgba values */
.gradient-bg {
  background: radial-gradient(ellipse at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(0, 255, 200, 0.2) 0%, transparent 50%), var(--bg-primary); }

.noise-bg { background-image: url("data:image/svg+xml,..."); /* Inline SVG noise */ }

.grid-bg {
  background-image: linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 50px 50px; }
```

## Per-Layout Recommendations

| Layout | Primary animation | Image animation | Notes |
|---|---|---|---|
| `title` | `reveal-scale` | `ken-burns` | Hero bg gets Ken Burns |
| `section-divider` | `reveal-clip-up` | -- | Bold geometric entrance |
| `content` | `stagger-children` + `reveal` | -- | Items appear sequentially |
| `hero-bottom` | `reveal` (text) | `ken-burns` (bg) | Text over cinematic image |
| `split-50-50` | `reveal-left` / `reveal-right` | -- | Mirror directions for balance |
| `big-number` | `reveal-scale` | -- | The number scales in |
| `quote` | `reveal-blur` | -- | Dreamy, contemplative entrance |
| `grid-cards` | `stagger-children` + `reveal-scale` | -- | Cards appear one by one |
| `timeline` | `stagger-children` + `reveal-left` | -- | Steps flow left to right |

## IntersectionObserver Trigger

Add `.visible` class on entry; observe once then disconnect.

```javascript
function initSlideAnimations() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });

  document.querySelectorAll('.slide').forEach(s => observer.observe(s));

  const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
  mq.addEventListener('change', (e) => {
    document.documentElement.classList.toggle('reduce-motion', e.matches);
  });
}
document.addEventListener('DOMContentLoaded', initSlideAnimations);
```

## Optional: Canvas 2D 3D Effects

Use sparingly (2-3 slides per deck max). These add atmospheric depth to title and section-divider slides.

### Shared Projection Utilities

Include once in `<script>`. All patterns below depend on these.

```javascript
// Project a 3D point onto 2D canvas using perspective division
function project(x, y, z, camZ) {
  const scale = camZ / (camZ + z);
  return {
    x: x * scale + canvas.width / 2,
    y: y * scale + canvas.height / 2,
    scale: scale
  };
}

// Rotate a point around the Y axis
function rotateY(x, z, angle) {
  const cos = Math.cos(angle), sin = Math.sin(angle);
  return { x: x * cos - z * sin, z: x * sin + z * cos };
}

// Rotate a point around the X axis
function rotateX(y, z, angle) {
  const cos = Math.cos(angle), sin = Math.sin(angle);
  return { y: y * cos - z * sin, z: y * sin + z * cos };
}
```

### Floating Particles

**Lines:** ~55 | **Impact:** 8/10 | **Reliability:** 9/10
**Pairs with:** Any dark theme
**Fallback:** CSS gradient background (`linear-gradient(135deg, #1a1a2e, #16213e)`)

```javascript
// Floating 3D particles — atmospheric background for title/section slides
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
canvas.style.cssText = 'position:absolute;inset:0;z-index:0;pointer-events:none;';
slideElement.appendChild(canvas);
function resizeCanvas() { canvas.width = slideElement.offsetWidth; canvas.height = slideElement.offsetHeight; }
resizeCanvas(); window.addEventListener('resize', resizeCanvas);

// 80 particles distributed through 3D space
const particles = Array.from({length: 80}, () => ({
  x: (Math.random() - 0.5) * 800,
  y: (Math.random() - 0.5) * 600,
  z: Math.random() * 500,
  vx: (Math.random() - 0.5) * 0.3,
  vy: (Math.random() - 0.5) * 0.3,
  vz: (Math.random() - 0.5) * 0.2
}));

let animId;
function animate() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const camZ = 400;
  for (const p of particles) {
    // Drift and bounce off bounds
    p.x += p.vx; p.y += p.vy; p.z += p.vz;
    if (Math.abs(p.x) > 400) p.vx *= -1;
    if (Math.abs(p.y) > 300) p.vy *= -1;
    if (p.z > 500 || p.z < 0) p.vz *= -1;
    // Project to 2D — size and opacity attenuate with depth
    const scale = camZ / (camZ + p.z);
    const sx = p.x * scale + canvas.width / 2;
    const sy = p.y * scale + canvas.height / 2;
    const r = 3 * scale;
    const alpha = 0.6 * scale;
    ctx.beginPath();
    ctx.arc(sx, sy, r, 0, Math.PI * 2);
    // Use the deck's accent color as an RGB triplet, e.g. "120, 180, 255"
    ctx.fillStyle = `rgba(${accentColor}, ${alpha})`;
    ctx.fill();
  }
  animId = requestAnimationFrame(animate);
}
animate();
```

### Rotating Wireframe

**Lines:** ~70 | **Impact:** 7/10 | **Reliability:** 8/10
**Pairs with:** Tech-oriented themes
**Fallback:** Static SVG wireframe

```javascript
// Rotating icosahedron wireframe — tech aesthetic for title/section slides
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
canvas.style.cssText = 'position:absolute;inset:0;z-index:0;pointer-events:none;';
slideElement.appendChild(canvas);
canvas.width = slideElement.offsetWidth; canvas.height = slideElement.offsetHeight;

// 12 vertices of an icosahedron (golden ratio geometry)
const t = (1 + Math.sqrt(5)) / 2;
const S = 80; // scale factor
const vertices = [
  [-1,t,0],[1,t,0],[-1,-t,0],[1,-t,0],
  [0,-1,t],[0,1,t],[0,-1,-t],[0,1,-t],
  [t,0,-1],[t,0,1],[-t,0,-1],[-t,0,1]
].map(v => [v[0]*S, v[1]*S, v[2]*S]);

// 30 edges connecting the vertices
const edges = [
  [0,1],[0,5],[0,7],[0,10],[0,11],[1,5],[1,7],[1,8],[1,9],
  [2,3],[2,4],[2,6],[2,10],[2,11],[3,4],[3,6],[3,8],[3,9],
  [4,5],[4,9],[4,11],[5,9],[5,11],[6,7],[6,8],[6,10],
  [7,8],[7,10],[8,9],[10,11]
];

let angle = 0, animId;
function animate() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  angle += 0.005;
  const camZ = 400;

  for (const [i, j] of edges) {
    // Rotate each vertex around X and Y axes
    const [ax, ay, az] = vertices[i];
    const [bx, by, bz] = vertices[j];
    const ra = rotateY(ax, az, angle);
    const raX = rotateX(ay, ra.z, angle * 0.7);
    const rb = rotateY(bx, bz, angle);
    const rbX = rotateX(by, rb.z, angle * 0.7);
    // Project to 2D
    const pa = project(ra.x, raX.y, raX.z, camZ);
    const pb = project(rb.x, rbX.y, rbX.z, camZ);
    // Depth-attenuated alpha
    const alpha = ((pa.scale + pb.scale) / 2) * 0.8;
    ctx.beginPath();
    ctx.moveTo(pa.x, pa.y);
    ctx.lineTo(pb.x, pb.y);
    // Use the deck's accent color as an RGB triplet, e.g. "0, 255, 200"
    ctx.strokeStyle = `rgba(${accentColor}, ${alpha})`;
    ctx.lineWidth = 1.5 * ((pa.scale + pb.scale) / 2);
    ctx.stroke();
  }
  animId = requestAnimationFrame(animate);
}
animate();
```

### Starfield

**Lines:** ~20 CSS + ~5 JS | **Impact:** 7/10 | **Reliability:** 9/10
**Pairs with:** Any dark theme
**Fallback:** Dark gradient background

```css
/* Three star layers at different Z-depths with CSS 3D perspective */
.starfield {
  position: absolute; inset: 0; z-index: 0; pointer-events: none;
  perspective: 500px;
  transform-style: preserve-3d;
  overflow: hidden;
}
.star-layer {
  position: absolute; inset: 0;
  background-repeat: repeat;
}
.star-layer-1 { transform: translateZ(-200px) scale(1.4); animation: drift 60s linear infinite; }
.star-layer-2 { transform: translateZ(-100px) scale(1.2); animation: drift 40s linear infinite; }
.star-layer-3 { transform: translateZ(0px);               animation: drift 25s linear infinite; }
@keyframes drift { to { background-position: 0 -2000px; } }
```

```javascript
// Generate random star positions as radial-gradient backgrounds
document.querySelectorAll('.star-layer').forEach(layer => {
  const count = 80;
  const dots = Array.from({length: count}, () => {
    const x = Math.random() * 100, y = Math.random() * 100;
    const size = (Math.random() * 1.5 + 0.5).toFixed(1);
    return `radial-gradient(${size}px circle at ${x}% ${y}%, rgba(255,255,255,0.8), transparent)`;
  });
  layer.style.backgroundImage = dots.join(',');
});
```

### Dot-Globe

**Lines:** ~80 | **Impact:** 9/10 | **Reliability:** 8/10
**Pairs with:** Bold/modern themes
**Fallback:** AI-generated globe image

```javascript
// Rotating dot-sphere — geographic data or "global" messaging
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
canvas.style.cssText = 'position:absolute;inset:0;z-index:0;pointer-events:none;';
slideElement.appendChild(canvas);
canvas.width = slideElement.offsetWidth; canvas.height = slideElement.offsetHeight;

// Generate 400 points on sphere surface using golden spiral distribution
const points = [];
const N = 400;
const goldenAngle = Math.PI * (1 + Math.sqrt(5));
for (let i = 0; i < N; i++) {
  const y = 1 - (i / (N - 1)) * 2;           // -1 to 1
  const radius = Math.sqrt(1 - y * y);
  const theta = goldenAngle * i;
  points.push({
    x: Math.cos(theta) * radius * 150,
    y: y * 150,
    z: Math.sin(theta) * radius * 150,
    highlight: false  // set true for specific points (cities, data)
  });
}

let angle = 0, animId;
function animate() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  angle += 0.003;
  const camZ = 400;

  // Rotate all points, then depth-sort so back-facing dots draw first
  const sorted = points.map(p => {
    const r = rotateY(p.x, p.z, angle);
    return { ...p, rx: r.x, rz: r.z };
  }).sort((a, b) => a.rz - b.rz);

  for (const p of sorted) {
    if (p.rz < -10) continue;  // behind the globe — skip entirely
    const proj = project(p.rx, p.y, p.rz, camZ);
    const alpha = (p.rz + 150) / 300;  // fade back-facing dots
    ctx.beginPath();
    ctx.arc(proj.x, proj.y, 2 * proj.scale, 0, Math.PI * 2);
    ctx.fillStyle = p.highlight
      ? `rgba(255, 100, 50, ${alpha})`             // highlight color
      // Use the deck's accent color as an RGB triplet, e.g. "150, 200, 255"
      : `rgba(${accentColor}, ${alpha * 0.5})`;
    ctx.fill();
  }
  animId = requestAnimationFrame(animate);
}
animate();
```

### Network Graph

**Lines:** ~60 | **Impact:** 7/10 | **Reliability:** 7/10
**Pairs with:** Tech/engineering themes
**Fallback:** Static SVG diagram

```javascript
// 3D network graph — node positions PRE-COMPUTED by AI, not force-directed
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
canvas.style.cssText = 'position:absolute;inset:0;z-index:0;pointer-events:none;';
slideElement.appendChild(canvas);
canvas.width = slideElement.offsetWidth; canvas.height = slideElement.offsetHeight;

const nodes = [
  { label: 'Frontend',    x:   0, y: -80, z: 100 },
  { label: 'API Gateway', x:   0, y:   0, z:   0 },
  { label: 'Auth',        x:-120, y:  40, z: -50 },
  { label: 'Database',    x: 120, y:  40, z: -50 },
  // AI generates layout based on slide content
];
const edges = [[0,1],[1,2],[1,3]];

let angle = 0, animId;
function animate() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  angle += 0.004;  // gentle rotation reveals depth
  const camZ = 500;

  // Project all nodes
  const projected = nodes.map(n => {
    const r = rotateY(n.x, n.z, angle);
    const p = project(r.x, n.y, r.z, camZ);
    return { ...n, sx: p.x, sy: p.y, scale: p.scale, rz: r.z };
  });

  // Draw edges
  for (const [i, j] of edges) {
    const a = projected[i], b = projected[j];
    const alpha = ((a.scale + b.scale) / 2) * 0.6;
    ctx.beginPath();
    ctx.moveTo(a.sx, a.sy);
    ctx.lineTo(b.sx, b.sy);
    // Use the deck's accent color as an RGB triplet
    ctx.strokeStyle = `rgba(${accentColor}, ${alpha})`;
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  // Draw nodes and labels (depth-sorted, front to back)
  projected.sort((a, b) => a.rz - b.rz);
  for (const n of projected) {
    const r = 6 * n.scale;
    ctx.beginPath();
    ctx.arc(n.sx, n.sy, r, 0, Math.PI * 2);
    // Use the deck's accent color as an RGB triplet
    ctx.fillStyle = `rgba(${accentColor}, ${n.scale * 0.9})`;
    ctx.fill();
    // Label
    ctx.font = `${Math.round(11 * n.scale)}px sans-serif`;
    ctx.fillStyle = `rgba(255, 255, 255, ${n.scale * 0.8})`;
    ctx.textAlign = 'center';
    ctx.fillText(n.label, n.sx, n.sy - r - 4);
  }
  animId = requestAnimationFrame(animate);
}
animate();
```

### Abstract Mesh

**Lines:** ~90 | **Impact:** 8/10 | **Reliability:** 7/10
**Pairs with:** Dark/atmospheric themes
**Fallback:** CSS gradient or AI-generated abstract image

```javascript
// Undulating triangle mesh — atmospheric background with depth
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
canvas.style.cssText = 'position:absolute;inset:0;z-index:0;pointer-events:none;';
slideElement.appendChild(canvas);
canvas.width = slideElement.offsetWidth; canvas.height = slideElement.offsetHeight;

// Generate a grid of points with random offset
const cols = 16, rows = 10;
const cellW = canvas.width / (cols - 1), cellH = canvas.height / (rows - 1);
const grid = [];
for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
  grid.push({
    baseX: c * cellW + (Math.random() - 0.5) * cellW * 0.4,
    baseZ: r * cellH + (Math.random() - 0.5) * cellH * 0.4
  });
}

let time = 0, animId;
function animate() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  time += 0.015;
  // Animate Y (height) with sin/cos wave
  const pts = grid.map(p => ({
    x: p.baseX, z: p.baseZ,
    y: Math.sin(p.baseX * 0.005 + time) * Math.cos(p.baseZ * 0.005 + time) * 40
  }));
  // Draw triangle strips row by row
  for (let r = 0; r < rows - 1; r++) {
    for (let c = 0; c < cols - 1; c++) {
      const i = r * cols + c;
      const tl = pts[i], tr = pts[i + 1];
      const bl = pts[i + cols], br = pts[i + cols + 1];

      for (const tri of [[tl, tr, bl], [tr, br, bl]]) {  // two triangles per cell
        const avgY = (tri[0].y + tri[1].y + tri[2].y) / 3;
        const alpha = 0.3 + ((avgY + 40) / 80) * 0.3;  // height-based color variation
        ctx.beginPath();
        ctx.moveTo(tri[0].x, tri[0].z - tri[0].y);
        ctx.lineTo(tri[1].x, tri[1].z - tri[1].y);
        ctx.lineTo(tri[2].x, tri[2].z - tri[2].y);
        ctx.closePath();
        // Use the deck's accent color as an RGB triplet
        ctx.fillStyle = `rgba(${accentColor}, ${alpha.toFixed(2)})`;
        ctx.fill();
        ctx.strokeStyle = `rgba(${accentColor}, ${(alpha * 0.5).toFixed(2)})`;
        ctx.lineWidth = 0.5; ctx.stroke();
      }
    }
  }
  animId = requestAnimationFrame(animate);
}
animate();
```

### Visibility Manager

Pause animations on non-visible slides. Attach to every Canvas pattern above.

```javascript
const animations = new Map();  // slideElement -> { start, stop }
function registerAnimation(slideEl, startFn, stopFn) { animations.set(slideEl, { start: startFn, stop: stopFn }); }
const observer = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    const anim = animations.get(e.target);
    if (!anim) return;
    e.isIntersecting ? anim.start() : anim.stop();
  });
}, { threshold: 0.1 });
// Usage: registerAnimation(slideEl, animate, () => cancelAnimationFrame(animId));
// observer.observe(slideEl);
```

### Feature Detection

```javascript
const canAnimate = (() => { try { return !!document.createElement('canvas').getContext('2d'); } catch { return false; } })();
const prefersMotion = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (canAnimate && prefersMotion) { /* init Canvas 2D effects */ }
else { slideElement.style.background = 'linear-gradient(135deg, #1a1a2e, #16213e)'; }
```
