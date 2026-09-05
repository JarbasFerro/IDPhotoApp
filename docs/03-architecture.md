# 03 — Native iOS architecture

## 1. Architecture objective

The application is iOS-only and should be architected as a first-class Apple platform product, not as a portable application with an iOS skin.

The architecture must optimize for:

1. **Correctness** — output geometry and rule evaluation are deterministic and testable.
2. **Native quality** — SwiftUI and Apple frameworks are the default implementation surface.
3. **Privacy** — the core workflow runs on-device and does not require an account or cloud image processing.
4. **Performance** — image work minimizes copies, stays off the main actor, and is profiled with Instruments on physical iPhones.
5. **Accessibility** — editing and validation remain usable without relying only on vision, color, or gestures.
6. **Replaceability** — face analysis, segmentation, persistence, and optional intelligence remain behind narrow protocols where practical.
7. **International scale** — country/document requirements remain data, not UI conditionals.
8. **System integration** — use iOS capabilities such as App Intents, PhotosPicker, ShareLink, Spotlight, and native printing when they improve the task.

## 2. Platform baseline

### Development baseline — September 2026

- **Product target:** iPhone / iOS only.
- **IDE / SDK:** Xcode 27 during development; while Xcode 27 remains beta, use it for technical validation and switch release builds to the first App Store-accepted non-beta Xcode 27.
- **Compiler:** Swift 6.4 compiler, Swift 6 language mode.
- **UI:** SwiftUI-first.
- **Deployment target:** proposed iOS 26.0; iOS 27 APIs are adopted behind availability checks until ADR-024 is finalized.
- **Concurrency:** structured Swift Concurrency with strict checking; UI state isolated to `@MainActor` where appropriate.
- **Observation:** Observation framework / `@Observable`; avoid adopting a third-party state-management framework.
- **Testing:** Swift Testing for new unit/integration suites; XCUITest for UI/system flows.

The deployment target is intentionally separate from the build SDK. The app should compile against the newest SDK so it receives current platform behavior and can adopt iOS 27 features without requiring every user to update immediately.

## 3. Apple-frameworks-first policy

Before adding a dependency, verify that an Apple framework cannot solve the requirement adequately.

Preferred framework map:

| Need | Preferred Apple technology |
|---|---|
| UI / navigation | SwiftUI |
| state observation | Observation (`@Observable`) |
| concurrency | Swift Concurrency |
| camera | AVFoundation |
| photo import | PhotosUI / `PhotosPicker` |
| face / image analysis | Vision |
| subject segmentation | Vision |
| optional custom on-device model | Core AI / Core ML only if Vision is insufficient |
| image pipeline | Core Image + ImageIO + Core Graphics |
| accelerated pixel operations | Accelerate / vImage where profiling justifies it |
| PDF geometry | Core Graphics PDF APIs |
| print UI | UIKit `UIPrintInteractionController` bridge if needed |
| export/share | `Transferable`, `ShareLink`, system share sheet |
| local settings | `UserDefaults` / AppStorage for simple settings |
| structured local metadata | SwiftData only if requirements justify it |
| localization | String Catalogs (`.xcstrings`) |
| symbols | SF Symbols |
| app icon | Icon Composer |
| shortcuts / Siri / Action button | App Intents / App Shortcuts |
| search exposure | Core Spotlight |
| contextual education | TipKit where useful |
| monetization | StoreKit |
| performance diagnostics | Instruments, MetricKit, OSLog/OSSignposter |
| privacy declaration | `PrivacyInfo.xcprivacy` |

Third-party SDKs should be exceptional, especially in the image, analytics, advertising, and privacy-sensitive layers.

## 4. Design-system architecture

The app should inherit the platform before customizing it.

Rules:

- standard SwiftUI controls and navigation are the default;
- do not recreate buttons, sheets, menus, search, share UI, or navigation chrome without a documented product need;
- build with the latest SDK so current Liquid Glass behavior is inherited automatically;
- custom `glassEffect` is reserved for a small number of floating, interactive surfaces where it clarifies hierarchy;
- no decorative layers of glass behind already-glass controls;
- semantic colors/materials instead of hard-coded appearance colors where possible;
- SF Symbols before custom glyph assets;
- Dynamic Type and accessibility sizes are supported by layout rather than patched later;
- motion uses SwiftUI system transitions and `sensoryFeedback` judiciously;
- Reduce Motion and accessibility contrast settings must remain coherent.

## 5. Logical architecture

