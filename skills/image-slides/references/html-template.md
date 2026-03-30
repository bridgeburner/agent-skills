# HTML Template

Complete HTML architecture template for slide presentations. Single HTML file with inline CSS/JS, viewport-locked slides, and scroll-snap navigation.

> **Note:** This template includes base styles inline for completeness. The authoritative CSS definitions live in `base-css.md` — if values diverge, `base-css.md` is the source of truth.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Presentation Title</title>

    <!-- Fonts (use Fontshare or Google Fonts) -->
    <link rel="stylesheet" href="https://api.fontshare.com/v2/css?f[]=...">

    <style>
        /* ===========================================
           CSS CUSTOM PROPERTIES (THEME)
           Easy to modify: change these to change the whole look
           =========================================== */
        :root {
            /* Colors */
            --bg-primary: #0a0f1c;
            --bg-secondary: #111827;
            --text-primary: #ffffff;
            --text-secondary: #9ca3af;
            --accent: #00ffcc;
            --accent-glow: rgba(0, 255, 204, 0.3);

            /* Typography - MUST use clamp() for responsive scaling */
            --font-display: 'Clash Display', sans-serif;
            --font-body: 'Satoshi', sans-serif;
            --title-size: clamp(2rem, 6vw, 5rem);
            --h2-size: clamp(1.5rem, 3.5vw, 2.75rem);
            --h3-size: clamp(1.25rem, 2.5vw, 2rem);
            --body-size: clamp(1rem, 2vw, 1.5rem);
            --small-size: clamp(0.875rem, 1.5vw, 1.125rem);

            /* Spacing - MUST use clamp() for responsive scaling */
            --slide-padding: clamp(1.5rem, 4vw, 4rem);
            --content-gap: clamp(1rem, 2vw, 2rem);
            --element-gap: clamp(0.25rem, 1vw, 1rem);

            /* Animation */
            --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
            --ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);
            --ease-in-out-smooth: cubic-bezier(0.65, 0, 0.35, 1);
            --duration-fast: 300ms;
            --duration-normal: 600ms;
            --duration-slow: 1000ms;
            --stagger-step: 80ms;
        }

        /* ===========================================
           BASE STYLES
           =========================================== */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
            scroll-snap-type: y mandatory;
            height: 100%;
        }

        body {
            font-family: var(--font-body);
            background: var(--bg-primary);
            color: var(--text-primary);
            overflow-x: hidden;
            height: 100%;
        }

        /* ===========================================
           SLIDE CONTAINER
           CRITICAL: Each slide MUST fit exactly in viewport
           - Use height: 100vh (NOT min-height)
           - Use overflow: hidden to prevent scroll
           - Content must scale with clamp() values
           =========================================== */
        .slide {
            width: 100vw;
            height: 100vh; /* EXACT viewport height - no scrolling */
            height: 100dvh; /* Dynamic viewport height for mobile */
            padding: var(--slide-padding);
            scroll-snap-align: start;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
            overflow: hidden; /* Prevent any content overflow */
        }

        /* Content wrapper that prevents overflow */
        .slide-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            max-height: 100%;
            overflow: hidden;
        }

        /* ===========================================
           IMAGE STYLES
           Background and inset image treatments.
           Preset-specific overrides loaded from presets/{preset}.md.
           =========================================== */

        /* Full-bleed background image */
        .slide-bg {
            position: absolute;
            inset: 0;
            background-size: cover;
            background-position: center;
            z-index: 0;
            /* + preset-specific filter from presets/{preset}.md */
        }

        .slide-bg + .slide-content {
            position: relative;
            z-index: 1;
        }

        /* Inset image */
        .slide-image {
            max-width: 100%;
            max-height: min(50vh, 400px);
            object-fit: contain;
            /* + preset-specific filter, border, shadow from presets/{preset}.md */
        }

        /* Image with caption */
        .slide-figure {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: var(--element-gap, 0.5rem);
        }

        .slide-figure figcaption {
            font-size: var(--small-size, 0.875rem);
            color: var(--text-secondary);
        }

        /* ===========================================
           PRESET-SPECIFIC IMAGE CSS
           Copy the appropriate block from presets/{preset}.md
           Each preset defines .slide-image and .slide-bg overrides
           =========================================== */

        /* ... preset image CSS goes here ... */

        /* ===========================================
           RESPONSIVE BREAKPOINTS
           Adjust content for different screen sizes
           =========================================== */
        @media (max-height: 600px) {
            :root {
                --slide-padding: clamp(1rem, 3vw, 2rem);
                --content-gap: clamp(0.5rem, 1.5vw, 1rem);
            }
        }

        @media (max-width: 768px) {
            :root {
                --title-size: clamp(1.75rem, 8vw, 3.5rem);
            }
        }

        @media (max-height: 500px) and (orientation: landscape) {
            /* Extra compact for landscape phones */
            :root {
                --title-size: clamp(1.25rem, 5vw, 2.25rem);
                --body-size: clamp(0.875rem, 1.5vw, 1.125rem);
                --slide-padding: clamp(0.75rem, 2vw, 1.5rem);
            }
        }

        /* ===========================================
           ANIMATIONS
           Trigger via .visible class (added by JS on scroll)
           =========================================== */
        .reveal {
            opacity: 0;
            transform: translateY(30px);
            transition: opacity var(--duration-normal) var(--ease-out-expo),
                        transform var(--duration-normal) var(--ease-out-expo);
        }

        .slide.visible .reveal {
            opacity: 1;
            transform: translateY(0);
        }

        /* Stagger children */
        .reveal:nth-child(1) { transition-delay: 0.1s; }
        .reveal:nth-child(2) { transition-delay: 0.2s; }
        .reveal:nth-child(3) { transition-delay: 0.3s; }
        .reveal:nth-child(4) { transition-delay: 0.4s; }

        /* ... more styles ... */
    </style>
