# 04 — Architecture

How the code is organised today (0.19.0) and the rules it must keep. The engineering contract is [AGENTS.md](../AGENTS.md); this file is the map.

## 1. The shape of the app

One app target, `Calipic`, about 8,000 lines of Swift plus 3,500 lines of tests. Swift 6 language mode, strict concurrency, no third-party dependencies. The Xcode project uses folder synchronisation: a new file in a folder joins the target automatically.

It began as a feasibility spike (`Spikes/IDPhotoSpike`) and became the production app in 0.19 by a rename with `git mv`, so `git log --follow` reaches the spike history. Unit tests are `CalipicTests`, UI tests `CalipicUITests`.

```text
Calipic/
├── App/
│   ├── CalipicApp.swift     start-up, launch flags, document and credits stores
│   ├── Domain/                   pure logic, no UI, no frameworks beyond Foundation and CoreGraphics types
│   ├── Imaging/                  the photo pipeline: files, Vision, Core Image, rendering, export
│   ├── Camera/                   AVFoundation session, live guidance, camera screen
│   ├── Features/                 screens and the workflow model
│   ├── Brand/                    tokens, accent roles, camera frame shape, app icon choice
│   └── Resources/                String Catalog, bundled rules catalog, assets, privacy manifest
├── Tests/                        Swift Testing: domain, pipeline, workflow, presentation
└── UITests/                      XCUITest flows with screenshots
Rules/catalog/v1/                 the rule data (source of truth) and its English strings
scripts/                          version bump, test runner, rules validator and bundler, wording check, brand generators, country ranking
```

## 2. Layers and what belongs where

| Layer | Key files | Owns | Must not |
|---|---|---|---|
| **Domain** | `PhotoGeometry`, `FaceGeometry` (crop solver), `PrintLayout` (paper catalog, layout solver), `DocumentProfile`, `DocumentChoice` (→ `RenderTarget`), `DocumentStore`, `Credits`, `ScreenSize` (true size on the display), `CutPlan` (cutting order), `PhotoMeasurement` (head and eye lines for the current framing), `Background`, `Tone` | Units, coordinate conversion, crop solving, rule interpretation, layout, credit arithmetic. Deterministic and unit-tested | Import SwiftUI, Vision, or AVFoundation; read the clock or the locale for results |
| **Imaging** | `PhotoPipeline` (actor), `FaceAnalyzer`, `BackgroundSegmenter`, `ToneAdjuster`, `SheetRenderer`, `PhotoFiles` | Ingest, analysis, masks, previews, final rendering, file writing and verification | Touch UI state |
| **Camera** | `CameraController`, `FrameAnalyzer`, `CaptureGuidance`, `CameraFramingGuide`, `CameraView` | Capture session, bounded live analysis, the guidance state machine | Decide compliance |
| **Features** | `PhotoWorkflow` (the one `@Observable` model), `AppFlow` (navigation), one file per screen, `CheckPresentation` and other presentation helpers | State, navigation, words | Do geometry or image math |

Views describe UI. They call `PhotoWorkflow`; the workflow calls the pipeline through the `PhotoProcessing` protocol, so tests can substitute it.

## 3. The life of a photo

