---
title: "The Owl Semaphore"
date: 2026-06-20
updated: 2026-06-20
author: Carey Balboa
categories: [Research, Methodology]
tags: [owl semaphore, epistemic notation, Klein four-group, symmetry, RFC 2119, accessibility, WCAG, metacognition, peer review, DNS Tool]
description: "The Owl Semaphore is a four-state visual notation for marking how a claim should be evaluated before you believe, challenge, or act on it. Four owls—standard, exploration, inversion, self-audit—mapped onto the symmetries of the Klein four-group."
aliases:
  - /blog/the-owl-semaphore/
extra:
  seo_title: "The Owl Semaphore: A Four-State Visual Notation for How to Read a Claim"
  og_title: "The Owl Semaphore"
  og_description: "Four owls tell the reader what kind of thinking they are looking at—standard, exploration, inversion, or self-audit. A finite epistemic algebra, drawn as a semaphore, mapped onto the Klein four-group."
  twitter_title: "The Owl Semaphore"
  twitter_description: "A four-state visual notation (NORMATIVE, NON-NORMATIVE, CRITICAL, METACOGNITIVE) for marking how a claim should be evaluated. Color + orientation + label, mapped onto the Klein four-group V₄."
  canonical_url: "https://www.it-help.tech/field-notes/the-owl-semaphore/"
---

## What the Owl Semaphore Is

Most notation tells you *what* something says. The Owl Semaphore tells you *how to read it*: whether a claim is meant as the standard, as a structured departure from it, as a deliberate inversion of it, or as an audit of the frame you are using to judge it at all. It is a small, fixed vocabulary—four states, four owls—designed to sit next to a claim, a document, a dataset, or a finding and mark the *kind of evaluation* it has already been through.

It is easiest to describe in three layers, each true at a different level of precision:

- **Formal.** A finite algebra over epistemic states, implemented as a reproducible visual notation system with enforced invariants.
- **Operational.** A four-state visual system for marking how a claim, document, dataset, or finding should be evaluated before belief, challenge, or action.
- **Human.** Four owls tell the reader what kind of thinking they are looking at: standard, exploration, inversion, or self-audit.

The four states are **NORMATIVE**, **NON-NORMATIVE**, **CRITICAL**, and **METACOGNITIVE**. Each is drawn as the Owl of Athena in a distinct orientation and color, and—this is the part that matters for honesty—each is *also* spelled out in a literal text label. The picture is a convenience; the word is the contract.