</head>
<body>
    <!-- Progress bar (optional) -->
    <div class="progress-bar"></div>

    <!-- Navigation dots (optional) -->
    <nav class="nav-dots">
        <!-- Generated by JS -->
    </nav>

    <!-- Slides -->

    <!-- Title slide with hero background image -->
    <section class="slide title-slide">
        <div class="slide-bg" style="background-image: url('{name}-assets/slide-01-hero.png')"></div>
        <div class="slide-content">
            <h1 class="reveal">Presentation Title</h1>
            <p class="reveal">Subtitle or author</p>
        </div>
    </section>

    <!-- Content slide with inset image -->
    <section class="slide">
        <div class="slide-content">
            <h2 class="reveal">Slide Title</h2>
            <p class="reveal">Content...</p>
            <figure class="slide-figure reveal">
                <img class="slide-image" src="{name}-assets/slide-03-concept.png" alt="Descriptive alt text">
                <figcaption>Optional caption</figcaption>
            </figure>
        </div>
    </section>

    <!-- Text-only slide (no image needed) -->
    <section class="slide">
        <div class="slide-content">
            <h2 class="reveal">Slide Title</h2>
            <p class="reveal">Content...</p>
        </div>
    </section>

    <!-- More slides... -->

    <script>
        /* ===========================================
           SLIDE PRESENTATION CONTROLLER
           Handles keyboard/touch/scroll navigation,
           progress bar, nav dots, and scroll-triggered
           animations via IntersectionObserver.
           =========================================== */

        class SlidePresentation {
            constructor() {
                this.slides = [...document.querySelectorAll('.slide')];
                this.currentIndex = 0;
                this.progressBar = document.querySelector('.progress-bar');
                this.navContainer = document.querySelector('.nav-dots');
                this.reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
                this.touchStartY = 0;

                this.buildNavDots();
                this.setupIntersectionObserver();
                this.setupKeyboard();
                this.setupTouch();
                this.updateProgress();
            }

            /* --- Nav dots --- */
            buildNavDots() {
                if (!this.navContainer) return;
                this.navContainer.innerHTML = this.slides
                    .map((_, i) => `<button class="nav-dot${i === 0 ? ' active' : ''}" aria-label="Go to slide ${i + 1}"></button>`)
                    .join('');
                this.dots = [...this.navContainer.querySelectorAll('.nav-dot')];
                this.navContainer.addEventListener('click', e => {
                    const dot = e.target.closest('.nav-dot');
                    if (dot) this.goTo(this.dots.indexOf(dot));
                });
            }

            /* --- IntersectionObserver: track current slide + trigger .visible --- */
            setupIntersectionObserver() {
                const observer = new IntersectionObserver(entries => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            entry.target.classList.add('visible');
                            const idx = this.slides.indexOf(entry.target);
                            if (idx !== -1) {
                                this.currentIndex = idx;
                                this.updateProgress();
                                this.updateDots();
                            }
                        }
                    });
                }, { threshold: 0.5 });
                this.slides.forEach(s => observer.observe(s));
            }

            /* --- Keyboard navigation --- */
            setupKeyboard() {
                document.addEventListener('keydown', e => {
                    switch (e.key) {
                        case 'ArrowDown': case 'ArrowRight': case ' ': case 'PageDown':
                            e.preventDefault(); this.next(); break;
                        case 'ArrowUp': case 'ArrowLeft': case 'PageUp':
                            e.preventDefault(); this.prev(); break;
                        case 'Home':
                            e.preventDefault(); this.goTo(0); break;
                        case 'End':
                            e.preventDefault(); this.goTo(this.slides.length - 1); break;
                    }
                });
            }

            /* --- Touch / swipe support --- */
            setupTouch() {
                document.addEventListener('touchstart', e => {
                    this.touchStartY = e.touches[0].clientY;
                }, { passive: true });
                document.addEventListener('touchend', e => {
                    const dy = this.touchStartY - e.changedTouches[0].clientY;
                    if (Math.abs(dy) > 50) dy > 0 ? this.next() : this.prev();
                });
            }

            /* --- Navigation helpers --- */
            next() { this.goTo(Math.min(this.currentIndex + 1, this.slides.length - 1)); }
            prev() { this.goTo(Math.max(this.currentIndex - 1, 0)); }
            goTo(index) {
                this.slides[index].scrollIntoView({ behavior: this.reducedMotion ? 'auto' : 'smooth' });
            }

            /* --- UI updates --- */
            updateProgress() {
                if (!this.progressBar) return;
                const pct = ((this.currentIndex + 1) / this.slides.length) * 100;
                this.progressBar.style.width = pct + '%';
            }
            updateDots() {
                if (!this.dots) return;
                this.dots.forEach((d, i) => d.classList.toggle('active', i === this.currentIndex));
            }
        }

        // Initialize when DOM is ready
        new SlidePresentation();
    </script>
</body>
</html>
```
