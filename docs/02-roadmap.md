# 02 — Roadmap: from 0.20 to App Store 1.0

**Updated:** 2026-11-14, at tag `v0.20.19`.

The roadmap is ambitious on purpose, and **nothing in it is final**. If a better idea appears for how the app looks, feels, or performs, propose it, record the decision in [05-decisions.md](05-decisions.md), and change this file in the same commit.

## 1. Where we are

- The full journey works on an iPhone for 22 documents and custom sizes: guided camera, automatic framing, background and light, Photo Check, Adjust, multi-person print sheets, home and shop printing with a print check and a cutting guide, digital photo, credits with unlock in place, a guided first photo (ADR-052), three languages with a language menu.
- **Good:** the camera screen, the deterministic core (crop solver, layout solver, rules as data), the test suite (203 passing; unit tests in under a minute, `scripts/test.sh`).
- **Not good enough yet: the look.** The founder's verdict on 0.20.19: "it doesn't feel like a well designed app, it needs refinement". The audit (2026-11-14) found no system: too many text sizes and footnotes, mixed alignment, boxes inside boxes, four button styles, a small photo, a different layout per step. The fix is decided: **One table, one tray** (ADR-054, [03-design.md §9](03-design.md)), and with the founder's free hand it also makes Print one screen and removes the second review (ADR-055). It comes next, before drafts.
- **Judged by one person so far.** Nobody outside has used the app. A small group of testers now comes right after real purchases (0.24), not at 0.95.
- **Not real yet:** purchases (credits are added without payment), drafts (everything is lost when the app closes; the guide gives its credit back after a relaunch as a workaround), and all evidence that needs devices and people (print measurements, speed, real faces).

## 2. The path at a glance

| Version | Theme | What the person gets | Main items |
|---|---|---|---|
| **0.17** | The ending | A print they can check against the screen, a cutting guide, a finished moment; controls that respond to touch | U1, U6, P1 |
| **0.18** | Shorter and measured | Five screens instead of eight; the app visibly measures the photo; results appear almost at once | U2, U3, P2, U15 |
| **0.19** | Calipic becomes the app | Nothing visible: the spike becomes the production project, with Swift tests in CI | E1 |
| **0.20** | The look (stage, paper, readouts **done in 0.20.0**; transitions and real faces **done in 0.20.5**) | A recognisable Calipic: the cutting mat, real paper, one continuous photo from shutter to sheet, real faces on Home | U5, U4, U10 |
| **0.20.6–0.20.19** | First photo, guided (done) | A welcome, a guide that points at each control, one free photo, a language menu, a sheet that fills slot by slot | U17, U18 |
| **0.21** | **Refinement: one table, one tray** | An app that looks designed: the photo large on the mat, one tray, one button, the same shape from Home to Finished; four screens instead of six (Print is one screen, one review) | **U19** |
| **0.22** | Keep my work | Close the app and continue later; reprint for free; delete everything in one tap | E2, U9 |
| **0.23** | Real credits | Buying a pack works; the balance survives a reinstall | E3, U12 |
| **0.24** | **First testers** | Nothing new: five to ten people who have never seen the app use it on TestFlight, with real purchases in the sandbox; their sessions and prints decide what 0.25 fixes | V5, V1, V2, L2 (early) |
| **0.25** | Tools and what the testers found | An editor that feels like an instrument; every unhappy path designed; the testers' top problems fixed | U7, U13, U14, P4, P5 |
| **0.30** | Photo quality | Clean hair edges, glare and shadow advice, helper mode, a good-spot coach | Q1–Q4, U11 |
| **0.40** | Ready for the world | Every Wave A profile re-checked; upload presets tested against the real forms; help; Siri | Q4, Q6, E4, E5, E6 |
| **0.90** | Harden | Nothing new: speed, memory, privacy, and edge cases closed | P6–P10, L1 |
| **0.95** | Beta | Real people, real printers | L2 |
| **1.0** | Launch | Worldwide, Wave A | L3 |

Work that needs devices and people (track V) runs in parallel from now and feeds the gates in §6.

## 3. The batches in detail

### 0.21 — Refinement: one table, one tray · Next

