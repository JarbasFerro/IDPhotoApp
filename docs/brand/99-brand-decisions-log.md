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

## BD-036 — Provisional icon construction

**Status:** Working  
**Decision:** Carry forward the current icon direction without another broad symbol exploration: an elegant portrait/bust silhouette with a bun and one curved loose hair strand, enclosed by a rounded crop-frame system whose small gaps occur around the frame while the right-side opening is substantially wider, making the frame read as a capital `C`.  
**Geometry constraints:** uniform stroke width; identical rounded endpoints; exact top/bottom mirror symmetry; equal small top-center and bottom-center gaps; small left-center interruption; clearly larger right-side opening.  
**Assets:** `docs/brand/assets/calipic-icon-draft-v0.svg` plus the identity handoff in `docs/brand/06-identity-exploration-handoff.md`.  
**Next action:** freeze symbol geometry provisionally and proceed to controlled color + real iOS context testing. Final vector geometry remains deferred.  
**Amendment — 2026-09-17 (founder note):** `calipic-icon-draft-v0.*` is **only a draft stand-in**. What is provisionally frozen is the symbol *territory* (portrait in a crop frame that reads as `C`), not the drawing. The form needs substantial refinement, and the final icon is expected to receive finishing touches — shadows, depth, texture — rather than remain a flat glyph. Consequences: (1) no asset, screen or marketing piece may treat v0 as the Calipic icon; (2) the current color/context tests use v0 flat because it is the only fixed geometry available, and their findings are provisional; (3) those tests must be re-run on the refined, finished icon before symbol or color is locked, which is why every render is required to be scripted (planned path `scripts/brand/`, see `docs/brand/prototypes/README.md`). **Reading the "Next action" above:** "freeze symbol geometry provisionally" means the tests hold v0 geometry fixed so that only color and context vary; it does not mean the drawing is finished. Form refinement and finishing proceed as a separate track inside the same territory, and are not a new broad symbol exploration. Status stays Working.

**Update 2026-09-17 (refinement candidate v1):** a first refinement inside this territory exists as `docs/brand/assets/calipic-icon-v1-master.svg` and `calipic-icon-v1-small.svg`, generated by `scripts/brand/build-icon-v1.py`, with finished studies (depth, shadow, grain) in the two finalist test colours. Evidence and open points: `docs/brand/prototypes/06-icon-refinement-v1.md`. It is a candidate for founder review; status stays Working and v0 remains the recorded reference until the founder accepts a form.

## BD-037 — Provisional color test palette (test values only)

**Status:** Working  
**Date:** 2026-09-17  
**Decision:** For the controlled color/context tests only, the following values are used. They exist so that every prototype document and script renders the same thing. **This is not a color decision.** BD-033 is unchanged: no brand color is approved.

| Test system | Light | Dark |
|---|---|---|
| A — deep blue | `#1F3FA8` | `#7C98F5` |
| B — dark cyan / blue-teal | `#0E6F7C` | `#4FC3D1` |
| C — graphite ink + cool accent | ink `#1C1F24`; accent `#5B7C99` | accent `#9DB7CF` |
| D — warm challenger (deep amber-ochre) | `#B26A00` | `#F0B55A` |

**Not yet defined:** a Dark Mode ink for system C, and Increase Contrast Light/Dark values for all four systems. The first prototype that needs them adds them to this table; they are not to be defined locally in a script or document.  
**Known risk — system D:** amber-ochre sits in the same hue family as the `warn` status color, which `03-color-strategy-research.md` §6 rates as a high identity-conflict risk, and `#B26A00` on white measures about 4.2:1 (below 4.5:1 for body text; `#5B7C99` is about 4.4:1). 03 §8 allows yellow/orange only as a challenger *if the first set lacks warmth or shelf recognition*; that condition has not been evaluated — D is included up front so the batch has one clearly differentiated alternative. D is in the batch to be tested against the status-independence rule, not because it is assumed to pass it.  
**Notes:** System D is the "one evidence-backed differentiated alternative" from the handoff, drawn from the conditional yellow/orange challenger line in 03 §8; purple/violet is not in the batch. The letters are test labels and do not match the candidate letters in 03 §8 (see the dated update there). Values may change between test rounds without a new BD entry, provided this table is kept current. Status colors (`pass`, `warn`, `fail`, `manual_check`) must remain independent of whichever system is chosen; a system that cannot meet this is rejected. Any winner still needs Increase Contrast variants, P3/sRGB evaluation and device testing (03 §5), and a re-run on the refined icon (BD-036 amendment), before BD-033 can change.

---

## Change discipline

When a brand decision is finalized:

1. add or update the relevant `BD-xxx` entry here;
2. update affected foundation/specification documents;
3. if the decision affects architecture or production behavior, update the appropriate product ADR/decision document too;
4. do not rely on a mockup, chat message, or marketing asset as the only record of a foundational decision.
