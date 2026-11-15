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
| Cutting mat | Photos and pages lie on a teal-grey mat with a fine grid (`#DCE8E6` / `#0E2C2E`, `Stage.swift`), edge to edge behind the navigation bar on Photo Check (0.21 pass 1); still a rounded panel 8 pt in from the screen edges on Your sheet, Print, Finished, and Digital Photo. **No bare text on the grid:** captions and counts sit below the mat; the measurement chip has a solid background; the unconverted screens keep a plain navigation bar (0.20.1). **The grid is not a scale:** never on Check your print. Home, Adjust, and settings stay plain |
| Paper | One shadow (`paperShadow`: contact edge plus a small spread). In Dark, paper is shown at about 94 % white (`paperDimmedInDark`); exported files are untouched |
| Readouts | Pure measurements ("34 mm", "35 × 45 mm") use the monospaced system design (`Typography.readout`); paper chips use the rounded design (`Typography.sizeChoice`), since monospaced chips felt too technical; sentences with a number keep the text face with monospaced digits |
| Radius | `tray` 30 (0.21), `photo` 6, `tile` 10, `card` 16, `group` 22 |
| Spacing | `tray` and `stageMargin` 20 (0.21), `titlePair` 2, `tight` 4, `caption` 6, `text` 8, `row` 10, `control` 12, `cardContent` 14, `group` 16, `block` 20, `sectionTight` 24, `section` 28 |
| Type | `trayTitle` (title2, bold, 0.21), `hero` (title, bold), `screenTitle` (title2, semibold), `statusTitle`, `cardTitle` (headline), `cardDetail` (subheadline), `rowTitle`, `note` (footnote), `noteDigits`, `caption`. System text styles only |
| Motion | `landing` (0.8 s spring), `reframe`, `compare`, `rearrange` (0.55 s spring), `backgroundFade`, `guideState`. Reach them through `resolved(reduceMotion:)` so the setting cannot be forgotten |
| Size | `statusMark` 22 pt, scaled with body (0.21); `minimumTarget` 44 pt for every control |

Buttons: one prominent button per screen (`brandProminentButtonStyle()`, large). Photo Check, Print and Digital Photo use `TrayActions`: plain alternatives and actions pinned below the scrolling tray at every text size. Screens awaiting conversion retain their earlier bordered alternatives and bottom bars.

## 3. Screens

