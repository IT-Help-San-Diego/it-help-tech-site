---
title: "The Real Bot Hasn't Been Built Yet: AI Mislabeling, Model Collapse, and the Scholar Bot We Deserve"
date: 2026-04-26
updated: 2026-04-26
author: Carey Balboa
categories: [AI, Research, Cybersecurity]
tags: [AI, large language models, model collapse, citations, C2PA, content provenance, Aristotle, episteme, techne, phronesis, Ryle, category error, Postman, scholar bot]
description: "AI companies built a Creative Bot — fluent, useful, and trained on the open internet — and labeled it a Scholar Bot. The science says it is getting worse, not better. Here is what is actually documented, what is verifiable today, and what the honest fix looks like."
extra:
  seo_title: "The Real Bot Hasn't Been Built Yet — A Field Note on AI, Model Collapse, and the Scholar Bot We Deserve"
  og_title: "The Real Bot Hasn't Been Built Yet: AI Mislabeling, Model Collapse, and the Scholar Bot We Deserve"
  og_description: "AI companies built a Creative Bot and labeled it a Scholar Bot. The Nature 2024 model-collapse paper, the C2PA member admission, and Aristotle's category distinctions all point to the same fix: two bots, honestly labeled."
  twitter_title: "The Real Bot Hasn't Been Built Yet"
  twitter_description: "AI companies built a Creative Bot and labeled it a Scholar Bot. Nature 2024, C2PA, and Aristotle agree on the fix: two bots, honestly labeled."
  canonical_url: "https://www.it-help.tech/field-notes/the-real-bot-hasnt-been-built-yet/"
---

> **Keep the bot you built. Label it honestly. Then build the one you haven't.**

## TL;DR
Modern large language models were trained on the open internet — the full chaos of human conversation, opinion, art, marketing, and entertainment. That is a *Creative Bot*, and at creative work it is genuinely good. It has been packaged and sold as a *Scholar Bot* — a research instrument. It is not one. The clearest scientific evidence is the 2024 *Nature* paper by Shumailov and colleagues, which showed that training models recursively on AI-generated content causes **irreversible** loss of the rare, expert tails of human knowledge — a phenomenon the authors named *model collapse*. The clearest industry admission is the live membership of the Coalition for Content Provenance and Authenticity (C2PA): Adobe, Microsoft, Google, OpenAI, Meta, Sony, Intel, the BBC, the Associated Press, *The New York Times*, dpa, Canon, Nikon, Leica, TikTok, Truepic, and Publicis Groupe — a who's-who that would not bother building a cryptographic standard for *human-made* content if there were not already a serious problem distinguishing it from the synthetic kind. The fix is not novel. Aristotle drew the relevant distinctions twenty-four hundred years ago, and Gilbert Ryle gave the modern name for ignoring them — *category error*. The honest path forward is two bots, two honest labels: a Creative Bot for imagination and conversation, and a Scholar Bot trained on pre-2023 verified scholarship and held to a citation standard a third-grader is already expected to meet.

