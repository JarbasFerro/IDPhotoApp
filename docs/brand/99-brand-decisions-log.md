# Calipic — Brand decisions log

This file records accepted, rejected, working, and deferred brand decisions. It exists to prevent future redesigns, implementation work, or marketing assets from silently reopening settled questions.

## Status key

- **Accepted** — current source of truth.
- **Working** — direction used provisionally while research continues.
- **Deferred** — intentionally unresolved until a later milestone.
- **Rejected** — explored and explicitly not selected.
- **Superseded** — previously accepted but replaced by a newer decision.

---

## BD-001 — Consumer-facing product name

**Status:** Accepted  
**Decision:** The consumer-facing product/brand name is **Calipic**.  
**Implementation note:** Repository name, bundle identifiers, targets, and spike project names are not automatically renamed by this decision.

## BD-002 — Platform relationship

**Status:** Accepted  
**Decision:** Calipic is iPhone/iOS-first. Native iOS familiarity takes priority over custom interaction patterns or a heavily themed visual shell.

## BD-003 — Product typography baseline

**Status:** Accepted  
**Decision:** System typography and Dynamic Type are the default for in-product UI. Marketing typography may be explored separately only if it adds real identity value.

## BD-004 — Product iconography baseline

**Status:** Accepted  
**Decision:** SF Symbols remain the default for standard actions and system concepts. Custom iconography is reserved for genuinely Calipic-specific concepts and brand assets.

## BD-005 — Liquid Glass / materials

**Status:** Accepted  
**Decision:** Calipic inherits current system materials through correct use of native controls. No app-wide imitation glass theme.

## BD-006 — Photo primacy

**Status:** Accepted  
**Decision:** The user's portrait is the primary visual content. Brand/UI chrome recedes around it.

## BD-007 — Identity manipulation

**Status:** Accepted  
**Decision:** Official-photo workflows do not cosmetically alter identity-bearing features. Image intelligence can assist with crop, background, quality analysis, and guidance within documented limits.

## BD-008 — Trust language

**Status:** Accepted  
**Decision:** Calipic must not guarantee government acceptance or imply government affiliation/certification. Manual checks and uncertainty remain visible.

## BD-009 — Advertising posture

**Status:** Accepted  
**Decision:** No intrusive advertising in the product workflow. The intended commercial architecture does not rely on third-party advertising SDKs.

## BD-010 — Brand personality

**Status:** Accepted  
**Decision:** **Elegant, friendly, photographic, practical, sophisticated.**  
**Anti-traits:** complicated, AI-branded, generic, childish, cheap.

## BD-011 — Emotional outcome

**Status:** Accepted  
**Decision:** The primary emotional outcome is **satisfaction** created by an unusually easy, complete real-world workflow.

## BD-012 — Premium posture

**Status:** Accepted  
**Decision:** Calipic is **quietly premium through quality and restraint**, not visibly luxury-coded.

## BD-013 — Technology posture

**Status:** Accepted  
**Decision:** AI/computer-vision technology should disappear behind useful behavior. Calipic is not marketed as an AI product.

## BD-014 — Privacy posture

**Status:** Accepted  
**Decision:** Privacy/on-device processing is a primary public brand promise, communicated through concrete behavior rather than abstract security imagery.

## BD-015 — Core brand proposition

**Status:** Accepted  
**Decision:** Calipic should be known primarily for **being the easiest/intuitive way to create an ID photo and turn it into a correct physical print**.

## BD-016 — Primary audience lens

**Status:** Accepted  
**Decision:** Brand communication should be especially understandable to **people avoiding the expense/inconvenience of photo shops** and **parents creating photos for children/family**, while remaining broadly useful for official-document users.

## BD-017 — Competitive reasons to pay

**Status:** Accepted  
**Decision:** Calipic must visibly outperform free alternatives by being **simpler, easier/more intuitive, and more beautiful**.

## BD-018 — Visual expressiveness

**Status:** Accepted  
**Decision:** Product UI outside the portrait should be **extremely minimal**. Distinctiveness must come from a very small number of strong details rather than density or decoration.

