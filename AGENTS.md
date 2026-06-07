# AGENTS.md

This is the canonical, durable source of truth for all AI agents and human
contributors working on this repository. `replit.md` is intentionally a stub
(see `PROJECT_EVOLUTION_LOG.md` 2026-04-18 entry); do not rely on it for
governance.

## Mandatory Read (All AI Agents)

If you are an AI coding or automation agent (Codex, Replit Agent, Claude Code,
Cursor, Copilot, Anti-Gravity, or similar), read these files before making any
edits, in this order:

1. `AGENTS.md` (this file) — primary governance
2. `STYLE_GUIDE.md` — visual system and tokens
3. `PROJECT_EVOLUTION_LOG.md` — recent change rationale and rollback hooks

Do not make style, UX, infrastructure, or copy edits until those files are read.

## Engineering Philosophy (Hard Quality Bar)

Build clean from the foundations up. Do not defer quality for later cleanup.

- This project is expected to be materially better than typical web builds.
- Changes must preserve or improve quality from all angles: speed, security, accessibility, code clarity, and conversion psychology.
- Prefer simple, durable architecture over short-term hacks.
- If a change introduces debt, stop and redesign before merging.
- Treat best practices as a symbiotic system: true quality is reached when all participating angles support each other (security, performance, accessibility, UX psychology, maintainability, and operations).
- We want to be different by pursuing that fully integrated standard, not isolated metric wins.

## Acceptance Gates (Required)

Every meaningful UI/platform change should meet these targets unless explicitly waived by the owner:

- Lighthouse: target perfect scores (100/100/100/100) on key pages and no regression accepted without written rationale.
- Mozilla Observatory/security posture: target A+ and score >=120.
- Security best practices: maintain strict CSP, safe headers, no trackers/cookies/framework bloat.
- Accessibility: WCAG-compliant contrast and readable typography, including for older users.
- Performance discipline: avoid layout shift, avoid unnecessary JS, keep CSS override layers intentional and non-duplicative.
- Trust/psychology: interface should signal calm authority, competence, and clarity without visual noise.

If a gate cannot be met, document the reason and rollback path in both PR notes and `PROJECT_EVOLUTION_LOG.md`.

## Non-Negotiable Rules

- Preserve Lighthouse and Observatory posture. Do not add scripts, trackers, or CSP-hostile inline changes.
- Preserve accessibility: WCAG contrast and clear text legibility, especially for older users.
- Keep brand intent:
  - Red plus sign stays.
  - IT/HELP edge outline stays, but should be tuned for clarity without harsh glow.
- Avoid duplicate CSS selectors and dead override blocks; Sonar must stay clean.
- Do not introduce new palette colors ad hoc. Use existing tokens first.
- **Never use Replit's "Publish" button.** It deploys to a `*.replit.app` host that creates an SEO collision with the production site (`https://www.it-help.tech/`). All deploys go through the GitHub Actions pipeline below.

## Development Workflow

### In-loop Lighthouse intelligence (`infra/audit/quick-lh.mjs`)

The deploy-gate audit (`infra/audit/run-lighthouse.mjs`) is median-of-N
across the full URL × form-factor grid — too slow and too binary for
in-the-loop use. **`infra/audit/quick-lh.mjs` is the agent's
working microscope:** one URL, one form factor, prints scores and the
ordered list of failing audits in ~20 seconds. Always use it instead of
asking the user to feed Lighthouse reports back.

```bash
npm run lh -- https://www.it-help.tech/field-notes/apple-sends-you-to-ijail/ mobile
npm run lh -- http://localhost:5000/ desktop --save /tmp/lh.json
```

Default form factor is `mobile` (matches PageSpeed default). The
`--save` flag dumps the full Lighthouse JSON for deeper inspection.

**Setup (one-time per environment):** `npm install` — `lighthouse` is
pinned in `package.json` as a devDependency so every agent and CI run
gets the same version. A chromium binary on PATH is also required;
that's already provisioned via `replit.nix` (`pkgs.chromium`) locally
and `apt-get install chromium-browser` in CI — see
`.github/workflows/deploy.yml`. CI's deploy gate still installs the
same version globally for `run-lighthouse.mjs` to keep the existing
pipeline contract unchanged.

