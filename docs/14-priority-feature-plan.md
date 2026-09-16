# 14 — Priority feature plan: print sheets, alignment, background, tone, iOS 26/27

**Date:** 2026-09-16  
**Status:** Research complete; plan proposed. Production work still gated on the M1 evidence rules in [AGENTS.md](../AGENTS.md).  
**Inputs:** user priorities after [spike 01](spikes/01-import-crop-export.md); inspection of the installed iOS 27.0 SDK (Xcode 27.0, 27A266a) at `/Applications/Xcode.app`; Apple documentation, WWDC25/WWDC26 sessions, ICAO/ISO portrait standards, printing-industry references, and a competitor scan. Sources are listed in §10.

## 1. What the user asked for

1. Customizable photo-paper dimensions, including popular sizes such as 15 × 10 cm.
2. When the paper changes, placement is re-optimized to use as much of the sheet as possible.
3. Several different photos on one page, with a copy count per photo.
4. Overflow automatically adds pages.
5. Bleed and corner cutting marks.
6. Automatic background removal and replacement with white.
7. Automatic photo adjustments "using Apple presets like Studio Light".
8. Automatic face and eye detection and alignment.
9. Latest iOS 26/27 UX/UI and AI capabilities.

All nine are feasible natively. Three need a correction before implementation (§2). The rest map cleanly onto the existing architecture, mostly as additions to the deterministic domain core (§4) and to Epics 5–8 and 12 in the [backlog](09-backlog.md).

## 2. Findings that change the plan

### 2.1 "Studio Light" cannot ship as a still-photo preset

Verified in the SDK headers and Apple documentation:

- `AVCaptureDevice.isStudioLightEnabled` (iOS 16) is a **read-only class property** that mirrors a Control Center toggle for the live *video* stream. Apps cannot enable it; non-VoIP apps only opt in through the `NSCameraStudioLightEnabled` Info.plist key, and Apple documents it only under "system video effects". Nothing states it applies to `AVCapturePhotoOutput` stills.
- Portrait Lighting effects (Studio, Stage, Contour, High-Key Mono) exist in Core Image only as `CICategoryApplePrivate` filters with undocumented inputs. Using them is private-API use and an App Review risk.
- PhotoKit exposes no lighting adjustment. The Photos app "Auto" enhance is opaque `PHAdjustmentData`.

What Apple does provide publicly, and what the plan uses instead: `CIImage.autoAdjustmentFilters(options:)` (iOS 5, not deprecated) returning `CIVibrance`, `CIToneCurve`, `CIHighlightShadowAdjust`, plus face-aware `CIFaceBalance`/`CIRedEyeCorrection` when faces are detected; and documented global filters (`CIExposureAdjust`, `CITemperatureAndTint`, `CIWhitePointAdjust`, `CIUnsharpMask`, `CINoiseReduction`). The plan names this feature **Document Tone** (§3.7): a conservative, global, reversible correction with a strength control and before/after. No face relighting, no local retouching. This also matches ADR-011 and the UK/Canada "unaltered by software" wording.

A one-day spike (S1-021) will still confirm on device whether the Studio Light Info.plist opt-in has any effect on captured stills. The default assumption is that it does not.

### 2.2 "Replace with white" is only correct for some jurisdictions

Official wording differs by country: Spain DNI requires a plain uniform **white** background; the US accepts white or off-white; the UK asks for plain **cream or light grey**; Germany asks for a light **neutral grey**, chosen against hair colour, and discourages white; France (secondary sources) light grey or light blue. The UK additionally requires photos "unaltered by computer software", and Canada rejects AI-altered photos.

Consequence: the replacement colour, its uniformity/contrast rule, and whether replacement is permitted at all become **profile data** (schema fields already sketched in [05-rules-engine.md §17](05-rules-engine.md)). For the confirmed Spain launch profile the default is white. The pipeline design (§3.6) is colour-agnostic.

### 2.3 Apple gives no top-of-head landmark

`FaceObservation.landmarks` contour runs cheek → chin → cheek; the face rectangle excludes hair and is undocumented as to what it covers. Only `HumanBodyPose3DObservation.topHead` exists, as a skeletal estimate. Crown (chin-to-crown head height) must therefore be **estimated** from a segmentation mask fused with an anthropometric extrapolation from eye line and chin (§3.8). This is also how the best open-source implementation (HivisionIDPhotos) and commercial services work.

### 2.4 Vision revisions differ between iOS 26 and iOS 27

The iOS 27 SDK adds `DetectFaceLandmarksRequest.Revision.revision4` (98 points, default on iOS 27) and `DetectFaceRectanglesRequest.Revision.revision4` (tighter boxes). With an iOS 26 minimum, geometry would differ by OS unless the request revision is pinned. FR-072 (deterministic geometry) requires pinning `.revision3` for both, or branching on `supportedRevisions` with separate calibration. Proposed as ADR-040.

### 2.5 Consumer printing silently scales