The specification is [03-design.md §9](03-design.md): the eleven problems and their fixes, the layout, type, buttons, status, each screen, the moments that must survive and get stronger (§9.10), the decisions made with the founder's free hand (§9.11), and the acceptance check. One pass at a time, each installed on the founder's iPhone before the next.

1. **Components and Photo Check.** `JourneyScreen`, `TrayRow`, `TrayActions`, `StatusMark`, the new tokens; Photo Check rebuilt on them (photo at least 45 % of the screen, verdict as the tray title, two rows, Adjust beside Print).
2. **Print as one screen** (ADR-055) and Digital Photo. `SheetView` and `PrintView` merge: the page stays on the mat; the tray moves through layout, unlock, where, print. The first page is full by default. The unlock is one sentence and **Unlock · 1 credit**. The guide's tips and the UI tests follow. The largest pass.
3. **Home, the welcome page, "You're all set".** The mat on Home; the document as one row; credits off Home.
4. **One review.** The camera's still lands on Photo Check; the camera review is removed (ADR-045 amended).
5. **Finished and the sheets.** Check your print with a large line; the type and button rules in every sheet.
6. **Review** of the built screens against §9 (Fable 5.2), then fixes. Rewrite 03-design §1 to §3 to match what was built.

Also in this batch, because the screens are being rebuilt anyway: the two Print UI tests that fail on a 6.3-inch iPhone, and screenshots made optional in the UI tests.

Done when: every journey screen passes the check in §9.9 in Light and Dark and in three languages; all twelve moments of §9.10 work on the iPhone, the seven marked stronger included; and the founder, using it, no longer says it needs refinement.

### 0.24 — First testers

Five to ten people who have never seen the app, on TestFlight, in at least two countries of Wave A. Each one makes a photo for a real document and prints it. Watch or record the first session (V5), ask for a picture of the print next to a ruler (V1), and include one older iPhone (V2). No new features in this version: only what is needed to distribute (TestFlight setup, a feedback link in Settings). The top problems they hit go to the front of 0.25. Needs 0.22 and 0.23 first, so nobody loses a photo or meets fake purchases.

### 0.17 — The ending · Done (2026-11-12), except the device measurements

0. **iOS 27 minimum (D-6).** Set the deployment target to 27.0, remove fallbacks written for iOS 26, and run the tests on an iOS 27 simulator (the current test simulator runs iOS 26.5 and can no longer host the app). Update AGENTS.md §1 and §9 in the same commit.
1. **U1 Print check with true size.** Per-model display density table, the points-per-millimetre formula, unit tests. *Check your print* after the print panel and from Print. *No* gives the specific fix and **Print Again**.
2. **U1 Finished.** Cut order drawn on the person's own page, three tips, **Done**. Shop route gets the same check.
3. **U6 Feedback map.** Haptics and numeric transitions on the stepper, chips, verdict, and unlock, through one small helper.
4. **P1 Baseline.** Add the missing signposts and record the first numbers on a device (see track P).

Done when: on the founder's iPhone and printer, a print can be checked against the screen without a ruler and the 50 mm line on screen measures 50 ± 0.5 mm.

### 0.18 — Shorter and measured · Done (2026-11-12), except: one review instead of two, checks appearing one by one, Actual size on Photo Check

1. **U2** Remove *Choose result*; Photo Check offers the outputs. Show *Before your photo* in full once per document. **Use Photo** flows into the Photo Check landing. Add the Photo · Check · Print marker.
2. **U3** Measured lines and millimetre labels on the photo, the **Measured** chip, checks arriving one by one, the **Actual size** toggle.
3. **P2** Start analysing the captured still while the review is on screen, and cancel on Retake. Warm up Vision and Core Image when Home is idle.
4. **U15** A script that exports the gallery from the UI tests in Light and Dark.

Done when: a first-time tester goes from launch to a shared digital photo in under 90 seconds, and says unprompted that the app measured the photo.

### 0.19 — Calipic becomes the app · Done (2026-11-12)

