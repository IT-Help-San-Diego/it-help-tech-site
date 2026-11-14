---
title: "Missing Security Headers on a Hosted Storefront: Who Can Set Them, and What Bug Bounties Cover"
date: 2026-11-13
updated: 2026-11-13
draft: true
author: Carey Balboa
categories: [Cybersecurity, Web Security]
tags: [security headers, HSTS, Content-Security-Policy, X-Frame-Options, bug bounty, Square Online, Bugcrowd, hosted e-commerce]
description: "Checked on 13 November 2026: the security headers 38 Square Online storefronts returned, whether six Square pages described a merchant setting for them, and how bug-bounty rules rate a report that one is missing."
extra:
  keywords: ["security headers", "HSTS", "Content-Security-Policy", "X-Frame-Options", "bug bounty", "Square Online", "Bugcrowd VRT", "IT Help San Diego"]
  seo_title: "Missing Security Headers on a Hosted Storefront, Measured"
  og_title: "Missing Security Headers on a Hosted Storefront: Who Can Set Them, and What Bug Bounties Cover"
  og_description: "Checked on 13 November 2026: the security headers 38 Square Online storefronts returned, whether six Square pages described a merchant setting for them, and how bug-bounty rules rate a report that one is missing."
  twitter_title: "Missing Security Headers on a Hosted Storefront, Measured"
  twitter_description: "The security headers 38 Square Online storefronts returned on 13 November 2026, whether six Square pages described a merchant setting, and how bug-bounty rules rate a report that one is missing."
  canonical_url: "https://www.it-help.tech/field-notes/security-headers-hosted-storefronts-and-bug-bounties/"
---

Disclosure: IT Help San Diego is a Square customer. It uses Square's booking service for its own appointments, and until 2 November 2026 one of its own domains pointed to a Square Online site.

## Summary

A security header is a line in a web server's response that switches on a protection in the browser. A bug bounty program offers rewards to researchers who report vulnerabilities.

This note tests a three-part hypothesis about a hosted e-commerce platform (one that runs every store on its own servers): **(1) the platform sets the baseline security headers its stores send; (2) the merchant cannot add the ones that are missing; (3) bug-bounty rules do not reward a report that one is missing.**

I tested it on one platform, Square Online, and against the rules of Bugcrowd, which hosted Square's public bounty program. Everything was measured or read on 13 November 2026, and headers can change with a single deployment.

