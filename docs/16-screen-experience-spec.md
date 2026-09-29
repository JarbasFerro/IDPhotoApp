# 16 — Calipic screen experience specification

**Status:** Active screen contract for the iPhone spike; state and visual evidence tracked below
**Scope:** The current Spain DNI photo flow, including system presentations and exceptional states
**Reviewed against:** SwiftUI source in `Spikes/IDPhotoSpike/App`, ADR-043, and brand documents, 2026-09-28

## 1. How to use this document

This is the target description of **what each current screen should show and how it should behave**. Screen sections identify shipped behavior and remaining gaps explicitly; [the implementation plan](17-screen-experience-implementation-plan.md) owns sequencing. The exact rule result, paper geometry, image dimensions, and available options come from the domain model, never from example copy here. The exact localized strings live in `App/Resources/Localizable.xcstrings`; the copy inventory and control map in §17 connect them to screens.

The current product is a Spain 26 × 32 mm DNI photo spike with a shared print session. The target path is:

```text
Home → Before your photo → Guided camera ─┐
                         → PhotosPicker ───┴→ Photo Check → Choose result ─┬→ Digital Photo → Share JPEG
                                        │                 │                └→ Your Sheet → Print/Share
               Home → Requirements       └→ optional Camera Help
               Home → App Icon                             └→ Adjust
```

There is no profile picker, general Settings, or background-refinement screen in the current app. Camera Help is available from the camera. Section 15 describes later destinations without creating placeholder navigation.

### 1.1 Current-to-target ledger

| Surface or decision | Before this pass | Target and status |
|---|---|---|
| Home profile claim | “Spain · DNI and passport” | **Spain · DNI photo** in code and catalog; source review remains a release dependency. |
| Requirements timing | Full list behind the Home card | Short preflight before every new camera or import action; full list stays available. Implemented. |
| Camera tutorial | Mandatory two-page introduction on first use | Camera opens after preflight; optional short tip and persistent Instructions help. Implemented. |
| Photo Check next step | Add to sheet | Continue to two-choice output screen. Implemented. |
| Digital result | Requires the sheet and a combined export | Direct verified JPEG for the checked person, with no PDF or page generation. Implemented. |
| Print result | Combined print and JPEG cards | Sheet remains first for print; print and page-share actions remain in Share. Implemented; print hierarchy needs device review. |
| Adjust | Native controls below the portrait; gesture alternatives hidden in Details | Native scrolling sheet with labeled Move and Zoom buttons and Details. Implemented; visual spacing under review. |
| Error copy and states | Several generic alerts and dead ends | Recoverable inline/result states and import retry. Partly implemented; see §14. |
| Visual evidence | Older brand screenshots and selected UI-test attachments | New synthetic-fixture captures for each main screen, plus compact/large text and Light/Dark review. In progress. |

This specification follows [the UX principles](04-ux-ui.md), [the experience constitution](brand/02-experience-constitution.md), [the visual identity](brand/07-visual-identity.md), [the executable tokens](brand/11-design-tokens.md), and [the voice guide](brand/12-voice-and-writing.md). The brand decisions log and accepted ADRs win if a proposed detail here conflicts with them. Official requirements and uncertainty come from [the Spain profile research](13-spain-foto-carnet.md) and versioned rule data.

## 2. Whole-app visual and interaction grammar

### 2.1 Feel and hierarchy

Calipic should feel calm, capable, and personal. The photo or physical sheet is the main visual object. The first glance on each screen should reveal one task, one next action, and any issue that blocks or weakens that action. Use negative space to separate stages. Avoid decorative dashboard cards, ornamental gradients, and technical controls on the fast path.

Use a `NavigationStack` for Home → Check → Choose result → Digital Photo or Sheet → print Share, standard sheets for preflight, Requirements, Adjust, and App Icon, `PhotosPicker` for importing, and the iOS print/share UI for output. Preserve system back affordances and swipe-back. The camera is a full-screen capture task. No tab bar is needed.

### 2.2 Shapes, surfaces, and color

| Element | Treatment |
|---|---|
| App background and lists | System background/list surfaces; no branded full-screen fill. |
| Portrait | Exact 26:32 frame, 6 pt corner radius, 1 pt quiet edge, restrained shadow only when it reads as a physical photo. Never crop UI status into the output. |
| Sheet of paper | White rectangle with true paper proportions, 1 pt edge and soft shadow; cut marks and check bar are thin functional lines. |
| Tappable grouped surface | System tertiary fill, 16 pt radius, used only when a whole card is an action or the surface groups one decision. |
| Symbol tile | 44 pt square, 10 pt radius, semantic fill. |
| Avatar in session | 44 pt circle with 2 pt separation stroke; the photo itself remains rectangular elsewhere. |
| Primary action | Native large bordered-prominent button with `Brand.accentFill`. One per state. |
| Secondary action | Native bordered button, menu, link, or plain list row according to purpose. |
| Status | Symbol + words + semantic pass/warn/fail/manual color. A green shape alone never means approval. |
| Camera guide | One continuous white oval around the expected head position, 2 pt or 3 pt in Increase Contrast. It is a composition aid only and appears only in the camera. |
| Other controls | System shape, radius, material, and Liquid Glass behavior. Do not hand-build system button chrome. |

