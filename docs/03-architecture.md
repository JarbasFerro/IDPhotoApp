# 03 — Architecture

## 1. Architecture goals

The architecture must optimize for five properties:

1. **Correctness** — output geometry and rule evaluation are deterministic and testable.
2. **Privacy** — the core workflow does not require cloud processing.
3. **Replaceability** — face detection, segmentation, analytics, and persistence implementations can be changed without rewriting product logic.
4. **International scale** — document rules are data, not UI conditionals.
5. **Testability** — image transformations and rule decisions can run in automated tests without booting the entire application.

## 2. Proposed stack

### Recommended baseline

- **Client:** Flutter / Dart.
- **Targets:** iOS + Android.
- **Native interop:** platform channels / FFI only for capabilities that materially outperform portable Dart implementations.
- **Persistence:** lightweight local database/key-value storage for settings, recent profile IDs, and optional job metadata; raw images should not be stored in the database.
- **Rule catalog:** versioned JSON (or generated typed assets) validated against a schema during CI/build.
- **Backend:** none required for the first core workflow.

This is an **Architecture Decision Candidate**, not a final lock. M1 must compare practical performance, plugin maturity, image memory behavior, native API access, and build/release complexity before ADR-001 becomes accepted.

## 3. Why Flutter is the current default

The product needs highly customized image UI but does not need two independent native product implementations. Flutter offers a single rendering/runtime model, one UI codebase, predictable custom drawing for crop guides, and strong cross-platform development speed.

However, the decision is conditional on M1 proving that:

- camera/photo-picker integrations are reliable enough;
- image processing does not cause unacceptable memory copies;
- face/segmentation native bridges can be integrated cleanly;
- generated PDF/image export is dimensionally exact;
- accessibility semantics remain strong;
- app size and cold-start impact are acceptable.

If those conditions fail, the fallback decision should compare Kotlin Multiplatform/shared core with native SwiftUI/Compose UIs or fully native apps.

## 4. Logical architecture

```text
┌───────────────────────────────────────────────┐
│ Presentation                                 │
│ screens, navigation, view models, editor UI  │
└──────────────────────┬────────────────────────┘
                       │
┌──────────────────────▼────────────────────────┐
│ Application / Use Cases                      │
│ select profile, analyze, edit, validate,     │
│ export digital, export print sheet           │
└──────────────┬───────────────────────┬────────┘
               │                       │
┌──────────────▼─────────────┐ ┌───────▼──────────────┐
│ Domain                     │ │ Ports / Interfaces   │
│ rules, geometry, states,   │ │ detector, segmenter,│
│ edit model, export model   │ │ encoder, storage... │
└──────────────┬─────────────┘ └───────┬──────────────┘
               │                       │
               │              ┌────────▼──────────────┐
               │              │ Infrastructure       │
               │              │ native ML, camera,   │
               │              │ files, PDF, analytics│
               │              └───────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│ Rules Catalog                               │
│ validated, versioned, sourced specifications│
└─────────────────────────────────────────────┘
```

The Domain layer must not depend on Flutter widgets or platform APIs.

## 5. Proposed source structure after stack lock

```text
lib/
├── app/
│   ├── app.dart
│   ├── navigation/
│   └── theme/
├── core/
│   ├── errors/
│   ├── logging/
│   ├── result/
│   └── utils/
├── domain/
│   ├── document_rules/
│   ├── geometry/
│   ├── image_job/
│   ├── quality_checks/
│   └── export/
├── application/
│   ├── analyze_photo/
│   ├── compose_photo/
│   ├── validate_photo/
│   ├── export_digital/
│   └── export_print/
├── infrastructure/
│   ├── camera/
│   ├── files/
│   ├── face_detection/
│   ├── segmentation/
│   ├── image_codec/
│   ├── pdf/
│   ├── persistence/
│   └── telemetry/
├── features/
│   ├── home/
│   ├── profile_picker/
│   ├── capture_import/
│   ├── analysis/
│   ├── editor/
│   ├── export/
│   └── settings/
└── l10n/

assets/
└── rules/

test/
integration_test/
tool/
```

Avoid a generic `services/` dumping ground. Each infrastructure adapter implements a narrow domain/application port.

## 6. Core domain model

### 6.1 DocumentProfile

Canonical representation of one supported output requirement set.

Key concepts:

- stable profile ID;
- jurisdiction;
- document/use-case type;
- output dimensions;
- permitted encodings;
- background requirements;
- composition constraints;
- manual instructions;
- provenance;
- version/effective dates.

### 6.2 PhotoJob

A working session containing references and parameters, not duplicated destructive images where avoidable.

Suggested conceptual fields:

```text
PhotoJob
- jobId
- profileId + profileVersion
- sourceImageRef
- normalizedImageInfo
- analysisResult
- segmentationResultRef/cache
- editParameters
- validationResult
- exportHistory metadata (optional)
```

### 6.3 EditParameters

Pure parameters describing the intended output:

