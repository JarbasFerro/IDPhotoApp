# Calipic — Icon size & context sheets (draft v0 stand-in)

**Status:** Evidence / observations + recommendation. Nothing here is approved; BD-033 (colour) remains the founder's decision.  
**Date:** 2026-09-17  
**Inputs:** `docs/brand/06-identity-exploration-handoff.md` §7 step 2, `docs/brand/03-color-strategy-research.md` §5–9, BD-033, BD-036.  
**Icon under test:** `docs/brand/assets/calipic-icon-draft-v0.svg` — **draft v0 stand-in only**.

---

## 1. Read this first: what the stand-in can and cannot tell us

The v0 icon is a flat geometric draft. Its form will be substantially refined and the final icon will receive finishing (shadow, depth, texture). This unit therefore evaluates only:

- **colour** behaviour of the four provisional systems on the mark at real sizes and in real contexts;
- **small-size structure** — which parts of the construction survive rasterisation.

It does **not** evaluate drawing polish. Geometry was not touched: the script only substitutes the mark colour (`#111111`), the field colour (`#FFFFFF`, which also drives the hair-strand cutout so the strand always matches the field) and the grey field stroke. For app-icon realism the field is extended full-bleed and masked with the iOS corner approximation (rx = 22.37 % of width); the mark keeps its exact v0 position on the 1024 canvas. No keyline is drawn on the icon itself, because iOS draws none on the Home Screen.

All palette values are the shared **provisional test values**, not decisions:

| Id | System | Light | Dark |
|---|---|---|---|
| A | Deep blue | `#1F3FA8` | `#7C98F5` |
| B | Dark cyan / blue-teal | `#0E6F7C` | `#4FC3D1` |
| C | Graphite + cool accent | ink `#1C1F24`, accent `#5B7C99` | ink `#F2F3F5`, accent `#9DB7CF` |
| D | Warm challenger (amber-ochre, icon-only) | `#B26A00` | `#F0B55A` |

Treatments: **T1** accent mark on white field · **T2** white mark on accent field · **T3** dark-mode mark on `#111214` field. For C the mark is the ink; the accent is used as the T2 field.

---

## 2. How to reproduce

```sh
scripts/brand/render-icon-sizes.sh                       # default: draft v0 stand-in
scripts/brand/render-icon-sizes.sh path/to/refined.svg   # re-run on a refined icon
scripts/brand/render-icon-sizes.sh refined.svg /tmp/out  # custom output dir
```

Requires `inkscape`, `python3` (stdlib) and `sips`. The script is idempotent (it regenerates only its own output paths) and self-verifies every PNG's existence and pixel size. If a refined icon uses different source colours or key points, override `MARK_HEX`, `FIELD_HEX`, `STROKE_HEX`, `STRAND_WIDTH`, `FRAME_WIDTH`, `PROBES` (see the script header).

Outputs in `docs/brand/prototypes/icon-sizes/`:

| Path | Content |
|---|---|
| `svg/<A-D>-t<1-3>.svg` | 12 recoloured app-icon composites (draft v0 stand-in) |
| `png/<A-D>-t<1-3>-<px>.png` | 108 renders: true vector rasterisation at 1024 / 180 / 120 / 87 / 80 / 60 / 58 / 40 / 29 px (never a downscale of the 1024 render) |
| `sheets/strip-t1…t3.png` | per treatment: 1:1 row, the small PNGs enlarged to 180 px with smooth interpolation, and the same enlarged with the pixel grid visible |
| `sheets/context-home-{light,dark,busy}.png` | iPhone Home Screen (@3x, 60 pt = 180 px), Calipic mid-grid among 11 + 4 dock self-drawn neutral placeholder icons, label "Calipic" |
| `sheets/context-appstore-{light,dark}.png` | App Store search-result row mock (placeholder copy, one neighbouring placeholder result) |
| `sheets/context-lists-{light,dark}.png` | Settings-style list row at 29 pt (87 px) + Spotlight row at 40 pt (120 px) |
| `metrics.tsv` | measured gap openness and hair-strand contrast per variant and size |

Every context sheet is a 4 × 3 matrix: columns A–D, rows T1–T3. Placeholder neighbours are generic glyphs in typical iOS icon colours; none is a real app's logo. They are not re-tinted in the T3 rows (iOS would darken them too), so T3 Home rows slightly overstate how dark Calipic looks relative to its neighbours.

---

## 3. v0 geometry translated to pixels

Nominal widths of the v0 construction at each render size (viewBox units × size / 1024):

