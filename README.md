# Calipic — ID photos at home

**Goal:** the #1 iPhone app for taking document photos at home and printing them yourself. It should be the easiest to use, give a studio-quality result thanks to its guidance and on-device image processing, print at the exact size the first time, and feel beautiful and satisfying to finish.

> **Project status (2026-11-11):** late **M1**. The spike app [`Spikes/IDPhotoSpike`](Spikes/IDPhotoSpike/README.md) (0.12.7) runs the complete Spain DNI flow on an iPhone: guided camera with review, import, automatic framing, white background, Document Tone, Photo Check, Adjust, digital JPEG, multi-person print sheets with AirPrint, and English, Spanish, and Portuguese (Brazil). The production project (M2) has not started. The remaining physical evidence and the path to 1.0 are in [the launch roadmap](docs/23-launch-roadmap.md).

## Start here

| Read | For |
|---|---|
| [20 — Product blueprint](docs/20-product-blueprint.md) | Every function and screen at launch, success targets, open decisions |
| [21 — User journeys](docs/21-user-journeys.md) | Personas and step-by-step journeys, from setup to a cut print |
| [22 — Quality and delight bar](docs/22-quality-and-delight-bar.md) | What "great photo", "beautiful", and "wow" mean, and how they are tested |
| [23 — Launch roadmap](docs/23-launch-roadmap.md) | Phases P0–P9 from the spike to App Store 1.0 |
| [16 — Screen experience spec](docs/16-screen-experience-spec.md) | Current screen contract |
| [10 — Decisions](docs/10-decisions.md) | ADRs, including the founder decisions below |

External reviews of 2026-11-11, kept as records: [ChatGPT](docs/20-product-outcome-and-launch-review-ChatGPT.md) and [Gemini](docs/20-product-outcome-and-launch-review-Gemini.md). What was adopted from each is in [the blueprint §10](docs/20-product-blueprint.md).

**Founder decisions (2026-11-11):**

- **Worldwide launch:** the most-used photo documents of the most relevant App Store countries, in tiers (ADR-047).
- **Pricing:** first photo free, then USD 0.99 per photo, with free editing until an explicit point of no return (ADR-048).
- **Drafts:** saved free of charge; a locked draft can never leave the app (ADR-049).
- **Accessibility:** a native baseline for 1.0 (ADR-050).
- **Children:** use the same flow as adults (ADR-017).
- **Measurement:** success is measured with known beta testers (ADR-020).

## Run the spike app

Open [`Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj`](Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj) in Xcode 27 and run the `IDPhotoSpike` scheme on an iPhone or simulator. See [setup and tests](Spikes/IDPhotoSpike/README.md) and the [spike reports](docs/spikes/).

## Product ambition

This project is now deliberately iOS-only.

The quality bar is not “a good cross-platform utility.” The target is an app that feels as if it were designed by an experienced Apple platform team: native interaction patterns, privacy-preserving on-device intelligence, careful motion and haptics, precise typography, fast camera behavior, deterministic output, and deep integration with the capabilities of iPhone.

The reference question for every feature is:

> **Would this feel credible as an Apple Design Award / WWDC-quality example of how to build an iPhone app?**

That does **not** mean adding every new Apple API. Apple-quality design prioritizes purpose, agency, responsibility, familiarity, flexibility, simplicity, craft, and delight. New platform capabilities should be used only when they make the core task better.

## Current Apple platform baseline

Development baseline as of September 2026:

- **Platform:** iOS / iPhone only.
- **UI:** SwiftUI-first.
- **Language:** Swift 6 language mode, using the Swift 6.4 compiler in Xcode 27.
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

The proposed screen-by-screen appearance, controls, copy, states, and accessibility behavior for the current spike are in [`docs/16-screen-experience-spec.md`](docs/16-screen-experience-spec.md).
The accepted flow decisions and implementation sequence for its next revision are in [`docs/17-screen-experience-implementation-plan.md`](docs/17-screen-experience-implementation-plan.md).

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

The product is useful without advertising interruptions. The first photo is free; each further photo costs one USD 0.99 credit, spent only after an explicit confirmation (ADR-048). Pricing never compromises the core workflow, privacy, or output quality.

## Guiding principles

- **Native by design:** prefer Apple frameworks and standard iOS interactions over custom abstractions when they meet the need.
- **Content first:** the portrait and compliance information are the content; chrome recedes around them.
- **Privacy first:** process photos on-device wherever technically practical.
- **Correctness over false confidence:** never claim an official photo is guaranteed to be accepted.
- **Rules are data:** country/document specifications are versioned, sourced, testable, and separated from image-processing code.
- **Non-destructive editing:** preserve the original image throughout the workflow.
- **Fast path first:** a good source photo should reach export in very few steps.
- **Explain failures:** every rejection or warning tells the user what to change.
- **Accessible baseline:** system controls, labelled buttons, status never by colour alone, and Reduce Motion for 1.0; full VoiceOver and Voice Control journeys after 1.0 (ADR-050).
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

## Repository map

```text
.
├── AGENTS.md                 # implementation contract for every contributor
├── Spikes/IDPhotoSpike/      # disposable feasibility app (current: 0.12.7)
├── scripts/                  # version bump, brand asset generation
└── docs/
    ├── 01–11                 # product, requirements, architecture, UX, rules, delivery, tests, privacy, backlog, decisions, iOS strategy
    ├── 12–19                 # kickoff, Spain research, feature plan, experience plans and research (12, 15, 17–19 are historical)
    ├── 20–23                 # blueprint, journeys, quality bar, launch roadmap (current)
    ├── brand/                # Calipic brand system and decisions log
    ├── spikes/               # spike evidence reports
    └── ui/                   # screen states and evidence
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
- English, Spanish, and Portuguese (Brazil) through String Catalogs; more languages for a worldwide launch are decision D-7;
- the 1.0 accessibility baseline (ADR-050);
- first photo free, then per-photo credits through StoreKit, with drafts and a locked export gate (ADR-048, ADR-049);
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

For the local environment findings, first implementation batches, and open kickoff decisions, see [`docs/12-implementation-kickoff.md`](docs/12-implementation-kickoff.md). The research-backed plan for print sheets, alignment, background replacement, tonal adjustment, and iOS 26/27 adoption is in [`docs/14-priority-feature-plan.md`](docs/14-priority-feature-plan.md).

## Definition of done

A feature is not done when it renders in one simulator. It is done when:

- acceptance criteria are met;
- the interaction follows current HIG guidance or documents why it intentionally differs;
- native controls/system behavior were preferred unless custom UI has a clear reason;
- error, empty, permission, loading, interruption, and cancellation states are covered;
- privacy/data flow is reviewed;
- unit/integration/UI tests exist at the appropriate level;
- the accessibility baseline (ADR-050) holds;
- localization does not break the layout;
- light/dark appearance and increased-contrast behavior are verified;
- relevant documentation is updated;
- performance is profiled on a physical iPhone, not inferred from Simulator;
- no known P0/P1 defect remains.

## Immediate next action

Follow [the launch roadmap §4](docs/23-launch-roadmap.md): fix the Tier 1 country list from market data, run the physical evidence round on device and printers, and start profile research. The production Xcode project is created only after the M1 evidence is complete.
