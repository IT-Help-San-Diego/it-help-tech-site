# Style Guide (Living)
Last updated: 2026-04-23

Purpose: Keep the visual system consistent and readable across the site. Update this file whenever palette, typography, or motion choices change.

## Brand Mark
- Primary identity element: the **Athenian owl medallion** at `/img/brand/owl-720.{webp,png}`. Greek-key border, gold owl on dark ground. Pairs with the IT+HELP wordmark across hero, topbar, polos, and collateral.

## Brand Colors
- IT+HELP Wordmark Gold Ramp (Athenian-Owl Banner) — **the live wordmark fill**:
  - Top: `#E0C58A` (`--brand-logo-gold-top`)
  - Mid: `#D2B56F` (`--brand-logo-gold-mid`) — dark-mode fill of `.logo-it` and `.logo-help`
  - Bottom: `#A8843E` (`--brand-logo-gold-bottom`)
  - Light-mode override: `html.switch .logo-it` and `html.switch .logo-help` use `--brand-gold` (`#C2A15A`) — one luminance step down — for contrast against the off-white surface (see `static/css/late-overrides.css`).
- Primary Blue (shared hue anchor for actions/glow/particles): `#58A6FF`
  - Source of truth: `--brand-blue` in `static/css/tokens.css`
  - If changed, also update:
    - `--brand-blue-rgb` (comma RGB)
    - `--brand-blue-glow` (particle glow)
- Legacy Logo Blue Ramp (retained as token aliases only — **no longer used on IT+HELP letters**; do not use for new components):
  - Top: `#327ED6` (`--brand-logo-blue-top` / `--logo-blue-top`)
  - Mid: `#2662AA` (`--brand-logo-blue-mid` / `--logo-blue-mid`)
  - Bottom: `#13437A` (`--brand-logo-blue-bottom` / `--logo-blue-bottom`)
- Schedule Indigo Depth Ramp:
  - Top: `#6CAFEF` (`--schedule-blue-top`)
  - Mid: `#3F86D8` (`--schedule-blue-mid`)
  - Bottom: `#2359A9` (`--schedule-blue-bottom`)
- Schedule CTA Operational Ramp (button-specific depth tokens):
  - Base Top: `#3D659A` (`--schedule-cta-top`)
  - Base Mid: `#244A79` (`--schedule-cta-mid`)
  - Base Bottom: `#123055` (`--schedule-cta-bottom`)
  - Hover Top: `#4673AA` (`--schedule-cta-hover-top`)
  - Hover Mid: `#2D5A8D` (`--schedule-cta-hover-mid`)
  - Hover Bottom: `#1C436F` (`--schedule-cta-hover-bottom`)
- Body/Utility Link Blue (same hue family, action-biased):
  - Dark mode link: `#79B8FF` (`$a1d`)
  - Dark mode hover: `#A5D0FF` (`$a2d`)
  - Light mode link: `#2B6FCD` (`$a1`)
  - Light mode hover: `#4A8EDF` (`$a2`)
- Gold Accent (reserved accent): `#C2A15A`
- Gold Stroke (pillbox/wordmark border match): `#D2B56F` (`--accent-gold-solid`)
- Plus Red (plus symbol only): `#FF0066`
- Dark Background: `#0D1117` (primary), `#161B22` (elevated surface)
- Light Text: `#FFFFFF`
- Secondary Text: `#B2BAC5` (e.g., "SAN DIEGO")

## Usage Rules
- Keep one hue family but use role-based depth:
  - Logo = deeper authority blue.
  - Schedule/link actions = clearly actionable blue, but on dark pages prefer a darker CTA tone to avoid glowing too bright.