1. **E1** Rename the target, scheme, bundle identifier, and folders from `Calipic` to Calipic; move the app to the repository root layout the team wants; keep git history with `git mv`.
2. Swift tests in CI on a macOS runner, if a runner with the needed SDK is available; otherwise a documented local gate.
3. Remove spike-only switches that are settled (the brand colour candidates), keeping developer details behind the long press.
4. Update [04-architecture.md](04-architecture.md) and every path in the docs.

Done when: the same tests pass under the new names and a fresh clone builds with the commands in the handoff document.

Result: the app is `Calipic/` (target, scheme, module, and folders renamed with `git mv`), bundle identifier `com.jarbasferro.calipic`. A Swift Testing job is in CI, but GitHub's `macos-26` image has no Xcode 27 yet, so it skips with a warning and the gate is local (`scripts/test.sh auto`); the job starts testing by itself when Xcode 27 arrives. The colour test systems A–D, their switch, and their evidence test are gone; teal is the only brand colour. The step marker keeps the word of past steps on Photo Check (founder feedback on 0.18).

## 4. Tracks

### U — Experience and interface

Specified in [03-design.md §7](03-design.md).

| ID | Item | Effort | Version |
|---|---|---|---|
| U1 | Print check with true size on screen; Finished; cutting guide | L | 0.17 |
| U2 | Shorter path: no *Choose result*, preflight once, one review, step marker | M | 0.18 |
| U3 | Show the measuring: lines and millimetres, checks one by one, actual size | M | 0.18 |
| U4 | One continuous object: zoom transitions, the photo becomes its copies (**done in 0.20.5**) | M | 0.20 |
| U5 | The look: stage, paper in Dark, type and number roles, one shadow | M | 0.20 |
| U6 | Feedback map: haptics, symbol effects, numeric transitions | S–M | 0.17 |
| U7 | Adjust as a tool: full-height photo, dial, band on the zoom scale, swatches | L | 0.25 |
| U8 | The sheet as a cutting mat: tap to select, pinch, copies fly in, informed paper chips (the layout, now part of the one Print screen, is done in U19; the rest only if testers ask) | M | after 0.25 |
| U9 | Home as the studio table with a Continue shelf (the table is done in U19; the shelf needs E2) | M | 0.22 |
| U10 | Real faces: private review set, public portraits (**Home sample and test photo done in 0.20.5**, a generated person, D-9; the varied review set is still open) | M (people) | 0.20 |
| U11 | Camera: helper mode, find a good spot, later best frame | M–L | 0.30 |
| U12 | Credits with StoreKit views | S | 0.23 |
| U13 | Choose document: your country first, recents, size glyphs, honest "not offered" | S | 0.25 |
| U14 | Designed unhappy paths | S–M | 0.25 |
| U15 | Screenshot gallery per release | S | 0.18 |
| U16 | Final icon with dark, tinted, and layered variants; App Store screenshots | M | 0.40 |
| U17 | First-photo guide: welcome, coached real flow to the print, two free credits (ADR-052) | M | **done in 0.20.14**; guide line at the action, four phases, in 0.20.15; guide bubble, clearer welcome, one starting credit in 0.20.16; guide in highlighter yellow in 0.20.17; anchored bubbles, several per screen, in 0.20.18; one free photo said up front, bubbles kept off the bottom controls, in 0.20.19 |
| U18 | Language menu in Settings (ADR-053); Spanish and Portuguese checked on screen for fit | S | **done in 0.20.19** |
| U19 | **Refinement: one table, one tray** (ADR-054, ADR-055, 03-design §9): one layout for every journey screen, three text roles, one button, one status mark, no cards or footnotes; Print as one screen; one review; first page full by default | L | 0.21 |

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
0.20 look + guide (done) ─▶ 0.21 refinement ─▶ 0.22 drafts ─▶ 0.23 StoreKit ─▶ 0.24 first testers ─▶ 0.25 tools + findings
                                                                                      │
V1 printers, V2 older iPhone, V5 first-use sessions ──▶ run inside 0.24 ◀──────────────┘
V4 real portraits ───────▶ needed by U19's review and Q1
                                                    0.25 ─▶ 0.30 quality ─▶ 0.40 world ─▶ 0.90 ─▶ 0.95 ─▶ 1.0