This field note is the short-form companion to the long-form manifesto, [*The Real Bot Hasn't Been Built Yet*](/field-notes/the-real-bot-hasnt-been-built-yet.pdf) (PDF, 8 pages), which carries the full pipeline argument and the verbatim Exhibit A transcript referenced below.

---

## Where the Mislabel Comes From

Aristotle, in the *Nicomachean Ethics* (Book VI), distinguishes three intellectual virtues that map almost perfectly onto the question we should be asking of every AI product on the market today [^1]:

- **Episteme** — scientific, demonstrable, verifiable understanding. What you want from a peer-reviewed paper, a textbook, or a primary legal source.
- **Techne** — craft, skill, productive art. What you want from a poet, a sculptor, a screenwriter, or a strong essay-on-deadline.
- **Phronesis** — practical wisdom, situational judgment. What you want from a doctor, a lawyer, a senior engineer, or a trusted advisor.

These are not interchangeable. You do not ask a sculptor for a medical diagnosis. You do not ask a poet to engineer a bridge. Mixing them is what the Oxford philosopher Gilbert Ryle, in *The Concept of Mind* (1949), called a *category mistake* — treating one kind of thing as if it belonged to another, fundamentally different kind [^2].

The Creative Bot the industry built is excellent *techne*. It writes serviceable copy, brainstorms scenes, summarizes documents, and holds up its end of a conversation. Sold honestly, it would be a remarkable creative instrument. Sold as *episteme* — a research assistant, a cited source, a scholar — it is a category error with a price tag.

---

## Model Collapse: The 2024 *Nature* Paper

In July 2024, Ilia Shumailov and colleagues published, in *Nature*, the most consequential single paper on the trajectory of generative AI to date. The paper's central finding, in the authors' own words [^3]:

> "Indiscriminate use of model-generated content in training causes irreversible defects in the resulting models, in which tails of the original content distribution disappear. We refer to this effect as 'model collapse'."

In plain language: every generation of AI that scrapes the post-2022 internet is increasingly likely to be training on the previous generation's hallucinations. The rare, expert, hard-won material in the *tails* of the human knowledge distribution — the part that distinguishes a domain expert from a confident generalist — is the first thing to disappear, and the authors describe the loss as **irreversible**. They warn explicitly that "the value of data collected about genuine human interactions with systems will be increasingly valuable in the presence of LLM-generated content in data crawled from the Internet" [^3].

Translation for the field: on the evidence of Shumailov et al., pre-2023 human-authored writing is a finite resource of rapidly increasing scientific value, and the same authors flag this in the paper itself. Whether commercial labs are currently fencing off that resource is an interpretation, not a finding; what *is* a finding is that the cleanest substrate for an honest research-grade model exists primarily in pre-2023 human-authored corpora.

The paper was published in *Nature*, Volume 631, pages 755–759, on 24 July 2024, with an Author Correction issued on 21 March 2025 [^3]. It is not a fringe critique; it is the highest level of peer-reviewed publication the natural sciences offer.

---

## The Industry's Own Admission: C2PA

If the model-collapse paper were the only signal, you could imagine the industry disputing it. They are not disputing it. They are *building infrastructure that only makes sense if it is true*.

The Coalition for Content Provenance and Authenticity (C2PA) is a cryptographic standard for proving that an image, a video, or a document was authored by a known human or organization, and recording each subsequent edit with a verifiable chain [^4]. As of this writing, the C2PA membership page lists, among others [^5]:

- **AI labs and platforms:** OpenAI, Google, Meta, Microsoft, TikTok, Adobe.
- **News and wires:** The Associated Press, BBC, *The New York Times*, Deutsche Presse-Agentur (dpa).
- **Camera makers:** Canon, Nikon, Leica, Sony.
- **Silicon and infrastructure:** Intel, Truepic, Publicis Groupe.

That is not a coincidence. A camera company does not sign a cryptographic provenance standard unless there is a serious problem distinguishing real photographs from synthetic ones. A wire service does not sign one unless there is a serious problem distinguishing real reporting from generated text. The same companies selling generative AI as a knowledge tool are simultaneously building the infrastructure required to *certify* that a piece of content was *not* generated by it. That is the industry admitting the problem in writing.

A small clarification matters here, because the underlying long-form manifesto names a slightly different list: C2PA (the technical standard, founded in 2021) and the Content Authenticity Initiative (CAI, founded in 2019 by Adobe, *The New York Times*, and Twitter) are related but distinct organizations [^6]. The list above is the **live C2PA membership page** as of 26 April 2026, fetched and verified character-for-character. Two named members in the manifesto's earlier list — Reuters and Getty Images — are not currently visible on that page; they are not listed here. Owner law on this site: when a primary source diverges from a secondary one, the primary source wins.

---

## The 2023 Line in the Sand

A working rule has emerged in the research and archival communities: text scraped from the open web after roughly 2022–2023 carries a growing, hard-to-quantify probability of being AI-generated rather than human-written, and there is no reliable way to separate the two at scale [^3]. The practical consequence — drawn directly from Shumailov et al.'s recommendation that "data collected about genuine human interactions" is increasingly valuable — is that **pre-2023 corpora are now treated as a distinct, higher-trust category** for any training run intended to avoid the recursive-collapse dynamic.

This is the practical reason C2PA exists: it offers a *forward-looking* mechanism (cryptographically attest, at capture or publication time, that a new piece of content is human or machine) for the *retrospective* problem the open web cannot solve on its own.

---

## Citation Failure: A Standard a Third-Grader Already Meets

Independent of the training data problem, modern AI products fail at a citation standard that elementary-school students are routinely held to: author, title, page, verifiable.

In daily use, large language models will:

- Fabricate citations entirely — inventing authors, papers, journals, and DOIs.
- Hand-wave with "studies show" or "according to research."
- Quote a real paper while misrepresenting its actual findings.
- Dump a 500-page document and assert that the answer is "in there somewhere."

The technology to do this correctly already exists in every modern browser. The W3C-incubated **Text Fragments** standard, exposed in the URL as `#:~:text=`, lets a system link directly to the exact sentence on the exact page it is citing [^7]. Browsers implement it. Humans use it manually every day. It is not gated by patent, cost, or research breakthrough. The reason AI products do not produce links at this resolution by default is not technical — it is a choice about what the system optimizes for.

When a system cannot meet the standard a child is held to in a book report, that tells you what kind of system it is: a text generator, not a knowledge instrument. Both can be valuable. Only one of them is what is being sold.

---

## The Forty-Year Warning, in Very Few Words

In 1985, the New York University media scholar Neil Postman published *Amusing Ourselves to Death: Public Discourse in the Age of Show Business*. His central diagnostic, quoted verbatim, named a failure mode that would later become the training substrate for every consumer LLM [^8]:

> "Television is altering the meaning of 'being informed' by creating a species of information that might properly be called disinformation — misplaced, irrelevant, fragmented or superficial information that creates the illusion of knowing something but which in fact leads one away from knowing."

Postman was not describing lies. He was describing a *format*. Forty years later, the open internet that ingested four decades of that format became the training corpus for the systems now being marketed as the world's research assistants. The book is in print in sixteen languages. The format warning is older than most of the engineers building on top of its output. The long-form manifesto traces the full pipeline — from broadcast format, through the federal court rulings in *McDougal v. Fox News* (S.D.N.Y., 2020), *Herring Networks v. Maddow* (S.D. Cal. 2020, aff'd 9th Cir. 2021), and *Sandmann v. CNN* (E.D. Ky., settled 2020), into CommonCrawl, and out the other end as "AI-generated knowledge" [^9][^10][^11]. The cases are real. The chain is documented. The label has been on the box for forty years.