Use teal for primary action, selected choice, and the brand mark. The current working accent values are `#0E6F7C` in Light Mode and `#4FC3D1` in Dark Mode; the filled-button role is `#0E6F7C` / `#25828E`, with high-contrast variants supplied by the asset catalog. Keep status colors independent: pass uses `checkmark.circle` and semantic green; warn `exclamationmark.triangle` and orange; fail `xmark.octagon` and red; manual check `eye` and neutral secondary color. In Dark Mode, the canvas remains quiet, the photo and paper stay visibly white where their content requires it, and controls retain native contrast. Reduce Transparency must leave text readable over the camera.

### 2.3 Type, spacing, and content

Use system text styles with Dynamic Type: `.title2.semibold` for the screen promise/result, `.title3.semibold` for check status, `.headline` for card titles, `.subheadline` for supporting details, `.footnote` for explanations, `.caption` only for actual captions. Use the spacing/radius/stroke values in `DesignTokens.swift`; let native lists, bars, sheets and buttons size themselves. Measurements and counts use localized Foundation formatting and inflection. Keep all user-facing strings in the String Catalog.

Write in short, direct sentences. Name what the user can do, what the app did, and what remains to check. Never imply government approval, certainty beyond the measured checks, or that background replacement is always allowed for every future profile. Prefer “Your photo stays on your iPhone” to abstract privacy badges. Do not use an icon as a substitute for a button label when the purpose is not obvious.

### 2.4 Motion, feedback, and accessibility

Motion should explain cause and effect: capture acknowledged immediately, source becoming framed result, photos rearranging on the sheet, and file preparation completing. The established motion tokens govern those moments. Reduce Motion replaces travel or bounce with immediate state changes or a simple fade. Haptics occur on meaningful ready/capture/landing/completion events, never continuously during drag.

All interactive targets are at least 44 × 44 pt. VoiceOver reads title → main object/status → details → primary action → secondary actions. Each check says its state in words. Voice Control names match the visible action. Large text reflows and scrolls; it does not shrink the portrait's real aspect ratio or hide the next action. Every crop operation also has a non-gesture control. Check Reduce Transparency, Increase Contrast, Differentiate Without Color, Bold Text, Dark Mode, RTL structure, and accessibility text sizes on every screen.

## 3. Screen 1 — Home

**Purpose:** Start a photo quickly and resume the current sheet. **Current source:** `Features/HomeView.swift`.

### Composition, top to bottom

1. Native navigation bar title **Calipic**. Avoid repeating the logo as a large hero. There is no camera permission prompt on arrival.
2. One left-aligned promise in `.title2.semibold`: **“A correct ID photo in a minute.”** Under it, the current supporting paragraph says to take or choose a photo, identifies the Spain DNI use, offers digital or print output, and states that work stays on iPhone. Let it wrap naturally; put longer privacy and acceptance details below.
3. Full-width primary **Take Photo** button with camera symbol. Full-width secondary **Choose Photo** button with photo symbol, 12 pt below. Both open the same short requirements preflight with their source selected. They are native large controls, enabled once private storage is ready; show **Preparing private photo storage…** while it starts. If the session is full, explain the limit next to the disabled action.
4. When an import or file preparation runs, a compact progress row directly beneath the actions: spinner, **“Opening photo…”** or **“Preparing files…”**, then **Cancel**. The row remains in the reading order and announces completion or failure once.
5. If a session exists, a tappable **Your sheet** card before the document card. Show up to four overlapping circular thumbnails, card title, localized people/copy count and paper name, trailing chevron. The whole card opens Sheet. VoiceOver gets one useful combined label rather than reading each decorative face.
6. Tappable document card: 44 pt document symbol tile, **“Spain · DNI photo”**, **“26 × 32 mm · white background”** as secondary text, trailing chevron. It opens full Requirements. Do not imply a passport rule has been verified solely because dimensions match DNI.
7. Quiet trust block: lock symbol plus **“Your photos stay on your iPhone.”** and a sentence that the receiving office decides acceptance. This is supporting text, never an official seal.
8. Optional **App Icon** row with current small icon, label and chevron; only shown when alternate icons are supported. Version `marketing version (build)` is last, tertiary and monospaced digits. Developer details may remain behind the current long press, invisible in normal use.

**Empty/session states:** With no photos, the Home should not show an empty “Your sheet” card. After returning from Share, the current session remains available. Import cancellation simply restores the previous state; an import failure shows a specific, recoverable message and leaves the session intact. Do not let an old failed import replace a newer selection.

## 4. Screen 2 — Photo requirements sheet

**Purpose:** Give useful capture guidance and a traceable source. **Current source:** `RequirementsView` in `Features/HomeView.swift`.

Present a native sheet with a nested `NavigationStack`, inline title **Photo requirements**, and trailing **Done**. Use a native `List` with three sections:

1. **Before you take the photo:** five rows with SF Symbols and plain text: recent color/front-facing photo; plain light background; visible face and eyes with neutral expression; headwear/glasses guidance; even front light. Keep the rows parallel and allow multiple lines. **Refine:** do not state “No hats or sunglasses” without the medical/religious exceptions nearby; avoid turning a nuanced official exception into an absolute rule.
2. **Official guidance:** concise exception note; direct link named **Spanish Ministry of the Interior**; “Source reviewed [date]” as footnote; note that other document types can differ. The link must be visually and semantically a link. Keep the actual review date tied to provenance data, not a stale static string.
3. **What the app does:** one short paragraph about framing, leveling, permitted background/tone preparation, and print output; explicit statement that facial appearance is not retouched and Calipic does not decide acceptance. Any operation not allowed by the selected profile must be absent from the claim. **Current gap:** the spike's review date and guidance are still literal UI strings; versioned profile data must own them before release.

No primary action is needed inside this reference sheet. The user closes it with Done or system sheet dismissal and returns to the same Home position.

## 5. Screen 3 — Optional camera Help

**Purpose:** Give brief capture advice and access to optional automatic capture. **Current source:** `CameraHelpView` in `Camera/CameraView.swift`.

The live camera starts without a tutorial gate. A first-use tip, **Keep your face inside the oval**, briefly takes the place of the live hint and disappears after four seconds. **Help** remains at the top of the camera. It opens a dark native Form with inline **Camera Help** title and **Done** in the toolbar. The **Taking your photo** section has three rows: frame the face, look at the lens and hold still, and use even light without headphones. Its footer explains that the guide only helps frame the source; the result still needs review. A second section has the native **Automatic capture** toggle and a short explanation of the three-second countdown and manual shutter. The form scrolls at accessibility sizes. Opening Help does not request permission or stop the camera session; it cancels any Auto countdown.

## 6. Screen 4 — Guided camera

**Purpose:** Obtain a usable source photo with calm, actionable feedback. **Current source:** `CameraView.swift`, `CameraFramingGuide.swift`.

### Live composition

- Live preview fills the display edge to edge; keep the person's face and shoulders visually primary. Force dark control styling for contrast without painting the image dark.
- Show one compact white oval sized for the visible head, leaving room for hair beyond the detector's face box. Lay it out in the same full-screen displayed-preview coordinates as the face observations. A stable phone movement grows an arrow from the relevant oval edge: straight for translation, curved for tilt, expanding or shrinking at the sides for distance. The cue and the spoken/visible instruction agree. When measured checks settle, the oval turns green; this indicates camera readiness, not official compliance. Lighting leaves the oval neutral. No C-shaped corners or progress arcs. A subtle eye-level line and gentle outer dimming are physical-device prototypes; remove them if they obstruct the subject. The guide is never exported.
- The top edge holds native glass **Cancel** and **Help** controls. The optional **Automatic capture** toggle is in Help so the live camera stays focused on the photo.
- The lower edge holds one message above the shutter on a restrained dark fade. It names the physical phone action, such as **“Move the phone right”**, **“Raise the phone”**, **“Tilt the phone down”**, or **“Bring the phone closer.”** An actionable correction replaces the brief first-use tip immediately; the tip never stacks over the head. On measured readiness, it says **“Ready to take photo”**; this means the live measurable checks have settled, not that the receiving office has approved the result. The preflight and Check screens carry manual requirements.
- Bottom controls: large, familiar white shutter centered and native glass **Switch Camera** on the right when the device has both cameras. No readiness graphics surround the shutter. During Auto countdown, show large 3, 2, 1 numerals inside it; after shutter press show a tick while still capture finishes.

The shutter remains usable in manual mode before every live check is ready; feedback informs rather than traps the user. Hints change only after stable analysis, and spoken announcements are rate limited. VoiceOver shutter value summarizes framing, head position, light, and distance in words. The camera preview and decorative guides are hidden from accessibility navigation.

The first stable Ready transition draws a brief brightening and scale settle on the oval. It then rests; later hint changes do not create a pulsing loop. Reduce Motion switches state without the visual settle. Shutter press fades the guide; a capture failure restores it. The actual still appears for review before Photo Check.

### Camera states

| State | On-screen result and action |
|---|---|
| Permission request / startup | Black camera surface with native progress indicator. Request permission only after the person confirms Open Camera in the preflight. |
| Denied/restricted | **Camera access is off**, short explanation, **Open Settings** and **Choose Photo Instead**. The latter dismisses camera and opens `PhotosPicker` directly. |
| No device camera | **No camera on this device**, then **Choose Photo Instead**, which opens `PhotosPicker`. |
| Interrupted/backgrounded | Keep the preview context, show **“Camera paused. It resumes when the interruption ends.”**; disable shutter, clear Auto countdown, restart when active. |
| Capture in progress | Soft bloom and one haptic, disabled shutter, no duplicate capture. On success show the actual still with Retake and Use Photo; on failure show a plain alert with a retry path. |
| Camera failure | Error headline plus a concrete **Try Again** or **Choose Photo** recovery. Avoid a dead-end `ContentUnavailableView`. |

Developer timing/debug text stays hidden unless developer mode is explicitly enabled. The visual guide must remain understandable in bright, dim, high-contrast, and Reduce Transparency settings.

### 6.1 Camera focus and captured photo review (ADR-045)