1. **Acquire.** Camera still or `PhotosPicker` item is copied into a private incoming folder (`StagedPhoto`). Limits: 150 MB, 80 megapixels. A camera still is copied, ingested, and analysed **while the person reviews it** (`PhotoWorkflow.prepareAhead`); **Use Photo** installs it with its analysis done (`useCapture`), **Retake** or **Cancel** deletes it (`discardAhead`). The face model is warmed up when the camera opens (`warmUp`).
2. **Ingest** (`PhotoPipeline.ingest`). Read size and orientation with ImageIO, make a **1,600 px preview**, copy the original into the photo's private folder. The original is never changed.
3. **Analyse** on the preview only. Vision face landmarks → `FaceGeometry` in normalized image space → `CropSolver.solve` for the current `RenderTarget` → a `CropAdjustment`.
4. **Segment** the person, score the mask and the real background, and build the tone reference. The document's background colour is applied by default only when the mask is trustworthy and the real wall is not already plain.
5. **Preview.** `CropPreview` shows the preview image with transforms (no re-render to move or zoom). Background and tone changes re-render the preview through the pipeline.
6. **Export** (only for unlocked photos). The crop is rendered from the **original file** at the output size; print pages are drawn at the paper size (300 ppi, or the profile's minimum, for example 400 for the Netherlands) with cut marks and the check line; files are written, reopened, and verified before the UI offers them.

Changing the document re-solves the crop from the stored geometry with no new Vision work.

## 4. State, concurrency, and stale results

- `PhotoWorkflow` is `@MainActor`. `PhotoPipeline` is an actor. Camera delegates run on their own queues.
- Every long task is tied to an identity: a session `revision`, a photo ID, and an export lease. A result is applied only if its photo still exists and its task was not cancelled. Follow this pattern for all new async work.
- Cancellation propagates: importing, analysis, previews, thumbnails, and exports each have a task that is cancelled when replaced. Going to the background cancels running work.
- Exceptions to strict isolation, each needing its written reason kept next to the code: `nonisolated(unsafe)` capture-session objects in `CameraController`; `@unchecked Sendable` on `FrameAnalyzer` and `PhotoCaptureProcessor`. Do not add more without the proof AGENTS.md §3 asks for.

## 5. Coordinate spaces

Named types, never bare `CGRect`s across layers: source pixels, normalized image space (0–1, origin top-left), preview points, output pixels, millimetres, PDF points. Conversions live in `PhotoGeometry.swift` and `PrintLayout.swift`. Photo axes stay left-to-right even in a right-to-left interface.

## 6. Rules and documents

- `Rules/catalog/v1/` is the source of truth: `catalog.json` (version, profile list, `regionDefaults`), one JSON file per profile with sources, `custom-size-shortcuts.json`, `strings.en.json`.
- `scripts/rules/validate_catalog.py` checks schema, units, ranges, sources, aspect ratios, and that each framing target is physically possible. No rule may be marked as a hard machine check until a calibrated evaluator exists.
- `scripts/rules/build_app_catalog.py` writes the one bundled file `App/Resources/CalipicCatalog.json`; `--check` fails when it is stale.
- In the app: `DocumentProfile` decodes it; `DocumentChoice` (official profile or custom size) produces a `RenderTarget`: trim format, composition spec, digital output spec, file name, page resolution. `DocumentStore` picks the first document: saved choice, then the region default, then ask once.
- Profile names and check labels are String Catalog keys (`profile.<id>.name`, `check.<id>`). Build such a key as a plain `String` before `String(localized:)`; an interpolated literal looks up the wrong key.

## 7. Credits and the export gate

- `CreditLedger` (pure) and `CreditStore` (`@Observable`, balance in `UserDefaults` under `creditBalance`, starting balance 1). `CreditPack.all` holds the three packs and their reference prices.
- `PhotoEntry.isUnlocked`. `PhotoWorkflow.unlock(_:)` spends one credit per locked photo; `relock(_:)` is called when an unlocked photo is edited; changing the document relocks everything.
- **The gate:** `prepareExport()` runs only when no photo is locked; `prepareDigitalExport(for:)` only for an unlocked photo. Edits to an unlocked entry are ignored by the model, so views cannot bypass the freeze.
- Not built: StoreKit, reserve/commit/release, restore, persistence of unlocked photos, the gate for App Intents, copy, and drag (none of those paths exist yet). Capture protection of locked previews exists as a spike (`CaptureProtection.swift`, works on iOS 27.2).

## 8. Privacy and security rules in code

- Everything runs on the device; the app makes no network requests.
- Working files live in a private directory with complete file protection, excluded from backup, wiped at launch (`prepareSession`). Exports are deleted when the screen that needed them goes away.
- Exports carry no location or camera metadata.
- Logs and signposts never contain photos, paths, landmarks, or identifiers of people or documents.
- `PrivacyInfo.xcprivacy` must match real API use. `UserDefaults` is used for the document, the credit balance, and settings.
- No real face may be committed. Test fixtures are generated (`SyntheticFixture`). A private local harness for real portraits exists (`scripts/face-harness.sh`); its inputs and reports are git-ignored.

## 9. Tests and checks

| What | How |
|---|---|
| All tests on a simulator | `scripts/test.sh auto` (first iOS 27 iPhone) or `scripts/test.sh "platform=iOS Simulator,id=<UUID>"` |
| Unit tests only (CI) | `scripts/test.sh --unit auto` |
| Read a result | `xcrun xcresulttool get test-results summary --path <file>.xcresult` |
| Screenshots from UI tests | `xcrun xcresulttool export attachments --path <file>.xcresult --output-path <dir>` |
| Rules | `python3 scripts/rules/validate_catalog.py Rules/catalog/v1` and `python3 -m unittest discover -s scripts/rules -p 'test_*.py'` |
| Bundled catalog is current | `python3 scripts/rules/build_app_catalog.py --check` |
| Plain wording | `python3 scripts/strings/check_copy.py` |

State at 0.19.0: 180 tests (161 Swift Testing, 19 UI), 177 pass, 3 skipped (evidence capture and the private portrait harness, which run only on request).

UI tests launch with flags: `--uitesting-fresh` (Spain DNI, nothing saved, one in-memory credit, print panel suppressed), `--uitesting-fixture`, `--uitesting-fixture-2`, `--uitesting-custom-size`.

CI on GitHub runs the Python checks (rules and wording) and has a Swift Testing job for any change under `Calipic/` (`.github/workflows/swift-tests.yml`). **GitHub's macOS runner has no Xcode 27 yet** (November 2026: Xcode 26.0 to 26.3), so the job warns and skips; it starts testing by itself when Xcode 27 arrives. Until then the gate is local: `scripts/test.sh auto` (all tests, about five minutes) before every commit that touches the app. UI tests stay local even then.

Simulators cannot prove camera behaviour, memory, heat, speed, or print size. Those need a physical iPhone and real prints.

## 10. Performance: what is known

Signposts exist for: camera start, capture, ingest, face analysis, segmentation, tone, composite, render, layout, PDF, export, digital export, and (since 0.17) `HomeAppeared`, `Verdict` (analysis to verdict on screen), and `FilesReady` (unlock to files ready). Subsystem `com.jarbasferro.calipic`.

**There is no full baseline.** The only device numbers are old: on an iPhone 15 Pro Max with iOS 26.6.2 (version 0.5.2, September 2026), camera start took 273 ms and shutter to staged photo 506 ms. On a Mac, face analysis took 50–120 ms per portrait after a model load of about 2 s. Until a proper baseline exists, nothing is a budget. The measuring plan and the ideas for speed are in [roadmap track P](02-roadmap.md).

Known design facts that matter for speed:

- Analysis and previews work on the 1,600 px preview, never the original. Only export reads the original.
- Moving and zooming in Adjust are view transforms. Background and tone changes re-render the preview.
- Segmentation waits for face analysis (it uses the face box), so the two run one after the other.
- Two `CIContext`s exist (segmenter and tone), each created once and reused.
- Sheet thumbnails are 160 px renders from the preview, refreshed when print items change.
- Vision models load on first use, which makes the first analysis after launch slower.

## 11. Lessons already paid for

Found while building; keep them in mind before changing these areas.

**Camera**

- Stills are capped at 12.6 megapixels with balanced quality. Asking for 48 megapixels with maximum quality made the shutter take seconds.
- Face angles must be read from the face object converted to the preview layer's space. The raw metadata angles are relative to the landscape sensor, so a level head reads as 90°.
- After an interruption (lock and unlock), restart the capture session explicitly; the "interruption ended" notice alone leaves a frozen preview.
- The face should fill 12–46 % of the screen (0.20.7; the face box is brows to chin). The first thresholds (30–55 %) forced the phone uncomfortably close; 16 % and a 40 cm distance limit still flipped between "closer" and "farther" at arm's length. "Too close" is now under 30 cm and needs 5 cm of clearance to go away.
- Instructions tell the person how to move the **phone**. Instructions about moving the face confused testers. Left and right depend on the lens and on whether the preview is mirrored.
- Studio Light cannot be offered to third-party photo capture.

**Framing**

- The roll that matters for the crop comes from the eye line, not from Vision's roll value (they differ by up to 4°).
- Yaw and pitch are noisy. They stay advisory: Photo Check uses the camera's limits (turn 20°, nod 15°), not 5°, so a photo the camera called ready is not told to retake (0.20.7). The light check warns at 2 % of the face clipped, not ICAO's 0.1 %, which is three pixels on the analysis image.
- The chin landmark sits slightly low; the crown is an estimate. Crown to chin is modelled as 1.8 × eye line to chin, which held on the portraits tried so far (adults, short hair). Children, tall hair, and headwear are not validated.
- Tilts up to 30° are levelled (0.20.4; was 15°), and the crop is kept inside the source so levelling pulls in no blank corners when there is room. Up to 15° this passes without comment; from 15° to 30° the photo is levelled and Photo Check says so, because the shoulders may look uneven; above 30° the app reports the tilt and asks for a retake.
- Rotation can reveal blank corners when the crop touches the edge of the source.

**Background**

- Vision's foreground-instance mask works well for single adults at preview size. Hard cases are untested: long or curly hair on a light wall, glasses, busy backgrounds, children.
- Mask coverage is measured on the face box inset 15 % horizontally and 10 % vertically; on the full box, good masks failed.
- The mask is fully opaque inside the face, so face pixels are never altered by the composite. A test checks this.
- The export upscales the preview-size mask. A full-resolution mask for large sources has not been evaluated.
- The "is the real wall plain?" check is strict on purpose: ordinary shaded walls fail it, which is when replacement helps.

**Print**

- Capacity per page with default options, for orientation: 10 × 15 cm holds 12 photos of 26 × 32 mm or 6 of 35 × 45 mm; A4 holds 60 or 30.
- Home printers may substitute the nearest paper they offer; the print panel prefers bordered papers. Borderless and Fit to Page are the usual causes of a wrong size.
- The row-by-row fill picks whichever way up fits more photos in each row, so on its own it mixed upright and sideways photos (8 copies on 10 × 15 cm with no margin or check bar: 5 sideways, 3 upright, although 9 upright fit). Since 0.20.6 each orientation is also tried alone, and at equal copies, safety margin and check bar one orientation wins. A mix stays only where it fits more copies. Since 0.20.7 the ranking is: copies, having a safety margin at all, the 50 mm check bar, one orientation, then the margin's size. So a full 12-up 10 × 15 cm sheet keeps the check bar with a 0.5 mm margin (it used to drop the bar for 1 mm), and 10 or 11 copies no longer get a sideways row.
- A sheet with one photo is a fixed grid (0.20.12). Re-planning the page for each copy count flipped it between portrait and landscape and re-centred every photo (8 copies portrait, 10 landscape, 11 portrait), which read as a flash. Now one full-page grid is chosen and filled in reading order as shown on screen; the remaining positions are `PrintPage.freeSlots` (drawn as outlines, never printed). The grid is always the fullest one, whatever the count: in 0.20.12 a roomier 1 mm grid for up to 9 copies was swapped for the 0.5 mm 12-up grid at the 10th copy, and the swap read as a flash. Sheets with several photos keep the per-page search.
- A page whose photos are mostly sideways is shown turned a quarter on screen (`PrintPage.displaysTurned`), so faces stand upright; the printed page is unchanged.

**Testing**

- iOS simulators cannot run these Vision models ("Could not create inference context"). Real-face checks run through the private macOS harness or on a device.
- Tests that capture evidence (frame studies) are skipped unless asked for by environment variable.
