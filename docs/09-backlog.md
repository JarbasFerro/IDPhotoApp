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

Selected on 2026-09-15: **Spain — foto carnet, width 26 mm × height 32 mm** (ADR-016). Use DNI as the first official research reference; see [source review](13-spain-foto-carnet.md). Source validation and child/baby scope remain open; selection alone does not complete this item.

Acceptance:

- authoritative sources identifiable;
- digital file export workflow, with no implied official online-submission support;
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

Implementation started 2026-09-16: [native prototype and test targets](../Spikes/IDPhotoSpike/README.md) are present. Simulator validation is recorded in [spike 01](spikes/01-import-crop-export.md); physical-device launch remains open.

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

## S1-017 — Face geometry and crown estimator benchmark — P0 / L

Dependencies: S1-004. Design: [14-priority-feature-plan.md §3.8](14-priority-feature-plan.md). Implemented 2026-09-16 with a macOS fixture harness and automatic alignment in the spike editor; see [spike 03](spikes/03-face-alignment.md). Device run and a wider fixture corpus remain open.

Acceptance:

- pinned landmark/rectangle revisions produce identical geometry on iOS 26 and 27;
- fused crown (mask + anthropometric) median error documented against labelled fixtures;
- failure-mode fixtures (tall hair, head covering, bald, beard, infant, tilt, glasses) each map to a defined state.

## S1-018 — Segmentation, composition, and iOS 27 refinement — P0 / XL

Dependencies: S1-006. Supersedes the scope split of S1-007/S1-008 by evaluating them together. Design: [14-priority-feature-plan.md §3.6](14-priority-feature-plan.md). Automatic mask, quality score, original-background assessment, and white replacement implemented 2026-09-16; see [spike 04](spikes/04-background-replacement.md). iOS 27 tap-to-refine, the accessible refinement alternative, and hard-case fixtures (long hair, glasses, busy background) remain open.

Acceptance:

- foreground-instance vs person-segmentation `.accurate` quality rubric documented;
- mask uncertainty score defined with pass/warn/fallback thresholds;
- `GenerateIterativeSegmentationRequest` include/exclude taps prototyped with asset download handling and an iOS 26 fallback;
- compositor leaves face-region pixels untouched.

## S1-019 — Print composer spike — P0 / L

Dependencies: S1-010. Design: [14-priority-feature-plan.md §3.1–3.5](14-priority-feature-plan.md). Implemented 2026-09-16 in the spike app; see [spike 02](spikes/02-print-composer.md). Several people per sheet in the UI landed in version 0.7.0. Physical measurement and AirPrint paper-list evidence remain open.

Acceptance:

- guillotine row solver passes the parameterized count table;
- PDF and 300 ppi JPEG sheets render ticks, adaptive bleed, and calibration bar;
- AirPrint `choosePaper` behaviour recorded for bordered vs borderless papers;
- physical measurement on two printers (10 × 15 and A4) recorded with tolerance.

## S1-020 — Camera with iOS 26 capture features — P0 / XL

Dependencies: S1-002. Evaluate Deferred Start, responsive capture, `maxPhotoDimensions`, `.onCameraCaptureEvent`, front-camera dynamic aspect ratio on iPhone 17, and `DetectLensSmudgeRequest` as a pre-capture warning. Guided camera implemented 2026-09-16 (version 0.5.0); capture aids phase 1 (relative head pose, face pitch, distance, lighting, face metering, auto capture) in versions 0.8.0 and 0.8.1; see [spike 05](spikes/05-guided-camera.md). All hardware evidence (first frame, shutter latency, orientation, interruptions, thermal) must come from the physical iPhone.

## S1-021 — Document Tone and Studio Light check — P1 / M

Dependencies: S1-009. Measure identity preservation and clipping for the auto-adjust chain; confirm on device that the Studio Light Info.plist opt-in does not affect stills. Design: [14-priority-feature-plan.md §2.1, §3.7](14-priority-feature-plan.md). Document Tone implemented 2026-09-16 (version 0.6.0) with synthetic and harness measurements; see [spike 06](spikes/06-document-tone.md). Studio Light confirmed unavailable to photo sessions on device (0.6.1). Open: warm-light evidence.

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