The oval remains compact. Try a gentle dimming outside it on a physical phone; do not obscure hair, shoulders, or the lighting context. Prototype a short, low-contrast eye-level line in the oval using measured face roll. Remove it if it covers the eyes or competes with the phone-movement arrow. The existing green oval and spoken **Ready to take photo** remain the settled guidance; manual shutter remains available at any time.

After the still capture finishes, display the **actual captured image** without guide graphics. Show **Review your photo**, **Retake**, and **Use Photo**. Retake returns to the live camera; Use Photo sends the immutable source to Photo Check. Do not show verification or compliance claims on this quick review. Its purpose is a fast look at expression, eyes, and obvious capture mistakes. The review is offered after manual and optional three-second automatic capture.

### 6.2 Shutter feedback (ADR-046)

At shutter press, acknowledge the action with one soft visual bloom and one haptic. Let AVFoundation provide the system shutter sound; do not add a custom sound. Show capture progress until the actual still is available, then reveal the review controls. The transition follows real capture completion rather than a fixed animation deadline. Reduce Motion removes the bloom. Keep the source photo unaltered and do not render a segmentation effect into it.

## 7. Short requirements preflight, system photo selection, and processing bridge

**Purpose:** prevent avoidable source-photo problems before either input path. **Current source:** `Features/PreparationView.swift`, `AppFlow.swift`.

The preflight is a native navigation sheet. Its inline title is **Before your photo**; the first list section names **Spain · DNI photo** and has three icon-and-text rows: face the camera with eyes open; use even light and a plain light background; include the full head and shoulders. The footer asks the person to check expression, glasses, and headwear requirements by eye. A **Full requirements** row pushes the sourced list inside the same sheet. A secondary row switches source (**Choose Photo Instead** or **Take Photo Instead**). The bottom safe-area button uses the already chosen source (**Open Camera** or **Choose Photo**). **Cancel** dismisses without requesting permission or changing the session.

On every entry point—Home, Retake, and Add another person—preserve whether the next photo adds a person or replaces the selected one. After Continue, dismiss preflight before presenting Camera or PhotosPicker. The full requirements navigation must return to this same preflight and retain the source selection.

The **Choose Photo** action opens `PhotosPicker` with image filtering and no broad Photo Library permission. Preserve the system picker UI. On selection, dismiss it and show the existing Home or Check context with a small progress state. For fast work, go directly to Check rather than interposing a branded loading page. If processing lasts long enough to be noticed, say what is happening: **Opening photo…**, **Finding your face…**, **Separating the background…**, or **Preparing files…**. Do not show fabricated percentages.

Picker cancellation is a quiet return. A corrupt, unsupported, or too-small photo gets a plain explanation and **Choose Another Photo**; keep any existing session/photos. Cancellation must stop its job and prevent stale results from changing a later selection. Large 48 MP input must not cause a visibly frozen main thread.

## 8. Screen 5 — Photo Check

**Purpose:** Show the prepared photo and honest, actionable checks. **Current source:** `Features/PhotoCheckView.swift`, `CheckPresentation.swift`.

### Layout and content

1. Native back button; inline title **Your photo** or **Photo N of M**. Trailing neutral trash button with accessible label **Remove Photo**. Tapping it opens a confirmation dialog explaining that copies on the sheet are removed but the original in Photos stays.
2. Large centered 26:32 portrait with paper edge and soft shadow. It should consume the flexible upper area without covering status or actions. It first shows the source while analysis runs; once ready, the portrait settles into the crop and the prepared background fades in. If Reduce Motion is on, switch without travel. The photo never becomes a status-colored card.
3. Short caption below the portrait: **Finding your face…**, **Framing…**, or **Hold to compare with the original**. Press and hold shows the immutable source; release restores the prepared view. An accessibility action **Compare with original** offers the same function and clearly reports which view is showing.
4. Status headline group: progress spinner or state symbol, short title, and short explanatory subtitle. Existing state family: **Checking your photo…**, **Looks good**, **A few things to check**, **Better to retake**. Use pass/warn/fail color only on the symbol, not across the whole portrait.
5. Up to five check rows, from actual analysis: **Head/Face**, **Framing**, **Background**, **Light**, **Sharpness** as applicable. Each row contains state symbol, short semibold label, and plain detail. **Refine:** allow the detail to wrap beneath its title rather than squeeze two text columns on narrow iPhones. A warning's detail ends with a feasible fix. Manual check appears as its own named state and can never be silently converted to pass.
6. Bottom action area over native bar material: full-width **Continue** primary; **Adjust** and **Retake** secondary below (side by side at normal type, stacked at accessibility sizes). Continue opens the output choice. Retake opens a native menu with **Take Photo** and **Choose Photo**; each goes through preflight. A toolbar **Requirements** action opens the full sourced list. Continue remains available after a warning, with the risk clear. If a measurable failure makes output impossible, disable it with a visible reason rather than allowing an inert tap.

The default normal-size screen should show photo, headline, essential checks, and actions without clipping; at large text sizes the entire content scrolls and actions remain reachable. VoiceOver reads the headline once, then each row as “topic, state, explanation.” Announce the final status after analysis, without moving focus away from the user's current control.

