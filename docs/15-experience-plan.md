# 15 — Experience plan: beautiful, easy, fun

**Date:** 2026-09-16  
**Status:** In progress. Decisions in §8 taken with the defaults on 2026-09-16; stage A shipped as 0.9.0, stage B as 0.10.0.  
**Builds on:** [04-ux-ui.md](04-ux-ui.md) (principles and screen catalogue), [11-ios-excellence-strategy.md](11-ios-excellence-strategy.md) (signature experiences), the spike app at version 0.8.2.

## 1. Where we are

The spike app does everything the product needs for Spain DNI: guided capture with live aids, automatic alignment, white background, Document Tone, several people per sheet, exact print sheets, digital JPEGs. It works on the user's iPhone. It also looks like what it is: one long developer screen that grew a section per spike.

Audit of the current experience, screen by screen:

| Screen today | What is wrong for a normal person |
|---|---|
| Main screen (one scroll) | Header, photo strip, crop, alignment card, background card, tone card, four sliders, buttons, print summary, export button, legal text, version. Eleven things compete; there is no sense of "step 1, 2, 3". Terms like "Edge softness", "Strength", "ICAO", "mask" leak through. |
| Empty state | A grey placeholder and three equal buttons. No invitation, no idea what the app will do. |
| Camera | Good. The hint, the readiness row, the Auto toggle and the debug line share the top; the debug line must go in release; the countdown is a bare number. |
| After capture | The photo appears in the crop with no transition; nothing says "we found your face and framed it"; the checks are a list of sentences. |
| Print sheet | A functional settings list. The live preview is the best part and sits in a small cell. Cutting options read like a print-shop form. |
| Export | A list of share links and instructions. Success has no moment. |
| Language | English only. The product name is "Foto carnet" and the first market is Spain. |
| Identity | No icon, default tint, no consistent voice. |

## 2. What "beautiful, easy, fun" means here

- **Beautiful**: the portrait is the hero on every screen; system typography, materials and Liquid Glass inherited from standard controls; one accent colour; generous space; nothing decorative on top of a face.
- **Easy**: one obvious action per screen; four steps that a first-time user can name (Take, Check, Sheet, Share); no term a person would need to look up; the automatic path needs zero adjustments for a decent photo; every adjustment is reversible and explained in one line.
- **Fun**: a few moments that feel alive and reward doing it right: the readiness circles filling, the countdown ring closing into the shutter, the photo "landing" into its official frame, the sheet re-flowing as copies change, a quiet success tick at the end. Calm delight, no confetti (strategy §4).

Success criteria for this plan:

1. A first-time user goes from launch to a shared sheet in under 60 seconds without reading help.
2. No technical term in the fast path (pixels, DPI, mask, segmentation, ICAO, strength, softness, bleed).
3. Every screen legible and operable at the largest accessibility text size and with VoiceOver; the UI test accessibility audits stay green.
4. Spanish and English complete; no truncated or clipped strings in either.
5. Reduce Motion and Reduce Transparency respected on every animation and material.

## 3. Target flow

Four steps, one `NavigationStack`, system sheets only for contained choices (UX doc §8).

```
Home ──▶ Camera (full screen) ──▶ Photo Check ──▶ Your Sheet ──▶ Share
  │                                  │  └─ Adjust (sheet)      └─ Print (system)
  └─ Choose Photo (system picker) ───┘
```

### Home
- Title "Foto carnet", one line of promise: "Una foto de carnet correcta en un minuto. Se queda en tu iPhone."
- One large primary button: **Take Photo**. Secondary: **Choose Photo**.
- Document card: "España · DNI, pasaporte · 26 × 32 mm · fondo blanco" with a chevron to requirements (source and date shown there, not here).
- If a session exists: a "Your sheet" card with the people's faces as small circles, the copy count, and **Continue**.
- Footer: privacy line and version, tertiary.

