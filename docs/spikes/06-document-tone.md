# M1 spike 06 — Document Tone

**Implemented:** 2026-09-16 (app version 0.6.0)  
**Status:** Global tone correction, policy gate, strength and before/after controls, assessment, and export sharpening implemented; simulator suites and the macOS Vision harness pass. The Studio Light still-image check needs one device session.  
**Backlog:** S1-021; FR-150 to FR-152. Design: [14-priority-feature-plan.md §2.1, §3.7](../14-priority-feature-plan.md). Decision: ADR-038.

## Question

Can one global, reversible correction built only from public Core Image filters make a typical phone portrait look like a studio ID photo (neutral background colour, well-exposed face, no clipping) without touching identity, and can the app measure that claim on every photo instead of asserting it?

## Implementation

- `App/Domain/Tone.swift` — pure Swift. `AlterationPolicy` (allowed, discouraged, forbidden) and `DocumentPolicy` (the engineering default for Spain DNI is allowed with a white background; the M4 rules catalog replaces this). `ToneSettings` (enabled, strength 0…1, default 0.6). `ToneMetrics` (face mean luminance, fraction of face pixels clipped dark and bright, background cast as mean red minus mean blue). `ToneAssessment` flags underexposed (< 0.30), overexposed (> 0.80), clipped (> 0.1 % of face pixels at either end, the ICAO portrait-quality limit) and colour cast (|cast| > 0.06).
- `App/Imaging/ToneAdjuster.swift` — one Core Image chain, all global (ADR-011): (1) neutral white balance as per-channel gains computed in linear light from the mean colour of the original background, applied only when that background is light enough to be trusted as a neutral (luminance ≥ 0.55); (2) Apple's `autoAdjustmentFilters` with crop and level disabled (on the corpus this yields vibrance and a tone curve; face balance and red-eye when Core Image detects a face); (3) a face-exposure step that moves the face's mean luminance towards 0.52 by at most ±0.5 EV; (4) `CIMix` between the source and the corrected image by strength. Export adds a mild unsharp mask (radius 1.2, intensity 0.35 × strength) after the crop is rendered at output size. Measurement helpers compute the metrics and the background reference from a 256 px or 128 px resample.
- `App/Imaging/PhotoPipeline.swift` — the background reference and face box are cached per photo at segmentation time. Tone is applied before the background composite, so a replaced white background stays exactly white and the reference measures the original wall, not the composite. Metrics are exposed for the status card.
- `App/Features/PhotoWorkflow.swift`, `ContentView.swift` — tone is enabled by default when the policy allows it and forced off when forbidden. The Document Tone section has an on/off switch, a strength slider, "Show original for comparison", and an assessment line ("Exposure and colour look right", "A colour cast is visible; the correction neutralises it", and so on). Resetting the crop keeps background, softness, and tone.
- `scripts/face-harness/main.swift` — for each private photo prints face luminance, clipping, cast, the background reference, and the assessment before and after tone at the default strength, and writes `fixture-N-tone.jpg` (tone plus white background) next to the untoned cutout.
- Debug builds only: `NSCameraStudioLightEnabled` in Info.plist and a `studioLightStatus` line in the camera debug overlay, to settle the Studio Light question on device.

## Bugs found by measurement

Both would have shipped without the synthetic test:

1. `CIWhitePointAdjust` with the background colour as its colour tints the image *towards* that colour; the synthetic warm scene went from cast 0.180 to 0.294. Replaced by explicit gains from the linear-light reference (cast 0.180 → 0.000).
2. `CIMix` returns its input image at amount 1 and its background image at amount 0, the opposite of the first wiring; at strength 1 the adjuster returned the source unchanged. Fixed by putting the corrected image on the input side.
3. Gains computed from sRGB values but applied in Core Image's linear working space left a residual cast (0.165); computing them in linear light removed it.

## Environment

- Xcode 27.0 (27A266a), Swift 6.4, Swift 6 language mode, strict concurrency; iOS 27 SDK; deployment target iOS 26.0.
- Simulators: iPhone 17 Pro on iOS 26.0 and "IDPhoto iPhone 15 Pro Max iOS 27" on iOS 27.0.
- macOS harness (`scripts/face-harness.sh`, now compiled for macOS 26) over the eight private portraits in `pics/` (git-ignored, ADR-027).

## Validation evidence

| Check | Result |
|---|---|
| Unit suites (both simulators) | 53 Swift Testing tests pass, including `ToneTests`: thresholds and clamping; strength 0 and "off" return the identical image; strength 1 removes the cast of a synthetic warm scene (0.180 → 0.000) while the face luminance moves less than 0.15 and no clipping appears; strength 0.5 lands between; sharpening keeps size and is identity when off; export applies tone before the white background so the corner pixel stays ≥ 245 |
| UI flows (both simulators) | Five XCUITests pass |
| Build | No concurrency warnings |
| Harness, eight private portraits, default strength 0.6 | Face luminance unchanged or lifted (0.41 → 0.43, 0.43 → 0.46); background cast stays within ±0.015 (the walls were already near-neutral grey, reference ≈ 0.69/0.70/0.69, so white balance had little to do); no photo crosses the bright-clipping limit because of tone; the two photos flagged "clipped" were already clipped in the source |
| Visual | `fixture-N-tone.jpg` versus `fixture-N-cutout.jpg`: slightly brighter, slightly more saturated skin, no visible halo or colour shift; identity is unchanged |

Studio Light: not yet checked. With the debug build's camera open on the iPhone 15 Pro Max, enable Studio Light in Control Center and compare the preview with the captured still; the overlay reports "studio light on/off · active yes/no". The plan's assumption is that stills are unaffected (the effect is a video effect); record the answer here and keep or drop the plist key accordingly.

## Findings

1. **Measure, do not trust filter names.** Two Core Image direction bugs were invisible to the eye on neutral photos and obvious on a synthetic warm scene with numbers. The synthetic test stays as the regression guard.
2. **The corpus is not the hard case.** All eight portraits already have neutral backgrounds and adequate exposure; the white balance path was only exercised by the synthetic scene. Warm indoor light (tungsten, evening) is the next evidence to gather.
3. **Apple's auto filters are conservative and safe.** On these photos they add vibrance and a gentle curve; the face-exposure clamp does the visible work on darker faces.
4. **Tone before background** is the right order; the reference measures the original wall and the replaced white is bit-exact.

## Limits and next evidence

1. Photograph under warm and cool indoor light and confirm the white balance direction and magnitude on real skin.
2. Studio Light device check (above).
3. Face balance and red-eye from `autoAdjustmentFilters` were not observed on this corpus; verify their effect once a photo triggers them.
4. Strength default 0.6 is a judgment; gather user feedback before M3 fixes it.
5. The assessment thresholds are engineering values derived from ICAO guidance, not certified limits.

**Outcome:** Keep. ADR-038 can move to Accepted after the warm-light and Studio Light checks are recorded.
