# 09 — Native iOS ordered implementation backlog

## 1. How to use this backlog

This is the execution order for the iPhone product. Convert items into GitHub issues as work becomes active.

Priority:

- **P0** — required for MVP/release viability.
- **P1** — strong quality target.
- **P2** — post-MVP/optional.

Size:

- **S** — small/self-contained.
- **M** — moderate.
- **L** — large/cross-cutting.
- **XL** — research/architecture-heavy.

The architecture is now fixed at the platform level: native Swift/SwiftUI. M1 validates implementations, limits, and performance rather than reconsidering Flutter/Android.

---

# EPIC 0 — Product/platform lock

## P0-001 — Confirm native iOS scope — P0 / S

Done when:

- iPhone/iOS-only scope accepted;
- Android/cross-platform removed from active plans;
- ADR-001 Accepted;
- Apple-frameworks-first policy Accepted.

## P0-002 — Select launch rule-research shortlist — P0 / M

Choose a deliberately small set of high-demand jurisdictions/document profiles.

Acceptance:

- authoritative sources identifiable;
- at least one digital workflow;
- at least one physical print workflow where practical;
- child/baby scope explicit per profile.

## P0-003 — Lock compliance wording — P0 / S

Define Ready, Needs Review, Retake Recommended, and Manual Check wording.

No UI may imply guaranteed government acceptance.

## P0-004 — Decide generic/custom sizes MVP scope — P1 / S

## P0-005 — Decide monetization direction — P1 / S

StoreKit only if monetization is introduced; guardrails remain mandatory.

---

# EPIC 1 — M1 native technical spikes

## S1-001 — Bootstrap disposable Xcode 27 spike app — P0 / M

Acceptance:

- native SwiftUI app;
- Swift 6 language mode;
- physical iPhone run;
- no production architecture assumption;
- spike results documented.

## S1-002 — AVFoundation responsive camera spike — P0 / XL

Dependencies: S1-001.

Build/test:

- camera permission at point of use;
- fast session startup;
- preview;
- still capture;
- high-resolution path;
- orientation;
- interruptions/backgrounding;
- repeated entry/exit;
- camera unavailable;
- memory/thermal behavior.

Instrument first-frame and shutter-to-result latency.

## S1-003 — PhotosPicker + Transferable ingest spike — P0 / L

Dependencies: S1-001.

Test:

- no broad library permission;
- HEIC/JPEG/PNG;
- orientation;
- large 24/48 MP images;
- ImageIO downsampling;
- temp/private lifecycle;
- cancellation.

## S1-004 — Vision face benchmark harness — P0 / L

Dependencies: S1-001.

Output:

- face count;
- normalized geometry;
- available landmarks/pose;
- latency;
- errors;
- fixture IDs/tags.

No private images in public repo.

## S1-005 — Benchmark Vision face analysis — P0 / XL

Dependencies: S1-004.

Acceptance:

- reliable observations selected;
- hard vs advisory check limitations documented;
- child/baby evidence noted;
- normalized mapping defined.

## S1-006 — Vision segmentation benchmark harness — P0 / L

## S1-007 — Benchmark automatic segmentation — P0 / XL

Dependencies: S1-006.

Cover hair, glasses, head coverings, shoulders, skin/background contrast, child/baby scenarios.

## S1-008 — iOS 27 segmentation-refinement spike — P1 / L

Dependencies: S1-007.

Prototype tap/scribble/rectangle refinement.

Acceptance:

- user value proven;
- iOS 26 fallback defined;
- accessibility alternative considered;
- performance recorded.

## S1-009 — Core Image/ImageIO render spike — P0 / XL

Prove:

- bounded decode;
- reused CIContext;
- working-resolution preview;
- high-resolution render;
- deterministic crop;
- background composition;
- metadata/color handling;
- memory stability.

## S1-010 — Core Graphics PDF/print spike — P0 / L

Dependencies: S1-009.

Acceptance:

- exact page geometry;
- exact photo placement;
- native print path;
- physical measurement at 100%.

## S1-011 — SwiftUI editor/accessibility spike — P0 / XL

Prototype:

- full-bleed photo canvas;
- drag/pinch;
- live guides;
- system toolbar/floating controls;
- VoiceOver adjustable/directional controls;
- Voice Control labels;
- Dynamic Type;
- Reduce Motion;
- increased contrast;
- current Liquid Glass behavior.

