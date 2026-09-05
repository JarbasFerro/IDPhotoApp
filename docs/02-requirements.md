# 02 — Native iOS requirements

This document defines functional and non-functional requirements for the iPhone product. IDs are stable references for design, code, tests, issues, and release gates.

Priorities:

- **P0** — required for MVP/release viability.
- **P1** — strong quality target; may move only through an explicit decision.
- **P2** — post-MVP/optional.

A requirement is not complete until its acceptance criteria are testable.

---

## 1. Platform and app launch

### FR-001 — Native iPhone application — P0

The production app is implemented natively in Swift/SwiftUI for iOS.

Acceptance:

- no Flutter/React Native/cross-platform runtime;
- app launches on supported physical iPhones;
- production UI uses SwiftUI first, with UIKit bridging only where Apple has no appropriate SwiftUI surface or a framework boundary requires it.

### FR-002 — Launch without account — P0

The user can enter the core app without registration or login.

### FR-003 — First-use privacy explanation — P0

Explain that the normal workflow processes identity photos locally on iPhone.

Acceptance:

- concise plain-language explanation;
- detailed Privacy/About view accessible later;
- no permission requested before a feature needs it.

### FR-004 — Optional onboarding — P1

Onboarding can be skipped and must not block the first core task.

---

## 2. Country and document selection

### FR-010 — Country/jurisdiction selection — P0

Select a jurisdiction from the published rule catalog.

### FR-011 — Document/use-case selection — P0

Show supported document profiles such as passport, visa, national ID, residence permit, licence, and clearly labelled non-official formats.

### FR-012 — Native search — P1

Use current SwiftUI/iOS search behavior to search localized country/document names and common aliases.

### FR-013 — Recent/favorite profiles — P1

Store recent/favorite profile IDs locally without storing face photos by default.

### FR-014 — Requirement preview — P0

Before acquisition, show the small set of requirements most useful for taking/selecting a good source photo.

### FR-015 — Source/provenance view — P0

Every official profile exposes authority/source, source URL/reference, rule version, and last-reviewed date.

### FR-016 — Unsupported profile handling — P0

Never silently substitute a similar official standard. Generic sizing, if supported, is clearly non-validated.

---

## 3. Camera acquisition

### FR-020 — AVFoundation guided camera — P0

Provide native camera capture using AVFoundation.

Acceptance:

- authorization requested only after `Take Photo`;
- denied/restricted states offer useful recovery;
- preview appears promptly on physical test devices;
- capture enters the same normalized pipeline as imports;
- app handles camera interruptions/backgrounding;
- capture does not depend on network.

### FR-021 — Responsive camera — P0

Camera implementation must be instrumented for screen-entry-to-first-frame and shutter-to-result latency.

Performance budgets are set by M1 physical-device measurements.

### FR-022 — Live source guidance — P1

Provide calm real-time guidance only for high-confidence, actionable source-photo conditions.

Possible guidance:

- one face only;
- move closer/farther;
- center/raise/lower device;
- improve lighting;
- hold still.

Acceptance:

- guidance is debounced/hysteretic to prevent flicker;
- it does not claim real-time government compliance;
- VoiceOver users do not receive excessive spoken updates.

### FR-023 — High-resolution still path — P0

Final capture quality is appropriate for document output even when real-time analysis uses a lower-resolution frame stream.

---

## 4. Existing-photo acquisition

### FR-030 — PhotosPicker import — P0

Use PhotosUI/`PhotosPicker` for normal source-photo selection.

Acceptance:

- no broad Photo Library permission is required for selecting one photo;
- cancellation is harmless;
- imported item enters the same pipeline as camera capture.

### FR-031 — Transferable/import handling — P0

Use supported native transfer/file mechanisms to ingest selected content safely.

### FR-032 — Supported formats — P0

Support HEIC/JPEG and other launch-approved image formats. PNG support may be included where useful.

### FR-033 — File validation — P0

Reject unreadable, corrupt, unsupported, or implausibly small inputs with actionable errors.

### FR-034 — Orientation normalization — P0

Normalize visual orientation before analysis while retaining only metadata needed for correct processing.

### FR-035 — Large-image memory safety — P0

