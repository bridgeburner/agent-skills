# Slide Layouts

Complete CSS class definitions and HTML structure for all 19 named slide layouts. Every layout follows the shared HTML convention and builds on top of the base CSS in [base-css.md](base-css.md).

## HTML Convention

Every slide uses this structure regardless of layout:

```html
<section class="slide {layout-class}" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <!-- Layout-specific structure -->
  </div>
</section>
```

- `.slide-bg` is optional (omit if no background image).
- `.slide-content` always wraps the inner content.
- Layout-specific child elements are documented per layout below.

---

## Foundation Layouts

### `title`

Opening slide. Hero background image with minimal overlaid text.

**Content limit:** 12 words max (1 heading + 1 subtitle + optional tagline).

```html
<section class="slide title" id="slide-1">
  <div class="slide-bg" style="background-image: url('assets/slide-01-hero.png')"></div>
  <div class="slide-content">
    <h1>Presentation Title</h1>
    <p class="subtitle">A short subtitle or tagline</p>
  </div>
</section>
```

```css
.slide.title .slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.3) 50%, transparent 100%);
}
.slide.title .slide-content {
  justify-content: flex-end;
  align-items: flex-start;
  padding-bottom: calc(var(--slide-padding) * 2);
}
.slide.title h1 {
  font-size: var(--title-size);
  font-weight: 800;
  line-height: 1.1;
}
.slide.title .subtitle {
  font-size: var(--h3-size);
  color: var(--text-secondary);
  margin-top: var(--element-gap);
}
```

### `section-divider`

Chapter break with large decorative number or keyword. Signals a topic shift.

**Content limit:** 8 words max (section number + heading + optional subtitle).

```html
<section class="slide section-divider" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <span class="section-number">01</span>
    <h2>Section Title</h2>
    <p class="section-subtitle">Optional brief context</p>
  </div>
</section>
```

```css
.slide.section-divider .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
}
.slide.section-divider .section-number {
  font-size: clamp(4rem, 15vw, 12rem);
  font-weight: 800;
  opacity: 0.15;
  position: absolute;
  line-height: 1;
}
.slide.section-divider h2 {
  font-size: var(--title-size);
  font-weight: 700;
  position: relative;
  z-index: 1;
}
.slide.section-divider .section-subtitle {
  font-size: var(--h3-size);
  color: var(--text-secondary);
  margin-top: var(--element-gap);
}
```

### `content`

Standard bullet content, left-aligned. The default workhorse for text-heavy slides.

**Content limit:** 40-50 words max, 4-6 bullet points, 1-2 lines per bullet.

```html
<section class="slide content" id="slide-{n}">
  <div class="slide-content">
    <h2>Slide Heading</h2>
    <ul class="bullet-list">
      <li>First point</li>
      <li>Second point</li>
      <li>Third point</li>
    </ul>
  </div>
</section>
```

```css
.slide.content .slide-content {
  justify-content: center;
  align-items: flex-start;
  gap: var(--content-gap);
}
.slide.content h2 {
  font-size: var(--h2-size);
  font-weight: 700;
}
.slide.content .bullet-list {
  list-style: none;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--element-gap);
}
.slide.content .bullet-list li {
  font-size: var(--body-size);
  line-height: 1.5;
  padding-left: 1.5em;
  position: relative;
}
.slide.content .bullet-list li::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0.6em;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
}
```

### `statement`

Single powerful sentence, very large centered text. Typography IS the visual.

**Content limit:** 15 words max, single sentence.

```html
<section class="slide statement" id="slide-{n}">
  <div class="slide-content">
    <h2>The future belongs to those who <span class="highlight">build</span> it.</h2>
  </div>
</section>
```

```css
.slide.statement .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: calc(var(--slide-padding) * 2);
}
.slide.statement h2 {
  font-size: clamp(2rem, 6vw, 5rem);
  font-weight: 700;
  line-height: 1.15;
  max-width: 20ch;
}
.slide.statement .highlight {
  color: var(--accent);
}
```

