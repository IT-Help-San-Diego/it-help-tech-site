+++
title = "Brand Colors"
description = "Canonical brand color system reference for IT Help San Diego."
path = "brand-colors"
in_search_index = false

[extra]
skip_author = true
skip_image = true
robots = "noindex, nofollow"
stylesheets = ["css/brand-colors.css"]
scripts = ["js/brand-colors.js"]
+++
<div class="brand-colors-page">
<p class="brand-colors-kicker">IT Help San Diego Inc.</p>
<p class="brand-colors-intro">Canonical palette and token reference for design, engineering, and vendor handoff. The brand is led by the <strong>METACOGNITIVE coin</strong> with a <strong>gold IT+HELP wordmark</strong>; blue is the action / link family. This page is public for sharing and is marked <code>noindex, nofollow</code>.</p>
<div class="brand-copy-actions brand-top-actions" role="group" aria-label="Copy all values">
<button type="button" class="brand-copy-btn" id="copy-all-hex">Copy all HEX</button>
<button type="button" class="brand-copy-btn" id="copy-all-css">Copy all CSS vars</button>
</div>
<div class="brand-priority-palette" role="list" aria-label="Primary brand palette preview">
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-logo-gold-mid" aria-hidden="true"></span>Logo Gold <code>#D2B56F</code></span>
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-plus-red" aria-hidden="true"></span>Plus Red <code>#FF0066</code></span>
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-logo-gold-top" aria-hidden="true"></span>Gold Highlight <code>#E0C58A</code></span>
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-logo-gold-bottom" aria-hidden="true"></span>Gold Shadow <code>#A8843E</code></span>
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-schedule-blue-mid" aria-hidden="true"></span>Action Blue <code>#3F86D8</code></span>
<span class="brand-priority-chip" role="listitem"><span class="brand-mini-swatch swatch-brand-blue" aria-hidden="true"></span>Primary Blue <code>#58A6FF</code></span>
</div>
<section class="brand-section brand-mark-section" aria-labelledby="brand-mark">
<div class="brand-section-head">
<h2 id="brand-mark">Brand Mark: the METACOGNITIVE coin</h2>
<p>Primary identity element. It heads the home page and appears on the site's icons, on its default link-preview picture and on its mail logo.</p>
<p>This coin is the company's mark. It is the METACOGNITIVE semaphore of <a href="https://tetrasemaphore.systems/">the Tetrasemaphore</a>, a notation of four signs that mark how a piece of work stands. Used as a logo it marks the company, and says nothing about the standing of the page it sits on. An Athenian owl medallion was the mark before it.</p>
</div>
<figure class="brand-mark-figure">
<picture>
<source srcset="/img/brand/metacognitive-720.webp" type="image/webp">
<img src="/img/brand/metacognitive-720.png" alt="The METACOGNITIVE coin of the Tetrasemaphore, the mark of IT Help San Diego" width="360" height="360" loading="lazy" decoding="async" class="brand-mark-image">
</picture>
<figcaption>Greek-key border in gold. On a dark ground, in the coin's own colour, the sign σₕ above a gold line and its mirror image below. Files: <code>/img/brand/metacognitive-720.webp</code> (WebP) and <code>/img/brand/metacognitive-720.png</code> (PNG fallback).</figcaption>
</figure>
</section>
<section class="brand-section" aria-labelledby="core-brand-colors">
<div class="brand-section-head">
<h2 id="core-brand-colors">Core Brand Colors</h2>
<p>Primary identity colors only.</p>
</div>
<div class="brand-grid">
<article class="brand-card">
<div class="brand-swatch swatch-brand-blue" aria-hidden="true"></div>
<h3>Primary Blue Anchor</h3>
<p class="brand-token"><code>--brand-blue</code></p>
<p class="brand-value"><code>#58A6FF</code></p>
<p class="brand-note">Primary hue anchor across identity and action states.</p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-plus-red" aria-hidden="true"></div>
<h3>Plus Red</h3>
<p class="brand-token"><code>.logo-plus</code></p>
<p class="brand-value"><code>#FF0066</code></p>
<p class="brand-note">Reserved for the plus symbol only.</p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-gold-accent" aria-hidden="true"></div>
<h3>Gold Accent</h3>
<p class="brand-token"><code>--accent-gold</code></p>
<p class="brand-value"><code>#C2A15A</code></p>
<p class="brand-note">Premium utility accent in controlled usage.</p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-gold-stroke" aria-hidden="true"></div>
<h3>Gold Stroke</h3>
<p class="brand-token"><code>--accent-gold-solid</code></p>
<p class="brand-value"><code>#D2B56F</code></p>
<p class="brand-note">Stroke/perimeter gold for logo and hero pill border match.</p>
</article>
</div>
</section>
<section class="brand-section" aria-labelledby="logo-gold-ramp">
<div class="brand-section-head">
<h2 id="logo-gold-ramp">Logo Authority Gold Ramp (Athenian-Owl Banner)</h2>
<p>IT+HELP wordmark fill and topbar banner gold tones. <code>--brand-logo-gold-mid</code> is the dark-mode letter color of <code>.logo-it</code> and <code>.logo-help</code>; in light mode (<code>html.switch</code>) the letters drop one luminance step to <code>--brand-gold</code> (<code>#C2A15A</code>) for contrast against the off-white surface.</p>
</div>
<div class="brand-grid brand-grid-3up">
<article class="brand-card">
<div class="brand-swatch swatch-logo-gold-top" aria-hidden="true"></div>
<h3>Logo Gold Top</h3>
<p class="brand-token"><code>--brand-logo-gold-top</code></p>
<p class="brand-value"><code>#E0C58A</code></p>
<p class="brand-note">Highlight tone for wordmark dimensionality.</p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-logo-gold-mid" aria-hidden="true"></div>
<h3>Logo Gold Mid</h3>
<p class="brand-token"><code>--brand-logo-gold-mid</code></p>
<p class="brand-value"><code>#D2B56F</code></p>
<p class="brand-note">Dark-mode IT+HELP letter fill. Light mode steps down to <code>--brand-gold</code> (<code>#C2A15A</code>). Same value as <code>--brand-gold-solid</code> (different role).</p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-logo-gold-bottom" aria-hidden="true"></div>
<h3>Logo Gold Bottom</h3>
<p class="brand-token"><code>--brand-logo-gold-bottom</code></p>
<p class="brand-value"><code>#A8843E</code></p>
<p class="brand-note">Shadow tone for banner depth and weight.</p>
</article>
</div>
</section>
<section class="brand-section brand-section-heritage" aria-labelledby="legacy-logo-blue">
<div class="brand-section-head">
<h2 id="legacy-logo-blue">Legacy Logo Blue Ramp <span class="brand-section-tag">retained as token aliases only</span></h2>
<p>The IT+HELP wordmark used this blue ramp before the gold transition. Tokens remain in <code>tokens.css</code> for back-compat but are no longer consumed by any selector. Do not use for new components.</p>
</div>
<div class="brand-grid brand-grid-3up">
<article class="brand-card">
<div class="brand-swatch swatch-logo-blue-top" aria-hidden="true"></div>
<h3>Legacy Logo Blue Top</h3>
<p class="brand-token"><code>--brand-logo-blue-top</code></p>
<p class="brand-value"><code>#327ED6</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-logo-blue-mid" aria-hidden="true"></div>
<h3>Legacy Logo Blue Mid</h3>
<p class="brand-token"><code>--brand-logo-blue-mid</code></p>
<p class="brand-value"><code>#2662AA</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-logo-blue-bottom" aria-hidden="true"></div>
<h3>Legacy Logo Blue Bottom</h3>
<p class="brand-token"><code>--brand-logo-blue-bottom</code></p>
<p class="brand-value"><code>#13437A</code></p>
</article>
</div>
</section>
<section class="brand-section" aria-labelledby="schedule-family">
<div class="brand-section-head">
<h2 id="schedule-family">Schedule and Nav Blue Family</h2>
<p>Action blues kept one step below logo luminance hierarchy.</p>
</div>
<div class="brand-grid">
<article class="brand-card">
<div class="brand-swatch swatch-schedule-blue-top" aria-hidden="true"></div>
<h3>Schedule Ramp Top</h3>
<p class="brand-token"><code>--schedule-blue-top</code></p>
<p class="brand-value"><code>#6CAFEF</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-blue-mid" aria-hidden="true"></div>
<h3>Schedule Ramp Mid</h3>
<p class="brand-token"><code>--schedule-blue-mid</code></p>
<p class="brand-value"><code>#3F86D8</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-blue-bottom" aria-hidden="true"></div>
<h3>Schedule Ramp Bottom</h3>
<p class="brand-token"><code>--schedule-blue-bottom</code></p>
<p class="brand-value"><code>#2359A9</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-top" aria-hidden="true"></div>
<h3>CTA Base Top</h3>
<p class="brand-token"><code>--schedule-cta-top</code></p>
<p class="brand-value"><code>#3D659A</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-mid" aria-hidden="true"></div>
<h3>CTA Base Mid</h3>
<p class="brand-token"><code>--schedule-cta-mid</code></p>
<p class="brand-value"><code>#244A79</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-bottom" aria-hidden="true"></div>
<h3>CTA Base Bottom</h3>
<p class="brand-token"><code>--schedule-cta-bottom</code></p>
<p class="brand-value"><code>#123055</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-border" aria-hidden="true"></div>
<h3>CTA Border</h3>
<p class="brand-token"><code>--schedule-cta-border</code></p>
<p class="brand-value"><code>rgba(88, 131, 187, 0.40)</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-hover-top" aria-hidden="true"></div>
<h3>CTA Hover Top</h3>
<p class="brand-token"><code>--schedule-cta-hover-top</code></p>
<p class="brand-value"><code>#4673AA</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-hover-mid" aria-hidden="true"></div>
<h3>CTA Hover Mid</h3>
<p class="brand-token"><code>--schedule-cta-hover-mid</code></p>
<p class="brand-value"><code>#2D5A8D</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-hover-bottom" aria-hidden="true"></div>
<h3>CTA Hover Bottom</h3>
<p class="brand-token"><code>--schedule-cta-hover-bottom</code></p>
<p class="brand-value"><code>#1C436F</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-schedule-cta-hover-border" aria-hidden="true"></div>
<h3>CTA Hover Border</h3>
<p class="brand-token"><code>--schedule-cta-hover-border</code></p>
<p class="brand-value"><code>rgba(104, 151, 211, 0.52)</code></p>
</article>
</div>
</section>
<section class="brand-section" aria-labelledby="theme-links-surfaces">
<div class="brand-section-head">
<h2 id="theme-links-surfaces">Links and Surface Colors</h2>
<p>Theme-safe link and background references.</p>
</div>
<div class="brand-grid">
<article class="brand-card">
<div class="brand-swatch swatch-dark-link" aria-hidden="true"></div>
<h3>Dark Link</h3>
<p class="brand-token"><code>$a1d</code></p>
<p class="brand-value"><code>#79B8FF</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-dark-link-hover" aria-hidden="true"></div>
<h3>Dark Link Hover</h3>
<p class="brand-token"><code>$a2d</code></p>
<p class="brand-value"><code>#A5D0FF</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-light-link" aria-hidden="true"></div>
<h3>Light Link</h3>
<p class="brand-token"><code>$a1</code></p>
<p class="brand-value"><code>#2B6FCD</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-light-link-hover" aria-hidden="true"></div>
<h3>Light Link Hover</h3>
<p class="brand-token"><code>$a2</code></p>
<p class="brand-value"><code>#4A8EDF</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-dark-bg-primary" aria-hidden="true"></div>
<h3>Dark Background Primary</h3>
<p class="brand-token"><code>$c1d</code></p>
<p class="brand-value"><code>#0D1117</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-dark-bg-secondary" aria-hidden="true"></div>
<h3>Dark Background Secondary</h3>
<p class="brand-token"><code>$c2d</code></p>
<p class="brand-value"><code>#161B22</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-light-bg-primary" aria-hidden="true"></div>
<h3>Light Background Primary</h3>
<p class="brand-token"><code>$c1</code></p>
<p class="brand-value"><code>#FAFBFC</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-light-bg-secondary" aria-hidden="true"></div>
<h3>Light Background Secondary</h3>
<p class="brand-token"><code>$c2</code></p>
<p class="brand-value"><code>#F5F5F7</code></p>
</article>
</div>
</section>
<section class="brand-section" aria-labelledby="text-neutrals">
<div class="brand-section-head">
<h2 id="text-neutrals">Text and Lockup Neutrals</h2>
<p>Support tones and structural text values.</p>
</div>
<div class="brand-grid brand-grid-3up">
<article class="brand-card">
<div class="brand-swatch swatch-light-text" aria-hidden="true"></div>
<h3>Light Text</h3>
<p class="brand-value"><code>#FFFFFF</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-secondary-text" aria-hidden="true"></div>
<h3>Secondary Text</h3>
<p class="brand-value"><code>#B2BAC5</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-location-dark" aria-hidden="true"></div>
<h3>San Diego (Dark)</h3>
<p class="brand-token"><code>.location</code></p>
<p class="brand-value"><code>#566376</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-location-light" aria-hidden="true"></div>
<h3>San Diego (Light)</h3>
<p class="brand-token"><code>html.switch .location</code></p>
<p class="brand-value"><code>#404D5B</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-brand-accent-ink" aria-hidden="true"></div>
<h3>Brand Accent Ink</h3>
<p class="brand-token"><code>--brand-accent-ink</code></p>
<p class="brand-value"><code>#16120A</code></p>
</article>
</div>
</section>
<section class="brand-section" aria-labelledby="effect-channels">
<div class="brand-section-head">
<h2 id="effect-channels">Effect Channel References</h2>
<p>RGB channel pairs used for glow and lighting effects.</p>
</div>
<div class="brand-grid brand-grid-2up">
<article class="brand-card">
<div class="brand-swatch swatch-brand-blue" aria-hidden="true"></div>
<h3>Brand Blue RGB</h3>
<p class="brand-token"><code>--brand-blue-rgb</code></p>
<p class="brand-value"><code>88, 166, 255</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-brand-blue-glow" aria-hidden="true"></div>
<h3>Brand Blue Glow</h3>
<p class="brand-token"><code>--brand-blue-glow</code></p>
<p class="brand-value"><code>176, 218, 255</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-gold-accent" aria-hidden="true"></div>
<h3>Gold RGB</h3>
<p class="brand-token"><code>--accent-gold-rgb</code></p>
<p class="brand-value"><code>194, 161, 90</code></p>
</article>
<article class="brand-card">
<div class="brand-swatch swatch-gold-glow" aria-hidden="true"></div>
<h3>Gold Glow</h3>
<p class="brand-token"><code>--accent-gold-glow</code></p>
<p class="brand-value"><code>224, 197, 138</code></p>
</article>
</div>
</section>
<section class="brand-section brand-rules" aria-labelledby="brand-rules">
<div class="brand-section-head">
<h2 id="brand-rules">Brand Rules</h2>
</div>
<ol>
<li>The METACOGNITIVE coin is the primary brand mark; the IT+HELP wordmark is its lockup partner.</li>
<li>IT+HELP letters render in the owl-banner gold ramp: <code>--logo-gold-mid</code> (<code>#D2B56F</code>) in dark mode, stepping down to <code>--brand-gold</code> (<code>#C2A15A</code>) in light mode for surface contrast. The legacy logo-blue ramp is retained as token aliases only and is not used on the wordmark in either theme.</li>
<li>Red is reserved for the plus symbol — never for body text, links, or other accents.</li>
<li>Action / link / schedule blues sit one luminance step below the wordmark gold so the lockup remains the dominant signal.</li>
<li>Gold accent (<code>--brand-gold</code>) and gold stroke (<code>--brand-gold-solid</code>) are used in restrained doses on hero pill border and CTA trim; they share hue with the logo gold ramp by design.</li>
<li><code>san diego</code> stays subordinate steel-blue gray (<code>#566376</code> dark / <code>#404D5B</code> light).</li>
<li>Do not mint ad hoc colors without updating <code>STYLE_GUIDE.md</code> and <code>static/css/tokens.css</code> in the same PR; <code>scripts/check-token-parity.sh</code> enforces no-hex-in-component-CSS.</li>
</ol>
</section>
</div>
