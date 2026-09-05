# 06 — Native iOS delivery plan

## 1. Delivery strategy

Build the project in gated milestones. Each milestone removes a specific risk before the next layer is added.

The sequence is intentionally not “design all screens, then code.” The largest risks are camera responsiveness, image memory, Vision quality, segmentation edges, exact geometry, print fidelity, accessibility of direct manipulation, and rule correctness.

The app is iOS-only. Native platform excellence is a deliverable in every milestone, not a polishing phase at the end.

## 2. Milestone overview

| Milestone | Goal | Primary exit condition |
|---|---|---|
| M0 | Product + platform definition | Native iOS scope, Apple-quality bar, requirements, risks, and decisions are explicit |
| M1 | Native technical feasibility | AVFoundation/Vision/Core Image/export/accessibility performance proven on device |
| M2 | SwiftUI foundation | Production Xcode project, architecture, tests, privacy, localization, CI |
| M3 | Image/camera pipeline | Capture/import → analysis → segmentation → deterministic render works end to end |
| M4 | Rules engine | Sourced/versioned profiles drive validation and crop geometry |
| M5 | Apple-quality product UX | Complete guided workflow is polished, accessible, and HIG-aligned |
| M6 | Export/print | Digital and physical outputs are verified dimensionally |
| M7 | Hardening | Accessibility, privacy, performance, reliability, localization, App Intents, QA gates pass |
| M8 | App Store release | TestFlight → review → controlled production launch |

---

## 3. M0 — Product and platform definition

### Objective

Lock what kind of iPhone product we are building before production implementation.

### Work

- accept iOS-only strategy;
- define Apple-quality review lens;
- define MVP and explicit non-goals;
- select preliminary minimum deployment strategy;
- define official-profile publication policy;
- define quality-state semantics;
- decide generic/custom photo-size scope;
- establish monetization guardrails;
- identify initial launch markets for rule research;
- define privacy constraints;
- establish native dependency policy;
- create revised native backlog.

### Exit criteria

- README and docs reflect iOS-only direction;
- ADR for native Swift/SwiftUI is Accepted;
- no unresolved cross-platform assumption blocks M1;
- Apple-frameworks-first policy accepted;
- M1 spike acceptance criteria are explicit.

---

## 4. M1 — Native iOS technical feasibility

### Objective

Prove the hardest Apple-platform capabilities on physical iPhones before freezing production architecture.

M1 spike code is disposable unless explicitly promoted after review.

### Spike A — AVFoundation responsive camera

Build a focused camera prototype.

Validate:

- point-of-use camera authorization;
- session startup;
- time to first preview frame;
- front/rear camera behavior if both remain in scope;
- orientation;
- still capture quality;
- high-resolution capture path;
- interruptions and background/foreground transitions;
- cancellation;
- repeated captures;
- thermal/memory behavior;
- camera unavailable/restricted states.

Instrument:

- screen entry → preview visible;
- shutter → capture result;
- peak memory;
- dropped/hitched UI behavior.

Review current WWDC26 camera guidance during implementation.

### Spike B — PhotosPicker + image ingest

Validate:

- system `PhotosPicker` without full-library permission;
- `Transferable` import;
- HEIC/JPEG/PNG as required;
- orientation metadata;
- wide-gamut/common color profiles;
- large 24/48 MP sources;
- ImageIO downsampling;
- temporary-file lifecycle;
- import cancellation.

Acceptance:

- no broad library permission required for normal import;
- no avoidable full-resolution decode for analysis;
- memory behavior recorded.

### Spike C — Vision face analysis

Use a controlled fixture corpus.

Evaluate:

- face count;
- frontal adult faces;
- skin-tone diversity;
- glasses/facial hair/hair types;
- lighting variation;
- children/babies where ethically sourced;
- rotation;
- small face in high-resolution image;
- landmarks/pose information;
- false positives;
- latency.

Acceptance:

- exact Vision observations chosen for MVP;
- unsupported/low-confidence checks documented;
- normalized domain geometry mapping defined.

### Spike D — Vision subject segmentation

Evaluate difficult edges:

- fine/curly hair;
- light hair on light background;
- dark hair on dark background;
- glasses;
- ears;
- shoulders;
- head coverings;
- child/baby hair;
- shadows;
- textured backgrounds.

For iOS 27, prototype tap/scribble/rectangle segmentation refinement as a candidate manual-correction UX.

