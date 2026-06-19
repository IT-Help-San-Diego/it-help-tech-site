---
title: "Bug-Bounty Programs Are a Corporate-Controlled Casino"
date: 2026-06-19
updated: 2026-06-19
author: Carey Balboa
categories: [Cybersecurity, Web Security, Disclosure]
tags: [bug bounty, vulnerability disclosure, Square Online, HSTS, security headers, HTTPS, CISA, Cyber Hygiene, responsible disclosure, ethical hacking]
description: "A federal cyber agency flags Square Online's missing HTTPS security headers every week. The platform won't let merchants fix it, and the bug-bounty funnel exists to manage reporters, not to fix the gap."
aliases:
  - /blog/bug-bounty-programs-are-a-corporate-controlled-casino/
extra:
  seo_title: "Bug-Bounty Programs Are a Corporate-Controlled Casino: Square Online's Year-Long Header Gap"
  og_title: "Bug-Bounty Programs Are a Corporate-Controlled Casino"
  og_description: "Every week a federal Cyber Hygiene scan flags Square Online's missing HTTPS security headers. Merchants can't patch it, and the bounty funnel is built to manage reporters—not close the gap."
  twitter_title: "Bug-Bounty Programs Are a Corporate-Controlled Casino"
  twitter_description: "A weekly federal scan flags Square Online's missing security headers. The platform blocks self-remediation and routes you to a bounty page. That's not security—it's risk management."
  canonical_url: "https://www.it-help.tech/field-notes/bug-bounty-programs-are-a-corporate-controlled-casino/"
---

## Executive Summary

Every week, a free scan from the United States' federal cyber-defense agency tells me the same thing: a **Square Online** storefront is missing basic HTTPS security headers, and the public landing pages that lead into the PCI-compliant checkout do not enforce a clean, modern TLS posture. Every week, nothing changes—because the merchant who owns the store **is not allowed to fix it**, and the platform that *can* fix it has chosen not to.

When you try to report the problem through normal channels, you are eventually pointed at a **bug-bounty program**. This Field Note argues that the modern bug-bounty model is not the security partnership it markets itself as. It is closer to a **corporate-controlled casino**: a system that centralizes vulnerability information under vendor-defined terms, shifts the unpaid labor of triage and proof onto outsiders, and pays out only when the house decides your finding "counts." The Square Online header gap is a clean illustration of all three failures at once.

This is an opinion piece grounded in verifiable facts: the scanners are real, the headers are documented standards, and the disclosure economics are public. The conclusion—that a security model requiring unpaid, over-controlled external labor to keep users safe is structurally broken—is mine.

---

## Table of Contents