```

- U3 and U1 share the true-size table: build it once in 0.17.
- U19 comes before E2 so that the Continue shelf, the drafts list and the purchase screens are built once, in the new layout.
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

A date never ends a phase early. Scope is cut instead, in this order: Wave A size → U8 → U7 → extra paper presets → App Intents. The four pillars, the unlock warning, and the export gate are never cut.

## 7. After 1.0

1. Wave B countries, in the order of [06](06-markets-and-documents.md).
2. More languages: Japanese, German, French, Italian, Korean, Arabic.
3. The accessibility release: full VoiceOver and Voice Control journeys, layouts for accessibility text sizes.
4. Best frame from a burst; reading the printed check line with the camera.
5. Age-related profile exceptions as data.
6. Optional on-device coaching, advisory only.

## 8. Implementation steps and the model for each

Written 2026-11-12 for a founder with limited usage across subscriptions. The tiers follow [AGENTS.md §19](../AGENTS.md): small models only for fully specified, cheaply verified work; frontier models for judgment, cross-file state, precise math, reviews, and anything outward-facing.

**Spending rule:** Sonnet 5.5 is the default worker. Opus 5.5 plans each batch (one pass that writes the briefs) and does the cross-file and visual work. Haiku 5.5 takes mechanical steps. Fable 5.2 is kept for the two highest-stakes designs (drafts and purchases) and the design round for the look. A GPT model, on the other subscription, reviews each batch independently: a different provider catches different mistakes and uses the other quota.

| # | Step | Model | Why this model |
|---|---|---|---|
| **0.17** | | | |
| 1 | Plan 0.17: briefs for every step below, with files and acceptance checks | Opus 5.5 | Planning for other models |
| 2 | Deployment target 26.0 → 27.0, iOS 27 test simulator, AGENTS.md lines | Haiku 5.5 | Mechanical; build and tests verify it |
| 3 | True-size table (iPhone model → screen density) and points-per-millimetre formula, with tests | Opus 5.5 | Units and device data: a plausible wrong value is costly |
| 4 | *Check your print* screen and the "No" diagnosis | Opus 5.5 | New visual moment plus print logic |
| 5 | *Finished* screen and cutting guide | Sonnet 5.5 | Follows the spec in 03-design U1 |
| 6 | Feedback map: haptics and number transitions | Sonnet 5.5 | Small judgment across several screens |
| 7 | New signposts for the performance baseline | Haiku 5.5 | Pattern already in the code |
| 8 | Spanish and Portuguese for new strings | Haiku 5.5 | Translation drafts, reviewed in step 10 |
| 9 | UI tests and screenshots | Sonnet 5.5 | Test updates with some judgment |
| 10 | Review: code, wording, light and dark screenshots | GPT (other subscription) | Independent second opinion |
| 11 | Fix findings, version bump, commit, tag, push, install on the iPhone | Opus 5.5 | Outward-facing actions |
| — | Measure the baseline and the 50 mm line on the iPhone and printer | Founder | Needs the device and a ruler |
| **0.18** | | | |
| 12 | Plan 0.18 | Opus 5.5 | Planning |
| 13 | Remove *Choose result*; outputs on Photo Check; preflight once per document; step marker | Opus 5.5 | Navigation and state across several files |
| 14 | Measuring lines on the photo (U3): image space → screen → millimetres | Opus 5.5 | Coordinate spaces; the signature moment |
| 15 | Analyse during the camera review; checks appear one by one | Opus 5.5 | Concurrency and stale results |
| 16 | Gallery export script | Haiku 5.5 | Bounded script, output is checkable |
| 17 | Strings, UI tests | Haiku 5.5, then Sonnet 5.5 | As in 0.17 |
| 18 | Review, then ship | GPT, then Opus 5.5 | As in 0.17 |
| **0.19** | | | |
| 19 | Rename plan: new names, bundle ID, effect on the installed app | Opus 5.5 | Irreversible identity change |
| 20 | The rename itself (`git mv`, project settings, paths in docs) | Sonnet 5.5 | Mechanical but wide; tests verify it |
| 21 | Swift tests in CI | Sonnet 5.5 | Configuration, checkable |
| **0.20** | | | |
| 22 | Design round for the look (stage, paper, type) | Fable 5.2 | The most visible creative choice before launch; one short session (round 3 is in [explorations](ui/explorations/README.md), founder chose B) |
| 23 | Build the chosen look and the continuous-photo transitions | Sonnet 5.5, Opus 5.5 reviews the screenshots | Implementation from a chosen design |
| — | Consented private portraits for review | Founder | People, not code |
| **0.21 — refinement** | | | |
| 23a | Audit of every screen, two directions, the specification in 03-design §9 (**done 2026-11-14**) | Fable 5.2 | Taste and system; the most visible choice before launch |
| 23b | Components (`JourneyScreen`, `TrayRow`, `TrayActions`, `StatusMark`) and Photo Check | Opus 5.5 | Sets the pattern every other screen copies |
| 23c | Print as one screen: merge `SheetView` and `PrintView`, tray states, navigation, guide tips, tests | Opus 5.5 | State across files, the guide, and the export gate; the riskiest pass |
| 23c2 | One review: remove the camera review, land the still on Photo Check | Opus 5.5 | Camera, concurrency, stale results |
| 23c3 | Digital Photo, Home, welcome, Finished, the sheets: one pass each | Sonnet 5.5, from the pattern | Implementation from a written specification |
| 23d | Strings for the changed sentences (es, pt-BR); UI tests kept green | Haiku 5.5, then Sonnet 5.5 | Mechanical, verified by the tests and the copy check |
| 23e | Review of the built screens against §9, in Light and Dark | Fable 5.2, one short session | Catches the gap between the specification and the build |
| **0.22** | | | |
| 24 | Design drafts and the export gate: storage format, protection, retention (D-7), the test that proves nothing locked leaves the app | Fable 5.2 | Privacy and money; the costliest mistake in the plan |
| 25 | Build drafts and the gate from that design | Opus 5.5 | State across the whole app |
| 26 | Continue shelf on Home | Sonnet 5.5 | Screen work on top of the model |
| 27 | Security and privacy review of drafts | GPT, then Fable 5.2 on disputed findings | Two independent reviews where it matters |
| **0.23** | | | |
| 28 | Design purchases: reserve, commit, release; restore; iCloud mirror | Fable 5.2 | No double charge, no lost paid photo |
| 29 | Build StoreKit and the Credits screen | Opus 5.5 | Follows the design; many edge cases |
| — | Sandbox and TestFlight purchase tests | Founder, with Sonnet 5.5 writing the test checklist | Needs App Store Connect |
| **0.24 — first testers** | | | |
| 29a | TestFlight setup, feedback link, tester instructions and the session checklist | Sonnet 5.5 drafts, founder runs | Needs App Store Connect and people |
| 29b | Read the sessions and prints; rank the problems | Opus 5.5 | Synthesis that decides the next batch |
| **0.25** | | | |
| 30 | The testers' top problems | Opus 5.5 plans, Sonnet 5.5 builds | Evidence first |
| 31 | Adjust as a tool | Opus 5.5 | Gestures, precise geometry, feel |
| 32 | Unhappy-path screens, document picker improvements | Sonnet 5.5 | Follows existing patterns |
| **Later** | | | |
| 33 | Calibrate checks on real portraits | Opus 5.5 | Thresholds become hard checks only with evidence |
| 34 | Hair-edge repair with iterative segmentation | Opus 5.5 | Vision API, little prior art in the code |
| 35 | Wave B profile research and rule data | Opus 5.5 | Sourced rules; the validator checks the data |
| 36 | Export performance with large photos | Opus 5.5 | Profiling and memory |
| 37 | Settings, Help, App Intents | Sonnet 5.5 | Standard screens and APIs |
| 38 | App Store text and screenshots | Opus 5.5 drafts, founder approves | Public wording, honesty rules |

GPT 6 Astra and GPT 6.1 Sol are listed only as "GPT" because their relative strengths were not assessed here. Use whichever the subscription allows more of for reviews; for a review, the stronger one is worth it.
