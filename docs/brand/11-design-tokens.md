# Calipic — Design tokens

**Status:** Draft — first executable layer; values are the ones the app already used  
**Date:** 2026-09-17  
**Scope:** Spacing, corner radii, stroke widths, type roles, icon and target sizes, and motion, as SwiftUI constants. Colour is referenced, not defined, here.  
**Derived from:** [`06-identity-exploration-handoff.md`](06-identity-exploration-handoff.md) Step 8, BD-002, BD-003, BD-004, BD-005, BD-018, BD-019, BD-033, [`02-experience-constitution.md`](02-experience-constitution.md) rules 4, 5 and 9, `AGENTS.md` §5–6.  
**Code:** `Spikes/IDPhotoSpike/App/Brand/DesignTokens.swift` (`enum Design`), tests in `Tests/CalipicFrameTests.swift` (`DesignTokensTests`).

This document describes what exists. It does not redesign anything: every value below was read out of the shipping screens, given a role name, and put back. Adopting the tokens produced no visual change (§7).

---

## 1. Why tokens, and why so few

Calipic's interface is native iOS with extreme restraint (BD-002, BD-018). Most of what a design-token system normally holds — colours for surfaces, elevation, component styles — is supplied by the system and must stay supplied by the system (BD-005). What is left to Calipic is small: how far apart things sit, how round its few custom surfaces are, how heavy its few custom lines are, which text style plays which role, and how its few animations move.

Tokens exist so that these decisions are made once, by role, and so that a future change of the product design language (handoff Step 7) is an edit in one file instead of a hunt through views. They are **named by role, not by value**: `Design.Spacing.control`, never `spacing12`.

---

## 2. The roles and their values

All distances are in points. They do not scale with Dynamic Type; text does, and layout follows the text.

### 2.1 Spacing — `Design.Spacing`

| Token | Value | Role | Seen in |
|---|---|---|---|
| `titlePair` | 2 | A title and the detail line directly under it | card titles, check headline |
| `tight` | 4 | A control and its own label | page caption, print-card text, version block |
| `caption` | 6 | A picture and its caption; lines of a note | portrait hint, icon names, privacy note |
| `text` | 8 | A heading and the paragraph that belongs to it | Home promise |
| `row` | 10 | A status glyph and its text; items in a quiet row | check rows, App Icon row, sheet section header |
| `control` | 12 | Neighbouring buttons, stacked or side by side | every button group |
| `cardContent` | 14 | Content inside a card | session, document, print and digital cards |
| `group` | 16 | Blocks that belong to one step | Photo Check, sheet pages, icon grid |
| `block` | 20 | Blocks inside a sheet or a scrolling accessibility layout | Photo Check at accessibility sizes |
| `sectionTight` | 24 | Sections of a short, finished screen | Share |
| `section` | 28 | Sections of a screen | Home, icon picker |

The screen margin is the system's: `.padding()` with no value. It is deliberately not a token.

### 2.2 Corner radii — `Design.Radius`

| Token | Value | Role |
|---|---|---|
| `photo` | 6 | A photo shown as an object: enough to read as paper, never a rounded avatar |
| `tile` | 10 | A symbol tile inside a card |
| `card` | 16 | A card: a tappable or grouped surface |

Buttons, sheets, lists and bars keep the system's shapes.

### 2.3 Stroke widths — `Design.Stroke`

| Token | Value | Role |
|---|---|---|
| `hairline` | 1 | Edges of photos, pages and crop previews; cut marks and the check bar on the sheet preview |
| `separation` | 2 | The ring that separates an overlapping element from what is behind it (session faces, selection badge) |
| `guide` | 2 | Guides drawn over or around a photo or the camera: the Calipic frame, the head oval |
| `guideHighContrast` | 3 | The same guides under Increase Contrast; use `Design.Stroke.guide(for:)` |

### 2.4 Sizes — `Design.Size`

| Token | Value | Role |
|---|---|---|
| `minimumTarget` | 44 | Smallest interactive target (HIG). Only ever a minimum width or height, never a visual size |
| `thumbnail` | 44 | A small square picture in a card or row: session faces, symbol tiles. Equal to the target today, for a different reason |
| `settingsIcon` | 29 | Base side of the app-icon thumbnail in the Home row, scaled with `.footnote` through `@ScaledMetric` |
| `pickerIcon` | 76 | Base side of an icon preview in the picker, scaled with `.body` |
| `completionSeal` | 56 | The completion seal on Share |