## S1-012 — App Intent proof — P1 / M

Prototype `Create ID Photo` / open profile.

Ensure no sensitive photo data exposed.

## S1-013 — Optional Foundation Models proof — P2 / L

Only if a concrete problem is selected.

Test structured warning explanation or profile selection. Controlled evaluation required.

## S1-014 — Physical-device performance baseline — P0 / L

Dependencies: S1-002, S1-003, S1-005, S1-007, S1-009.

Test older supported + current iPhone.

Record:

- app/camera startup;
- Vision latency;
- segmentation;
- preview;
- final render;
- PDF;
- peak memory;
- thermal behavior.

## S1-015 — Finalize deployment target ADR — P0 / S

Dependencies: S1-014.

Current proposal: iOS 26 minimum, compile with iOS 27 SDK, availability-gate iOS 27 features.

## S1-016 — Lock M1 implementation ADRs — P0 / M

Dependencies: S1-002 through S1-015.

Update ADR-003/004/005/024/034 and performance budgets.

---

# EPIC 2 — Production SwiftUI foundation

## F2-001 — Bootstrap production iOS app — P0 / M

Dependencies: S1-016.

Acceptance:

- SwiftUI app target;
- Swift 6 mode;
- selected minimum iOS;
- signing/bundle ID setup;
- unit/UI test targets;
- physical device launch.

## F2-002 — Add PrivacyInfo.xcprivacy — P0 / S

Dependencies: F2-001.

Start valid and minimal; update with actual APIs/dependencies.

## F2-003 — Add String Catalog/localization foundation — P0 / M

## F2-004 — Establish Observation/AppEnvironment pattern — P0 / M

Use `@Observable`, initializer injection, typed environment only where appropriate.

## F2-005 — Establish domain/module boundaries — P0 / M

No SwiftUI import in pure domain geometry/rules.

## F2-006 — Implement typed error model — P0 / M

## F2-007 — Implement structured privacy-safe logging/signposts — P0 / M

## F2-008 — Configure navigation shell — P0 / M

Use native `NavigationStack` unless product testing demonstrates another structure.

## F2-009 — Configure Xcode Cloud or CI — P0 / L

Checks:

- build;
- Swift Testing;
- rule validation placeholder;
- localization;
- privacy manifest;
- dependency-lock review.

## F2-010 — Establish Apple dependency review template — P0 / S

Every third-party package must explain why Apple APIs are insufficient.

## F2-011 — Establish current-HIG UI review checklist — P0 / S

---

# EPIC 3 — Domain geometry and job model

## D3-001 — Coordinate-space value types — P0 / L

Types:

- source pixels;
- normalized image;
- preview points;
- output pixels;
- physical millimetres;
- PDF points.

## D3-002 — Physical conversion/rounding policy — P0 / M

## D3-003 — Aspect/crop primitives — P0 / L

## D3-004 — `PhotoJob` immutable-source model — P0 / M

## D3-005 — `EditParameters` — P0 / M

## D3-006 — validation state model — P0 / M

`pass / warn / fail / manual_check`.

## D3-007 — print-grid geometry — P0 / L

## D3-008 — Swift Testing parameterized boundary suite — P0 / M

---

# EPIC 4 — Image acquisition and lifecycle

## I4-001 — SourceAsset abstraction — P0 / S

## I4-002 — PhotosPicker production import — P0 / L

Dependencies: I4-001, S1-003.

## I4-003 — AVFoundation camera controller — P0 / XL

Dependencies: I4-001, S1-002, ADR-034.

Include authorization, lifecycle, interruptions, capture and instrumentation.

## I4-004 — Camera SwiftUI presentation/preview bridge — P0 / L

## I4-005 — Image header/type validation — P0 / M

## I4-006 — ImageIO orientation + bounded decode — P0 / L

## I4-007 — Private source/temp lifecycle + file protection — P0 / L

## I4-008 — stale-source cleanup — P0 / M

---

# EPIC 5 — Vision and quality analysis

## A5-001 — Vision face analyzer adapter — P0 / L

## A5-002 — Normalize Vision observations to domain geometry — P0 / M

## A5-003 — no-face/multiple-face states — P0 / M

## A5-004 — source resolution check — P0 / M

## A5-005 — blur/sharpness calibration — P0 / L

## A5-006 — exposure calibration — P0 / L

## A5-007 — pose/rotation advisory — P1 / L

Only if evidence supports it.

