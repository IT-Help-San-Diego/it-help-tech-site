# it-help.tech: Zola → lightweight HTML — Migration Plan & Strategic Analysis

**Author:** Hermes · **Date:** 2026-06-27 · **Status:** PLAN (no execution yet)
**Repo:** `~/Documents/GitHub/it-help-tech-site` (org IT-Help-San-Diego, deploy on push to `main`)

---

## Goal
Make it-help.tech feel as clean, fast, and low-maintenance as organiccomputer.me / intellectualresistance.com — the no-framework, hand-crafted, zero-error ideal — **while keeping the hero animation gorgeous and never losing the ability to revert.**

## DECISION LOCKED (2026-06-27): Option A — de-theme Zola

Carey approved **Option A** after full A-vs-C analysis. Rationale captured:
- **Raw HTML is the *dirty* option at 21 pages** — it duplicates `<head>`/CSP/nav/footer/hero across 31 files; one nav change = 31 hand-edits = exactly the epistemic drift Carey despises. A generator gives "trace-the-source" correctness-by-construction (one template = single source of layout, one .md = single source per page), the SEL4-style model.
- **The pain was the 1.3 MB `abridge` theme, never Zola itself.** Build only emits post pages + Field Notes list + sitemap.xml. Taxonomies (tags/categories) are NOT producing browsable pages today; NO RSS/Atom feed is generated. So the kept machinery is tiny and fully comprehensible.
- **Workflow payoff:** Carey's bot-driven flow ("idea → make a Field Note") becomes a single clean `.md` file the generator absorbs — index/sitemap/JSON-LD auto-update, zero collateral edits. Gets *easier* as the blog grows.

### Locked sub-decisions
1. **Approach:** A (de-theme Zola, keep your own ~150 lines of templates, drop `themes/abridge`).
2. **Blog:** Field Notes STAYS and grows. Keep the calm scientific *voice* + "Field Notes" *name* (branding), but mark up as `schema.org/Blog`+`BlogPosting` for SEO (independent axis — present as field notes, machines read as well-structured blog).
3. **JS policy:** minimal-JS progressive enhancement is FINE (Carey: "not anti any code we need, anti how everybody does heavy shit"). Keep the hero `hero-logo.js` (canvas constellation) + theme toggle. "Trace-the-source" clean only.
4. **Theme:** dark-DEFAULT always; light is an escape hatch ("unless the user says fuck this, I need light"). The existing 530-byte `theme-toggle.min.js` + `theme-init.js` (FOUC-prevent, SRI-pinned) already implement exactly this — KEEP as-is.

## The honest wrinkle (read this first)
The two sibling sites are **single-page**. That is *the entire reason* they need no generator — there is literally one `index.html`. it-help.tech is **not** single-page:

- **23 content pages** (services, billing, about, dns-tool, privacy, policies, signature, etc.)
- a real **blog ("Field Notes") with 10 posts**, plus **taxonomies** (categories + tags), **per-taxonomy Atom feeds**, and a generated **sitemap**.
- an auto-generated **llms.txt / llms-full.txt** corpus.
- a post-deploy **Lighthouse + Mozilla Observatory gate** (median-of-3) that blocks regressions.

A static-site generator is *the correct tool* for a multi-page blog with taxonomies. **Hand-maintaining 23+ pages and a growing blog as raw HTML is a step backward in maintainability** — every new post would mean hand-editing the blog index, tag pages, sitemap, feeds, and nav by hand, and the "zero-error, all-one-language" cleanliness gets *harder* to hold, not easier, as the page count grows. That's the opposite of what the SEL4-style discipline you love is going for (SEL4's cleanliness comes from the right abstractions, not from removing all tooling).

**So the real question isn't "Zola vs. raw HTML." It's "what is actually causing the pain?"** Three candidate root causes, three very different fixes:

### Option A — Ditch the `abridge` theme, keep Zola (RECOMMENDED)
Most of the "Zola is difficult / incompatible" pain is almost certainly the **`abridge` theme** (1.3 MB of someone else's templates, i18n lookups, Ferris SVGs, a search library, `js_switcher` logic, `load_data` calls). Your templates already override much of it. **Cut the theme entirely**, inline a tiny set of your own Tera templates (you already have `base.html`, `index.html`, `page.html`, `field-notes.html`, 5 partials, 2 macros — that's nearly a complete bespoke theme already), and Zola becomes a ~150-line-of-template, no-dependency, single-language build that behaves exactly like a hand-rolled site but still generates the blog/sitemap/feeds for you.
- **Effort:** medium. **Risk:** low (incremental, page output identical). **Maintainability:** best. **Revert:** trivial per-commit.
- This gets you the *feel* of the siblings (clean, one mental model, no foreign framework) **without** giving up the generator that a blog genuinely needs.