### Camera (exists; polish)
- Keep: preview, oval guide, one hint, readiness row, eye line, Auto.
- Change: the four readiness circles become one ring around the shutter that fills as segments turn green; when "Ready" the ring closes and the countdown runs inside it; the shutter morphs into a tick on capture. The hint capsule stays the only text. Debug line becomes a hidden developer option (long-press on the version on Home) instead of showing in every debug build.
- Reduce Motion: the ring fills without animation and the countdown is a plain number.

### Photo Check (new screen)
- Transition: the captured frame appears full screen, then scales and slides into the official 26 × 32 frame while the background fades to white (Signature 2). It communicates "we found you and framed you". Duration 600 ms; Reduce Motion crossfades.
- Portrait card with the final look (crop, white background, tone), large, on a plain surface.
- Status headline in one of three states, each with a symbol, a colour and text: **Looks good** / **A few things to check** / **Better to retake**. Under it at most four rows, plain words: "Head size", "Eyes level", "Background", "Light". A row explains the fix in one sentence when tapped.
- Hold to compare: press and hold the portrait to see the original; release to return. One TipKit tip the first time.
- Actions: **Add to sheet** (primary), **Adjust** and **Retake** (secondary). Continue is available in all three states; the app never blocks a human decision (UXP-04).

### Adjust (sheet over Photo Check)
- The portrait fills the sheet; drag to reframe, pinch to zoom, two fingers to straighten (already supported in the model).
- A floating control cluster at the bottom, standard glass: **Auto** (re-align), **Background** Original / White, **Light** on/off with a small slider revealed on tap, **Compare**.
- Advanced values (exact zoom, degrees, softness) live under **Details**, off the fast path.
- Done applies; swipe down cancels with a confirmation only if something changed.

### Your Sheet (composer, redesigned)
- The live sheet preview is the hero, full width, with the real crops (exists) and a soft paper shadow.
- People row: circles with faces and a copy count each; tap to open a small stepper popover; **Add person** at the end of the row (camera or library).
- Paper as horizontal chips with tiny paper silhouettes: 10 × 15, A4, 13 × 18, Custom. Orientation is automatic; a chip toggles it if someone cares.
- Photo size chips per person only when a second size is added.
- **Options** disclosure: bleed, corner marks, calibration bar, maximum copies, fill order, with one-line explanations.
- Motion: when copies or paper change, placements animate to their new positions (matched geometry per placement id). This is the "fun" of this screen.

### Share (replaces Export list)
- Two cards with real thumbnails: **Print sheet** (Print, Share PDF, Share JPEG pages) and **Digital photos** (one per person, Share all).
- Print is primary when a printer is reachable. The "Actual Size, measure the bar" advice is one short line under the print card, expanded on tap.
- On success: a gentle tick and haptic, then **Done** returns Home with the session kept.

## 4. Cross-cutting work

- **Voice and copy**: short, friendly, second person, no exclamation marks; Spanish as the primary voice, English parallel. A copy table for every hint, check and button lives in the String Catalog with comments for translators.
- **Localisation**: Spanish (es-ES) and English complete via the existing String Catalog; numbers, units and paper names formatted per locale ("10 × 15 cm" vs "4 × 6 in"); right-to-left checked once for layout sanity.
- **Identity**: app icon in Icon Composer (a portrait frame with a soft tick, works at all sizes, no text); one accent colour (proposed: a calm blue-green); launch screen matches Home.
- **Motion and haptics**: `sensoryFeedback` on ready, capture, landing, success; nothing during drags; all animations gated on Reduce Motion.
- **Accessibility**: VoiceOver labels and values for every control, adjustable actions for zoom and position, rotor-friendly status list, Dynamic Type up to AX5 with layouts that wrap rather than shrink, contrast checked over photos (materials behind text), Reduce Transparency fallbacks.
- **Quiet ease**: no onboarding; one TipKit tip each for hold-to-compare and drag-to-reframe; App Intent "Take an ID photo" so Siri, Shortcuts and the Action button can open the camera directly.
- **Empty and error states**: every one has a picture, one sentence and one action.

## 5. What we deliberately do not add