Acceptance:

- automatic segmentation quality rubric documented;
- failure/fallback defined;
- refinement approach selected or deferred;
- performance/memory measured.

### Spike E — Core Image / ImageIO render pipeline

Prove:

- bounded analysis decode;
- reuse of processing context;
- low-copy representations;
- responsive working-resolution preview;
- exact high-resolution final crop;
- background composition;
- color/profile handling;
- no repeated lossy encode cycles.

Acceptance:

- deterministic known fixture outputs;
- memory budget documented;
- chosen pipeline types recorded.

### Spike F — PDF and physical print

Generate known photo sizes on representative page formats.

Validate:

- Core Graphics PDF page geometry;
- mm → PDF point calculations;
- margins/gutters/cut marks;
- system print interaction;
- Actual Size / 100% output;
- physical ruler/caliper measurement.

Acceptance:

- measured sizes fall within documented tolerance;
- scaling risks understood;
- implementation approach locked.

### Spike G — SwiftUI editor and accessibility

Prototype:

- edge-to-edge portrait canvas;
- drag/pinch;
- live crop guide/status;
- system toolbar/floating control behavior;
- Dynamic Type around editor;
- VoiceOver labels/value/state;
- non-gesture move/zoom actions;
- Voice Control naming;
- Reduce Motion behavior;
- high contrast/dark appearance.

Acceptance:

- core task can be completed without precision gestures;
- screen does not require custom controls where system controls suffice;
- custom glass, if any, has a concrete UX reason.

### Spike H — App Intents

Prototype one small intent: `Create ID Photo` or open a document profile.

Acceptance:

- action is discoverable in Shortcuts/Siri as supported;
- deep link reaches correct app state;
- no sensitive photo/face data exposed as indexed entities.

### Spike I — optional Foundation Models evaluation

Only execute if a concrete user problem is selected, such as explaining structured warnings.

Prove:

- on-device availability behavior;
- deterministic compliance remains source of truth;
- model-unavailable fallback;
- controlled evaluation set;
- no authoritative/hallucinated rule claims.

This spike may conclude “do not ship AI in MVP.” That is a valid success result.

### Spike J — device/performance baseline

Profile on at least:

- one older device compatible with the proposed minimum iOS target;
- one current-generation iPhone.

Record:

- launch;
- camera first frame;
- capture latency;
- import/downsample;
- Vision face analysis;
- segmentation;
- first preview;
- final render;
- PDF generation;
- peak memory;
- responsiveness/hangs;
- repeated-session thermal behavior.

### M1 exit criteria

- native Swift/SwiftUI architecture confirmed;
- minimum deployment proposal validated or revised;
- camera approach confirmed;
- Vision capabilities selected with explicit limitations;
- segmentation/refinement strategy defined;
- Core Image/ImageIO pipeline proven;
- PDF physical sizing proven;
- accessible editor interaction proven;
- baseline performance budgets recorded;
- no unresolved feasibility blocker.

---

## 5. M2 — Production SwiftUI foundation

### Objective

Create a clean production project after M1 evidence is available.

### Xcode project

- create native iOS SwiftUI application;
- Swift 6 language mode;
- strict concurrency warnings/errors policy;
- bundle ID/signing setup;
- minimum deployment target from M1;
- app target + unit/UI test targets;
- local Swift packages only if they enforce real stable boundaries;
- no third-party dependency by default.

### Foundation architecture

- `AppEnvironment` / typed dependency injection;
- navigation model;
- Observation-based feature state;
- domain value types;
- typed errors;
- cancellation/revision model;
- structured logging with privacy redaction.

### Design foundation

- current SwiftUI system controls;
- semantic spacing/product tokens only where needed;
- String Catalog;
- SF Symbols baseline;
- light/dark/high-contrast support;
- accessibility test scaffolding;
- no custom design system that fights HIG behavior.

### Privacy foundation

- `PrivacyInfo.xcprivacy` exists immediately;
- camera usage purpose string;
- no Photo Library permission if PhotosPicker covers import;
- private/temp file directories;
- cleanup policy;
- dependency privacy review template.

### CI

Evaluate Xcode Cloud first; GitHub Actions/macOS remains an alternative.

PR checks:

- build;
- Swift Testing;
- rules validator placeholder;
- deterministic fixture tests;
- localization validation;
- privacy manifest validation;
- Package.resolved dependency review when changed.

### Exit criteria