SF Symbols are otherwise sized by the text style they sit in (BD-004), not by a point size.

### 2.5 Type roles — `Design.Typography`

System text styles only (BD-003). Every role therefore follows Dynamic Type, Bold Text and the user's language.

| Token | SwiftUI | Role |
|---|---|---|
| `screenTitle` | `.title2` semibold | The one sentence that names a screen's promise or result |
| `statusTitle` | `.title3` semibold | The check headline |
| `titleGlyph` | `.title2` | A large glyph next to a title |
| `cardTitle` | `.headline` | Card and section titles |
| `cardDetail` | `.subheadline` | The line under a card title; summaries |
| `rowTitle` | `.subheadline` semibold | A row's name, next to its detail |
| `note` | `.footnote` | Explanations, privacy and compliance notes |
| `noteDigits` | `.footnote`, monospaced digits | Version and measurements that must not jitter |
| `caption` | `.caption` | Captions under pictures |

Body text has no token: unstyled `Text` is already the system body style.

### 2.6 Motion — `Design.Motion`

A `Motion` wraps an `Animation` that is private to the type. A view can only obtain it through `resolved(reduceMotion:)` — or `resolved(animated:)` where a parent has already made the decision and passes `animated` down — and both return `nil` when nothing should move: the state still changes, without movement. A view therefore cannot use a Calipic animation without answering the Reduce Motion question.

| Token | Curve | Role |
|---|---|---|
| `landing` | spring 0.8 s, bounce 0.12 | The portrait settles into its official frame (Photo Check) |
| `reframe` | spring 0.7 s, bounce 0.1 | A crop moves to a new position |
| `compare` | spring 0.5 s, bounce 0.1 | Press and hold to compare with the original |
| `rearrange` | spring 0.55 s, bounce 0.12 | Photos move to new places on the sheet |
| `backgroundFade` | ease in-out 0.45 s | The processed background fades over the original |
| `guideState` | ease in-out 0.2 s | A camera guide changes colour |
| `landingDelay(reduceMotion:)` | 650 ms / 50 ms | How long Photo Check shows the uncropped photo before framing it |

Motion communicates state or cause and effect (`AGENTS.md` §5). A new token needs a sentence of that kind in its doc comment.

---

## 3. Colour: referenced, not duplicated

Colour already has two single sources of truth, and the tokens add no third:

- **Brand accent** — `Brand.accent`, `Brand.accentFill`, `Color.brandAccent`, `Color.brandAccentFill`, `brandProminentButtonStyle()` and `brandNeutralToolbarItem()` in `App/Brand/BrandRoles.swift`; values in the asset catalog, generated by `scripts/brand/generate-brand-assets.py` (BD-033, BD-037).
- **Status** — `StatusStyle` in `App/Features/StatusStyle.swift`: system semantic green, orange, red and secondary, always paired with a symbol and text, and independent of the accent.

Everything else is a system semantic colour or material (`.primary`, `.secondary`, `.tertiary`, `.fill.tertiary`, `.bar`, `.regularMaterial`). Those are used directly; wrapping them would only hide what they are.

---

## 4. SwiftUI mapping

```swift
VStack(alignment: .leading, spacing: Design.Spacing.section) { … }
Text("Your sheet").font(Design.Typography.cardTitle)
.background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Design.Radius.card))
.strokeBorder(.primary.opacity(0.15), lineWidth: Design.Stroke.hairline)
@ScaledMetric(relativeTo: .body) private var iconSide = Design.Size.pickerIcon
withAnimation(Design.Motion.landing.resolved(reduceMotion: reduceMotion)) { landed = true }
```

Adopted in this pass: Home, Photo Check (including `PortraitView`), Sheet (including the sheet preview), Share, and the icon picker. Not yet adopted, on purpose, to keep the first pass reviewable: the Adjust sheet, the guided camera and its instructions, and the requirements list. They use the same values and can adopt the same tokens without a visual change.

---

## 5. Rules for adding a token

