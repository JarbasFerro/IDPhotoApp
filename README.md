# ID Photo App

A privacy-first **native iOS application** for creating standards-compliant identity photos for passports, visas, ID cards, driving licences, residence permits, CVs, and other official or professional uses.

> Project status: **planning / pre-implementation**. The repository is intentionally specification-first. Production code begins only after the native iOS technical spikes establish image quality, performance, accessibility, and export fidelity.

## Product ambition

This project is now deliberately iOS-only.

The quality bar is not “a good cross-platform utility.” The target is an app that feels as if it were designed by an experienced Apple platform team: native interaction patterns, excellent accessibility, privacy-preserving on-device intelligence, careful motion and haptics, precise typography, fast camera behavior, deterministic output, and deep integration with the capabilities of iPhone.

The reference question for every feature is:

> **Would this feel credible as an Apple Design Award / WWDC-quality example of how to build an iPhone app?**

That does **not** mean adding every new Apple API. Apple-quality design prioritizes purpose, agency, responsibility, familiarity, flexibility, simplicity, craft, and delight. New platform capabilities should be used only when they make the core task better.

## Current Apple platform baseline

Development baseline as of September 2026:

- **Platform:** iOS / iPhone only.
- **UI:** SwiftUI-first.
- **Language:** Swift 6 language mode, using the Swift 6.4 compiler available with Xcode 27 beta during pre-release development.
- **SDK:** iOS 27 SDK / Xcode 27 during development; ship using a non-beta Xcode release accepted by App Store Connect.
- **Minimum deployment target:** proposed iOS 26.0, with iOS 27 enhancements adopted through availability-gated APIs until the final deployment decision is validated.
- **Design system:** Apple Human Interface Guidelines, native controls, refreshed Liquid Glass behavior, SF Symbols, Dynamic Type, semantic materials, and system navigation/toolbars.
- **Image intelligence:** Vision first; Foundation Models/Core AI only where they add meaningful capability without becoming the source of truth for compliance.
- **Rendering:** Core Image + ImageIO/Core Graphics, with Metal-backed execution where appropriate.
- **Camera:** AVFoundation for a purpose-built capture experience; PhotosUI `PhotosPicker` for imports.
- **Persistence:** minimal local persistence; SwiftData only when a real persistence requirement exists.
- **System integration:** App Intents / Siri / Shortcuts / Spotlight where the task naturally benefits.
- **Testing:** Swift Testing for new unit/integration tests, XCUITest for UI flows, fixture-based image verification, Accessibility Inspector/audits, Instruments, and physical print measurement.
- **Backend:** none required for the core workflow.

The detailed rationale and platform capability map are in [`docs/11-ios-excellence-strategy.md`](docs/11-ios-excellence-strategy.md).

## Product intent

The app should make the complete ID-photo workflow fast and understandable:

1. Choose the destination country and document/use case.
2. Take a new photo or choose one with the system photo picker.
3. Check whether the source photo is usable.
4. Remove or normalize the background when allowed.
5. Align the face, crop, resize, and compose the photo according to the selected specification.
6. Show clear warnings for requirements the app can and cannot validate automatically.
7. Let the user make manual corrections without losing the original.
8. Export a digital file and/or a print-ready sheet using native share, save, and print experiences.

The product should be useful without advertising interruptions. Monetization, if introduced, must not compromise the core workflow, user privacy, or exported-photo quality.

## Guiding principles

- **Native by design:** prefer Apple frameworks and standard iOS interactions over custom abstractions when they meet the need.
- **Content first:** the portrait and compliance information are the content; chrome recedes around them.
- **Privacy first:** process photos on-device wherever technically practical.
- **Correctness over false confidence:** never claim an official photo is guaranteed to be accepted.
- **Rules are data:** country/document specifications are versioned, sourced, testable, and separated from image-processing code.
- **Non-destructive editing:** preserve the original image throughout the workflow.
- **Fast path first:** a good source photo should reach export in very few steps.
- **Explain failures:** every rejection or warning tells the user what to change.
- **Accessible by default:** VoiceOver, Voice Control, Dynamic Type, Reduce Motion, Differentiate Without Color, sufficient contrast, large targets, and non-gesture alternatives are part of the feature definition.
- **International by design:** no architecture decision assumes one country, one document type, one language, or one unit system.
- **Intelligence with boundaries:** generative AI may explain or assist, but deterministic rules and measurable computer-vision results remain authoritative for official output.
- **No novelty tax:** do not add widgets, Live Activities, AI, custom glass, or animation merely because an API exists.