- IT/HELP lettering should use a bright blue solid core with subtle highlight/depth shadows for dimensionality (Safari-stable rendering).
- Blue direction: indigo-leaning (avoid consumer "UI chrome" blues and avoid cyan drift).
- Current lock target: true non-purple blue aligned to DNS Tool `--status-info` (`#58A6FF`) as the anchor.
- High-emphasis blue surfaces (IT/HELP lettering and Schedule button) should remain in the same family even when depth differs by role.
- Standard text links (including phone/map links) should remain in-family with Schedule blue, only shifting brightness for contrast by theme.
- Current blue target: DNS-aligned true blue (non-purple), with depth from shading rather than violet tint.
- If the logo reads purplish on Apple displays, cool hue by a small step (increase green/reduce red) before changing luminance.
- Render IT/HELP letters as a single text layer; avoid duplicated pseudo-text overlays that can create ghosting on retina and screenshot captures.
- Prefer shadow-based edge treatment for IT/HELP lettering by default; if gold wrap remains imperceptible, use a controlled `-webkit-text-stroke` pass (roughly `0.9px`-`1.2px`) with solid fill and no glow-heavy stack.
- For solid premium outlines, use near-integer stroke widths (`~1px`) with a tiny gold smoothing halo; avoid thin sub-pixel strokes that can look jagged.
- To avoid inner horseshoe artifacts on curved glyphs (notably `P`), prefer `paint-order: stroke fill`; if bottom edges read weak, add only a subtle downward gold micro-shadow.
- For cleaner curved tops (especially `P` shoulder), avoid negative-Y top highlight strokes; prefer a centered micro gold smoothing halo plus a downward closure pass.
- Gold wrap continuity target: if perimeter looks broken, use a low-radius centered halo (`~0.2px`) plus a small positive-Y closure (`~0.4-0.6px`) before increasing stroke thickness further.
- If a shoulder spur appears only on desktop, apply desktop-only reductions to stroke/halo first (`@media (min-width: 700px)`) and keep mobile values unchanged.
- If a desktop-only glyph artifact persists, snap desktop logo size and optical offsets to integer-pixel geometry before adding more effect layers.
- For a bolder headline-wrap experiment, raise gold perimeter stroke into the `~1.2px-1.3px` range and keep `P` as a controlled per-glyph carveout.
- If curved-edge noise persists, prefer pure `-webkit-text-stroke` perimeter with no extra gold `filter` stack before increasing effect complexity.
- Keep Apple rendering weight consistent: do not downshift IT/HELP glyphs to `800` in Safari-targeted overrides; keep the logo at its core heavyweight geometry.
- Keep logo color strategy blue-led: gold should remain a restrained edge hint only, not a dominant fill impression.
- IT/HELP hierarchy target: keep `IT` on the deeper mid-blue and `HELP` roughly 3-5% lighter (top-blue token) for subtle lockup dominance without breaking cohesion.
- IT/HELP lettering should favor stable depth (tonal fill + restrained edge) over attention-grabbing glow.
- Current IT/HELP finish target: blue-dominant fill with strong silhouette presence (slightly larger wordmark, restrained gloss, crisp contour).
- IT/HELP gold treatment, if used, should be a thin perimeter band around glyph edges (all sides) with blue fill visually dominant.
- Build the strip as a larger outer gold ring under a smaller inner blue contour ring in `text-shadow` order so the perimeter remains visible in Safari.
- Keep perimeter ring weights top/bottom balanced to avoid rough edge artifacts on rounded glyph shoulders (especially `P`) on desktop Safari.
- Prefer a drop-shadow perimeter ring for IT/HELP edge treatment when Safari shows curved-edge artifacts from dense directional text-shadow stacks.
- When the ring reads too faint, match the glyph perimeter color to the hero pill gold stroke (`#D2B56F`) before increasing blur or glow.
- If visibility is still insufficient after ring tuning, apply direct stroke using `--accent-gold-solid` so gold perimeter remains unmistakable across desktop/mobile.
- Apply micro-kerning and optical offsets to IT/HELP consistently across desktop and mobile; avoid relying on one breakpoint tune.
- Avoid silver/steel casts in IT/HELP lettering by keeping cool overlay alpha restrained.
- Keep logo rendering Safari-stable: use solid indigo fill + shadow depth and avoid `background-clip:text` gradients on IT/HELP glyphs.
- For Safari/iOS stability, keep IT/HELP fill as `currentColor` and avoid transparent text fill paths that can introduce curved-edge artifacts.
- Gold-forward fallback snapshot (if we intentionally choose that direction): `main@a3b9ea2` from PR `#430`; use it as the restore baseline for logo color treatment.
- Use Gold in controlled doses: CTA button style and restrained logo trim only.
- Red is reserved for the plus sign.
- Avoid introducing new colors without updating this guide.
- Do not use gold as a general link/highlight color across body content.
- Keep the red plus sign unchanged; it is a core identity anchor.
- Plus symbol vertical alignment target: `top: -0.055em` on `.logo-plus` to keep optical center aligned with IT/HELP cap height.
- Plus treatment should remain red (`#FF0066`) with subtle depth via shadow shaping; do not hue-shift it toward pink/purple.
- Plus motion should remain subtle-but-visible in normal mode (a brief micro-jitter pulse), and be disabled only when `prefers-reduced-motion` is set.
- Keep IT/HELP edge outlining for readability and depth, but tune intensity before adding thickness.
- Current target is a subdued edge treatment (~25% quieter than the original high-contrast pass) in `static/css/late-overrides.css`.
- `san diego` lockup should read as steel-blue gray (not flat gray), with a tight optical gap under IT/HELP and consistent desktop/mobile proportion.
- Keep the `san diego` size ratio to the IT/HELP mark visually consistent across breakpoints (desktop and mobile should read like the same lockup, not two different logo scales).
- `san diego` must remain visually subordinate to `IT+HELP`: lower luminance, softer glow, and lighter emphasis than primary brand text.
- Apply a small optical center nudge to `san diego` when needed so it sits centered under the composite `IT+HELP` glyph mass, not just mathematically centered text bounds.
- Keep vertical lockup breathing room: `san diego` should never touch/scrunch into `IT+HELP`; favor a slightly lower placement over over-tight stacking.
- Keep explicit descender clearance: the `g` in `san diego` should never approach the hero tagline border; preserve visible gap in both desktop and mobile lockups.
- Tone target for `san diego`: steel gray-blue (not brand-logo blue) so hierarchy stays clear even when the lockup is centered and tight.
- Hero tagline panel should remain dark-first and high-legibility, but may use light translucency in dark mode; do not make it fully transparent.
- Hero tagline panel should be translucent enough to reveal background motion subtly, but never use backdrop blur that softens tagline readability.
- Hero tagline panel interior in dark mode should stay cool navy-blue translucent; avoid warm/brown casts.
- Hero tagline gold frame should read as a crisp solid perimeter on mobile and desktop.
- Hero tagline border weight target is slightly restrained (about `1.75px`) so the pill frames content without competing with the IT/HELP lockup.
- Hero tagline optical centering: keep bottom padding ~`1px` greater than top so two-line copy sits centered in the rounded shell.
- Implement hero tagline perimeter as a true gold border stroke (not a warm fill band) to avoid muddy color bleed on iPhone.
- Avoid inner highlight seams on the hero pill: no inset white line, inset border ring, or inner blue edge that can read as a gap on mobile.
- Keep hero pill interior as a clean flat translucent navy surface (no faux bevel/tilt gradients) for a tighter professional finish.
- Keep hero pill as a single-surface shell (border + translucent fill on outer wrapper, transparent text layer) to prevent inner-gap artifacts.
- Hero tagline copy is `IT research that solves.` (single line) with `solves` as the gold highlight phrase. The H1 directly below carries the literal proposition (`We solve tech problems. No monthly retainers.`) for SEO; the hero pill carries the brand character (research as the method, problem-solving as the identity). Do not duplicate the H1 verbatim inside the pill. Avoid `in motion` (collides with the defunct "Research In Motion" / BlackBerry name) and avoid superlatives per the owner humility rule — `solves` states what the work does, not self-superiority.
- Highlight words inside the hero tagline (`solves`) should remain crisp; avoid glow blur on those terms.
- Topbar surface treatment is stratified by capability, not just by width: BASE rule (all viewports) sets `background: var(--c1)` so the topbar is opaque and exactly matches body bg — by construction no chroma/luminance step exists at the topbar/body junction, so no seam can render. DESKTOP rule (`@media (min-width: 961px) and (hover: hover) and (pointer: fine)`) re-enables the Apple glass aesthetic + 38% gold WCAG 1.4.11 hairline, but mixes from `--c1` (not `--surface-charcoal`) so even in translucent state the topbar reads continuous with the page. TOUCH override (`@media (hover: none), (pointer: coarse)`) forces the solid treatment regardless of width — catches iPad landscape (≥1024px) and any touch laptop. Never tint the topbar with a token that doesn't match `--c1`; the seam will return.
- Hero decorative layers (`.circuit-bg`, `.logo-constellation`) carry a 56px top-fade `mask-image` so grid lines and constellation dots fade in smoothly below the topbar boundary instead of clipping hard against the sticky bar's bottom edge.
- Keep nav icon slots symmetric; if house vs sun optical size diverges, tune glyph size/stroke, not whitespace hacks.
- Hero nav row uses fixed slot geometry (home slot, more, schedule, mode slot). Keep spacing in CSS grid; do not add manual whitespace characters in markup to fake alignment.
- `More` label + chevron should stay in the Schedule blue family for control-row cohesion.
- Schedule CTA should favor deeper, restrained blue depth (not bright toy-like highlights) with subtle professional relief.
- Keep Schedule CTA one blue-step below the IT/HELP lockup in luminance so the logo remains the strongest blue anchor.
- Keep Schedule CTA values tokenized via `--schedule-cta-*` variables (avoid one-off hardcoded hex in component rules) so hierarchy tweaks stay centralized.
- In-content gold CTA (`.cta-button`, e.g. "Book an On-Site Visit") should use the same geometry language as Schedule (balanced height, medium corner radius, restrained relief) while remaining gold-first for role separation.
- Keep Schedule CTA slightly shorter than icon slots so the control row height is driven by 44px-class tap targets, not by the button block.
- Home glyph should stay as a modern outline icon (Apple-style weight/rounding) at a 44px-class touch target on mobile.
- Hero vertical rhythm should use micro-adjustments only: reduce dead air above the logo and tighten `san diego` under IT+HELP, while preserving clear separation between logo block, tagline pill, and nav row.

