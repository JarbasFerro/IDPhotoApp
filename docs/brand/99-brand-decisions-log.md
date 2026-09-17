# Calipic — Brand decisions log

This file records accepted, rejected, and deferred brand decisions. It exists to prevent future redesigns, implementation work, or marketing assets from silently reopening settled questions.

## Status key

- **Accepted** — current source of truth.
- **Working** — direction used provisionally while discovery continues.
- **Deferred** — intentionally unresolved until a later milestone.
- **Rejected** — explored and explicitly not selected.
- **Superseded** — previously accepted but replaced by a newer decision.

---

## BD-001 — Consumer-facing product name

**Status:** Accepted  
**Decision:** The working consumer-facing product/brand name is **Calipic**.  
**Scope:** Brand and product documentation.  
**Implementation note:** Repository name, bundle identifiers, targets, and spike project names are not automatically renamed by this decision. Technical renaming requires a separate implementation change.

## BD-002 — Platform relationship

**Status:** Accepted through existing product architecture  
**Decision:** Calipic is an iPhone/iOS-first brand and product. Native Apple interaction patterns take precedence over a heavily custom visual shell.  
**Consequence:** Brand distinctiveness should primarily come from composition, photography, semantics, copy, selective accent, icon/app-icon work, motion, and carefully chosen custom assets rather than replacing standard iOS behavior.

## BD-003 — Product typography baseline

**Status:** Accepted through existing product architecture  
**Decision:** System typography and Dynamic Type are the default for in-product UI.  
**Open question:** Marketing/brand typography outside the app may use a separate supporting typeface if there is a strong identity reason and licensing/distribution remain appropriate.

## BD-004 — System iconography baseline

**Status:** Accepted through existing product architecture  
**Decision:** SF Symbols are the default for standard product actions and status concepts.  
**Open question:** A small custom symbol vocabulary may be created only for genuinely Calipic-specific concepts not well represented by SF Symbols.

## BD-005 — Liquid Glass / material posture

**Status:** Accepted through existing product architecture  
**Decision:** Calipic inherits current system materials/Liquid Glass through correct use of native controls. It will not create an app-wide imitation glass theme.

## BD-006 — Photo primacy

**Status:** Accepted through existing product architecture  
**Decision:** The user's portrait is primary content. Brand chrome, controls, and decorative devices should recede when they compete with the photo.

## BD-007 — Identity manipulation

**Status:** Accepted through existing product architecture  
**Decision:** Official-photo workflows do not cosmetically alter identity-bearing facial features, hairstyle, clothing, or other identity characteristics. Image intelligence may assist with compliant crop, background, quality analysis, and guidance within documented boundaries.

## BD-008 — Trust language

**Status:** Accepted through existing product architecture  
**Decision:** Calipic must not guarantee government acceptance or imply government affiliation/certification. Uncertainty and manual checks remain visible.

## BD-009 — Advertising posture

**Status:** Accepted through existing product architecture  
**Decision:** No intrusive advertising or conversion pressure inside the critical photo correction workflow; the preferred product direction remains no third-party advertising SDK.

## BD-010 — Core brand personality

**Status:** Working  
**Current hypothesis:** **Precise, calm, trustworthy, human, photographic.**  
**Reason:** This is strongly consistent with the existing product definition and UX principles, but should be confirmed/refined through discovery Q16–Q20.

## BD-011 — Emotional territory

**Status:** Working  
**Current hypothesis:** **Confidence without anxiety.**  
**Reason:** Calipic's deeper problem is uncertainty around a constrained official-photo task. The intended emotional outcome should be relief and control without false reassurance.

## BD-012 — Premium posture

**Status:** Working  
**Current hypothesis:** **Quietly premium through craft and restraint**, not luxury-coded and not visibly “premium” through ornamental styling.  
**Dependency:** Discovery Q09, Q18, Q46.

## BD-013 — Technology posture

**Status:** Working  
**Current hypothesis:** Technology should be felt through useful behavior rather than marketed as “AI-powered.” Vision/AI terminology is secondary to plain-language user outcomes.  
**Dependency:** Discovery Q38.

## BD-014 — Privacy posture

**Status:** Working  
**Current hypothesis:** Privacy is a concrete trust proof point, communicated with plain facts such as on-device processing, rather than fear-based messaging.  
**Dependency:** Discovery Q10.

## BD-015 — Visual identity, palette, logo and app icon

**Status:** Deferred  
**Decision:** No palette, logo architecture, graphic motif, app-icon direction, custom brand typeface, or gradient policy is approved yet. These must follow strategic discovery rather than precede it.

## BD-016 — Product descriptor / App Store naming

**Status:** Deferred  
**Decision required:** Whether consumer presentation is simply `Calipic` or uses a descriptor such as `Calipic — ID Photos`.

## BD-017 — Monetization expression

**Status:** Deferred  
**Decision required:** Monetization model and how prominently “no ads” becomes part of the public brand promise.

---

## Change discipline

When a brand decision is finalized:

1. add or update the relevant `BD-xxx` entry here;
2. update any affected foundation/specification document;
3. if the decision affects architecture or production behavior, update the appropriate product ADR/decision document too;
4. do not rely on a mockup, chat message, or marketing asset as the only record of a foundational decision.