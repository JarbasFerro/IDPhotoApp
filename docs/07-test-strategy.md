# 07 — Native iOS test strategy

## 1. Goal

The app manipulates identity photos and makes rule-aware formatting claims. Testing must go well beyond UI snapshots.

The highest-risk defects are silent correctness failures:

- wrong crop geometry;
- wrong pixel dimensions;
- wrong physical print size;
- incorrect rule interpretation;
- segmentation artifacts around identity-bearing regions;
- false compliance confidence;
- privacy regressions;
- inaccessible editing;
- image-pipeline memory/performance failures.

The test strategy must also support the project’s iOS quality bar: SwiftUI behavior, accessibility, camera lifecycle, current OS compatibility, App Intents, and physical-device performance.

## 2. Tooling baseline

Preferred Apple-native tooling:

- **Swift Testing** for new unit/domain/integration-style tests where suitable;
- **XCUITest** for UI/system flows;
- **Xcode accessibility audits / Accessibility Inspector** for semantic and interaction review;
- **Instruments** for Time Profiler, Allocations/Leaks, Swift Concurrency, hangs/responsiveness, and signposts;
- **MetricKit** only if adopted for production diagnostics;
- **AppIntentsTesting** if App Intents ship;
- custom fixture/golden comparison helpers for deterministic image outputs;
- physical printers/rulers/calipers for print verification.

Do not add a third-party test framework unless it solves a meaningful gap.

## 3. Test layers

### 3.1 Pure Swift tests

The majority of tests should be fast and platform-light.

Cover:

- unit conversions;
- coordinate-space conversion;
- aspect-ratio calculations;
- crop solving;
- print packing;
- rounding policy;
- rule evaluation;
- semantic rule validation;
- error mapping;
- state transitions;
- stale-result/revision behavior;
- file-size quality-selection logic.

Use parameterized Swift Testing cases heavily for boundary math and rule profiles.

### 3.2 Fixture/image tests

Use controlled images and metadata.

Validate:

- orientation normalization;
- ImageIO downsampling behavior;
- face geometry normalization;
- crop region;
- background composition;
- output dimensions;
- metadata stripping;
- pixel-level invariants where deterministic;
- tolerances around anti-aliasing/encoding where byte equality is inappropriate.

### 3.3 Golden/reference visual tests

Use only where a visual baseline is meaningful.

Examples:

- crop-guide overlay;
- status components;
- print-sheet preview;
- editor layout at key iPhone sizes/text sizes;
- representative composed images from synthetic/non-sensitive fixtures.

Goldens never replace dimensional assertions.

### 3.4 Integration tests

Cover flows such as:

- imported source → analysis → edit → export;
- captured source → analysis → edit → export;
- profile change recalculates constraints;
- camera authorization denied → recovery through Settings or Choose Photo;
- cancellation/stale result cannot overwrite newer photo;
- corrupted rule profile rejected;
- export reopened and verified;
- app background/foreground during processing;
- iOS 27-only feature unavailable on iOS 26 fallback path.

### 3.5 XCUITest end-to-end tests

Automate stable system/user paths where practical:

- home → profile → import/camera choice;
- permission recovery;
- photo-check result states with injected/test fixtures;
- editor controls;
- export screens;
- Dynamic Type layout variants;
- deep links/App Intent destinations.

System pickers and camera hardware boundaries may require controlled test hooks rather than brittle automation.

### 3.6 Manual visual QA

Required for:

- segmentation edges;
- hair detail;
- glasses/transparent edges;
- clothing/background boundaries;
- head coverings;
- child/baby cases;
- low-contrast foreground/background;
- camera-overlay usability;
- editor direct manipulation;
- VoiceOver/Voice Control behavior;
- Liquid Glass/custom overlay readability.

### 3.7 Physical QA

Required for:

- AVFoundation camera behavior on real hardware;
- performance/memory/thermal checks;
- print output.

For print, physically measure:

- page behavior;
- photo width/height;
- margins;
- gutters;
- scaling introduced by print paths.

## 4. Test-data policy

Identity photos are sensitive.

Permitted sources:

- synthetic images;
- appropriately licensed/public datasets whose terms allow the use;
- explicitly consented internal fixtures;
- geometric synthetic fixtures for crop/print math.

Never commit private family/user photos to the public repository.

Sensitive fixture data stays outside Git with documented local setup and retention expectations.

## 5. Fixture taxonomy

Each fixture carries structured metadata.

```text
Fixture
- id
- imageRef
- source/licence class
- orientation
- width/height
- color/profile metadata where relevant
- expected face count
- annotated face box/landmarks if available
- scenario tags
- expected quality states by algorithm version where appropriate
```

Suggested tags:

```text
adult
child
baby
glasses
facial-hair
curly-hair
fine-hair
head-covering
light-background
dark-background
busy-background
low-light
overexposed
blurred
rotated
multiple-faces
no-face
high-resolution
low-resolution
wide-gamut
heic
jpeg
```