## D3-007 — print layout solver — P0 / L

Replaces the fixed grid: `PaperSize`, `PrintJob`, `PrintLayoutSolver`, adaptive bleed, overflow paging, fill strategies (FR-140–FR-146).

## D3-008 — Swift Testing parameterized boundary suite — P0 / M

## D3-009 — Face geometry and crop solution types — P0 / M

`FaceGeometry` with crown method/confidence, `CropSolution` with residuals, rotation in `EditParameters` (FR-153–FR-155).

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

## B6-008 — opportunistic capture/HEIC mattes — P1 / M

Read hair/skin/portrait mattes from `AVCapturePhoto` and ImageIO auxiliary data as a prior; never a dependency.

## B6-009 — original-background compliance check — P1 / M

Measure uniformity/colour of the original background and recommend "Original" when it already satisfies the profile.

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

## R7-016 — background colour, contrast, and alteration policy fields — P0 / M

## R7-017 — composition bands with crown definition and targets — P0 / M

Head-height band, hard-reject band, target, `crownDefinition`, eye line, top margin, centring; Spain uses labelled ICAO engineering defaults.

## R7-018 — digital submission presets schema — P1 / M

---

# EPIC 8 — Rendering/editor engine

## E8-001 — Core Image preview renderer — P0 / L

## E8-002 — high-resolution final renderer — P0 / XL

## E8-003 — direct manipulation crop/position gestures — P0 / L

## E8-004 — VoiceOver/non-gesture position controls — P0 / L

## E8-005 — live rule feedback during edit — P0 / L

## E8-006 — guide overlays — P1 / M

## E8-007 — reset/automatic composition — P0 / S

## E8-008 — Document Tone — P1 / L

Global, reversible auto-adjust chain with strength and before/after; gated by profile `alterationPolicy` (FR-150–FR-152). No beautification, no relighting.

## E8-009 — fused crown estimator and eye levelling in the crop solver — P0 / L

## E8-010 — crown/chin manual handles with override logging — P0 / M

---

# EPIC 9 — Signature camera guidance

## C9-001 — define real-time guidance rules — P0 / L

Only high-confidence, actionable guidance. Include head-pose hints from roll/yaw/pitch and a lens-smudge warning (iOS 26).

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

## U10-010 — print composer UI — P0 / XL

Person cards with copy steppers (adjustable actions), paper picker, live sheet preview, page indicator, reorder (iOS 27 `reorderable` with Move Up/Down fallback), bleed/marks options, Actual Size guidance.

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

## P12-007 — paper catalog and custom sizes — P0 / M

## P12-008 — sheet renderer: ticks, adaptive bleed, calibration bar — P0 / L

## P12-009 — lab-ready 300 ppi sheet JPEG — P1 / M

## P12-010 — AirPrint `choosePaper` delegate and bordered-paper preference — P0 / M

## P12-011 — overflow paging and fill strategies — P0 / M

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

**Deferred until after 1.0** (ADR-050, founder decision 2026-11-11). The 1.0 baseline in AGENTS.md §6 still applies; the audits below return as the first post-launch accessibility release.

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

# EPIC 19 — Launch differentiators and satisfaction

Added 2026-11-11 from [the product blueprint](20-product-blueprint.md), [user journeys](21-user-journeys.md), and [quality and delight bar](22-quality-and-delight-bar.md). These items close the gap between a correct workflow and the "#1 at-home ID photo and print" goal. Each new screen needs a contract in [doc 16](16-screen-experience-spec.md) before implementation.

## L19-001 — Helper mode: guidance for the person holding the phone — P0 / L

Preflight asks **Who is taking the photo?** (Me / Someone helping). Helper mode defaults to the back camera and words every instruction for the photographer; spoken guidance stays rate-limited. The recommended way to photograph a child (ADR-017). Acceptance: physical-device task test with a helper on both cameras; direction words correct for lens facing and mirroring (ADR-044). Journey J3, function F-15.