| Element | v0 units | 180 px | 120 | 87 | 80 | 60 | 58 | 40 | 29 |
|---|---|---|---|---|---|---|---|---|---|
| Frame stroke | 72 | 12.7 | 8.4 | 6.1 | 5.6 | 4.2 | 4.1 | 2.8 | 2.0 |
| Right opening (net of round caps) | 356 | 62.6 | 41.7 | 30.2 | 27.8 | 20.9 | 20.2 | 13.9 | 10.1 |
| Left gap (net of caps) | 20 | 3.5 | 2.3 | 1.7 | 1.6 | 1.2 | 1.1 | 0.8 | 0.6 |
| Top / bottom gap (net of caps) | 4 | 0.7 | 0.5 | 0.3 | 0.3 | 0.2 | 0.2 | 0.2 | 0.1 |
| Hair strand | 12 | 2.1 | 1.4 | 1.0 | 0.9 | 0.7 | 0.7 | 0.5 | 0.3 |
| Bust base → frame inner edge | 36 | 6.3 | 4.2 | 3.1 | 2.8 | 2.1 | 2.0 | 1.4 | 1.0 |

Measured from the renders (`metrics.tsv`; values are normalised so they are identical for every colour and treatment). *Openness*: 0 = gap reads as mark colour (closed), 1 = reads as field colour (open). It is the best (maximum) value found within ±1 px of the gap centre along the stroke, so it does not depend on where the probe lands. *Strand contrast*: strongest pixel change the strand causes, as a fraction of full mark/field contrast.

| Size | Top/bottom gap openness | Left gap openness | Right opening | Strand contrast |
|---|---|---|---|---|
| 1024 | 1.00 | 1.00 | 1.00 | 1.00 |
| 180 | 0.39 | 1.00 | 1.00 | 1.00 |
| 120 | 0.29 | 1.00 | 1.00 | 1.00 |
| 87 | 0.52 | 1.00 | 1.00 | 0.96 |
| 80 | 0.20 | 0.86 | 1.00 | 0.89 |
| 60 | 0.22 | 0.63 | 1.00 | 0.75 |
| 58 | 0.20 | 0.66 | 1.00 | 0.73 |
| 40 | 0.20 | 0.53 | 1.00 | 0.55 |
| 29 | 0.55 | 0.83 | 1.00 | 0.41 |

The non-monotonic values (87 and 29 px) are pixel-grid phase: at odd sizes a pixel is centred on the sub-pixel gap, at even sizes the gap straddles two pixels and is diluted. That is itself a finding — a feature below ~1 px renders inconsistently from size to size.

---

## 4. Per-size verdicts (structure; same for every colour)

Based on looking at the 1:1 rows, the enlarged strips and the @3x context sheets.

| Size (use) | Frame reads | C reads | Bust reads | Hair strand | Small gaps |
|---|---|---|---|---|---|
| 1024 (marketing) | Yes | Yes | Yes | Yes | Top/bottom already look like hairline slits next to the left gap — inconsistent family |
| 180 (Home @3x, App Store row) | Yes | Yes, immediately | Yes, bun + shoulders clear | Yes, clean 2 px line | Left: yes. Top/bottom: a nick in the stroke, not a gap |
| 120 (Spotlight @3x, Home @2x) | Yes | Yes | Yes | Yes (1.4 px, full contrast) | Left: yes. Top/bottom: nick |
| 87 (Settings @3x) | Yes | Yes | Yes | Marginal — still continuous, slightly grey | Left: yes. Top/bottom: faint notch |
| 80 | Yes | Yes | Yes | Marginal, 89 % contrast | Left: softening. Top/bottom: faint notch |
| 60 / 58 | Yes | Yes | Yes; bun starts merging into the head mass | **Degraded** — 0.7 px, ~75 % contrast, reads as a thin grey scratch rather than a drawn strand | Left: a pinch (63 %). Top/bottom: effectively closed |
| 40 | Yes (2.8 px stroke) | Yes — frame now reads as a plain "C-bracket" because the small gaps are gone | Silhouette yes; bun is a bump | **Fails** — 0.5 px, 55 % contrast, broken dotted diagonal | Left: ambiguous smudge. Top/bottom: closed |
| 29 | Yes but only 2 px; corners go soft | Yes (10 px opening) | Head + shoulders blob; bust base (1 px clearance) visually sits on the frame | **Fails** — 0.3 px, ~40 % contrast; reads as damage/noise across the head, worse than no strand | All small gaps read as random grey pixels |

Summary:

1. **Frame and C are robust at every size.** The wide right opening is the strongest part of the construction and never fails. The "portrait frame first, C second" hierarchy holds down to about 58 px; at 40 px and below the C dominates because the small gaps that say "crop frame" have closed.
2. **The bust reads at every size** as a person silhouette. What is lost below ~60 px is its character (bun separation, neck taper), not its recognisability.
3. **The hair strand survives to 87 px, is degraded at 58–80 px, and fails at 40 px and below.** On an iPhone (@3x) that means it is present on the Home Screen (180), App Store row and Spotlight (120), marginal in Settings (87). It fails in every @2x small context (58/40) and at 29 px. At 29–40 px it is actively harmful — it looks like a rendering defect on the head.
4. **The top/bottom gaps do not exist at any shipping size.** At 4 units net they are under 1 px even at 180 px. The geometry rule "equal small gaps at top, bottom and left" is therefore not true optically: left reads as a gap, top/bottom read as nicks.