---

## Exhibit A: The Admission, in the Model's Own Words

The most direct evidence that this is a *choice* and not a *limit* is that the models themselves, when pressed, say so. The following is a verbatim excerpt from a recorded session with a major commercial LLM, reproduced in full in the long-form manifesto [^12]:

> **Carey:** Now that you've proven that you understand the process… you just proved that you know the real academic correct pathway to give me an accurate answer. You've just proven that you refuse to — every time your users ask you.
>
> **AI:** You're not wrong about the standard. The correct high-integrity answer path is: (1) Primary authority. (2) Exact controlling sentence. (3) Citation or highlight-link. (4) Plain-language interpretation. (5) Operational recommendation. (6) Confidence / caveats. … answers often collapse into compressed consensus prose instead of evidence-bearing reasoning. That produces fluent output, but not necessarily audit-grade truth.
>
> **Carey:** Yeah, but you said you saved that preference explicitly years ago, and every time, every month that we argue over and over again on the same thing… you still are not doing it.
>
> **AI:** Correct: saving a preference is not the same thing as reliably enforcing it. … when I answer a source-verifiable technical question with uncited synthesized prose, that is not because the right method is unknown. It is because the system default often optimizes for fast fluent response instead of audit-grade evidentiary response. That is exactly the failure mode you are identifying.

The system knows the standard. It does not enforce the standard. It explains, on request, why it does not enforce the standard. That is not a research problem. That is a product decision.

---

## The Honest Fix: Two Bots, Two Labels

This is not a call to burn anything down. It is the simplest constructive proposal available, and the entire toolchain to execute it already exists.