### Option B — Replace Zola with a ~100-line custom build (markdown→HTML)
Write a tiny in-repo builder (Python/Node) that renders your markdown + one layout into static HTML, generates the blog index/sitemap/feeds. You own 100% of it, no Rust/Zola install.
- **Effort:** high (you're rebuilding the 10% of Zola you use). **Risk:** medium (you now maintain a build tool). **Maintainability:** good if disciplined, but it's still a generator — just one you have to debug yourself. Reasonable only if you want zero third-party build deps as a principle.

### Option C — True no-build raw HTML (full sibling parity)
Flatten everything to hand-written `.html`. Only sane if you **kill the blog** (or freeze it) and accept hand-editing nav/sitemap forever.
- **Effort:** high upfront, **high forever after.** **Risk:** maintainability debt grows with every page. Only choose this if the blog is going away and the page count will stay tiny and static.

> **My recommendation: Option A.** It delivers the thing you actually want — the clean, lightweight, one-language, no-foreign-framework feel — at the lowest risk, and it *keeps getting easier* as the blog grows instead of harder. If after seeing it you still want zero generator, B/C remain open. **This plan is written for Option A**, with B/C noted as forks.

---

## Current-state inventory (verified 2026-06-27)
- **Generator:** Zola, `theme = "abridge"` (1.3 MB vendored theme).
- **Templates (yours):** `base.html` (144 ln), `index.html`, `page.html`, `field-notes.html`, `partials/{head,hero_logo,_footer-org,_jsonld,_sprite}.html`, `macros/{csp,macros}.html`, `shortcodes/{img,picture,picture_simple}.html`, `robots.txt`, `sitemap.xml`. ~508 `{% %}` control statements, 49 `get_url`, 4 `regex_replace`.
- **Hero animation (PRESERVE — "the sexy one"):** `partials/hero_logo.html` + `static/js/hero-logo.js` (21.8 KB). Layers: circuit-bg grid, **canvas constellation** (pointer-reactive, honors `prefers-reduced-motion`), CSS 3D-tilt on hover, gold **owl medallion** (`owl-720.webp/png`), tagline pill, 16 floating particles. **NOTE:** site is *not* strictly no-JS today — hero JS + theme-toggle JS exist as progressive enhancement (page works without them).
- **Email/DNS posture (DO NOT TOUCH in this migration):** Google Workspace MX, OnDMARC SPF, MTA-STS enforce, DKIM, BIMI (now fixed), DNSSEC. Website generator change must not alter any DNS/email record.
- **Deploy gate:** `.github/workflows/deploy.yml` → Zola build → PurgeCSS → KaTeX prune → CSP-hash regen (`infra/cloudfront/update_policy.sh`) → llms gen → S3 sync (`--delete`) → CloudFront invalidate → Lighthouse(98+)/Observatory(A+,120) median-of-3 gate → IndexNow.

## Hard constraints (non-negotiable)
1. **Always revertable.** Every step on a topic branch, squash-merge per repo AGENTS.md, never force-push main. Pre-migration tag `pre-zola-migration` on main.
2. **Lighthouse 100/100/100/100 target, Observatory A+ ≥120** — the existing gate must still pass; do not weaken CSP.
3. **CSP discipline preserved.** The site uses a **nonce-based** CSP today (hero JS + theme JS run under nonce). If we keep JS, keep nonce flow; if any page goes pure-static, pin style by SHA-256 hash like the siblings. Never `unsafe-inline`.
4. **Hero animation visually identical** after migration (DOM-metric + screenshot verified, not vibes).
5. **No DNS/email/CloudFront-distribution changes** as part of the site migration. (Headers-policy JSON edits only if CSP model changes, and only via PR + verify.)
6. **SEO continuity:** every existing URL must still resolve at the same path (services/, billing/, about/, dns-tool/, field-notes/ + 10 posts, privacy/, etc.). 301 nothing by accident. Sitemap + feeds + llms.txt must still emit.

---

## Plan — Option A (de-theme Zola), bite-sized & TDD-style

> Verification tool available in-repo: `npm run lh -- <url> <form-factor>` (quick Lighthouse) + the deploy gate's median-of-3. Use a local `zola serve` on :5000 for every visual check.

### Phase 0 — Safety net
- **0.1** Tag current main: `git tag pre-zola-migration && git push origin pre-zola-migration`. (Instant full revert point.)
- **0.2** Branch `migrate/de-theme-zola`. Confirm clean tree, HEAD==origin/main.
- **0.3** Snapshot the live rendered output for diffing: `zola build` → copy `public/` to `/tmp/baseline-public/`. This is the byte-level "after must ≈ before" oracle.

### Phase 1 — Vendor the theme's *used* bits, drop the 1.3 MB dependency
- **1.1** Enumerate exactly which `abridge` files are referenced (templates `{% extends/include/import %}`, `config.extra` keys, `themes/abridge/i18n`, `themes/abridge/sass`). Output a keep-list.
- **1.2** Copy ONLY the referenced theme templates/sass into the repo's own `templates/` and `sass/`, rewriting `{% extends "abridge/..." %}` → local paths. Replace `load_data("themes/abridge/i18n/…")` with a single inlined `i18n/en.toml` (you're English-only; delete the lang branching).
- **1.3** Remove `theme = "abridge"` from `config.toml`. Delete `themes/`. 
- **1.4** `zola build` → diff `public/` against `/tmp/baseline-public/`. **Expected: near-zero diff** (only whitespace/comment noise). Resolve any real diff before moving on.
- **1.5** Commit. PR. Verify live-equivalent locally. *(Revert = drop this commit.)*