## Accessibility
- Minimum contrast ratio for normal text: 4.5:1 (WCAG).
- Re-run Lighthouse when changing the palette or text colors.

## Typography
- Logo: heavy system display (`SF Pro Display` / system stack).
- Body: site default; keep headings bold and legible.

## Motion
- Particles: subtle motion, visible but not distracting.
- Particle colors: mostly Primary Blue with ~30% Gold accents for sparkle.
- Constellation canvas: subtle drifting nodes + connecting lines behind the hero logo only.
- Constellation layout seed: golden-angle (Fibonacci/phyllotaxis-inspired) distribution for an intentional mathematical pattern.
- Light mode: increase constellation/particle contrast so motion remains visible on white backgrounds.
- Mobile light mode: on touch/narrow viewports, increase constellation contrast and link visibility so geometry reads clearly.
- Mobile dark mode: on narrow viewports, boost constellation visibility based on site theme state (`html:not(.switch)`), not OS color-scheme.
- Mobile dark layering: place constellation above particles on narrow dark viewports so line geometry remains visible.
- Mobile dark rendering: use sparse Fibonacci neighbor links (`+1,+2,+3,+5`) instead of full mesh links to avoid dense webbing.
- Respect `prefers-reduced-motion`: disable decorative hero motion effects when reduction is requested.
- Avoid aggressive glitch effects; prioritize clarity and polish.
- Remove unused animation/keyframe blocks from render-blocking CSS before adding new effects.