## L19-002 — Find a good spot: home setup coaching — P0 / M

A short, illustrated section in preflight and Help: face a window, plain light wall about 0.5–1 m behind you (so your shadow falls out of frame), no strong light behind you, phone at eye level. Live camera keeps "Find more light" and backlight cues. Acceptance: testers can name the setup advice after one read; no more than four tips; no stock-photo faces. Function F-16.

## L19-003 — Print check after printing — P0 / M

After Print, offer **Check your print**: did the 50 mm bar measure 50 mm? Yes ends with the W7 confirmation. No asks for the measured value (Stepper) and diagnoses the likely cause (fit-to-page scaling, borderless paper, wrong paper size), then offers a reprint with corrected settings. Never infer a correct print from the print controller's completion callback; only the person's answer counts, and it is feedback, not certification. Hidden when the check bar was turned off. Acceptance: diagnosis table tested against the printer round; the first-print target in [20 §7](20-product-blueprint.md). Screen S-16, function F-47. Post-launch: read the bar with the camera.

## L19-004 — Cutting guide — P1 / S

Three-step guide drawn from the person's actual layout (cut order: rows, then columns; use the tick marks; scissors or trimmer tips). Acceptance: testers cut a sheet correctly on the first attempt. Screen S-17, function F-48.

## L19-005 — Print at a shop — P1 / S

In Print & Share, a **Print at a shop** path shares the existing 300 ppi lab JPEG (P12-009) with short instructions: order a standard print of that paper size, no cropping or fit, measure the bar. Acceptance: one round of real lab or kiosk prints measured in a launch market. Journey J5, function F-46.

## L19-006 — Credits, unlock confirmation, and restore — P0 / L

Implement ADR-048: a StoreKit consumable at USD 0.99; one free credit in total; a credit ledger with reserve, commit after the first verified output, and release on failure, idempotent per unlock ID; the unlock confirmation (S-18) with open checks, cost or total, and the point-of-no-return sentence; frozen render recipe after unlocking; **Edit photo** creating a new draft with a warning; price in preflight once after the free credit is used and in Settings; a design spike first for balance and free-credit persistence (StoreKit consumable history and the iCloud key-value store); restore in Settings; App Review notes. Acceptance: sandbox and TestFlight tests for purchase, cancel, interruption, pending, Ask to Buy, crash between reserve and commit, reinstall with and without iCloud; no double charge; no path loses edits or a paid photo. Screen S-18, functions F-51, F-52, F-59. Supersedes the conditional wording in AS18-006.

## L19-007 — Blind quality study against photo-shop photos — P0 / L

Run the study in [22 §2.3](22-quality-and-delight-bar.md) twice: once in P4 to guide tuning, once in beta. Consent, storage, and deletion follow ADR-027 and [08](08-privacy-security.md); no photos enter the repository. Acceptance: report with preference rates per skin-tone group and the actions taken.

## L19-008 — Home fresh-install visual and Settings & About — P1 / M

Show what the person will get on first launch (sample result in the 26:32 frame); move App Icon, privacy details, restore, and help into a Settings & About screen (S-19). The `marketing version (build)` line stays on Home as the last, tertiary element (AGENTS.md §17). Acceptance: [22 §3.2](22-quality-and-delight-bar.md) review in Light and Dark.

## L19-009 — Rating request policy — P1 / S

Use `RequestReviewAction` at most once per version, only on a later Home visit after the person confirmed a correct print or shared a digital photo; never on a result, print, or purchase screen. Acceptance: unit-tested eligibility logic; no prompt in the task flow.

## L19-010 — Market ranking, Tier 1 list, and ASO evidence — P0 / M (first)

**Done 2026-11-11:** part 1 [24 — Launch country ranking](24-launch-country-ranking.md) and part 2 [25 — Wave A document types](25-wave-a-document-types.md). ASO keyword research stays open for P9.

