# Schedule Subdomain Retirement — Internal Plan

**Status:** Plan — awaiting Carey's go on Phase 1 execution
**Owner:** Hermes lane (DNS + code swaps); Square-side steps are Carey's dashboard clicks
**Canonical replacement URL:** `https://book.squareup.com/appointments/mwhvoaiqecb5o2/location/LA35149CK62SV/services`
(the booking URL already live on the Google Business Profile since 2026-11-02, verified on the live Maps listing)

## Why

`schedule.it-help.tech` is a Square Online (Weebly) custom domain. Its WAS findings
(JS cookie flags, clickjacking, jQuery-era vendor debt) are Square's to fix and they
never will. Google already routes bookings to `book.squareup.com`; the subdomain now
exists only as an obsolete entry point and a permanent vendor-noise generator on the
CISA WAS monthly.

## Current state (measured 2026-11-02)

- `schedule.it-help.tech` A → `199.34.228.179` (WEEBLYNET1 — Square/Weebly netblock), TTL 300
- Zone records tied to the name (`Z01245183GUCWF9WBTBAL`):
  - `schedule.it-help.tech.` A 199.34.228.179
  - `schedule.it-help.tech.` CAA (amazon.com / letsencrypt.org / iodef hello@it-help.tech)
  - `schedule.it-help.tech.` MX `0 .` (null)
  - `schedule.it-help.tech.` TXT `a585aec0-063b-11f0-95ef-0bf02fbb7a6f` (Square custom-domain verification) + `v=spf1 -all`
  - `_dmarc.schedule.it-help.tech.` TXT `p=reject` (family lockdown record, dies with the name)
- Live references (surfaces that still point at the subdomain):

| Surface | Files | Deploy |
|---|---|---|
| Corporate site (it-help-tech-site) | `config.toml` (nav "Schedule"), `templates/base.html` (topbar CTA), `templates/partials/_footer-org.html` (Book On-Site Visit + footer Schedule), `content/_index.md` (home CTA), `content/contact.md`, `content/services.md`, 2 field notes, `static/llms.txt`, `infra/llms/llms-full.config.json` | auto-deploy on push to main (GH Actions) |
| OrganicComputer (organiccomputer) | `index.html` (footer + inline), `AGENTS.md` (operating rule line), `llms-full.txt` ×2 | auto-deploy on push to main |
| DNS Tool (dns-tool-intel) | `go-server/templates/_footer.html` ("Professional Consulting" link) | build + `deploy/deploy-aws.sh` |
| Google Business Profile | **DONE** — booking action → book.squareup.com (verified live 2026-11-02) | — |
| CISA WAS scope | `schedule.it-help.tech` authorized as webapp #5 | scope-change coordination (below) |

Historical/test-data mentions (`PROJECT_EVOLUTION_LOG.md`, dns-tool `docs/research/*`,
`dns-eval/Inputs/*`, icsae testdata, memory-archive) stay as-is — they are records of
the past, not live surfaces.

## Phase 1 — Cut live references (code swaps)

1. **it-help-tech-site**: replace every `https://schedule.it-help.tech*` link with the
   canonical `book.squareup.com` URL above (nav label "Schedule" stays; CTA text stays).
   Keep `PROJECT_EVOLUTION_LOG.md` untouched (changelog records history).
   Push to main → auto-deploy → verify live on www.it-help.tech.
2. **organiccomputer**: same swap in `index.html`, `AGENTS.md` (rewrite the operating
   rule line "bookings always route through schedule.it-help.tech" → canonical URL),
   `llms-full.txt`. Push to main → auto-deploy → verify.
3. **dns-tool-intel**: swap `_footer.html` consulting link; PR → merge → deploy-aws.sh →
   verify footer on dnstool.it-help.tech.

## Phase 2 — Square-side cleanup (Carey's dashboard clicks; can be done any time before/after DNS cut)

- Square Online → Settings → remove `schedule.it-help.tech` as custom domain
  (it is verified by the `a585aec0-…` TXT currently in our zone; after DNS deletion
  Square will show it disconnected — tidy it in their UI regardless).
- Check appointments settings: confirmation email templates must reference
  `book.squareup.com`, never the custom domain (private note: any confirmation that
  embeds the custom domain would silently break at DNS cut).

## Phase 3 — CISA WAS scope coordination

- Email CISA (vulnerability@cisa.dhs.gov) + reference the WAS App A (Private Sector)
  form: remove `schedule.it-help.tech` from the authorized webapp list (5 → 4).
  Note DNS is being retired effective <date>; the authorized list should match reality.
- Expected effect on the NEXT monthly report: schedule absent; if the in-flight scan
  already ran, one `unreachable`/error row for it is expected and is the honest record.

## Phase 4 — DNS teardown (Route 53, one change batch)

DELETE from `Z01245183GUCWF9WBTBAL`:
- `schedule.it-help.tech.` A, CAA, MX, TXT (incl. the Square verification token)
- `_dmarc.schedule.it-help.tech.` TXT

Verify: `dig @1.1.1.1 schedule.it-help.tech` → NXDOMAIN on 1.1.1.1/8.8.8.8/9.9.9.9 +
authoritative NS. Old bookmarks then fail honestly (NXDOMAIN) instead of landing on
Square's page. TTL 300 = <5 min to full propagation of the deletion.

## Phase 5 — Post-cut verification

- Google booking button still renders and resolves (book.squareup.com — independent
  of our DNS, cannot break).
- All three sites' booking CTAs point to book.squareup.com (curl the live pages).
- Next WAS report: schedule absent; CyHy unaffected (CyHy scope is IPs only).
- One-time follow-up: sweep Search Console/referrer logs one week later for
  meaningful inbound links to schedule.it-help.tech worth a note in this file.

## Decision points (Carey)

1. **Hard removal vs 301 stub**: recommended = hard removal (NXDOMAIN). The 301
   alternative (repoint the name to our own CloudFront redirect to book.squareup.com)
   keeps old bookmarks alive but adds a hostname + cert + WAS surface to maintain —
   not worth it for a booking link nobody has bookmarked.
2. **Execution**: on your go, Phase 1 runs now (three pushes, two auto-deploys, one
   manual dns-tool deploy), then Phases 3-4 can land same-day.