**Failure/unknown cases:** No face, multiple faces, tilted or incomplete head, limited resolution, uncertain hair edge, or unavailable Vision must have specific text and a next action. A photo removed while this route is open shows **This photo was removed** and an obvious way back to Home or Sheet.

## 9. Screen 6 — Adjust sheet

**Purpose:** Correct the prepared image while retaining the original and exact output frame. **Current source:** `Features/AdjustSheet.swift`, `CropPreview.swift`.

Present a large native sheet with inline **Adjust** title and **Done** toolbar button. The 26:32 crop preview is centered at the top, capped so controls remain reachable; white photo background, 6 pt corners, quiet 1 pt edge. Below is a brief instruction: **“Drag to move, pinch to zoom.”** Direct drag, pinch and straighten gestures change the same adjustment model that powers the output. Keep the crop's exact aspect and do not let gestures reveal empty pixels in final output.

Below the image, in this order:

1. One row with **Auto** (or **Reset** if no automatic solution) and **Compare**. Auto returns to the recommended composition; Compare is a button-style toggle for the original source. Both are large native controls with selected state spoken.
2. **Background** label and native segmented picker **Original / White**. When separation is running, show spinner and **“Separating the background…”**. If it is low quality, show a symbol and specific hair/shoulder edge warning. If unavailable, disable White and explain that the original remains. The options must obey the selected profile's alteration policy.
3. **Light and colour** native toggle, when allowed. One footnote explains that exposure/tint is evened out and facial appearance is not retouched. A short assessment message follows when available.
4. **Move and zoom** disclosure, before Details. Inside: labeled native buttons **Move Up**, **Move Down**, **Move Left**, **Move Right**, **Zoom In**, **Zoom Out**, and **Reset Position**. Each moves a small bounded step; buttons are an explicit alternative to gestures. VoiceOver and Voice Control use the same names.
5. **Details** disclosure, closed by default. Inside: native sliders **Zoom**, **Left and right**, **Up and down**, **Straighten**, and conditional **Edge softness** / **Correction strength**. Show the actual accessible value and make each slider operable via VoiceOver adjustment. If the crop will print soft, place the warning immediately below the related zoom/position controls.

The current model applies changes immediately, so Done closes the sheet; swipe dismissal preserves the edits. If a future version stages changes, add Cancel/discard confirmation only when edits would be lost. Keep Compare temporary on exit. The portrait must begin below the navigation controls on initial presentation; verify this on compact and large iPhones.

Avoid a permanent floating glass control cluster over the face. If one is explored later, compare it against this native sheet and document why it improves reach and legibility.

## 10. Screen 7 — Your Sheet

**Purpose:** Arrange one or more prepared portraits on real paper. **Current source:** `Features/SheetView.swift`.

Use a native `List` with inline title **Your sheet**. The first section is a live sheet preview in a quiet white page shape with true paper aspect ratio, subtle edge and shadow. Multiple pages are horizontally scrollable; each has **Page N of M** beneath it. The accessible page element states page count and number of placed photos. Beneath preview, show paper name, localized page count, and “placed of requested copies.” If copies cannot fit, show a warning with count and the concrete choices **choose larger paper**, **reduce copies**, or **allow more pages** if available. A genuinely empty layout shows **Nothing to print** with a recovery action.

Each person has a section header with small rectangular portrait, **Your photo** or **Photo N**, and a **Check** button opening that person's Photo Check. Within the section, every print size is a native Stepper row: localized physical dimensions on the left, copy count on the right. Swipe removal is destructive and labeled **Remove**; also provide an accessible non-swipe removal action. **Add another size** opens a confirmation dialog of supported dimension presets. Additional sizes must be clearly identified as sizes, not as alternate document compliance claims.

An **Add another person** menu offers **Take Photo** and **Choose Photo**. At the maximum, show the limit in the disabled row. Explain nearby that each person's photo keeps its own framing/background/light while sharing this sheet.

**Paper** section: native **Paper size** picker with the supported presets, including the current 10 × 15 cm / 4 × 6 in label. Custom selection reveals labeled width and height numeric fields, **Apply custom size**, inline 50–500 mm validation, and the AirPrint nearest-paper explanation. Keep units visible in labels and speakable in VoiceOver. Keyboard should not cover Apply or the bottom Continue button.

**Cutting options** disclosure is closed initially. Inside are native controls in this order: **Orientation** Automatic/Portrait/Landscape; **Safety margin around each photo**; **Corner cut marks**; **50 mm check bar**; **As many copies as possible**; **Order on the page** One size at a time/Mix sizes. The footer explains the safety margin and measurement bar. **Refine:** use short inline help for options whose effect is not visible at preview scale, and ensure default settings produce a correct, useful sheet without opening this section.

A full-width native prominent **Continue** sits in a bottom safe-area bar. Disable it only when the sheet has no printable page or work is running, with the cause visible in the list. Copy/paper changes update the page preview with the established restrained rearrangement motion. Reduce Motion updates instantly.

## 11. Screen 8 — Choose result, Digital Photo, and print Share

**Purpose:** Let the person choose a single digital JPEG or a physical print sheet from the same checked edit. **Current source:** `Features/OutputChoiceView.swift`, `PhotoWorkflow.swift`, `PhotoPipeline.swift`, `ShareView.swift`.

### Choose result