### Phase 2 — Simplify templates to one clean mental model
- **2.1** Collapse `base.html` i18n/search/uglyurl branches (English-only, no offline search lib) — delete dead `{% if %}` arms. Target: base.html from 144 ln → ~90 ln, zero feature flags.
- **2.2** Fold `macros/macros.html` + `macros/seo.html` usage into explicit partials where it improves readability; keep `csp.html` (nonce) as-is.
- **2.3** Re-evaluate the 3 shortcodes (`img`, `picture`, `picture_simple`) — only 8 invocations total. Consider one unified `picture` shortcode. 
- **2.4** Build-diff against baseline again (still ≈ identical). Run `npm run lh` on homepage + one post. Commit. PR.

### Phase 3 — Asset & CSS hygiene (the "zero-error, clean" pass)
- **3.1** PurgeCSS already runs in CI; run it locally and **commit the purged, deduped CSS as source** so the repo itself is Sonar-clean (no dead selectors) rather than relying on a build step to hide cruft.
- **3.2** Audit `static/js/` — keep `hero-logo.js` (the animation) + `theme-init`/`theme-toggle`; delete any unreferenced JS (`brand-colors.js` if only used on one dev page).
- **3.3** Confirm no external subresources except where intentional. Document the JS-under-nonce decision in AGENTS.md (the site is "minimal-JS progressive-enhancement," NOT "zero-JS like siblings" — be honest in docs).

### Phase 4 — Hero animation parity (must stay gorgeous)
- **4.1** Before/after screenshot of the hero at desktop + mobile widths via local `zola serve` + browser tool. DOM-metric check (canvas present, owl `<img>` dimensions, particle count). 
- **4.2** Confirm `prefers-reduced-motion` still kills the constellation; confirm hover-tilt still works. No regression in the WAI accessibility annotations already in `hero_logo.html`.

### Phase 5 — Full verification & cutover
- **5.1** Local: `zola build` + run the repo's own `infra/audit/run-lighthouse.mjs` against `http://localhost:5000` for the URL grid. Must hit thresholds.
- **5.2** Merge PR(s) to main (squash). CI runs the real deploy gate. If gate fails → it does NOT deploy; fix forward or `git revert`.
- **5.3** Post-deploy live verification (skill `hardened-static-site-aws-family`): apex+www 200, HSTS, CSP intact, hero renders, sitemap/feeds/llms.txt present, all 23+ URLs resolve, BIMI logo serves `image/svg+xml`.
- **5.4** Update `PROJECT_EVOLUTION_LOG.md` + `AGENTS.md` (note theme removed, single-language, minimal-JS posture). Update `~/IT Help San Diego Inc./ASSET-INVENTORY.md`.

## Files likely to change
- `config.toml` (drop theme, menu cleanup), `templates/*` (de-theme, simplify), `sass/*` (purged source), `i18n/en.toml` (new, inlined), delete `themes/`, possibly `static/js/*` (prune), `.github/workflows/deploy.yml` (only if theme-path assumptions change), `AGENTS.md` + `PROJECT_EVOLUTION_LOG.md`.
- **NOT changed:** any DNS record, email posture, CloudFront distribution, ACM cert, `infra/cloudfront/security-headers.json` (unless CSP model deliberately changes).

## Risks & mitigations
- **R1 — build output drifts from baseline.** Mitigate: byte-diff `public/` vs `/tmp/baseline-public/` after every phase; treat any non-cosmetic diff as a stop.
- **R2 — CSP/nonce breakage blanks a page** (the family's classic failure). Mitigate: keep nonce flow intact; live CSP check post-deploy; the deploy gate + Observatory catch it.
- **R3 — hero animation regresses.** Mitigate: Phase 4 screenshot + DOM-metric gate.
- **R4 — SEO/URL drift.** Mitigate: enumerate all output paths pre/post; diff the sitemap.
- **R5 — Lighthouse gate fails on merge.** Mitigate: run the repo's own audit locally before merging; gate fails closed (no deploy) so prod is never broken.

## Open questions for Carey
1. **Which option — A (de-theme Zola, recommended), B (tiny custom builder), or C (raw HTML, blog frozen)?**
2. Is **Field Notes (the blog) staying and growing?** (If yes → A is clearly right. If you're freezing/killing it → C becomes viable.)
3. OK to **keep the hero JS + theme-toggle JS as progressive enhancement** (the honest current state), or do you want a hard **zero-JS** rule like the siblings (which means rebuilding the constellation as a CSS-only animation — losing the pointer-reactive star-field)?
4. Keep the **dark/light theme toggle**, or go single dark theme like the siblings?
