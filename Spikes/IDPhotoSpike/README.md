# Foto carnet feasibility prototype

Native iPhone app for the first M1 import/render experiment. This is disposable spike code, not the production application or a published DNI-compliance implementation.

## Run

1. Open `IDPhotoSpike.xcodeproj` in Xcode 27 and select the shared `IDPhotoSpike` scheme.
2. Choose an iPhone simulator running iOS 26 or later and run.
3. Take or choose a photo, review the automatic alignment and background, open **Print sheet** to set paper and copies, and select **Prepare Export**.

For the user's iPhone 15 Pro Max / iOS 26.6.2: select a development team under Signing & Capabilities, use an available unique bundle identifier if needed, pair the phone, enable Developer Mode as required, and run. No signing identity is checked into the repository.

Command-line simulator build from the repository root:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Spikes/IDPhotoSpike/IDPhotoSpike.xcodeproj \
  -scheme IDPhotoSpike \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

List simulators, then pass a simulator UUID to the test script:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
scripts/test-spike.sh 'platform=iOS Simulator,id=<simulator UUID>'
```

## Implemented

- PhotosPicker with file-based Transferable import; no broad photo-library permission.
- Immutable, privately stored source; protected and excluded-from-backup working directories.
- ImageIO orientation normalization and a preview bounded to a 1,600-pixel long edge.
- Deterministic 13:16 portrait crop with drag/pinch, labeled adjustable sliders, and reset.
- JPEG at 520 × 640 pixels, sRGB, with new whitelisted metadata. The resolution is an engineering choice, not a sourced official upload requirement.
- Document Tone ([spike 06](../../docs/spikes/06-document-tone.md)): one global, reversible correction (neutral white balance from the original background, Apple's auto-adjustment filters, a ±0.5 EV face-exposure clamp, export sharpening) with a strength slider, before/after toggle, and a measured assessment of exposure, clipping, and colour cast; gated by the document's alteration policy and applied before the background composite.
- Capture aids ([spike 05 addendum](../../docs/spikes/05-guided-camera.md)): head pose relative to the camera with an eye line (Core Motion only decides whether to move the phone or the head), face pitch and distance from a throttled live Vision pass, lighting direction and backlight from the luma plane, face-metered exposure, a four-segment readiness row, and auto capture with a countdown.
- Guided camera ([spike 05](../../docs/spikes/05-guided-camera.md)): AVFoundation front/back capture with permission at point of use, full-quality HEIF stills into the same private staging path as imports, horizon-level rotation, interruption handling, a debounced one-line hint driven by face metadata, a head guide, volume/Action-button capture, and a lens-smudge advisory after import. Needs a physical iPhone; simulators show the no-camera screen.
- Background replacement ([spike 04](../../docs/spikes/04-background-replacement.md)): foreground-instance mask cross-checked with person segmentation, a mask-quality score that keeps the original when separation is unreliable, an assessment of the original background, and a white composite (Spain DNI) with an edge-softness control, applied identically to the preview, the digital JPEG, and the print sheet.
- Automatic alignment ([spike 03](../../docs/spikes/03-face-alignment.md)): pinned-revision Vision landmarks, person-mask plus anatomical crown estimate, ICAO-default composition solver, eye levelling with a Straighten control, and a status card with pass/warn/fail/manual checks. Real-face evidence comes from `scripts/face-harness.sh` on macOS because the simulators here cannot run Vision.
- Several people per sheet ([spike 02 addendum](../../docs/spikes/02-print-composer.md)): up to six photos in one session, each with its own crop, background, tone, sizes, and copies; one digital JPEG per person and one sheet for all; the sheet preview draws the real crops.
- Print composer ([spike 02](../../docs/spikes/02-print-composer.md)): paper catalog plus custom sizes, deterministic guillotine layout solver with per-size copy counts, automatic rotation and paper orientation, adaptive 0–1 mm bleed, corner cut ticks, 50 mm calibration bar, overflow pages, and two fill strategies.
- Sheet output as a PDF with page boxes equal to the paper and one 300 ppi JPEG per page; both verified after writing.
- AirPrint via `UIPrintInteractionController` with photo output type and a `choosePaper` delegate that logs offered papers and prefers bordered paper.
- Post-encoding JPEG format/dimension/metadata checks and PDF page-size verification.
- Native share sheets for JPEG, PDF, and page JPEGs; originals are never modified in Photos.
- Cancellation/revision checks and stale-result cleanup; image processing runs on an actor away from the main actor.
- String Catalog, minimal privacy manifest, Swift Testing, XCUITest, and privacy-safe signposts.

## Versions

The main screen shows `marketing version (build)`, for example `0.3.0 (34)`. The marketing version tracks the spike number (`0.<spike>.<fix>`), and the build number is the git commit count set by `scripts/bump-version.sh <version>` before committing. Commits handed to a device are tagged `v<version>`; `git log --oneline | tail -n +1 | sed -n "$(( $(git rev-list --count HEAD) - <build> + 1 ))p"` maps a build number back to its commit.

## Data lifetime

Imported provider files are copied while their transfer URL is valid. Staged files are removed after ingestion, including failure/cancellation. Replaced/removed sources are deleted. Export files are retained while the export sheet and its system sharing interaction are active, then removed when the export sheet closes. Abandoned working files are cleared on the next app launch. Backgrounding cancels work; active source storage uses complete file protection. No account, backend, analytics, or photo logging exists.

Files deliberately saved/shared by the user are owned by their destination and are not deleted by the app. A photo held only in iCloud may require a system download before import; already-local inputs can be processed offline.

## Private portraits

Put consented test portraits in `<repo>/pics/` (git-ignored) and run `scripts/face-harness.sh`. It writes a report, annotated previews, raw masks, and aligned crops to `Artifacts/face-report/` (git-ignored). The iOS test target contains the same harness; it records a known issue on simulators that cannot create a Vision inference context and runs fully on a physical device.

## Test fixtures

Tests generate colored geometry images at runtime, including EXIF rotations/mirroring, synthetic GPS/comment metadata, HEIC/PNG, Display P3 color, and a 48 MP case. No private photo fixture is committed. Debug builds accept `--uitesting-fixture` to load the generated four-color image through the ingest pipeline. This flag and fixture generator are excluded from Release builds.

## Remaining M1 work

- Physical-device launch, memory/thermal/latency measurements, and broader device coverage.
- Real-camera HEIC/PNG and wider color-profile fixtures beyond the generated JPEG/HEIC/PNG tests.
- Camera, Vision face analysis, segmentation/refinement, calibrated quality checks.
- Full VoiceOver/Voice Control task validation, Dynamic Type/contrast/motion matrix.
- Share destinations and interrupted-share lifetime tests on device.
- Physical print measurements at 100% scaling on two printers, plus the AirPrint paper-list log from a real printer; PDF math alone does not prove printer accuracy.
- Copies-versus-bleed default decision.
- Official profile schema/catalog and complete source-policy validation.

The 80 MP / 150 MB / 16,384-pixel-edge input guards are provisional resource limits, not measured performance budgets. Export decoding is bounded to the resolution needed for the selected crop; Instruments must still establish its real device memory behavior.

No third-party packages or project-generation tools are required. The image-only spike uses Core Graphics for its deterministic crop/scale; it does not create a CIContext. Core Image remains the planned composition layer when segmentation/background work is evaluated.
