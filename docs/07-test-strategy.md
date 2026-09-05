# 07 — Test strategy

## 1. Goal

The app manipulates identity photos and claims rule-aware formatting. Testing must therefore go beyond UI snapshots. The highest-risk defects are silent correctness failures: wrong crop geometry, wrong dimensions, bad rule interpretation, altered physical print size, segmentation artifacts, and false compliance signals.

## 2. Test layers

### 2.1 Pure unit tests

Run fast and cover:

- unit conversion;
- aspect-ratio calculations;
- crop solving;
- print packing;
- rounding policy;
- rule evaluation;
- semantic rule validation;
- error mapping;
- state transitions;
- file-size quality-selection logic.

These should form the majority of the test suite.

### 2.2 Fixture/image tests

Use controlled test images with known annotations.

Validate:

- orientation normalization;
- face geometry mapping;
- crop result;
- background composition;
- output dimensions;
- pixel-level invariants where deterministic;
- tolerances around anti-aliasing/encoding where exact bytes are inappropriate.

### 2.3 Golden visual regression tests

Use only for stable visual/rendering outputs where a golden is meaningful.

Examples:

- crop-guide overlay;
- status components;
- print-sheet preview;
- editor layout at key device sizes;
- representative composed images from synthetic/non-sensitive fixtures.

Goldens are not substitutes for dimensional assertions.

### 2.4 Integration tests

Cover multi-module flows:

- import → analyze → edit → export;
- profile change recalculates constraints;
- denied permissions recover safely;
- cancellation/stale analysis result cannot overwrite a newer job;
- corrupted rule profile is rejected;
- generated export is re-opened and verified.

### 2.5 End-to-end device tests

Run on real iOS/Android devices for:

- camera capture;
- photo picker;
- lifecycle/backgrounding;
- low-memory scenarios where feasible;
- save/share;
- OS permission variants;
- large camera images;
- print/share path.

### 2.6 Manual visual QA

Required for areas hard to reduce to a scalar score:

- segmentation edges;
- hair detail;
- glasses/transparent edges;
- clothing/background boundary;
- child/baby cases;
- low-contrast foreground/background;
- editor usability;
- screen-reader flow.

### 2.7 Physical QA

Required for print output.

Generate sheets, print with documented settings, and physically measure:

- page size;
- photo width/height;
- margins;
- copy spacing;
- scaling errors introduced by common print dialogs.

## 3. Test-data policy

Identity photos are sensitive. Test data must be controlled.

Permitted sources:

- synthetic faces/images created for testing where suitable;
- licensed public-domain or test datasets whose terms allow the intended use;
- explicitly consented internal test images;
- geometric synthetic fixtures for crop/print math.

Do not commit private family/user photos to a public repository.

Private fixture data belongs outside the public repo and must be referenced through documented local setup if needed.

## 4. Fixture taxonomy

Each fixture should carry metadata, not just a filename.

Concept:

```text
Fixture
- id
- imageRef
- source/licence class
- orientation
- width/height
- expected face count
- annotated landmarks/box if available
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
```

## 5. Geometry test requirements

Geometry must be tested at boundaries.

For each constraint:

- one value clearly below minimum;
- exactly at minimum;
- just inside minimum;
- preferred/center value;
- just inside maximum;
- exactly at maximum;
- clearly above maximum.

Floating-point comparisons use explicit tolerances. Physical-unit conversions must avoid chaining rounded results.

## 6. Rule-profile tests

Every profile loaded in production must automatically prove:

- schema validity;
- semantic validity;
- unique identity/version;
- complete source provenance for official profiles;
- existing localization keys;
- valid units;
- consistent output dimensions;
- all machine-hard rules have registered evaluators;
- no expired profile is active unless explicitly allowed;
- fixtures for critical numeric boundaries pass.

## 7. Crop-solver tests

Test:

- exact aspect ratio;
- feasible constraint solution;
- no empty source pixels in crop;
- deterministic output;
- behavior when constraints conflict;
- preferred target selection inside legal range;
- very small/large subject;
- subject near source edge;
- portrait/landscape source images;
- rotation-normalized input.

When constraints are mathematically impossible, solver returns a typed failure/warning; it must not silently produce a non-compliant crop.

## 8. Image-render tests

For deterministic source/parameters, assert:

- exact final width/height;
- correct crop region;
- no unintended stretch;
- background mode/value;
- no guides burned into image;
- metadata policy;
- expected color-space handling;
- one final encoding step where practical.

For JPEG, avoid byte equality as the primary correctness check unless encoder/runtime is fixed and intended to be byte-stable.

## 9. Segmentation evaluation

Do not judge segmentation by a few visually easy images.

Define a benchmark rubric with scores for:

- face/hair preservation;
- missing foreground pixels;
- background leakage;
- edge halo/fringing;
- fine-hair handling;
- glasses/transparent detail;
- clothing edge;
- shadow interpretation;
- consistency across skin tones/background brightness;
- runtime;
- memory;
- model size.