```text
- crop center / rectangle
- subject scale
- translation
- rotation if permitted
- background mode/value
- mask corrections
- limited tonal corrections if supported
```

The renderer reconstructs the preview/output from source + parameters.

### 6.4 ValidationResult

```text
ValidationResult
- profileId/version
- overallState
- checks[]

ValidationCheck
- ruleId
- state: pass | warn | fail | manual_check
- measuredValue? 
- expectedRange?
- confidence?
- userMessageKey
- remediationMessageKey
```

## 7. Image pipeline

The pipeline must distinguish preview resolution from final export resolution.

### Stage 1 — Ingest

- obtain photo/camera asset;
- decode header and validate format;
- read orientation;
- retain immutable source reference;
- reject implausible/corrupt input.

### Stage 2 — Normalized analysis bitmap

Create a bounded-resolution, correctly oriented bitmap for detection/analysis. Do not run heavy ML on a 40+ MP image unless profiling proves it necessary.

### Stage 3 — Face analysis

- face count;
- bounding box;
- landmarks/pose/confidence as available;
- derived normalized geometry.

All detector-specific types are converted immediately into domain-neutral structures.

### Stage 4 — Quality analysis

Independent checks:

- resolution;
- blur/sharpness;
- exposure;
- face geometry;
- optional pose/eye/occlusion warnings.

Checks must be independently testable and independently disableable if a model/algorithm proves unreliable.

### Stage 5 — Segmentation

Generate a foreground alpha mask at an appropriate working resolution. Preserve enough information to re-run/refine final-resolution edges during export if the model supports it.

### Stage 6 — Rule evaluation

Run composition/quality measurements against the selected `DocumentProfile` and produce `ValidationResult`.

### Stage 7 — Preview composition

Render source + mask/background + crop parameters to a UI-resolution preview. Guides and warnings are overlays; they are never baked into the photo.

### Stage 8 — Final render

Reconstruct from original/high-resolution source. Apply deterministic transforms in a defined order and encode once at the end where possible.

### Stage 9 — Post-export verification

Decode metadata/header from the generated asset and verify dimensions, page size, format, and other machine-checkable invariants before reporting success.

## 8. Coordinate systems

Image apps become fragile when pixels, display points, crop coordinates, and physical units are mixed. Define coordinate types explicitly.

Recommended systems:

- **SourcePixelSpace** — actual normalized source image pixels.
- **NormalizedImageSpace** — 0.0–1.0 coordinates independent of resolution.
- **PreviewSpace** — Flutter logical pixels for interaction/rendering.
- **OutputPixelSpace** — final exported image pixels.
- **PhysicalSpaceMm** — millimetres used for document/print rules.
- **PdfPointSpace** — points used for page generation where applicable.

Conversion functions should be centralized and unit-tested. Domain rule geometry should prefer normalized and physical units instead of UI coordinates.

## 9. Geometry engine

Create a small pure-Dart package/module responsible for:

- aspect-ratio calculations;
- crop fitting;
- head-height target/range evaluation;
- eye-line/face-center placement;
- safe translation/scale ranges;
- mm ↔ inch ↔ pixel conversions;
- DPI/PPI calculations;
- print grid packing;
- margins/gutters/cut marks;
- rounding policy.

No UI code should independently repeat this math.

Critical rule: define rounding once. For example, physical-to-pixel conversion must specify whether values are rounded to nearest integer and at which stage. Avoid repeated conversion/rounding.

## 10. Face-detection abstraction

Define a port similar to:

```text
FaceDetector
  detect(AnalysisImage) -> FaceDetectionResult
```

Domain-neutral result:

```text
FaceDetectionResult
- faces[]

DetectedFace
- boundingBoxNormalized
- landmarksNormalized
- yaw/pitch/roll? 
- confidence? 
```

Candidate implementations may use platform Vision APIs, ML Kit, or another vetted on-device model. The architecture must permit A/B benchmark comparison using the same fixture corpus.

## 11. Segmentation abstraction

```text
SubjectSegmenter
  segment(AnalysisImage, optionalFaceHint) -> SegmentationResult
```

Result should expose:

- mask reference/data;
- source/working dimensions;
- confidence/quality information if available;
- model/implementation version;
- warnings.

Do not couple the editor to a specific segmentation SDK.

## 12. Rules catalog architecture

Initial recommendation:

1. Human-maintained canonical source files under `assets/rules/`.
2. JSON Schema validation in CI.
3. Additional semantic validator written in Dart/tooling.
4. Build step generates typed immutable rule objects or validates runtime assets.
5. Tests load every profile.
6. Rule fixtures assert expected dimensions and sample composition decisions.

A future remote catalog must be signed and versioned. The app should activate a new catalog atomically and retain a known-good fallback.

## 13. State management

Do not choose a state-management package before the Flutter spike. Required properties are more important than brand:

- explicit unidirectional state transitions;
- testable view models/controllers;
- cancellation of obsolete image-processing tasks;
- no hidden mutable singleton job state;
- lifecycle-safe handling when the app backgrounds;
- clear distinction between transient UI state and persisted domain state.