## A5-008 — analysis orchestrator with cancellation/revision — P0 / XL

## A5-009 — OSLog signposts and Instruments benchmark hooks — P0 / M

---

# EPIC 6 — Segmentation/background

## B6-001 — Vision segmentation adapter — P0 / L

## B6-002 — mask representation/cache lifecycle — P0 / L

## B6-003 — Core Image background compositor — P0 / L

## B6-004 — segmentation uncertainty/failure path — P0 / M

## B6-005 — iOS 27 refinement interaction — P1 / XL

Dependencies: S1-008.

Availability-gated with iOS 26 fallback.

## B6-006 — accessible refinement alternative — P1 / L

## B6-007 — segmentation regression fixture suite — P0 / L

---

# EPIC 7 — Rules engine

## R7-001 — canonical schema — P0 / L

## R7-002 — schema validator — P0 / M

## R7-003 — semantic validator — P0 / L

## R7-004 — typed Swift rule loader — P0 / L

## R7-005 — provenance model — P0 / M

## R7-006 — evaluator registry — P0 / L

## R7-007 — output-dimension evaluator — P0 / M

## R7-008 — head-size evaluator — P0 / L

## R7-009 — head-position evaluator — P0 / L

## R7-010 — resolution evaluator — P0 / M

## R7-011 — manual-check rules — P0 / M

## R7-012 — background policy — P0 / M

## R7-013 — automatic crop solver — P0 / XL

## R7-014 — initial official profiles — P0 / XL

## R7-015 — rules CI validation — P0 / M

---

# EPIC 8 — Rendering/editor engine

## E8-001 — Core Image preview renderer — P0 / L

## E8-002 — high-resolution final renderer — P0 / XL

## E8-003 — direct manipulation crop/position gestures — P0 / L

## E8-004 — VoiceOver/non-gesture position controls — P0 / L

## E8-005 — live rule feedback during edit — P0 / L

## E8-006 — guide overlays — P1 / M

## E8-007 — reset/automatic composition — P0 / S

## E8-008 — limited tonal correction only if approved — P1 / L

No beautification.

---

# EPIC 9 — Signature camera guidance

## C9-001 — define real-time guidance rules — P0 / L

Only high-confidence, actionable guidance.

## C9-002 — low-resolution Vision frame analysis — P0 / L

## C9-003 — debounce/hysteresis guidance — P0 / M

No flickering messages.

## C9-004 — accessible spoken guidance policy — P0 / M

Avoid VoiceOver spam.

## C9-005 — camera visual overlay polish — P0 / L

Content first, minimal chrome.

## C9-006 — camera performance/energy regression tests — P0 / L

---

# EPIC 10 — Main SwiftUI UX

## U10-001 — Home — P0 / M

## U10-002 — searchable country/document picker — P0 / L

## U10-003 — requirements summary — P0 / M

## U10-004 — capture/import decision — P0 / M

## U10-005 — analysis transition — P0 / S

## U10-006 — Photo Check — P0 / L

## U10-007 — editor screen — P0 / XL

## U10-008 — export choice — P0 / S

## U10-009 — digital export UI — P0 / M

## U10-010 — print setup UI — P0 / L

## U10-011 — source/provenance detail — P0 / M

## U10-012 — Help/Settings/Privacy — P0 / M

## U10-013 — recent/favorite profiles — P1 / M

## U10-014 — complete error/empty/interruption state pass — P0 / XL

## U10-015 — current Liquid Glass/HIG review — P0 / M

## U10-016 — full accessibility pass — P0 / XL

VoiceOver, Voice Control, Dynamic Type, Reduce Motion, contrast, non-color state.

## U10-017 — task-based usability test — P0 / L

---

# EPIC 11 — Digital export

## X11-001 — exact JPEG encode — P0 / L

## X11-002 — PNG where required — P1 / M

## X11-003 — metadata stripping — P0 / M

## X11-004 — file-size constraint loop — P1 / L

## X11-005 — post-export verification — P0 / M

## X11-006 — Transferable/ShareLink native share path — P0 / M

## X11-007 — save destination behavior — P0 / M

---

# EPIC 12 — Print/PDF

## P12-001 — Core Graphics PDF renderer — P0 / L

## P12-002 — page/copy layout — P0 / L

## P12-003 — cut guides — P1 / M

## P12-004 — native print interaction — P0 / M

## P12-005 — physical size QA — P0 / L

