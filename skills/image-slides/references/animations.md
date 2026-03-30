# Animation System

Reduced-motion-first animation catalog for slide presentations. Static by default; motion is opt-in via `prefers-reduced-motion: no-preference`.

## 1. Timing Custom Properties

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

## 2. Reduced-Motion-First Authoring

All transform/clip-path transitions and `@keyframes` live inside the motion media query. Outside it, elements use opacity-only fades.

```css
/* Base: no motion — elements fade in without movement */
.reveal, .reveal-scale, .reveal-left, .reveal-right,
.reveal-blur, .reveal-clip-up, .reveal-clip-left, .reveal-bounce { opacity: 0; }
.visible .reveal, .visible .reveal-scale, .visible .reveal-left, .visible .reveal-right,
.visible .reveal-blur, .visible .reveal-clip-up, .visible .reveal-clip-left,
.visible .reveal-bounce { opacity: 1; transition: opacity var(--duration-fast) ease-out; }

@media (prefers-reduced-motion: no-preference) {
  /* Sections 3–5 content goes here */
}
```

Everything in sections 3–5 is wrapped inside that `@media` block.

## 3. Entrance Animations

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

## 4. Stagger Pattern

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

## 5. Image-Specific Animations

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

## 6. Background Effects

```css
.gradient-bg {
  background: radial-gradient(ellipse at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(0, 255, 200, 0.2) 0%, transparent 50%), var(--bg-primary); }

.noise-bg { background-image: url("data:image/svg+xml,..."); /* Inline SVG noise */ }

.grid-bg {
  background-image: linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 50px 50px; }
```

## 7. Per-Slide-Type Recommendations

| Layout | Primary animation | Image animation | Notes |
|---|---|---|---|
| `title` | `reveal-scale` | `ken-burns` | Hero bg gets Ken Burns |
| `section-divider` | `reveal-clip-up` | — | Bold geometric entrance |
| `content` | `stagger-children` + `reveal` | — | Items appear sequentially |
| `hero-bottom` | `reveal` (text) | `ken-burns` (bg) | Text over cinematic image |
| `split-50-50` | `reveal-left` / `reveal-right` | — | Mirror directions for balance |
| `big-number` | `reveal-scale` | — | The number scales in |
| `quote` | `reveal-blur` | — | Dreamy, contemplative entrance |
| `grid-cards` | `stagger-children` + `reveal-scale` | — | Cards appear one by one |
| `timeline` | `stagger-children` + `reveal-left` | — | Steps flow left to right |

## 8. IntersectionObserver Trigger

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
