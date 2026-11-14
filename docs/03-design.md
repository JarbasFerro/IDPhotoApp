# 03 — Design

**Part A** is the contract: how the app looks and behaves today (spike 0.16.0). **Part B** is the direction: where the experience should go next. Part B is ambitious on purpose and nothing in it is final; the order of work is in [02-roadmap.md](02-roadmap.md).

Screenshots of every current screen: [ui/gallery/](ui/gallery/). Earlier design rounds and the options that were not chosen: [ui/explorations/](ui/explorations/README.md).

---

# Part A — The app today

## 1. Design language

> **From 0.21 the layout, type, buttons and status marks follow §9 (One table, one tray). Where this section, §2 or §3 says otherwise, §9 wins until the rows are rewritten screen by screen.**

- **Native first.** System navigation, sheets, menus, steppers, pickers, and share and print panels. Liquid Glass comes from the SDK through standard controls. Custom drawing is kept for three things only: the photo, the paper, and the camera guide.
- **The photo is the content.** Chrome stays quiet and neutral. Teal is for the main action, selection, and very few details. Never a teal field around a portrait.
- **Paper is an object.** A photo or page is white, has 6 pt corners (pages have square corners), a hairline edge, and a soft shadow. It is white in Light and Dark.
- **Calm, then alive on change.** Motion and haptics mark cause and effect: the photo landing in its frame, copies moving on the sheet, an unlock. No decorative motion. Every custom animation respects Reduce Motion.
- **Status is never colour alone.** `pass`, `warn`, `fail`, `manual_check` always carry a symbol and words (`StatusStyle`).

## 2. Tokens

All in `App/Brand/DesignTokens.swift` (`Design.…`) and `BrandRoles.swift`. Use a token; do not write a literal.

| Group | Tokens |
|---|---|
| Colour | `Color.brandAccent` (text, glyphs, selection), `Color.brandAccentFill` (filled buttons, badges). Light `#0E6F7C`; Dark accent `#4FC3D1`, fill `#25828E`. Asset catalog holds Increase Contrast values |
| Surfaces | `Surface.screen` (grouped background), `Surface.card`, `Surface.stage` (Home hero), `Surface.mat` (the cutting mat, below) |
| Cutting mat | Photos and pages lie on a teal-grey mat with a fine grid (`#DCE8E6` / `#0E2C2E`, `Stage.swift`), a rounded panel 8 pt in from the screen edges, on Photo Check, Your sheet, Print, Finished, and Digital Photo. **No bare text on the grid:** captions and counts sit below the mat; the measurement chip has a solid background; the navigation bar stays plain, with no tint behind the steps (0.20.1). **The grid is not a scale:** never on Check your print. Home, Adjust, and settings stay plain |
| Paper | One shadow (`paperShadow`: contact edge plus a small spread). In Dark, paper is shown at about 94 % white (`paperDimmedInDark`); exported files are untouched |
| Readouts | Pure measurements ("34 mm", "35 × 45 mm") use the monospaced system design (`Typography.readout`); paper chips use the rounded design (`Typography.sizeChoice`), since monospaced chips felt too technical; sentences with a number keep the text face with monospaced digits |
| Radius | `photo` 6, `tile` 10, `card` 16, `group` 22 |
| Spacing | `titlePair` 2, `tight` 4, `caption` 6, `text` 8, `row` 10, `control` 12, `cardContent` 14, `group` 16, `block` 20, `sectionTight` 24, `section` 28 |
| Type | `hero` (title, bold), `screenTitle` (title2, semibold), `statusTitle`, `cardTitle` (headline), `cardDetail` (subheadline), `rowTitle`, `note` (footnote), `noteDigits`, `caption`. System text styles only |
| Motion | `landing` (0.8 s spring), `reframe`, `compare`, `rearrange` (0.55 s spring), `backgroundFade`, `guideState`. Reach them through `resolved(reduceMotion:)` so the setting cannot be forgotten |
| Size | `minimumTarget` 44 pt for every control |

Buttons: one prominent button per screen (`brandProminentButtonStyle()`, large), secondary actions bordered or plain. Bottom actions sit on the screen background and move into the scrolling content at accessibility text sizes.

## 3. Screens