```text
┌────────────────────────────────────────────────────┐
│ SwiftUI Presentation                               │
│ screens, navigation, feature views, accessibility  │
└──────────────────────┬─────────────────────────────┘
                       │
┌──────────────────────▼─────────────────────────────┐
│ Feature Models / Application Use Cases             │
│ @Observable state, commands, async orchestration   │
└──────────────┬───────────────────────┬─────────────┘
               │                       │
┌──────────────▼──────────────┐ ┌──────▼─────────────┐
│ Domain                      │ │ Apple Adapters     │
│ rules, geometry, validation,│ │ AVFoundation,      │
│ edits, export contracts     │ │ Vision, CoreImage, │
│ pure Swift where possible   │ │ PhotosUI, Print... │
└──────────────┬──────────────┘ └──────┬─────────────┘
               │                       │
┌──────────────▼───────────────────────▼─────────────┐
│ Rules Catalog / Assets                             │
│ versioned, sourced, validated specifications       │
└────────────────────────────────────────────────────┘
```

The Domain layer must not import SwiftUI, AVFoundation, PhotosUI, or UIKit.

## 6. Proposed source structure

Start simple. Add modules only where they enforce a meaningful boundary.

```text
IDPhotoApp/
├── App/
│   ├── IDPhotoApp.swift
│   ├── AppEnvironment.swift
│   ├── Navigation/
│   └── DesignSystem/
├── Features/
│   ├── Home/
│   ├── ProfilePicker/
│   ├── Requirements/
│   ├── Capture/
│   ├── PhotoCheck/
│   ├── Editor/
│   ├── Export/
│   └── Settings/
├── Domain/
│   ├── DocumentRules/
│   ├── Geometry/
│   ├── PhotoJob/
│   ├── Validation/
│   └── Export/
├── ImagePipeline/
│   ├── Acquisition/
│   ├── VisionAnalysis/
│   ├── Segmentation/
│   ├── Rendering/
│   └── ImageIO/
├── Infrastructure/
│   ├── Persistence/
│   ├── Logging/
│   ├── AppIntents/
│   ├── Spotlight/
│   └── Store/
├── Resources/
│   ├── Rules/
│   ├── Localizable.xcstrings
│   └── Assets.xcassets
└── Tests/
```

If compile times or reuse justify it, `Domain`, `RuleKit`, `ImagePipeline`, and `TestSupport` may later become local Swift packages. Do not split the project into packages simply to mimic a large-company architecture.

## 7. State management

Use platform-native state tools.

Default pattern:

- immutable domain value types;
- `@Observable` feature models for screen/workflow state;
- `@MainActor` for UI-facing state mutation;
- dependencies injected through initializers or a small typed `AppEnvironment`;
- SwiftUI `Environment` only for truly app-wide capabilities;
- explicit async use cases for long-running work;
- no global mutable singleton `PhotoJob`;
- no Redux/TCA-style dependency unless a real complexity problem emerges that native tools cannot solve cleanly.

Views should describe UI. They should not contain image-processing algorithms or document-rule math.

## 8. Concurrency model

Image work is expensive and must never accidentally block UI responsiveness.

Principles:

- UI-facing models run on the main actor;
- image decoding, Vision analysis, segmentation, and rendering execute away from the main actor;
- task cancellation is propagated when the user replaces an image, changes profile, or leaves the workflow;
- every long operation carries a job/revision identity so stale results cannot overwrite newer state;
- use `Sendable` models across concurrency boundaries;
- avoid `Task.detached` unless actor inheritance is explicitly undesirable and documented;
- use task groups only when parallel work is independent and memory impact is measured;
- profile actor contention and task scheduling with the Swift Concurrency instrument.

Example stale-result rule:

1. photo A begins analysis;
2. user picks photo B;
3. A is cancelled;
4. even if a framework callback for A completes, its revision no longer matches the active job and is discarded.

## 9. Image acquisition

### 9.1 Camera

Use AVFoundation for the custom capture experience because the product benefits from live composition and quality guidance.

Architecture:

- dedicated camera session controller;
- explicit authorization flow initiated by user action;
- camera session lifecycle tied to the capture screen;
- preview and capture configuration optimized independently;
- high-resolution still capture only when needed;
- no permanent camera session running outside the capture flow;
- interruptions, thermal pressure, media-services reset, and backgrounding handled explicitly;
- signpost launch-to-first-frame and shutter-to-result latency.

The technical spike should incorporate current Apple camera guidance, including fast camera startup and high-resolution capture practices from WWDC26.

### 9.2 Photo import

Use `PhotosPicker` / PhotosUI rather than requesting broad Photo Library access.

