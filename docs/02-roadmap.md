# 02 — Roadmap: from 0.16.0 to App Store 1.0

**Updated:** 2026-11-12, at tag `v0.16.0`.

The roadmap is ambitious on purpose, and **nothing in it is final**. If a better idea appears for how the app looks, feels, or performs, propose it, record the decision in [05-decisions.md](05-decisions.md), and change this file in the same commit.

## 1. Where we are

- The full journey works on an iPhone for 22 documents and custom sizes: guided camera, automatic framing, background and light, Photo Check, Adjust, multi-person print sheets, home and shop printing, digital photo, credits with unlock in place, three languages.
- **Good:** the camera screen, the deterministic core (crop solver, layout solver, rules as data), the test suite (162 passing).
- **Not good enough yet:** the look (it reads like Settings), the ending (nothing after the print panel), the sense of one journey, and visible precision. See the review in [03-design.md §5](03-design.md).
- **Not real yet:** purchases (credits are added without payment), drafts (everything is lost when the app closes), and all evidence that needs devices and people (print measurements, speed, real faces).

## 2. The path at a glance

| Version | Theme | What the person gets | Main items |
|---|---|---|---|
| **0.17** | The ending | A print they can check against the screen, a cutting guide, a finished moment; controls that respond to touch | U1, U6, P1 |
| **0.18** | Shorter and measured | Five screens instead of eight; the app visibly measures the photo; results appear almost at once | U2, U3, P2, U15 |
| **0.19** | Calipic becomes the app | Nothing visible: the spike becomes the production project, with Swift tests in CI | E1 |
| **0.20** | The look | A recognisable Calipic: warm stage, real paper, one continuous photo from shutter to sheet, real faces on Home | U5, U4, U10 |
| **0.21** | Keep my work | Close the app and continue later; reprint for free; delete everything in one tap | E2, U9 |
| **0.22** | Real credits | Buying a pack works; the balance survives a reinstall | E3, U12 |
| **0.23** | Tools | An editor and a sheet that feel like instruments; every unhappy path designed | U7, U8, U13, U14, P4, P5 |
| **0.30** | Photo quality | Clean hair edges, glare and shadow advice, helper mode, a good-spot coach | Q1–Q4, U11 |
| **0.40** | Ready for the world | Every Wave A profile re-checked; upload presets tested against the real forms; help; Siri | Q4, Q6, E4, E5, E6 |
| **0.90** | Harden | Nothing new: speed, memory, privacy, and edge cases closed | P6–P10, L1 |
| **0.95** | Beta | Real people, real printers | L2 |
| **1.0** | Launch | Worldwide, Wave A | L3 |

Work that needs devices and people (track V) runs in parallel from now and feeds the gates in §6.

## 3. The next three batches in detail

### 0.17 — The ending

0. **iOS 27 minimum (D-6).** Set the deployment target to 27.0, remove fallbacks written for iOS 26, and run the tests on an iOS 27 simulator (the current test simulator runs iOS 26.5 and can no longer host the app). Update AGENTS.md §1 and §9 in the same commit.
1. **U1 Print check with true size.** Per-model display density table, the points-per-millimetre formula, unit tests. *Check your print* after the print panel and from Print. *No* gives the specific fix and **Print Again**.
2. **U1 Finished.** Cut order drawn on the person's own page, three tips, **Done**. Shop route gets the same check.
3. **U6 Feedback map.** Haptics and numeric transitions on the stepper, chips, verdict, and unlock, through one small helper.
4. **P1 Baseline.** Add the missing signposts and record the first numbers on a device (see track P).

Done when: on the founder's iPhone and printer, a print can be checked against the screen without a ruler and the 50 mm line on screen measures 50 ± 0.5 mm.

### 0.18 — Shorter and measured

1. **U2** Remove *Choose result*; Photo Check offers the outputs. Show *Before your photo* in full once per document. **Use Photo** flows into the Photo Check landing. Add the Photo · Check · Print marker.
2. **U3** Measured lines and millimetre labels on the photo, the **Measured** chip, checks arriving one by one, the **Actual size** toggle.
3. **P2** Start analysing the captured still while the review is on screen, and cancel on Retake. Warm up Vision and Core Image when Home is idle.
4. **U15** A script that exports the gallery from the UI tests in Light and Dark.

Done when: a first-time tester goes from launch to a shared digital photo in under 90 seconds, and says unprompted that the app measured the photo.

### 0.19 — Calipic becomes the app