Candidate packages can be compared in M1/M2. Avoid adopting a large architecture framework solely because it is popular.

## 14. Concurrency and cancellation

Image work can be expensive. Every long operation should support cancellation or stale-result rejection.

Example:

1. User imports photo A.
2. Analysis A begins.
3. User immediately imports photo B.
4. Result A must never overwrite state for B.

Use a job/revision token to associate asynchronous results with the active `PhotoJob` state.

CPU-heavy pure Dart transforms should be isolated from the UI isolate when profiling requires it. Native ML calls must likewise avoid blocking the UI thread.

## 15. Caching

Cache only where it has measurable UX value.

Potential caches:

- normalized analysis image;
- face detection result;
- segmentation mask;
- low-resolution composed preview.

Cache keys must include source identity/hash, algorithm version, and relevant parameters. A changed segmentation model must not reuse an old incompatible mask.

Sensitive temporary caches must follow retention/deletion policy.

## 16. Persistence

### MVP

Persist only:

- app settings;
- language override;
- recent/favourite profile IDs;
- optional non-sensitive job metadata if resume is implemented;
- installed rule-catalog version.

Do not create a permanent gallery of source faces by default.

### Storage abstraction

Keep persistence behind repositories/interfaces so secure local storage, preferences, or a database can change without leaking into features.

## 17. Backend strategy

MVP should not have a backend unless required for one of these validated needs:

- signed rule catalog updates;
- optional purchase/entitlement verification beyond store-native needs;
- explicitly opt-in diagnostics/support;
- future account/sync service.

A backend is not justified merely to process images that can be processed locally.

## 18. Telemetry

Telemetry must be optional/configurable according to release/legal decisions and privacy-preserving by schema.

Allowed examples:

- app version;
- OS major version;
- device performance tier (not unique fingerprint);
- profile ID/version;
- pipeline stage duration bucket;
- check outcome category;
- export format;
- structured error code.

Forbidden by default:

- image pixels;
- thumbnails;
- face embeddings;
- landmark arrays;
- EXIF GPS;
- local file paths;
- user name/document number;
- arbitrary exception context containing sensitive paths/data.

## 19. Error model

Use typed errors, not user-facing raw exceptions.

Suggested groups:

```text
InputError
PermissionError
DecodeError
FaceDetectionError
SegmentationError
RuleCatalogError
GeometryError
RenderError
EncodeError
PdfError
StorageError
ShareError
```

Each maps to:

- stable internal code;
- safe diagnostic context;
- localized user message;
- recovery actions;
- severity.

## 20. Dependency policy

Before adding a package/SDK, record:

- purpose;
- owner/maintainer;
- latest maintenance signal;
- licence;
- native platforms/permissions;
- transitive dependencies;
- binary-size impact;
- privacy/network behavior;
- replaceability;
- benchmark if performance-critical.

Prefer fewer well-understood dependencies in the image pipeline.

## 21. CI/CD target architecture

After M2:

### Pull request checks

- format/lint;
- static analysis;
- unit tests;
- rules schema + semantic validation;
- golden tests;
- dependency/security checks where configured;
- debug builds for iOS/Android where runners permit.

### Main branch

- all PR checks;
- signed/non-production distributable builds when credentials/infrastructure are configured;
- versioned artifacts;
- release notes generated from accepted process.

### Release candidate

- integration suite;
- physical-device smoke test;
- rule audit;
- export fixture verification;
- print measurement checklist;
- privacy/store checklist.

## 22. Architecture fitness tests

The architecture should be considered healthy if we can:

- swap face detector without changing editor screens;
- add a country profile without changing crop code;
- test crop math without Flutter bindings;
- run rule validation over all profiles in CI;
- run image fixture tests headlessly;
- disable telemetry without breaking application behavior;
- generate the same output geometry from identical input/parameters across supported platforms;
- add another output paper size using configuration/domain logic rather than screen-specific code.

## 23. M1 technical spikes required before architecture lock

### Spike A — Camera/import

Validate capture/import, orientation, permissions, HEIC/JPEG handling, large-image memory behavior.

### Spike B — Face detection

Benchmark at least the strongest practical on-device candidate(s) over a representative fixture set.

### Spike C — Segmentation

Benchmark edge quality, hair, glasses, light/dark backgrounds, diverse skin tones, babies/children where consented fixtures exist, runtime, memory, and model size.

### Spike D — Geometry/export

Produce exact known outputs and compare pixel dimensions/crops byte- or pixel-wise where appropriate.

### Spike E — PDF/print

Generate known physical sizes, inspect PDF page boxes, print at 100%, and physically measure.

### Spike F — Accessibility/editor

Prototype crop gestures plus accessible alternative controls and screen-reader semantics.

### Spike G — Performance

Measure memory and latency on one lower-tier and one current representative device per platform if available.

Only after these spikes should `docs/10-decisions.md` mark the core stack and ML implementations as accepted.