Use ImageIO downsampling/bounded analysis representations. Do not fully decode 24/48 MP sources when analysis does not require it.

---

## 5. Source-photo analysis

### FR-040 — Vision face detection — P0

Use Apple Vision as the default face-analysis framework unless M1 demonstrates a material limitation requiring a new ADR.

### FR-041 — Face count — P0

Detect no-face and multiple-face states and block unsafe automatic continuation.

### FR-042 — Domain-normalized face geometry — P0

Convert Vision observations into explicit normalized domain coordinate types immediately after analysis.

### FR-043 — Confidence/measurement uncertainty — P0

Do not treat low-confidence/unstable measurements as precise hard-rule inputs.

### FR-044 — Sharpness/blur screening — P0

Provide calibrated blur/sharpness guidance.

### FR-045 — Exposure screening — P0

Warn about severe under/overexposure where calibration supports useful guidance.

### FR-046 — Resolution sufficiency — P0

Determine whether the source can produce the requested output without unacceptable upscaling.

### FR-047 — Head-size evaluation — P0

Where official rules define measurable head/face occupancy and Vision semantics support it, evaluate against sourced tolerances.

### FR-048 — Head-position evaluation — P0

Where measurable, evaluate vertical/horizontal composition.

### FR-049 — Pose/expression/occlusion advisory — P1

Provide advisory warnings only when evidence supports them. Subjective or low-confidence requirements remain `manual_check`.

### FR-050 — Analysis result model — P0

Every rule/check shown to the user is `pass`, `warn`, `fail`, or `manual_check` with an actionable explanation.

---

## 6. Segmentation and background

### FR-060 — Vision subject segmentation — P0

Use Vision subject/foreground segmentation as the baseline implementation.

### FR-061 — Rule-aware background policy — P0

Do not replace/alter background when the selected document profile disallows or cannot confidently permit it.

### FR-062 — Background replacement — P0

Where permitted, compose an approved background deterministically.

### FR-063 — Edge quality — P0

Preserve identity-bearing foreground detail including hair, ears, glasses edges, and clothing boundaries as reliably as supported.

### FR-064 — Segmentation uncertainty — P0

When automatic quality is inadequate, expose a safe fallback rather than hiding artifacts.

### FR-065 — iOS 27 segmentation refinement — P1

Evaluate and, if useful, implement current Vision tap/scribble/rectangle segmentation refinement for difficult masks.

Acceptance:

- availability-gated;
- iOS 26 fallback exists;
- no dependency of official correctness on the optional API;
- accidental user refinements are reversible.

### FR-066 — Accessible refinement — P1

Where freehand/direct visual refinement is offered, provide a reasonable non-freehand or guided alternative for accessibility where technically possible.

### FR-067 — No identity alteration — P0

Background operations cannot intentionally reshape facial structure, skin, hairline, ears, or other identity-bearing content.

---

## 7. Crop, alignment, and editor

### FR-070 — Rule-derived crop — P0

Generate initial crop from selected `DocumentProfile` and measured subject geometry.

### FR-071 — Exact aspect ratio — P0

Final crop maintains exact required aspect ratio.

### FR-072 — Deterministic geometry — P0

Identical source pixels + profile version + edit parameters produce identical output geometry.

### FR-073 — Automatic alignment — P0

Provide a stable preferred crop/position inside legal constraints where feasible.

### FR-074 — Direct manipulation — P0

Sighted users can drag/pinch to adjust position/scale within allowed render bounds.

### FR-075 — Accessible editor alternatives — P0

Provide non-precision-gesture controls such as move directions, zoom in/out, reset, and clear semantic status.

### FR-076 — Live constraint feedback — P0

Rule status updates during editing after an appropriate bounded debounce.

### FR-077 — Guide overlays — P1

Show only guides that materially help the user understand composition.

### FR-078 — Original preservation — P0

Edits remain parameterized/non-destructive until export.

### FR-079 — Reset — P0

User can restore automatic/original edit state.

---

## 8. Editing policy

### FR-080 — No beautification in official mode — P0

No face reshaping, eye enlargement, synthetic makeup, beautification smoothing, wrinkle removal, hair reconstruction, clothing replacement, or generative facial editing.

### FR-081 — Limited tonal correction — P1