Benefits:

- system-controlled privacy;
- limited selection without full library permission;
- familiar interaction;
- less custom code;
- fewer permission failure states.

Import using `Transferable` where practical and copy the selected source into app-controlled temporary/private storage only when processing requires it.

## 10. Image pipeline

The pipeline should avoid repeatedly materializing full-resolution `UIImage` values.

Preferred primitives:

- ImageIO / `CGImageSource` for metadata-aware decode and downsampling;
- `CGImage` / `CIImage` as core processing representations;
- a reused Metal-backed `CIContext` for composition/export where supported;
- Core Graphics for exact raster/PDF geometry;
- `UIImage` mainly at UIKit boundaries, not as the universal pipeline type.

Pipeline:

### Stage 1 — ingest

- validate type/header;
- read orientation;
- capture dimensions/color information;
- store immutable source reference;
- reject corrupt or implausible inputs.

### Stage 2 — analysis image

Downsample to a bounded resolution using ImageIO. Apply orientation consistently. Do not decode a 48 MP file into memory merely to detect a face.

### Stage 3 — Vision analysis

Use Vision for:

- face count;
- face bounding boxes;
- available landmarks/pose information;
- foreground/subject segmentation;
- supported quality/image-analysis operations where evidence is strong enough.

Convert Vision observations immediately into domain-neutral normalized geometry.

### Stage 4 — deterministic quality checks

Independent checks may include:

- input resolution;
- blur/sharpness;
- exposure;
- face size/position;
- head pose where measurement reliability supports it.

Each check can be enabled, disabled, calibrated, and tested independently.

### Stage 5 — segmentation

Use Vision subject/foreground segmentation first. On iOS 27, investigate the new tap/scribble/rectangle segmentation capabilities as a precise user-driven refinement mechanism.

The automatic segmenter must expose uncertainty and a fallback. A broken hair mask must never silently become the official export.

### Stage 6 — rule evaluation

Evaluate measurable results against the selected `DocumentProfile` and produce `pass / warn / fail / manual_check` states.

### Stage 7 — preview

Compose a responsive working-resolution preview. Guides and status are SwiftUI overlays and are never baked into the image.

### Stage 8 — final render

Reconstruct from the original/high-resolution source using the final crop/mask/background parameters. Encode once at the end where possible.

### Stage 9 — post-export verification

Re-open generated output and verify dimensions, format, page size, metadata policy, and profile-specific machine-checkable constraints before reporting success.

## 11. Coordinate systems

Use explicit value types. Never pass anonymous `CGRect` values across layers without knowing their coordinate space.

Required spaces:

- `SourcePixelSpace`
- `NormalizedImageSpace` (0...1)
- `PreviewPointSpace`
- `OutputPixelSpace`
- `PhysicalMillimeterSpace`
- `PDFPointSpace`

Conversions are centralized and unit-tested.

Rule geometry should prefer normalized/physical coordinates rather than screen points.

## 12. Geometry engine

A pure Swift domain module owns:

- aspect-ratio calculations;
- crop fitting;
- head-height target/range evaluation;
- eye-line and face-center placement;
- legal translation/scale ranges;
- millimetre ↔ inch ↔ pixel conversions;
- PPI/DPI calculations;
- print-grid packing;
- margins/gutters/cut marks;
- rounding policy.

No SwiftUI view independently reimplements this math.

Rounding is defined once and tested at boundaries.

## 13. Core domain model

### `DocumentProfile`

Contains:

- stable profile ID;
- jurisdiction;
- document/use-case type;
- output dimensions;
- permitted encodings;
- background rules;
- composition constraints;
- manual instructions;
- provenance;
- version/effective dates.

### `PhotoJob`

```text
PhotoJob
- id
- profileID + profileVersion
- sourceAsset
- normalizedImageInfo
- analysisResult
- segmentationState
- editParameters
- validationResult
- exportMetadata (optional)
- revision
```

### `EditParameters`

```text
- crop rectangle/center
- subject scale
- translation
- permitted rotation
- background mode/value
- mask corrections
- permitted tonal correction parameters
```

### `ValidationResult`

```text
ValidationResult
- profileID/version
- overallState
- checks[]

ValidationCheck
- ruleID
- state: pass | warn | fail | manual_check
- measuredValue?
- expectedRange?
- confidence?
- userMessageKey
- remediationMessageKey
```

## 14. Foundation Models / generative intelligence policy

Generative intelligence is optional and subordinate to the deterministic product core.

Potential high-value uses:

- explain a structured warning in simpler language;
- answer a question such as “Why do I need more space above my head?” using only approved rule context;
- provide non-authoritative photo-taking coaching;
- natural-language shortcuts to select a document profile.

Rules:

- a Foundation Model never decides final crop dimensions or official pass/fail geometry;
- model output cannot silently override sourced rule text;
- official-photo decisions remain traceable to rule IDs and deterministic measurements;
- image inputs stay on-device unless a future cloud feature is separately approved;
- if a Foundation Models feature is added, use Apple’s Evaluations framework / a controlled evaluation suite before release;
- the experience must degrade cleanly when Apple Intelligence/model availability is absent.

A feature should not exist merely to claim “AI.”

## 15. App Intents and system integration

Expose only actions that make sense outside the app.

Candidate App Intents:

- `CreateIDPhoto`
- `OpenDocumentProfile`
- `CreatePrintSheetFromLastPreparedPhoto` only if a safe recent-job model exists

Candidate App Shortcuts:

- “Create an ID photo”
- “Make a passport photo”
- “Open my recent ID photo format”

Privacy rule: sensitive user photos, face geometry, and file paths must not become broadly indexed App Entities.

Use Core Spotlight for document/profile discovery, not personal images.

## 16. Localization

Use String Catalogs from the first production screen.

Requirements:

- no user-facing production strings embedded in code outside intentional developer diagnostics;
- pluralization and grammatical variation represented structurally;
- official document names may have localized aliases while preserving canonical identifiers;
- measurement formatting uses Foundation format styles;
- RTL layout should not be accidentally blocked by custom geometry;
- pseudolocalization / long-string testing is part of CI/manual QA.

## 17. Accessibility architecture

Accessibility is not a modifier pass at the end.

Core editor must support:

- VoiceOver labels and values;
- accessible adjustable actions for scale/position where suitable;
- explicit move up/down/left/right alternatives;
- Voice Control discoverable names;
- Dynamic Type including accessibility sizes for surrounding controls;
- status semantics independent of color;
- Reduce Motion fallbacks;
- increased contrast;
- sufficient hit regions;
- meaningful focus updates after analysis or modal transitions.

For image-centric content, descriptions should communicate task state without unnecessarily narrating sensitive physical traits.

## 18. Persistence

Default to less persistence.

Persist:

- settings;
- favorites/recent document profile IDs;
- installed rule-catalog version;
- purchase entitlement state via StoreKit mechanisms as appropriate.

Do not create a permanent face gallery by default.

Use SwiftData only if resume/history or more complex local structured data becomes a validated requirement. A simple requirement should not be inflated into a database.

## 19. Sensitive file lifecycle

Source and temporary outputs are sensitive.

Rules:

- use app-private storage;
- use file protection appropriate for sensitive content;
- strip EXIF/GPS from official exports unless a profile explicitly requires metadata;
- delete temporary analysis/render files when the job completes or expires;
- clean stale files after interrupted sessions;
- exclude unnecessary temporary content from backups;
- never log raw image bytes, thumbnails, landmarks, or local sensitive paths.

## 20. Privacy manifest and permissions

The production target includes `PrivacyInfo.xcprivacy` from the beginning, not as release cleanup.

Camera access:

- request only when the user chooses camera capture;
- clear `NSCameraUsageDescription` in plain language.

Photo import:

- prefer PhotosPicker so full-library permission is unnecessary for the normal flow.

Every dependency must be reviewed for required-reason APIs and its own privacy manifest.

## 21. Telemetry

Start with Apple-native diagnostics and minimal structured instrumentation.

Preferred sequence:

1. local `Logger` / unified logging with privacy redaction;
2. Instruments during development;
3. MetricKit for production performance diagnostics if useful;
4. third-party crash/analytics SDK only after an explicit privacy/value decision.

Never collect:

- source/exported face images;
- thumbnails;
- face embeddings;
- landmarks;
- EXIF GPS;
- user document numbers;
- arbitrary file paths.

## 22. Performance observability

Create signposts for:

- camera screen requested → first preview frame;
- shutter → captured photo ready;
- import → analysis image ready;
- face analysis;
- segmentation;
- first compliant preview;
- high-resolution render;
- PDF generation;
- export completion.

Budgets are established on physical devices after M1 profiling. Do not choose artificial performance numbers before measurements.

Use Instruments run comparisons to prove improvements rather than relying on subjective impressions.

## 23. Testing architecture

### Swift Testing

Use for:

- geometry;
- rule evaluation;
- conversion/rounding;
- domain state transitions;
- export invariants;
- fixture-driven Vision result normalization where determinism permits.