| # | Screen | What it does | Source |
|---|---|---|---|
| 1 | **Home** | Hero picture: a selfie, the ID photo made from it, and the printed sheet (a generated sample person, D-9; the person's own original, photo and copies once they have one, 0.20.5). Easter egg (0.20.9): a tap on the sample brings the next of nine generated people while the three papers shuffle slightly on the mat (cross-fade only under Reduce Motion; also an accessibility action), the promise "Take it at home. Print it yourself.", the *Your sheet* card (with a menu to remove one photo or all of them, 0.20.2; on Your sheet, touch and hold a person) when a session exists, one card with the document and *Photo requirements*, **Take Photo**, **Choose from Library**, then the privacy line, the credits button, and the version | `HomeView.swift` |
| 2 | **Choose document** | Sheet with search; **Custom size** first, then profiles grouped by country, each country with its flag (also on the Home document card), with size and background. Custom size takes width and height in mm or inches and offers shortcuts | `DocumentPickerView.swift` |
| 3 | **Photo requirements** | The document's rules from the catalog with official sources and the review date | `HomeView.swift` (`RequirementsView`) |
| 4 | **Before your photo** | Three things to get right. Shown in full the first time for each document; after that the camera or picker opens directly (requirements stay in Home, Photo Check's More menu, and Camera Help) | `PreparationView.swift`, `AppFlow.swift` |
| 5 | **Camera** | Full-screen preview, one oval, one instruction about moving the phone, an arrow for direction, green when ready, white shutter, automatic capture with a countdown, off by default since 0.20.19 and switched by a timer button left of the shutter, labelled "Auto: Off" / "Auto: On" (white filled when on), the instruction and the countdown at the top under the front camera so reading them keeps the eyes near the lens, with "Look here ↑" during the countdown (0.20.9); the review says "Your eyes look closed or turned down" and makes Retake the main button when the eyes measured closed, camera switch, Help. After the shutter: the still with **Retake** and **Use Photo**, shown exactly as the preview showed it (same fill, same mirroring; the file keeps the whole unmirrored frame) | `Camera/` |
| 6 | **Photo Check** (0.21 pass 1) | A large portrait on the edge-to-edge mat; Original is a visible glass capsule (hold to compare, tap for 1.2 seconds). The shared tray holds the inline verdict, its supporting line, Measured (head height readout), and To check by eye (count). Both rows open their system sheets. Adjust sits beside the main output; the other output is in More. Better to retake or measured closed eyes makes Retake primary, with Print anyway / Use anyway below and Adjust in More. Measuring draws before the verdict and feedback; returning to a checked photo does not replay them. Unlocked edits still ask before relocking | `PhotoCheckView.swift`, `Features/Journey/`, `CheckDetailsSheet.swift` |
| 7 | **Adjust** | An editor in a sheet, the photo always in view (0.20.2): the crop with drag and pinch on top, one tool's controls below it, and a tool strip at the bottom: **Crop** (zoom slider, Move and Zoom buttons, framing presets for custom sizes), **Straighten**, **Background** (choice, edge softness), **Light** (light and colour, strength, black and white for custom sizes). Auto/Reset and Compare in the bar. Changing tool never resets a value | `AdjustSheet.swift`, `CropPreview.swift` |
| 9 | **Digital Photo** (0.21 pass 2) | The large digital crop stays on the mat. Locked: the unlock sentence, **Unlock · 1 credit**, Keep Editing; a low balance offers Get Credits. Preparing: progress in the title. Ready: inline pass mark, “Your digital photo is ready”, Sized for online forms, **Share Photo**, plain Done. Unlock gives one success tap, lift and light sweep; the preview uses the export's digital framing recipe | `DigitalPhotoView.swift` |
| 10 | **Print** (0.21 pass 2) | One page strip on the mat, at the same position through all four trays: Your sheet (copies, paper, full-page fill), Unlock, Where will you print?, then Print at home / Print at a shop. The first page starts full. Back steps through trays before leaving layout; the toolbar menu holds cutting options, adding a person, more sizes/paper and unlocked formats. Long instructions scroll with the main button pinned; Check Your Print stays reachable on smaller phones. Page indicators are native, in a footer below the paper | `PrintView.swift`, `PrintView+Layout.swift`; reusable sheets / page drawing in `SheetView.swift` |
| 12 | **Credits** | Balance, what a credit covers in three lines, three packs with the price per photo and a **Best value** tag. The only place that shows money | `CreditsView.swift` |
| 13 | **Settings** and **App Icon** | Credits, app icon picker (33 characters), Language menu (Same as iPhone, English, Español, Português (Brasil); applies the next time the app opens, ADR-053), privacy sentence, version | `HomeView.swift`, `AppIconPickerView.swift` |

**Step marker** (0.21 pass 1, shared by Photo Check, Your sheet, Print and Digital Photo): three words, Photo · Check · Print (or Save), with the current word primary and the others secondary. No capsules. VoiceOver still reads “Step 2 of 3: Check”.

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

Chosen by the founder on 2026-11-14 (refinement round 1 in `docs/ui/explorations/`), after "it doesn't feel like a well designed app". An audit of all 61 scenes found no ugly screen and no system. This section is the system. The founder then gave a free hand ("complete freedom to change anything"); the choices made with it are listed in §9.11 and marked **(free hand)** where they appear. **Where it disagrees with §1 to §3, this section wins**; update those rows as each screen is rebuilt.

### 9.1 What was wrong, and the fix for each

How to build each fix, file by file, is in **§10.2** (F1 to F11 match the rows below).

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

A pass is done when, in screenshots in Light and Dark, English, Spanish and Portuguese: the screen has one filled button; no text below the Secondary role except Home's version line; nothing is centred that §9.3 does not centre; no rounded box sits inside the tray; the object fills the stage; the UI tests pass; **and every moment of §9.10 that lives on the screen has been watched working in a screen recording on the founder's iPhone**, with Reduce Motion on and off.

### 9.10 The moments (founder, 2026-11-14: "don't lose our wow moments")

How each moment works in the code today and exactly what to build is in **§10.3** (M1 to M12 match the rows below). Refinement removes noise, never a moment. The quiet tray exists so that these stand out. Each one is listed with where it lives after 0.21; a pass that touches a screen must keep its moments working, and where the table says **stronger**, deliver that too.

| # | Moment | Today | After 0.21 |
|---|---|---|---|
| 1 | **The shutter** | One bloom and one haptic, then a review screen | **Stronger:** the bloom carries the still onto Photo Check's mat with no screen in between |
| 2 | **The landing** | The photo settles into its official frame on Photo Check (`Motion.landing`) | Kept, and larger: the photo is at least 45 % of the screen, so the move from the raw still to the framed photo is the first thing seen |
| 3 | **The measuring** | Lines and the millimetre chip draw on the photo | Kept on the stage. **Stronger:** the lines draw while the title still says "Checking your photo…", then the verdict replaces it with its mark bouncing once and its haptic |
| 4 | **Compare** | Press and hold to see the original | Kept (`Motion.compare`), now with a visible **Original** capsule so people find it |
| 5 | **The photo becomes its copies** | From Photo Check the portrait travels to the page and the copies appear row by row, a light tap per row | Kept, and it is now the entrance to the one Print screen. **Stronger:** the first page is full by default, so every row fills |
| 6 | **A copy at a time** | Each added copy drops into the next free slot; counts roll; a new page fills row by row; pages snap and follow | Kept exactly. The free-slot outlines stay |
| 7 | **The unlock** | The card folds away, one success haptic (the page lift described in U4 was never built) | **Stronger**, since the page no longer changes screens: the page lifts, one soft light sweeps across it, the success haptic fires, and the tray turns to "Where will you print?" |
| 8 | **The print matches the screen** | Check your print: the 50 mm line at true size | Kept. **Stronger:** the line is drawn large; on "Yes, Same Size" it turns green with the seal and a success haptic before Finished opens |
| 9 | **The cut order** | Finished draws the cuts on the person's own page | Kept. **Stronger:** the cut lines draw one after another in cutting order when the screen opens |
| 10 | **The sample people** | A tap on Home's sample brings the next of nine people | Kept, on the mat |
| 11 | **Every touch answers** | The feedback map of U6: ticks on the stepper and chips, rolling numbers, warning haptic with a reason | Kept exactly; the new rows and the tray's state changes join the same map |
| 12 | **The guide** | Yellow bubbles pop in, the hand bounces, the ring breathes | Kept |

Rules for all of them: one moment at a time; none repeats or loops (the guide's breathing ring is the one exception, and it is temporary); each respects Reduce Motion (the change happens without movement); a back swipe mid-way must work; none may delay a tap by more than 100 ms.

### 9.11 Decisions made with the founder's free hand (2026-11-14)

The founder said "you have complete freedom to change anything". These go beyond the chosen direction B; each is recorded in [05-decisions.md](05-decisions.md) and can be reversed by saying so.

| Decision | Instead of | Why |
|---|---|---|
| **Print is one screen** with a tray that changes (ADR-055) | Your sheet, then Print, both showing the same page | One object, one journey (§6): the page never leaves the mat; one screen fewer; each word of the step marker is one screen |
| **One review** (ADR-045 amended) | Camera review, then Photo Check | The same photo was approved twice. Photo Check shows the same still, measured, with Retake one tap away |
| **The first page is full by default** | 8 copies, leaving free slots | The paper is used either way; spare photos are what people want from a sheet |
| **Credits leave Home**; the version leaves Home at 1.0 | A caption line with both | Home says one thing. The balance matters at the unlock; the version matters to the founder until launch |
| **Status inline, verdict as the title** | A large icon over a centred headline | Calm by default; orange only for a measured problem |
| **A small group of testers after real purchases (0.24)**, before the tools work | A beta only at 0.95 | The look and the flow have been judged by one person. Five people who have never seen the app are worth more than another round of polish |

## 10. Building 0.21: implementation notes for every fix and every moment

Written 2026-11-14 from a line-by-line inventory of the code at tag `v0.20.19`. §9 says **what**; this section says **how**, in enough detail that a model which has not seen the design discussion can build it. Line numbers are those of `v0.20.19` and will drift: find the code by the names given. Paths are under `Calipic/App/` (`F/` = `Features/`, `B/` = `Brand/`, `C/` = `Camera/`).

### 10.0 Ground rules for whoever builds this

1. Read §9 first. If these notes and §9 disagree, stop and ask; do not guess.
2. One pass at a time, in the order of §9.9. Do not start a pass before the previous one builds and its tests pass.
3. **Do not change:** the verdict logic (`CheckPresentation.summary`), the layout solver (`PrintLayoutSolver`), the export gate, credit arithmetic, or any rule data. This work is presentation and navigation.
4. **Keep every accessibility identifier** unless §10.4 says it is removed or moved. UI tests find controls by identifier. An identifier on a container hides its children from the tests: put identifiers on the same kind of element they are on today (a `Text`, a `Button`, or an `.accessibilityElement(children: .combine)` block).
5. Every new or changed user-facing string goes into `F/../Resources/Localizable.xcstrings` with Spanish and Brazilian Portuguese, and unused keys are removed (see `docs/00-handoff.md`). Run `python3 scripts/strings/check_copy.py`.
6. Every custom animation takes Reduce Motion into account. Use `Design.Motion.<token>.resolved(reduceMotion:)` where a token fits; a literal animation must be written `reduceMotion ? nil : …`. Haptics still fire under Reduce Motion.
7. No fixed `Task.sleep` may be the only thing between two animations when a real signal exists (a state change, a transition's completion). Where a sleep stays, check `Task.isCancelled` after it.
8. After each pass: `scripts/test.sh --unit auto`, then the UI tests of the screens touched with `--ui`, then the full run before the commit. Look at the screenshots in Light and Dark and in `--language es` and `--language pt-BR`.
9. If something in the code is not as these notes describe, say so in the hand-back instead of working around it.

### 10.1 The shared pieces (pass 1, before any screen)

Create `F/Journey/JourneyScreen.swift`, `F/Journey/TrayRow.swift`, `F/Journey/TrayActions.swift`, `F/Journey/StatusMark.swift`. Add the tokens to `B/DesignTokens.swift`.

**Tokens**

| Token | Value | Notes |
|---|---|---|
| `Design.Radius.tray` | 30 | Top corners of the tray. Replaces the literal 28 in `SheetView` and `PrintView` |
| `Design.Spacing.tray` | 20 | The tray's side padding and the gap between blocks in it |
| `Design.Spacing.stageMargin` | 20 | Minimum space between the object and every edge of the stage |
| `Design.Typography.trayTitle` | `Font.title2.weight(.bold)` | Tray titles. `screenTitle` and the unused `statusTitle` are deleted once nothing uses them |
| `Design.Size.statusMark` | 22 | Base size of `StatusMark`, scaled with `@ScaledMetric(relativeTo: .body)` |

**Pass 1 implementation (0.21.0).** Shared components live in `App/Features/Journey`. The tray measures its natural content and actions, so the 55 % / 75 % cap includes padding and pinned actions. Photo Check reserves 45 % of the full screen for the portrait at standard text sizes. Long warnings and translations therefore scroll inside the tray before the general cap; the native scroll indicator flashes when needed, both check rows remain reachable, and actions stay pinned. At accessibility sizes the stage shrinks instead (§9.8). Measurements in rows are pure lengths (`≈` marks an estimated crown); the full head wording stays in the chip. Debug fixtures exercise thirty rows, a failed face check, closed eyes, and a public generated portrait independently of private local inputs. Simulator checks are recorded in the roadmap; physical motion and haptics still need the founder's review.

**Pass 2 implementation.** Print reserves 45 % of the available height for its tray at normal text sizes (75 % at accessibility sizes), so the full page keeps exactly the same position and scale through all four states. Long instructions scroll within that fixed footprint; actions stay pinned. Page dots use native `UIPageControl` with a 44 pt hit area in a reserved footer below the existing snapping strip. Unlock briefly retains its pre-spend words and balance while the page lifts and the light passes, then shows the next tray. Returning to layout cancels any pending export and deletes completed files. Digital Photo uses the same crop recipe as its actual digital export, including a looser online crop when the profile asks for one.

**Passes 1–2 review fixes (0.21.3).** Cancelling a page arrival clears its hidden-row state. Unlock lift/sweep consume a new trigger change, so a newly mounted page or a returning view cannot replay an old unlock. Original comparison coordinates both holds with an identified timed tap; an expired tap never overrides a hold or a newer tap. Print's import alert offers **Choose Another Photo**, retaining add-person mode; export errors retain **Try Again**. Digital Photo keys transitions by locked/preparing/ready/failed and opts into animated measured tray heights through `JourneyScreen.trayAnimation`; the same token resolves to nil under Reduce Motion. The Copies row retains its numeric transition and selection tick.

**Follow-up alignment fixes (0.21.4).** The tray's plain button style expands the label itself to the full-width 44 pt hit region, retaining pressed and disabled feedback. Photo Check waits for the actual visible overlay's animation completion, with a per-visit identity and cancellation; a held comparison invalidates the interrupted draw, and release redraws before the verdict. The measurement chip is disabled during the initial check so it cannot hide that first draw. Under Reduce Motion, completion is immediate. Fill results carry the complete job/item request: stale results are hidden immediately, late publications are rejected, and an already-open native menu checks its captured request again before applying a count.

**Unlock trigger correction (0.21.5).** Print increments its lift/sweep and success-feedback event only after its unlock action succeeds with a nonzero locked count. Removing the last locked person, opening or returning to the screen, a short balance and a repeated action with nothing locked do not celebrate. This replaces M7’s earlier count-change example, which could also fire on removal.

**`JourneyScreen`**

```swift
struct JourneyScreen<Stage: View, Tray: View, Actions: View>: View {
    /// `stage` receives the free size it may fill (already inside the safe area and the margins).
    init(@ViewBuilder stage: @escaping (CGSize) -> Stage,
         @ViewBuilder tray: @escaping () -> Tray,        // title, supporting line, rows
         @ViewBuilder actions: @escaping () -> Actions)  // a TrayActions
}
```

How it lays out, from back to front:

1. `MatSurface()` (already in `B/Stage.swift`: the grid canvas on `Surface.mat`) with `.ignoresSafeArea()`. It covers the whole screen, including behind the status bar, the navigation bar and the tray's rounded corners.
2. A `VStack(spacing: 0)`:
   - the **stage area**: a `GeometryReader` that takes all remaining height. It calls `stage(CGSize(width: w - 2 * stageMargin, height: h - 2 * stageMargin))` and centres the result. It respects the top safe area, so the object never sits under the navigation bar.
   - the **tray**: `VStack(alignment: .leading, spacing: Design.Spacing.group)` holding `tray()` and then `actions()`, with padding `.horizontal` 20, `.top` 22, `.bottom` 8. Background: `UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30).fill(Design.Surface.tray)` with `.shadow(color: .black.opacity(dark ? 0.6 : 0.12), radius: 16, y: -4)` and `.ignoresSafeArea(edges: .bottom)` (this is exactly the tray `PrintView` draws today at `F/PrintView.swift` 63–68; move it here).
3. **The tray's height limit.** The `tray()` part (not the actions) is wrapped in `ViewThatFits(in: .vertical) { content; ScrollView { content }.scrollBounceBehavior(.basedOnSize) }` inside `.frame(maxHeight: limit)`, where `limit = screenHeight * 0.55 − actionsHeight` (0.75 instead of 0.55 when `dynamicTypeSize.isAccessibilitySize`). Result: a short tray hugs its content; a long one scrolls inside itself while the actions stay visible.
4. `.toolbarBackground(.hidden, for: .navigationBar)` and `.navigationBarTitleDisplayMode(.inline)`, so the mat shows through the bar.
5. `.animation(Design.Motion.rearrange.resolved(reduceMotion:), value: <the tray's state>)` is applied by the screen, not by `JourneyScreen`, so each screen decides what counts as a state change.
6. The tray's `actions()` area carries `.guideAvoid()` (the guide's bubbles must not cover it; defined in `F/TutorialViews.swift`).

**`TrayRow`**

One line of the tray. No background, no border.

```swift
TrayRow(title: Text, detail: Text? = nil, value: Text? = nil, chevron: Bool = false, action: (() -> Void)? = nil,
        leading: () -> some View = { EmptyView() }, trailing: () -> some View = { EmptyView() })
```

- Layout: `HStack(spacing: 12)`: the leading view in a 24 pt wide column (a `StatusMark`, a flag, an SF Symbol in `brandAccent`, or a step number), then `VStack(alignment: .leading, spacing: 2)` with the title (`.body`, primary) and the optional detail (`Typography.cardDetail`, secondary, wraps), then `Spacer`, then the value (`cardDetail` secondary, or `Typography.readout(.subheadline)` for a measurement), then the trailing control, then `chevron.right` (`.footnote.weight(.semibold)`, tertiary) when `chevron` is true.
- Minimum height 50 pt. With an `action` the whole row is one `Button` with `.buttonStyle(.plain)` and `.contentShape(Rectangle())`, `.accessibilityElement(children: .combine)`, trait `.isButton`.
- `TrayRows { … }` is the container: a `VStack(spacing: 0)` that puts a `Divider()` between rows, inset on the leading side to the title's edge (36 pt when rows have a leading view, 0 otherwise). No divider above the first or below the last row.

**`TrayActions`**

```swift
TrayActions(primary: Button, secondary: Button? = nil, peer: Button? = nil)
```

- `primary`: `.brandProminentButtonStyle()`, `.controlSize(.large)`, label with `.frame(maxWidth: .infinity)`.
- `secondary`: a plain teal text button under the primary, `.frame(maxWidth: .infinity, minHeight: 44)`.
- `peer`: a plain teal text button to the **left** of the primary in an `HStack(spacing: 8)`; it takes one third of the width, the primary two thirds (`.layoutPriority` or a `Grid`). Use `peer` or `secondary`, never both.
- At accessibility text sizes `peer` stacks above nothing: it becomes a `secondary` (under the primary).
- No other button styles appear on a journey screen. `.bordered` is not used.

**`StatusMark`**

```swift
StatusMark(_ state: CheckState)        // .pass .warn .fail .manualCheck
StatusMark.progress                    // while checking
```

| State | Symbol | Colour |
|---|---|---|
| pass | `checkmark.circle.fill` | `StatusStyle.pass` (green) |
| warn | `exclamationmark.circle.fill` | `StatusStyle.warn` (orange) |
| fail | `xmark.circle.fill` | `StatusStyle.fail` (red) |
| manualCheck | `eye.circle.fill` | `StatusStyle.neutral` (secondary) |
| progress | `ProgressView().controlSize(.small)` | — |

Size: `.font(.system(size: scaledStatusMark))`, 22 pt at the default text size. `accessibilityLabel` is `StatusStyle.name(for:)` ("Looks good", "Needs attention", "Better to retake", "Check by eye"). It replaces the outline symbols of `AlignmentPresentation.symbol(for:)` on rows and the `.largeTitle` verdict glyph. `CheckDetailsSheet` rows use it too.

**`StepMarker`** (`F/StepMarker.swift`): redraw as `HStack(spacing: 14)` of the three names (`Photo`, `Check`, `Print` or `Save`), each `.subheadline.weight(.semibold)`; the current step in the primary colour, the others secondary. Remove the three capsules. Keep `.frame(minHeight: 44)`, the combined accessibility label "Step N of 3: name", and the identifier `stepMarker`.

Done when: a preview or a throwaway screen shows a mat to every edge, an object centred in the stage, a tray that hugs three rows and one button, and a tray with thirty rows that scrolls while its button stays put; in Light and Dark; at the largest accessibility size.

### 10.2 The fixes, one by one

#### F1 — Type: three roles, no footnotes

*Today:* `Typography.note` is used in 27 places and `caption` in 6 on the screens below; `rowTitle` in 8; `screenTitle` in 6; verdict glyphs use `.largeTitle`.

*Do:*

1. On journey screens replace by role: a screen's one title → `hero` (Home, Finished, welcome, "You're all set") or `trayTitle` (all others); a row's name → `.body`; a supporting line or a row's value → `cardDetail` with `.foregroundStyle(.secondary)`; a measurement → `Typography.readout(.subheadline)`.
2. `rowTitle` (semibold subheadline) → `.body` regular, everywhere.
3. Handle every small grey line exactly as this table says. "Delete" means remove the `Text` and its string key.

| Line (English) | Where today | Action |
|---|---|---|
| "Your photos stay on your iPhone." | `F/HomeView.swift` footer, 366 | Delete from Home. Keep on the welcome page (`F/TutorialViews.swift` 310) as `cardDetail` |
| Credits count, `creditsButton` | `F/HomeView.swift` 370–377 | Remove from Home. The Credits screen stays reachable from Settings › Credits (`settingsCredits`). Update the two UI tests that tap `creditsButton` to go through `settingsButton` |
| Version, `appVersion` | `F/HomeView.swift` 379–386 | Keep as the last line of Home's tray: `Typography.noteDigits`, tertiary, leading. Keep the long press that toggles developer details. Wrap in a `#if` or a build flag later, at 1.0 |
| "Hold to compare with the original" / "Original" / "Finding your face…" / "Framing…" | `F/PhotoCheckView.swift` 180–184 (also carries the identifier `photoCheck`) | Delete all four. The **Original** capsule (M4) replaces the first; the tray title "Checking your photo…" replaces the last two. Move the identifier `photoCheck` onto the Original capsule, which is always present |
| "Fix these issues or continue after checking by eye." and the other verdict subtitles | `F/CheckPresentation.swift` 172–179 | The supporting line under the verdict is now always "Framed for <document name>" once checking is done, and "Finding your face and preparing the background." while checking. Exception: with exactly one attention row, show that row's own sentence (today's behaviour, `F/PhotoCheckView.swift` 257–265). For *Better to retake* show "This photo has problems we can't fix. A new one takes a minute." Delete the two other subtitle strings |
| "Unlocked. Printing and sharing this photo is free." (`unlockedNote`) | `F/PhotoCheckView.swift` 210–213 | When the photo is unlocked this replaces "Framed for …" as the supporting line; keep the identifier `unlockedNote` on it; no icon |
| Row subtitles (titles joined by " · ") | `F/PhotoCheckView.swift` 308 | Keep as the row's `detail`, in `cardDetail` secondary, one line |
| "This document's rules ask for an unedited photo. …" + "Use Original Photo" | `F/PhotoCheckView.swift` 331–336 | Becomes a third `TrayRow`: leading `StatusMark(.manualCheck)`, title "Edited photo", detail the existing sentence, trailing text button "Use Original" (`useOriginal`) |
| "N copies · N pages · Room for N more" (`layoutSummary`) | `F/SheetView.swift` 113–119 | The supporting line under "Your sheet" in Print's layout state. Wording: "12 copies on 10 × 15 cm paper", plus " · 2 pages" when more than one page, plus " · room for 4 more" when there are free slots. Keep the rolling-number transition and the identifier |
| "<size> · N copies" under "Your photo", and the "Check" link | `F/SheetView.swift` 177–190 | Delete both (the summary line says it; Back returns to Photo Check). With two or more people the selected person's name ("Photo 2") is the Copies row's detail |
| "N copies on <paper> paper" (in `printHeader`) | `F/PrintView.swift` 153–160 | The supporting line in the unlock, where and print states |
| "Before you print" | `F/PrintView.swift` 206–207 | Delete |
| "Choose where you print to see the steps." | `F/PrintView.swift` 212–214 | Delete |
| "Never Fit to Page or borderless" | `F/PrintView.swift` 220 | Join into the step's title: "Choose Actual Size, or 100 %. Never Fit to Page." |
| "Your printer and photo paper" / "A print shop or kiosk" | `F/PrintView.swift` 198–199 | Keep as each route row's `detail` |
| Shop note (`printRouteNote`) | `F/PrintView.swift` 233–237 | Keep as a `TrayRow` with the `storefront` symbol leading, in the print state for the shop route |
| "Lay it on the screen to see it is the right size" / "When the prints are back, lay one on the screen" | `F/PrintView.swift` 336–338 | Keep as the detail of the "Check Your Print" row (`checkPrintButton`) |
| The three unlock benefits, "After this, framing and edits are final.", "You have N credits. After this: N credits." | `F/CreditsView.swift` `UnlockCard`, 62–101 | On Print and Digital Photo replace the whole card with one `.body` sentence: "Unlocking gives you every print and the digital photo, as often as you like. Edits are final after that." (identifier `unlockCard`). When the balance is too low add one line under it, `.body`, with `StatusMark(.warn)`: "You have no credits." or "You have 1 credit. You need 2." (identifier `creditBalanceLine`). `UnlockBenefits` stays on the Credits sheet only |
| "Sized for online forms" | `F/DigitalPhotoView.swift` 39–41 | Supporting line under "Your digital photo is ready" |
| "Cut them out and they are ready to use." | `F/FinishedView.swift` 60–62 | Supporting line under Finished's title |
| "Every page is cut the same way." / "Page 1 shown." | `F/FinishedView.swift` 97–99 | Delete from under the mat; append to the first cut step's detail when there are several pages |
| Tip details on Finished | `F/FinishedView.swift` 108–113 | Keep as each row's `detail` |
| Instruction and help lines on Check your print | `F/PrintCheckView.swift` 105–174 | Keep the words, as `cardDetail` secondary, leading (F2) |
| Adjust's line under the photo, Custom size notes, Sheet options notes, Credits footers | `F/AdjustSheet.swift`, `F/DocumentPickerView.swift`, `F/SheetView.swift`, `F/CreditsView.swift` | Sheets: keep as system `Section` footers or `cardDetail`; no change in wording |

Done when: `grep -n "Typography.note\b\|Typography.caption\b\|\.footnote\|\.caption" ` on the journey screens' files returns only Home's version line, chevrons, badges (`.caption2` on the copies badge and the cut badge), and readouts.

#### F2 — Alignment: left

*Do:* in the tray every `VStack` is `alignment: .leading` and no text has `.multilineTextAlignment(.center)` or a bare `.frame(maxWidth: .infinity)` that centres it. Specifically remove the centring at: `F/PhotoCheckView.swift` 268–269 (verdict) and 212 (unlocked note); `F/SheetView.swift` 113–120 (summary line, centred by its parent); `F/DigitalPhotoView.swift` 21 (`VStack(alignment: .center …)`); `F/FinishedView.swift` 58 and 62; `F/TutorialViews.swift` 425 ("You're all set" summary) and the centred seal block; every centred `Text` in `F/PrintCheckView.swift` (107, 113, 127, 130, 148, 151, 165, 169, 174, 314); the balance block in `F/CreditsView.swift` 112–123.

A title with a mark is `HStack(alignment: .firstTextBaseline, spacing: 8) { StatusMark; Text(title) }`, leading.

Stays centred: the object on the stage; button labels; a sheet's navigation title; the true-size line on Check your print (it is an object, not text).

Done when: on every journey screen and sheet, the left edges of the title, the supporting line and the rows line up at 20 pt (16 pt in system lists).

#### F3 — Two surfaces: mat and tray

*Do, per screen (remove exactly these):*

| Screen | Remove |
|---|---|
| Home | `Surface.screen` background and bottom bar (59, 66); the grey hero box `RoundedRectangle(22).fill(Surface.stage)` (142, 176); `Surface.card` on `sessionCard` (273) and `documentCard` (319) |
| Photo Check | `.onMat(bleed: 16)` panel (177–179); `Surface.card` details card (297); `Surface.screen` bottom bar (55) |
| Print (was Your sheet + Print) | `.onMat()` panels (`F/SheetView.swift` 47, `F/PrintView.swift` 142–146); both local trays (`F/SheetView.swift` 50–56, `F/PrintView.swift` 63–68); `Surface.card` on the route cards (285–298), the steps card (231), `checkRow` (345), and `UnlockCard` |
| Digital Photo | `.onMat(bleed: 16)` (25–30) and the card drawn by `UnlockCard` |
| Finished | `.onMat(bleed: 16)` (83–95); `Surface.card` tips card (115); `Surface.screen` bottom bar (39) |
| Welcome, You're all set | `Surface.card` on the credit note (392) and the tips (440); `Surface.screen` (316, 462) |

What stays as its own small surface: paper (white, `paperShadow`), the measurement chip and the Original capsule on the stage, paper chips, the copies badge, the guide's yellow bubble. `.onMat` itself stays in `B/Stage.swift` only if a sheet still uses it; otherwise delete it.

Done when: no `Surface.card`, `Surface.stage` or `.onMat(` is left in the journey screens' files, and no rounded rectangle is drawn inside a tray.

#### F4 — Buttons

*Do, per screen:*

| Screen / state | Primary | Text button | Removed or moved |
|---|---|---|---|
| Home | **Take Photo** (`takePhoto`) | "Choose from Library" (`choosePhoto`), `secondary` | — |
| Home, guide with a photo waiting | **Continue** (`coachAction`) | — | Take Photo and Choose from Library hidden, as today |
| Photo Check | **Print** (`outputPrint`) or **Digital Photo** (`outputDigital`), whichever is the document's main output | "Adjust" (`adjust`), `peer` | The other output (`.bordered` today) moves into the ••• menu (`photoMenu`) as "Digital Photo" or "Print", with the same identifier on the menu item |
| Photo Check, *Better to retake* or eyes measured closed | **Retake** (opens the camera directly: `acquire(.camera, .replace)`) | "Print anyway" / "Use anyway", `secondary` | "Adjust" moves into the ••• menu in this state |
| Print · layout | **Continue** (`continueToShare`) | — | "Check" link deleted; the Fill pill becomes the text menu "Fill pages" (`fillPages`) under the Copies row; the scissors button becomes ••• (`printMenu`) containing Cutting options (`cuttingOptions`), Add another person (`addPerson`), More sizes and paper (`moreOptions`), More Formats (`moreFormats`, only when unlocked) |
| Print · unlock | **Unlock · 1 credit** (`unlockAndPrint`; the number is the locked count: "Unlock · 2 credits") | "Keep Editing" (`keepEditing`), `secondary`: back to layout | When credits are short the primary is **Get Credits** (`getCredits`) |
| Print · where | **Choose where to print**, disabled (`chooseRouteFirst`) | — | The route rows are the controls |
| Print · print, home | **Print** (`printAtHome`) | "Change where", `secondary` | "More Formats" in the ••• menu |
| Print · print, shop | **Share Print Image(s)** (`sharePages`; `sharePagesPreparing` while files are made) | "Change where", `secondary` | — |
| Digital Photo, locked | **Unlock · 1 credit** (`unlockDigital`) | "Keep Editing" (`keepEditing`) | — |
| Digital Photo, ready | **Share Photo** (`shareDigitalJPEG`) | "Done" (`digitalDone`), `secondary` | `.bordered` Done |
| Finished | **Done** (`finishedDone`) | — | — |
| Check your print | **Yes, Same Size** (`checkMatches`) | "No" (`checkNoMatch`), `secondary` | `.bordered` No |
| Check your print · which way | No primary. Three `TrayRow`-style rows with chevrons: "Smaller" (`checkSmaller`), "Larger" (`checkLarger`), "Not sure" (`checkNotSure`) | — | `.bordered` Smaller / Larger |
| Check your print · diagnosis | **Print Again** (`printAgain`, home route) | "Close" (`diagnosisClose`), `secondary` | `.bordered` Close; on the shop route **Close** is the primary |

The toolbar "Done" on Print (`shareDone`) stays, shown when everything is unlocked, as today.

Done when: `grep -n "buttonStyle(.bordered)"` on the journey screens' files returns only the paper chips and the stepper; each state shows exactly one filled button.

#### F5 — The object fills the stage

*Today:* Photo Check's photo is `.frame(maxWidth: width)` with `width` fixed at 250 while checking and 210 after (200 at accessibility sizes) (`F/PhotoCheckView.swift` 139–154). Print shows a compact preview 170 pt tall (110 for a landscape page) (`F/PrintView.swift` 137–138). Digital Photo uses `maxWidth` 240 or 200. Finished fits a 300 × 280 box.

*Do:*

1. **Photo Check and Digital Photo.** With the stage size `(w, h)` from `JourneyScreen` and the format's aspect `a = width / height`: reserve `r = 40` pt at the bottom for the measurement chip and the Original capsule; `photoHeight = min(h − r, w / a)`, `photoWidth = photoHeight * a`. Place the photo centred in the area above the reserve, the chip centred under it, the capsule at the stage's bottom-leading corner.
2. **The settle (keeps moment M2).** While `checking` is true the photo is drawn at `scaleEffect(1.06)` with `paperShadow(lifted: true)`; when it lands it animates to `1.0` and the normal shadow with `Design.Motion.landing`. This replaces the 250 → 210 width change.
3. **Print.** Use the full `SheetPreview` (not `compact`) in every state, with `pageBox = (w, h − 24)` (24 pt for the page dots). The page-fitting code in `SheetPreview` (`F/SheetView.swift` 622, 646–650) does not change. The `compact` mode and `pageStack` are no longer used by Print; delete them if nothing else uses them (the multi-page hint is now the next page peeking in from the right, which the horizontal paging already does).
4. **Finished.** Fit the page to the stage minus 32 pt (16 pt each side for the cut badges).
5. **Home.** The three sample papers scale with the stage: the group's natural size is 300 × 236 pt; apply `scaleEffect(min(w / 300, h / 236, 1.35))`.

Done when: on a 6.1-inch iPhone at the default text size the photo on Photo Check is at least 45 % of the screen height (measure the screenshot: at least 380 of 844 pt), and on Print the page is at least 300 pt tall.

#### F6 — No empty middles

Nothing to build beyond F5 and `JourneyScreen`: the stage takes the free height. Check Home, Photo Check, Digital Photo (locked), and Print's where state on the smallest and largest iPhone: the tray's bottom is at the screen's bottom and the object fills what is above.

For the sheet **Check your print** (`F/PrintCheckView.swift`): put the true-size reference in the vertical centre of the area above the buttons, draw the line 2 pt thick with 14 pt end ticks, and put the question directly under it as the title. The reference must stay at true size (`length * pointsPerMM`): thicker, never longer.

#### F7 — One layout

Each journey screen's `body` becomes `JourneyScreen(stage:tray:actions:)`. Remove each screen's own `ScrollView`, `safeAreaInset(edge: .bottom)`, `.background(Design.Surface.screen)`, and the accessibility-size branch that moved the buttons into the scroll content (`if dynamicTypeSize.isAccessibilitySize { actions }`): `JourneyScreen` handles large text itself.

#### F8 — One status mark

| Place | Today | Becomes |
|---|---|---|
| Photo Check verdict | `.largeTitle` glyph over a centred `hero` title (`F/PhotoCheckView.swift` 243–255) | `StatusMark` before the title in `trayTitle`; `StatusMark.progress` while checking. Keep the bounce (`.symbolEffect(.bounce, options: .nonRepeating, value: verdictBounce)`) on the mark and the haptic at 224–231 unchanged. Keep `checkHeadline` on the combined title block |
| Photo Check rows | Outline symbols, width 24 (`281–292`) | `StatusMark(worstState)` on the Measured row, `StatusMark(.manualCheck)` on the by-eye row |
| Row titles | "Everything measured looks fine" / "N things to look at" / "N things to check by eye" | Titles "Measured" and "To check by eye". Details stay (the joined names). Values: the head height readout ("23.7 mm") on Measured when a measurement exists; the count on the by-eye row. Identifiers `measuredRow`, `byEyeRow` stay |
| Print "Your sheet is ready" | Green `checkmark.circle.fill` in `titleGlyph` above the title | No mark: the title alone. (A mark means a check was made; here nothing was checked.) |
| Digital "Your digital photo is ready." | Green glyph + title, centred | `StatusMark(.pass)` before the title |
| Check your print icons (`ruler`, `arrow.left.and.right`, `printer`) | `titleGlyph` above centred titles | Delete the icons; titles only. The diagnosis title gets `StatusMark(.warn)` before it |
| Finished, You're all set | 56 pt seal above a centred title | The seal stays at 56 pt, leading, above the title (the one large mark, §9.6) |
| `CheckDetailsSheet` rows | `Label` icons from `StatusStyle.symbol` | `StatusMark` |

#### F9 — Print's layout state (the old Your sheet tray)

The tray, top to bottom (all of `trayContent`, `F/SheetView.swift` 124–166, is rebuilt):

1. Title "Your sheet" (`trayTitle`).
2. Supporting line (`layoutSummary`), F1.
3. With two or more people only: the row of person circles (`personCircle-N`), as today (52 pt, selected ring, copies badge, context menu "Check Photo" / "Remove Photo"). With one person there are no circles; "Add another person" is in the ••• menu.
4. `TrayRow(title: "Copies", detail: <"Photo 2" when several people>)` with the `Stepper` (`copiesStepper`) as the trailing control and the count as the value before it (rolling number, `.numericText`). Under the row, when `fill` is not empty: the text menu "Fill pages" (`fillPages`) with today's items ("1 page · 12 copies" …).
5. `TrayRow(title: "Paper")` whose trailing content is the chip strip (`paper-<id>`, then "More", `moreOptions`), horizontally scrollable, starting under the title when it does not fit beside it.
6. The warning `StatusLabel` "N copies do not fit within N pages." becomes a row with `StatusMark(.warn)`.
7. `TrayActions(primary: Continue)`.

The guide's tips on this state point at the Copies row's stepper (`.copies`), then the chips (`.paper`), then Continue (`.continueSheet`): change the order in `guideTip` to `[.copies, .paper, .continueSheet]`.

#### F10 — Print is one screen

*Today:* `Route.sheet` opens `SheetView` and `Route.share` opens `PrintView` (`F/AppFlow.swift` 5–10, 39–53).

*Do:*

1. **Routes.** Delete `Route.share`. `Route.sheet` opens the new `PrintView`. Remove `path.append(.share)` (`F/SheetView.swift` 157), the zoom source for `.share` (`F/SheetView.swift` 93), and the `.share` cases in `F/Transitions.swift` and in the error-alert rule in `F/AppFlow.swift`. In `F/AppFlow.swift` 52 change `path.firstIndex(of: route)` to `path.lastIndex(of: route)` (the same in `revealCopies`): with `firstIndex`, a path that contains the same route twice zooms from the wrong source.
2. **Files.** `F/PrintView.swift` becomes the screen. `F/SheetView.swift` keeps only the reusable pieces: `SheetPreview`, `SheetPageView`, `UprightPageView`, `SheetOptionsView`, `CuttingOptionsView`, `fillChoices`. Move `revealCopies`, `copiesBinding`, `steppedCopies`, `summary(_:)`, `personCircle`, `paperChips`, `fillMenu` into `PrintView` (or an extension file `F/PrintView+Layout.swift`).
3. **State.**

```swift
enum PrintStep { case layout, unlock, route, send }
@State private var layoutConfirmed = false
private var step: PrintStep {
    if !layoutConfirmed { return .layout }
    if locked > 0 { return .unlock }
    if route == nil { return .route }     // route is forced to .shop when home printing is unavailable
    return .send
}
```

   - **Continue** sets `layoutConfirmed = true`.
   - **Keep Editing** sets `layoutConfirmed = false`.
   - **Change where** sets `chosenRoute = nil`.
   - Choosing a route row sets `chosenRoute` (today's `routeCard` action, with its `.selection` haptic).
   - Unlock is today's `unlock()`.
   - Arriving on the screen always starts at `.layout`, also when the photos are already unlocked.
4. **Back.** In `.layout` the system back button and the edge swipe work as usual and leave the screen. In the other three states hide the system button (`.navigationBarBackButtonHidden(step != .layout)`) and show a toolbar button in `.topBarLeading` with `chevron.backward` (accessibility label "Back") that steps back: send → route (`chosenRoute = nil`; when the route is forced, go to layout), route → layout, unlock → layout. This is the one place where the edge swipe is given up, for three short states.
5. **The stage** shows the full `SheetPreview` in every state. It must not be re-created when the step changes: keep it outside any `switch step`, so the page never flickers.
6. **The tray per state** (titles `trayTitle`, supporting line `cardDetail`):

| Step | Title | Supporting line | Rows | Actions |
|---|---|---|---|---|
| layout | "Your sheet" | summary (`layoutSummary`) | F9 | **Continue** |
| unlock | "Unlock this photo" ("Unlock 2 photos" for several) | "12 copies on 10 × 15 cm paper" | the unlock sentence (`unlockCard`); the balance line only when short | **Unlock · 1 credit** / **Get Credits**; "Keep Editing" |
| route | "Where will you print?" | the copies line | two `TrayRow`s: `printer` "At Home" · "Your printer and photo paper" (`routeHome`); `storefront` "At a Shop" · "A print shop or kiosk" (`routeShop`); each with a chevron | disabled **Choose where to print** |
| send, home | "Print at home" | the copies line | step rows with a number in the leading column: "Load 10 × 15 cm photo paper"; "Choose Actual Size, or 100 %. Never Fit to Page."; "Measure the 50 mm line before cutting" (or "Measure one photo before cutting"); then "Check Your Print" (`checkPrintButton`, `ruler` leading, chevron) | **Print**; "Change where" |
| send, shop | "Print at a shop" | the copies line | "Order a standard print on 10 × 15 cm paper"; "Ask for no cropping and no Fit to Page"; the measure step; the shop note if the profile has one (`printRouteNote`); "Check Your Print" | **Share Print Image(s)**; "Change where" |

   The identifier `printHeader` goes on the combined title-and-supporting-line block in the unlock, route and send states.
7. **Transitions between steps:** `.animation(Design.Motion.rearrange.resolved(reduceMotion:), value: step)` on the tray; the tray's content uses `.transition(.opacity)` keyed by `.id(step)`. The stage does not animate, except for the unlock moment (M7).
8. **Files to print.** `model.prepareExport()` is called after a successful unlock (today) and on entering `.send` when `model.exported == nil`. When `layoutConfirmed` goes back to false, call `model.finishExport()` so files made for the old layout cannot be printed. Verify what `finishExport()` discards before relying on it; if it does more than drop the files, say so.
9. **Menus.** The toolbar's trailing ••• (`printMenu`): Cutting options (`cuttingOptions`), Add another person → Take Photo (`addPersonCamera`) / Choose Photo (`addPersonLibrary`), More sizes and paper (`moreOptions`), and, when nothing is locked, More Formats (`moreFormats`). The UI tests that tap `cuttingOptions`, `moreFormats` or `addPerson` directly must open `printMenu` first.
10. **The first page full.** In `F/PhotoWorkflow.swift` (`install`, around 279 and 291) the first person's item is created with 8 copies. Create it with the number of copies that fills one page instead: add a pure helper `PrintLayoutSolver.copiesFillingOnePage(job:itemID:)` (the same search `SheetView.fillChoices` does for `pages == 1`: the largest count whose layout is complete on one page) and use its result, falling back to 8 if it returns nil. A second and third person still start with 4. Unit-test the helper for 26 × 32 mm on 10 × 15 cm (12), 35 × 45 mm on 10 × 15 cm, and 2 × 2 in on 4 × 6 in. UI and unit tests that expect "8 copies" for a new sheet change to the new count.
11. **The guide.** `guideTip` in the merged screen: layout → `[.copies, .paper, .continueSheet]` through `model.tutorial.current`; unlock → `.unlock`; route → `.route`; send → `.printHome` or `.share`. The route tip's anchor is the pair of rows; `prefersBelow` no longer applies to it (it sits above the rows, which are in the tray).

Done when: from Photo Check, **Print** opens one screen; the page stays in exactly the same place from "Your sheet" to "Print at home"; Back from each state lands where the table says; the full UI test run passes with the identifier changes of §10.4.

#### F11 — One review

*Today:* after the shutter `C/CameraView.swift` `takePhoto()` (439–482) shows an in-place review (`showingCapturedReview`, controls at 484–553) with **Retake** (`cameraRetake`) and **Use Photo** (`cameraUsePhoto`). Analysis starts when the review appears (`onReviewChange(staged)` → `PhotoWorkflow.prepareAhead`). **Use Photo** calls `onCapture`, which runs `model.useCapture`; when the photo is installed, `F/AppFlow.swift` 93–103 pushes Photo Check behind the camera cover and closes the cover.

*Do:*

1. In `takePhoto()`, after the still is staged and its preview image is loaded, keep showing the still full screen exactly as the review does today (the black layer and the mirrored, clipped image: keep that code), with **no controls**: no Retake, no Use Photo, no "Review your photo" title. Then immediately do what **Use Photo** does today: `onReviewChange(staged)` (starts the analysis), then `onCapture(staged, metrics)`.
2. While waiting for the install, show a small `ProgressView` (white, `.controlSize(.regular)`) centred near the bottom where the shutter was, and keep **Cancel** (`cameraReviewCancel`) at the top; Cancel calls today's `discardCapturedPhoto()` and returns to the live camera.
3. The hand-over (this is moment M1): when `model.lastInstalled` changes in `F/AppFlow.swift`, do today's push without animation, then close the cover inside a transaction with `disablesAnimations = true`, with a white veil over the change:
   - the camera fades its existing bloom layer (`flash`) to full for 0.15 s before the cover closes;
   - `AppFlow` shows a full-screen white overlay at opacity 0.55 the moment the cover closes and fades it to 0 over 0.35 s (`easeOut`);
   - under Reduce Motion: no veil; a 0.2 s cross-fade.
4. Photo Check then opens showing the uncropped still (as it does today while `landed` is false) and lands it into the frame (M2). On this route start the landing 350 ms after the veil starts to fade instead of the fixed 650 ms: pass the reason for arrival to `PhotoCheckView` (a `Bool` such as `arrivedFromCamera`) and pick the delay from it.
5. **Eyes closed.** Today the review says "Your eyes look closed or turned down" when `model.aheadEyesLookClosed` is true and makes Retake the main button. Keep the measurement; store the result on the photo's entry when it is installed (find where `aheadEyesLookClosed` is set in `F/PhotoWorkflow.swift` 72–91 and copy it to the entry in `useCapture` / `install`). On Photo Check, when it is true: the supporting line is "Your eyes look closed or turned down." with `StatusMark(.warn)`, and the actions are those of the retake state in F4. Keep the identifier `eyesClosedNote` on that line.
6. Delete `capturedReviewControls`, `usingPhoto`, the strings "Review your photo" (camera), "Use Photo", and the camera's "Retake" if nothing else uses them; delete the VoiceOver announcement "Photo captured. Review your photo." and announce "Photo captured." instead.
7. Tests: `testCameraCapturedReviewOffersRetake` (in `SheetAndCameraUITests`) is rewritten to: capture → Photo Check appears (`photoCheck`) → the toolbar's **Retake** (`retake`) exists. The launch arguments `--camera-review-fixture` and `--camera-review-off-center` keep driving the still shown during the hand-over.
8. The 15-second safety net in `F/AppFlow.swift` 104–109 stays.

Done when: on the iPhone, from the shutter press to the framed photo on Photo Check there is no tap and no intermediate screen; Cancel during the wait returns to the camera; a photo with closed eyes offers Retake as the filled button.

### 10.3 The moments, one by one

Each has: what the code does today, what it must do after 0.21, and how to tell it works. "RM" is Reduce Motion.

#### M1 — The shutter

- **Today.** `C/CameraView.swift`: `flash = true`, a `Task` sleeps 120 ms and sets it false; the bloom is a `RadialGradient` (white 0.55 → 0.18 → clear, radius 20 → 380) animated `easeOut(0.23)`, not drawn under RM (209–213). Haptic: `.sensoryFeedback(.impact(weight: .medium), trigger: camera.isCapturing)` when capturing starts (130). The guide oval fades out while capturing (`C/CameraFramingGuide.swift` 65–66).
- **After.** Unchanged at the press. The end is F11 step 3: the white veil that carries the still onto Photo Check.
- **Sequence and timings:** press → haptic and bloom (0.23 s up, 0.23 s down) → the still, full screen, with a spinner (as long as the face analysis takes, typically under a second) → veil up 0.15 s → cover closes, no animation → veil down 0.35 s on Photo Check → landing (M2).
- **Works when:** in a screen recording at normal speed there is one continuous white pulse between the camera and Photo Check and no frame shows Home or an empty Photo Check; with RM on there is a plain cross-fade and the haptic still fires.

#### M2 — The landing

- **Today.** `F/PhotoCheckView.swift` `.task(id: photoID)` (110–124): `landed = false`; sleep `Design.Motion.landingDelay` (650 ms, 50 ms under RM); wait in 50 ms steps until `entry.isAnalyzing` is false; then `withAnimation(Design.Motion.landing…) { landed = true }`. `PortraitView(showsOriginal: comparing || !landed)` shows the uncropped photo until then; the crop springs to the frame (`Motion.reframe` inside `PortraitView`), the width goes 250 → 210, the shadow from lifted to normal.
- **After.** The same sequence on a larger photo (F5): uncropped still at scale 1.06 with the lifted shadow → `landing` spring (0.8 s, bounce 0.12) to the framed crop at scale 1.0 with the normal shadow. Delay: 650 ms after a push, 350 ms when arriving from the camera (F11). Add `guard !Task.isCancelled` after every sleep in this task.
- **No haptic** belongs to the landing; the verdict's haptic follows (M3).
- **Works when:** the first thing that moves on Photo Check is the photo tightening into its frame; leaving the screen mid-landing and coming back restarts it cleanly; with RM on the framed photo simply appears.

#### M3 — The measuring

- **Today.** After the landing, if a measurement exists: sleep 600 ms, `showsMeasureLines = true`; `MeasurementOverlay` (`F/MeasurementOverlay.swift` 35–94) draws three white hairlines (crown and chin dashed, eyes solid) and a bracket with `.trim(from: 0, to: progress)` over `easeOut(0.7)` and fades in the label "Head 34 mm" / "allowed 32–36 mm"; after 2.6 s the lines fade over 0.35 s. `MeasurementChip` under the photo toggles them (`measureChip` / `measureChipLinesShown`). The verdict: the headline stays `.checking` until background and light are done; when it changes, `.sensoryFeedback` gives `.success` for *Looks good* and `.warning` for the other two (224–231), and 80 ms later the glyph bounces once (232–239), not under RM.
- **After.** The same, with three changes:
  1. The chip sits on the stage under the photo (F5); the overlay is drawn on the photo as today.
  2. While the lines draw, the tray's title is "Checking your photo…" with `StatusMark.progress`. When the headline changes, the title cross-fades to the verdict (`.contentTransition(.opacity)`), the `StatusMark` bounces once, the haptic fires. Order in time: landing → lines draw (0.6 s after landing, 0.7 s to draw) → verdict whenever the last check finishes. If the checks finish before the lines have drawn, hold the verdict until the lines are fully drawn (`progress == 1`): the measuring must be seen before the answer.
  3. Fix: add `guard !Task.isCancelled` after the 600 ms sleep; cancel the bounce `Task` in `.onDisappear`.
- **Works when:** the lines are seen drawing before the verdict appears, every time, also on a fast phone; the verdict arrives with one bounce and one haptic; reopening an already-checked photo shows the verdict at once, with no haptic.

#### M4 — Compare

- **Today.** A long press on the photo (`onLongPressGesture(minimumDuration: 0.15, maximumDistance: 40)`, `onPressingChanged`) sets `comparing` with `Design.Motion.compare` (158–163); the uncropped original shows while held; the overlay hides; an accessibility action "Compare with original" toggles it. Nothing on screen says it exists except a grey caption.
- **After.** Keep the long press on the photo. Add the **Original** capsule on the stage, bottom-leading, 16 pt from the edges: `Label("Original", systemImage: "rectangle.on.rectangle")`, `.font(.subheadline.weight(.semibold))`, `.buttonStyle(.glass)`-like capsule (the system glass capsule; minimum height 36 pt, hit area 44 pt). Pressing and holding it sets `comparing` exactly like the photo's gesture (`onLongPressGesture(minimumDuration: 0, …, onPressingChanged:)`); a plain tap shows the original for 1.2 s and returns. While `comparing`, the capsule is filled (`brandAccentFill`, white label). It is disabled while checking. It carries the identifier `photoCheck` and the accessibility hint "Press and hold to compare with the original."
- **Works when:** a first-time user can find and use compare without being told; releasing always returns to the framed photo; VoiceOver's action still toggles.

#### M5 — The photo becomes its copies

- **Today.** Photo Check's photo is a `matchedTransitionSource` for `.sheet` (`F/PhotoCheckView.swift` 165); the destination uses `.navigationTransition(.zoom…)` (`F/Transitions.swift` 31–47). On arrival from Photo Check, `SheetView.revealCopies()` (`F/SheetView.swift` 96–111): `revealedRows = 0`, sleep 300 ms, then for each row `withAnimation(.spring(duration: 0.35, bounce: 0.2)) { revealedRows = row }` and sleep 110 ms; finally `revealedRows = nil` with `easeOut(0.25)`. Hidden copies are at opacity 0 and scale 0.6; their slots show as dashed outlines. One light impact per row (84). Skipped under RM.
- **After.** The same, into Print's layout state (F10). Three changes:
  1. Start hidden: initialise `revealedRows` to 0 in `PrintView`'s `init` when the previous route is a `.check`, so no frame shows a full page before the reveal (today it is set in a `.task`, one frame late).
  2. With the first page full (F10 step 10) every row fills: on 10 × 15 cm with a 26 × 32 mm photo that is four rows of three.
  3. Use `path.lastIndex(of:)` (F10 step 1).
- **Timings:** zoom (system) → 300 ms → rows at 110 ms intervals, each a 0.35 s spring → cut marks and the check line fade in over 0.25 s.
- **Works when:** tapping **Print** on Photo Check makes the portrait grow into the page and the rows drop in one after another with a tap each; with RM on the page is simply full; swiping back mid-reveal works and coming forward again does not replay it for the same visit.

#### M6 — A copy at a time

- **Today.** The solver always uses the fullest grid, so adding a copy only inserts one photo view (`.transition(.opacity.combined(with: .scale(scale: 0.8)))`, animated with `Motion.rearrange`) into the next free slot; free slots are dashed outlines (`emptySlots`, `F/SheetView.swift` 793–807). The summary and the copies count roll (`.contentTransition(.numericText(value:))` with `.snappy`). The stepper gives a `.selection` tick per real change (`copiesTick`). When a page is added the preview scrolls to it (`.smooth(duration: 0.4)`) and fills it row by row (`fill(newPagesFrom:)`: 450 ms, then 90 ms per row). Pages snap (`.scrollTargetBehavior(.viewAligned)`).
- **After.** Unchanged. It now lives in Print's layout state. Do not "simplify" any of it while moving the code. The rolling count moves to the Copies row's value and the summary line.
- **Works when:** each tap on + adds exactly one photo in the next slot with a tick, nothing else on the page moves, and the 13th copy on a 12-slot page brings a new page that fills row by row.

#### M7 — The unlock

- **Today.** `unlock()` (`F/PrintView.swift` 443–449) runs `model.unlockAll()` inside `withAnimation(Motion.rearrange)`; the `UnlockCard` leaves with opacity and a 0.9 scale; `.sensoryFeedback(.success, trigger: locked == 0)` (107), which fires on any change of that value; then `promptRouteChoice` scrolls to the route cards and pulses a ring. The page itself does nothing (the design doc's "the page lifts" was never built). On Digital Photo there is no animation and the haptic fires when the file is ready, not at the tap.
- **After.** The page is still on the stage, so the moment happens on it:
  1. **Trigger:** increment the celebration event in Print's `unlock()` only after `model.unlockAll()` succeeds with at least one locked photo. Do not derive it from the locked count: removing the last locked person also makes that count zero. Opening or returning to the screen, removing a person, an insufficient balance and a repeated action with nothing locked do not celebrate.
  2. **Haptic:** `.success`, from the same trigger (replace the `locked == 0` trigger).
  3. **Lift:** the page scales 1.0 → 1.03 → 1.0 (`spring(duration: 0.6, bounce: 0.25)` up, settling back), with `paperShadow(lifted: true)` during it.
  4. **Light sweep:** one band of light crosses the page once: a `LinearGradient` from clear to `white.opacity(0.55)` to clear, 40 % of the page's width, rotated 20°, moving from fully off the leading edge to fully off the trailing edge in 0.7 s (`easeInOut`), masked to the page's rectangle, `.blendMode(.plusLighter)`, `.allowsHitTesting(false)`, removed when done. Put it in a small reusable modifier `lightSweep(trigger:)` in `B/Stage.swift`.
  5. **Tray:** cross-fades from the unlock state to "Where will you print?" with `Motion.rearrange`, starting 0.25 s after the sweep starts, so the eye is on the page first.
  6. Delete `promptRouteChoice` and its ring pulse: the tray now shows only the route rows, so nothing needs pointing at.
  7. **Digital Photo:** the same lift and sweep on the photo and the `.success` haptic at the unlock, then the tray changes to "Your digital photo is ready" when the file exists (show "Preparing your photo…" with `StatusMark.progress` as the title meanwhile). Remove the haptic on `result?.id`.
  8. **RM:** no lift, no sweep; the tray cross-fades; the haptic fires.
- **Works when:** on the tap the phone gives one success tap, the page breathes once and a light passes over it, and then the question appears; opening Print with an already-unlocked photo does none of this.

#### M8 — The print matches the screen

- **Today.** `F/PrintCheckView.swift`: `TrueSizeReference` draws the 50 mm line (a `Canvas`, 1 pt, end ticks) at `length * pointsPerMM`; **Yes, Same Size** sets `showFinished = true`, a plain push with nothing else; **No** swaps to "Is the print smaller or larger?" (`.selection`); an answer shows the diagnosis (`.warning`). Those swaps use a bare `withAnimation` with no RM check.
- **After.**
  1. The line is drawn large and central (F6): 2 pt, 14 pt ticks, its readout "50 mm" under it in `Typography.readout(.subheadline)`.
  2. On **Yes, Same Size**: the line and its ticks change colour to `StatusStyle.pass` over 0.25 s; a `StatusMark(.pass)` appears at the line's trailing end and bounces once; `.sensoryFeedback(.success)`; after 600 ms (300 ms under RM, no bounce) push Finished. Disable the buttons during the wait.
  3. Finished then arrives **without** its own success haptic (remove `.sensoryFeedback(.success, trigger: appeared)` at `F/FinishedView.swift` 45 when arriving this way; keep it for any other arrival): one success, not two.
  4. Give the three `withAnimation` calls an RM check.
- **Works when:** saying yes turns the line green with one tap of the phone before the next screen appears; the line on screen still measures 50 ± 0.5 mm with a ruler.

#### M9 — The cut order

- **Today.** `F/FinishedView.swift` `CutOverlay` (148–189): one `Canvas` draws every cut of `CutPlan(page:)` at once (a white 3.5 pt halo and a 1.5 pt teal line; trims dashed), with two numbered badges at the first row cut and the first column cut. Nothing animates. The seal bounces and a success haptic fires on appear.
- **After.** The cuts draw themselves in cutting order:
  1. Give `CutOverlay` a `progress: Double` from 0 to `plan.cuts.count` and make it `Animatable` (`animatableData = progress`). Cut number `i` (in `Cut.index` order) is drawn from its `from` point towards its `to` point by the fraction `min(max(progress − i, 0), 1)`.
  2. Badge 1 fades in when the first row cut starts; badge 2 when the first column cut starts.
  3. Start 400 ms after the screen appears: `withAnimation(.linear(duration: min(0.18 * count, 2.5))) { progress = count }`.
  4. The row of the tray that describes the stage being drawn ("Cut the strips apart first", then "Then cut each photo out") is the primary colour while its cuts draw and secondary before; all rows are primary when drawing ends.
  5. RM: `progress = count` at once. No haptic per cut.
- **Works when:** a person who has never cut ID photos can say, after watching once, which cuts come first.

#### M10 — The sample people

- **Today.** `F/HomeView.swift`: a tap on the hero (when the person has no photo yet) advances `sampleIndex` through nine sample people; the three papers re-pose (rotation and offset from `poses`) with `spring(duration: 0.55, bounce: 0.35)` (a 0.3 s ease under RM) and the images cross-fade; a light impact; accessibility action "Show another example"; identifier `homeHero`.
- **After.** Unchanged, on the mat instead of the grey box. Keep the tap target as the whole group of papers.
- **Works when:** tapping the papers on Home shuffles them to another person with a light tap, nine times round.

#### M11 — Every touch answers

The full map, to keep exactly (file, kind, trigger):

| Where | Feedback | When |
|---|---|---|
| Camera | medium impact | capture starts |
| Camera | selection | each countdown number; the Auto button |
| Photo Check | success / warning | the verdict changes to *Looks good* / to the other two |
| Adjust | rigid impact (0.6) | the rotation crosses level, or zoom and position return to automatic |
| Print · layout | light impact | each row of the arriving first page |
| Print · layout | selection | each real change of copies (stepper or Fill); a new paper; another person selected |
| Print | success | the unlock (M7) |
| Print · where | selection | a route chosen |
| Check your print | selection / warning / success | "No" / a diagnosis shown / "Yes, Same Size" (M8) |
| Finished | success | appears, unless it follows M8 |
| Digital Photo | success | the unlock (M7), no longer the file |
| Credits | success | the balance changes |
| Home | light impact | another sample person |
| You're all set | success | appears |

Numbers that roll (`.contentTransition(.numericText)`, `.snappy`, not under RM): the camera countdown, the copies count and the summary line, the copies badge on a person's circle, the credit balance, "Guide · N of M".

New in 0.21: no haptic for a tray state change by itself (Continue, Keep Editing, Change where): the tray's movement is the answer.

#### M12 — The guide

- **Today.** `F/TutorialViews.swift`: a bubble pops in at scale 0.92 with `spring(duration: 0.45, bounce: 0.3).delay(0.2)` (a 0.2 s fade under RM); the hand symbol bounces twice per new tip; the ring around the control breathes (`easeInOut(1.1).repeatForever`, steady under RM). The ring is the one looping animation in the app, on purpose: it is temporary and it is the only thing that tells a first-time user where to tap.
- **After.** Unchanged, re-anchored to the new controls: `.document` on Home's document row; `.takePhoto`; `.checkResult` on Photo Check's two rows (the bubble above them, in the stage's lower part); `.output`; `.copies`, `.paper`, `.continueSheet` in Print's layout state; `.unlock`; `.route` on the two route rows; `.printHome` / `.share`. Bubbles keep off the tray's actions unless they point at one (`guideAvoid`).
- **Works when:** `testTutorialCoachesThePhotoToPrint` passes with the merged screen and, on the iPhone, every bubble's tail touches its control and no bubble covers a button it is not about.

### 10.4 Identifiers

**Unchanged, same kind of element:** `settingsButton`, `homeHero`, `takePhoto`, `choosePhoto`, `coachAction`, `yourSheet`, `sessionMenu`, `documentCard`, `appVersion`, `stepMarker`, `checkHeadline`, `measuredRow`, `byEyeRow`, `unlockedNote`, `useOriginal`, `adjust`, `outputPrint`, `outputDigital`, `retake`, `photoMenu`, `measureChip`, `measureChipLinesShown`, `portrait`, `sheetPreview`, `layoutSummary`, `copiesStepper`, `fillPages`, `paper-<id>`, `moreOptions`, `personCircle-N`, `continueToShare`, `unlockAndPrint`, `getCredits`, `keepEditing`, `routeHome`, `routeShop`, `chooseRouteFirst`, `printAtHome`, `sharePages`, `sharePagesPreparing`, `shareDone`, `checkPrintButton`, `printRouteNote`, `unlockDigital`, `shareDigitalJPEG`, `digitalDone`, `finishedScreen`, `finishedDone`, every identifier of Check your print, Credits, Settings, Adjust, the document picker, the camera's live screen, and the guide.

**Moved:**

| Identifier | From | To |
|---|---|---|
| `photoCheck` | the caption under the photo | the Original capsule |
| `printHeader` | the header under the mat on Print | the title block of the tray in the unlock, where and print states |
| `unlockCard` | the card's title | the unlock sentence |
| `creditBalanceLine` | always shown in the card | the line shown only when credits are short |
| `cuttingOptions`, `moreFormats`, `addPerson`, `addPersonCamera`, `addPersonLibrary` | toolbar button, tray button, dashed circle | items of the ••• menu `printMenu` (new) |
| `requirementsLink` | a row on Home | an item in Home's ••• menu and a row in Choose document |
| `creditsButton` | Home's footer | removed; tests use `settingsButton` then `settingsCredits` |
| `eyesClosedNote` | the camera review | Photo Check's supporting line |

**Removed, with their tests rewritten:** `person-N` (the "Check" link), `cameraRetake`, `cameraUsePhoto`. `cameraReviewCancel` stays, on the Cancel button shown while the still is handed over.

**New:** `printMenu` (the ••• menu on Print), `changeRoute` ("Change where"), `printBack` (the back button that steps through Print's states). The Original capsule needs no new identifier: it carries `photoCheck`.
