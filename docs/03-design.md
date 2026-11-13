# 03 — Design

**Part A** is the contract: how the app looks and behaves today (spike 0.16.0). **Part B** is the direction: where the experience should go next. Part B is ambitious on purpose and nothing in it is final; the order of work is in [02-roadmap.md](02-roadmap.md).

Screenshots of every current screen: [ui/gallery/](ui/gallery/). Earlier design rounds and the options that were not chosen: [ui/explorations/](ui/explorations/README.md).

---

# Part A — The app today

## 1. Design language

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
| 1 | **Home** | Hero picture (a photo and the sheet it becomes; the person's own photo once they have one), the promise "Take it at home. Print it yourself.", the *Your sheet* card (with a menu to remove one photo or all of them, 0.20.2; on Your sheet, touch and hold a person) when a session exists, one card with the document and *Photo requirements*, **Take Photo**, **Choose from Library**, then the privacy line, the credits button, and the version | `HomeView.swift` |
| 2 | **Choose document** | Sheet with search; **Custom size** first, then profiles grouped by country, each country with its flag (also on the Home document card), with size and background. Custom size takes width and height in mm or inches and offers shortcuts | `DocumentPickerView.swift` |
| 3 | **Photo requirements** | The document's rules from the catalog with official sources and the review date | `HomeView.swift` (`RequirementsView`) |
| 4 | **Before your photo** | Three things to get right. Shown in full the first time for each document; after that the camera or picker opens directly (requirements stay in Home, Photo Check's More menu, and Camera Help) | `PreparationView.swift`, `AppFlow.swift` |
| 5 | **Camera** | Full-screen preview, one oval, one instruction about moving the phone, an arrow for direction, green when ready, white shutter, optional automatic capture with a countdown, camera switch, Help. After the shutter: the still with **Retake** and **Use Photo**, shown exactly as the preview showed it (same fill, same mirroring; the file keeps the whole unmirrored frame) | `Camera/` |
| 6 | **Photo Check** | The photo settles into the official frame. One verdict (*Looks good*, *Review your photo*, *Better to retake*). A card with two short rows (measured checks, the document's by-eye checks) that each open their own half-height list (**Measured**: what to look at, then what looks fine; **Check by eye**), so the screen stays one page (0.20.4); with a single issue the verdict line says what it is. Hold the photo to compare with the original. the document's main output as the prominent button (**Print**, or **Digital Photo** for digital-first documents such as the UK passport), the other output below it, and a plain **Adjust**; **Retake** and a More menu in the toolbar. An unlocked photo says so, and Adjust asks before changing it | `PhotoCheckView.swift`, `CheckDetailsSheet.swift`, `CheckPresentation.swift` |
| 7 | **Adjust** | An editor in a sheet, the photo always in view (0.20.2): the crop with drag and pinch on top, one tool's controls below it, and a tool strip at the bottom: **Crop** (zoom slider, Move and Zoom buttons, framing presets for custom sizes), **Straighten**, **Background** (choice, edge softness), **Light** (light and colour, strength, black and white for custom sizes). Auto/Reset and Compare in the bar. Changing tool never resets a value | `AdjustSheet.swift`, `CropPreview.swift` |
| 9 | **Digital Photo** | Locked: the unlock card and **Unlock and Save**. Ready: the photo, **Share Photo**, **Done** | `DigitalPhotoView.swift` |
| 10 | **Your sheet** | The page as hero with "N copies · M pages". A tray with the person line and **Check**, face circles with copy badges, add-person menu, a copies stepper, paper chips, **More** (Sheet options: sizes per person, any paper), **Continue**. Scissors in the bar open **Cutting options** (0.20.4) | `SheetView.swift` |
| 11 | **Print** | Page thumbnail and "Your sheet is ready"; *Before you print* in three steps (load paper, Actual Size, measure the line). Locked: the unlock card, **Unlock and Print**, **Keep Editing**, or **Get Credits**. Unlocked: a **Check Your Print** row under the steps, then **Print at Home**, **Print at a Shop**, **More Formats**. A finished print job opens the check by itself | `PrintView.swift` |
| 11a | **Check Your Print** | The 50 mm line (or one photo's outline when the page has no line) drawn at true size: lay the print on the screen. **Yes, Same Size** → Finished. **No** → *smaller or larger?* → the specific fix (Actual Size, Fit to Page, Borderless, paper) and **Print Again**. The shop route asks the shop to print at original size. Unknown iPhone model: measure with a ruler, or set up the screen once with a bank or ID card (**Screen Size**) | `PrintCheckView.swift`, `Domain/ScreenSize.swift` |
| 11b | **Finished** | "Your photos are the right size", the person's own page with the cuts drawn in order (rows, then photos, then trims), three cutting tips, **Done** to Home | `FinishedView.swift`, `Domain/CutPlan.swift` |
| 12 | **Credits** | Balance, what a credit covers in three lines, three packs with the price per photo and a **Best value** tag. The only place that shows money | `CreditsView.swift` |
| 13 | **Settings** and **App Icon** | Credits, app icon picker (33 characters), privacy sentence, version | `HomeView.swift`, `AppIconPickerView.swift` |

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

### U4 — One continuous object (M)

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
- **Best frame:** capture a short burst and keep the sharpest frame with eyes open (after 1.0 unless it proves cheap).

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
