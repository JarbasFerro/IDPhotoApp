# M1 spike 03 — Face geometry, crown estimate, and automatic alignment

**Implemented:** 2026-09-16  
**Status:** Domain solver, Vision adapter, automatic alignment in the editor, and a macOS fixture harness implemented. Real-face evidence comes from macOS Vision on six private portraits. The user ran the build on a physical iPhone 15 Pro Max (iOS 26.6.2) on 2026-09-16 and Vision analysis worked there; iOS simulators on this Mac cannot run Vision inference.  
**Backlog:** S1-017; initial portions of S1-004/S1-005. Requirements FR-070 to FR-073, FR-153 to FR-156. Design: [14-priority-feature-plan.md §3.8](../14-priority-feature-plan.md). Decisions: ADR-039, ADR-040.

## Question

Can pinned-revision Vision landmarks plus a fused crown estimate (person mask agreeing with an anatomical extrapolation) place the Spain 26 × 32 crop automatically, level the eyes, and report the ICAO-style checks honestly, using only Apple frameworks and deterministic domain code?

## Implementation

- `App/Domain/FaceGeometry.swift` — `HeadFrame` (eye midpoint origin, x along the eye line, y down the head axis) so every head measurement is taken along the head's own axis rather than vertically; `FaceGeometry` (image-frame normalized points plus aligned-frame pixel distances); `CrownEstimator` (crown distance above the eyes = (k − 1)·(eye-to-chin), k = 1.8 for adults; the person-mask crown wins when it agrees within 0.35 inter-eye distances, otherwise anatomy wins and a hair-volume or head-at-edge flag is raised); `CompositionSpec` (ICAO Portrait Quality engineering defaults: head 60–90 % of height with 74 % target, eye midpoint 30–50 % from top with 42 % target, ±5° yaw/pitch, ±8° roll reported, tilts up to 15° levelled automatically, IED ≥ 90 px with 120 px recommended); and `CropSolver` (solve in the aligned frame, map the crop centre back to the image, level the eyes when the tilt is within the auto-level limit, express as the editor's zoom/travel/rotation model, emit `pass / warn / fail / manualCheck` checks).
- `App/Domain/PhotoGeometry.swift` — `CropAdjustment.rotationDegrees` (±15°, counter-clockwise about the crop centre), applied in the preview and in the export renderer.
- `App/Imaging/FaceAnalyzer.swift` — `DetectFaceLandmarksRequest(.revision3)` pinned per ADR-040; pupils (eye regions as fallback) and the lowest face-contour point converted with `pointsInImageCoordinates(_:origin: .upperLeft)`; eyes ordered by x because Vision names them from the viewer's side; eye-line roll computed from the pupils; chin chosen as the contour point farthest down the head axis; `GeneratePersonSegmentationRequest` at `.accurate` (falls back to `.balanced`, then to no mask) scanned for the farthest foreground pixel above the eyes along the head axis within ±0.6 IED of it, so headphones beside the head do not count. Segmentation is a prior, never a dependency.
- `App/Features/PhotoWorkflow.swift` — analysis runs after import on the bounded preview, is guarded by photo identity, applies the automatic composition once when exactly one face is found, and exposes `automaticAdjustment` so Reset returns to it. Export does not cancel a running analysis.
- `App/Features/ContentView.swift`, `AlignmentPresentation.swift` — status card with symbol and text per check (never colour alone), "Align automatically" replacing Reset when a solution exists, a Straighten slider, an explicit note when analysis is unavailable on the device, and a "no headphones, earbuds, hats, or other accessories" line in the requirements checklist.
- `scripts/face-harness.sh`, `scripts/face-harness/main.swift` — compiles the same domain and adapter sources for macOS and runs them over `pics/` (git-ignored), writing `report.txt`, annotated previews, the raw person mask, and the aligned 26 × 32 crop per picture to `Artifacts/face-report/` (git-ignored).

## Environment

- Xcode 27.0 (27A266a), Swift 6.4, Swift 6 language mode, strict concurrency; iOS 27 SDK; deployment target iOS 26.0.
- iOS simulators: iPhone 17 Pro on iOS 26.0 and "IDPhoto iPhone 15 Pro Max iOS 27" on iOS 27.0.
- macOS 26.6.2 on Apple Silicon for the Vision harness.
- Fixtures: five webcam portraits of one consenting adult, 1440 × 960, short hair, no glasses, camera below eye level, plus one iPhone selfie with a 35° head tilt and over-ear headphones (1290 × 1745, cropped from a screenshot); stored locally only (ADR-027).

## Validation evidence

| Check | Result |
|---|---|
| Domain and pipeline suites (iOS 26.0 and 27.0 simulators) | 38 Swift Testing tests pass, including tilted-head measurement and head-frame round trips; the private-fixture test records one known issue because Vision cannot create an inference context on these simulators |
| UI flows (both simulators) | Four XCUITests pass, including the composer flow; the editor shows the "not available on this device" note in the simulator |
| macOS harness on six portraits | Every picture: one face, mask crown chosen with confidence 0.9, mask/anatomy divergence within ±0.2 IED, head 74 % as targeted, analysis 50–120 ms per picture after a 2 s model load |
| Physical iPhone 15 Pro Max, iOS 26.6.2 (user run) | Import, analysis, and the status card worked; the tilted selfie was correctly reported as tilted 35° and turned sideways. Before the head-axis fix it was also cropped too tightly, which motivated this revision |