1. [The Weekly Alert Nobody Will Fix](#the-weekly-alert-nobody-will-fix)
2. [What the Scan Actually Finds](#what-the-scan-actually-finds)
3. [Why Merchants Can't Fix It Themselves](#why-merchants-can-t-fix-it-themselves)
4. [A Year of Being Told to Fix It Myself](#a-year-of-being-told-to-fix-it-myself)
5. [The Bug-Bounty Funnel: Where Reports Go to Be Managed](#the-bug-bounty-funnel-where-reports-go-to-be-managed)
6. [The Economics: Speculative, Unpaid Consulting](#the-economics-speculative-unpaid-consulting)
7. [How Bounty Programs Help Vendors Dodge Responsibility](#how-bounty-programs-help-vendors-dodge-responsibility)
8. [The Inversion of "Ethical Hacking"](#the-inversion-of-ethical-hacking)
9. [What Actually Needs to Change](#what-actually-needs-to-change)
10. [Actionable Takeaways](#actionable-takeaways)

---

## The Weekly Alert Nobody Will Fix

The U.S. Cybersecurity and Infrastructure Security Agency (CISA) runs a free **Cyber Hygiene** program that continuously scans enrolled organizations' internet-facing assets and emails them the results [^1]. It is about as close to a neutral, authoritative second opinion as a small business can get for free. And week after week, that scan flags the same class of problem on a **Square Online** subdomain: the public-facing landing pages that sit *in front of* the payment flow do not force HTTPS and are missing modern HTTP security headers.

The same findings show up from independent tooling—open-source scanners like ProjectDiscovery's nuclei [^8] and commercial engines like Qualys [^9]—because they are not exotic. They are the first things any competent web scanner checks.

Here is the part that turns a routine finding into a Field Note: the reports started in **mid-2025**, and as I write this in **June 2026**, the gap is still open. More than a year of weekly notices, acknowledged and unresolved. The exposure is real but unglamorous—exactly the kind of issue a bounty program will happily mark "informational" while it stays live on thousands of merchant storefronts.

---

## What the Scan Actually Finds

None of these findings are zero-days. They are documented, decades-old web-security baselines:

- **No forced HTTPS redirect.** A landing page reachable over plain `http://` lets a network attacker tamper with the page—including the links and redirects that send a shopper toward checkout—before any encryption is in play.
- **Missing HTTP Strict Transport Security (HSTS).** HSTS tells browsers to refuse plaintext connections to a host for a defined period, defeating downgrade and SSL-stripping attacks [^2]. It is considered baseline hardening, with a public preload list browsers ship by default [^6][^7].
- **No Content-Security-Policy (CSP).** CSP is the single most effective in-browser control against cross-site scripting and content injection [^3].
- **Missing `X-Frame-Options` / framing protection.** Without it, the page can be embedded in a hostile frame for clickjacking [^4].

The consensus baseline for all of this is not controversial—OWASP publishes a Secure Headers project precisely so that "which headers, and why" is a settled question, not a debate [^5]. A shopper on a missing-headers landing page is exposed to man-in-the-middle manipulation *before* they ever reach the hardened, PCI-compliant payment form. "The checkout itself is compliant" is not an answer to "the page that funnels people into checkout is not."

---

## Why Merchants Can't Fix It Themselves

On a normal site, a competent admin closes these findings in an afternoon: force the redirect, add the headers at the edge, submit to the HSTS preload list, done. On a closed storefront platform, the merchant has no such access.

When merchants try to self-remediate by putting their own CDN or WAF in front of the store—Cloudflare, AWS CloudFront—the platform can flag the custom domain as **disconnected** and, in some cases, knock the storefront offline. There is no supported mechanism to inject your own headers or enforce your own TLS policy. The control plane that *could* fix the finding belongs entirely to the vendor; the liability for the open finding lands on the merchant. Reports raised in the seller community get acknowledged and forwarded, then stall without a remediation timeline [^10].

That asymmetry—**you own the risk, they own the fix**—is the structural setup that makes the bug-bounty funnel so convenient for the vendor and so hollow for everyone else.

---

## A Year of Being Told to Fix It Myself

I want this part on the record, because it is the part that turns a technical finding into a pattern of conduct. For roughly a year I have tried, repeatedly, to simply *give* the vendor the information: the scan reports, the exact failing headers, the affected URLs, the dates. Receiving that costs them nothing. The response has not been "thank you, we'll route this to engineering." It has been to push me toward a bug-bounty program—as if a paying customer reporting a defect in the product they pay for were an outside researcher auditioning for a payout.

When support did engage, the reply followed one unchanging script: **the problem is on my end, and I should fix it.** Over a year of correspondence, the message was consistently that the customer—who has no access to the platform's response layer—was the one who needed to act.

The most revealing version of that advice was being told to **update my DNS records** to resolve the missing security headers. That is not merely unhelpful; it is technically impossible, and it is worth explaining exactly why:

- **HSTS, Content-Security-Policy, and `X-Frame-Options` are HTTP *response headers*.** The web server emits them with every page it serves [^2][^3][^4]. They live in the HTTP response, not in the domain name system.
- **A forced HTTPS redirect is also server-side response behavior**—the server answers an `http://` request with a redirect to `https://`. Again: emitted by whatever serves the page.
- **DNS does a different job entirely.** DNS records (`A`/`AAAA`, `CNAME`, `MX`, `TXT`, and the like) map names to addresses and publish service metadata. There is no DNS record type that can attach a security header to an HTTP response or force a redirect on a platform-hosted page. Telling a customer to "fix it in DNS" is like telling someone to repair a leaking roof by repainting the mailbox—the lever does not connect to the thing that is broken.

And here is the part that makes the advice not just wrong but circular: on a closed storefront platform, the customer **cannot set those response headers at all**—only the vendor can. So the customer is being instructed to perform, in the wrong layer, a fix that the platform has already made impossible for them to perform in the *right* one.

The throughline of the year is simple to state and hard to defend: the only party who *can* fix this has spent twelve months insisting that the party who *can't* should.

---

## The Bug-Bounty Funnel: Where Reports Go to Be Managed

Follow the escalation path and it eventually terminates at a **bug-bounty / responsible-disclosure program** [^11]. On paper this looks like the responsible thing: a clear place to send findings, a coordinated-disclosure process, maybe a reward. In practice, for a finding like this, the funnel does three things for the vendor and very little for users:

1. **It centralizes and controls** serious vulnerability information under terms the vendor writes—including how, when, and whether anything is ever disclosed publicly.
2. **It shifts labor** for triage, reproduction, and impact analysis onto outsiders who are paid only if the vendor agrees the finding has value.
3. **It generates PR.** "We run a bug-bounty program" reads as a security investment, even while the same documented gap stays open and the weekly scans keep firing.

A merchant who reports through support gets redirected into the funnel. A researcher who uses the funnel is bound by disclosure rules engineered around the vendor's legal risk, not public safety. Everyone who actually cares about the exposure gets routed into a channel optimized for managing *reporters*, not for *shipping fixes*.

There is a quieter insult underneath all of this. I am not an anonymous researcher fishing for a payout—I am a paying customer who tried, again and again, to hand over a free defect report and was waved toward the rewards program instead. When a company would rather route a customer to a bounty page than simply *accept information it is being given for nothing*, the funnel has stopped being a security process. It has become a mechanism for not having to listen.

---

## The Economics: Speculative, Unpaid Consulting

Strip away the language and a bounty submission is **speculative, unpaid security consulting** performed under rules the client wrote unilaterally [^14]. The researcher invests real hours to verify a finding, write a reproducible proof of concept, and propose remediation. In return they face:

- **Arbitrary scope rulings**—"out of scope," "informational," "won't fix," "duplicate"—decided by the same party who benefits from minimizing severity.
- **Severity deflation.** A finding that maps to a meaningful CVSS score [^13] gets re-scored down to a token tier, or to nothing.
- **Payouts measured in the low hundreds of dollars** for issues whose exploitation could cost the vendor far more in incident response, legal exposure, and brand damage.

Even the platforms built on this model—Bugcrowd [^15], Synack [^16], and the rest—run on the same core arrangement: the house sets the table, the house judges the hand, and the house decides when you get paid. When one reported bug can prevent losses orders of magnitude larger than its payout, and the discoverer walks away with a three-figure check, that is not a partnership. It is value extraction with a leaderboard bolted on.

---

## How Bounty Programs Help Vendors Dodge Responsibility

The deeper problem isn't any single stingy payout—it's what the model lets a vendor *avoid*. A well-run bounty page lets a company:

- **Defer baseline engineering.** Why prioritize shipping documented security headers when the issue can sit indefinitely as a low-tier, "accepted-risk" bounty item?
- **Convert public-safety questions into private contractual ones.** Disclosure rules turn "users are exposed" into "a reporter is under NDA-like terms," moving the conversation out of public view.
- **Launder accountability into marketing.** The program itself becomes evidence of diligence, regardless of whether anything actually gets fixed.

The Square Online header gap demonstrates the whole loop: a CISA-validated, year-old finding, a platform that forbids self-remediation, a funnel that points reporters at a bounty page, and an exposure that remains live the entire time.

---

## The Inversion of "Ethical Hacking"

Bounty culture has quietly annexed the word *ethical*. A researcher who follows platform rules and accepts small, inconsistent payouts is the "ethical hacker." Someone who declines that economic arrangement, or who publicly documents a vendor's year-long inaction, risks being branded unprofessional or reckless.

But ethics was never about obeying the platform. It is about aligning your actions with the people actually at risk:

- **Merchants**, whose stores carry an open finding they are structurally forbidden from closing.
- **Shoppers**, exposed on the pages that funnel them toward payment.
- **Researchers**, who take real legal and financial risk to surface problems and are then underpaid, gagged, or waved off.

A system that quietly silences all three—merchants through opaque support funnels, shoppers through invisibility, researchers through legal and financial asymmetry—is not "ethical hacking." It is corporate self-protection wearing a security badge.

---

## What Actually Needs to Change

The fix is not a better-run casino. It is rejecting the premises that make the casino necessary:

- **Baseline hardening is the vendor's job, not a bounty line item.** Forced HTTPS, HSTS, CSP, and framing protection are table stakes that a platform must ship for every merchant by default—no report required [^5].
- **Coordinated disclosure should serve the public, not just the vendor's legal team.** Published guidance for good-faith disclosure already exists; the missing piece is vendor commitment to timelines, transparency, and a real deadline for fixing documented findings—not indefinite "accepted risk" [^12].
- **If you require external labor to stay safe, pay for it like labor.** Speculative, judged-by-the-beneficiary payouts are not a substitute for either fixing your own baselines or contracting real security work.

Any model that *requires* unpaid, over-controlled outside effort to keep users safe is structurally unethical. Any disclosure regime that lets the vendor decide unilaterally what the public learns, and when, is structurally unsafe. Square's open header gap checks both boxes.

---

## Actionable Takeaways

If you run a storefront on a closed platform—or you're tired of doing free consulting for companies that won't fix their baselines—here is the practical playbook:

1. **Run your own scans.** Point a free scanner (ProjectDiscovery's nuclei [^8], Qualys [^9]) or, if you qualify, CISA Cyber Hygiene [^1] at your own subdomain. Document missing HTTPS redirects, absent HSTS, and missing CSP / framing headers.
2. **Archive the evidence.** Save each report with its date, scanner version, and exact findings (for example, "no HSTS header on `https://yourstore.square.site`"). A dated trail is what turns "I complained" into "this has been open since *X*."
3. **Escalate through official channels—and cite the authority.** File through the platform's security or trust process and reference the CISA finding as a neutral source. Ask for a remediation *timeline*, not just an acknowledgment.
4. **Publicize the pattern, responsibly.** A redacted scan plus a factual account of the vendor's response timeline is fair, useful, and defensible. Stick to what you can document.
5. **Set a personal disclosure policy and hold it.** Decide in advance what you *will* do (a concise, good-faith heads-up) and what you *won't* do (full, bounty-grade reporting for vendors that treat you as a free lead source). Deciding once means you don't re-litigate the emotional math every time.

If your business needs its email, DNS, and web-facing posture actually hardened—instead of explained away—[our team does that work end to end](/services/).

**In short:** A weekly notice from a federal cyber agency should be a gift. When the platform that can fix it won't, and the only door left open is a bounty page that pays out at the house's discretion, the program isn't protecting users. It's protecting the vendor. Name it, document it, and stop funding the casino with free chips.

---

## References

[^1]: Cybersecurity and Infrastructure Security Agency (CISA). (n.d.). *Cyber Hygiene Services*. Retrieved June 19, 2026, from <https://www.cisa.gov/cyber-hygiene-services>

[^2]: MDN Web Docs. (n.d.). *Strict-Transport-Security*. Retrieved June 19, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>

[^3]: MDN Web Docs. (n.d.). *Content-Security-Policy*. Retrieved June 19, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>

[^4]: MDN Web Docs. (n.d.). *X-Frame-Options*. Retrieved June 19, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>

[^5]: OWASP. (n.d.). *OWASP Secure Headers Project*. Retrieved June 19, 2026, from <https://owasp.org/www-project-secure-headers/>

[^6]: OWASP. (n.d.). *HTTP Strict Transport Security Cheat Sheet*. Retrieved June 19, 2026, from <https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html>

[^7]: HSTS Preload List. (n.d.). *HSTS Preload List Submission*. Retrieved June 19, 2026, from <https://hstspreload.org/>

[^8]: ProjectDiscovery. (n.d.). *ProjectDiscovery: Open-source security tools (nuclei)*. Retrieved June 19, 2026, from <https://projectdiscovery.io/>

[^9]: Qualys. (n.d.). *Qualys Web Application Scanning*. Retrieved June 19, 2026, from <https://www.qualys.com/>

[^10]: Square Seller Community. (n.d.). *Square Seller Community*. Retrieved June 19, 2026, from <https://www.sellercommunity.com/>

[^11]: Block, Inc. (n.d.). *Block (Square / Cash App) bug bounty program on HackerOne*. Retrieved June 19, 2026, from <https://hackerone.com/block>

[^12]: OWASP. (n.d.). *Vulnerability Disclosure Cheat Sheet*. Retrieved June 19, 2026, from <https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html>

[^13]: FIRST. (n.d.). *Common Vulnerability Scoring System (CVSS)*. Retrieved June 19, 2026, from <https://www.first.org/cvss/>

[^14]: Wikipedia. (n.d.). *Bug bounty program*. Retrieved June 19, 2026, from <https://en.wikipedia.org/wiki/Bug_bounty_program>

[^15]: Bugcrowd. (n.d.). *Bugcrowd crowdsourced security platform*. Retrieved June 19, 2026, from <https://www.bugcrowd.com/>

[^16]: Synack. (n.d.). *Synack penetration testing platform*. Retrieved June 19, 2026, from <https://www.synack.com/>

---

*This Field Note is an opinion piece grounded in publicly verifiable facts and reflects the state of the referenced tools, standards, and programs as of June 2026. Security headers, disclosure norms, and platform policies continue to evolve.*