- Borderless printing enlarges content by roughly 2 % (Canon, Epson, Ilford documentation), so a 35 × 45 mm photo prints at about 35.7 × 45.9 mm and up to 3 mm at the paper edge is lost.
- AirPrint chooses the smallest listed paper that contains the PDF page; custom paper sizes cannot be created from an app; iOS 17+ users report a default "scale to fit" behaviour.
- Kiosks (Walgreens, CVS) print borderless with fill-crop.

Consequence: the sheet is rendered as a **full-page image at exactly the paper's aspect and size** with a white safe margin, a 50 mm calibration bar, corner ticks instead of through-lines, `UIPrintInfo.outputType = .photo`, a `choosePaper` delegate that prefers a bordered paper over the borderless variant, and an explicit "print at Actual Size, measure before cutting" instruction. Physical measurement remains the release gate (ADR-026).

### 2.6 iOS 27 delivers the two capabilities the strategy hoped for

Confirmed in the SDK:

- `Vision.GenerateIterativeSegmentationRequest` (iOS 27): seed by point, box, or scribble buffer; `addIncludedPoint`/`addExcludedPoint`; quality levels fast/balanced/accurate; model assets are downloaded on demand (`assetStatus`, `downloadAssets()`). This is the "tap to fix the cutout" refinement path anticipated in FR-065 and ADR-004.
- `FoundationModels.Attachment` image input, `LanguageModelCapabilities.vision`, and the Evaluations framework (iOS 27). Image input is understanding only, never pixel output. It fits the existing "advisory, never authoritative" boundary (ADR-032) and is proposed only for optional coaching (§3.9).

## 3. Feature plans

Each feature lists intent, design, Apple APIs, domain additions, acceptance, and risks. IDs refer to new requirements (FR-140+) and backlog items added alongside this document.

### 3.1 Paper catalog and custom paper sizes (FR-140, FR-141)

**Design.** A `PaperSize` catalog in versioned data, separate from document profiles:

| Preset | mm | Notes |
|---|---|---|
| 10 × 15 cm (metric lab cut) | 100 × 150 | Default in EU/JP lab and pharmacy flows |
| 4 × 6 in | 101.6 × 152.4 | Default for AirPrint `.photo` paper in inch locales and most home inkjet packs sold as "10 × 15 / 4 × 6" |
| 13 × 18 cm / 5 × 7 in | 127 × 178 | Second most common home/lab size |
| 9 × 13 cm / 3.5 × 5 in ("L") | 89 × 127 | Japan and EU secondary |
| A6 | 105 × 148 | AirPrint `.photo` default in A-series locales |
| A4 / US Letter | 210 × 297 / 215.9 × 279.4 | Plain-paper test prints and photo paper; choose by locale |
| Optional advanced | 15 × 20, 20 × 30, 10 × 10, Instax image areas | Image export only; not AirPrint paper |
| Custom | user-entered mm or inches | Marked "custom"; image/PDF export; AirPrint will snap to the nearest containing paper |

Both 100 × 150 and 101.6 × 152.4 are kept as distinct presets because the 1.6/2.4 mm difference flips grid counts at tight gutters. Labels always show both naming orders ("10 × 15 cm · 6 × 4 in") and never infer orientation from the name.

**Domain.** `PaperSize { id, widthMm, heightMm, names, regions, kind: photo | office | custom, airPrintCompatible }`. Custom sizes are validated (min 50 mm, max 500 mm) and stored locally.

**Acceptance.** Catalog validated in CI; locale-based default (metric 10 × 15 vs 4 × 6); custom size round-trips through the solver, PDF page box, and JPEG pixel dimensions.

### 3.2 Layout optimizer (FR-142, FR-143)

**Design.** A deterministic, pure-Swift **two-stage guillotine (row/shelf) solver**. Rows are the natural unit because users cut with scissors or a guillotine; MaxRects/Skyline pack marginally better but produce staggered, non-guillotine layouts. Search space is tiny (≤ 4 photo types × 2 orientations × ≤ 8 rows), so exhaustive search runs in microseconds.

Algorithm:

1. Inputs: paper W × H, margin `m` to the bleed edge, gutter `g`, bleed `b`, items `(trimW, trimH, copies, rotatable)`.
2. Cell size = trim + 2·bleed. Evaluate both paper orientations and both cell orientations.
3. Single-type page: `columns = ⌊(W − 2m + g) / (cellW + g)⌋`, `rows = ⌊(H − 2m + g) / (cellH + g)⌋`, plus the two "one rotated strip" patterns from pallet-loading heuristics.
4. Mixed page: enumerate row recipes per type/orientation; choose the multiset of rows that fits `H − 2m` and maximizes placed count, tie-breaking on fewer distinct row heights, then larger leftover strip, then user order. Column x-positions snap to a shared grid when the same cell width recurs so vertical cut lines run through.
5. **Adaptive bleed:** try bleed 1.0 → 0.5 → 0 mm and keep the largest bleed that does not reduce the page count (35 × 45 on 10 × 15 keeps 6 copies only at ≤ 0.5 mm bleed).
6. Deterministic: integer micrometres, fixed iteration order, no randomness. Same inputs → identical layout (FR-072 discipline applied to print).