1. **E1** Rename the target, scheme, bundle identifier, and folders from `IDPhotoSpike` to Calipic; move the app to the repository root layout the team wants; keep git history with `git mv`.
2. Swift tests in CI on a macOS runner, if a runner with the needed SDK is available; otherwise a documented local gate.
3. Remove spike-only switches that are settled (the brand colour candidates), keeping developer details behind the long press.
4. Update [04-architecture.md](04-architecture.md) and every path in the docs.

Done when: the same tests pass under the new names and a fresh clone builds with the commands in the handoff document.

## 4. Tracks

### U — Experience and interface

Specified in [03-design.md §7](03-design.md).

| ID | Item | Effort | Version |
|---|---|---|---|
| U1 | Print check with true size on screen; Finished; cutting guide | L | 0.17 |
| U2 | Shorter path: no *Choose result*, preflight once, one review, step marker | M | 0.18 |
| U3 | Show the measuring: lines and millimetres, checks one by one, actual size | M | 0.18 |
| U4 | One continuous object: zoom transitions, the photo becomes its copies | M | 0.20 |
| U5 | The look: stage, paper in Dark, type and number roles, one shadow | M | 0.20 |
| U6 | Feedback map: haptics, symbol effects, numeric transitions | S–M | 0.17 |
| U7 | Adjust as a tool: full-height photo, dial, band on the zoom scale, swatches | L | 0.23 |
| U8 | Your sheet as a cutting mat: tap to select, pinch, copies fly in, informed paper chips | M | 0.23 |
| U9 | Home as the studio table with a Continue shelf | M | 0.21 |
| U10 | Real faces: private review set, licensed public portraits | M (people) | 0.20 |
| U11 | Camera: helper mode, find a good spot, later best frame | M–L | 0.30 |
| U12 | Credits with StoreKit views | S | 0.22 |
| U13 | Choose document: your country first, recents, size glyphs, honest "not offered" | S | 0.23 |
| U14 | Designed unhappy paths | S–M | 0.23 |
| U15 | Screenshot gallery per release | S | 0.18 |
| U16 | Final icon with dark, tinted, and layered variants; App Store screenshots | M | 0.40 |

### P — Performance and feel

Rule: **measure first, then set a budget** (AGENTS.md §14). The thresholds below are proposals to confirm after P1.

| ID | Item | Why it matters |
|---|---|---|
| P1 | **Baseline.** Add signposts for: launch to an interactive Home; shutter or import to the verdict on screen; frame time while dragging in Adjust and while the sheet rearranges. Record every signpost on the current iPhone and one older supported model, in a table in [04 §10](04-architecture.md) | Nothing can be improved or protected without numbers |
| P2 | **Start early.** Analyse the captured still during the camera review; warm up Vision and Core Image when idle after launch | The verdict can be on screen the moment the person taps Use Photo |
| P3 | **Show results as they arrive.** Frame the photo when the face is measured; add the background and each check as they complete (pairs with U3) | Waiting becomes watching |
| P4 | **Adjust at full frame rate.** Coalesce re-renders while a slider moves; render at view size while dragging and at preview size on release | A tool must never lag behind the finger |
| P5 | **Sheet.** Cache thumbnails by photo, edit, and size; draw busy pages in one pass; test six people on A4 | Thirty copies must rearrange smoothly |
| P6 | **Export.** Measure time and peak memory for six people from 48-megapixel sources at 400 ppi; render each person once; start making files right after the unlock; show progress on the button | The step after paying must feel instant and never crash |
| P7 | **Launch.** Decode the catalog off the main thread or lazily; keep Home's first frame free of image work | First impression |
| P8 | **Camera.** Smooth preview while guidance runs; behaviour when the phone gets warm; time to first frame | The best screen must stay the best |
| P9 | **App size.** Weigh the asset catalog (33 alternate icons) and trim | Download size affects installs |
| P10 | **Memory and heat** on the older iPhone across a full family session | Older phones are most of the world |

Proposed feel thresholds: any touch answers within 100 ms; anything longer than 400 ms shows what is happening in words; no animation drops frames on the older test phone; the verdict appears within about a second of Use Photo once P2 is in.

### Q — Photo quality

| ID | Item |
|---|---|
| Q1 | Calibrate the checks on the private portrait set: head-size error, background, light, sharpness. Decide which, if any, earn a hard pass or fail |
| Q2 | Hair-edge repair: tap to fix with iterative segmentation |
| Q3 | Glare on glasses and shadow advice, as warnings |
| Q4 | Digital presets tested against the real upload forms (US passport renewal, US visa, UK passport, Saudi Absher, South Korea) |
| Q5 | Blind comparison against shop photos, twice: once to guide tuning, once in beta |
| Q6 | Netherlands head size by age; other profile questions |