Brightness/white-balance/contrast normalization may be introduced only if it preserves appearance and product/rule policy approves it.

### FR-082 — Before/after — P1

Allow comparison without confusing source, preview, and final export.

---

## 9. Digital export

### FR-090 — Exact pixel dimensions — P0

When specified, encoded output matches exact required width/height.

### FR-091 — Physical size/resolution conversion — P0

Physical dimensions + PPI/DPI expectations convert deterministically with one documented rounding policy.

### FR-092 — File format — P0

JPEG baseline; PNG/other launch-approved formats only where appropriate.

### FR-093 — File-size constraints — P1

When a profile defines byte-size constraints, optimize encoding without altering dimensions or needlessly degrading quality.

### FR-094 — Color handling — P1

Export in a deliberately selected compatible color space/profile and test real output.

### FR-095 — Metadata stripping — P0

Remove unnecessary sensitive metadata, including geolocation.

### FR-096 — Post-export verification — P0

Re-open/inspect generated output and verify dimensions/format/metadata invariants before success state.

### FR-097 — Native share/save — P0

Use `Transferable`, `ShareLink`, system share/save surfaces, or native destination APIs rather than a custom file browser.

### FR-098 — No surprise watermark — P0

No watermark unless disclosed before the user invests effort.

---

## 10. Print-sheet export

### FR-100 — Paper selection — P0

Support a deliberate first set of common photo/paper sizes.

### FR-101 — Physical-size accuracy — P0

Placed photos are mathematically correct at 100% print scale.

### FR-102 — Layout packing — P0

Fit requested copies while respecting margins, gutters, orientation, and cut guides.

### FR-103 — Copy count — P1

Allow requested copy count where practical.

### FR-104 — Core Graphics PDF — P0

Generate PDF using an implementation that preserves exact page geometry; Core Graphics is the preferred baseline.

### FR-105 — Native print UI — P0

Use native iOS printing interface where printing directly from the app is supported.

### FR-106 — Actual Size warning — P0

Clearly instruct users about Actual Size / 100% and scaling risk when leaving the app’s controlled print path.

### FR-107 — Physical calibration — P0

Release QA prints and physically measures representative sheets.

---

## 11. Rules/content

### FR-110 — Versioned rule profiles — P0

Each profile has stable ID/version.

### FR-111 — Provenance — P0

Official profiles contain authoritative source metadata and last-reviewed date.

### FR-112 — Effective dates — P1

Schema supports effective date ranges.

### FR-113 — Localized rule text — P0

Profile names/instructions/warnings are localized independently from numeric values.

### FR-114 — Rule validation — P0

Schema and semantic errors fail CI/production publication safely.

### FR-115 — Rule capability level — P0

Each rule is classified as machine-hard, machine-advisory, manual, informational, or unsupported for the current implementation.

### FR-116 — Future signed remote catalog — P1 architecture / deferred feature

Architecture supports a signed/validated/atomic remote update mechanism without requiring it for MVP.

---

## 12. iOS design-system behavior

### NFR-UI-001 — Current HIG alignment — P0

Navigation, sheets, menus, search, alerts, toolbars, permission timing, and common controls follow current Human Interface Guidelines unless an explicit design decision documents a deviation.

### NFR-UI-002 — SwiftUI standard controls first — P0

Before introducing a custom control, document why the system control cannot meet the task.

### NFR-UI-003 — Liquid Glass by inheritance — P0

Build against the current SDK and allow standard SwiftUI components to adopt current Liquid Glass behavior naturally.

Do not build a custom app-wide “glass theme.”

### NFR-UI-004 — Custom glass restraint — P0

Custom `glassEffect` is used only when it improves interaction/hierarchy and remains accessible under Reduce Transparency/Increase Contrast.

### NFR-UI-005 — Content-first photo surfaces — P0

Camera/photo/editor content remains visually dominant over navigation chrome.

### NFR-UI-006 — System typography/symbols — P0

Use system typography and SF Symbols unless a domain-specific custom asset has a clear need.

### NFR-UI-007 — Haptic restraint — P1

Use system sensory feedback only for meaningful events such as alignment/success; no continuous decorative haptics.

---

## 13. Accessibility

### NFR-A11Y-001 — VoiceOver core flow — P0

