# Base CSS

Complete mandatory base styles for viewport-fitting slide presentations. Every presentation MUST include these styles.

```css
/* ===========================================
   Z-INDEX STACKING ORDER
   0: .slide-bg         — background images
   1: .slide-content     — main content (when following .slide-bg)
   2: decorative elements — section numbers, watermarks, floating accents
   3: slide navigation   — progress bar, nav dots
   4: overlays           — modals, expanded images, lightboxes
   =========================================== */

/* ===========================================
   VIEWPORT FITTING: MANDATORY BASE STYLES
   These styles MUST be included in every presentation.
   They ensure slides fit exactly in the viewport.
   =========================================== */

/* 1. Lock html/body to viewport */
html, body {
    height: 100%;
    overflow-x: hidden;
}

html {
    scroll-snap-type: y mandatory;
    scroll-behavior: smooth;
}

/* 2. Each slide = exact viewport height */
.slide {
    width: 100vw;
    height: 100vh;
    height: 100dvh; /* Dynamic viewport height for mobile browsers */
    overflow: hidden; /* CRITICAL: Prevent ANY overflow */
    scroll-snap-align: start;
    display: flex;
    flex-direction: column;
    position: relative;
}

/* 3. Content container with flex for centering */
.slide-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    max-height: 100%;
    overflow: hidden; /* Double-protection against overflow */
    padding: var(--slide-padding);
}

/* 4. ALL typography uses clamp() for responsive scaling */
:root {
    /* Titles scale from mobile to desktop — presentation-sized */
    --title-size: clamp(2rem, 5vw, 4rem);
    --h2-size: clamp(1.5rem, 3.5vw, 2.75rem);
    --h3-size: clamp(1.25rem, 2.5vw, 2rem);

    /* Body text — presentation-sized (min 1.5rem / 24px at max viewport) */
    --body-size: clamp(1rem, 2vw, 1.5rem);
    --small-size: clamp(0.875rem, 1.5vw, 1.125rem);

    /* Spacing scales with viewport */
    --slide-padding: clamp(1rem, 4vw, 4rem);
    --content-gap: clamp(0.5rem, 2vw, 2rem);
    --element-gap: clamp(0.25rem, 1vw, 1rem);
}

/* 5. Cards/containers use viewport-relative max sizes */
.card, .container, .content-box {
    max-width: min(90vw, 1000px);
    max-height: min(80vh, 700px);
}

/* 6. Lists auto-scale with viewport */
.feature-list, .bullet-list {
    gap: clamp(0.4rem, 1vh, 1rem);
}

.feature-list li, .bullet-list li {
    font-size: var(--body-size);
    line-height: 1.4;
}

/* 7. Grids adapt to available space */
.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));
    gap: clamp(0.5rem, 1.5vw, 1rem);
}

/* 8. Images constrained to viewport */
img, .image-container {
    max-width: 100%;
    max-height: min(50vh, 400px);
    object-fit: contain;
}

/* 9. Full-bleed background images for hero slides */
.slide-bg {
    position: absolute;
    inset: 0;
    background-size: cover;
    background-position: center;
    z-index: 0;
    /* Preset-specific filter/brightness applied per-preset */
}

.slide-bg + .slide-content {
    position: relative;
    z-index: 1;
}

/* 10. Inset images with preset treatment */
.slide-image {
    max-width: 100%;
    max-height: min(50vh, 400px);
    object-fit: contain;
    /* Preset-specific filter, border, shadow applied per-preset */
}

/* 11. Image with caption */
.slide-figure {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--element-gap);
}

.slide-figure figcaption {
    font-size: var(--small-size);
    color: var(--text-secondary);
}

/* ===========================================
   RESPONSIVE BREAKPOINTS
   Aggressive scaling for smaller viewports
   =========================================== */

/* Short viewports (< 700px height) */
@media (max-height: 700px) {
    :root {
        --slide-padding: clamp(0.75rem, 3vw, 2rem);
        --content-gap: clamp(0.4rem, 1.5vw, 1rem);
        --title-size: clamp(1.5rem, 4.5vw, 3rem);
        --h2-size: clamp(1.25rem, 3vw, 2rem);
    }
}

/* Very short viewports (< 600px height) */
@media (max-height: 600px) {
    :root {
        --slide-padding: clamp(0.5rem, 2.5vw, 1.5rem);
        --content-gap: clamp(0.3rem, 1vw, 0.75rem);
        --title-size: clamp(1.25rem, 4vw, 2.25rem);
        --body-size: clamp(0.875rem, 1.5vw, 1.125rem);
    }

    /* Hide non-essential elements */
    .nav-dots, .keyboard-hint, .decorative {
        display: none;
    }
}

/* Extremely short (landscape phones, < 500px height) */
@media (max-height: 500px) {
    :root {
        --slide-padding: clamp(0.4rem, 2vw, 1rem);
        --title-size: clamp(1.1rem, 3.5vw, 1.75rem);
        --h2-size: clamp(1rem, 2.5vw, 1.5rem);
        --body-size: clamp(0.75rem, 1.2vw, 1rem);
    }
}

/* Narrow viewports (< 600px width) */
@media (max-width: 600px) {
    :root {
        --title-size: clamp(1.5rem, 7vw, 3rem);
    }

    /* Stack grids vertically */
    .grid {
        grid-template-columns: 1fr;
    }
}

/* ===========================================
   REDUCED MOTION
   Respect user preferences
   =========================================== */
@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.2s !important;
    }

    html {
        scroll-behavior: auto;
    }
}

/* ===========================================
   UTILITY CLASSES
   Reusable visual treatments for cards, panels,
   and accent text. Apply to any element.
   =========================================== */

/* Frosted glass panel — use on cards, text panels over hero images, nav overlays */
.glass {
    backdrop-filter: blur(16px) saturate(180%);
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 1rem;
}

/* Gradient accent text — applies preset accent color(s) as text fill */
.gradient-text {
    background: linear-gradient(135deg, var(--accent), var(--accent-secondary, var(--accent)));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}
```