### `end`

Closing slide / call-to-action. Similar to title but with CTA elements.

**Content limit:** 12 words max (heading + CTA text + optional contact info).

```html
<section class="slide end" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <h2>Thank You</h2>
    <p class="cta">Get started at example.com</p>
    <p class="contact">team@example.com</p>
  </div>
</section>
```

```css
.slide.end .slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.4) 50%, transparent 100%);
}
.slide.end .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
  gap: var(--element-gap);
}
.slide.end h2 {
  font-size: var(--title-size);
  font-weight: 800;
}
.slide.end .cta {
  font-size: var(--h3-size);
  color: var(--accent);
}
.slide.end .contact {
  font-size: var(--body-size);
  color: var(--text-secondary);
}
```

---

## Image-Forward Layouts

### `hero-bottom`

Full-bleed background image with text anchored to the bottom via a floor-fade gradient.

**Content limit:** 20 words max. **Image aspect ratio:** 16:9.

```html
<section class="slide hero-bottom" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <h2>Headline Over Image</h2>
    <p>Supporting text sits on the gradient floor.</p>
  </div>
</section>
```

```css
.slide.hero-bottom {
  padding: 0;
}
.slide.hero-bottom .slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.4) 40%, transparent 70%);
}
.slide.hero-bottom .slide-content {
  justify-content: flex-end;
  padding: var(--slide-padding);
  padding-bottom: calc(var(--slide-padding) * 1.5);
}
```

### `hero-center`

Full-bleed background image with centered text inside a frosted-glass scrim.

**Content limit:** 12 words max. **Image aspect ratio:** 16:9.

```html
<section class="slide hero-center" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <h2>Centered Statement</h2>
    <p>Brief supporting line</p>
  </div>
</section>
```

```css
.slide.hero-center .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
}
.slide.hero-center .slide-content::before {
  content: '';
  position: absolute;
  inset: 20% 10%;
  background: rgba(0,0,0,0.5);
  backdrop-filter: blur(8px);
  border-radius: 1rem;
  z-index: -1;
}
```

### `hero-left`

Full-bleed background image with text pinned to the left third via a left-to-right gradient.

**Content limit:** 30 words max. **Image aspect ratio:** 16:9.

```html
<section class="slide hero-left" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <h2>Left-Anchored Heading</h2>
    <p>More room for supporting text in this sidebar region.</p>
  </div>
</section>
```

```css
.slide.hero-left .slide-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to right, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.5) 35%, transparent 65%);
}
.slide.hero-left .slide-content {
  max-width: 50%;
  padding: var(--slide-padding);
  justify-content: center;
}
```

### `split-50-50`

Balanced half-image, half-text. The workhorse of professional decks.

**Content limit:** 30-40 words in text column, 3-5 bullets. **Image aspect ratio:** 3:4 or 4:3.

Use `split-50-50-reverse` to flip the image to the right side.

```html
<section class="slide split-50-50" id="slide-{n}">
  <div class="slide-media">
    <img src="assets/..." alt="Description">
  </div>
  <div class="slide-text">
    <h2>Heading</h2>
    <p>Supporting text or bullet list here.</p>
  </div>
</section>
```

```css
.slide.split-50-50 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  padding: 0;
}
.slide.split-50-50-reverse {
  display: grid;
  grid-template-columns: 1fr 1fr;
  padding: 0;
}
.slide.split-50-50-reverse .slide-media {
  order: 2;
}
.slide.split-50-50-reverse .slide-text {
  order: 1;
}
.slide[class*="split-"] .slide-media {
  height: 100%;
  overflow: hidden;
}
.slide[class*="split-"] .slide-media img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.slide[class*="split-"] .slide-text {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: var(--slide-padding);
  gap: var(--content-gap);
}
```

### `split-60-40`

Image-dominant split (60% image, 40% text). Use when the image is the star.

**Content limit:** 25-30 words in text column. **Image aspect ratio:** 3:4.