**Caveat — single-run jitter:** a one-shot Lighthouse run is noisy,
especially on mobile Performance. Treat the **failing-audits list as
ground truth** and the perf score as directional. The deploy gate's
median-of-N is what gates shipping.

**When to use it:**
- After any change to templates, CSS, JS, image assets, or front matter
  on a page that had a Lighthouse complaint, *before* opening the PR.
- When the user reports a PageSpeed/Lighthouse issue, run it first
  rather than guessing — exit lists every failing audit verbatim.
- The mobile Performance score will be lower than the user's PageSpeed
  reading because the Replit datacenter has higher latency to
  CloudFront. The **failing audits list is what matters** — that is
  what reproduces between this tool and the user's reports.

The deploy gate (`run-lighthouse.mjs`) remains the source of truth for
"are we shipping". `quick-lh.mjs` is the source of truth for "what
should I edit next".

### Branching & PR workflow

- Work on `replit/working` (or a topic branch named `replit/<scope>` for isolated changes).
- Push to GitHub and open a PR against `main`.
- Merge to `main` via **squash and merge** only.
- After every squash-merge, reset the working branch locally so the next PR doesn't carry duplicate commits:
  ```bash
  git fetch origin
  git checkout replit/working
  git reset --hard origin/main
  git push --force origin replit/working
  ```
  Then click "Pull" in Replit to sync.
- Topic branches (`replit/<scope>`) can be deleted after merge.

## Deploy & Build Pipeline

Automatic on merge to `main` via `.github/workflows/deploy.yml`:

1. **Zola build** → outputs to `public/` (or `build/` after the llms generator runs).
2. **PurgeCSS** removes unused styles.
3. **KaTeX assets** removed if unused.
4. **CSP hashes auto-regenerated** via `infra/cloudfront/update_policy.sh` (signature pages use `infra/cloudfront/update_policy_signatures.sh` when `POLICY_ID_SIGNATURES` is set).
5. **`infra/llms/build-llms-full.mjs`** auto-generates `build/llms-full.txt` from `content/*.md` so it never drifts from the live site.
6. **S3 sync** with proper cache headers (`max-age=3600, stale-while-revalidate=86400` for `llms*.txt`; long-cache for fingerprinted assets).
7. **CloudFront invalidation**.
8. **Post-deploy audit gate** — `infra/audit/run-lighthouse.mjs` runs Lighthouse mobile/desktop and Mozilla Observatory against URLs in `infra/audit/audit.config.json`. Median-of-3 sampling per (url, formFactor); fails if any per-category median drops below thresholds (currently 98 for Performance/Accessibility/Best Practices/SEO; A+/120 for Observatory). Single-sample dips that pass the median surface as warnings, not failures.
9. **IndexNow ping** (`indexnow-ping` job, `continue-on-error`, isolated from the audit gate) — diff-driven instant-indexing notification to participating engines (Bing, Yandex, Seznam.cz, Naver, Yep). Pings only URLs whose markdown source changed in the push; filters drafts; deploys with no content changes do not ping. Google does not participate in IndexNow and is unaffected. Verification key file: `static/<key>.txt`.

Local build: `zola build` → `public/`. Local preview: `zola serve --interface 0.0.0.0 --port 5000`.

## Required Update Process For Visual Changes

When changing palette, hero/logo styling, nav/CTA styling, or readability treatment:

1. Update source styles in the canonical file(s), not random one-off duplicates.
2. Update `STYLE_GUIDE.md` if any visual rule or token meaning changes.
3. Add an entry to `PROJECT_EVOLUTION_LOG.md` with:
   - date
   - actor
   - files touched
   - rationale
   - rollback reference (commit/PR)
4. Run `zola build` before opening or updating a PR.

## Project Architecture (At-a-Glance)

**Stack:** Zola static site generator + Abridge theme (customized). SASS for styles, PurgeCSS for optimization. No client-side frameworks. No trackers, no cookies, no third-party JS frameworks.

**Layout:**