First, rank App Store countries by relevance (iPhone users and App Store spending, from a named and dated source) and list, per country, the documents for which people supply their own photo, plus the most-requested visa photos (ADR-047). Output: the Tier 1 list for founder confirmation (D-8). Then complete the research listed in [brand 04 §9](brand/04-market-prioritization.md): competitor ranking per launch country, keyword volumes ("passport photo", "ID photo", "foto carnet", "foto 3x4"), competitor pricing and paywalls, review mining for unmet needs. Output informs ADR-047, the profile research order (L19-013), App Store subtitle and keywords, and screenshots. Acceptance: a dated research document with sources.

## L19-011 — Best-frame burst — P2 / L

Capture a short burst and choose the sharpest frame with open eyes using `DetectFaceCaptureQualityRequest` for ranking only ([14 §5.7](14-priority-feature-plan.md)). Post-launch candidate. Function F-17.

## L19-012 — Drafts and the export gate — P0 / L

Implement ADR-049: automatic drafts (source, recipe, profile, lock state, sheet) in app-private storage with complete file protection, excluded from backups; **Continue** on Home; Delete and Delete all; 30-day retention; one export service for every output path, bound to draft ID and recipe hash; locked previews at display resolution without copy, drag, share, or save. Acceptance: an export-gate test enumerating every output path (digital JPEG, PDF, page JPEG, AirPrint, share sheet, Save to Photos, copy, drag and drop, context menus, App Intents, Quick Look) proves a locked person cannot leave the app; relaunch, low-storage, and locked-device tests; privacy text updated (doc 08). Functions F-60, F-61.

## L19-013 — Tier 1 profile research and validation — P0 / XL

For each profile in [25 §3](25-wave-a-document-types.md), in that order, starting with the alteration policy: one sourced profile document like [13](13-spain-foto-carnet.md) (dimensions, head and eye geometry, background colour, alteration policy, digital submission limits, children's rules, sources, last-reviewed date), rule data, fixtures, and the [01 §15](01-product-definition.md) release gate. Profiles that miss the gate move to Tier 2. Acceptance: per profile, a reviewed research document and passing rule tests. Function F-04.

## L19-014 — Shadow and side-light advisory — P1 / M

Detect a background shadow next to the head and uneven light across the face, in live guidance and Photo Check. Advisory only (warn or manual check) until calibration proves reliability (AGENTS.md §9). Acceptance: calibrated on a consented fixture set across skin tones; no false fail.

## L19-015 — Glasses glare advisory — P1 / M

Flag likely reflections on glasses and suggest tilting the glasses or moving the light; respect each profile's glasses rule. Advisory only. Acceptance: calibrated on consented fixtures with and without glasses.

## L19-017 — Capture protection for locked previews — P0 / M

Implement ADR-049 D-9. A device spike on iOS 26 and 27 tests the secure-layer technique on every locked preview: Photo Check, Adjust, the sheet, and the confirmation. Fallback: hide locked previews while `sceneCaptureState` is active, and explain after a screenshot. Acceptance: screenshots and recordings on physical devices show the locked photo blank; unlocked photos are unaffected; no layout, gesture, animation, or performance regression in the W3 landing; App Review notes prepared. Keep the technique behind one small view so it can be replaced if iOS changes.

## L19-016 — Quick sheet presets — P2 / S

One-tap starting layouts on Your sheet ("One person, most copies", "Family", "ID + passport sizes"). Acceptance: each preset produces a valid layout on every catalog paper.

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

As of 2026-11-11 the spike has explored much of U10, X11, and P12 ahead of this order. The current phase plan and the place of Epic 19 in it are in [the launch roadmap](23-launch-roadmap.md).

# 3. Definition of done for every iOS feature

A feature is done only when relevant items are true:

- acceptance criteria tested;
- current HIG/native control review completed;
- accessibility baseline kept (AGENTS.md §6, ADR-050);
- no unnecessary permission;
- privacy/logging reviewed;
- async cancellation/stale state handled;
- physical-device behavior verified when hardware/performance relevant;
- Instruments review for performance-sensitive code;
- localization/String Catalog complete;
- iOS 26/iOS 27 availability behavior tested if applicable;
- documentation/ADR updated if a foundational choice changed.
