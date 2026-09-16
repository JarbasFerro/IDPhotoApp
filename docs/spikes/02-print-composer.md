# M1 spike 02 — Print composer: paper catalog, packing solver, bleed and cut marks

**Implemented:** 2026-09-16  
**Status:** Solver, renderer, composer UI, and AirPrint bridge implemented; simulator checks passed on iOS 26.0 and iOS 27.0; physical print and printer paper-list evidence pending.  
**Backlog:** S1-019, initial portions of S1-010 and D3-007. Requirements FR-140 to FR-148. Design: [14-priority-feature-plan.md §3.1–3.5](../14-priority-feature-plan.md).

## Question

Can a deterministic, pure-Swift layout engine place several photo sizes with per-photo copy counts on any of the common photo papers (and custom sizes), re-optimize when the paper changes, add pages on overflow, and render print-accurate PDF and JPEG sheets with bleed, corner cut ticks, and a calibration bar, using only Apple frameworks?

## Implementation

Code lives in the disposable spike app ([run instructions](../../Spikes/IDPhotoSpike/README.md)).

- `App/Domain/PrintLayout.swift` — `PaperSize` catalog (10 × 15, 4 × 6 in, 13 × 18, 9 × 13, A6, A5, A4, US Letter, validated custom 50–500 mm), `PrintItem`, `PrintJob`, `PrintOptions`, and `PrintLayoutSolver`. The solver is a two-stage guillotine packer working in integer micrometres. Per page it searches every type order, per-row photo orientation, row-major and column-major stacking, both paper orientations, and the bleed candidates {1, 0.5, 0} mm, with an optional 6 mm strip reserved for the calibration bar. Score order is copies placed, then bleed, then calibration bar, then fewer distinct row heights, then less used length. Pages repeat on remaining demand up to `maxPages`; paper orientation is locked after page 1. Corner ticks are computed from the geometry and clipped so they never enter a neighbouring bleed box.
- `App/Imaging/SheetRenderer.swift` — Core Graphics PDF with the page box equal to the paper (0.25 pt ticks) and one JPEG per page at exactly the paper aspect at 300 ppi (1 px pure-black ticks, no anti-aliasing, DPI tag 300). Rotated placements draw the upright raster turned 90°. The calibration bar is a 50 mm rule with end caps and a localized caption. Post-write verification checks page count, page boxes, JPEG pixel size, and absent GPS metadata.
- `App/Imaging/PhotoPipeline.swift` — `export(photo:adjustment:job:)` renders the digital JPEG as before, solves the job, renders one raster per item and per page bleed (the trim crop expanded by the bleed fraction; white is painted where the expanded crop leaves the source), and writes the sheet files into the private export directory.
- `App/Features/PrintComposerView.swift` — paper picker with custom size entry, orientation, per-size copy steppers (edit/reorder/delete), add-size buttons, cutting options (adaptive bleed, corner ticks, calibration bar, maximum-copies mode, fill order), a `Canvas` page preview with a spoken summary per page, and a layout summary line.
- `App/Features/PrintController.swift` — `UIPrintInteractionController` bridge: `outputType = .photo`, simplex, `showsPaperSelectionForLoadedPapers`, and a `choosePaper` delegate that logs every paper the printer offers (size and printable rect in mm) and prefers a bordered paper of the best size over a borderless one, because borderless printing scales the image.

Defaults: margin 4 mm from the paper edge to the bleed edge (trim edges therefore ≥ 5 mm from the paper edge), gutter 2 mm, bleed adaptive 0–1 mm, corner ticks 3 mm, calibration bar 50 mm. Maximum-copies mode (margin 3 mm, no gutter, no bleed) is opt-in.

## Environment

- Xcode 27.0 (27A266a), Swift 6.4 compiler, Swift 6 language mode, complete strict concurrency; iOS 27 SDK; deployment target iOS 26.0.
- Simulators: iPhone 17 Pro on iOS 26.0 (23A343) and "IDPhoto iPhone 15 Pro Max iOS 27" on iOS 27.0 (24A434).
- No physical device run in this increment.

## Validation evidence

| Check | Result |
|---|---|
| Domain, renderer, pipeline, and workflow suite | 27 Swift Testing tests passed on iOS 26.0 and iOS 27.0, including the parameterized paper × photo table and determinism cases |
| UI flows | Four XCUITests passed on both runtimes: empty state and requirements, crop and export, accessibility text size to export, and the new print-composer flow with a targeted accessibility audit |
| Debug sheet | A rendered 10 × 15 sheet with three 35 × 45 and four rotated 26 × 32 placements was inspected visually: rotation, ticks clipped at gutters, calibration bar, and caption all correct |