Harness output (private pictures, index only):

| # | IED px | Roll eye/Vision | Yaw | Pitch | Mask − anatomy (IED) | Implied k | Rotation | Overall | Non-pass checks |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 138 | −10.5 / −6.5 | 9.3 | 7.3 | 0.01 | 1.80 | 10.5 | warn | roll, yaw, pitch |
| 1 | 97 | −4.2 / −0.4 | 5.1 | −2.9 | 0.11 | 1.86 | 4.2 | warn | resolution (warn), yaw |
| 2 | 192 | −2.8 / 0.7 | 2.0 | 16.0 | 0.20 | 1.91 | 2.8 | warn | pitch |
| 3 | 133 | −1.4 / 0.9 | 8.3 | −0.2 | −0.04 | 1.78 | 1.4 | warn | yaw |
| 4 | 59 | −2.2 / 1.6 | 1.6 | 4.4 | 0.04 | 1.82 | 2.2 | fail | resolution (fail) |
| 5 | 224 | 35.6 / 28.7 | −4.8 | 0.8 | 0.06 | 1.83 | 0.0 | warn | roll |

Visual review of the annotated previews and aligned crops: the mask crown sits on the top of the hair, also on the tilted selfie where it is measured along the head axis and ignores the headphones; the pupils are on the irises; the chin point sits 2–4 % of head height below the visible chin (on the neck shadow), which slightly enlarges the head estimate; the aligned 26 × 32 crops are credible ID compositions with levelled eyes, and the 35° selfie gets a loose crop containing the whole head while the status card says to retake.

Covered by unit tests: crown agreement/hair-volume/bad-mask/cut-off/no-mask branches; well-framed face lands on the 74 % / 42 % targets and round-trips through the editor model; tilt of 4° is corrected and 12° is reported instead; a small face fails resolution, hits the zoom limit, and fails overall; a face near the top keeps the crop inside the source; multiple faces fail, hair volume becomes a manual check, no mask becomes a warning; rotation clamps to ±8° and invalid values reset to 0; solutions are deterministic.

Fixed during the spike: eye ordering (Vision's "left eye" is image-left, so the initial roll came out near 180°); mask scan direction (bitmap memory row 0 is the top scanline, so the first pass reported every mask as touching the top edge); vertical head measurement (a 35° tilt shortened the vertical chin-to-crown distance by cos 35° and produced an over-zoomed crop on the device; measurements now use the head-aligned frame).

## Findings

1. **k ≈ 1.8 holds for this adult.** Implied ratios of 1.74–1.88 across five shots support the default; calibration on more people (children, receding hairlines, beards) remains open.
2. **Mask and anatomy agree on short hair,** so the fusion rule picks the mask and the crown lands on the visible hair top. Tall hair and headwear paths are only unit-tested so far.
3. **Vision roll and eye-line roll differ by up to 4°.** Eye-line roll is what the crop needs; keep Vision's value for diagnostics only.
4. **Yaw is noisy on webcam shots** (5–9° while facing the camera). Keep yaw and pitch advisory (`warn`), never a hard failure, until calibrated on device photos.
5. **The chin landmark sits slightly low.** Consider using the lowest contour point offset upward by a small fraction of IED, or the `medianLine` end, after checking more faces.
6. **Simulators cannot run Vision here** (iOS 26.0, 26.5, 27.0 all fail with "Could not create inference context"); the macOS harness is the working substitute and a useful permanent tool for private fixtures.
7. **Rotation reveals blank corners** when the crop touches the source edge; the solver keeps the crop inside the source but does not yet enlarge the margin for rotation.
8. **Large tilts are measured, not fixed.** Levelling a 35° selfie would rotate the torso and background by 35°, so the app keeps the loose crop, reports the tilt, and asks for a retake; tilts up to 15° are levelled automatically and anything above 8° is still flagged.

## Limits and next evidence

1. Run the private-fixture test on a physical iPhone (signing required) to confirm identical geometry on iOS 26 and 27 with the pinned revision.
2. Extend the local corpus: glasses, beard, tall or curly hair, head covering, a child, strong tilt, and a photo with two people; record each outcome against FR-156.
3. Compensate the chin bias and re-check head height against a hand-measured crown-to-chin on a few pictures.
4. Add margin for rotation so levelled crops never show blank corners.
5. Decide whether `GenerateForegroundInstanceMaskRequest` should replace or complement person segmentation for the crown prior once spike S1-018 evaluates edge quality.

**Outcome:** Keep. Automatic alignment is credible on the available fixtures and the domain solver is fully unit-tested. ADR-039 and ADR-040 stay Proposed until device evidence and a wider corpus exist.