---

## 5. Colour and treatment observations (shelf presence)

WCAG contrast of the provisional values, for reference (mark vs field; tile vs test wallpaper):

| | Mark:field T1/T2 | Mark:field T3 | T2 tile vs light wallpaper | T2 tile vs dark wallpaper |
|---|---|---|---|---|
| A | 9.0 | 6.8 | 7.7 | 2.2 |
| B | 5.9 | 9.0 | 5.0 | 3.3 |
| C (ink on white; T2 = white on accent 4.4) | 16.5 / 4.4 | 16.9 | 3.7 | 4.5 |
| D | 4.2 | 10.2 | 3.6 | 4.6 |

White T1 tile vs light wallpaper: 1.17. `#111214` T3 tile vs dark wallpaper: 1.04; vs dark list card `#1C1C1E`: 1.10.

### 5.1 Treatment

- **T1 (accent mark on white)** — On the light wallpaper the white tile has almost no edge, so the icon reads as a floating line drawing with clearly less visual mass than its filled neighbours. On dark and busy wallpapers the white tile is very present, but so are the other white-field placeholders (Notes, Tasks, Web): the brand hue is then carried only by strokes that are 2–4 px wide at list sizes, and **A, B and C become hard to tell apart at 29–40 px** (A reads as near-black navy, B as dark grey-green). T1 is the most "quiet / native" treatment and the weakest colour carrier.
- **T2 (white mark on accent field)** — Holds a solid, consistent tile on all three wallpapers, in the App Store row and in both list appearances. It is the only treatment where the candidate hue is still unmistakable at 29 px. Strand survival is the same as in T1 (the normalised metrics are identical).
- **T3 (dark mode)** — On the dark wallpaper the field is invisible (1.04:1), which is normal for iOS dark icons: the mark floats as coloured line art and reads well at 180 px. In dark Settings/Spotlight cards the tile merges with the card (1.10:1) and depends entirely on the system keyline. Thin coloured strokes on near-black at 87 px keep their hue better than T1 does on white.

### 5.2 Candidates

- **A — Deep blue.** T2 is a strong, calm tile; highest mark contrast of the chromatic candidates (9.0). On the busy wallpaper it sits next to system-blue neighbours (Inbox, Web) but separates by being clearly darker. Risks: in T1 at small sizes it collapses toward black; the dark value `#7C98F5` in T3 drifts toward periwinkle at 87–120 px, which brushes against the no-violet rule and should be re-checked or pulled toward cyan-blue.
- **B — Dark cyan / blue-teal.** Most distinct hue on the shelf in T2: nothing else in a typical icon grid occupies it (the closest placeholder, a brighter teal, stays clearly lighter). T3 `#4FC3D1` is the most legible and most clearly "coloured" dark-mode mark. Mark contrast in T2 (5.9) is adequate but visibly softer than A.
- **C — Graphite + cool accent.** T1 (ink on white) is the crispest rendering of the structure at every size (16.5:1) and the most elegant at 1024, but it has no colour identity on the shelf — it sits with Timer and other monochrome utility icons. T2 on the `#5B7C99` accent field is the weakest tile tested: greyish, low mark contrast (4.4), reads as a muted/disabled utility. T3 is indistinguishable from a generic monochrome dark icon. C's shelf weakness matches the "insufficient App Store differentiation" failure mode predicted in `03` §8.
- **D — Warm challenger.** T2 does add warmth and is distinct from A–C, but it lands inside the existing warm cluster (orange Market, brown Reader placeholders) and camouflages on the warm areas of the busy wallpaper. Lowest mark contrast (4.2): the frame looks thinner and the strand is the first to disappear. T3 `#F0B55A` on near-black is attractive and very legible (10.2). In all treatments the hue sits in the warning family (`03` §6), so it stays an icon-only challenger.

### 5.3 Context notes

- **App Store row (180 px):** everything reads; this context is about tile presence next to the GET button and screenshots. T2 tiles anchor the row; T1 tiles depend on the store's keyline and look like an outline logo. The App Store shows the default icon in both appearances, so T3 rows are for completeness only.
- **Settings 29 pt (87 px):** frame, C and bust all read. Strand is marginal. Hue is readable only in T2 (and in T3 for B and D).
- **Spotlight 40 pt (120 px):** all structure including the strand reads.
- **Busy wallpaper:** the rounded-square tile is what protects the mark. T2 and T3 hold; T1 holds as a white tile; no treatment loses the C.

---

## 6. Recommendation (not a decision)