```html
<!-- Same structure as split-50-50 -->
<section class="slide split-60-40" id="slide-{n}">
  <div class="slide-media">
    <img src="assets/..." alt="Description">
  </div>
  <div class="slide-text">
    <h2>Heading</h2>
    <p>Brief supporting text.</p>
  </div>
</section>
```

```css
.slide.split-60-40 {
  display: grid;
  grid-template-columns: 3fr 2fr;
  padding: 0;
}
```

### `split-40-60`

Text-dominant split (40% image, 60% text). Use when text needs room to breathe.

**Content limit:** 40-50 words in text column, up to 5 bullets. **Image aspect ratio:** 4:3.

```html
<!-- Same structure as split-50-50 -->
<section class="slide split-40-60" id="slide-{n}">
  <div class="slide-media">
    <img src="assets/..." alt="Description">
  </div>
  <div class="slide-text">
    <h2>Heading</h2>
    <ul class="bullet-list">
      <li>Point one</li>
      <li>Point two</li>
      <li>Point three</li>
    </ul>
  </div>
</section>
```

```css
.slide.split-40-60 {
  display: grid;
  grid-template-columns: 2fr 3fr;
  padding: 0;
}
```

### `image-gallery`

2-4 images in an asymmetric mosaic. First image spans full height on the left, remaining images stack on the right.

**Content limit:** Optional heading (8 words max), 2-4 images. **Image aspect ratio:** mixed.

```html
<section class="slide image-gallery" id="slide-{n}">
  <div class="slide-content">
    <h2>Gallery Title</h2>
    <div class="gallery-grid">
      <div class="gallery-item"><img src="assets/..." alt="..."></div>
      <div class="gallery-item"><img src="assets/..." alt="..."></div>
      <div class="gallery-item"><img src="assets/..." alt="..."></div>
    </div>
  </div>
</section>
```

```css
.slide.image-gallery .gallery-grid {
  display: grid;
  grid-template-columns: 3fr 2fr;
  grid-template-rows: 1fr 1fr;
  gap: clamp(0.25rem, 0.5vw, 0.5rem);
  height: min(70vh, 600px);
  width: 100%;
}
.slide.image-gallery .gallery-grid .gallery-item:first-child {
  grid-row: 1 / -1;
}
.slide.image-gallery .gallery-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 0.5rem;
}
```

---

## Data & Metrics Layouts

### `big-number`

Single huge statistic with a label. For metrics, milestones, market size.

**Content limit:** 10 words + the number. No bullets.

```html
<section class="slide big-number" id="slide-{n}">
  <div class="slide-content">
    <div class="stat-value">$4.2B</div>
    <div class="stat-label">Total addressable market by 2027</div>
    <div class="stat-context">Growing at 34% CAGR</div>
  </div>
</section>
```

```css
.slide.big-number .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
}
.slide.big-number .stat-value {
  font-size: clamp(4rem, 15vw, 12rem);
  font-weight: 800;
  line-height: 1;
  color: var(--accent);
}
.slide.big-number .stat-label {
  font-size: var(--h2-size);
  color: var(--text-secondary);
  margin-top: var(--element-gap);
  max-width: 60ch;
}
.slide.big-number .stat-context {
  font-size: var(--body-size);
  color: var(--text-secondary);
  opacity: 0.7;
  margin-top: calc(var(--element-gap) * 0.5);
}
```

### `stats-row`

2-4 metrics displayed side by side. Dashboard or comparison feel.

**Content limit:** 15-20 words total, 2-4 stat items.

```html
<section class="slide stats-row" id="slide-{n}">
  <div class="slide-content">
    <h2>Key Metrics</h2>
    <div class="stats-container">
      <div class="stat-item">
        <div class="stat-value">99.9%</div>
        <div class="stat-label">Uptime</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">2M+</div>
        <div class="stat-label">Users</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">150ms</div>
        <div class="stat-label">Avg Response</div>
      </div>
    </div>
  </div>
</section>
```