After **Continue** on Photo Check, push a scrollable screen with inline title **Choose result**. A small 26:32 prepared portrait sits beside **Choose your result** and one sentence explaining that framing and adjustments are saved for either path. The primary full-width choice is **Digital Photo**, photo symbol, **“One JPEG for online forms, ready to share.”** The secondary full-width choice is **Print Sheet**, printer symbol, **“Set paper and copies for one or more people.”** Both have chevrons and full-row targets. A footnote asks the person to check expression, eyes, and glasses and says the receiving office decides acceptance. Back returns to the same Photo Check and its edits.

### Direct Digital Photo

Push a native scroll view with inline title **Digital Photo**. While the selected person's JPEG is rendering and being reopened for verification, show **Preparing your photo…** with a spinner. No print layout, PDF, or page JPEG is created. On success show a quiet check symbol, **Your digital photo is ready.**, the selected 26:32 portrait, the app's **JPEG · 520 × 640 pixels** preset, and the remaining manual-check sentence. The full-width primary **Share JPEG** uses the system ShareLink; **Done** returns Home with the session kept. System share cancellation keeps this screen ready. On failure show **Photo not ready**, the plain cause if available, and **Try Again**; keep the source and edit. Back returns to Choose result so the person can choose Print Sheet without reacquisition. The temporary JPEG stays alive while this result and its system share activity are active.

### Print Share

**Purpose:** Deliver the prepared files using familiar system paths. **Current source:** `Features/ShareView.swift`, `PrintController.swift`.

Use inline title **Share**. On entry, show a centered spinner and **“Preparing your files…”** while export and post-export verification run. Do not display a success seal until the files actually exist and checks have passed. On error, show **Files not ready**, one plain cause when known, and primary **Try Again**; keep the sheet settings and source photos intact.

When ready, the top result group contains a 56 pt checkmark seal, **“Your files are ready.”**, and **“Print the sheet or share the photos.”** This is a quiet confirmation with one success haptic and optional non-repeating symbol motion. It must not imply official acceptance. Then:

1. **Print sheet** card: small true-proportion page thumbnail, title, paper/copy/page summary, and a short instruction **“Print at Actual Size (100 %), not Fit to Page. Measure the 50 mm bar before cutting.”** Show **Print** as the primary card action where system printing is available. Beneath it, **Share PDF** and **Share JPEG** for whole pages as native ShareLinks. Do not label a page JPEG as an individual ID photo. If a check bar is off, adapt the instruction so it does not tell people to measure an absent bar.
2. **Digital photo(s)** card: the combined print export also contains one JPEG per person. Show the app's JPEG pixel preset as export metadata, not a sourced official upload requirement. When several people are present, show **Share all** and labels **Photo N** under thumbnails. Each thumbnail is a ShareLink with a complete spoken label. The direct Digital Photo route above remains the simplest way to share just the checked person.
3. Full-width neutral **Done** returns Home with the session kept. System share/print cancellation leaves Share ready for another attempt. Temporary export files are managed through workflow lifetime; they must not disappear while the system share or print controller still needs them.

The two cards should remain visually distinct without becoming a dense export dashboard. Preserve a comfortable hierarchy at large text sizes and make all ShareLink targets at least 44 pt.

## 12. Screen 9 — App Icon sheet

**Purpose:** Let a person choose the Home Screen icon outside the ID-photo task. **Current source:** `Features/AppIconPickerView.swift`.

Use a native sheet with inline **App Icon** title and **Done**. A scrollable adaptive grid has two sections: **People** and **Just for fun**. Each choice shows the approved square icon preview at about 76 pt at default size (scaling with Dynamic Type), then a short two-line name. The selected icon gets a bottom-right circular check badge with a separating ring, semibold label, and VoiceOver selected trait. The entire cell is tappable; the previews keep their true square shape and must not stretch.

A footnote below explains **“Changes the Calipic icon on your Home Screen.”** During the system change, disable duplicate taps and preserve the selected state. If iOS refuses, show a system alert **“We couldn't change the icon.”** with **“Try again in a moment.”** This preference never interrupts capture, Check, Sheet, or Share.

## 13. Shared dialogs, menus, and system surfaces

| Surface | Contents and behavior |
|---|---|
| Remove photo dialog | Destructive **Remove Photo**, explanatory text “The original in your photo library is kept,” native Cancel. Return to a valid route after deletion. |
| Retake menu | **Take Photo** and **Choose Photo**, each with SF Symbol; replacing this entry does not erase other people or print preferences. |
| Add size dialog | Actual supported dimension presets; clear title **Add a size** and sentence that each size gets its own copies. |
| Add person menu | Camera or Photos, same terms and icons as Home. Preserve sheet context while acquiring. |
| Root workflow error | Specific action-oriented title/message rather than generic “Unable to complete” when the cause is known; preserve the current work. |
| Share sheet / print controller | Native system UI; do not create a custom destination browser. Returning or cancelling restores Share with ready files. |

Alerts are for interruptions. Recoverable warnings belonging to a field, check, or export choice appear inline next to that control.

## 14. State and content coverage for implementation

[The per-screen state and recovery matrix](ui/screen-states.md) records triggers, exact visible messages, actions, destinations, and shipped versus target status. The list below is the coverage checklist for visual and test work.