## 6. Geometry tests

Test every numeric constraint at boundaries:

- clearly below minimum;
- exactly minimum;
- just inside minimum;
- preferred/center;
- just inside maximum;
- exactly maximum;
- clearly above maximum.

Floating-point comparisons use explicit tolerances. Do not chain rounded conversions.

## 7. Rule-profile tests

Every production profile must prove automatically:

- schema validity;
- semantic validity;
- unique ID/version;
- provenance for official profiles;
- localization keys exist;
- units are valid;
- output dimensions are internally consistent;
- machine-hard rules have evaluators;
- effective/expiry dates are valid;
- numeric boundary fixtures pass.

## 8. Crop-solver tests

Test:

- exact aspect ratio;
- feasible solution;
- no empty source pixels;
- deterministic result;
- conflicting constraints;
- preferred target inside legal range;
- tiny/large subject;
- subject near source edge;
- portrait/landscape sources;
- orientation-normalized input;
- precise rounding.

Impossible constraints return typed diagnostics, never silent noncompliance.

## 9. Image-render tests

For deterministic source + parameters assert:

- exact final width/height;
- correct crop;
- no stretch;
- intended background;
- no guide burned into output;
- metadata policy;
- color-space behavior;
- one final lossy encoding step where practical.

For JPEG, compare decoded image/geometry/tolerance rather than assuming byte equality.

## 10. Vision face-analysis evaluation

Benchmark Vision on representative scenarios.

Measure:

- face recall;
- false positives;
- landmark availability;
- landmark error where annotated;
- rotation behavior;
- multiple-face behavior;
- resolution/downsample stability;
- latency;
- memory.

A Vision measurement used for a hard rule requires accuracy evidence for that exact semantic measurement.

## 11. Segmentation evaluation

Evaluate more than easy studio portraits.

Rubric:

- face/hair preservation;
- missing foreground;
- background leakage;
- halo/fringing;
- fine hair;
- glasses;
- ears;
- clothing edge;
- head coverings;
- shadows;
- consistency across skin tones/background brightness;
- runtime;
- memory.

If annotated masks exist, add IoU/boundary metrics, but visual review remains required.

### iOS 27 refinement evaluation

If tap/scribble/rectangle segmentation ships, test:

- difficult hair boundaries;
- user selects foreground correctly;
- user selects background correctly;
- accidental tap recovery;
- repeated refinement;
- VoiceOver/non-freehand fallback;
- iOS 26 behavior when the API is unavailable.

## 12. Camera test strategy

AVFoundation must be tested on physical iPhones.

Scenarios:

- first authorization;
- already authorized;
- denied/restricted;
- front/rear switch if supported;
- portrait/landscape device movement as relevant;
- repeated enter/exit;
- app interruption/background;
- phone call/system interruption where reproducible;
- camera unavailable;
- low light;
- high contrast;
- multiple faces;
- capture immediately after camera opens;
- repeated captures;
- thermal stress;
- low available storage.

Metrics:

- screen entry → first preview frame;
- shutter → capture ready;
- shutter → first analysis result;
- preview smoothness;
- peak memory;
- energy/thermal behavior during guidance.

Real-time guidance must be debounced/hysteretic enough that messages do not flicker.

## 13. PhotosPicker/import tests

Verify:

- no broad Photo Library permission required;
- cancellation is harmless;
- HEIC/JPEG/PNG handling;
- large 24/48 MP image;
- orientation;
- color profile;
- cloud-backed Photos item behavior as exposed by system picker;
- import interruption;
- unsupported/corrupt data response.

## 14. Quality-check calibration

Blur/exposure/pose checks are user-assistance tools.

For each:

- labelled representative fixtures;
- score distribution;
- threshold policy;
- false pass/warn/fail measurement;
- prefer `warn` when confidence cannot justify failure;
- algorithm/calibration dataset version recorded.

## 15. Print test matrix

Validate:

- each supported page size;
- portrait/landscape where supported;
- one/multiple copies;
- packing boundaries;
- cut guides on/off;
- native print path;
- share PDF → common external viewer/print path;
- Actual Size / 100%;
- deliberate fit-to-page to confirm user warning.

Record physical measurements and tolerance.

## 16. Device / OS matrix

Finalize after M1.

Current proposal:

- one older iPhone that supports iOS 26 and represents the minimum performance tier;
- one mid/current iPhone;
- one current flagship/48 MP camera path;
- iOS 26 latest stable supported version;
- iOS 27 latest release/beta during pre-release validation.

Simulator supplements but never replaces camera/performance/thermal/device testing.

## 17. Accessibility test matrix

Every release candidate:

### VoiceOver

- full primary flow;
- camera controls;
- photo-check states;
- editor move/zoom alternatives;
- export/print;
- focus after async analysis.

### Voice Control

- actionable controls have distinct names;
- core flow operable without ambiguous labels.

### Dynamic Type

- standard largest text size;
- accessibility sizes;
- editor surrounding UI reflow;
- no hidden primary action.