```css
.slide.stats-row .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
  gap: var(--content-gap);
}
.slide.stats-row .stats-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: var(--content-gap);
  width: 100%;
  max-width: 1000px;
  margin: 0 auto;
}
.slide.stats-row .stat-item {
  text-align: center;
}
.slide.stats-row .stat-value {
  font-size: clamp(2rem, 8vw, 5rem);
  font-weight: 800;
  color: var(--accent);
  line-height: 1.1;
}
.slide.stats-row .stat-label {
  font-size: var(--body-size);
  color: var(--text-secondary);
  margin-top: calc(var(--element-gap) * 0.5);
}
```

### `comparison`

Two-column layout with a visual divider for comparing options, features, or before/after.

**Content limit:** 40-50 words total, 3-5 items per column.

```html
<section class="slide comparison" id="slide-{n}">
  <div class="slide-content">
    <h2>Before vs. After</h2>
    <div class="comparison-grid">
      <div class="comparison-column">
        <h3>Before</h3>
        <ul><li>Manual processes</li><li>Slow feedback</li></ul>
      </div>
      <div class="comparison-divider"></div>
      <div class="comparison-column">
        <h3>After</h3>
        <ul><li>Fully automated</li><li>Real-time insights</li></ul>
      </div>
    </div>
  </div>
</section>
```

```css
.slide.comparison .slide-content {
  justify-content: center;
  gap: var(--content-gap);
}
.slide.comparison .comparison-grid {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: var(--content-gap);
  align-items: start;
  width: 100%;
}
.slide.comparison .comparison-divider {
  width: 2px;
  background: var(--text-secondary);
  opacity: 0.2;
  align-self: stretch;
}
.slide.comparison .comparison-column h3 {
  font-size: var(--h3-size);
  margin-bottom: var(--element-gap);
  color: var(--accent);
}
.slide.comparison .comparison-column ul {
  list-style: none;
  padding: 0;
}
.slide.comparison .comparison-column li {
  font-size: var(--body-size);
  padding: calc(var(--element-gap) * 0.5) 0;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}
```

---

## Structured Content Layouts

### `grid-cards`

2x2 or 2x3 grid of icon + title + description cards. Max 6 cards (hard limit for viewport fitting).

**Content limit:** 60-80 words total across all cards. Max 6 cards.

```html
<section class="slide grid-cards" id="slide-{n}">
  <div class="slide-content">
    <h2>Features</h2>
    <div class="card-grid">
      <div class="card">
        <div class="card-icon">⚡</div>
        <h3>Fast</h3>
        <p>Sub-100ms response times across all endpoints.</p>
      </div>
      <!-- More cards -->
    </div>
  </div>
</section>
```

```css
.slide.grid-cards .slide-content {
  justify-content: center;
  gap: var(--content-gap);
}
.slide.grid-cards .card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 280px), 1fr));
  gap: var(--content-gap);
  width: 100%;
}
.slide.grid-cards .card {
  background: rgba(255,255,255,0.05);
  border-radius: 0.75rem;
  padding: clamp(1rem, 2vw, 1.5rem);
  display: flex;
  flex-direction: column;
  gap: calc(var(--element-gap) * 0.5);
}
.slide.grid-cards .card .card-icon {
  font-size: clamp(1.5rem, 3vw, 2.5rem);
}
.slide.grid-cards .card h3 {
  font-size: var(--h3-size);
}
.slide.grid-cards .card p {
  font-size: var(--body-size);
  color: var(--text-secondary);
  line-height: 1.4;
}
```

### `timeline`

Horizontal sequence of 3-5 connected steps. Stacks vertically on mobile.

**Content limit:** 50-60 words total, 3-5 steps.

