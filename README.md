# ID Photo App

A privacy-first mobile application for creating standards-compliant identity photos for passports, visas, ID cards, driving licences, residence permits, CVs, and other official or professional uses.

> Project status: **planning / pre-implementation**. The repository is intentionally initialized with specifications and decision records before production code is added.

## Product intent

The app should make the complete ID-photo workflow fast and understandable:

1. Choose the destination country and document/use case.
2. Take a new photo or import an existing one.
3. Check whether the source photo is usable.
4. Remove or normalize the background when allowed.
5. Align the face, crop, resize, and compose the photo according to the selected specification.
6. Show clear warnings for requirements the app can and cannot validate automatically.
7. Let the user make manual corrections without losing the original.
8. Export a digital file and/or a print-ready sheet.

The product should be useful without advertising interruptions. Monetization, if introduced, must not compromise the core workflow, user privacy, or exported-photo quality.

## Guiding principles

- **Privacy first:** process photos on-device wherever technically practical.
- **Correctness over false confidence:** never claim an official photo is guaranteed to be accepted.
- **Rules are data:** country/document specifications must be versioned, sourced, testable, and updatable without rewriting the image pipeline.
- **Non-destructive editing:** preserve the original image throughout the workflow.
- **Fast path first:** a good source photo should reach export in very few steps.
- **Explain failures:** every rejection or warning should tell the user what to change.
- **Accessible by default:** support scalable text, screen readers, strong contrast, large touch targets, and non-color-only status cues.
- **International by design:** no architecture decision should assume one country, one document type, one language, or one unit system.

## Proposed technical baseline

The current recommendation is a **Flutter/Dart** application targeting iOS and Android from one codebase, with native platform bridges only where they provide a clear quality or performance advantage. This is a proposal, not yet a locked architecture decision; Milestone M1 includes a technical spike before the stack is frozen.

Expected characteristics:

- On-device image processing by default.
- Modular image-processing pipeline.
- Versioned local rule catalog for country/document requirements.
- Deterministic crop/output engine separated from UI code.
- Platform-native camera/photo-library integration.
- Automated visual regression tests using a controlled, consented test-image corpus.
- Minimal backend for MVP; a backend should exist only when a concrete requirement justifies it.

## Initial repository map

```text
.
├── README.md
├── .gitignore
└── docs/
    ├── 01-product-definition.md
    ├── 02-requirements.md
    ├── 03-architecture.md
    ├── 04-ux-ui.md
    ├── 05-rules-engine.md
    ├── 06-delivery-plan.md
    ├── 07-test-strategy.md
    ├── 08-privacy-security.md
    ├── 09-backlog.md
    └── 10-decisions.md
```

## MVP definition

The MVP is not “an editor that can make a 35 × 45 mm image.” It is a complete, trustworthy workflow covering a deliberately limited set of document specifications.

MVP must include:

- iOS and Android builds.
- Country + document/use-case selection.
- Camera capture and photo import.
- Basic automatic source-photo quality checks.
- Face detection and alignment assistance.
- Background removal/replacement with a manual correction path.
- Rule-driven crop and output dimensions.
- Digital export.
- Print-sheet generation for common paper sizes.
- A clear distinction between automatic checks, warnings, and requirements that require human judgement.
- Source/provenance metadata for every published document rule.
- English plus an internationalization architecture ready for additional languages.
- No account requirement for the core workflow.
- No cloud upload required for the core workflow.
- Automated unit, integration, and golden-image tests for critical transformations.

## Out of scope for the first MVP

- Guaranteed government acceptance.
- A universal biometric-compliance certification claim.
- Photo printing/fulfilment logistics.
- Social/community features.
- Mandatory user accounts.
- Cloud photo storage.
- Generative alteration of facial identity, hairstyle, clothing, or other identity-bearing features.
- Broad AI retouching/beautification.

## Development sequence

The high-level order is:

**M0 — Product definition → M1 — technical spikes → M2 — foundation → M3 — image pipeline → M4 — rules engine → M5 — end-to-end UX → M6 — export/print → M7 — hardening/compliance → M8 — store release.**

Detailed entry/exit criteria are in [`docs/06-delivery-plan.md`](docs/06-delivery-plan.md).

## Definition of done

A feature is not done when it renders on one simulator. It is done when:

- acceptance criteria are met;
- error and empty states are covered;
- analytics/privacy implications have been reviewed;
- unit/integration/UI tests exist at the appropriate level;
- accessibility is checked;
- localization does not break the layout;
- relevant documentation is updated;
- it works on the supported physical-device matrix;
- no known P0/P1 defects remain.

## Planning documents

Start with:

- [`01-product-definition.md`](docs/01-product-definition.md) — product scope and success criteria.
- [`02-requirements.md`](docs/02-requirements.md) — detailed functional and non-functional requirements.
- [`03-architecture.md`](docs/03-architecture.md) — proposed technical design.
- [`05-rules-engine.md`](docs/05-rules-engine.md) — how official photo specifications become safe, versioned product data.
- [`06-delivery-plan.md`](docs/06-delivery-plan.md) — execution plan and milestone gates.
- [`09-backlog.md`](docs/09-backlog.md) — ordered implementation backlog.
- [`10-decisions.md`](docs/10-decisions.md) — architectural/product decisions that must be locked deliberately.

## Immediate next action

Execute **M0 and M1 only** before building the production UI. The first code should be technical-spike code used to validate face detection, segmentation quality, deterministic crop geometry, performance, and export fidelity on representative iOS and Android devices.