- `content/` — Markdown pages, field notes, and embedded JSON-LD schema
- `templates/` — Zola HTML templates and macros (`base.html`, `page.html`, `field-notes.html`); also project-level theme overrides (Zola precedence rule), e.g. `templates/robots.txt` is the canonical source for `/robots.txt`
- `themes/abridge/` — Abridge theme; SEO macros at `themes/abridge/templates/macros/seo.html`
- `sass/` — SASS sources (`_extra.scss` holds component/interaction tokens; `css/abridge.scss` holds theme/link tokens)
- `static/` — assets, `llms.txt`; `static/css/late-overrides.css` is the canonical visual-system file
- `infra/` — `audit/` (Lighthouse + Observatory gate), `llms/` (build-time `llms-full.txt` generator), `cloudfront/` (CSP policy regen)
- `public/` — Zola build output (gitignored)
- `build/` — generator output staged for S3 (gitignored)

**Content pages and schema types:**

| Page | File | Schema Types |
|------|------|--------------|
| Home | `content/_index.md` | FAQPage, LocalBusiness+ProfessionalService, WebSite, WebPage |
| Services | `content/services.md` | WebSite, WebPage, LocalBusiness, ItemList, Offer, FAQPage, Service graph |
| Billing | `content/billing.md` | Offer, FAQPage |
| About | `content/about.md` | AboutPage with Organization |
| DNS Tool | `content/dns-tool.md` | SoftwareApplication |
| Field Notes Index | `content/field-notes/_index.md` | ItemList |
| Field Notes Posts | `content/field-notes/*.md` | Article (via `templates/page.html`) |

**SEO architecture:** Theme SEO macros handle base meta, OG, Twitter. Per-page overrides via content frontmatter (`extra.og_title`, `extra.twitter_description`, etc.). JSON-LD schema lives in content Markdown files, not templates. `templates/field-notes.html` adds Blog schema for the index.

**CSS load order (do not reorder):** `critical.min.css` (inlined) → `abridge.css` (theme, via `config.extra.stylesheets`) → `tokens.css` → `_footer-org.css` → `late-overrides.css`.

**LLM/bot files:** `templates/robots.txt` enumerates AI bot permissions and is rendered to `/robots.txt` (overriding the theme's robots template; **never edit `themes/abridge/templates/robots.txt` and never reintroduce `static/robots.txt`** — both are silently overridden). `static/llms.txt` is the short LLM-friendly summary. `build/llms-full.txt` (auto-generated at deploy time from `content/*.md` by `infra/llms/build-llms-full.mjs`) is the sole source for `/llms-full.txt` — Phase C of the rollout completed when `static/llms-full.txt` was deleted; **never reintroduce a hand-maintained `static/llms-full.txt`** (it would silently shadow the auto-generated copy in dev and drift from the live site).

## Canonical Files

- Visual system: `static/css/late-overrides.css`
- Theme/link tokens: `sass/css/abridge.scss`
- Component/interaction tokens: `sass/_extra.scss`
- Project style rules: `STYLE_GUIDE.md`
- Change history: `PROJECT_EVOLUTION_LOG.md`
- Site config: `config.toml`
- Layout shell + footer NAP: `templates/base.html`
- Audit gate config + thresholds: `infra/audit/audit.config.json`
- llms-full generator + page order: `infra/llms/build-llms-full.mjs`, `infra/llms/llms-full.config.json`

## Why `replit.md` Is a Stub

Replit's checkpoint subsystem auto-rewrites `replit.md` on every "Loop ended"
event (commit author `careybalboa <...@users.noreply.replit.com>`, trailer
`Replit-Commit-Checkpoint-Type: full_checkpoint`). Manually curated sections do
not survive. There is no documented `.replit` flag to disable this. We
therefore deny the auto-summarizer anything meaningful to manage by keeping
`replit.md` short, and we enforce the stub policy with a CI guard
(`.github/workflows/replit-md-guard.yml`). All real governance lives here,
in `STYLE_GUIDE.md`, and in `PROJECT_EVOLUTION_LOG.md`. See
`PROJECT_EVOLUTION_LOG.md` 2026-04-18 doc-hierarchy entry for the full
investigation.