Solver capacities per page with default options (copies first, then bleed, then bar):

| Paper | 26 × 32 | 35 × 45 | 51 × 51 | 50 × 70 | 30 × 40 |
|---|---|---|---|---|---|
| 10 × 15 and 4 × 6 in | 12 (bleed 1) | 6 (bleed 0.5, rotated) | 2 | 2 | 8 |
| 13 × 18 | 20 (bleed 0, rotated) | 9 (bleed 1) | 6 | 4 | 14 |
| 9 × 13 | 8 | 4 | 2 | 2 | 5 |
| A6 | 14 (bleed 0, mixed orientation) | 6 | 2 | 2 | 9 |
| A5 | 30 | 15 | 6 | 5 | – |
| A4 | 60 | 30 (bleed 0.5) | 15 | 14 | 42 |
| US Letter | 56 | 29 (mixed orientation) | 15 | 14 | 38 |

Covered behaviour: single-size capacity at or above the plain-grid bound for every preset; exact counts where mixing cannot help (10 × 15 with 35 × 45 = 6; 9 × 13 with 35 × 45 = 4); adaptive bleed (35 × 45 on 10 × 15 keeps 6 copies only at 0.5 mm; a fixed 1 mm bleed drops to 5 per page); the calibration bar is omitted on a full 12-up 10 × 15 sheet and present when space remains; maximum-copies mode places 8 rotated 35 × 45 on 10 × 15 with shared cuts; 30 copies overflow to 5 pages and a 2-page cap reports 18 unplaced; mixed 35 × 45 and 26 × 32 jobs place all copies with correct per-item copy indices in both fill strategies; oversized items are reported, never looped; custom papers validate and lock one orientation across pages; no placement overlaps, all placements respect the margin, ticks never enter a neighbour; identical jobs give identical layouts; PDF page boxes and JPEG pixel sizes match the paper (1181 × 1772 for 10 × 15 cm, 1200 × 1800 for 4 × 6 in); a mid-grey raster lands inside its bleed box with white gutters and a black hairline tick beside it; a mixed sheet export produces every page file and cleanup removes them; an unplaceable job raises a user-facing error rather than an empty file.

Fixed during the spike: the column-major search initially reported the photo orientation relative to the transposed axes, so rotated placements carried upright trim sizes; the invariant test caught it.

## Findings

1. **Mixed-orientation columns beat the plain grid** on A6 (14 vs 12 copies of 26 × 32), 13 × 18 (10 vs 9 of 35 × 45), and US Letter. Because the score ranks copies before bleed, those layouts drop the bleed. Whether users want "more copies" or "safer cutting" by default is a product question for the physical print review; both are one option away in `PrintOptions`.
2. **Bleed costs capacity on tight papers.** A fixed 1 mm bleed turns a 6-up 35 × 45 sheet on 10 × 15 into 5-up. Adaptive bleed is the right default.
3. **The calibration bar rarely fits on a full sheet.** It appears whenever a 6 mm strip is free, which is most non-saturated layouts; the Actual Size instruction stays in the UI regardless.
4. **Ticks need clipping.** With a 2 mm gutter, unclipped 3 mm ticks would cross into the neighbour's bleed; clipping by geometry keeps every mark outside every image.
5. **Solver cost is negligible** for the spike sizes (microseconds to low milliseconds), so the composer recomputes the layout on every edit without caching.

## Limits and next evidence

1. Print the PDF on at least two printers (one Canon, one Epson or HP), bordered and borderless, on 10 × 15 and A4; measure the 50 mm bar and one trim with calipers; record the tolerance (ADR-026). The `choosePaper` log lines record the printer's offered papers and the chosen one.
2. Verify on a physical iPhone that the AirPrint sheet keeps the PDF at 100 % when the paper matches, and record what happens when only a borderless 4 × 6 paper is offered for a 100 × 150 page.
3. The composer places crops of one photo; the multi-person flow (several prepared photos in one job) is supported by the domain model and tests but not yet by the spike UI.
4. Custom paper and Instax-style sizes are export-only; AirPrint snaps to the nearest containing paper.
5. The command-line build did not add the composer's new strings to `Localizable.xcstrings`; sync the catalog from Xcode and review the copy before any localization work.
6. Before promotion: decide the copies-versus-bleed default, move `PaperNames` into localized catalog data, and add VoiceOver task testing of the stepper and preview on device.

**Outcome:** Keep. The solver and renderer are candidates for promotion into the production `Domain/PrintLayout` and `ImagePipeline/Rendering` modules after physical measurement; ADR-036 remains Proposed until then.