The next UI pass should verify these states as concrete screen variants, not only as hidden code branches:

| Area | Required variants |
|---|---|
| Home | Fresh install; session with one/many people; maximum people; import running/cancelled/failed. |
| Requirements | Long translated text; source unavailable; source review date/outdated-profile notice. |
| Preflight | Camera selected; import selected; source switch; full requirements and return; Cancel; Add/Retake mode preservation. |
| Camera Help | Optional first-use tip; scrollable advice and Automatic capture toggle; accessibility text; return to live camera. |
| Camera | Requesting; running with each hint; ready; Auto countdown cancelled by changed conditions; still capture; denied/restricted; unavailable; interrupted; capture error. |
| Import | Picker cancelled; unsupported/corrupt file; small image; cancellation; successive picks. |
| Photo Check | Checking; good; warning; fail; manual check; no/multiple face; analysis unavailable; low-quality mask; portrait comparison; removed photo. |
| Adjust | Automatic/original; White enabled/disabled; segmenting; mask warning; tone allowed/forbidden; Details expanded; large text; undo/reset. |
| Sheet | One/multiple people; one/multiple sizes; zero/maximum copies; empty; incomplete layout; custom paper invalid; multiple pages; keyboard visible. |
| Share | Preparing; verified files; print unavailable; individual/multiple JPEG; failed export/retry; system share/print cancellation. |
| Output choice / digital | Both choices; removed person; JPEG preparing/verified/failure/retry; Back and Done; cancelled ShareLink; selected-person-only file. |
| App Icon | Current/alternate choice; changing; change failure; supported/unsupported device. |

For every variant, inspect safe areas, one dominant action, localized copy, VoiceOver focus/readout, Voice Control names, Dynamic Type, Dark Mode, high contrast, reduced transparency, and reduced motion. Camera and printing need physical-device and physical-output review in addition to simulator screenshots. UI snapshots should use controlled non-personal fixtures; never commit family or identity photos.

## 15. Future destinations already proposed in planning

These are **not current spike screens**. When the product grows beyond one sourced profile, add a searchable country/document picker between Home and acquisition, with recent/favorite profiles, localized names, exact size, and source/review status. Requirements then reflect the chosen versioned profile. Reuse the camera, Check, Adjust, and output surfaces while deriving all copy/options from that profile.

If background refinement becomes available, reveal it only when mask quality needs help, with a non-freehand accessible alternative and an iOS 26 fallback. Help/Settings should contain real durable needs, not act as filler navigation. These additions require their own screen-level amendment before implementation.

## 16. Review gate

A UI change is ready for implementation review when a reader can trace every visible element to a purpose, every button to an action, every warning to a recovery, and every status to measured evidence or an explicit manual check. Review against the project's ten PR acceptance questions, the String Catalog, and the approved brand decisions. Update this document when a screen's information order, action hierarchy, or behavior changes materially.

## 17. Exact control and copy inventory

Shipped English phrases in the inventory below are String Catalog keys unless identified as a calculated template; target-only suggestions in §§3–13 still need catalog entries when implemented. The app currently uses English as its source language and supplies Spanish and Brazilian Portuguese. SF Symbols supplement the visible label; Voice Control uses the visible action name. Native Back, picker, print, and share controls retain their system labels. See [visual review evidence](ui/screen-evidence.md) for annotated layouts and observed screenshots.