If pixel-level annotated masks are available, include quantitative IoU/boundary metrics, but product visual review remains necessary because aggregate scores can hide objectionable face/hair defects.

## 10. Face-detection evaluation

Measure:

- face detection recall on supported source conditions;
- false-positive rate;
- landmark availability;
- landmark positional error against annotations where available;
- stability under resolution changes;
- rotation behavior;
- multiple-face behavior;
- latency/memory.

A detector used for a hard composition rule must demonstrate adequate accuracy for the exact landmark semantics required by that rule.

## 11. Quality-check calibration

Blur/exposure/pose checks should be calibrated as user-assistance tools.

For each check:

- collect labelled representative fixtures;
- establish score distribution;
- choose threshold policy;
- quantify false pass/false warn/false fail;
- prefer `warn` when confidence does not justify hard rejection;
- record algorithm version and calibration dataset version.

Do not tune thresholds using only a small set of handpicked good/bad photos.

## 12. Print test matrix

At minimum validate:

- each supported paper size;
- portrait and landscape page orientation if supported;
- one and many copies;
- edge cases for packing count;
- cut guides on/off;
- PDF viewed/printed through common platform paths;
- actual-size printing;
- a deliberate fit-to-page print to confirm the warning is meaningful.

Record measured physical size and allowed test tolerance.

## 13. Device matrix

Finalize in M1 after minimum OS versions are selected.

Maintain coverage across:

- lower-performance supported Android device;
- current/mid Android device;
- older supported iPhone;
- current representative iPhone;
- different camera resolutions/aspect ratios;
- at least one low-memory stress case.

Simulators/emulators supplement this matrix but do not replace it.

## 14. Accessibility testing

For every release candidate:

- VoiceOver primary flow on iOS;
- TalkBack primary flow on Android;
- maximum/large text size checks;
- reduced motion behavior if motion is meaningful;
- high contrast/visibility review;
- keyboard/switch-like navigation where platform/tooling permits;
- editor usability without pinch/drag as the only controls.

## 15. Localization testing

Pseudo-localization or synthetic long strings should stress:

- country/profile lists;
- warnings;
- requirement checklist;
- editor controls;
- export summary;
- settings;
- store screenshot layouts later.

At least one RTL smoke test is recommended before architecture is considered localization-safe, even if RTL is not a launch language.

## 16. Performance tests

M1 establishes budgets. Thereafter track:

- cold startup;
- analysis bitmap creation;
- face detection p50/p95;
- segmentation p50/p95;
- preview composition;
- final export;
- PDF generation;
- peak resident memory where tooling supports it.

Run representative performance tests on physical devices. Do not rely on simulator timing.

## 17. Network/privacy tests

For the core offline flow:

- inspect network traffic;
- verify no photo upload;
- verify third-party SDKs do not make undocumented photo-related calls;
- verify analytics payload schema;
- verify app remains functional with network disabled.

## 18. Failure-injection tests

Simulate:

- detector exception;
- segmentation exception;
- cancelled operation;
- out-of-memory-like decode failure where possible;
- storage full/permission failure;
- share-sheet cancellation;
- corrupt rules catalog;
- unsupported schema version;
- invalid remote signature if remote rules exist;
- app interruption during analysis/export.

User state should remain understandable and the source image must never be corrupted.

## 19. Regression triage

Severity model:

### P0

- wrong official output dimensions;
- source image corruption/data loss;
- sensitive photo upload/privacy breach;
- app cannot complete core workflow for broad supported devices;
- rule catalog causes materially false output across a launch profile.

### P1

- substantial crop/compliance error;
- segmentation defect commonly visible on identity region;
- export/print scaling issue;
- inaccessible critical flow;
- common crash;
- misleading compliance state.

### P2

- localized cosmetic defect;
- minor layout issue;
- non-critical performance regression;
- low-frequency recoverable inconvenience.

## 20. Release test gate

A release candidate requires:

- unit/integration suites green;
- all production rule profiles validated;
- no P0;
- no correctness/privacy/data-loss P1;
- golden review complete;
- physical-device smoke tests complete;
- print measurement complete for changed print code/rules;
- accessibility smoke tests complete;
- offline/network privacy check complete after dependency changes;
- performance regression reviewed;
- release rule sources rechecked if content changed.

## 21. Test artifacts to add during implementation

Planned structure:

```text
test/
├── domain/
│   ├── geometry/
│   ├── rules/
│   └── validation/
├── application/
├── infrastructure/
└── golden/

integration_test/
├── import_to_digital_export_test.dart
├── import_to_print_export_test.dart
├── permission_recovery_test.dart
└── profile_change_test.dart

test_data/
├── synthetic/
├── metadata/
└── README.md

tool/
├── validate_rules.dart
├── benchmark_pipeline.dart
└── inspect_export.dart
```

Private/consented sensitive datasets remain outside the public repository.