- clean checkout builds with documented Xcode version;
- production app launches on physical iPhone;
- unit/UI tests run;
- sample localized content works;
- VoiceOver-friendly sample state exists;
- privacy manifest is valid;
- no image/business logic embedded in SwiftUI views.

---

## 6. M3 — Image and camera pipeline

### Objective

Turn spike findings into production-quality acquisition/analysis/rendering.

### Build order

1. source asset abstraction;
2. PhotosPicker import;
3. AVFoundation camera session/capture;
4. ImageIO metadata and bounded decode;
5. source lifecycle/file protection;
6. Vision face analysis;
7. derived geometry;
8. blur/resolution/exposure checks;
9. Vision segmentation;
10. optional refinement interaction backend;
11. preview renderer;
12. deterministic high-resolution renderer;
13. cancellation/revision safeguards;
14. typed errors/recovery;
15. signposts/performance instrumentation.

### Exit criteria

- controlled fixture images flow end-to-end;
- live camera works reliably across test devices;
- source remains immutable;
- no-face/multiple-face handled;
- segmentation failure has safe fallback;
- old async results cannot overwrite a newer job;
- main actor remains responsive;
- memory stays within M1 budget.

---

## 7. M4 — Rules engine and initial rule catalog

### Objective

Make product behavior data-driven and auditable.

### Work

- canonical schema;
- semantic validator;
- Swift typed profile loader;
- provenance model;
- evaluator registry;
- output-size rules;
- head-size/position evaluators;
- manual-check representation;
- background policy;
- profile version/review-date presentation;
- initial launch profiles;
- boundary fixtures;
- CI validation.

### Exit criteria

- adding a supported profile requires no document-specific SwiftUI/crop code;
- every launch profile has sources and review date;
- invalid profiles fail CI;
- every machine-hard rule has tests;
- manual requirements remain visible;
- profile version is traceable in diagnostics.

---

## 8. M5 — Apple-quality product UX

### Objective

Turn capability into a coherent native iPhone experience.

### Build order

1. home;
2. searchable country/document profile selection;
3. requirement summary;
4. guided camera / Choose Photo path;
5. analysis transition;
6. Photo Check;
7. constrained editor;
8. export choice;
9. digital export;
10. print setup;
11. completion;
12. help/settings;
13. App Intent deep-link integration;
14. optional intelligent explanation if approved.

### Required review passes

#### HIG / design principles

- purpose;
- agency;
- responsibility;
- familiarity;
- flexibility;
- simplicity;
- craft;
- delight.

#### Native component review

For every custom control, answer: why does the system component not meet the need?

#### Liquid Glass review

- standard components inherit system styling;
- content remains primary;
- no decorative glass overload;
- Reduce Transparency/contrast remain usable.

#### Accessibility

- VoiceOver;
- Voice Control;
- Dynamic Type/accessibility sizes;
- Reduce Motion;
- Increased Contrast;
- Differentiate Without Color;
- switch/keyboard behavior where relevant.

#### Localization

- pseudolocalization;
- long strings;
- RTL structural test;
- measurement formatting.

### Usability gate

Task-test:

- create from Photos;
- create from camera;
- recover from denied camera permission;
- understand a warning;
- understand manual checks;
- correct crop with gestures;
- correct crop without gestures;
- generate a print sheet;
- locate source provenance;
- launch from Shortcut/deep link.

### Exit criteria

- core workflow works without explanation;
- no inaccessible gesture-only critical action;
- native navigation/presentation behavior is consistent;
- no major misunderstanding of Ready vs guaranteed acceptance;
- no high-severity usability issue remains.

---

## 9. M6 — Export and print fidelity

### Digital export

Validate:

- exact pixels/aspect ratio;
- JPEG/PNG encoding as required;
- color profile;
- metadata stripping;
- file-size constraints;
- post-export decode verification;
- `Transferable`/share/save behavior.

### Print export

Validate:

- page dimensions;
- grid packing;
- copy count;
- margins/gutters;
- cut guides;
- PDF page boxes;
- native print UI;
- Actual Size instruction;
- physical measurement across representative printers.

### Exit criteria

- output fixtures pass;
- files reopen with exact expected properties;
- PDF page boxes are correct;
- physical photo size is within documented tolerance;
- failed save/share/print states are recoverable.

---

## 10. M7 — Hardening

### Objective

Remove App Store/reliability/accessibility risk and polish the details visible in real usage.