This Field Note ports and updates the standalone description that has lived on the [DNS Tool](https://dnstool.it-help.tech/owl-semaphore) site, bringing it in line with the **v3.0.0** release of the system [^repo]. The v3 release does not change the four states or their algebra; it adds the formal justification for *why* there are exactly four, states the system's limits plainly, and tightens the language so the analogies it borrows stay analogies.

---

## Table of Contents

1. [The Four Owls](#the-four-owls)
2. [Why Exactly Four States](#why-exactly-four-states)
3. [The Mathematical Foundation](#the-mathematical-foundation)
4. [Triple-Redundant Encoding and Accessibility](#triple-redundant-encoding-and-accessibility)
5. [Standards Mapping](#standards-mapping)
6. [The Owl in Human Experience](#the-owl-in-human-experience)
7. [Limitations and Scope Boundaries](#limitations-and-scope-boundaries)
8. [Use Boundaries and Ethics](#use-boundaries-and-ethics)
9. [Where It Came From: the DNS Tool](#where-it-came-from-the-dns-tool)
10. [Download, Cite, and License](#download-cite-and-license)

---

## The Four Owls

Each state is a symmetry of one upright owl. Read the owl as a coordinate plane: the identity leaves it untouched; the other three are the reflections and rotation that a square figure admits. Every move is its own undo—do it twice and you are back where you started.

### NORMATIVE: The Standard

{{ picture_simple(base="images/owl-semaphore-norm", alt="NORMATIVE owl: the Owl of Athena upright, gold, facing forward—the unaltered standard state.", class="img-centered-240", width="480", height="480", loading="lazy", decoding="async") }}

- **Operator:** identity, *I* — determinant **+1**
- **Transform:** (x, y) → (x, y) (no change)
- **Reads as:** *"This is the standard."*
- **Register:** RFC 2119 **MUST / SHALL** [^rfc2119]

The upright gold owl is the baseline: operationally validated within a stated domain. It is the thing other states are measured against. NORMATIVE does not mean "true" and it does not mean "approved by the people in charge"—it means *this is the established convention here.*

### NON-NORMATIVE: The Lateral Reflection

{{ picture_simple(base="images/owl-semaphore-nonnorm", alt="NON-NORMATIVE owl: the Owl of Athena reflected left-to-right, teal—a structured departure from the standard.", class="img-centered-240", width="480", height="480", loading="lazy", decoding="async") }}

- **Operator:** vertical-axis reflection, σᵥ — determinant **−1**
- **Transform:** (x, y) → (−x, y) (mirror left↔right)
- **Reads as:** *"This reflects the standard."*
- **Register:** Informative / Advisory (**NOTE**)

The owl faces the other way. NON-NORMATIVE is a legitimate, structured exploration that is *not* the baseline—an advisory note, an alternative reading, a path that diverges on purpose. The whole reason this state exists as a *distinct* category, rather than collapsing into "wrong," is to protect exploration that disagrees with the convention without being an error.

### CRITICAL: The Inversion

{{ picture_simple(base="images/owl-semaphore-crit", alt="CRITICAL owl: the Owl of Athena rotated 180 degrees, crimson—a full inversion of the standard.", class="img-centered-240", width="480", height="480", loading="lazy", decoding="async") }}

- **Operator:** 180° rotation, C₂ — determinant **+1**
- **Transform:** (x, y) → (−x, −y) (half-turn)
- **Reads as:** *"This inverts the standard."*
- **Register:** RFC 2119 **MUST NOT / SHALL NOT** [^rfc2119]

The owl is turned fully upside down. CRITICAL marks a claim that has been subjected to adversarial or falsification analysis—the standard's own logic turned against it. Note the algebra: a half-turn is the *composition* of the two reflections (mirror left-right, then flip top-bottom). CRITICAL is not a fourth idea bolted on; it is what the other two moves *make* when combined. "Critical" here means *examined to the point of inversion*, not *condemned*.

### METACOGNITIVE: The Frame Audit

{{ picture_simple(base="images/owl-semaphore-meta", alt="METACOGNITIVE owl: the Owl of Athena reflected top-to-bottom, amethyst—an audit of the observer's own frame.", class="img-centered-240", width="480", height="480", loading="lazy", decoding="async") }}

- **Operator:** horizontal-axis reflection, σₕ — determinant **−1**
- **Transform:** (x, y) → (x, −y) (mirror top↔bottom)
- **Reads as:** *"The observer audits the frame."*
- **Register:** Epistemic / Framework (**META**)

The owl is flipped onto its back, looking up at itself. METACOGNITIVE is the move that questions the instrument rather than the reading—*the problem may be the lens I am looking through.* In v3 this state's canonical wording is **"The observer audits the frame"** (the earlier "This audits the standard" phrasing is retired, because the point is precisely that the audit is turned on the observer, not the object).

---

## Why Exactly Four States

The number four is not chosen for tidiness; it is forced. Two independent yes/no distinctions, closed under composition, produce exactly four states and no others:

- **Distinction 1 — orientation of stance toward the standard.** A claim can be read in agreement with the prevailing standard, or laterally reflected against it. This is the σᵥ axis.
- **Distinction 2 — locus of audit.** Evaluation can be aimed at the object under analysis, or turned back onto the observer's own evaluative frame. This is the σₕ axis.

From there the count is settled by elimination:

- **Not two.** A single binary (normative vs. not) cannot represent the frame-audit move at all. It collapses two genuinely different failure modes into one bucket, and a reader who sees only that bucket cannot tell whether to *challenge the claim* or *audit themselves.*
- **Not three.** Take any three of the four and the set is not closed: compose the two reflections and you produce the fourth (σᵥ then σₕ gives the half-turn, C₂). A three-state system names some moves but not the move its own moves generate. **Closure forces the fourth state into existence**—that is the central structural fact of the system.
- **Not six or eight.** Larger symmetry groups only add generators with no new epistemic meaning. They re-describe the same two underlying distinctions under more names: redundant labels, not new kinds of thinking.
- **Not a continuous scale.** A confidence dial from 0 to 1 answers *how sure* you are along one axis. The frame-audit move is not "more skeptical"—it is *sideways* to confidence, questioning the instrument rather than the reading. You cannot reach METACOGNITIVE by sliding a normativity slider, because it lives on a different axis. Where you genuinely need a confidence gradient, run it *alongside* the semaphore; the two answer different questions.

Four is the unique answer that is both **complete** (closed under composition) and **non-redundant** (no spare states).

---

## The Mathematical Foundation

The four states are the four elements of the **Klein four-group**, written V₄ [^klein]. Mapping the states onto a finite group is what makes the system *checkable* rather than merely asserted: you can verify closure with a multiplication table instead of trusting a taxonomy.

| State | Operator | det | Transform | Reads as | Register |
|---|---|---|---|---|---|
| NORMATIVE | *I* | +1 | (x, y) → (x, y) | "This is the standard." | MUST / SHALL |
| NON-NORMATIVE | σᵥ | −1 | (x, y) → (−x, y) | "This reflects the standard." | Informative (NOTE) |
| CRITICAL | C₂ | +1 | (x, y) → (−x, −y) | "This inverts the standard." | MUST NOT / SHALL NOT |
| METACOGNITIVE | σₕ | −1 | (x, y) → (x, −y) | "The observer audits the frame." | Framework (META) |

Composing any two states yields a third defined state. The full table is closed—every cell lands back inside the set:

| ∘ | *I* | σᵥ | C₂ | σₕ |
|---|---|---|---|---|
| **I** | *I* | σᵥ | C₂ | σₕ |
| **σᵥ** | σᵥ | *I* | σₕ | C₂ |
| **C₂** | C₂ | σₕ | *I* | σᵥ |
| **σₕ** | σₕ | C₂ | σᵥ | *I* |

Two design choices are worth stating explicitly, because they are what make V₄ the *right* structure rather than a near-miss:

- **Why V₄ and not the cyclic group C₄.** Every state move in this system is its own inverse: reflect a stance twice and you return to it; audit a frame and audit it back and you return to the original reading. That involutive property (g² = *I* for every element) holds in V₄ and fails in C₄, whose generator has order 4. C₄ would impose a directional 4-cycle on states that have no such ordering.
- **Why an abelian group, and an algebra at all.** The two distinctions commute: reflecting stance then auditing frame gives the same result as auditing frame then reflecting stance. That order-independence is exactly the abelian condition, so a non-abelian group would encode a path-dependence the phenomena do not exhibit. And an *algebra*, rather than a flat list of four labels, is what lets you say that CRITICAL *is* the composition of the two reflections—and verify it—rather than asserting four unrelated names.

This is the place to be careful about claims. The Owl Semaphore is designed to be *compatible* with established mathematics and to borrow *carefully bounded analogies* from epistemology and cognitive science. It is not a unified theory of knowledge. When the literature on self-reference is invoked—Gödel's incompleteness results, for instance—it is **illustrative**: a familiar example of a system reasoning about its own limits, not a claim that the semaphore proves anything Gödel proved. The same restraint applies to CRITICAL: terms like "inversion" and "self-audit" are structural descriptions, not psychiatric or diagnostic ones.

---

## Triple-Redundant Encoding and Accessibility

A notation that depends on color alone excludes the people most likely to be reading carefully. The Owl Semaphore therefore encodes every state three independent ways:

1. **Color** — gold, teal, crimson, amethyst.
2. **Orientation** — upright, mirrored, inverted, flipped.
3. **Literal label** — the words NORMATIVE, NON-NORMATIVE, CRITICAL, METACOGNITIVE.

The label is authoritative. Color and orientation are aids; the text is the contract. This satisfies the spirit of WCAG 2.2 Success Criterion 1.4.1, *Use of Color*: meaning is never carried by color alone [^wcag141].

The CRITICAL state makes this rule unusually vivid. Its composite is intentionally rendered as a low-contrast crimson-on-crimson figure—roughly 1.10:1, far below any legibility threshold. That is deliberate: it is the acute test of the system's own rule. If you cannot reliably distinguish CRITICAL by *looking*, you fall back to the orientation and, above all, to the label—which is exactly what the design intends. The badge is unreadable by color; the state is never unreadable, because the word is always present.

Within this Field Note, every owl image carries descriptive alt text naming its state, and each state is spelled out in the surrounding text, so nothing here depends on seeing the color either.

---

## Standards Mapping

The four states line up cleanly with the conformance vocabulary practitioners already use, which is part of why the notation is easy to adopt:

| Owl state | RFC 2119 / register | What it signals |
|---|---|---|
| NORMATIVE | MUST / SHALL | The validated standard within a stated domain. |
| NON-NORMATIVE | NOTE (informative) | A legitimate, advisory departure—explore, don't enforce. |
| CRITICAL | MUST NOT / SHALL NOT | A position reached by inversion or falsification analysis. |
| METACOGNITIVE | META (framework) | An audit of the evaluative frame itself. |

The mapping to RFC 2119 keywords [^rfc2119] is an *analogy of register*, not a claim that the IETF defined a metacognitive state. It exists so that someone fluent in standards documents can read an owl without learning a new severity scale from scratch.

---

## The Owl in Human Experience

Strip away the algebra and the semaphore describes four ordinary moves anyone makes when they think carefully about a claim:

- **NORMATIVE** is *taking the established view*—reading something the way it is conventionally meant.
- **NON-NORMATIVE** is *trying it the other way around*—holding an alternative without insisting it is the rule.
- **CRITICAL** is *turning the claim against itself*—the deliberate, adversarial test.
- **METACOGNITIVE** is *catching yourself*—realizing the difficulty may be in your own frame, not in the thing you are judging.

The contribution of the system is not that these moves are novel; it is that they are *named, distinguished, and made visible.* In ordinary discussion they blur together, and a reader cannot tell whether an objection is an alternative (NON-NORMATIVE), a refutation (CRITICAL), or a step back to question the premises (METACOGNITIVE). The owls hold those apart so the reasoning stays legible across disagreement, transformation, and self-examination.

---

## Limitations and Scope Boundaries

The v3 release is explicit about what the system does *not* claim, so the algebra is not over-read.

- **The four states are deliberately coarse.** They mark *which kind* of epistemic move you are looking at—standard, exploration, inversion, self-audit—not the degree, confidence, or correctness of it. Many real evaluations carry finer gradations (partial agreement, mixed evidence, staged revision) that the four states intentionally compress. The coarseness is the source of the system's parsimony and verifiability, but it means the notation classifies stance; it never substitutes for the underlying argument.
- **No empirical validation yet.** The algebraic claims—closure, involution, commutativity—are proven. The *epistemic* claim, that these four states usefully and reliably partition how practitioners evaluate real claims, has not been tested. There is no inter-rater reliability study and no corpus annotation showing that independent readers assign the same state to the same artifact. Until such studies exist, the epistemic utility is a design hypothesis supported by analogy to mature practice (peer review, CVE severity, methodology audit), not a validated result.
- **Cultural specificity.** The owl iconography, the color palette, and the orientation conventions are situated choices. Owls do not carry uniform connotations across cultures; crimson-as-adversarial and gold-as-authoritative are not universal; left/right reading assumptions reflect particular conventions. The mapping from badge to state depends on a learned key—which is exactly why the literal label, never the color or orientation alone, is the carrier of record.

---

## Use Boundaries and Ethics

Because the semaphore marks *how something is being evaluated*, it can be misused as an instrument of authority. Three boundaries keep it honest:

- **The states are epistemic-stance labels, not authority labels.** A NORMATIVE owl means "operationally validated within a stated domain," not "approved by management." A CRITICAL owl means "subjected to adversarial analysis," not "condemned." Reading the badges as a chain of command inverts their purpose: the system encodes *position*, not rank—and never truth.
- **NON-NORMATIVE and CRITICAL must not be used to suppress dissent.** The reason NON-NORMATIVE exists as a distinct, legitimate state is to protect structured exploration that disagrees with the baseline. Tagging a dissenting analysis NON-NORMATIVE or CRITICAL in order to dismiss it—rather than to describe the evaluative move actually performed—is a misuse of the notation. The mark describes the analysis; it does not license ignoring it.
- **Whoever classifies is accountable for the classification.** Applying an owl is itself an evaluative act, and it can be wrong. The honest use makes the classifier's reasoning *more* visible and arguable—which state, on what evidence, within what domain—not less. A reader is always entitled to contest the badge, and the triple-redundant label exists partly so the claim being made is explicit enough to contest.

---

## Where It Came From: the DNS Tool

The Owl Semaphore was not invented to decorate pages. It grew inside the [DNS Tool](https://dnstool.it-help.tech/owl-semaphore)—a long-running research and operations effort that needed a compact, unambiguous way to mark how each finding had been evaluated: which results were the validated standard, which were advisory, which had been tested to the point of inversion, and where the analysis had to turn back on its own method. The semaphore is the notation that fell out of that need, and it has since been written up as a standalone, versioned, citable system.

---

## Download, Cite, and License

The Owl Semaphore is published openly under **CC BY 4.0** [^ccby]. The canonical specification, the full operator definitions, the accessibility conformance notes, and the owl assets live in the GitHub repository [^repo]; the archival record is on Zenodo.

- **Cite this version (v3.0.0):** DOI [10.5281/zenodo.20468727](https://doi.org/10.5281/zenodo.20468727)
- **Cite all versions (concept DOI, resolves to latest):** DOI [10.5281/zenodo.19473697](https://doi.org/10.5281/zenodo.19473697)
- **Author ORCID:** [0009-0000-5237-9065](https://orcid.org/0009-0000-5237-9065)
- **Source & assets:** [github.com/IT-Help-San-Diego/owl-semaphore](https://github.com/IT-Help-San-Diego/owl-semaphore)

BibTeX for the versioned release:

```bibtex
@misc{balboa_owl_semaphore_2026,
  author       = {Balboa, Carey},
  title        = {The Owl Semaphore: A Four-State Visual Epistemic Notation},
  year         = {2026},
  version      = {3.0.0},
  doi          = {10.5281/zenodo.20468727},
  howpublished = {Zenodo},
  note         = {Concept DOI 10.5281/zenodo.19473697 (all versions)},
  url          = {https://doi.org/10.5281/zenodo.20468727},
  license      = {CC BY 4.0}
}
```

If you want this kind of disciplined, citable rigor applied to your own DNS, email, and security posture—rather than asserted—[our team does that work end to end](/services/).

---

## References

[^repo]: IT Help San Diego. (2026). *Owl Semaphore* (v3.0.0) [Source code and specification]. GitHub. <https://github.com/IT-Help-San-Diego/owl-semaphore>

[^rfc2119]: Bradner, S. (1997). *Key words for use in RFCs to Indicate Requirement Levels* (RFC 2119). Internet Engineering Task Force. <https://www.rfc-editor.org/rfc/rfc2119>

[^klein]: Wikipedia. (n.d.). *Klein four-group*. Retrieved June 20, 2026, from <https://en.wikipedia.org/wiki/Klein_four-group>

[^wcag141]: W3C. (2023). *Understanding Success Criterion 1.4.1: Use of Color* (WCAG 2.2). <https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html>

[^ccby]: Creative Commons. (n.d.). *Attribution 4.0 International (CC BY 4.0)*. Retrieved June 20, 2026, from <https://creativecommons.org/licenses/by/4.0/>

---

*The Owl Semaphore is a notation for marking how a claim has been evaluated; it encodes position, not truth. This Field Note reflects v3.0.0 of the system as of June 2026. The algebraic properties are proven; the broader epistemic utility is a design hypothesis, stated here with its limits intact.*