## BD-019 — Appearance

**Status:** Accepted  
**Decision:** Calipic is equally native to Light and Dark Mode. Neither is the master visual identity.

## BD-020 — Visual motif boundaries

**Status:** Accepted  
**Promising:** crop corners, framing, subtle calibration/alignment, photo-paper ratios, optical geometry, restrained measurement/ruler cues.  
**Rejected:** registration-mark aesthetics and calipers as a brand motif.

## BD-021 — Logo architecture

**Status:** Accepted  
**Decision:** Build toward a **powerful standalone symbol**, with the Calipic wordmark secondary.

## BD-022 — App-icon communication

**Status:** Accepted  
**Decision:** Category recognition wins over abstraction. The app icon should immediately suggest **ID photo**.

## BD-023 — Leading symbol territory

**Status:** Working  
**Direction:** Explore a **face/portrait silhouette integrated with crop corners** as the leading symbol territory.  
**Constraint:** Avoid resemblance to Face ID, surveillance/facial recognition, Contacts, or generic camera-app clip art.

## BD-024 — Name semantics

**Status:** Accepted  
**Decision:** The `Cali-` association with calibration/precision is useful for brand meaning, but it must not produce a caliper-tool identity.

## BD-025 — Product voice

**Status:** Accepted  
**Decision:** Voice is **calm and concise**. A human `we` voice is permitted. Direct instructions such as “Move a little farther away” are preferred over tentative wording. Core official-photo workflows do not use humor.

## BD-026 — Marketing language strength

**Status:** Accepted  
**Decision:** Marketing may use stronger outcome language such as “Passport photos made right,” while in-product compliance claims remain precise and non-guaranteeing.

## BD-027 — Feature naming

**Status:** Accepted  
**Decision:** Feature names remain descriptive (`Photo Check`, `Background`, `Print Sheet`, etc.), not branded sub-products.

## BD-028 — Consumer descriptor

**Status:** Accepted  
**Decision:** Consumer-facing naming direction is **Calipic — ID Photos**, subject to App Store metadata/search constraints.

## BD-029 — Monetization model

**Status:** Accepted as product direction  
**Decision:** Credit model: tutorial/onboarding result free, an initial free credit, then inexpensive purchased credits. No subscription is required in the intended baseline model.  
**Implementation dependency:** StoreKit product design, credit accounting, restoration rules, pricing, and legal/App Store review require separate product decisions.

## BD-030 — “No ads” messaging

**Status:** Working  
**Decision:** “No ads” is strategically positive but should be a supporting proof point rather than the core proposition. If the no-subscription model remains true, `No ads. No subscription.` is a promising concise expression.

## BD-031 — Launch languages

**Status:** Accepted  
**Decision:** Initial language target is **English, Spanish, Portuguese (Brazil)**.

## BD-032 — Launch-market priority

**Status:** Research in progress  
**Decision:** Market sequence will be evidence-led rather than based on founder location. Current evidence makes the United States the leading candidate, but the sequence is not yet locked.

## BD-033 — Color

**Status:** Research in progress  
**Decision:** No brand color is approved. Color selection must account for empirical perception research, cultural variation, portrait interaction, competitor differentiation, Light/Dark Mode, accessibility, and semantic status colors.

## BD-034 — Design-conflict hierarchy

**Status:** Accepted  
**Decision:** When otherwise-good design goals conflict, prioritize: **1) native iOS familiarity, 2) beauty, 3) accessibility**. Product correctness/privacy remain non-negotiable constraints rather than ranked preferences.

## BD-035 — Brand references

**Status:** Accepted as inspiration, not imitation  
**Decision:** Apple and Teenage Engineering are useful references for restraint, detail, ownability, and functional beauty. Calipic must not visually copy either brand.

---

## Change discipline

When a brand decision is finalized:

1. add or update the relevant `BD-xxx` entry here;
2. update affected foundation/specification documents;
3. if the decision affects architecture or production behavior, update the appropriate product ADR/decision document too;
4. do not rely on a mockup, chat message, or marketing asset as the only record of a foundational decision.