## Change Tracking
- AI agent entry point is `AGENTS.md`.
- Log visual-system changes in `PROJECT_EVOLUTION_LOG.md`.
- Each entry should include: date, actor (AI/dev), files changed, rationale, and rollback notes.

## Tone of Voice
Applies to all body copy, headings, CTAs, and meta descriptions across the corp site (per `.agent-transfer/plans/ia-blueprint.md` §"Tone & voice").

- **Calm authority.** Match the "intelligence brief" register of the dns-tool. State the situation; do not sell.
- **No marketing-speak.** Forbidden vocabulary includes (but is not limited to): "synergize," "leverage," "solutions provider," "best-in-class," "world-class," "cutting-edge," "unlock," "empower," "seamless," "bulletproof."
- **Specific over generic.** Prefer the concrete, measurable claim: "We rescue email from spam folders by fixing SPF/DKIM/DMARC alignment" beats "We help with email."
- **Discretion language.** "Concierge," "discreet," "by appointment," "high-profile" — the right register for La Jolla / Del Mar clientele. Never name clients or industries beyond high-level sector references.
- **One scientific moment per page.** Each page should carry exactly one technical detail that signals depth without overwhelming a non-technical reader (e.g., "SPF macro expansion checked against RFC 7208 §7.4"). Use sparingly; more than one per page reads as showing off.
- **No retainer language.** Do not describe ongoing engagement structures that resemble managed-services lock-in. The managed-agent option is the only ongoing-fee product, and it is described as opt-in, per-device, and cancellable.