| # | Screen | What it does | Source |
|---|---|---|---|
| 1 | **Home** | Hero picture: a selfie, the ID photo made from it, and the printed sheet (a generated sample person, D-9; the person's own original, photo and copies once they have one, 0.20.5). Easter egg (0.20.9): a tap on the sample brings the next of nine generated people while the three papers shuffle slightly on the mat (cross-fade only under Reduce Motion; also an accessibility action), the promise "Take it at home. Print it yourself.", the *Your sheet* card (with a menu to remove one photo or all of them, 0.20.2; on Your sheet, touch and hold a person) when a session exists, one card with the document and *Photo requirements*, **Take Photo**, **Choose from Library**, then the privacy line, the credits button, and the version | `HomeView.swift` |
| 2 | **Choose document** | Sheet with search; **Custom size** first, then profiles grouped by country, each country with its flag (also on the Home document card), with size and background. Custom size takes width and height in mm or inches and offers shortcuts | `DocumentPickerView.swift` |
| 3 | **Photo requirements** | The document's rules from the catalog with official sources and the review date | `HomeView.swift` (`RequirementsView`) |
| 4 | **Before your photo** | Three things to get right. Shown in full the first time for each document; after that the camera or picker opens directly (requirements stay in Home, Photo Check's More menu, and Camera Help) | `PreparationView.swift`, `AppFlow.swift` |
| 5 | **Camera** | Full-screen preview, one oval, one instruction about moving the phone, an arrow for direction, green when ready, white shutter, automatic capture with a countdown, off by default since 0.20.19 and switched by a timer button left of the shutter, labelled "Auto: Off" / "Auto: On" (white filled when on), the instruction and the countdown at the top under the front camera so reading them keeps the eyes near the lens, with "Look here ↑" during the countdown (0.20.9); the review says "Your eyes look closed or turned down" and makes Retake the main button when the eyes measured closed, camera switch, Help. After the shutter: the still with **Retake** and **Use Photo**, shown exactly as the preview showed it (same fill, same mirroring; the file keeps the whole unmirrored frame) | `Camera/` |
| 6 | **Photo Check** | The photo settles into the official frame. One verdict (*Looks good*, *Review your photo*, *Better to retake*), shown only once every check, including background and light, has finished, so it never changes a moment later (0.20.9). A card with two short rows (measured checks, the document's by-eye checks) that each open their own half-height list (**Measured**: what to look at, then what looks fine; **Check by eye**), so the screen stays one page (0.20.4); with a single issue the verdict line says what it is. Hold the photo to compare with the original. the document's main output as the prominent button (**Print**, or **Digital Photo** for digital-first documents such as the UK passport), the other output below it, and a plain **Adjust**; **Retake** and a More menu in the toolbar. An unlocked photo says so, and Adjust asks before changing it | `PhotoCheckView.swift`, `CheckDetailsSheet.swift`, `CheckPresentation.swift` |
| 7 | **Adjust** | An editor in a sheet, the photo always in view (0.20.2): the crop with drag and pinch on top, one tool's controls below it, and a tool strip at the bottom: **Crop** (zoom slider, Move and Zoom buttons, framing presets for custom sizes), **Straighten**, **Background** (choice, edge softness), **Light** (light and colour, strength, black and white for custom sizes). Auto/Reset and Compare in the bar. Changing tool never resets a value | `AdjustSheet.swift`, `CropPreview.swift` |
| 9 | **Digital Photo** | Locked: the unlock card and **Unlock and Save**. Ready: the photo, **Share Photo**, **Done** | `DigitalPhotoView.swift` |
| 10 | **Your sheet** | The page as hero with "N copies · M pages · Room for K more" (numbers roll, 0.20.12). One photo fills a fixed grid slot by slot from the top left: adding a copy only adds a photo, the page never changes shape, and the free slots show as faint dashed outlines (0.20.12). A new page slides in empty and its copies drop in row by row. A tray with the person line and **Check**, face circles with copy badges, add-person menu, a **Fill** menu ("2 pages · 24 copies", from the layout solver, 0.20.9) beside the copies stepper, pages that snap one at a time and follow a new page into view (0.20.10), a stepper that always moves one copy (0.20.13; whole pages are the Fill menu's job), paper chips, **More** (Sheet options: sizes per person, any paper), **Continue**. Scissors in the bar open **Cutting options** (0.20.4), a shorter sheet that leaves the page visible while switches change it (0.20.10) | `SheetView.swift` |
| — | **First-photo guide** (ADR-052, 0.20.14) | A new install opens a welcome page: a selfie becoming an ID photo on the mat, a yellow "Guided first photo" chip, "Let's make your first ID photo together", take, check, print, a preview of the guide bubble ("It sits above the next button to tap, and goes away after your first photo"), "The guide gives you one free photo: this first one … After that, each photo uses one credit" right under the title, and **Start** (no skip). Then the real screens carry the guide as yellow speech bubbles over the screen, one at a time, each next to the control it is about with its tail on it, so nothing moves (since 0.20.18): a hand symbol, "Guide · 2 of 4" with a thin four-phase bar, one short instruction, and **Next** on an explanation. A bubble sits on the side with more room, except the check result and "where you'll print", which go below so the verdict and the question stay visible. It pops in at each tip (a fade under Reduce Motion); VoiceOver reads each one. The control is outlined with a slow breathing yellow ring (steady under Reduce Motion). Order: Home, the document (Next, or choosing a document) then Take Photo; Photo Check, the check list (Next) then Print (the other output is hidden during the guide); Your sheet, the paper chips (Next or a new paper), the copies stepper (Next or a change), then Continue; Print, Unlock, the route cards, then Print or Share. Back on Home mid-way, a **Continue** button replaces Take Photo. It ends after a print job is sent or the image is shared, with **You're all set** (check the 50 mm line, "Your free photo is used" with prints of it staying free, the digital photo is included). Developer details add "Restart the First-Photo Guide" in Settings | `TutorialViews.swift`, `TutorialCoach.swift`, `Domain/Tutorial.swift` |
| 11 | **Print** | Page thumbnail (a small stack and "N copies on M pages" when there are several, 0.20.10) and "Your sheet is ready"; "Where will you print?" with two large cards, **At Home** and **At a Shop**, nothing chosen at first (0.20.10; it was a segmented control that went unnoticed); until one is chosen the steps say to choose and the main button reads "Choose where to print" (a bordered, legible disabled button). Right after unlocking, the cards scroll into view and pulse their accent outline once, and keep a light accent outline until one is chosen (0.20.12). Shop-only documents and devices without printing skip the question above *Before you print* in three steps that follow it (home: load paper, Actual Size, measure the line; shop: order a standard print, no cropping or Fit to Page, measure). Locked: the unlock card, **Unlock**, **Keep Editing**, or **Get Credits**, in a raised tray (0.20.6). Unlocking only unlocks, and the files are prepared meanwhile. Unlocked: a **Check Your Print** row under the steps, then one main button, **Print** (the print panel) or **Share Print Image** (the share sheet directly, no extra sheet), and **More Formats**. A finished print job opens the check by itself | `PrintView.swift` |
| 11a | **Check Your Print** | The 50 mm line (or one photo's outline when the page has no line) drawn at true size: lay the print on the screen. **Yes, Same Size** → Finished. **No** → *smaller or larger?* → the specific fix (Actual Size, Fit to Page, Borderless, paper) and **Print Again**. The shop route asks the shop to print at original size. Unknown iPhone model: measure with a ruler, or set up the screen once with a bank or ID card (**Screen Size**) | `PrintCheckView.swift`, `Domain/ScreenSize.swift` |
| 11b | **Finished** | "Your photos are the right size", the person's own page with the cuts drawn in order (rows, then photos, then trims), three cutting tips, **Done** to Home | `FinishedView.swift`, `Domain/CutPlan.swift` |
| 12 | **Credits** | Balance, what a credit covers in three lines, three packs with the price per photo and a **Best value** tag. The only place that shows money | `CreditsView.swift` |
| 13 | **Settings** and **App Icon** | Credits, app icon picker (33 characters), Language menu (Same as iPhone, English, Español, Português (Brasil); applies the next time the app opens, ADR-053), privacy sentence, version | `HomeView.swift`, `AppIconPickerView.swift` |

**Step marker** (Photo Check, Your sheet, Print, Digital Photo): the current step's name ("Check", "Print", or "Save") over three short segments, filled up to the current step (`StepMarker.swift`, 0.20.2). It replaced the breadcrumb "✓ Photo › Check › Print", which never sat well in the bar. VoiceOver reads "Step 2 of 3: Check".

**Measuring** (Photo Check, D-2): when the photo lands, dashed white lines draw in at the top of the head and the chin, a solid one at the eyes, with a bracket and the head length ("Head 23.7 mm", or "about" when the top of the head is an estimate). After about three seconds they fold into a chip under the photo; tapping the chip shows them again. "Allowed 32–36 mm" and a status symbol appear only when the document's rules state a head height (`PhotoMeasurement.swift`, `MeasurementOverlay.swift`).

**Unlock card** (Print and Digital Photo, while locked): the title "Unlock your photo" with the cost as a filled badge ("1 credit"), three short lines for what it gives (the digital photo, as many prints as you like, print or share again at no cost; `UnlockBenefits`, also shown on Credits), then "After this, framing and edits are final.", and below the card "You have N credits. After this: M." or "You need N." (0.20.4). That sentence is the point-of-no-return warning and must stay next to the button that spends the credit.

**States every screen must handle:** loading with a named activity, empty, failure with a plain cause and one way forward, permission denied (camera), no camera (simulator), a person removed while a screen is open, accessibility text sizes, Light and Dark.

## 4. Words

The voice is calm, direct, and plain. People should never need to know a file format or a technical term.

- **Banned in the app's text** (enforced by `scripts/strings/check_copy.py` in CI): JPEG, JPG, PDF, pixel, px, DPI, ppi, segmentation, mask, ICAO, bleed. Two entries are allow-listed with a reason.
- **Never say:** AI, scan, detect, recognition, guaranteed, approved, certified, compliant, valid or invalid, passed or failed as a verdict, error codes, premium, upgrade, limited time, perfect, beautify, retouch.
- **Say instead:** photo, check, check by eye, framed to size, could not be checked, retake, stays on your iPhone, the office that receives it, credit.
- **Instructions** are short imperatives about one thing: "Move a little closer", "Hold the phone at eye level".
- **Every warning gives a way forward:** what happened, then what to do. "The face is dark. Face a window or a lamp and retake."
- **Wording ladder:** facts may say done; uncalibrated measurements say "looks fine"; human judgement is "to check by eye". Nothing says "passed" or "approved".
- **Strings** live in `Localizable.xcstrings` with Spanish and Portuguese (Brazil) for every entry. Use Foundation formatters for numbers, units, and dates.

---

# Part B — Where to take it

## 5. Honest review of 0.16.0

The camera is the best screen. The engineering under every screen is sound. But the app does not yet look or feel like the best in its category:

1. **It looks like Settings.** Grey grouped background, white cards, teal buttons. Nothing says "photo studio", and nothing is recognisably Calipic once the camera closes.
2. **The photo stops being the hero.** After Photo Check it shrinks to a 52 pt circle and a thumbnail.
3. **Precision is our difference and it is invisible.** The app measures a head to the millimetre and shows a sentence. A competitor's screenshot could be swapped in and nobody would notice.
4. **Eight separate screens, no thread.** Plain pushes, no sense of progress, the same photo redrawn on each screen. Two review screens follow each other (camera review, then Photo Check).
5. **The ending is missing.** The journey stops at the print panel. The moment that decides satisfaction (the print measures right, the copies are cut) has no screen.
6. **Few moments, few responses.** Two custom animations and a handful of haptics. Steppers, chips, and sliders feel inert.
7. **Home sells with a grey silhouette.** A portrait app has never been judged with a real face on screen.
8. **Dark mode is stark.** Pure white paper on pure black.
9. **Waiting is a line of text.** "Finding your face…" hides work that would be impressive to watch.

## 6. Direction: a precise instrument with a warm result

Six principles for every new screen:

1. **The photo is the largest thing on screen** wherever it appears (at least 45 % of the height on Photo Check, Adjust, and Digital Photo).
2. **One object, one journey.** The photo is the same object from the shutter to the sheet. It moves between screens; it is not redrawn.
3. **Show the measuring.** Where a number is true, show it on the photo or the paper, in millimetres. Never show a number we cannot stand behind.
4. **Paper is real.** True proportions, true size when asked, soft light, no glare in Dark.
5. **Every touch answers.** Within 100 ms, with movement or a haptic that matches what changed.
6. **Native first.** System controls and system glass. Custom work goes into the photo, the paper, and the measuring layer, where it is ours alone.

## 7. Proposals

Each has an ID used by the roadmap. Effort: S under a day, M a few days, L a week or more. The founder's answers on these are recorded as D-1 to D-8 in [05-decisions.md](05-decisions.md).

### U1 — Finish the journey: print check, true size, finished (L) · Built in 0.17

The highest-value missing piece (pillar 3 and the end of the journey).

- **Check your print** appears after the print panel closes and from Print at any time. It shows the 50 mm line **at true size on the screen**: "Hold your print against the screen. Do the lines match?" **Yes** / **No** / **Skip**. No ruler needed.
- **No** asks one question (shorter or longer?) and gives the specific fix: Fit to Page was on, borderless was on, or the paper size was wrong. Then **Print Again**.
- **Yes** leads to **Finished**: the page with cut lines drawn in order (rows first, then columns), three short cutting tips, and **Done**. One success haptic. No upsell and no rating request here.
- **True size needs a table** of display density per iPhone model (`utsname.machine` → pixels per inch). Points per millimetre = ppi ÷ `UIScreen.nativeScale` ÷ 25.4, which stays right under Display Zoom. Unknown model: hide the true-size view and fall back to "measure the line with a ruler". Unit-test the table and the formula; confirm on a device with a ruler (50 ± 0.5 mm).
- The answer is the person's own. Never infer a correct print from the print panel finishing.

Done when: a first-time tester with a home printer reaches Finished and can say whether the print is the right size.

### U2 — A shorter path with a visible thread (M) · Built in 0.18 (one review instead of two is still open)

- **Remove *Choose result*.** Photo Check's main button becomes the document's main output (**Print** or **Digital Photo**) and the other output is the secondary button. Digital-only and shop-only documents show what they support.
- **Before your photo** in full only the first time for a document; after that the camera opens directly and the tips live in Camera Help.
- **One review, not two.** **Use Photo** on the camera animates the still straight into the Photo Check landing, so it reads as one moment.
- **A quiet three-step marker** in the navigation area: Photo · Check · Print.

Result: Home → Camera → Photo Check → Your sheet → Print (five screens instead of eight).

### U3 — Show the measuring (M) · Built in 0.18: the lines and chip (checks one by one and Actual size are still open)

The signature Calipic moment, built from data the app already has (the face analysis and the profile's composition bands).

- After the photo lands in its frame, thin guide lines draw in: top of head, chin, eye line. Labels in millimetres: "Head 34 mm · allowed 32–36". They hold for about two seconds, then settle into a small **Measured** chip. Tap the chip to see them again.
- Lines take the status colour with a symbol, never teal over the portrait. Under Reduce Motion they appear without drawing.
- **Checks arrive one by one** instead of a spinner: each measured row appears as it completes (size, head, eyes, background, light). The work becomes visible and the wait feels shorter.
- **Actual size** toggle on Photo Check: the photo at its real physical size next to a ruler edge (same table as U1).
- Custom sizes show the size only; there are no official bands to draw.
- Honesty: millimetre labels are facts about the framing we made. The verdict wording stays on the ladder (Part A §4).

Done when: testers, asked what the app did, mention that it measured the photo.

### U4 — One continuous object (M) · Built in 0.20.5

Built with the system zoom transition (`Transitions.swift`): Home's *Your sheet* card and Photo Check's photo open Your sheet; the photo opens Digital Photo; the page opens Print. Arriving from Photo Check, the copies on the first page appear row by row with a light tap each. Unlock folds the card away. Photo Check itself keeps the standard push, because it often opens after the camera, with nothing on screen to zoom from. Pages whose photos lie sideways on the paper are shown turned a quarter, so faces are always upright (Your sheet, Print, Finished); the printed page is unchanged.


- Home hero or *Your sheet* card → the screen it opens: zoom transition (`matchedTransitionSource` with `.navigationTransition(.zoom)`).
- Photo Check → Your sheet: the portrait travels to the page and **becomes its copies**, one after another, with a light haptic per row.
- Your sheet → Print: the page becomes the header thumbnail.
- Unlock: the page lifts slightly and the unlock card folds away; one success haptic.
- Reduce Motion: cross-fades. All of it interruptible: a back swipe mid-transition must work.

### U5 — The look: stage, paper, type, numbers (M) · Built in 0.20: option B, Cutting mat (round 3)

One design round (three options, judged with real portraits in Light and Dark), then tokens.

- **Stage.** A warm neutral behind photos and pages instead of system grey (candidates: light `#F3F1ED`, dark `#17181A`), as asset colours behind `Surface.stage` and optionally `Surface.screen`. Cards stay system.
- **Paper in Dark.** Slightly dimmed white (about 94 %) so paper does not glare. Exported files are untouched; this is display only.
- **Type roles.** Larger, tighter heroes. Measurements and counts become a second voice: monospaced digits, a rounded or expanded system design for numbers and units ("34 mm", "8 copies"). System fonts only, Dynamic Type kept.
- **Depth.** One shadow recipe for paper (contact shadow plus soft ambient) used everywhere a photo or page appears.
- **Symbols.** One weight and scale per role; symbol effects only on state change (U6).

### U6 — Every touch answers (S–M) · Built in 0.17 (copies, paper and person selection, verdict, straighten and Auto; Print and Credits keep their own)

A feedback map, implemented once and reused:

| Event | Response |
|---|---|
| Camera becomes ready | One soft haptic (exists) |
| Verdict appears | Symbol bounce once; success or warning haptic |
| Copies stepper | Selection tick per step; count uses a numeric text transition |
| Paper chip or person selected | Selection tick; the page rearranges |
| Dial or slider crosses the automatic value or a rule limit | Rigid tick |
| Unlock | Success haptic; card transition |
| Something cannot be done | Warning haptic with the visible reason |

No sounds beyond the system shutter. Nothing repeats or loops.

### U7 — Adjust as a tool (L) · Prototype both (D-4)

- The photo fills the screen; controls sit in a native sheet with detents (system glass), so the photo stays large.
- **Straighten** becomes a ruler dial under the photo, with a tick at zero and at the automatic value.
- **Zoom** shows the allowed head-size band on its scale, so the person sees when they leave the range. The U3 guide lines stay visible while adjusting.
- **Background** as colour swatches (Original, the profile colour, alternatives for custom sizes), not a segmented control.
- **Hold to compare** stays. **Auto** returns to the solved framing with the reframe spring.
- Move and Zoom buttons stay (accessibility baseline).

### U8 — Your sheet as a cutting mat (M)

- Tap a photo on the page to select that person; their copies highlight.
- Pinch the page to zoom, up to true size.
- New copies travel from the face circle to their place on the page.
- Paper chips carry a small paper-shaped glyph in true proportion and how many copies fit ("A4 · up to 30"), so choosing paper is an informed choice.
- A **cut lines** toggle previews where to cut.
- Consider the tray as a native sheet with detents so the page can use the full height (D-4: prototype both).

### U9 — Home as the studio table (M)

- First launch: a sample set that looks like real people (see U10), one gentle entrance, then still.
- With drafts: a **Continue** shelf with real thumbnails and what is left to do ("Ready to print", "1 credit to unlock"). This is the Home of [roadmap E2](02-roadmap.md).
- The document row shows the size as a small proportional rectangle (35 × 45 beside 2 × 2 in look different), which helps scanning more than flags would.
- The credits balance stays one tap away, never promoted.

### U10 — Real faces (M, needs people, not code)

- A private, consented portrait set for design review and quality work: several skin tones, hair types, glasses, a child. Never committed (ADR-027).
- Licensed or commissioned portraits for anything public: the Home sample, App Store screenshots.
- Rule: no visual decision is final until it has been seen with a real face in Light and Dark.

### U11 — Camera additions (M–L)

The camera is the screen to protect; add without crowding it.

- **Helper mode:** someone else holds the phone, back camera, guidance addressed to the photographer. The recommended way to photograph a child.
- **Find a good spot:** before the first photo, a live reading of light direction and background ("Face the window", "Step away from the wall").
- **Best frame:** capture a short burst and keep the sharpest frame with eyes open (after 1.0 unless it proves cheap). Since 0.20.9 the single still is checked for closed or downturned eyes during its review instead; a burst costs about half a second per full-quality still.

### U12 — Credits with StoreKit views (S, with roadmap E3)

Use StoreKit's SwiftUI product views for the packs so prices, pending states, and Ask to Buy are native. Keep the screen quiet: balance, one sentence, three packs, restore.

### U13 — Choose document (S)

The person's country first, then recent documents, then everything; the proportional size glyph from U9; a "closed to home photos" explanation when someone searches for a document we deliberately do not offer (for example a German passport), so the absence reads as honesty.

### U14 — States worth looking at (S–M)

Redesign the non-happy paths with the same care: camera permission denied, no face found, several faces, photo too small, export failed, sheet empty or full, no credits. Each gets a clear symbol, one sentence, one action.

### U15 — A gallery every release (S)

A script exports the UI-test screenshots (Light and Dark) into `docs/ui/gallery/` with fixed names, so each release can be reviewed side by side with the last. Today the gallery was exported by hand for 0.16.0.

### U16 — Icon and App Store presence (M)

Lock the icon finish with dark and tinted variants and a layered version for Liquid Glass; screenshots built around the three moments people will remember: the measuring (U3), the sheet filling (U4), the print matching the screen (U1).

## 8. How to run a design round

1. State the problem and which pillar it serves.
2. Produce two or three real alternatives, not variations of one. Mock-ups were made in Claude Design for rounds 1 and 2; any tool is fine as long as the result is saved as an image in `docs/ui/explorations/` with one line per option.
3. The founder chooses. Record the choice in that folder's README and in Part A when built.
4. Build it, then look at screenshots in Light and Dark **before committing**. Fix clipping, wrapping, and weak contrast first.
5. Update Part A and the gallery in the same commit.

## 9. Refinement: one table, one tray (U19, ADR-054)

Chosen by the founder on 2026-11-14 (refinement round 1 in `docs/ui/explorations/`), after "it doesn't feel like a well designed app". An audit of all 61 scenes found no ugly screen and no system. This section is the system. The founder then gave a free hand ("complete freedom to change anything"); the choices made with it are listed in §9.10 and marked **(free hand)** where they appear. **Where it disagrees with §1 to §3, this section wins**; update those rows as each screen is rebuilt.

### 9.1 What was wrong, and the fix for each

| # | Problem in 0.20.19 | Fix |
|---|---|---|
| 1 | About seven text sizes; a small grey footnote on almost every screen | Three text roles plus the readout (§9.3). Footnotes are deleted, promoted to a sentence, or moved behind a row (§9.4) |
| 2 | Centred screens and left-aligned screens in one journey | Everything in the tray is left-aligned (§9.3) |
| 3 | Five kinds of container, boxes inside boxes | Two surfaces on a journey screen: the mat and the tray. No cards (§9.2) |
| 4 | Four button treatments, stacks of two or three full-width pills | One filled button, at most one text button, chips only for a set of choices (§9.5) |
| 5 | The photo takes a third of Photo Check; the page is a thumbnail on Print | The object on the mat takes the whole stage, at least 45 % of the screen height (§9.2) |
| 6 | Empty middles (Home, Photo Check, Digital Photo, Check your print) | The stage stretches and the tray hugs its content, so there is no middle to be empty |
| 7 | A different page layout for each step | One layout for Home, Photo Check, Your sheet, Print, Digital Photo, Finished (§9.2) |
| 8 | Status marks of three sizes; an orange alarm as the default; one eye icon for a problem and for a routine check | One status mark, inline with words (§9.6) |
| 9 | Your sheet's tray: six control shapes in 150 pt | Labelled rows; rare actions move to the toolbar menu (§9.7) |
| 10 | The same page is shown on two screens in a row (Your sheet, then Print), and the same photo is reviewed twice (camera review, then Photo Check) | **Print is one screen** whose tray changes; **one review**: the still lands on Photo Check (§9.7) **(free hand)** |
| 11 | The default sheet leaves empty slots on paper that is used up anyway | The first page is filled by default **(free hand)** |

### 9.2 Layout: stage and tray

Every journey screen (Home, Photo Check, Print, Digital Photo, Finished, and the guide's welcome and "You're all set") is built from one component, `JourneyScreen(stage:tray:)`.

- **Stage.** The mat (`Surface.mat`, with its grid) fills the screen from the top edge, under the status bar and a transparent navigation bar, down to behind the tray's top corners. It is no longer a rounded panel inset by 8 pt. The grouped grey background is never visible on a journey screen.
- **The object.** One thing lies on the mat: the photo, the page, or Home's sample prints. It is centred in the free area between the navigation bar and the tray, with at least 20 pt to every edge, and scaled to fill that area. On Photo Check and Digital Photo it is at least 45 % of the screen height on a 6.1-inch iPhone at the default text size. Nothing else sits on the mat except the measuring layer (lines, the millimetre chip), page dots, and the compare control (§9.4).
- **Tray.** One white panel (`Surface.tray`) at the bottom: top corners 30 pt (`Radius.tray`), a soft upward shadow, 20 pt side padding, 22 pt above the title, and the bottom safe area plus 8 pt below the actions. Its height is its content. It never takes more than 55 % of the screen: beyond that, the rows scroll inside the tray and the actions stay pinned at its bottom.
- **The tray is the only container.** No white cards, no tinted panels, no nested rounded rectangles. Groups are separated by a hairline (rows) or by 20 pt of space (blocks).
- **Tray order, always:** title, at most one supporting line, rows or controls, actions.
- **Navigation bar.** Transparent over the mat. Back and menu buttons are the system glass circles. The centre holds the step marker as three words, the current one in the label colour and the others secondary: `Photo  Check  Print`. No dashes under it. With Print as one screen, each word is exactly one screen.
- **Sheets are not journey screens.** Choose document, Photo requirements, Before your photo, Check details, Adjust, Cutting options, More formats, Check your print, Credits, Settings, and the app icon picker stay system sheets on the grouped background with standard inset lists. They follow §9.3 to §9.6 but keep their structure. The camera does not change.

### 9.3 Type and alignment

Three roles and the readout, mapped to the existing tokens:

| Role | Token | Used for |
|---|---|---|
| Title | `Typography.hero` (title, bold) on Home, Finished, the welcome page and "You're all set"; `Typography.trayTitle` (title2, bold; new, replaces `screenTitle` and `statusTitle` on journey screens) everywhere else | The one line that names what the screen says. One per screen |
| Body | `.body` | Row names, sentences the person must read, button-adjacent facts |
| Secondary | `Typography.cardDetail` (subheadline, secondary colour) | At most one supporting line under the title; the value at the end of a row |
| Readout | `Typography.readout` (monospaced) | Pure measurements: "26 × 32 mm", "23.7 mm" |

- `Typography.note` and `Typography.caption` are not used on journey screens, with one exception: the version on Home in builds before 1.0 (§9.4). They remain for legal and privacy text in sheets.
- `rowTitle` (semibold subheadline) is retired: a row name is body, regular weight.
- Everything in the tray is left-aligned: titles, lines, rows. Centred: the object on the stage, a button's label, and a sheet's navigation title. Nothing else.

### 9.4 What happens to each small grey line

| Line today | Becomes |
|---|---|
| "Hold to compare with the original" | Deleted. A glass capsule **Original** sits at the stage's bottom-left corner; press and hold it (or the photo) to compare. The accessibility action stays |
| "Your photos stay on your iPhone." (Home) | Deleted from Home. It stays in Settings › Privacy and on the welcome page |
| "1 credit" and the version (Home) | **(free hand)** The balance leaves Home: it is shown where it is spent (the unlock button, and "You have no credits" when short) and in Settings › Credits. The version stays as one quiet line at the bottom of Home's tray **until 1.0 only**, because the founder identifies builds from screenshots; from 1.0 it is in Settings alone. The long press on it still turns on developer details |
| "Fix these issues or continue after checking by eye." | Deleted. The rows say what there is to look at |
| "Unlocked. Printing and sharing this photo is free." | The supporting line under the title, when unlocked |
| "8 copies · 1 page · Room for 4 more" under the mat | The supporting line under the tray title on Print: "12 copies on 10 × 15 cm paper" |
| The unlock card's three benefits, "After this, framing and edits are final.", "You have 1 credit. After this: 0 credits." | One body sentence: "Unlocking gives you every print and the digital photo, as often as you like. Edits are final after that." The cost is in the button: **Unlock · 1 credit**. The balance is said only when it is not enough: "You have no credits." with **Get Credits** as the button |
| "Before you print" label, "Choose where you print to see the steps." | Deleted. The steps appear as rows once a place is chosen |
| "Sized for online forms" | The supporting line under "Your digital photo is ready" |
| "Never Fit to Page or borderless" under step 2 | Joined to its step: "Choose Actual Size, or 100 %. Never Fit to Page." |

### 9.5 Buttons

1. **Primary:** `brandProminentButtonStyle()`, large, full width, exactly one per screen, at the bottom of the tray.
2. **Text button:** plain teal text, 44 pt tall, for the single alternative. Under the primary button when it is a way out ("Choose from Library", "Keep Editing", "Done"); to the left of it in a 1 : 2 row when the two are peers ("Adjust" beside "Print").
3. **Chips:** only for one choice among several (paper sizes). Never for an action.
4. **Toolbar:** system glass circles; everything a screen needs rarely (Retake, requirements, cutting options, add a person, more formats, remove) goes in its ••• menu.

Removed: the pale-teal full-width buttons (`.bordered` Digital Photo, Adjust, No, Close, Done), the "Check" link on the sheet (Back does that), and the Fill pill (§9.7). A primary button that cannot act yet stays in place, disabled, and says what is missing ("Choose where to print").

### 9.6 Status

One component, `StatusMark`: a 22 pt circle before the words it belongs to. `pass`: green with a check. `warn`: orange with "!". `fail`: red with "×". `manual_check`: neutral grey with the eye. It is used inline with a row or a title, never alone as a large icon above a centred title. The only large mark left is the seal on Finished and "You're all set".

Photo Check's verdict logic does not change (ADR-007). Its presentation does: the verdict is the tray title with its mark in front (*Looks good*, *Review your photo*, *Better to retake*), followed by the supporting line "Framed for Spain · DNI". Two rows follow: **Measured** (the mark of its worst item, the head height as a readout at the end) and **To check by eye** (the neutral mark, the count at the end). While checking, the title is "Checking your photo…" with the system progress view in the mark's place.

### 9.7 Each screen

The journey is four screens and the camera: **Home → Camera → Photo Check → Print → Finished** (Digital Photo takes Print's place for a digital main output).

| Screen | Stage | Tray |
|---|---|---|
| **Home** | The sample selfie, photo and sheet lying on the mat (the person's own once they have one). The wordmark "Calipic" and the ••• button over the mat | Title "Take it at home. Print it yourself." · row: flag, document name, size as a readout, chevron (opens Choose document; Photo requirements moves into that sheet and the ••• menu) · **Take Photo** · "Choose from Library" · before 1.0, the version line. With photos in progress, a row per person above the document row |
| **Camera** | Unchanged, except the end **(free hand)**: there is no separate review. The shutter's bloom carries the still straight onto Photo Check's mat, where it settles into its frame (the landing animation). Analysis starts at the shutter, as it does today during the review | — |
| **Photo Check** | The framed photo, at least 45 % of the screen, with the measuring lines on request and the **Original** capsule | Verdict title with its mark · "Framed for …" · rows Measured and To check by eye · "Adjust" beside **Print** (or **Digital Photo** when that is the main output; the other output is in the ••• menu). **Retake** is the toolbar's text button and becomes the primary button when the verdict is *Better to retake* or the eyes measured closed |
| **Print** **(free hand: Your sheet and Print are one screen)** | The page, always: large, with page dots, free slots, and the stack for several pages. It does not move or shrink while the tray changes | Four states, cross-fading in place; Back steps to the previous state before leaving the screen. **1 · Layout:** title "Your sheet" · "12 copies on 10 × 15 cm paper" · row **Copies** with the count and the stepper · row **Paper** with the chips · with two or more people, a row of their circles above Copies · **Continue**. **2 · Unlock** (skipped when already unlocked): title "Unlock this photo" · the unlock sentence · **Unlock · 1 credit** · "Keep Editing" (back to state 1). **3 · Where:** title "Where will you print?" · two rows, **At Home** and **At a Shop**, each with its symbol and one secondary line; tapping one goes on. **4 · Print:** title "Print at home" or "Print at a shop" · the numbered steps as rows · **Print** or **Share Print Image** · "Change where" as the text button. Add a person, add a size, cutting options and More Formats live in the toolbar ••• menu |
| **Digital Photo** | The photo, at least 45 % | Locked: Print's Unlock state. Ready: title "Your digital photo is ready" with the pass mark · "Sized for online forms" · **Share Photo** · "Done" |
| **Finished** | The page with the cut order drawn on it | The seal and title "Your photos are the right size" (left-aligned, the seal before the title) · the cut steps as rows · **Done**. "Check Your Print" opens from the print panel closing, as today, and from the ••• menu |
| **Welcome, You're all set** | Welcome: the selfie becoming the photo. All set: the printed page | The same content as today, in the tray, under the rules above |
| **Check your print** (sheet) | — | The 50 mm line drawn large in the upper half, with its readout; the question as a left-aligned title; **Yes, Same Size** and the text button "No" |

**Copies (free hand).** A new sheet starts with the first page full (today: 8 copies, which leaves 4 slots empty on 10 × 15 cm). The stepper still moves one copy at a time; "Fill the page" is a text button under the Copies row, shown only when there are free slots.

**The guide** follows the same shape: Home (document, Take Photo), Photo Check (the rows, Print), Print (copies and paper, Continue, Unlock, where, Print). Four phases stay four.

### 9.8 Dark, large text, motion, the guide

- **Dark:** the mat is `#0E2C2E`, the tray is the elevated system background, paper stays at 94 % white. Since the mat fills the screen, pure black no longer appears on a journey screen.
- **Large text:** the tray scrolls inside its 55 % limit. At accessibility sizes the limit rises to 75 % and the stage shrinks; the object stays visible. The 1.0 baseline (ADR-050) still applies; no extra tuning.
- **Motion:** the tray changes height with `Motion.rearrange`; its content cross-fades when the state changes (locked to unlocked, choosing where to print). The photo keeps its zoom transitions between screens (U4), now from stage to stage. Reduce Motion: no movement, the change still happens.
- **The guide:** the yellow bubbles stay anchored to their controls and never cover the tray's actions unless they point at one (0.20.19 behaviour, unchanged).

### 9.9 How it is built

New pieces, all in `App/Brand` or `App/Features/Journey`: `JourneyScreen`, `TrayRow` (name, optional secondary line, trailing value, chevron or control), `TrayActions` (primary, optional text button, optional leading peer), `StatusMark`, `Radius.tray`, `Typography.trayTitle`. `Surface.card` and `Surface.stage` leave the journey screens. Print's tray state is derived from the model (locked count, chosen route), with one stored value for "layout confirmed", so a relaunch or Back cannot leave it in an impossible state.

Build order, one pass each, each on the founder's iPhone before the next:

1. The components, then **Photo Check**.
2. **Print as one screen** (the largest pass: `SheetView` and `PrintView` merge; navigation, the guide's tips and the UI tests follow), and **Digital Photo**. The first page filled by default.
3. **Home**, the welcome page, "You're all set".
4. **One review:** the camera's still lands on Photo Check; the camera review screen is removed.
5. **Finished** and the sheets (Check your print, then type and button rules in the rest).
6. Review of the built screens against this section (Fable 5.2), then fixes.

A pass is done when, in screenshots in Light and Dark, English, Spanish and Portuguese: the screen has one filled button; no text below the Secondary role except Home's version line; nothing is centred that §9.3 does not centre; no rounded box sits inside the tray; the object fills the stage; and the UI tests pass.

### 9.10 Decisions made with the founder's free hand (2026-11-14)

The founder said "you have complete freedom to change anything". These go beyond the chosen direction B; each is recorded in [05-decisions.md](05-decisions.md) and can be reversed by saying so.

| Decision | Instead of | Why |
|---|---|---|
| **Print is one screen** with a tray that changes (ADR-055) | Your sheet, then Print, both showing the same page | One object, one journey (§6): the page never leaves the mat; one screen fewer; each word of the step marker is one screen |
| **One review** (ADR-045 amended) | Camera review, then Photo Check | The same photo was approved twice. Photo Check shows the same still, measured, with Retake one tap away |
| **The first page is full by default** | 8 copies, leaving free slots | The paper is used either way; spare photos are what people want from a sheet |
| **Credits leave Home**; the version leaves Home at 1.0 | A caption line with both | Home says one thing. The balance matters at the unlock; the version matters to the founder until launch |
| **Status inline, verdict as the title** | A large icon over a centred headline | Calm by default; orange only for a measured problem |
| **A small group of testers after real purchases (0.24)**, before the tools work | A beta only at 0.95 | The look and the flow have been judged by one person. Five people who have never seen the app are worth more than another round of polish |