Recommended defaults: margin 4 mm to the bleed edge (so the trim edge sits ≥ 5 mm from the paper edge, inside Canon's 5 mm unprintable zone), gutter 2 mm, bleed adaptive 0–1 mm. A "Max copies" option allows zero gutter with shared cut lines, off by default because a cut error then produces one oversize and one undersize photo.

Verified counts with those defaults (paper portrait/landscape and photo rotation chosen automatically):

| Paper | 26 × 32 | 35 × 45 | 51 × 51 | 50 × 70 |
|---|---|---|---|---|
| 10 × 15 / 4 × 6 | 12 (3 × 4) | 6 (2 × 3) | 2 | 2 |
| 13 × 18 | 20 (4 × 5) | 9 (3 × 3) | 6 | 4 |
| A6 | 12 | 6 (rotated) | 2 | 2 |
| A4 | 60 (rotated) | 30 | 15 | 12 |
| US Letter | 56 | 28 (rotated) | 15 | 12 |

Mixed example on 10 × 15 with margin 4, gutter 2, bleed 0.5: four 35 × 45 plus six 26 × 32 → page 1 holds two rows of 2 × 35 × 45 (94 mm) plus one row of 3 × 26 × 32 (33 mm), page 2 holds the remaining three.

**Domain.** `PrintLayoutSolver.solve(job: PrintJob) -> PrintLayout` with `PrintPage { placements: [Placement { itemID, copyIndex, trimRectMm, bleedRectMm, rotated }], marks, calibrationBar }` and diagnostics (utilisation, unplaced items). Lives in `Domain/PrintLayout`, replacing the fixed `PrintLayout` struct from spike 01.

**Acceptance.** Parameterized Swift Testing cases for every preset × sample photo size matching the table above; no overlaps; every trim rect ≥ 5 mm from the paper edge; layout identical across runs and devices; solver < 5 ms for 4 types × 50 copies × 10 pages.

### 3.3 Multiple photos per sheet with per-photo copies (FR-144)

**Design.** A `PrintJob` holds ordered `PrintItem`s, each referencing a prepared photo (its immutable source, crop, mask, tone parameters, and profile version) plus `copies` and `allowRotation`. Photos may have different trim sizes (26 × 32 for a parent, 35 × 45 for a visa). The composer UI is a list of person cards with a stepper (VoiceOver adjustable action), a live sheet preview, page indicator, and the iOS 27 `.reorderable()` / `reorderContainer` modifiers to change fill order, with an iOS 26 fallback of Move Up/Down actions.

No mainstream iOS app clearly offers mixed-person sheets; this is a differentiator for families renewing several documents at once (see §5).

**Privacy.** Prepared photos live in the existing private working directory for the session; a print job is not a permanent gallery (ADR-021). Adding another person reuses the normal capture/import flow.

### 3.4 Overflow pages and fill strategy (FR-145)

Greedy per page: solve for remaining demand, subtract, repeat; hard cap 10 pages with a clear message. Two strategies: **by type** (default; finish all copies of one photo before the next, fewer distinct cut heights per page) and **interleave** (each page carries every photo proportionally, useful when the user prints only page 1). PDF gets one page per sheet; JPEG export gets one file per page.

### 3.5 Bleed and cutting marks (FR-146)

Printing-industry conventions adapted to small ID photos:

- **Bleed:** photo raster extends 0.5–1 mm beyond the trim (background and shoulders, never the face), chosen adaptively by the solver. A 1 mm cutting error then yields a slightly small photo rather than a white sliver.
- **Marks:** corner ticks only, never lines across a photo. Four L-ticks per photo, each 3 mm long, starting at the bleed edge and running away from the photo; ticks of neighbours merge into a short dash across the gutter. PDF stroke 0.25 pt; JPEG 1 px pure black at 300 ppi without anti-aliasing (inkjets render thin grey badly).
- **Calibration bar:** a 50 mm rule inside the safe area with the text "50 mm · print at Actual Size · measure before cutting", localized.
- **Optional dotted trim outline** only when the gutter is ≥ 3 mm.

Marks and bar are drawn by the sheet renderer from the layout geometry, never burned into the photo raster itself (UXP-07 still holds for the photo; the sheet is a print artefact).

### 3.6 Background removal and replacement (FR-060–FR-067 refined, FR-147)

**Pipeline (all on-device):**

1. **Opportunistic mattes.** If the source HEIC carries `kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte`/skin mattes or a portrait effects matte (Camera-app Portrait shots), or if in-app capture requested `enabledSemanticSegmentationMatteTypes`, use them as a high-quality prior. They are half-resolution, device dependent, and absent without a person, so the pipeline never depends on them.
2. **Automatic mask.** `GenerateForegroundInstanceMaskRequest` → `generateScaledMask(for:scaledToImageFrom:)` for a full-resolution soft mask (`instanceAtPoint` selects the face's instance when several are found), cross-checked with `GeneratePersonSegmentationRequest(.accurate)`, which Apple documents as including matting refinement. Choose per image by a documented quality heuristic.
3. **Edge treatment.** `CIMorphologyMinimum` (choke 0–1 px), `CIGaussianBlur` (feather), `CIBlendWithMask` onto the profile's background colour. Optional colour-decontamination of the 1–2 px fringe.
4. **Uncertainty.** Edge-entropy in the hair band, holes inside the face/torso region, and mask/face-box consistency produce a score → `pass`, `warn` (show Refine), or fallback (keep original, retake). A broken hair mask never silently exports (FR-064).
5. **Refine (iOS 27).** `GenerateIterativeSegmentationRequest` seeded with the face box, plus include/exclude taps (max 13 points; 11 with a box). Handle `assetStatus == .notReady` with a download prompt on Wi‑Fi. iOS 26 fallback: switch between candidate masks, adjust choke/feather, keep original, or retake. Accessible alternative: "Include this area / Exclude this area" from a small grid of named regions (FR-066).
6. **Background check before replacing.** Measure uniformity and colour of the original background; if it already satisfies the profile, offer "Original" as the recommended choice. Replacement is opt-in when the profile marks replacement `unknown` or the jurisdiction says "unaltered".

**Domain.** `SegmentationResult { maskRef, method, qualityScore, warnings }`; `BackgroundChoice { original | profileColor(color) | custom(color, nonOfficial) }` stored in `EditParameters`.

**Acceptance.** Fixture suite covering hair types, glasses, head coverings, shoulders, low-contrast backgrounds, children (consented or synthetic per ADR-027); edge rubric documented; iOS 26/27 parity tests; no face pixels modified by the compositor (pixel diff inside the face region = 0).

### 3.7 Document Tone: automatic adjustments (FR-081 refined, FR-150–FR-152)

**Design.** One toggle, one strength slider, before/after.

- Start from `autoAdjustmentFilters(options: [.crop: false, .level: false])`, keeping red-eye correction (a flash artefact, not identity).
- Add a neutral white balance from the background/grey-world estimate (`CITemperatureAndTint`) once the background is known, exposure clamp ±0.5 EV, and a mild `CIUnsharpMask` applied only at export resolution.
- Strength blends original and adjusted output 0–100 %; default 60 %.
- Everything is global and reversible; nothing is spatially masked to the face. No skin smoothing, no eye/teeth work, no relighting (ADR-011).
- Profile gate: `alterationPolicy` = `allowed | discouraged | forbidden`. UK-style "unaltered" profiles default the toggle off with an explanation.

**Capture-side option to evaluate:** `AVCapturePhotoOutput.isConstantColorEnabled` (iOS 18) delivers daylight-normalized colour but forces the flash; evaluate in the camera spike, likely unsuitable for faces.

**Acceptance.** Fixture-based: identity-preservation check (face-region structural similarity above an agreed threshold at 100 % strength), no clipping beyond ICAO's 0.1 % saturated pixels in the face region, deterministic output for identical inputs, state in `EditParameters` so export reproduces the preview exactly.

### 3.8 Automatic face and eye alignment (FR-070–FR-073 refined, FR-153–FR-156)

**Measurements (Vision, revision pinned):**

- `DetectFaceLandmarksRequest(.revision3)`: `leftPupil`/`rightPupil` → eye centres, inter-eye distance (IED), eye midpoint; `faceContour` bottom → chin; `medianLine` → face axis; `roll`, `yaw`, `pitch` as `Measurement<UnitAngle>`.
- Crown estimate, two ways, fused:
  - anthropometric: `crown_A = chin − k · (chin − eyeline)`, k ≈ 1.75–1.85 for adults (calibrated on the fixture corpus, tunable per profile/age group);
  - mask: topmost foreground row within the face's horizontal band from the segmentation mask (`crown_S`);
  - if `|crown_S − crown_A| < ~0.35 · IED` use `crown_S` (short hair, bald); otherwise hair volume or headwear is present, use `crown_A` and raise a "hair volume" advisory (ICAO and the German Fotomustertafel define crown ignoring hair).
- Optional sanity check with `HumanBodyPose3DObservation.topHead` projected via `pointInImage(for:)`; shoulders level from `DetectHumanBodyPoseRequest`.
- Multiple faces: `instanceAtPoint`/largest face plus FR-041 blocking.

**Solver.** Level the eyes by rotating within the permitted roll range (ICAO roll ≤ 8°, best practice ≤ 5°; rotation is a new permitted `EditParameters` field), then scale from the profile's head-height target (mid-band), then place vertically so eye line and top margin both satisfy their bands, horizontally centering the face axis. If bands conflict, prioritize the profile's hard numeric rule and report the residual. Always expose crown and chin handles; store the user override and its delta for calibration.

**Rule bands.** Spain publishes no head-height or eye-line numbers; the app uses ICAO Portrait Quality bands mapped to 26 × 32 as a labelled **engineering default** (head 60–90 % of height, eye midpoint 30–50 % from top, centring 45–55 %), never presented as an official DNI requirement. Other jurisdictions supply their own bands through the schema (`headHeight` band, `hardRejectBand`, `target`, `crownDefinition: skull | hair`, `eyeLine`, `topMargin`).

**Acceptance.** Fixture corpus with labelled crown/chin/eyes: median crown error < 0.15 · IED on adults; pose gates match Vision angles ±1°; identical solution for identical inputs on iOS 26 and 27; failure modes (tall hair, hijab/hat, bald, beard, infant, tilt, glasses) each have a fixture and an expected state (`pass`, `warn`, `manual_check`).

### 3.9 iOS 26/27 platform adoption (ranked by user value)

Confirmed against the installed SDK and Apple sessions. iOS 27 items are availability-gated with an iOS 26 fallback.

| Rank | Capability | iOS | Why it helps this app |
|---|---|---|---|
| 1 | Deferred Start (`automaticallyRunsDeferredStart`, `isDeferredStartEnabled`) and responsive capture, `maxPhotoDimensions` from `supportedMaxPhotoDimensions` | 26 / 17 | Faster first frame and shutter; 48 MP rear, 18 MP front on iPhone 17 |
| 2 | `GenerateIterativeSegmentationRequest` | 27 | Tap-to-fix mask refinement (Signature 3 in the excellence strategy) |
| 3 | `DetectLensSmudgeRequest` | 26 | Pre-capture "clean your lens" warning; cheap and high value for ID photos |
| 4 | `.onCameraCaptureEvent` (volume, Action button, Camera Control, AirPods stem) with `defaultSoundDisabled`; `AVCaptureSystemZoomSlider` on Camera Control devices | 17 / 26 | Hands-free self-capture at arm's length |
| 5 | Center Stage front camera: `setDynamicAspectRatio(.ratio3x4)`, smart framing kept **off**, sensor-orientation compensation on | 26 (iPhone 17) | Correct 3:4 framing for selfie ID capture without a session rebuild |
| 6 | `PHPickerMetadataOptions.removeLocation` / `photosPickerMetadataOptions` | 27 | Location stripped at the picker, strengthening the privacy story |
| 7 | Liquid Glass by inheritance; one `GlassEffectContainer` over the editor; `backgroundExtensionEffect`; `scrollEdgeEffectStyle(.hard)` over photos; `toolbarMinimizeBehavior`, `visibilityPriority` | 26 / 27 | Content-first editor and composer chrome per ADR-029 |
| 8 | `.reorderable()` + `reorderContainer`, `swipeActions` on any view | 27 | Reordering print items; swipe to remove a person card |
| 9 | Foundation Models image input + `@Generable` + Evaluations framework | 27 | Optional "Photo Coach": advisory checks such as glare on glasses or shadow on background, on-device only, deterministic checks stay authoritative |
| 10 | App Intents: `CreateIDPhoto`, `OpenDocumentProfile`, `AppIntentsTesting` | 26 / 27 | Existing plan; no new schema needed |
| 11 | Accessibility Nutrition Labels, `accessibilityLinkedGroup` | 26 / 27 | Declare VoiceOver, Voice Control, Larger Text, Contrast, Reduced Motion support honestly |
| 12 | Swift 6.4 hygiene: typed-throws `Task`, `withTaskCancellationShield` around final file writes, `anyAppleOS` availability | Xcode 27 | Cancellation safety for export |

Explicitly **not** adopted: Image Playground/generative fills (identity), Private Cloud Compute for portraits (no need, network, quota), Core AI custom segmentation at launch (Vision suffices), Visual Intelligence, LockedCameraCapture, smart framing auto-zoom, Cinematic capture (bakes bokeh into stills).

## 4. Domain model additions

```text
PaperSize            id, widthMm, heightMm, names[], regions[], kind, airPrintCompatible
PrintItem            id, preparedPhotoID, profileID/version, trimMm(w,h), copies, allowRotation
PrintJob             paper, orientation(auto|portrait|landscape), items[], options
PrintOptions         marginMm=4, gutterMm=2, bleedPolicy(adaptive 0…1 | fixed | none),
                     marks(ticks|none), calibrationBar, fillStrategy(byType|interleave), maxPages=10
PrintLayout          pages[PrintPage], diagnostics(utilisation, unplaced)
PrintPage            placements[Placement], marks[], calibrationBar?
Placement            itemID, copyIndex, trimRectMm, bleedRectMm, rotated
SheetRenderer        PDF (Core Graphics, page box = paper) and JPEG (exact aspect, 300 ppi)

FaceGeometry         eyeCenters, eyeMidpoint, interEyeDistance, chin, crown{value, method, confidence},
                     roll/yaw/pitch, faceBox, shoulders?, faceCount
CropSolution         crop, rotation, residuals[], diagnostics
SegmentationResult   maskRef, method, qualityScore, warnings[]
EditParameters (+)   rotationDegrees, backgroundChoice, toneEnabled, toneStrength, maskRefinements[]
DocumentProfile (+)  background{color, contrastRule, replacementPolicy}, alterationPolicy,
                     composition{headHeight band+hard+target, crownDefinition, eyeLine, topMargin, centring},
                     digitalPresets[] (dims exact|min|max, aspect, byte limits)
```

All of these are pure Swift in `Domain/`, with explicit coordinate spaces per ADR-009 (`PhysicalMillimeterSpace` for layout, `PDFPointSpace` at render time).

## 5. Improvements beyond the requested list

Ranked by user value and evidence from the competitor scan.

1. **Lab-ready sheet JPEG.** One JPEG per page at exactly the paper aspect, 300 ppi (1200 × 1800 px for 4 × 6, 1181 × 1772 px for 100 × 150), sRGB, with the calibration bar. "No 4 × 6 JPEG for retail printing" is a top App Store complaint against the leading competitor.
2. **Calibration bar plus measure-before-cut instruction**, later a camera-based check of the printed bar. Wrong physical size after printing is the most common one-star theme across all competitors.
3. **Mixed-person sheets** (already in scope) as the headline family feature; no mainstream iOS competitor does it clearly.
4. **ICAO-clause compliance checklist**: pose ±5°/±8°, mouth closed, eyes open, glasses glare, asymmetric shadows on background, four-zone lighting uniformity, < 0.1 % clipped pixels in the face region, IED ≥ 90 px (240 px best practice). Advisory unless calibrated (FR-043, FR-115).
5. **Digital submission presets** in the profile schema with a byte-target encoder: US DS-160 600–1200 px square ≤ 240 KB, UK ≥ 600 × 750 and 50 KB–10 MB, Canada 3:2 1200 × 1800–3000 × 4500 and 200 KB–5 MB, India 630 × 810 and 10–250 KB. Post-MVP content, but the schema and encoder loop (X11-004) should anticipate them.
6. **Child and baby mode** encoding ICAO relaxations (under 1: eyes may be closed; ≤ 6: ±15° pose, free expression; ≤ 11: head 50–90 %, eye line 30–60 %) and a "no hands or toys" manual check. Fits ADR-017.
7. **Pre-capture lens smudge warning** and **burst-and-rank** using `DetectFaceCaptureQualityRequest` (valid only for ranking shots of the same person, never as an absolute threshold).
8. **Alteration legality per country** shown before export (UK "unaltered", Canada AI ban, Germany digital-only channel through certified providers since May 2025), so the app never sells an output that cannot be used.
9. **Honest pricing surface**: whatever ADR-015 decides, show it before capture; no end-of-flow watermark (already FR-098).
10. **Live head-pose guidance** in the camera from `roll`/`yaw`/`pitch`, debounced (C9-001), replacing vague "hold still" messages with "tilt slightly left".

## 6. Sequencing

### 6.1 Remaining M1 spikes (add to Epic 1)

| Spike | Question | Depends on |
|---|---|---|
| S1-017 Face geometry and crown estimator benchmark | Are pinned-revision landmarks plus fused crown accurate enough on the fixture corpus? | S1-004 |
| S1-018 Segmentation, composition, iOS 27 refinement | Mask quality rubric, uncertainty score, iterative refinement UX, iOS 26 fallback | S1-006 |
| S1-019 Print composer | Solver correctness, PDF/JPEG sheet renderer, AirPrint `choosePaper` behaviour, borderless vs bordered paper, physical measurement on two printers | S1-010 |
| S1-020 Camera with iOS 26 capture features | Deferred Start, responsive capture, capture events, front-camera 3:4, smudge detection | S1-002 |
| S1-021 Document Tone and Studio Light check | Identity-preservation metrics for the auto-adjust chain; confirm Studio Light plist has no effect on stills | S1-009 |

S1-017 and S1-018 share the fixture corpus (ADR-027); S1-019 is independent and can start immediately from spike 01's PDF code.

### 6.2 Production mapping

| Milestone | Additions from this plan |
|---|---|
| M3 pipeline | segmentation stack, Document Tone chain, face geometry adapter with pinned revisions, mask uncertainty |
| M4 rules | background colour/contrast/replacement fields, alteration policy, composition bands with crown definition, digital presets schema, Spain engineering defaults labelled as such |
| M5 UX | print composer screen (person cards, steppers, sheet preview, page indicator, reorder), Refine sheet, Document Tone control, alignment handles |
| M6 export | paper catalog, solver, sheet renderer (PDF + JPEG), AirPrint delegate, calibration bar, physical print matrix |
| M7 hardening | iOS 26/27 parity matrix for Vision revisions and refinement, accessibility labels for composer/refine, Evaluations run for the optional coach |

### 6.3 Dependency sketch

```text
S1-017 face geometry ─┐
S1-018 segmentation ──┼─► M3 pipeline ─► M4 rules (bands, background, alteration) ─► M5 editor/composer UX
S1-019 print composer ┘                                                            └► M6 export/print
S1-020 camera ────────► M3 capture
S1-021 tone ──────────► M3 tone chain (gated by M4 alterationPolicy)
```

## 7. Test additions

- Parameterized solver suite: every paper preset × {26 × 32, 35 × 45, 51 × 51, 50 × 70, 30 × 40} with expected counts (§3.2 table); overlap and margin invariants; adaptive-bleed choice; overflow paging; determinism across runs.
- Sheet renderer: PDF page boxes equal paper size ±0.01 pt; placement rects reopen at expected mm; JPEG dimensions and DPI tags; tick geometry; calibration bar length.
- Physical matrix (ADR-026): two printers (one Canon, one Epson or HP), bordered and borderless, 10 × 15 and A4; measure trim and bar with calipers; record tolerance.
- Segmentation fixtures and rubric; face-region pixel-equality test for the compositor.
- Face geometry fixtures with labelled crown/chin/eyes; iOS 26 vs 27 parity with pinned revisions.
- Document Tone identity metrics and clipping limits.
- Accessibility: composer steppers as adjustable actions, Refine non-freehand path, VoiceOver description of a sheet ("Page 1 of 2: 4 copies of Ana, 3 copies of Luis").
- Optional coach: Evaluations framework suite for invented rules and contradictions (FR-134).

## 8. Decisions proposed

Recorded as Proposed in [10-decisions.md](10-decisions.md):

- **ADR-036** Print sheet composer and paper catalog (guillotine solver, defaults, JPEG + PDF, AirPrint handling).
- **ADR-037** Background replacement colour and permission are profile data; Spain default white.
- **ADR-038** Tonal correction policy: Document Tone only; no Portrait Lighting or Studio Light claims.
- **ADR-039** Face alignment estimator: pinned landmarks plus fused crown with manual handles.
- **ADR-040** Vision request revision pinning across iOS 26/27.
- **ADR-041** iOS 27 iterative segmentation as the refinement path with iOS 26 fallback (refines ADR-004).
- **ADR-042** Foundation Models image input is advisory only and on-device only (refines ADR-032).

Open product inputs (not blocking the spikes):

1. Default paper per locale, and whether the zero-gutter "Max copies" mode ships in 1.0.
2. Whether custom paper sizes ship in 1.0 or after (the solver supports them either way).
3. Whether the optional Photo Coach is pursued at all (FM14-001).
4. Monetization (ADR-015), because it decides where the "what is free" surface goes.

## 9. API availability summary (verified in the iOS 27.0 SDK)

| API | Min iOS | Role |
|---|---|---|
| `DetectFaceLandmarksRequest` `.revision3` / `.revision4` (98 pt) | 18 / 27 | eye line, chin, pupils; pin revision |
| `DetectFaceRectanglesRequest` `.revision4` | 27 | tighter boxes; pin revision |
| `FaceObservation.roll/yaw/pitch` (`Measurement<UnitAngle>`) | 18 | pose gates, eye levelling |
| `DetectFaceCaptureQualityRequest` | 18 | burst ranking only |
| `DetectHumanBodyPoseRequest` / `…3DRequest` (`topHead`) | 18 | shoulders; crown sanity check |
| `GenerateForegroundInstanceMaskRequest` / `InstanceMaskObservation.generateScaledMask` | 18 | primary mask |
| `GeneratePersonSegmentationRequest(.accurate)` | 18 | matting-refined mask |
| `GenerateIterativeSegmentationRequest` | 27 | tap/box/scribble refinement, downloadable assets |
| `DetectLensSmudgeRequest` | 26 | pre-capture warning |
| `AVSemanticSegmentationMatte` hair/skin/glasses; ImageIO aux keys | 13–14.1 | opportunistic prior |
| `CIImage.autoAdjustmentFilters(options:)` | 5 | Document Tone base |
| `AVCaptureSession` deferred start, `isResponsiveCaptureEnabled`, `maxPhotoDimensions` | 26 / 17 / 16 | camera |
| `AVCaptureDevice.setDynamicAspectRatio`, `smartFramingMonitor` | 26 | iPhone 17 front camera |
| `AVCaptureDevice.isStudioLightEnabled` (read-only, video effect) | 16 | not usable for stills |
| `UIPrintInteractionController`, `UIPrintInfo.outputType = .photo`, `UIPrintPaper.bestPaper`, `UIPrintPageRenderer` | 4.2+ | printing; unchanged in iOS 26/27 |
| `PHPickerMetadataOptions.removeLocation`, `photosPickerMetadataOptions` | 27 | import privacy |
| SwiftUI `reorderable`, `reorderContainer`, `toolbarOverflowMenu`, `visibilityPriority`, `swipeActionsContainer` | 27 | composer UI |
| SwiftUI `glassEffect`, `GlassEffectContainer`, `backgroundExtensionEffect`, `scrollEdgeEffectStyle` | 26 | editor chrome |
| `FoundationModels.Attachment` (image), `LanguageModelCapabilities.vision`, Evaluations | 27 | optional coach |
| `AppIntents.LongRunningIntent`, `AppIntentsTesting` | 27 | intents |

## 10. Sources

Apple platform:

- Vision framework — https://developer.apple.com/documentation/vision
- `GenerateIterativeSegmentationRequest` — https://developer.apple.com/documentation/vision/generateiterativesegmentationrequest
- `DetectFaceLandmarksRequest.Revision.revision4` — https://developer.apple.com/documentation/vision/detectfacelandmarksrequest/revision-swift.enum/revision4
- `InstanceMaskObservation` — https://developer.apple.com/documentation/vision/instancemaskobservation
- `GeneratePersonSegmentationRequest` — https://developer.apple.com/documentation/vision/generatepersonsegmentationrequest
- `DetectLensSmudgeRequest` — https://developer.apple.com/documentation/vision/detectlenssmudgerequest
- `CIImage.autoAdjustmentFilters(options:)` — https://developer.apple.com/documentation/coreimage/ciimage/autoadjustmentfilters(options:)
- `AVCaptureDevice.isStudioLightEnabled` — https://developer.apple.com/documentation/avfoundation/avcapturedevice/isstudiolightenabled
- `AVSemanticSegmentationMatte` — https://developer.apple.com/documentation/avfoundation/avsemanticsegmentationmatte
- `AVCapturePhotoOutput.maxPhotoDimensions` — https://developer.apple.com/documentation/avfoundation/avcapturephotooutput/maxphotodimensions
- `UIPrintInteractionController` — https://developer.apple.com/documentation/uikit/uiprintinteractioncontroller
- `UIPrintPaper.bestPaper(forPageSize:withPapersFrom:)` — https://developer.apple.com/documentation/uikit/uiprintpaper/bestpaper(forpagesize:withpapersfrom:)
- `UIPrintInfo.OutputType.photo` — https://developer.apple.com/documentation/uikit/uiprintinfo/outputtype-swift.enum/photo
- Foundation Models multimodal prompting — https://developer.apple.com/documentation/FoundationModels/analyzing-images-with-multimodal-prompting
- WWDC26 What's new in image understanding (237) — https://developer.apple.com/videos/play/wwdc2026/237/
- WWDC26 What's new in SwiftUI (269) — https://developer.apple.com/videos/play/wwdc2026/269/
- WWDC26 What's new in Foundation Models (241) — https://developer.apple.com/videos/play/wwdc2026/241/
- WWDC26 Evaluations framework (298) — https://developer.apple.com/videos/play/wwdc2026/298/
- WWDC26 Responsive camera (303), High-resolution capture (304), Center Stage front camera (341)
- WWDC25 Build a SwiftUI app with the new design (323) — https://developer.apple.com/videos/play/wwdc2025/323/
- WWDC25 Capture controls (253) — https://developer.apple.com/videos/play/wwdc2025/253/
- Accessibility Nutrition Labels — https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels

Standards and jurisdictions:

- ICAO TR Portrait Quality v1.0 — https://www.icao.int/sites/default/files/TRIP/Publications/TR-Portrait-Quality-v1.0.pdf
- ISO/IEC 19794-5 geometry as reproduced by NIST — https://www.nist.gov/document/ansi-nist2007griffin-face-std-m1pdf
- Spain DNI photo requirement — https://www.dnielectronico.es/PortalDNIe/PRF1_Cons02.action?pag=REF_1084
- UK HMPO photo rules — https://www.gov.uk/photos-for-passports/photo-requirements
- Germany Fotomustertafel — https://www.nuernberg.de/imperia/md/buergeramt_mitte/dokumente/fotomustertafel.pdf
- Germany digital-only photos from May 2025 — https://www.bmi.bund.de/SharedDocs/kurzmeldungen/DE/2025/04/neue-passbilder.html
- Canada passport photos — https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-passports/photos.html

Printing:

- Photo print sizes — https://en.wikipedia.org/wiki/Photo_print_sizes
- Canon borderless extension — https://ij.manual.canon/ij/webmanual/PrinterDriver/W/PRO-540S/1.0/EN/PPG/dg-c_borderless03.html
- Epson borderless expansion — https://files.support.epson.com/htmldocs/r3000_/r3000_00ug/print_comp.4.4.html
- Ilford borderless guide — https://ilford.com/support/printing-with-ilford-hints-tips/a-guide-to-borderless-printing/
- Printer minimum margins — https://rasterbator.io/guides/printer-minimum-margins-borderless-printing
- Crop mark offset convention — https://printplanet.com/forum/prepress-and-workflow/prepress-and-workflow-discussion/5558-what-is-the-print-industry-standard-for-crop-mark-offset
- Rectangle bin packing survey (Jylänki) — https://github.com/secnot/rectpack
- AirPrint paper selection behaviour — https://developer.apple.com/forums/thread/30197

Competitors and open source:

- HivisionIDPhotos — https://github.com/Zeyi-Lin/HivisionIDPhotos
- PassbildPro multi-person sheets — https://www.passbild-pro.de/anleitung/unterschiedliche-bilder-auf-einem-format
- Passfoto – Passbild (bleed "printed slightly larger") — https://apps.apple.com/de/app/passfoto-passbild/id917389447
- Passport Booth reviews — https://apps.apple.com/us/app/passport-booth/id1492235157
- Foto de carnet (mixed sizes per sheet) — https://apps.apple.com/es/app/foto-de-carnet/id1483868574