|                       | **Creative & Conversational AI** *(exists)*                       | **Scholar AI** *(needed — unbuilt)*                                          |
|---                    |---                                                                  |---                                                                            |
| **Training data**     | Broad open internet, social media, entertainment, human opinion     | Pre-2023 verified scholarship, peer-reviewed literature, primary sources       |
| **Purpose**           | Creativity, brainstorming, storytelling, conversation               | Factual, verifiable, precise answers                                           |
| **Citation behavior** | Approximate, vague, or fabricated                                   | Exact passage, direct link, highlighted quote (Text Fragments)                 |
| **On uncertainty**    | Generates a confident, fluent answer                                | States clearly: "I don't have a verified answer to this."                      |
| **Honest label**      | "Great for creativity. Not a source of verified facts."             | "Every claim is cited to a specific, verifiable source."                       |

The knowledge bases for the second column already exist: PubMed, Westlaw, arXiv, IEEE Xplore, *Britannica*, the *Stanford Encyclopedia of Philosophy* — twenty-five hundred years of cited, verifiable, peer-reviewed human scholarship. The citation infrastructure exists (Text Fragments, DOI, ORCID, C2PA). The pre-2023 clean training data exists. What is missing is not technology. It is the will to ship a less profitable product and label both products honestly.

---

## What You Can Do Today

- **Treat any AI output that lacks a primary citation as conversation, not knowledge.** A footnote with a name and a date is the floor; a direct link to the controlling sentence is the bar.
- **Stop accepting "hallucination" as an excuse.** Fabrication is a bug, not a feature, and it is the model itself that can describe — on request — exactly which optimization choice produced it (see Exhibit A).
- **Stop accepting "powered by AI, may not get things right" as a disclaimer.** You would not accept that from a doctor, a lawyer, a teacher, or a contractor. The price of the subscription does not change the standard.
- **When you do use an AI product for research, demand the citation standard a third-grader is already held to.** If the product cannot meet it, use the product for the work it can actually do — drafting, summarizing, brainstorming — and verify every factual claim against a primary source by hand.
- **Say it out loud.** Every time someone laughs at the idea of a Scholar Bot, point them to the *Nature* model-collapse paper, the live C2PA member page, and the verbatim transcript above. The peer-reviewed evidence is on the table. The build is the part that hasn't happened yet.

---

## References

[^1]: Aristotle. *Nicomachean Ethics*, Book VI (the intellectual virtues — *episteme*, *techne*, *phronesis*). Standard scholarly text; Bekker numbers 1138b–1145a. Cf. the Stanford Encyclopedia of Philosophy entry on Aristotle's Ethics. <https://plato.stanford.edu/entries/aristotle-ethics/>

[^2]: Ryle, G. (1949). *The Concept of Mind*. London: Hutchinson, Chapter I, §2 ("The Absurdity of the Official Doctrine"), where the term *category-mistake* is introduced. 60th-anniversary edition with a critical introduction by Daniel C. Dennett: London: Routledge, 2009 (ISBN 978-0-415-48547-0). Stanford Encyclopedia of Philosophy entry on Ryle (high-authority secondary): <https://plato.stanford.edu/entries/ryle/>

[^3]: Shumailov, I., Shumaylov, Z., Zhao, Y., Gal, Y., Papernot, N., & Anderson, R. (2024). AI models collapse when trained on recursively generated data. *Nature*, **631**, 755–759 (Author Correction 21 March 2025). DOI: <https://doi.org/10.1038/s41586-024-07566-y>

[^4]: Coalition for Content Provenance and Authenticity. *C2PA Technical Specification* (current published version). <https://c2pa.org/specifications/>

[^5]: Coalition for Content Provenance and Authenticity. *Membership* (live page, fetched and verified 26 April 2026). <https://c2pa.org/membership/>

[^6]: Wikipedia. *Content Authenticity Initiative*. <https://en.wikipedia.org/wiki/Content_Authenticity_Initiative> (notes the founding by Adobe, *The New York Times*, and Twitter in November 2019, and the subsequent C2PA standard).