## Design Tokens (SOT)

The single source of truth for design tokens is `static/css/tokens.css` (CSS custom properties for runtime theming) mirrored by `sass/_tokens.scss` (SCSS variables for compile-time computation). Drift between the two files fails CI via `scripts/check-token-parity.sh`. Add/change tokens **only** in those two files, never inline in component CSS.

### Token table

| CSS token | SCSS token | Value | Role |
|---|---|---|---|
| `--bg-primary` | `$bg-primary` | `#0d1117` | Main page background (dark) |
| `--bg-secondary` | `$bg-secondary` | `#161b22` | Elevated surfaces |
| `--bg-tertiary` | `$bg-tertiary` | `#21262d` | Cards, modals |
| `--bg-elevated` | `$bg-elevated` | `#30363d` | Highest elevation |
| `--text-primary` | `$text-primary` | `rgba(230,237,243,.9)` | Primary body text |
| `--text-secondary` | `$text-secondary` | `#9ca3af` | Secondary body text (~6.3:1 on `--bg-primary`) |
| `--code-bg` | _(css-only)_ | `#161b22` | Code block background |
| `--code-border` | _(css-only)_ | `#30363d` | Code block border |
| `--code-color` | _(css-only)_ | `#f0a8c8` | Inline code color |
| `--status-success` | `$status-success` | `#3fb950` | Pass / OK |
| `--status-warning` | `$status-warning` | `#e3b341` | Warn / soft fail |
| `--status-danger` | `$status-danger` | `#f85149` | Hard fail |
| `--status-info` | `$status-info` | `#c8956a` | Informational (warm copper) |
| `--status-neutral` | `$status-neutral` | `#8b949e` | Neutral / muted |
| `--accent-steel` | `$accent-steel` | `#9a8f82` | Premium steel accent |
| `--accent-deep` | `$accent-deep` | `#3d2e1f` | Deep umber accent |
| `--accent-violet` | `$accent-violet` | `#c8956a` | Primary warm accent |
| `--accent-violet-hover` | `$accent-violet-hover` | `#d4a87d` | Hover variant of `--accent-violet` |
| `--accent-cyan` | `$accent-cyan` | `#d4a853` | Intelligence gold |
| `--accent-cobalt` | `$accent-cobalt` | `#b8a089` | Warm taupe |
| `--accent-gold` | `$accent-gold` | `#d4a853` | Premium trust gold |
| `--accent-gold-muted` | `$accent-gold-muted` | `#c9a84c` | Borders / glows |
| `--accent-amber` | `$accent-amber` | `#e8b54a` | Highlight emphasis |
| `--border-default` | `$border-default` | `#30363d` | Default border |
| `--border-muted` | `$border-muted` | `#30363d` | Muted border |
| `--brand-it-help-red` | `$brand-it-help-red` | `#e8195e` | **Red plus sign — DO NOT CHANGE** |
| `--brand-it-help-blue` | `$brand-it-help-blue` | `#4a8fdf` | **IT/HELP edge outline — DO NOT CHANGE** |
| `--brand-it-help-gray` | `$brand-it-help-gray` | `#9aa0a6` | "san diego" subtitle |