## P12-006 — user Actual Size guidance — P0 / S

---

# EPIC 13 — App Intents / Spotlight

## AI13-001 — `CreateIDPhotoIntent` — P1 / M

## AI13-002 — `OpenDocumentProfileIntent` — P1 / M

## AI13-003 — App Shortcut phrases/localization — P1 / M

## AI13-004 — Core Spotlight document-profile indexing — P1 / M

## AI13-005 — AppIntentsTesting + privacy review — P1 / M

No personal photos/face-derived data indexed.

---

# EPIC 14 — Optional intelligent assistance

## FM14-001 — select one concrete user problem — P2 / S

If no strong problem exists, close epic as deferred.

## FM14-002 — structured Foundation Models prototype — P2 / L

## FM14-003 — model-unavailable fallback — P2 / M

## FM14-004 — controlled evaluation suite — P2 / L

## FM14-005 — privacy/authority UX review — P2 / M

Generative output never creates official rule results.

---

# EPIC 15 — Accessibility excellence

## AX15-001 — VoiceOver core-flow audit — P0 / L

## AX15-002 — Voice Control audit — P0 / M

## AX15-003 — Dynamic Type accessibility-size audit — P0 / L

## AX15-004 — Reduce Motion/Transparency audit — P0 / M

## AX15-005 — Increased Contrast/Color differentiation audit — P0 / M

## AX15-006 — editor accessibility task test — P0 / L

---

# EPIC 16 — Privacy/security

## PS16-001 — privacy manifest validation — P0 / M

## PS16-002 — required-reason API audit — P0 / M

## PS16-003 — runtime network inspection — P0 / M

## PS16-004 — temp/file-protection verification — P0 / M

## PS16-005 — EXIF/GPS stripping tests — P0 / M

## PS16-006 — dependency privacy/security audit — P0 / M

## PS16-007 — App Privacy answers draft + binary reconciliation — P0 / M

---

# EPIC 17 — Performance/reliability

## PR17-001 — signpost coverage for critical intervals — P0 / M

## PR17-002 — Instruments baseline — P0 / L

## PR17-003 — memory pressure / 48 MP stress — P0 / L

## PR17-004 — repeated camera thermal/energy stress — P0 / L

## PR17-005 — Swift Concurrency race/stale-result audit — P0 / L

## PR17-006 — hang/responsiveness audit — P0 / M

## PR17-007 — MetricKit decision — P1 / S

---

# EPIC 18 — App Store release

## AS18-001 — final name/brand lock — P0 / M

## AS18-002 — Icon Composer app icon — P0 / M

## AS18-003 — SF Symbols/custom icon audit — P0 / S

## AS18-004 — App Store screenshots/story — P0 / L

## AS18-005 — privacy policy/support page — P0 / M

## AS18-006 — StoreKit products if monetized — P1 / L

## AS18-007 — TestFlight internal QA — P0 / L

## AS18-008 — TestFlight external/usability validation — P0 / L

## AS18-009 — final rule provenance audit — P0 / M

## AS18-010 — final accessibility/performance/privacy gates — P0 / L

## AS18-011 — App Store submission — P0 / M

Use App Store-accepted non-beta Xcode toolchain.

## AS18-012 — phased launch / monitoring — P0 / M

---

# 2. Critical path

```text
P0-001
→ S1-001
→ S1-002 / S1-003 / S1-004 / S1-006 / S1-009 / S1-011
→ S1-014
→ S1-015 / S1-016
→ F2-001
→ D3 + I4
→ A5 + B6
→ R7
→ E8 + C9
→ U10
→ X11 + P12
→ AX15 + PS16 + PR17
→ AS18
```

App Intents can progress after the navigation/domain model stabilizes. Optional Foundation Models work is deliberately outside the critical path.

# 3. Definition of done for every iOS feature

A feature is done only when relevant items are true:

- acceptance criteria tested;
- current HIG/native control review completed;
- VoiceOver/Voice Control semantics present;
- Dynamic Type considered;
- Reduce Motion/contrast considered;
- no unnecessary permission;
- privacy/logging reviewed;
- async cancellation/stale state handled;
- physical-device behavior verified when hardware/performance relevant;
- Instruments review for performance-sensitive code;
- localization/String Catalog complete;
- iOS 26/iOS 27 availability behavior tested if applicable;
- documentation/ADR updated if a foundational choice changed.