## iOS experience goals

The application should exploit iPhone capabilities where they improve the task:

- edge-to-edge camera and photo editing;
- fast, responsive AVFoundation capture with live guidance;
- Vision face detection and subject segmentation on-device;
- iOS 27 image-understanding/tap-to-segment capabilities for mask refinement where useful;
- native Liquid Glass behavior from standard SwiftUI controls and navigation;
- subtle `sensoryFeedback` rather than decorative haptics;
- `PhotosPicker` instead of demanding full photo-library access;
- `ShareLink`/`Transferable` and native print/share sheets;
- App Intents so a user can start common actions from Siri, Shortcuts, Spotlight, or the Action button where appropriate;
- Spotlight indexing for document profiles, not sensitive user photos;
- Icon Composer and SF Symbols for a platform-native visual identity;
- String Catalogs for localization;
- on-device processing and explicit privacy manifests.

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
    ├── 10-decisions.md
    └── 11-ios-excellence-strategy.md
```

## MVP definition

The MVP is not “an editor that can make a 35 × 45 mm image.” It is a complete, trustworthy iPhone workflow covering a deliberately limited set of document specifications.

MVP must include:

- native iPhone app;
- country + document/use-case selection;
- AVFoundation camera capture and PhotosPicker import;
- basic automatic source-photo quality checks;
- Vision-based face detection and alignment assistance;
- background segmentation/removal with a manual correction path;
- rule-driven crop and output dimensions;
- digital export;
- print-sheet generation for common paper sizes;
- a clear distinction between automatic checks, warnings, and requirements that require human judgement;
- source/provenance metadata for every published document rule;
- English plus String Catalog/localization architecture ready for additional languages;
- complete VoiceOver and Dynamic Type support for the core flow;
- no account requirement for the core workflow;
- no cloud upload required for the core workflow;
- no third-party analytics/ads SDK unless separately justified;
- automated unit, integration, UI, accessibility, and golden-image tests for critical transformations.

## Out of scope for the first MVP

- Android, web, Windows, macOS, or cross-platform frameworks.
- Guaranteed government acceptance.
- A universal biometric-compliance certification claim.
- Photo printing/fulfilment logistics.
- Social/community features.
- Mandatory user accounts.
- Cloud photo storage.
- Generative alteration of facial identity, hairstyle, clothing, or other identity-bearing features.
- Broad AI retouching/beautification.
- Platform integrations that do not improve the ID-photo workflow.

## Development sequence

**M0 — Product/platform definition → M1 — native iOS technical spikes → M2 — SwiftUI foundation → M3 — image/camera pipeline → M4 — rules engine → M5 — Apple-quality product UX → M6 — export/print → M7 — accessibility/performance/privacy hardening → M8 — App Store release.**

Detailed entry/exit criteria are in [`docs/06-delivery-plan.md`](docs/06-delivery-plan.md).

## Definition of done

A feature is not done when it renders in one simulator. It is done when:

- acceptance criteria are met;
- the interaction follows current HIG guidance or documents why it intentionally differs;
- native controls/system behavior were preferred unless custom UI has a clear reason;
- error, empty, permission, loading, interruption, and cancellation states are covered;
- privacy/data flow is reviewed;
- unit/integration/UI tests exist at the appropriate level;
- VoiceOver, Voice Control, Dynamic Type, Reduce Motion, and contrast behavior have been checked as applicable;
- localization does not break the layout;
- light/dark appearance and increased-contrast behavior are verified;
- relevant documentation is updated;
- performance is profiled on a physical iPhone, not inferred from Simulator;
- no known P0/P1 defect remains.

## Immediate next action

Execute the revised **M1 native-iOS spike program** before final production UI work. The first code should validate:

1. responsive AVFoundation capture and PhotosPicker import;
2. Vision face geometry;
3. Vision segmentation and iOS 27 refinement APIs;
4. Core Image high-resolution composition without unnecessary copies;
5. exact digital/PDF export geometry;
6. SwiftUI editor gestures plus VoiceOver/Voice Control alternatives;
7. performance, memory, thermal behavior, and cancellation;
8. the minimum deployment target and availability strategy.

Only after these results should the production Xcode project structure be frozen.