# M1 spike 01 — Import, crop, and export

**Implemented:** 2026-09-16  
**Status:** First prototype implemented and simulator checks passed; physical evidence pending.  
**Backlog:** S1-001, S1-003, S1-009; initial geometry portions of S1-010/S1-011.

## Question

Can a native SwiftUI prototype import an image privately, preserve its original, crop it to Spain's 26 mm wide × 32 mm high format, and generate verified JPEG/PDF output without decoding the entire source for the preview?

## Implementation

Project and reproducible run/test commands: [IDPhotoSpike](../../Spikes/IDPhotoSpike/README.md).

The app uses PhotosPicker/FileRepresentation, a serial image-processing actor, ImageIO, Core Graphics, Observation, and system sharing. No third-party dependency was added. The staging guard requests only file size rather than a broad file-attributes dictionary. Crop, source pixels, output pixels, physical dimensions, and PDF conversions are explicit domain values. All long-running workflow results carry a revision check; cancellation and late callbacks cannot replace a newer image or present an obsolete export.

The source is immutable. Analysis-quality preview is bounded to a 1,600-pixel long edge, capped at the source size. Export returns to the source and downsamples only to the resolution needed for the selected crop. The JPEG is 520 × 640 pixels in sRGB; this is an engineering resolution choice. PDF places six copies at exactly 26 × 32 mm on A6, independent of raster metadata.

File output is reopened before presenting sharing controls. JPEG validation covers decoding, format, dimensions, orientation, and sensitive metadata. PDF validation covers decoding, page count, and physical page size. A private-file lifecycle covers transfer staging, source replacement/removal, cancelled work, sharing, and next-launch cleanup.

This format is an engineering preset, not an active official-rules catalog entry. The app presents manual-review guidance and links to the sourced DNI reference. It preserves the original background and does not claim automated official acceptance.

## Environment

- Xcode 27.0, build 27A266a; Swift 6.4 compiler, Swift 6 language mode, complete strict concurrency checking.
- iOS 27 SDK; deployment target iOS 26.0.
- Simulator: iPhone 15 Pro Max, iOS 26.5 and iOS 27.0 runtimes.
- Physical test device supplied by the user: iPhone 15 Pro Max / iOS 26.6.2. No physical test or signing evidence yet.
- Local working-tree implementation based on repository commit `c493a77`; no implementation commit created yet.

## Validation evidence

| Check | Result |
|---|---|
| Final domain/image/workflow suite, iOS 26.5 | 14 Swift Testing tests passed, including parameterized cases |
| Domain/image/workflow suite, iOS 27 | 13 tests passed before the final staging-size refinement and its additional test |
| Default UI flows and targeted accessibility audit | Two XCUITests passed on iOS 26.5 and iOS 27 |
| Largest accessibility text size, iOS 27 | Additional UI test passed: scroll to export, prepare files, reach Share JPEG |
| Release build, generic iPhone destination | Passed with signing disabled; this is build evidence, not a device launch |
| Project/resources/docs | Project plist, privacy manifest, String Catalog, shared scheme, shell syntax, local links, and whitespace checks passed |

The final small-image preview cap was exercised on both runtime families. The final staging test proves that the copied file survives removal of the provider's source URL. The three current UI cases passed across targeted runs; earlier failed accessibility test runs remain in ignored local artifacts for diagnosis.

Covered behavior:

- Portrait/landscape/square/odd-sized crop inputs, zoom/translation boundaries, invalid edit values, and exact 13:16 aspect ratio.
- All eight EXIF orientations, preview/export agreement, top/bottom crop placement, and original-byte preservation.
- JPEG/HEIC/PNG ingest, Display P3-to-sRGB output, synthetic GPS/comment metadata removal, and a generated 48 MP input with bounded preview.
- Transfer staging survives provider-file removal without changing the provider original; corrupt input rejection, cancelled-import staging cleanup, late-import replacement protection, and cancelled-export cleanup.
- A6 page dimensions and six nonoverlapping photo rectangles at the specified physical size.
- Empty state → requirements → return; crop adjustment → export; targeted accessibility audit for element detection, hit regions, and sufficient descriptions.

The first accessibility audit stalled on a small text control. Requirements/reset controls were enlarged to 44-point targets; the subsequent targeted audit passed on both OS runtimes. The accessibility-size check exposed drag-to-crop intercepting central scroll swipes. The preview now shrinks at accessibility sizes; the test scrolls outside the portrait and scrolls the export List to its lazily created share row. Empty-state, crop, export, and accessibility-size screenshots were inspected without visible clipping of the content in view.

Local artifacts are ignored by Git:

- `build/Tests-26.5-final.xcresult`
- `build/Tests-27.xcresult`
- `build/Tests-27-final.xcresult` (core tests pass; initial accessibility-size test failure)
- `build/Core-26.5-final.xcresult` (14 core tests pass)
- `build/UI-27-final.xcresult` (default UI checks pass; initial large-text share-row lookup failure)
- `build/Accessibility-27.xcresult` (corrected large-text test passes)
- `Artifacts/` screenshots and exported test attachments

## Limits and next evidence

1. Run on the user's iPhone with signing configured. Measure memory, thermal behavior, latency, interruptions, and repeated imports with Instruments/signposts; simulator timings are not device budgets.
2. Exercise the actual PhotosPicker provider, iCloud download/cancellation, and real-camera images on device. UI automation currently injects a generated fixture into the same ingest path, so it does not prove the provider transfer boundary.
3. Test native share destinations and file lifetimes under interruption/backgrounding. UI tests currently establish export presentation, not every destination's completion behavior.
4. Physically print at 100% and measure copies. Numeric PDF geometry does not establish printer accuracy.
5. Complete VoiceOver/Voice Control manual tasks, contrast/transparency/motion settings, localization expansion, and wider hardware coverage.
6. Continue camera, Vision face analysis, segmentation/refinement, and official rules-catalog spikes. Those capabilities are not part of this first increment.

**Outcome:** Keep the prototype for further M1 evidence. Do not mark M1 complete or promote this code to production architecture yet. The input guards and export defaults remain provisional engineering choices.

## API references used

- [Apple FileRepresentation](https://developer.apple.com/documentation/CoreTransferable/FileRepresentation) — copy received files while the provider URL is available.
- [Apple ImageIO thumbnail creation](https://developer.apple.com/documentation/imageio/cgimagesourcecreatethumbnailatindex(_:_:_:)) — bounded image decoding.
- [Apple thumbnail orientation transform](https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailwithtransform) — upright preview/export coordinates.