Widgets, Live Activities, filters, stickers, retouching, a chat screen, accounts, cloud, a tab bar, custom share sheets, confetti. Strategy §7 stands.

## 6. Stages and versions

Each stage ships to the user's iPhone as a version and is judged there. Work stays in the spike project until stage D; the Domain, Imaging and Camera layers do not change shape, so promotion to the production project (M2) is a move, not a rewrite.

| Stage | Version | Deliverable | Judged by |
|---|---|---|---|
| A. Structure and words | 0.9 | Done in 0.9.0: four-step flow (Home, Photo Check, Your Sheet, Share) with the Adjust sheet; session card on Home; plain-language checks from one pure mapping with tests; Spanish and English complete (301 strings, Info.plist names); developer details behind a long press on the version line | Can a friend go launch-to-share unaided? Are both languages complete? |
| B. Moments | 0.10 | Done in 0.10.0: the portrait lands into its frame on Photo Check (wide and uncropped while checking, then the crop springs to the solved framing and the white background fades in, with a light haptic); the readiness ring around the shutter (four arcs that turn green, close into a full ring when ready, and host the 2-1 countdown; the shutter turns green and shows a tick while capturing); the sheet preview re-flows with a spring when copies or paper change (each placement is a view keyed by item and copy); "Your files are ready" with a bouncing tick and a success haptic on Share; hold-to-compare from stage A. Every animation is off under Reduce Motion | Does each moment explain something? Nothing flickers or lags on the phone |
| C. Look | 0.11 | App icon, accent colour, glass control cluster in Adjust, paper chips, people row, light and dark, Dynamic Type and VoiceOver audits, App Store-style screenshots from UI tests | Side-by-side screenshots against Apple's own apps; audits green |
| D. Ease and reach | 0.12 | TipKit tips, App Intent, Spotlight for the document profile, print-flow polish, final copy pass, then the M2 production project with the spike code promoted | Launch-to-share under 60 s for a new user; M1 exit checklist |

Estimated effort at the current pace: stage A two sessions, B one to two, C two, D one to two.

## 7. Engineering notes for the stages

- The flow change is mostly `Features/`: `ContentView` splits into `HomeView`, `PhotoCheckView`, `AdjustSheet`, `SheetView`, `ShareView`; `PhotoWorkflow` gains a `step` and per-entry `checkSummary` but keeps its pipeline contract, so the 65 unit tests and the pipeline stay untouched.
- Photo Check rows come from `AlignmentSolution.checks`, `BackgroundAssessment`, `MaskQuality` and `ToneAssessment` through one `CheckPresentation` that maps states to the three headline states and plain words; the mapping is a pure function with tests.
- The landing transition uses `matchedGeometryEffect` between the camera's frozen frame and the Photo Check portrait; the frozen frame is the preview-resolution image already produced by ingest, so nothing waits for the full-resolution render.
- Sheet re-flow animates `Placement` by a stable identity (`itemID` + `copyIndex`), which the solver already provides.
- The readiness ring is a `Canvas` fed by `CaptureReadiness`; no new signals.
- UI tests gain one flow per step and keep the accessibility audits; screenshots from these tests become the App Store set.

## 8. Decisions

Taken on 2026-09-16 with the defaults below (user: "Go ahead"). One addition from the user: the invented 10 × 15 cm paper preset is removed; 4 × 6 in (the same physical sheet) is the default and is labelled "10 × 15 cm · 4 × 6 in".

1. **App name shown to people**: "Foto carnet" (current) vs "ID Photo" for international. **Default: Foto carnet in Spanish, ID Photo in English, same icon.**
2. **Accent colour**: a calm blue-green, a warm orange, or system blue. **Default: blue-green.**
3. **Voice**: friendly and warm ("Perfecto. Ya tienes tu foto.") vs neutral institutional. **Default: friendly and warm, never jokey.**
4. **Where the checks sit**: a dedicated Photo Check screen after capture (this plan) vs checks shown inside the editor as today. **Default: dedicated screen.**
5. **When to move to the production project**: after stage D (this plan) vs immediately. **Default: after stage D.**