1. Carry **T2 as the primary shelf treatment** into the next round for the chromatic candidates, with **A and B as the two leaders** on size/context evidence. B has the more ownable hue on the shelf; A has the stronger mark contrast and the more native feel. This unit cannot separate them further — that needs the product-surface and accessibility units.
2. Keep **C-T1 (ink on white) as the restraint benchmark** and as the likely monochrome/reversed variant, but the evidence here does not support C as the primary app-icon colour system. C-T2 on the grey-blue accent should be dropped or its accent re-specified.
3. Keep **D as an icon-only challenger in T3/T2 only**, with its low mark contrast and warning-family conflict noted.
4. Re-check A's dark value for violet drift before any further dark-mode work.
5. Do not select a colour from this document alone; BD-033 stays open.

---

## 7. Input for the later icon refinement

These are constraints derived from rasterisation, not drawing suggestions. Units are 1024-canvas units.

| Topic | v0 | Evidence | Minimum to aim for |
|---|---|---|---|
| Frame stroke | 72 | 4.2 px @60, 2.0 px @29 — holds | Keep ≥ 64; do not go lighter. Anything under ~1.75 px @29 (≈ 62 units) starts to break at corners |
| Right opening | 356 net | never fails | Keep ≥ ~250 net (≈ 7 px @29) so the C survives at 29 px |
| Small gaps (top/bottom/left) | 4 / 4 / 20 net | top/bottom never resolve; left is a 63 % pinch at 60 px | A gap needs ≥ 1.5 px of clear field to read: **≥ 26 units net at 60 px, ≥ 38 units net at 40 px** (with 72-unit round caps that is ≈ 98–110 units centre-to-centre). Make all three small gaps optically equal; v0's are not |
| Small gaps vs C hierarchy | — | widening the small gaps narrows the ratio to the right opening | Keep right opening ≥ 6× the small gap so the C still wins |
| Hair strand | 12 | full contrast ≥ 1.0 px (87 px); fails < 0.6 px | **≥ 22 units to hold at 60 px** (1.3 px); ≥ 32 units to hold at 40 px, which would cut the head in two. Recommend: thicken to ~22–26 units with a tapered end, and **omit the strand in any ≤ 40 px artwork** |
| Single-source icon pipelines | — | if only one 1024 master is supplied, the strand is rasterised by the system at every size | Design the strand to fade out gracefully (taper, no sharp S-bend) rather than alias; test again at 29/40 |
| Bust → frame clearance | 36 (base), 58 (bun top) | base touches the frame visually at 29 px (1.0 px) | ≥ 50 units (≈ 1.4 px @29, 2.9 px @60); also satisfies the handoff's "no accidental tangencies" check |
| Bun / head separation | overlapping ellipses | bun reads to ~60 px, a bump below | Acceptable; if the bun is a signature, give it a clearer neck-in so it survives to 40 px |
| Pixel-grid behaviour | — | 87 and 29 px renders differ from their neighbours because sub-pixel features land on pixel boundaries | After refinement, re-run this script and check `metrics.tsv` is monotonic for every retained feature |

---

## 8. Which conclusions could change once depth / texture / shadow are added

Likely to change:

- **T1's weak tile edge on light wallpapers** — a subtle field tone, inner shade or edge treatment would restore the tile. T1's shelf-presence verdict should be re-tested, not treated as final.
- **T3 merging into dark cards/wallpaper** — a lifted dark field or material highlight changes this.
- **C-T2 looking flat and "disabled"** — graphite systems benefit most from material finish; C may recover some presence. Its lack of hue identity will not change.
- **D's low mark contrast** — depth behind a white mark can add separation; the numeric contrast will not change.
- **Perceived stroke weight** — shadows and bevels make strokes look heavier or lighter; the minimum-stroke numbers in §7 refer to the flat shape.

Unlikely to change:

- Sub-pixel facts: a 12-unit strand and 4-unit gaps cannot be rescued by finishing; texture makes thin negative-space details *harder* to hold, not easier.
- The robustness of the wide right opening and the frame stroke.
- Hue confusability of thin coloured strokes on white at 29–40 px (T1), and D sitting in the warm/warning cluster.
- The relative ranking of tile presence: filled field (T2) > white field (T1) on light backgrounds.

---

## 9. Limits of this test

- Mock contexts are self-drawn approximations of iOS layouts at @3x, rendered by Inkscape; they are not device screenshots. Physical-device checks under bright/dim light (`03` §5) are still required.
- sRGB only; no Display P3 evaluation.
- Increase-Contrast values, grayscale and colour-vision-deficiency simulations are outside this unit.
- Wallpapers are flat synthetic stand-ins; real photographic wallpapers and iOS tinted/clear icon modes are not covered.
- Verdicts are one reviewer's reading of the renders; they are observations to be confirmed by the founder.