A VoiceOver user can complete the core workflow without a known avoidable blocker.

### NFR-A11Y-002 — Voice Control — P0

Primary controls have distinct, discoverable spoken labels.

### NFR-A11Y-003 — Dynamic Type — P0

Surrounding UI supports accessibility text sizes without hiding primary actions.

### NFR-A11Y-004 — Status independent from color — P0

Pass/warn/fail/manual states use symbols/text, not color alone.

### NFR-A11Y-005 — Reduce Motion — P0

Important transitions remain understandable with Reduce Motion enabled.

### NFR-A11Y-006 — Contrast/transparency — P0

UI remains usable with increased contrast and reduced transparency.

### NFR-A11Y-007 — Editor equivalence — P0

Crop/position can be adjusted without relying solely on pinch/drag.

---

## 14. Localization

### NFR-I18N-001 — String Catalogs — P0

Production strings use `.xcstrings` from first implementation.

### NFR-I18N-002 — Long text — P0

Layouts survive materially longer translations.

### NFR-I18N-003 — RTL structural readiness — P1

Architecture does not hard-code left/right layout assumptions that block RTL.

### NFR-I18N-004 — Foundation formatting — P0

Measurements/numbers/dates use appropriate Foundation formatting rather than manual string concatenation.

---

## 15. Privacy and local data

### NFR-PRIV-001 — Local processing — P0

Core image processing remains on-device.

### NFR-PRIV-002 — Privacy manifest — P0

Production target includes valid `PrivacyInfo.xcprivacy` and accurately describes applicable data/API use.

### NFR-PRIV-003 — Required-reason API accuracy — P0

Any required-reason APIs used by app/dependencies are declared using approved reasons matching actual behavior.

### NFR-PRIV-004 — No unnecessary Photos permission — P0

PhotosPicker covers normal import; broad library access is not requested without a new feature need.

### NFR-PRIV-005 — Sensitive temporary lifecycle — P0

Temporary images/masks are private, protected, cleaned, and excluded from backup where ephemeral.

### NFR-PRIV-006 — No hidden upload — P0

No source/derived image upload occurs in the core flow.

### NFR-PRIV-007 — Telemetry minimization — P0

No image pixels, thumbnails, face embeddings/landmarks, GPS, sensitive paths, names, or document numbers in telemetry/logs.

---

## 16. Concurrency, performance, reliability

### NFR-PERF-001 — Main-actor responsiveness — P0

Heavy decode/Vision/segmentation/render work does not block the main actor enough to create visible hangs.

### NFR-PERF-002 — Bounded memory — P0

Large source images use bounded analysis decoding and memory-safe final rendering.

### NFR-PERF-003 — Physical-device budgets — P0

M1 establishes measurable latency/memory/thermal budgets on representative iPhones.

### NFR-PERF-004 — Instruments verification — P0

Performance-sensitive changes are verified with Instruments rather than Simulator timing/subjective feel alone.

### NFR-CONC-001 — Swift 6 concurrency safety — P0

Use Swift 6 language mode/strict concurrency with clear actor boundaries and `Sendable` correctness.

### NFR-CONC-002 — Cancellation/stale result protection — P0

Replacing a photo/profile or leaving a workflow cannot allow obsolete async results to overwrite current state.

### NFR-REL-001 — Offline core flow — P0

Shipped profiles + capture/import/process/export work without network.

### NFR-REL-002 — Source crash safety — P0

Failures never overwrite/corrupt source.

### NFR-REL-003 — Interruption recovery — P0

Camera and processing handle app lifecycle/system interruptions with understandable recovery.

### NFR-REL-004 — iOS support policy — P0

Minimum deployment target is explicitly decided after M1; current proposal is iOS 26 with iOS 27 APIs availability-gated.

---

## 17. State architecture

### NFR-ARCH-001 — Observation — P0

Use SwiftUI/Observation (`@Observable`) for UI-facing feature state.

### NFR-ARCH-002 — Domain independence — P0

Pure geometry/rules/validation do not depend on SwiftUI/AVFoundation/PhotosUI/UIKit.

### NFR-ARCH-003 — No third-party architecture by default — P0

Do not adopt TCA/Redux/DI frameworks without a demonstrated problem and ADR.