1. **One role, more than one possible home.** A value becomes a token when it names a role that a second screen has, or plainly will have, *for the same reason*. Values that can only ever belong to one view stay in that view (the 20 pt status-glyph column on Photo Check, the tick inside the picker's badge). Two equal numbers with different reasons are two tokens or two literals, never one token: `minimumTarget` and `thumbnail` are both 44.
2. **Name the role.** If the only honest name is the number, it is not a token.
3. **Never for the system's job.** No tokens for screen margins, button or sheet shapes, list insets, bar heights, materials or semantic colours. Use the system API with no value.
4. **Type roles are text styles.** No point sizes, no custom fonts in the product UI (BD-003). The two fixed-size glyphs that exist (`completionSeal`, the camera countdown) are sizes, not type roles.
5. **Motion goes through `Motion`.** No bare `.animation(.spring…)` in a view; every new animation states what it communicates and resolves Reduce Motion.
6. **Changing a value is a design decision.** Record it in `99-brand-decisions-log.md` or the product design language document, and check Light, Dark, Increase Contrast and an accessibility text size.
7. **Keep the file small.** If `DesignTokens.swift` grows past what fits on two screens, the product has probably gained decoration (BD-018).

---

## 6. What is deliberately not tokenised

- **Photo and print geometry.** Crop maths, the 26 × 32 mm aspect ratio, millimetre-to-point scales, sheet page heights (130 / 220 pt): these are product correctness (constitution rule 2), owned by the domain layer.
- **One-off layout maths.** Portrait widths on Photo Check (220 / 300 / 340), the 86 pt share thumbnail, badge offsets, the overlap of session faces, list row insets on the sheet.
- **Opacities of edges and shadows** (`0.15`, `0.25`, shadow radii). They are tuned per surface against a photo and have no shared role yet. Candidates for the product design language, not before.
- **The camera.** Shutter, readiness ring and hint sizes belong to one custom control and change together; they stay local to `CameraView`.
- **The Calipic frame's proportions.** Corner ratio, gap ratio and the 52° sweep are icon geometry and live with the shape (`CalipicFrame.Icon`), sourced from `scripts/brand/build-icon-v2.py`.
- **Haptics.** Too few to need names; they sit next to the state they confirm.
- **Anything the system provides** (rule 3 above).

---

## 7. Proof of no visual change

Method: `UITests/BrandContextUITests.testCaptureBaseline` (`TEST_RUNNER_BRAND_CONTEXT_CAPTURE=1`) was run twice on the same simulator (iPhone Air, iOS 26.5, Light Mode): once with the app built from `origin/main` at 0.11.1, once from the branch that introduced the tokens. The nine screenshots were exported with `xcrun xcresulttool export attachments` and compared pixel by pixel at 1260 × 2736, ignoring the top 7 % (status-bar clock).

| Screen | Differing pixels |
|---|---|
| Home | 0 |
| Home with a session | 0 |
| Photo Check | 0 |
| Sheet | 0 |
| Share | 0 |
| Adjust, Adjust with details | 0 (not adopted; control) |
| Camera instructions, camera unavailable | 0 (not adopted; control) |

The icon picker was compared through the regular suite's `AppIconPicker` screenshot: 0 differing pixels. The regular suite's other screenshots differ only where the capture itself is not deterministic — the Home indicator fading in, a navigation bar's scroll-edge blur settling, and the Adjust shot taken after a slider gesture — and were checked by eye.

Limits: Light Mode, one device size, default text size plus the suite's two accessibility-size shots. Dark Mode and Increase Contrast were not captured; no token touches colour, so no difference is expected there, but it was not measured.

---

## 8. Open points

- Some roles have a single adopter today (`text`, `sectionTight`, `Radius.tile`, `statusTitle`, `rowTitle`, the icon sizes). They are kept because the screens not yet adopted (§4) use the same values for the same roles; if that adoption does not confirm them, they go back to being literals.
- The spacing scale has eleven steps because the screens had eleven. The product design language (handoff Step 7) should decide whether 6/8, 10/12 and 14/16 are really different roles or historical accident, and merge them knowingly — with a visual change, reviewed as one.
- Edge and shadow opacities (§6) want roles once the photo-as-object treatment is specified.
- Adoption in the Adjust sheet, camera and requirements list.