| Screen/state | Visible copy and shape | Symbol; action or state | VoiceOver / Voice Control |
|---|---|---|---|
| Home | **Calipic**; **A correct ID photo in a minute.**; supporting paragraph in §3 | Navigation title; left-aligned text | Combined promise and support before actions. |
| Home actions | **Take Photo**, **Choose Photo** | `camera`, `photo.on.rectangle`; open preflight with corresponding source | Button names match text; unavailable while storage initializes or session is full. |
| Home progress | **Preparing private photo storage…**, **Opening photo…**, **Preparing files…**, **Cancel** | Native progress; Cancel cancels current job | Progress and Cancel appear in reading order. |
| Home session | **Your sheet**; `^[n person](inflect: true) · ^[n copy](inflect: true) · {paper}` | Overlapping 44 pt circular portraits; card opens Sheet | Combined label **Your sheet: {n} people, {n} copies**; hint **Opens the print sheet.** |
| Home document | **Spain · DNI photo**; **26 × 32 mm · white background** | `person.text.rectangle`, chevron; opens Requirements | Combined card; hint **Shows the photo requirements.** |
| Home trust/settings | **Your photos stay on your iPhone.**; acceptance sentence in §3; **App Icon**; `{marketing version} ({build})` | `lock`, current icon, chevron; App Icon sheet | App Icon value names current selection; version is informational. |
| Preflight | **Before your photo**, **Spain · DNI photo**; three requirement rows and footer in §7 | `person.crop.rectangle`, `sun.max`, `viewfinder` | Rows read in list order; no tap action. |
| Preflight actions | **Full requirements**, **Choose Photo Instead** / **Take Photo Instead**, **Open Camera** / **Choose Photo**, **Cancel** | Native navigation, source switch row, bottom prominent button | Button names match text; switching source closes preflight then opens selected acquisition. |
| Requirements | **Photo requirements**, section/row copy in §4, source link and review date, **Done** | Native list and link; Done closes | Source link has link trait; each multiline row reads fully. |
| Camera | **Cancel**, **Help**, one CameraPresentation hint or first-use oval tip, shutter, **Switch Camera** when available | Glass buttons, one compact oval with an edge-connected phone-movement arrow when needed, green when ready, white shutter, camera switch | Shutter value reads four readiness groups as `{group} {OK / needs attention / not measured}`; spoken cue matches text. |
| Camera Help | **Camera Help**, **Taking your photo**, three advice rows, **Automatic capture**, **Done** | Native scrolling Form and toggle | Advice reads in order; toggle announces its state. |
| Photo Check | **Your photo** or **Photo {n} of {m}**, **Requirements**, **Remove Photo**, portrait caption, status title/subtitle, up to five rows | Source portrait, status symbol; toolbar and rows | Portrait action **Compare with original**; each row reads topic, pass/warn/fail/manual state, then detail. |
| Photo Check actions | **Continue**, **Adjust**, **Retake** → **Take Photo** / **Choose Photo** | Prominent, bordered, menu | Names match text; Retake retains person identity and edits until new source installs. |
| Adjust | **Adjust**, **Done**, **Drag to move, pinch to zoom.**, **Auto** / **Reset**, **Compare**, **Background**, **Original**, **White**, **Light and colour**, **Move and zoom**, **Details** | Native scrolling sheet, segmented picker, toggle, disclosures | Compare announces selected state; unavailable White has adjacent reason. |
| Adjust alternatives | **Move Up**, **Move Down**, **Move Left**, **Move Right**, **Zoom In**, **Zoom Out**, **Reset Position** | Labeled native buttons below portrait | Exact visible names are Voice Control names; edits are bounded. |
| Adjust details | **Zoom**, **Left and right**, **Up and down**, **Straighten**, conditional **Edge softness** and **Correction strength** | Native sliders | Slider value and adjustment work through VoiceOver. |
| Choose result | **Choose result**, **Choose your result**, saved-edits sentence, **Digital Photo**, **Print Sheet**, each description and manual-check footer in §11 | Small portrait, `photo`, `printer`, chevrons; push selected route | Whole choice row is one labeled button with descriptive text. |
| Digital preparing/ready/error | **Preparing your photo…**; **Your digital photo is ready.**; `JPEG · {width} × {height} pixels`; manual-check sentence; **Share JPEG**, **Done**; **Photo not ready**, cause, **Try Again** | Progress, check symbol, 26:32 portrait, ShareLink | Title and file details precede primary Share JPEG; error action repeats export. |
| Sheet | **Your sheet**, `Page {n} of {m}`, people/size/copy rows, **Add another size**, **Add another person**, paper and cutting controls in §10, **Continue** | White paper preview, Stepper, pickers, disclosures | Page describes count/placement; person can be removed without a swipe. |
| Print Share | **Share**, **Preparing your files…**, **Your files are ready.**, print/page and digital cards, **Print**, **Share PDF**, **Share JPEG**, **Done**; **Files not ready**, **Try Again** | Verified result, paper thumbnail, native Print/ShareLinks | Card titles distinguish individual photo JPEG from page JPEG. |
| App Icon | **App Icon**, **People**, **Just for fun**, named choices, explanatory footnote, **Done**, change-failure alert | Square icon grid and selected badge | Cell name and selected trait; system error can be retried. |

**Dynamic presentation keys.** `CameraPresentation.text(for:)` uses **Position your face inside the guide**; **Only one person in the frame**; **Bring the phone closer**; **Move the phone farther away**; **Centre your face in the oval**; **Move the phone left/right**; **Raise/Lower the phone**; **Tilt the phone up/down**; **Raise/Lower the phone to eye level**; **Hold the phone upright**; **Level the phone to match your head**; **Keep your head level**; **Look straight at the camera**; **Hold the phone at eye level**; **Move away from the bright light behind you**; **Find more light on your face**; **Tip: turn slightly to your left/right, towards the light**; **Hold still**; **Ready to take photo**. Each slash pair is a separate localized key. The stabilized cue represents physical phone motion; horizontal direction is derived using lens facing and preview mirroring. A green oval means measured camera checks look ready, never that the photo is officially acceptable.

`CheckPresentation` selects **Checking your photo…** / **Finding your face and preparing the background.**, **Looks good** / **Everything we can measure is fine. Also check by eye: neutral expression, eyes open, no glare on glasses.**, **A few things to check** / **You can continue, or fix the items below first.**, or **Better to retake** / **This photo has problems we can't fix. A new one takes a minute.** Row details vary with measured face, framing, background, light, and sharpness results; the exact localized key is selected in `CheckPresentation.swift` and each row includes the spoken state name from `StatusStyle.name(for:)`. The computed framing percentage is formatted from `solution.headHeightFraction`; it is not a fixed requirement. The JPEG pixel dimensions come from `PhotoFormat.spainPrototype.output`, while paper and copy counts come from the active print job and localized inflection. Requirement provenance and review date belong to the profile source, not to these templates.