### E — Engineering foundations

| ID | Item | Notes |
|---|---|---|
| E1 | The spike becomes the production app | §3, 0.19 |
| E2 | **Drafts and the full export gate** (ADR-049): save source, edit recipe, document, and lock state per person; Continue on Home; delete one or all; paid photos kept until deleted, locked drafts deleted after 30 days unused (D-7); unlock bound to the recipe so a changed photo relocks; a test that lists every way out of the app and proves a locked photo cannot use it; capture protection checked on iOS 26 | The largest engineering item. Design the storage format first and write it down |
| E3 | **StoreKit** (ADR-048): three consumables; reserve on unlock, commit after the first verified file, release on failure; restore; balance mirrored in iCloud key-value storage; tests for cancel, pending, Ask to Buy, interruption, crash between reserve and commit, reinstall | No path may charge twice or lose a paid photo |
| E4 | Settings and Help complete: restore, delete all, help for photo, print, cut, and shop, legal text | |
| E5 | App Intents: "Take an ID photo", open a document; through the export gate | |
| E6 | Language review by native speakers; convert the English text to American spelling (D-8); languages after 1.0 | |
| E7 | Wave B research (needs no code; can start any time) | [06](06-markets-and-documents.md) |

### V — Evidence that needs devices and people

These cannot be done by a model alone. The founder runs them; the results go into [04 §10](04-architecture.md) and decide the gates.

| ID | Item |
|---|---|
| V1 | **Printer round:** three printers (inkjet, laser, photo) × two papers, tolerances written before measuring, the 50 mm line and one photo measured |
| V2 | **Older iPhone:** the full journey on the oldest iPhone that runs iOS 27, capture protection included |
| V3 | **Camera calibration** on front and back cameras: do the direction cues match reality |
| V4 | **Real portraits:** the private set for U10 and Q1 |
| V5 | **First-use sessions** with testers who have never seen the app, timed |
| V6 | **Shop prints** in at least one launch country |

### L — Launch

| ID | Item |
|---|---|
| L1 | Harden: privacy audit (no network, metadata, file protection, retention), 48-megapixel stress, stale-result audit, accessibility baseline check, no P0 or P1 defects |
| L2 | Beta on TestFlight with the founder's testers across Wave A countries where possible; the measures in [01 §9](01-product.md) |
| L3 | App Store: name lock, icon, screenshots, privacy answers, per-country wording that promises only supported documents, review notes explaining the free credit, phased release |

## 5. Order and dependencies

```text
0.17 ending ─▶ 0.18 shorter + measured ─▶ 0.19 production app ─▶ 0.20 look ─▶ 0.21 drafts ─▶ 0.22 StoreKit ─▶ 0.23 tools
                                                                                    │              │
V1 printers ─────────────▶ confirms U1                                              └──────┬───────┘
V4 real portraits ───────▶ needed by 0.20 and Q1                                           ▼
V2 older iPhone ─────────▶ confirms ADR-024 and track P                       0.30 quality ─▶ 0.40 world ─▶ 0.90 ─▶ 0.95 ─▶ 1.0
```

- U3 and U1 share the true-size table: build it once in 0.17.
- U9's Continue shelf needs E2.
- U12 needs E3.
- U5 should not be judged without V4.

## 6. Gates before 1.0

1. Prints measure right on every test printer (V1), or the print check reliably leads to a right print.
2. The beta measures in [01 §9](01-product.md) are met or the founder waives them one by one.
3. No way exists to take a locked photo out of the app (E2 test green).
4. No purchase path charges twice or loses work (E3 tests green).
5. Every shipped profile has its research document and review date.
6. Speed and memory are recorded on two iPhones and no P0 or P1 defect is open.

A date never ends a phase early. Scope is cut instead, in this order: Wave A size → U7 and U8 → extra paper presets → App Intents. The four pillars, the unlock warning, and the export gate are never cut.

## 7. After 1.0

1. Wave B countries, in the order of [06](06-markets-and-documents.md).
2. More languages: Japanese, German, French, Italian, Korean, Arabic.
3. The accessibility release: full VoiceOver and Voice Control journeys, layouts for accessibility text sizes.
4. Best frame from a burst; reading the printed check line with the camera.
5. Age-related profile exceptions as data.
6. Optional on-device coaching, advisory only.