The values above are the **dark defaults** (canonical `:root`).

### Light theme (opt-in via the sun toggle)

Dark is the forced default. The sun toggle (`#mode`) adds `.switch` to `<html>`
and persists `theme=light`; light is **never** auto-applied from the OS
`prefers-color-scheme`. `static/css/tokens.css` carries a single centralized
`html.switch { … }` block (immediately after the canonical `:root`) that flips
only the surface / text / border / code tokens to light values, so every
tokenized component themes at once instead of staying dark on a light body.
Values mirror the abridge light palette (`--abridge-c1/c2/c3`, `--abridge-f1`)
so the custom surfaces agree with the abridge-themed body and links.

| Token | Dark (`:root`) | Light (`html.switch`) |
|---|---|---|
| `--bg-primary` | `#0d1117` | `#FAFBFC` |
| `--bg-secondary` | `#161b22` | `#F5F5F7` |
| `--bg-tertiary` | `#21262d` | `#ECECEF` |
| `--bg-elevated` | `#30363d` | `#E5E5E7` |
| `--text-primary` | `rgba(230,237,243,.9)` | `#1D1D1F` |
| `--text-secondary` | `#9ca3af` | `#57606A` (~6.3:1 on `--bg-primary`) |
| `--code-bg` | `#161b22` | `#F5F5F7` |
| `--code-border` | `#30363d` | `#E1E4E8` |
| `--code-color` | `#f0a8c8` | `#A21B5C` |
| `--border-default` | `#30363d` | `#D0D7DE` |
| `--border-muted` | `#30363d` | `#D8DEE4` |

Brand / schedule / accent tokens are mode-agnostic and intentionally NOT flipped.
The `html.switch` block lives **outside** the canonical `:root`, so the
token-parity guard (`first_root_block`) does not scan it and no `sass/_tokens.scss`
mirror is required — but the no-hex rule still exempts `tokens.css`, so the light
hex literals belong only there, never in consumer CSS.

### Rules

- The two SOT files (`static/css/tokens.css`, `sass/_tokens.scss`) are the **only** files allowed to contain hex literals. All other CSS/SCSS must reference tokens via `var(--name)` or `$name`.
- `scripts/check-token-parity.sh` enforces both invariants: (a) `--name` and `$name` values are equal across both files, and (b) `static/css/late-overrides.css`, `sass/_extra.scss`, and `sass/css/abridge.scss` contain zero color hex literals.
- Adding a new token requires updating both files in the same PR plus an entry in `PROJECT_EVOLUTION_LOG.md`.
- Brand non-negotiables (`--brand-it-help-red`, `--brand-it-help-blue`) are never moved or renamed. Their values must remain visually identical to the original brand marks.

## Key Files
- Hero/logo styles: `static/css/late-overrides.css`
- Palette + component tokens: `sass/_extra.scss`
- Theme link colors: `sass/css/abridge.scss`
- Brand color reference: `BRAND_COLORS.md`
- Logo markup: `templates/partials/hero_logo.html`
- Hero logo behavior: `static/js/hero-logo.js`
- Evolution log: `PROJECT_EVOLUTION_LOG.md`
- Email signature (canonical copy-paste source): `static/ithelp-logo-sig-research.html`
- `/signature` reference page + install guide: `content/signature.md`, styled by `static/css/signature.css`

## Email Signature

The email signature is a self-contained artifact, **not** part of the website's
token system. It has its own fixed palette (dark `#111827` ground, `#c8a878`
muted gold, `#c42a2a` brand red) hardcoded as literal hex in
`static/ithelp-logo-sig-research.html` — literal hex is mandatory because email
clients (Gmail, Outlook, Apple Mail) cannot resolve CSS `var()` tokens. The
standalone file is the single source of truth users copy from; it gets the
relaxed signatures CSP automatically via its `ithelp-logo-sig-*` filename. The
`/signature` page renders a scoped preview that mirrors that palette
(`static/css/signature.css`, namespaced under `.sig-preview`). When signature
content changes, edit both the standalone file and the preview block in
`content/signature.md`.