```html
<section class="slide timeline" id="slide-{n}">
  <div class="slide-content">
    <h2>Our Process</h2>
    <div class="timeline-track">
      <div class="timeline-step" data-step="1">
        <h3>Research</h3>
        <p>Deep dive into user needs and market landscape.</p>
      </div>
      <div class="timeline-step" data-step="2">
        <h3>Design</h3>
        <p>Rapid prototyping and iterative refinement.</p>
      </div>
      <div class="timeline-step" data-step="3">
        <h3>Ship</h3>
        <p>Launch with confidence, measure, improve.</p>
      </div>
    </div>
  </div>
</section>
```

```css
.slide.timeline .slide-content {
  justify-content: center;
  gap: var(--content-gap);
}
.slide.timeline .timeline-track {
  display: flex;
  justify-content: space-between;
  position: relative;
  width: 100%;
  padding-top: 2rem;
}
.slide.timeline .timeline-track::before {
  content: '';
  position: absolute;
  top: 0;
  left: 5%;
  right: 5%;
  height: 2px;
  background: var(--accent);
  opacity: 0.3;
}
.slide.timeline .timeline-step {
  flex: 1;
  text-align: center;
  padding: 0 clamp(0.5rem, 1vw, 1rem);
  position: relative;
}
.slide.timeline .timeline-step::before {
  content: attr(data-step);
  position: absolute;
  top: -2rem;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  background: var(--accent);
  color: var(--bg-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: var(--small-size);
}
.slide.timeline .timeline-step h3 {
  font-size: var(--h3-size);
  margin-bottom: calc(var(--element-gap) * 0.5);
}
.slide.timeline .timeline-step p {
  font-size: var(--body-size);
  color: var(--text-secondary);
}
```

### `quote`

Large centered blockquote with decorative quotation mark and attribution.

**Content limit:** 40 words max. Optional background image.

```html
<section class="slide quote" id="slide-{n}">
  <div class="slide-bg" style="background-image: url('assets/...')"></div>
  <div class="slide-content">
    <blockquote>The best way to predict the future is to invent it.</blockquote>
    <div class="attribution">
      <strong>Alan Kay</strong>, Computer Scientist
    </div>
  </div>
</section>
```

```css
.slide.quote .slide-content {
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: calc(var(--slide-padding) * 2);
}
.slide.quote blockquote {
  font-size: clamp(1.25rem, 3.5vw, 2.5rem);
  font-style: italic;
  line-height: 1.4;
  max-width: 50ch;
  position: relative;
}
.slide.quote blockquote::before {
  content: '\201C';
  font-size: clamp(4rem, 10vw, 8rem);
  position: absolute;
  top: -0.5em;
  left: -0.3em;
  color: var(--accent);
  opacity: 0.3;
  font-style: normal;
  line-height: 1;
}
.slide.quote .attribution {
  font-size: var(--body-size);
  color: var(--text-secondary);
  margin-top: var(--content-gap);
}
.slide.quote .attribution strong {
  color: var(--text-primary);
}
```

### `team-grid`

Headshots with names and roles. 3-4 people per slide.

**Content limit:** 3-4 members. Name + role per member. **Image aspect ratio:** 1:1 (portraits).

```html
<section class="slide team-grid" id="slide-{n}">
  <div class="slide-content">
    <h2>Our Team</h2>
    <div class="team-members">
      <div class="member">
        <img src="assets/..." alt="Jane Doe headshot">
        <h3>Jane Doe</h3>
        <p class="role">CEO & Co-founder</p>
      </div>
      <!-- More members -->
    </div>
  </div>
</section>
```

```css
.slide.team-grid .slide-content {
  justify-content: center;
  align-items: center;
  gap: var(--content-gap);
}
.slide.team-grid .team-members {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--content-gap);
  max-width: 900px;
  margin: 0 auto;
}
.slide.team-grid .member {
  text-align: center;
}
.slide.team-grid .member img {
  width: clamp(80px, 12vw, 150px);
  height: clamp(80px, 12vw, 150px);
  border-radius: 50%;
  object-fit: cover;
  margin-bottom: var(--element-gap);
}
.slide.team-grid .member h3 {
  font-size: var(--h3-size);
}
.slide.team-grid .member .role {
  font-size: var(--small-size);
  color: var(--text-secondary);
}
```

