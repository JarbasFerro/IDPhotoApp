# M1 spike 04 — Background separation and white replacement

**Implemented:** 2026-09-16 (app version 0.4.0)  
**Status:** Automatic mask, mask-quality score, original-background assessment, and white replacement implemented in the spike app with macOS Vision evidence on eight private portraits. iOS 27 tap-to-refine, the accessible refinement alternative, and hard-case fixtures remain open.  
**Backlog:** S1-018 (partial); FR-060 to FR-064, FR-067, FR-147. Design: [14-priority-feature-plan.md §3.6](../14-priority-feature-plan.md). Decisions: ADR-004, ADR-037, ADR-041.

## Question

Can Vision's foreground and person masks, scored for quality and composited with Core Image, replace the background with the Spain DNI white deterministically, keep face pixels untouched, and fall back honestly when separation is unreliable?

## Implementation

- `App/Domain/Background.swift` — `BackgroundColor` and `BackgroundChoice` (original or a profile colour; white for Spain), `MaskStatistics` and `MaskQuality.assess` (fail when the inset face box is less than 90 % covered or coverage is implausible; warn for soft edges above 25 % of coverage or foreground on the top row), and `BackgroundAssessment` (mean luminance and deviation of the original background where the mask says background; issues `dark`, `slightlyUneven`, `uneven`; pass only when light and even).
- `App/Imaging/BackgroundSegmenter.swift` — `GenerateForegroundInstanceMaskRequest` with the instance under the eye midpoint and `generateScaledMask` at preview resolution, plus `GeneratePersonSegmentationRequest(.accurate)` resampled to the same size; both are scored and the better one wins. Statistics run on a 256 px downsample. `BackgroundCompositor` uses one shared `CIContext`: 1 px choke (`CIMorphologyMinimum`) to remove the background fringe, Gaussian feather from 0.5 to 3 px at a 1600 px long edge scaled with the image (the Edge softness control), `CIBlendWithMask` over a solid sRGB colour, output rendered to sRGB.
- `App/Imaging/PhotoPipeline.swift` — masks are cached in memory per prepared photo and dropped with it, never written to disk. The same compositor runs on the preview for the editor and on the decoded working image before the crop for the digital JPEG and every sheet raster, so all outputs match.
- `App/Features/PhotoWorkflow.swift` — segmentation runs after face analysis; when the mask passes and the original background is not already plain and light, White is selected by default; Reset keeps the background choice.
- `App/Features/ContentView.swift`, `AlignmentPresentation.swift` — a Background section with the original-background verdict, a mask-quality line when it is not clean, an Original/White segmented control (disabled when separation failed), an Edge softness slider, and an explanation that white is the Spain requirement.
- `scripts/face-harness/main.swift` — per picture: method, statistics, quality, original-background assessment, the raw foreground mask, and a white cutout of the aligned crop.

## Environment

- Xcode 27.0 (27A266a), Swift 6.4, Swift 6 language mode, strict concurrency; iOS 27 SDK; deployment target iOS 26.0.
- iOS simulators: iPhone 17 Pro on iOS 26.0 and "IDPhoto iPhone 15 Pro Max iOS 27" on iOS 27.0 (Vision unavailable; segmentation returns nil and the app keeps the original).
- macOS 26.6.2 for the Vision harness. Fixtures: eight private portraits of one adult, short hair, no glasses, plain wall with shading, a door in frame, one with over-ear headphones and a 35° tilt.

## Validation evidence

| Check | Result |
|---|---|
| Unit suites (iOS 26.0 and 27.0 simulators) | 44 Swift Testing tests pass, including mask-quality thresholds, background-assessment states, statistics on a synthetic mask, compositor output (corners white, face region identical to the source within ±1, feathered edge), and a pipeline export with an installed mask (white corners, coloured person area, original export unchanged) |
| UI flows (both simulators) | Four XCUITests pass; the background control exists and stays disabled where Vision is unavailable |
| macOS harness on eight portraits | Foreground-instance mask chosen every time; inset-face coverage 0.99–1.00; uncertain ratio 0.03–0.06; no top-edge foreground; every mask `pass`; original background judged `warn` or `fail` (mean luminance 0.65–0.76, deviation 0.13–0.20: a white wall with lamp shading and a door in frame); segmentation 60–160 ms per picture after model load |

Visual review of the cutouts: hair, ears, and shoulder edges are clean on all eight; the headphones are kept as part of the subject, which is correct for separation and is handled by the accessories reminder in the checklist. The white replacement makes the aligned 26 × 32 crops look like finished ID photos.

Calibration during the spike: Vision's face rectangle is a little wider than the head, so measuring coverage on the full box scored good masks at 0.83–0.92 and failed them; coverage is now measured on a box inset 15 % horizontally and 10 % vertically.

## Findings

1. **Foreground-instance masks are excellent for single adults** at preview resolution; the person model was never preferred on this corpus. Whether it wins on multi-person or low-contrast scenes is untested.
2. **The original-background assessment is strict by design.** Home walls with shading fail the uniformity test, which matches the DNI wording ("uniform") and is exactly when replacement helps. The wording distinguishes dark-but-plain from uneven.
3. **Face pixels are provably untouched**: the mask is fully opaque inside the face, so the blend returns the source there; the compositor test checks a grid of face pixels.
4. **One compositor serves three outputs.** Preview, digital JPEG, and sheet rasters share the mask and parameters, so what the user sees is what prints (UXP-07).
5. **Unavailable Vision degrades cleanly**: the control is disabled with an explanation and every export uses the original background.

## Limits and next evidence

1. iOS 27 `GenerateIterativeSegmentationRequest` refinement (include/exclude taps, asset download) and the non-freehand accessible alternative (FR-065, FR-066) are not yet built; ADR-041 stays Proposed.
2. Hard cases are missing from the corpus: long or curly hair on a light wall, glasses, a busy background, a child, two people. Add them locally and rerun `scripts/face-harness.sh`.
3. Edge quality at export resolution relies on upscaling a preview-resolution mask; evaluate a full-resolution mask for 48 MP sources against memory (S1-014).
4. Physical-device run of the white export on the iPhone 15 Pro Max, then a printed 26 × 32 to check that the white matches paper white.
5. Colour is fixed to white pending the profile schema (R7-016); other jurisdictions need grey or blue through data.

**Outcome:** Keep. Automatic white replacement is credible on the available portraits with honest fallbacks. Promote the segmenter and compositor with the alignment code after device evidence and hard-case fixtures.
