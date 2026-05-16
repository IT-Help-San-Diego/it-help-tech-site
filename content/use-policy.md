+++
title = "Use, License & Reuse Policy"
description = "How content, code, brand assets, DNS Tool references, and AI/LLM access are licensed across IT Help San Diego properties."
path = "use-policy"
aliases = ["/license/", "/reuse/"]

[extra]
skip_image = true
skip_author = true
seo_title = "Use, License & Reuse Policy — IT Help San Diego"
og_description = "What you can and cannot reuse from www.it-help.tech: corporate content, field notes, DNS Tool references, brand assets, and AI/LLM ingestion posture."
twitter_description = "Plain-English split of what is reserved, what is openly licensed only when marked, and how AI crawlers fit in."
+++

This page describes how the work published at `www.it-help.tech` is
licensed. Different parts of the site are covered by different terms.
The short version is that **most things are reserved**, a small set of
research write-ups can be openly reused **only when they say so on the
page**, and access by AI/search crawlers is not the same as a license to
republish.

This is a plain-English operations policy, not legal advice. If you
need a formal license for something specific, write to
`licensing@it-help.tech` and we will answer in writing.

The machine-readable companion lives in the repository as
[`LICENSE`](https://github.com/IT-Help-San-Diego/it-help-tech-site/blob/main/LICENSE)
and [`NOTICE`](https://github.com/IT-Help-San-Diego/it-help-tech-site/blob/main/NOTICE).

## 1. Corporate site content and code — all rights reserved

The business-facing parts of this site — including the home page,
[Services](/services/), [Billing](/billing/), [About](/about/),
[Managed Agent](/managed-agent/),
[Full-Day Engagements](/full-day-engagements/), [Privacy](/privacy/),
[Security Policy](/security-policy/), [Contact](/contact/), and all
pricing, packaging, and methodology copy — are proprietary work
product of IT Help San Diego Inc. The same applies to the templates,
SASS, JavaScript, build scripts, and infrastructure code in our
repositories that we authored.

You may quote short excerpts for commentary, criticism, news reporting,
or scholarship consistent with U.S. fair-use principles, with
attribution and a link back to the source page. Anything more —
mirroring, redistribution, modification, training, derivative products
— requires written permission.

## 2. Field notes / public research — reserved by default, CC BY 4.0
only where the page says so

[Field Notes](/field-notes/) are part of our public research record.
They cover topics like DNS, email security, Mac IT, password ergonomics,
and AI model behaviour, and they cite primary sources so other
practitioners can verify our work.

By default, each field note is **all rights reserved**, just like the
rest of the site. We do not silently relicense research articles as
open content.

A field note is offered under [Creative Commons Attribution
4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
only when the article itself is **explicitly marked**, in one of two
equivalent ways:

- a `reuse_license = "CC-BY-4.0"` entry in the page's `[extra]`
  frontmatter table, or
- a visible "License" / "Reuse" notice in the page body that names
  CC BY 4.0 and links to the license text.

If neither mark is present, the article is reserved. If you are
unsure, ask before republishing.

When CC BY 4.0 does apply, attribution should read substantially as:

> "*&lt;Article title&gt;*" by Carey Balboa / IT Help San Diego Inc.,
> licensed under [CC BY
> 4.0](https://creativecommons.org/licenses/by/4.0/). Source:
> `https://www.it-help.tech/field-notes/<slug>/`

Embedded media inside an openly licensed field note — photographs,
diagrams, screenshots, logos, owl marks — remain governed by sections
4 and 5 below unless the caption explicitly says otherwise. An open
licence on the text does not extend to the brand mark next to it.

## 3. DNS Tool — separate license (BUSL-1.1)

[DNS Tool](https://dnstool.it-help.tech) and its CLI live in their own
repository,
[`dns-tool-intel`](https://github.com/IT-Help-San-Diego/dns-tool-intel/),
and are distributed under the Business Source License 1.1 (BUSL-1.1).
Any DNS Tool references on this site — descriptions, screenshots,
sample reports, methodology summaries — are covered by the DNS Tool
project's own license and citation terms (including its Zenodo deposit
where applicable).

Nothing on `www.it-help.tech` grants additional rights over DNS Tool
software, source, or outputs. When in doubt, defer to the `LICENSE`,
`NOTICE`, and `CITATION.cff` files in the DNS Tool repository.

## 4. Immutable Fact AI / The Real Bot path — reserved commercial work

Pages, prototypes, naming, and design work tied to our **Immutable
Fact AI** / "The Real Bot" product path — including the field note
[*The Real Bot Hasn't Been Built
Yet*](/field-notes/the-real-bot-hasnt-been-built-yet/) and its
companion PDF — are protected commercial work product. They are
**not** offered under CC BY 4.0 or any other open license, even though
they appear under `/field-notes/`. The CC BY 4.0 marker described in
section 2 will not be applied to these pages. Licensing or
collaboration: `licensing@it-help.tech`.

## 5. Brand, logos, owl marks, trademarks — all rights reserved

Reserved unless and until we agree otherwise in writing:

- The names *"IT Help San Diego"* and *"IT Help"* and their wordmarks.
- The Athenian-owl medallion, the IT+HELP wordmark, the red plus mark,
  and any combination thereof.
- The IT+HELP banner cutout (gold IT+HELP + red plus + silver SAN
  DIEGO) and the favicon family generated from the same source.
- The brand colour system at [/brand-colors/](/brand-colors/) when
  used to identify IT Help San Diego Inc.
- Photographs and likenesses of our staff and clients.

Trademark rights are asserted independently of any content licence
elsewhere on the site, and **survive** them. A CC BY 4.0 marker on a
field note does not license the owl, the wordmark, or the company name.

## 6. Third-party theme and dependencies — their own licences

We build on third-party work that keeps its own licence:

- [Zola](https://www.getzola.org/) static-site generator (build-time
  only; not redistributed).
- The [Abridge](https://github.com/Jieiku/abridge) theme under
  `themes/abridge/`. See `themes/abridge/LICENSE` in the repository.
- Node devDependencies (Lighthouse, etc.) pinned in `package.json`,
  each retaining its upstream licence.
- Any vendored fonts or icons included for build — see upstream source
  for terms.

Nothing in our policy overrides those upstream licences.

## 7. AI and LLM crawlers — access is not a reuse licence

Our [`robots.txt`](/robots.txt) and [`llms.txt`](/llms.txt) deliberately
allow major AI and search crawlers — GPTBot, ChatGPT-User,
OAI-SearchBot, ClaudeBot, PerplexityBot, GeminiBot, Google-Extended,
CCBot, YouBot, PhindBot, ExaBot, AndiBot, FirecrawlAgent, and the
traditional Googlebot / Bingbot — to fetch and index publicly
available pages. We want real people who ask an assistant about
"Apple IT in San Diego" or "how DMARC works" to find an accurate,
first-party answer.

That permission is narrow and operational. **Access is not a licence
to reuse.** Specifically, allowing a crawler to read these pages does
not grant:

- a right to redistribute or republish our pages verbatim;
- a right to train commercial foundation models on our content beyond
  what applicable law independently permits;
- a right to build derivative products from our text, code, diagrams,
  research figures, or brand assets;
- a right to remove attribution or alter context;
- a right to use our company name, staff names, or client names to
  imply endorsement of an AI product, dataset, or training corpus.

Sections 1 through 5 above still apply. If you operate an AI system
and want broader reuse rights, contact `licensing@it-help.tech`. We are
happy to talk; we are not happy to be quietly relicensed.

## 8. Reporting problems and asking for permission

- **Licensing and reuse requests:** `licensing@it-help.tech`
- **Security issues:** `security@it-help.tech` — see the
  [Security Policy](/security-policy/).
- **General contact:** [/contact/](/contact/)

This page may be updated. The version at
`https://www.it-help.tech/use-policy/` is canonical; the repository
`LICENSE` and `NOTICE` files are the operational summary.

---

*This page describes how IT Help San Diego Inc. makes its work
available. It is not legal advice and does not create a lawyer-client
relationship.*