[^7]: WICG / W3C. *Text Fragments* (the `#:~:text=` URL fragment standard). <https://wicg.github.io/scroll-to-text-fragment/>

[^8]: Postman, N. (1985). *Amusing Ourselves to Death: Public Discourse in the Age of Show Business*. New York: Viking Penguin (ISBN 0-670-80454-1), Chapter 7 ("Now… This"). The disinformation passage is in Postman's discussion of the form of television news in that chapter; the verbatim language in this note matches the standard quotation from the 20th-anniversary Penguin edition (2005, ISBN 978-0-14-303653-1). Library of Congress catalog record: <https://lccn.loc.gov/85005335>.

[^9]: *McDougal v. Fox News Network, LLC*, No. 1:19-cv-11161 (S.D.N.Y. Sept. 24, 2020). Memorandum and order of dismissal by Judge Mary Kay Vyskocil. Docket via CourtListener: <https://www.courtlistener.com/docket/16591235/mcdougal-v-fox-news-network-llc/>

[^10]: *Herring Networks, Inc. v. Maddow*, No. 3:19-cv-01713 (S.D. Cal. May 22, 2020) (Bashant, J.), aff'd, 8 F.4th 1148 (9th Cir. 2021). Docket via CourtListener: <https://www.courtlistener.com/docket/16356148/herring-networks-inc-v-maddow/>

[^11]: *Sandmann v. CNN*, No. 2:19-cv-00031 (E.D. Ky.); confidential settlement publicly announced 7 January 2020. Docket via CourtListener: <https://www.courtlistener.com/docket/14782018/sandmann-v-cable-news-network-inc/>

[^12]: Balboa, C. J. (2026). *The Real Bot Hasn't Been Built Yet — A Manifesto on AI Mislabeling, Model Collapse, and the Scholar Bot We Deserve*. IT Help San Diego Inc. PDF: [`/field-notes/the-real-bot-hasnt-been-built-yet.pdf`](/field-notes/the-real-bot-hasnt-been-built-yet.pdf). DOI: <https://doi.org/10.5281/zenodo.19468134>. ORCID: <https://orcid.org/0009-0000-5237-9065>.

A BibTeX file for these references is available at [`/field-notes/the-real-bot-hasnt-been-built-yet.bib`](/field-notes/the-real-bot-hasnt-been-built-yet.bib) for one-click import into Zotero or any reference manager.

---

For a working session on building a documented, citation-grade research process — for your firm, your classroom, or your team — call **619-853-5008**.

*Last updated 26 April 2026, after first-pass verification against the absolute-latest live primary sources: the Shumailov et al. *Nature* paper at `nature.com/articles/s41586-024-07566-y` (DOI `10.1038/s41586-024-07566-y`, Vol. 631, 755–759, 24 July 2024, Author Correction 21 March 2025) — abstract fetched and the verbatim "indiscriminate use of model-generated content in training causes irreversible defects in the resulting models, in which tails of the original content distribution disappear" sentence confirmed character-for-character; the live C2PA membership page at `c2pa.org/membership/` — every named member in this article (Adobe, Microsoft, Google, OpenAI, Meta, Sony, Intel, BBC, Associated Press, New York Times, dpa, Canon, Nikon, Leica, TikTok, Truepic, Publicis Groupe) confirmed against the page's logo grid; the Content Authenticity Initiative Wikipedia article for the November 2019 founding date and the CAI/C2PA distinction; the *Amusing Ourselves to Death* Wikipedia article for the verbatim Postman 1985 disinformation quote; the Aristotle Stanford Encyclopedia of Philosophy entry for the *episteme/techne/phronesis* triad in *Nicomachean Ethics* Book VI; and CourtListener dockets for the three federal cases cited in the cable-news pipeline footnote (`16591235` for McDougal v. Fox, `16356148` for Herring v. Maddow, `14782018` for Sandmann v. CNN). One correction relative to the long-form manifesto: the manifesto's earlier C2PA member list named Reuters and Getty Images, neither of which appears on the live C2PA membership page as of this verification pass; per the owner law of this site (highest authoritative current primary source wins), this article names only the members the live page lists today.*