### `logo-wall`

Partner, client, or technology logo grid. Common for "trusted by" slides.

**Content limit:** Heading + 6-12 logos. No body text.

```html
<section class="slide logo-wall" id="slide-{n}">
  <div class="slide-content">
    <h2>Trusted By</h2>
    <div class="logos">
      <img src="assets/logo-a.png" alt="Company A">
      <img src="assets/logo-b.png" alt="Company B">
      <!-- More logos -->
    </div>
  </div>
</section>
```

```css
.slide.logo-wall .slide-content {
  justify-content: center;
  align-items: center;
  gap: var(--content-gap);
  text-align: center;
}
.slide.logo-wall .logos {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: clamp(1.5rem, 4vw, 3rem);
  max-width: 900px;
  margin: 0 auto;
}
.slide.logo-wall .logos img {
  height: clamp(30px, 5vw, 60px);
  width: auto;
  max-height: 60px;
  object-fit: contain;
  filter: grayscale(1) brightness(0.8);
  opacity: 0.6;
  transition: all 0.3s;
}
```

---

## Shared Split Layout Styles

These rules apply to ALL split variants (`split-50-50`, `split-50-50-reverse`, `split-60-40`, `split-40-60`). They are defined once using an attribute selector.

```css
/* Shared media column for all split layouts */
.slide[class*="split-"] .slide-media {
  height: 100%;
  overflow: hidden;
}
.slide[class*="split-"] .slide-media img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.slide[class*="split-"] .slide-text {
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: var(--slide-padding);
  gap: var(--content-gap);
}
```

---

## Image Sizing

These overrides replace the base-css defaults for layout-specific contexts.

```css
/* Split layout images: full-height cover, no max-height constraint */
.slide[class*="split-"] .slide-media img {
  max-height: none;
  height: 100%;
  object-fit: cover;
}

/* Inset images in content slides: taller allowance than base default */
.slide.content .slide-image,
.slide.content .slide-figure img {
  max-height: min(65vh, 550px);
  object-fit: contain;
}

/* Gallery images fill their grid cell */
.slide.image-gallery .gallery-item img {
  max-height: none;
}
```

---

## Responsive Stacking

All multi-column layouts stack vertically below 768px. Include this block after all layout definitions.

```css
@media (max-width: 768px) {
  /* Split layouts: image on top, text below */
  .slide[class*="split-"] {
    grid-template-columns: 1fr;
    grid-template-rows: 45% 1fr;
    padding: 0;
  }
  .slide.split-50-50-reverse .slide-media,
  .slide.split-50-50-reverse .slide-text {
    order: unset;
  }

  /* Comparison: single column */
  .slide.comparison .comparison-grid {
    grid-template-columns: 1fr;
  }
  .slide.comparison .comparison-divider {
    width: 100%;
    height: 2px;
  }

  /* Stats: 2-up grid */
  .slide.stats-row .stats-container {
    grid-template-columns: repeat(2, 1fr);
  }

  /* Team: 2-up grid */
  .slide.team-grid .team-members {
    grid-template-columns: repeat(2, 1fr);
  }

  /* Hero-left: full width text */
  .slide.hero-left .slide-content {
    max-width: 100%;
  }
}

/* Timeline stacks at narrower breakpoint (phone width) */
@media (max-width: 600px) {
  .slide.timeline .timeline-track {
    flex-direction: column;
    gap: var(--content-gap);
    padding-top: 0;
    padding-left: 2rem;
  }
  .slide.timeline .timeline-track::before {
    top: 0;
    bottom: 0;
    left: 0;
    right: auto;
    width: 2px;
    height: auto;
  }
  .slide.timeline .timeline-step {
    text-align: left;
  }
  .slide.timeline .timeline-step::before {
    top: 0;
    left: -2rem;
    transform: translate(-50%, 0);
  }
}
```
