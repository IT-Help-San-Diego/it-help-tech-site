# Schedule Subdomain Retirement — Internal Plan

**Status:** Phase 1 (code swaps) DONE + verified live 2026-11-02 — awaiting Carey's go on Phases 3–4 (CISA email + DNS teardown)
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

## Phase 1 — Cut live references (code swaps) ✅ SHIPPED 2026-11-02

1. **it-help-tech-site**: every `https://schedule.it-help.tech*` link replaced with the
   canonical `book.squareup.com` URL (nav label "Schedule" stays; CTA text stays).
   `PROJECT_EVOLUTION_LOG.md` untouched (changelog records history).
   Commit `5d6f620` on main → auto-deploy → **verified live**: 0 old-schedule refs on
   www.it-help.tech (home + llms.txt), canonical URL serving.
2. **organiccomputer**: same swap in `index.html`, `AGENTS.md` (operating rule line
   rewritten), `llms-full.txt`. Commit `b7ed7e6` → auto-deploy → **verified live**:
   0 old-schedule refs on organiccomputer.me.
3. **dns-tool-intel**: `_footer.html` consulting link swapped, PR #548
   (`hermes/retire-schedule-footer`, squash-merged, CI green incl. CodeQL/guard/lighthouse)
   → deploy-aws.sh in flight → verify footer on dnstool.it-help.tech after deploy.

## Phase 2 — Square-side cleanup (Carey's dashboard clicks; can be done any time before/after DNS cut)

- Square Online → Settings → remove `schedule.it-help.tech` as custom domain
  (it is verified by the `a585aec0-…` TXT currently in our zone; after DNS deletion
  Square will show it disconnected — tidy it in their UI regardless).
- Check appointments settings: confirmation email templates must reference
  `book.squareup.com`, never the custom domain (private note: any confirmation that
  embeds the custom domain would silently break at DNS cut).

## Phase 3 — CISA WAS scope coordination

- **DRAFT READY (not sent)** — Gmail draft r-8454772465141031661
  ("WAS scope update — remove schedule, finalize our list", drafted 2026-08-29) to
  vulnerability@cisa.dhs.gov: removes `schedule.it-help.tech` (Square/Weebly-hosted,
  not our infrastructure), cleans up the dns-evil-* fixtures, finalizes the webapp
  list to four (server, www, dnstool, screen). Send-on-go after the DNS cut is exercised.
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