### NFR-ARCH-004 — Apple-frameworks-first dependency policy — P0

Every third-party dependency records why first-party APIs are insufficient plus privacy/license/maintenance/performance/removal analysis.

---

## 18. App Intents and system integration

### FR-120 — Create-ID-photo App Intent — P1

Expose a simple intent/shortcut that starts the core workflow.

### FR-121 — Open-profile App Intent — P1

Allow selecting/opening a known document profile through system experiences where useful.

### FR-122 — Sensitive entity restriction — P0

Personal photos, face geometry, and sensitive file paths are not broadly indexed App Entities.

### FR-123 — Core Spotlight profiles — P1

Supported document profiles may be indexed for safe system search discovery.

### NFR-INTENT-001 — App Intents testing — P1

Adopt AppIntentsTesting/current Apple validation tools for shipped intents where applicable.

---

## 19. Optional Foundation Models / intelligence

### FR-130 — AI is optional — P2

No generative model is required for the core workflow.

### FR-131 — Allowed AI roles — P2

Potential uses are explanation/coaching/natural-language profile selection.

### FR-132 — AI cannot define compliance — P0

Foundation Models/cloud models cannot set official dimensions, crop geometry, or authoritative pass/fail results.

### FR-133 — Model-unavailable fallback — P0 if AI ships

Core feature remains complete when the model is unavailable.

### FR-134 — Controlled evaluation — P0 if AI ships

Evaluate for invented rules, contradictions, accuracy, latency, and privacy before release.

### FR-135 — Cloud AI requires new ADR — P0

No silent Private Cloud Compute/external provider fallback involving sensitive image data.

---

## 20. Testing and observability

### NFR-TEST-001 — Swift Testing — P0

Use Swift Testing for new domain/unit/integration suites where suitable.

### NFR-TEST-002 — XCUITest — P0

Automate stable primary/error/deep-link UI flows.

### NFR-TEST-003 — Fixture/golden image tests — P0

Critical render/export transformations have controlled non-sensitive fixtures.

### NFR-TEST-004 — Physical print tests — P0

Dimensionally relevant print changes are physically measured.

### NFR-TEST-005 — Accessibility audits — P0

Release candidate includes VoiceOver/Voice Control/Dynamic Type/motion/contrast testing.

### NFR-OBS-001 — Unified logging — P0

Use privacy-safe `Logger`/OSLog diagnostics.

### NFR-OBS-002 — Signposts — P0

Instrument critical camera/image/export intervals.

### NFR-OBS-003 — MetricKit decision — P1

Evaluate Apple-native production diagnostics before adding third-party monitoring.

---

## 21. Security

### NFR-SEC-001 — No secrets in repository — P0

Signing/API/service credentials are never committed.

### NFR-SEC-002 — Dependency review — P0

Review all non-Apple code for security/privacy/supply-chain risk.

### NFR-SEC-003 — Signed remote rules — P0 if remote rules ship

Remote catalog authenticity/integrity must be cryptographically verified with rollback/fallback.

### NFR-SEC-004 — Malformed image resilience — P0

Image ingest validates headers/dimensions and avoids unbounded allocation.

---

## 22. App Store/release

### NFR-REL-010 — App Store privacy accuracy — P0

App Privacy answers/privacy policy/privacy manifest match actual binary/runtime behavior.

### NFR-REL-011 — Release toolchain — P0

Production submission uses an App Store-accepted non-beta Xcode version.

### NFR-REL-012 — Icon Composer — P0

Final app icon is built/tested using current Apple icon tooling.

### NFR-REL-013 — SF Symbols audit — P0

Use system symbols for standard actions unless a custom domain icon is justified.

### NFR-REL-014 — TestFlight gate — P0

Release passes internal/external TestFlight quality validation before production.

---

## 23. Global definition of done

A production feature is complete only when relevant requirements above are satisfied and:

- happy/error/cancellation states exist;
- current HIG/native-control review is complete;
- accessibility equivalent exists;
- localization is complete;
- privacy/data flow is reviewed;
- concurrency/cancellation behavior is tested;
- physical-device behavior is verified when hardware/performance relevant;
- iOS 26/iOS 27 availability behavior is verified where applicable;
- documentation/ADRs are updated after foundational changes.