### Visual/motion settings

- Increase Contrast;
- Differentiate Without Color;
- Reduce Motion;
- Reduce Transparency;
- dark appearance;
- Bold Text.

No critical action may require pinch/drag only.

## 18. Liquid Glass / current iOS appearance tests

For latest SDK builds verify:

- standard controls look correct without custom overrides;
- custom glass surfaces remain readable over light/dark/complex photos;
- Reduce Transparency does not break hierarchy;
- increased contrast remains understandable;
- toolbar/action placement follows current iOS conventions;
- no custom effect causes scrolling/input/performance regressions.

UI regression review should occur when moving between Xcode/iOS SDK major releases.

## 19. Localization tests

Use pseudolocalization/long strings for:

- country/profile lists;
- warnings;
- manual checklist;
- editor controls;
- export summary;
- Settings/Help;
- App Shortcut phrases where localized.

Run at least one RTL structural test even if not a launch language.

## 20. App Intents tests

If App Intents ship:

- intent resolves expected profile/action;
- missing/ambiguous parameters handled;
- app launch/deep link state correct;
- sensitive photos/geometry not exposed as App Entities;
- intent availability matches OS target;
- AppIntentsTesting suite where applicable;
- Siri/Shortcuts manual device validation.

## 21. Foundation Models evaluation

If optional generative assistance ships, it gets its own evaluation gate.

Test:

- model unavailable;
- supported device/model available;
- structured warning explanation accuracy;
- no invented official requirement;
- no contradiction of deterministic check;
- prompt injection/untrusted text if external rule/support content ever enters context;
- localization quality;
- latency;
- privacy/data path.

Use Apple Evaluations framework or equivalent controlled evaluation harness where practical.

A failed evaluation can remove the feature without affecting core functionality.

## 22. Performance tests

Track on physical devices:

- cold/warm app startup;
- camera first frame;
- analysis image creation;
- face analysis p50/p95;
- segmentation p50/p95;
- first prepared preview;
- gesture-to-render responsiveness;
- final export;
- PDF generation;
- peak resident memory;
- repeated-session thermal behavior.

Use Instruments run comparisons after performance changes.

## 23. Network/privacy tests

For the core flow:

- test with network disabled;
- inspect traffic;
- verify no photo upload;
- verify no hidden third-party SDK calls;
- verify logs redact/private-mark sensitive values;
- verify temporary file cleanup;
- verify EXIF/GPS removal;
- verify PrivacyInfo.xcprivacy/required-reason APIs match binary behavior.

## 24. Failure injection

Simulate:

- Vision failure;
- segmentation failure;
- cancellation;
- stale async result;
- decode failure;
- storage full;
- share/print cancellation;
- corrupt rules catalog;
- unsupported schema version;
- app interruption during analysis/export;
- iOS 27 optional API unavailable;
- Foundation Model unavailable if feature exists.

Source image must remain intact and user state understandable.

## 25. Regression severity

### P0

- wrong official output dimensions;
- source corruption/data loss;
- sensitive image/privacy breach;
- core flow broadly unusable on supported devices;
- rule catalog produces materially false output for launch profile.

### P1

- substantial crop/compliance error;
- common segmentation defect around identity region;
- export/print scaling issue;
- inaccessible critical flow;
- common crash/hang;
- misleading compliance state;
- camera reliably fails on a supported device class.

### P2

- cosmetic/layout defect;
- low-frequency recoverable issue;
- non-critical performance regression.

## 26. Release gate

Release candidate requires:

- Swift Testing suites green;
- production rule profiles validated;
- no P0;
- no correctness/privacy/data-loss/accessibility P1;
- fixture/golden review complete;
- physical iPhone smoke test complete;
- camera performance reviewed;
- print measurement complete when print code/rules changed;
- VoiceOver core flow complete;
- Dynamic Type/motion/contrast pass complete;
- network/privacy check after dependency changes;
- performance regression reviewed;
- App Intents/optional AI evaluation complete if those features changed;
- release rule sources rechecked.

## 27. Planned test structure

```text
IDPhotoAppTests/
├── Domain/
│   ├── GeometryTests.swift
│   ├── RuleTests.swift
│   ├── ValidationTests.swift
│   └── PrintLayoutTests.swift
├── ImagePipeline/
│   ├── ImageIngestTests.swift
│   ├── VisionMappingTests.swift
│   ├── RendererTests.swift
│   └── ExportTests.swift
├── Features/
│   └── WorkflowStateTests.swift
└── TestSupport/
    ├── Fixtures/
    ├── GoldenComparator.swift
    └── Metadata/

IDPhotoAppUITests/
├── PrimaryFlowUITests.swift
├── PermissionRecoveryUITests.swift
├── AccessibilityUITests.swift
└── DeepLinkUITests.swift

Tools/
├── RuleValidator/
├── FixtureInspector/
└── ExportInspector/
```

Private/consented sensitive datasets remain outside the public repository.