### Reliability

- repeated camera sessions;
- interruptions;
- background/foreground;
- memory pressure;
- low disk;
- corrupt/huge input;
- cancellation races;
- offline mode;
- thermal stress;
- OS update/beta compatibility.

### Performance

Use Instruments to profile and compare runs for:

- SwiftUI responsiveness;
- Time Profiler hotspots;
- allocations/leaks;
- Swift Concurrency contention;
- image memory;
- camera startup;
- export.

Use MetricKit only if it materially improves production diagnostics.

### Accessibility

Perform full core-flow audits on physical device with accessibility features enabled.

No release while a core task is unavailable to VoiceOver due to an avoidable design choice.

### Privacy/security

- no unexpected network traffic in core flow;
- PrivacyInfo.xcprivacy matches binary behavior;
- required-reason APIs declared correctly;
- temporary photos deleted;
- EXIF/GPS stripping verified;
- logs contain no sensitive image/face data;
- every third-party dependency re-reviewed;
- permission strings match actual use.

### System integration

- App Intents tested with AppIntentsTesting if adopted;
- Spotlight only contains safe entities;
- Shortcuts/deep links recover correctly after app state changes.

### Exit criteria

- no open P0;
- no correctness/privacy/data-loss/accessibility P1;
- performance budgets pass;
- launch rules re-audited;
- App Store disclosures match binary;
- TestFlight release candidate accepted by internal/external testers.

---

## 11. M8 — App Store release

### Objective

Ship a polished iPhone product safely.

### Product page

- final product name;
- Icon Composer final icon;
- screenshots/localizations;
- concise privacy-first messaging;
- accurate capability claims;
- no “guaranteed accepted” language;
- support/privacy policy.

### Store configuration

- App Privacy answers;
- age rating;
- encryption/export compliance declarations as applicable;
- StoreKit products if monetized;
- TestFlight notes;
- phased release where appropriate.

### Release QA

- build using App Store-accepted non-beta Xcode;
- archive validation;
- clean install;
- upgrade path if applicable;
- production rules/catalog hash/version recorded;
- rollback/hotfix procedure documented.

### Exit criteria

- App Review approved;
- production version available to intended cohort;
- quality monitoring in place;
- next feature/rule wave begins only after first-release stability.

---

## 12. WWDC-quality review gate

Before calling 1.0 complete, run a separate product review that ignores the backlog and asks only:

1. Is the purpose immediately obvious?
2. Does it look and behave like current iOS rather than a custom framework?
3. Does the photo remain the visual focus?
4. Is every animation/haptic useful?
5. Are system capabilities used meaningfully rather than decoratively?
6. Can a VoiceOver user complete the core task?
7. Are permissions minimal and explained at point of use?
8. Does the app stay fast with 48 MP images?
9. Is every compliance claim traceable?
10. Is optional AI clearly subordinate to deterministic logic?
11. Are empty/error/interruption states as polished as the happy path?
12. Could we remove any visible control or step?
13. Is there at least one moment of genuine delight that comes from the workflow working exceptionally well rather than from decoration?

A “no” does not automatically block release, but every “no” needs an explicit decision.

## 13. Workstream disciplines

Even with one developer, track distinct disciplines:

- Product/specification
- Apple platform architecture
- UX/UI
- Camera/image pipeline
- Rules/content research
- Accessibility
- QA/validation
- Privacy/security
- Performance
- App Intents/system integration
- App Store operations

## 14. Suggested GitHub labels

```text
priority:P0
priority:P1
priority:P2
area:product
area:ios
area:swiftui
area:camera
area:vision
area:image-pipeline
area:rules
area:export
area:privacy
area:accessibility
area:performance
area:app-intents
area:qa
area:release
type:feature
type:bug
type:spike
type:chore
type:decision
```

Milestones mirror M0–M8.

## 15. Change-control rule

When implementation changes a foundational assumption, update:

1. the relevant requirement;
2. `10-decisions.md`;
3. affected acceptance criteria;
4. backlog dependencies;
5. privacy/security analysis if data flow changes;
6. iOS excellence strategy if platform usage changes.

Do not quietly work around architectural discoveries.

## 16. Immediate next development step

Create the **M1 native iOS spike Xcode project**, not the final home screen.

The first production-looking artifact should emerge only after we have measured the camera, Vision, image pipeline, editor accessibility, and exact export behavior on real iPhones.