- **Baseline posture.** The response headers at the root (home page) address of 38 Square Online storefronts were checked for seven baseline protections, explained under [What counts as the baseline](#what-counts-as-the-baseline). All 38 carried two: a redirect to HTTPS and an HSTS header. None carried the other five: a Content Security Policy, framing protection, `X-Content-Type-Options`, `Referrer-Policy` and `Permissions-Policy`. Page content was not read.
- **Who can set them.** Every check came out the same on all 38 stores, which points to the platform as the party that sets these headers. The six Square pages I read described no merchant setting for them. Two routes around that exist on paper: a partial Content Security Policy or a referrer policy delivered inside the page, and, for a store on the merchant's own domain, a layer in front of the store that the merchant runs, such as a firewall. I tested neither.
- **What a bounty covers.** In Bugcrowd's rating list (its taxonomy) of 8 July 2026, a missing HSTS, Content Security Policy, `X-Frame-Options` or `X-Content-Type-Options` header is P5 by default. P5, labeled Informational, is the fifth of five levels, and Bugcrowd describes it as not rewardable. The list has no entry for `Referrer-Policy` or `Permissions-Policy`. The last public terms of Square's program, dated 1 October 2026 (UTC), offered rewards for P1 to P3 only.
- **Bounty spend.** Block, whose products include Square, wrote on 14 October 2026 that researchers have earned more than $1 million through its programs. I found no public total for Square alone. Under the last public terms of Square's program, a report of a missing header that the taxonomy rates P5 carried no reward by default. So, on those terms, Block's figure is not a measure of the baseline.

**Result.** Part 1 held for the 38 stores measured. Part 2 did not hold as first worded. It held only in the narrower form stated under "Who can set them" above. Part 3 held as a default for the four baseline headers that Bugcrowd's taxonomy rates P5, with exceptions. On this evidence, the practical route to closing these gaps runs through the platform. This note does not show that it is the only route (see [What this does not show](#what-this-does-not-show)).

A missing header is not an exploit. I did not test any store for a vulnerability, and nothing here shows one.

If your store runs on a hosted platform, check what your store sends, ask the platform which security headers it sets and whether you can set any yourself, and report a missing header to its support channel or security contact. The steps are under [If your store runs on a hosted platform](#if-your-store-runs-on-a-hosted-platform).

## What counts as the baseline

Each of these protections is described in guidance from MDN (Mozilla's web documentation) or OWASP (a nonprofit security foundation), cited below. There are seven, in four groups below: two for HTTPS, a Content Security Policy, framing protection, and three further headers. Choosing these seven as the baseline is my call.

- **HTTPS, enforced.** A site that accepts plain HTTP requests should redirect them to HTTPS, and MDN recommends a permanent redirect such as a `301`. The site should also send `Strict-Transport-Security` (HSTS), which tells the browser to use only HTTPS for that host for a stated period [^1] [^2]. Major browsers also ship a built-in list of HTTPS-only sites, the HSTS preload list. Listing requires, among other things, an HSTS period (`max-age`) of at least one year, with `includeSubDomains` and `preload`. The list's own site recommends HSTS but not preloading, so preloading is not part of the baseline here [^3].
- **Content Security Policy.** `Content-Security-Policy` lets a site declare which sources of script, style and other content a page may load. That helps guard against cross-site scripting, an attack that injects script into a page [^4].
- **Framing protection.** `X-Frame-Options`, or the `frame-ancestors` directive of a Content Security Policy, tells the browser whether another site may display the page inside a frame. Sites can use either one to avoid clickjacking, an attack that relies on showing the page inside another site [^5].
- **The rest of the set.** OWASP's Secure Headers Project describes response headers a site can use to increase its security [^6]. Its Response Headers page lists the three headers above with several others, including `X-Content-Type-Options` (which stops the browser from treating a file as a different type than the server declared), `Referrer-Policy` (which governs how much a request reveals about the page it came from) and `Permissions-Policy` (which limits the sites that can be given access to browser features). It marks `Permissions-Policy` as a working draft [^7].

A header scanner such as MDN's HTTP Observatory checks the headers a site sends [^8].

A missing header is not a vulnerability in the usual sense. It does not show that anything is broken. It means the response headers did not switch on a layer of protection that the browser offers.

## Measurement 1: what the storefronts send

**Method.** On 13 November 2026, between 13:17:51 and 13:19:03 UTC, two requests were sent to each of 38 Square Online storefronts on `*.square.site`: one over plain HTTP and one over HTTPS. Both went to the store's root address (its home page address), and redirects were not followed. The response headers were recorded. Page content was not read, so a policy delivered inside the page would not have been seen. A second pass, run separately, sent the same two requests to 12 of the 38 between 13:23:22 and 13:23:54 UTC. Each of those 12 stores therefore received four requests in total. Every row of the table came out the same on those 12. Neither pass sent anything else to any store.

Each count is the number of stores, of 38, whose response carried the header. Except where the table says otherwise, the header was read from the HTTPS response.

| Protection | Header checked | Of 38 |
|---|---|---|
| Redirect from HTTP to HTTPS | `Location` on the plain HTTP response | 38 |
| HSTS | `Strict-Transport-Security` | 38 |
| Content Security Policy | `Content-Security-Policy` | 0 |
| Framing protection | `X-Frame-Options`, or `frame-ancestors` in a policy | 0 |
| File type protection | `X-Content-Type-Options` | 0 |
| Referrer policy | `Referrer-Policy` | 0 |
| Permissions policy | `Permissions-Policy` | 0 |

Five details belong with the table.

- Each of the 38 redirects was a `302`, a temporary redirect, to the same host over HTTPS. MDN recommends a permanent redirect such as `301` [^1].
- The HSTS value was the same in all 38 HTTPS responses: `max-age=7776000` (90 days), with no `includeSubDomains` and no `preload`. That does not meet the requirements of the HSTS preload list [^3]. Preloading is not part of the baseline here.
- Thirty-seven of the HTTPS responses had status `200` and an HTML content type. One was a `302` redirect to a domain outside `square.site`, and that store's results come from the redirect response.
- Three plain HTTP redirect responses (1 of 38 in the first pass, 2 of 12 in the second, on different stores) carried a `Content-Security-Policy-Report-Only` header. A report-only policy enforces nothing, and none of the three had `frame-ancestors`. No HTTPS response in either pass carried that header.
- Every response came through the same content delivery network (a relay service in front of a site's servers). Every HTTPS response carried the same value in a header named `x-revision`. The same values across all 38 stores point to one shared configuration, not 38 separately configured servers.

**Check it yourself.** These commands send one plain HTTP request and one HTTPS request to an address and print the response headers. They run in the Terminal app on a Mac, or in a Linux shell such as bash, as long as `curl` is installed. First set `SITE` to the address you want to check, without `http://` or `https://` in front, such as a store's `square.site` address or your own domain:

```bash
SITE="PUT-THE-ADDRESS-HERE"
curl -sI "http://$SITE/"
curl -s -D - -o /dev/null "https://$SITE/"
```

## Check 2: who can set these headers

The table supports part 1 of the hypothesis. Every row came out the same on all 38 stores, which points to the platform, not the merchant, as the party that sets these headers. Part 2 was checked against Square pages and web specifications.

On 13 November 2026 I read six Square pages about Square Online: four Support Center articles (on connecting a domain [^9], troubleshooting a domain [^10], custom tracking codes [^11] and firewall caching [^12]) and two developer pages (the Square Online overview [^13] and the Snippets API reference [^14]). The article on connecting a domain said that Square includes SSL, the encryption behind HTTPS, with any domain a merchant connects, and described these merchant controls: register a domain, connect one, forward one, disconnect one. It described no setting for the HTTPS redirect, HSTS, a Content Security Policy, framing protection or any other response header.

The developer overview described a way to add a script to each page's head (the part not shown on the page), except checkout pages, and a way to list a seller's sites. As described there, neither sets response headers. None of the six pages said which security headers Square sets for Square Online stores, and none described a merchant setting for them.

A setting may exist that those pages do not describe. Two other routes exist on paper:

- **A partial policy from inside the page.** The Content Security Policy specification allows a policy to be delivered by a `meta` element, a tag in the page's head, but `frame-ancestors` is not supported there [^15]. The Referrer Policy specification allows a referrer policy to be set the same way [^16]. The custom tracking codes article described a setting for adding a merchant's own code to a site's head [^11]. So a merchant may be able to add either policy without Square. Measurement 1 read response headers only, so it would not have seen either. HSTS and `X-Frame-Options` do not work from a `meta` element [^17] [^5]. I did not check `X-Content-Type-Options` or `Permissions-Policy` for an in-page route.
- **A layer in front.** The firewall caching article addressed sellers who use a firewall with a Square Online site [^12]. It said a firewall can cache web content (keep copies of it), so I read the firewall as a layer in front of the store. By inference, a layer like that could add response headers on a merchant's own domain. The article covered caching only.

So part 2 is supported only in a narrower form. The Square pages I read on 13 November 2026 described no merchant setting for these headers. Two routes around that exist on paper: a partial Content Security Policy or a referrer policy delivered inside the page, and a layer in front of the store that the merchant runs. Of the two, only the second could supply HSTS, `X-Frame-Options` or `frame-ancestors`. I tested neither route.

## Check 3: how bounty rules rate a missing header

A bug bounty program offers rewards, usually money, to researchers who find and report vulnerabilities [^18]. The rules below come from two platforms that host such programs and two companies that run their own.

- **Bugcrowd.** Version 1.19.1 of Bugcrowd's Vulnerability Rating Taxonomy, released on 8 July 2026, has a subcategory called Lack of Security Headers with 11 entries. Ten are rated P5, including `Strict-Transport-Security`, `Content-Security-Policy`, `X-Frame-Options` and `X-Content-Type-Options`. The eleventh, Cache-Control for a Sensitive Page, is P4. The taxonomy has no entry for `Referrer-Policy` or `Permissions-Policy`. The scale runs from P1 (Critical) to P5 (Informational) [^19]. Bugcrowd's documentation describes a P5 finding as accepted but not rewardable, and says P5 submissions move to Won't Fix automatically unless the program's owner opts in to have specified findings triaged [^20].
- **HackerOne.** Its platform-wide list of ineligible findings says the issues on it are closed as invalid, except in rare cases that demonstrate clear security impact. Two entries matter here: clickjacking on pages with no sensitive actions, and a group it calls optional hardening or missing best practices, which includes SSL/TLS configuration and opinions about a site's Content Security Policy [^21]. The list does not name HSTS or `X-Frame-Options`.
- **Microsoft.** The Microsoft 365 bounty requires Critical or Important severity. Among common out-of-scope issues, which it says do not usually earn an award, it lists missing HTTP security headers, and it names `X-Frame-Options` and `Content-Security-Policy`. That entry is in a group the page describes as based on user configuration or action [^22]. Microsoft's severity guide for online services gives clickjacking from a missing `X-Frame-Options` header or `frame-ancestors` directive as a reference example of Low severity for data it classifies as General [^23].
- **Google.** Its Bug Hunters site files "Lack of HSTS" and "Lack of X-Frame-Options without a well-defined risk" under invalid reports [^24] [^25].

These are defaults, and most come with stated exceptions. Bugcrowd's taxonomy gives P4, not P5, to clickjacking on a sensitive click-based action, to a login over plain HTTP, and to a session token sent unencrypted [^19]. HackerOne's exception is stated above. Microsoft says an out-of-scope submission may still qualify for an award under a separate policy [^22]. A program can also depart from its platform's defaults [^20] [^21]. So part 3 is supported only as a default. The supported statement is that, under Bugcrowd's rules, a report saying only that HSTS, a Content Security Policy, `X-Frame-Options` or `X-Content-Type-Options` is missing is not rewardable by default. It is not that a header gap can never be paid for.

## Check 4: the bounty program that covered Square

Bugcrowd's data gives February 2018 as the start of the Square program it hosted [^26]. Block, whose products include Square, wrote on 14 October 2026 that all five of its Bugcrowd programs stopped accepting new submissions on 30 September 2026, and that since 7 October 2026 it has run one Block-wide program on HackerOne that is private and by invitation only [^27]. The post says the private launch is deliberate and that Block plans to grow the program over time [^27]. Bugcrowd's page for the Square program is marked paused, and its data says the program will not reopen. The brief on that page (the document that sets out the program's terms), as published at 05:59 UTC on 1 October 2026 (22:59 on 30 September in US Pacific time), is the last public statement of those terms [^26]. I found no public page for the HackerOne program's terms, and nothing below describes them.

What the last public terms said:

- **What was offered.** Rewards for P1 to P3 only. The first group of targets (seven sites, apps and devices) listed $5,000 to $18,000 for P1, $1,000 to $5,000 for P2, and $250 to $1,000 for P3. A second group, with one web target, listed the same P1 and P2 amounts and nothing for P3. The brief said P4 findings would not be accepted. It did not mention P5 and set no reward for it.
- **How findings were rated.** The brief said a finding's first rating would use Bugcrowd's taxonomy, and the page's data gave the version as 1.19.1. In that version a report of a missing HSTS, Content Security Policy, `X-Frame-Options` or `X-Content-Type-Options` header is P5 by default, which carried no reward. Clickjacking on a sensitive click-based action is P4, which the brief did not accept.
- **What the exclusions named.** The brief's own exclusion list did not mention security headers, HSTS, Content Security Policy or clickjacking. By default, those reports fell outside the rewards through the taxonomy's rating, not by name. The brief also said a rating could be changed for likelihood or impact, and that a researcher could appeal a downgrade.
- **Whether storefronts were in scope.** A program's scope is the list of sites, apps and devices it accepts reports about. I could not read that list in the brief itself. On 13 November 2026, Bugcrowd sent a logged-out visitor the brief's target names, and one group's description, as blocked-out characters. A public third-party archive of bounty scopes, as saved on 28 September 2026 [^28], lists the program's in-scope web targets as `*.square.com`, `*.squareup.com`, `square.online` and `weebly.com`. It does not list `*.square.site`. The brief's 17 blocked-out names (seven and one in the two groups above, and nine in a third group marked out of scope) match the archive in order, by category and by length. That ties the archive to the brief, but length cannot tell `square.online` from `*.square.site`, which are both 13 characters. So the absence of `*.square.site` rests on the archive, which is more than two days older than the brief. Later versions of the archive and earlier versions of the brief were not checked. The brief allowed other Block-owned domains to be accepted on review.

## Posture and spend, side by side

| Bounty spend | Baseline posture |
|---|---|
| More than $1 million earned by researchers, across Block's programs together [^27] | 2 of 7 baseline protections on all 38 stores measured, and the other 5 on none |

**What the spend figure covers.** It is Block's own figure, published on 14 October 2026, for its programs together. The post dates Block's work with researchers from 2018 and gives no figure per program. I found no public total for Square alone. On 13 November 2026, Bugcrowd's statistics data for the Square program listed 589 rewarded vulnerabilities and an average payout of $2,312.50, with no total and no period [^29].

**What the posture figure covers.** Response headers at the root address of 38 Square Online storefronts on 13 November 2026. Page content was not read.

Under the last public terms of Square's program, a report of a missing Content Security Policy, `X-Frame-Options` or `X-Content-Type-Options` header was P5 by default, which carried no reward. The taxonomy those terms used has no entry for `Referrer-Policy` or `Permissions-Policy`. So, on those terms, the size of the spend is not a measure of the baseline.

## What this does not show

- **It is not a census.** The 38 stores are a convenience sample: 19 from a public listing of `square.site` hostnames and 19 from web searches. Only each store's root address was requested, from one location, on one day. Checkout pages, product pages and stores on a merchant's own domain were not measured.
- **It did not read the pages.** Only response headers were recorded, so a policy delivered inside a page would not have been seen.
- **It is not an exploit.** Whether a missing header matters depends on what the page does.
- **It does not show that only the platform can act.** Two routes exist on paper: a partial Content Security Policy or a referrer policy delivered inside the page, and a layer in front of the store that the merchant runs. I tested neither.
- **The documentation I read was six pages.** A merchant setting may exist that those pages do not describe.
- **It is not the current bounty terms.** Block describes its current program, on HackerOne, as private. The terms here are the last public ones for the Square program on Bugcrowd.
- **Defaults are not verdicts.** The rules name exceptions, and a program can depart from its platform's defaults. They do not show what any program did with any report.
- **It is one platform.** Nothing here tests the hypothesis on any other hosted platform, or compares Square Online with one.

## If your store runs on a hosted platform

- **Look at what your store sends.** Run the commands from Measurement 1 against your own address, or use a free scanner such as MDN's HTTP Observatory [^8]. The commands show response headers only, not anything set inside the page.
- **Ask the platform** which security headers it sets on your pages and whether you can set any yourself. Note the date of the answer, because the configuration can change.
- **Know which pages handle sign-in and payment,** and whose servers serve them. Whether a missing header matters depends on what the page does.
- **Treat baseline headers as a buying criterion.** You get a platform's default headers along with its checkout.
- **Do not count on a bounty program to carry the message.** Under Bugcrowd's rules, for example, a report that says only that HSTS or `X-Frame-Options` is missing is not rewardable by default (see Check 3). Report a missing header to the platform's support channel, or to its security contact if it lists one.

## Method and data

The requests were scripted and run, the cited documents fetched and read, and this text drafted, by an AI coding agent (Anthropic's Claude) working under my direction. Where the note says "I read", "I found" or "I tested", the agent did the work and I reviewed what it reported. Each request to a store was identified as research in its user agent string (the label a program sends to say what it is). The second pass, run separately, also fetched its own copies of most documents cited in Checks 2 to 4. In a third pass, six reviewers (separate runs of the agent) checked a draft of this note against the saved evidence and the live sources, and the revised text was checked again. Where a later pass corrected an earlier one, this note uses the corrected reading. The raw response headers, the per-store table and a fetched copy of every document cited are kept on file with their retrieval times.

I am not publishing the list of stores. They are other people's businesses, and the result was the same on all 38.

This note replaces an earlier one, published on 19 June 2026. What changed is recorded on the [corrections page](/corrections/).

*Measured on 13 November 2026.*

---

## References

[^1]: MDN Web Docs. (2026, September 11). *Strict-Transport-Security header*. Mozilla. Retrieved November 13, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Strict-Transport-Security>

[^2]: OWASP Foundation. (n.d.). *HTTP Strict Transport Security Cheat Sheet*. OWASP Cheat Sheet Series. Retrieved November 13, 2026, from <https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html>

[^3]: *HSTS Preload List Submission*. (n.d.). Retrieved November 13, 2026, from <https://hstspreload.org/>

[^4]: MDN Web Docs. (2026, March 22). *Content-Security-Policy (CSP) header*. Mozilla. Retrieved November 13, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy>

[^5]: MDN Web Docs. (2026, October 28). *X-Frame-Options header*. Mozilla. Retrieved November 13, 2026, from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/X-Frame-Options>

[^6]: OWASP Foundation. (n.d.). *OWASP Secure Headers Project*. Retrieved November 13, 2026, from <https://owasp.org/projects/secure-headers-project>

[^7]: OWASP Foundation. (n.d.). *Response Headers*. OWASP Secure Headers Project. Retrieved November 13, 2026, from <https://secure-headers-project.owasp.org/response-headers/>

[^8]: MDN Web Docs. (n.d.). *HTTP Observatory*. Mozilla. Retrieved November 13, 2026, from <https://developer.mozilla.org/en-US/observatory>

[^9]: Square. (n.d.). *Connect a custom domain to your Square Online site*. Square Support Center. Retrieved November 13, 2026, from <https://squareup.com/help/us/en/article/6916-connect-your-domain-with-square-online-store>

[^10]: Square. (n.d.). *Troubleshoot your Square Online domain*. Square Support Center. Retrieved November 13, 2026, from <https://squareup.com/help/us/en/article/7629-troubleshoot-your-domain-to-see-your-square-online-site>

[^11]: Square. (n.d.). *Add custom tracking codes to your online store*. Square Support Center. Retrieved November 13, 2026, from <https://squareup.com/help/us/en/article/6957-add-custom-tracking-code-to-your-website>

[^12]: Square. (n.d.). *Troubleshoot firewall caching for your online store*. Square Support Center. Retrieved November 13, 2026, from <https://squareup.com/help/us/en/article/8255-troubleshoot-firewall-caching-behavior>

[^13]: Square. (n.d.). *Build eCommerce Applications for Square Online*. Square Developer. Retrieved November 13, 2026, from <https://developer.squareup.com/docs/online-api>

[^14]: Square. (n.d.). *Snippets* (API version 2026-09-16). Square API Reference. Retrieved November 13, 2026, from <https://developer.squareup.com/reference/square/snippets-api>

[^15]: W3C. (2026, October 27). *Content Security Policy Level 3* (W3C Working Draft), section 3.3, The `meta` element. Retrieved November 13, 2026, from <https://www.w3.org/TR/CSP3/#meta-element>

[^16]: W3C. (2017, January 26). *Referrer Policy* (W3C Candidate Recommendation), section 4, Referrer Policy Delivery. Retrieved November 13, 2026, from <https://www.w3.org/TR/referrer-policy/#referrer-policy-delivery>

[^17]: Hodges, J., Jackson, C., & Barth, A. (2012, November). *RFC 6797: HTTP Strict Transport Security (HSTS)*, section 8.5. Internet Engineering Task Force. <https://www.rfc-editor.org/info/rfc6797/#section-8.5>

[^18]: OWASP Foundation. (n.d.). *Vulnerability Disclosure Cheat Sheet*. OWASP Cheat Sheet Series. Retrieved November 13, 2026, from <https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html>

[^19]: Bugcrowd. (2026, July 8). *Vulnerability Rating Taxonomy* (Version 1.19.1). GitHub. <https://github.com/bugcrowd/vulnerability-rating-taxonomy/releases/tag/v1.19.1>. The ratings are in the file `vulnerability-rating-taxonomy.json` at that tag (<https://raw.githubusercontent.com/bugcrowd/vulnerability-rating-taxonomy/v1.19.1/vulnerability-rating-taxonomy.json>), and the scale is described in `README.md` at the same tag.

[^20]: Bugcrowd. (n.d.). *Managing Submission Severity*. Bugcrowd Docs. Retrieved November 13, 2026, from <https://docs.bugcrowd.com/customers/submission-management/severity-overview/>

[^21]: HackerOne. (2025, May 19). *Core Ineligible Findings*. HackerOne Help Center. <https://docs.hackerone.com/en/articles/8494488-core-ineligible-findings>

[^22]: Microsoft Security Response Center. (2026, October 22). *M365 Bounty*. Retrieved November 13, 2026, from <https://www.microsoft.com/en-us/msrc/bounty-online-services>

[^23]: Microsoft Security Response Center. (n.d.). *Microsoft Vulnerability Severity Classification for Online Services*. Retrieved November 13, 2026, from <https://www.microsoft.com/en-us/msrc/olsbugbar>

[^24]: Google. (n.d.). *Lack of HSTS (HTTP Strict Transport Security)*. Google Bug Hunters. Retrieved November 13, 2026, from <https://bughunters.google.com/learn/invalid-reports/network-protocols/lack-of-hsts-http-strict-transport-security>

[^25]: Google. (n.d.). *Lack of X-Frame-Options without a well-defined risk*. Google Bug Hunters. Retrieved November 13, 2026, from <https://bughunters.google.com/learn/invalid-reports/web-platform/csrf-clickjacking/lack-of-x-frame-options-without-a-well-defined-risk>

[^26]: Bugcrowd. (2026, October 1). *Bug Bounty: Square - Bugcrowd* [Bug bounty engagement brief, marked paused]. Retrieved November 13, 2026, from <https://bugcrowd.com/engagements/square>

[^27]: Block Security Team. (2026, October 14). *Block's Bug Bounty Program Is Moving to HackerOne*. Block Engineering Blog. <https://engineering.block.xyz/blog/blocks-bug-bounty-program-is-moving-to-hackerone>

[^28]: *bugcrowd_data.json* [Data file of Bugcrowd program scopes]. (2026, September 28). In *bounty-targets-data*, commit `aaf3c4f`. GitHub. Retrieved November 13, 2026, from <https://github.com/arkadiyt/bounty-targets-data/blob/aaf3c4f4b1e3c6951bf9f04f29c3daf21798cbb2/data/bugcrowd_data.json>

[^29]: Bugcrowd. (n.d.). [Statistics data for the Square program, served as JSON with no title]. Retrieved November 13, 2026, from <https://bugcrowd.com/engagements/square/statistics>