### Image golden/reference tests

- fixed source fixtures;
- fixed edit parameters;
- deterministic output geometry;
- pixel/tolerance comparisons where codecs permit;
- metadata assertions.

### XCUITest

Cover:

- primary flow;
- permission-denied recovery;
- PhotosPicker boundary where automation permits;
- error states;
- Dynamic Type layout;
- VoiceOver/accessibility audit scenarios where tooling supports them.

### Physical validation

- real iPhone camera capture;
- memory/thermal tests;
- interruption/backgrounding;
- print at Actual Size / 100%;
- measure printed dimensions physically.

## 24. CI/CD

Preferred path: Xcode Cloud if it provides the required test/device/build capabilities at acceptable cost; GitHub Actions/macOS remains an alternative.

PR gates:

- build with current supported Xcode;
- Swift format/lint policy if adopted;
- Swift Testing suites;
- rule schema/semantic validation;
- deterministic image/export fixtures;
- privacy manifest validation;
- localization checks;
- dependency review when Package.resolved changes.

Main/release gates add:

- archive validation;
- XCUITest matrix;
- Instruments/performance review for critical changes;
- App Store privacy/export metadata review;
- TestFlight validation.

## 25. Dependency rule

For every non-Apple package or binary SDK record:

- exact product need;
- why an Apple API is insufficient;
- maintainer and release activity;
- license;
- transitive dependencies;
- network behavior;
- permissions;
- privacy manifest;
- required-reason APIs;
- binary size;
- startup/runtime impact;
- removal strategy.

Default answer for analytics, ad, photo-editing, and AI SDKs is “no” until justified.

## 26. M1 native iOS spikes

### Spike A — responsive camera + PhotosPicker

Validate AVFoundation startup/capture, permissions, interruptions, HEIC/JPEG, orientation, large photos, and system photo import.

### Spike B — Vision face analysis

Measure face count, normalized geometry, landmarks/pose usefulness, latency, and failure cases on representative fixtures.

### Spike C — Vision segmentation

Evaluate subject/foreground segmentation and iOS 27 tap-to-segment refinement for hair, glasses, head coverings, shoulders, children/babies, and difficult backgrounds.

### Spike D — Core Image / ImageIO pipeline

Prove bounded decode, low-copy analysis, responsive previews, high-resolution final render, color handling, and memory stability.

### Spike E — exact image/PDF export

Generate known dimensions, verify headers/page boxes, print at 100%, and physically measure.

### Spike F — SwiftUI editor + accessibility

Prototype drag/pinch, constrained geometry, live validation, VoiceOver adjustable actions, button alternatives, Dynamic Type, Reduce Motion, and Voice Control naming.

### Spike G — App Intents proof

Prototype a small `Create ID Photo` intent/shortcut to validate system entry points without exposing sensitive photo data.

### Spike H — iOS 27 optional intelligence

Prototype only if a clear user benefit exists. Evaluate Foundation Models image/text assistance against a controlled rubric and prove that the app remains correct when the model is unavailable.

### Spike I — performance

Use Instruments on at least one older supported and one current iPhone class. Record memory, latency, responsiveness, and thermal behavior.

## 27. Architecture fitness tests

The architecture is healthy if we can:

- add a document profile without changing SwiftUI crop logic;
- test geometry without booting the app;
- replace one Vision-derived heuristic without rewriting screens;
- cancel photo A and guarantee it cannot update photo B;
- run the full core flow offline;
- delete all optional AI functionality without breaking compliance logic;
- use standard iOS controls without fighting a custom design system;
- enable VoiceOver and finish the core workflow without gesture-only dead ends;
- generate identical output geometry from identical source/parameters;
- prove no third-party network call is necessary during the core flow.

## 28. Primary Apple references

Keep these as living architectural references and review them after each WWDC / major SDK release:

- Apple Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines/
- WWDC26 iOS guide — https://developer.apple.com/wwdc26/guides/ios/
- WWDC26 SwiftUI guide — https://developer.apple.com/wwdc26/guides/swiftui/
- Liquid Glass overview — https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass
- Vision — https://developer.apple.com/documentation/vision
- App Intents — https://developer.apple.com/documentation/appintents
- Foundation Models — https://developer.apple.com/documentation/FoundationModels
- Privacy manifests — https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Xcode system requirements — https://developer.apple.com/xcode/system-requirements/

Platform APIs and guidance evolve. When the repository and Apple documentation conflict, update the repository deliberately and record the architecture decision.