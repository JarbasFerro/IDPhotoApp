# 05 — Decisions

The decisions that are in force, one short entry each. ADR numbers are kept because code comments and [AGENTS.md](../AGENTS.md) refer to them. The full original records (context, alternatives, evidence) are in git history: `git show v0.16.0:docs/10-decisions.md`.

**How to use this file**

- A decision here is the default. It is not a wall: the founder has said that nothing is final. To change one, write the reason and the new decision here first, then change the code.
- Add a new decision as the next ADR number with a date. Mark a replaced one as *Superseded by ADR-xxx* instead of deleting it.
- **F** = decided by the founder. Do not reverse an F decision without asking.

## Product and scope

| ADR | Decision | Status |
|---|---|---|
| 001 | Native iPhone app in Swift and SwiftUI. No Android, web, or cross-platform layer | Accepted |
| 012, 013, 014 | No backend, no account, no ads for the core workflow | Accepted |
| 016 | Spain DNI is the engineering reference profile | Accepted |
| 017 | Children use the adult flow; no child mode at 1.0. Checks that countries relax for babies warn and never block. Age exceptions can be added later as profile data | Accepted (F) |
| 018 | **Custom size without a country:** width × height in mm or inches, shortcuts, Wider/Standard/Closer framing, White or Light grey background, black and white. Photographic checks only; never a compliance claim | Accepted (F) |
| 019 | Rules ship with app updates. Remote catalog updates are deferred and would need signing and rollback | Deferred |
| 020 | No analytics or crash-reporting SDK. Success is measured with known beta testers, TestFlight, and App Store Connect | Accepted (F) |
| 022 | JPEG for digital photos; a document with exact page boxes (PDF) for print sheets | Accepted in practice |
| 024 | **Minimum iOS 27**, built with the newest SDK. No iOS 26 fallbacks: the newest Vision, SwiftUI, and segmentation APIs can be used directly | Accepted (F), 2026-11-12. Supersedes the iOS 26 proposal. The project still says 26.0 until roadmap 0.17 step 0 |
| 031 | App Intents ("Take an ID photo", open a document) are wanted for 1.0 and must go through the export gate. No face photos in Spotlight | Accepted for architecture; not built |
| 032, 042 | On-device language models may explain or coach. They never decide dimensions, crop, or pass/fail. No Private Cloud Compute for identity photos | Accepted boundary; not built |
| 047 | **Worldwide launch.** Wave A (15 countries) at 1.0, Wave B (20) in the first updates; mainland China and Russia excluded. Never offer a profile for a document closed to home photos. Details: [06](06-markets-and-documents.md) | Accepted (F) |
| 048 | **Pricing in credits.** 1 free credit for a new install, used by the first-run tutorial (ADR-052), so a person has no credit left after it; the welcome page says the guide gives one free photo and that each photo after it uses one credit; it was 2 in 0.20.14 and 0.20.15, back to 1 since 0.20.16 (F, 2026-11-14); 1 credit unlocks one person's photo for all outputs and reprints; packs 1 / 5 / 10 for USD 0.99 / 3.99 / 6.99; the app shows credits, not money; unlock happens in place on Print and Digital Photo; edits are final after unlocking and editing relocks. No subscription. The word "unlock" is accepted for this action | Accepted (F), amended 2026-11-12, 2026-11-13 and 2026-11-14 |
| 048 (integrity, not built) | Reserve the credit on unlock, commit after the first verified output, release on failure; never charge twice; balance and "free credit used" mirrored in iCloud key-value storage and reconciled with StoreKit history; spending works offline | Accepted; to build |
| 049 | **Drafts and one export gate.** Every person in progress is saved on the device (source, edit recipe, document, lock state) with complete file protection, and excluded from backups. **Retention (F, 2026-11-12):** an unlocked (paid) photo stays until the person deletes it, so reprints stay free; a locked draft is deleted after 30 days unused; Delete and Delete all are always available. Every path out of the app goes through one export service that refuses locked photos. Locked previews are display resolution only and capture-protected | Accepted (F); gate exists for print and digital files, drafts not built |
| 050 | **Accessibility is a native baseline for 1.0:** system controls and text styles, a label on every icon-only control, status never by colour alone, Reduce Motion respected, existing accessible features kept. Full VoiceOver journeys, audits as a gate, and layouts tuned for accessibility sizes come after 1.0 | Accepted (F) |
| 051 | **Editing on every profile.** Background replacement and Document Tone are offered even where official rules ask for an unedited photo; the app says so honestly and offers the original in one tap. The background is replaced only when the real wall fails the check. Official pages found through search count as sources | Accepted (F) |

## Photo and rules

| ADR | Decision | Status |
|---|---|---|
| 002 | All image processing happens on the device | Accepted |
| 003, 040 | Apple Vision for face analysis; landmark and rectangle requests pinned to revision 3 until a calibrated move to revision 4 | Accepted in practice |
| 004, 041 | Apple Vision for segmentation. Iterative segmentation (iOS 27) is the planned repair tool; when it cannot help, the fallback is edge softness, original background, or retake | Accepted in practice; repair not built |
| 006, 025 | Rules are versioned data with provenance and a last-reviewed date. Source preference: issuing authority, official delegate, adopted standard, marked secondary source | Accepted |
| 007 | Check states are `pass`, `warn`, `fail`, `manual_check`. A measurement is a hard check only after calibration for that exact rule; today every machine check is advisory | Accepted |
| 008 | The original source photo is never modified | Accepted |
| 009 | Geometry always carries its coordinate space: source pixels, normalized image, preview points, output pixels, millimetres, PDF points | Accepted |
| 010 | Official outputs are deterministic: the same inputs give the same file | Accepted |
| 011, 038 | No change to the person's identity: no retouching, reshaping, or generated content. Document Tone is one global, reversible correction of exposure and colour | Accepted |
| 026 | Print accuracy is proven by measuring real prints, not by math alone | Accepted; printer round not done |
| 027 | No private or family face photos in the repository. Fixtures are synthetic (including generated people who do not exist, D-9), licensed, or consented | Accepted |
| 036 | Print sheet: paper catalog plus custom paper; deterministic row solver; 0–1 mm adaptive safety margin, 4 mm page margin, 2 mm gutter, corner marks, 50 mm check line; zero-gutter "as many as possible" is opt-in | Accepted in practice |
| 037 | The replacement background colour comes from the profile | Accepted in practice |
| 039 | Crop solving: eye line and chin from landmarks; the crown is an estimate from the mask top and face proportions; level the eyes, scale to the head-height target, place by the eye-line and top-margin bands | Accepted in practice; calibration open |

## Engineering

| ADR | Decision | Status |
|---|---|---|
| 023 | SwiftUI with Observation (`@Observable`) and Swift Concurrency. No third-party state framework | Accepted |
| 028 | Apple frameworks first. A third-party dependency needs a written review (need, licence, privacy, size, removal plan). There are none today | Accepted |
| 029 | Standard SwiftUI controls carry the current iOS look, Liquid Glass included. No app-wide custom glass theme | Accepted; see the proposals in [03-design.md](03-design.md) Part B |
| 033 | Swift Testing for unit and integration tests; XCUITest for flows | Accepted |
| 034, 035 | AVFoundation for the guided camera, permission asked only at Take Photo; PhotosPicker for import, no library permission | Accepted |

## Experience

| ADR | Decision | Status |
|---|---|---|
| 043 | A short requirements summary before capture or import; Adjust is a native sheet. "No mandatory tutorial" is superseded by ADR-052 | Accepted; amended 2026-11-13 |
| 052 | **First-run tutorial (F, 2026-11-13).** A new install opens a welcome page, then coaches the real flow, on the real screens, with the person's real photo, until it is printed or shared. The welcome page says it is a guided first photo and shows the guide. On each screen the guide is one or more highlighter-yellow speech bubbles (since 0.20.17; system yellow `#FFCC00` / `#FFD60A` with near-black text, never amber, to stay clear of the orange warn status; used only by the guide) floating over the screen next to the control they are about, the tail on its centre, without moving anything (since 0.20.18, F: option B of round 1, because several screens have several things to do, and a line in the bottom bar hid the screen). Each bubble shows "Guide · 2 of 4" and one instruction; an explanation carries **Next** (using the control also passes it), a bubble about a button ends when it is tapped, and the control is outlined in the same yellow. Tips per screen: Home, document then Take Photo; Photo Check, the result then the output; Your sheet, paper, copies, Continue; Print, Unlock, where, then Print or Share. The filled bubble reads as a temporary layer, not part of the app (F, 2026-11-14: a plain line was easy to miss). Phases: photo (the document is confirmed by taking the photo), Photo Check, sheet, print (unlock, choose where, print or share); a digital main output has three. **Amended 2026-11-14 (F, round 1 in `docs/ui/explorations/`):** the 0.20.14 coach card at the top pushed the screen down and sat far from the button; research (NN/g, onboarding benchmarks, real apps) favoured a fixed layout with the hint at the action and about four steps. TipKit was rejected for the guide because its tips dismiss on an outside tap and are unreliable on toolbar items; it stays available for optional tips. No skip; it resumes after a relaunch, and a credit spent on a photo lost before it was printed is given back. Photo Check offers only the main output during it. It ends with "You're all set" (check your print, credits left). Existing installs never see it | Accepted (F); amended 2026-11-14 |
| 053 | **Language menu (F, 2026-11-14).** Settings has a Language menu: Same as iPhone, English, Español, Português (Brasil), each in its own words. It stores the app's own `AppleLanguages`, the same value iOS writes from Settings > Calipic > Language, and applies the next time Calipic opens (the footer says so). Switching inside a running app was not built: half the text is looked up outside SwiftUI and would stay in the old language | Accepted (F) |
| 054 | **One table, one tray (F, 2026-11-14).** Every journey screen (Home, Photo Check, Your sheet, Print, Digital Photo, Finished) has the same two parts: the cutting mat edge to edge with the photo or page large on it, and one white tray below holding everything that is read or tapped. Three text roles, left-aligned, one filled button and at most one text button, one status mark, no cards and no small grey footnotes. The full specification is [03-design.md §9](03-design.md); it supersedes the inset mat panel, the white cards, and "bottom actions sit on the screen background". The alternative, tidying today's layouts, was rejected as cleaner but not distinctive | Accepted (F); to build in 0.21 |
| 055 | **Print is one screen (2026-11-14, with the founder's free hand).** Your sheet and Print merge: the page stays large on the mat while the tray moves through layout, unlock, where to print, and print; Back steps through the states. A new sheet starts with its first page full instead of 8 copies. The journey is Home, Camera, Photo Check, Print, Finished. Credits are no longer shown on Home; the version stays there until 1.0 only (03-design §9.4, §9.7, §9.11) | Accepted (free hand); to build in 0.21 |
| 044 | Camera: one oval, one instruction about moving the **phone**, a plain white shutter, green when the live checks settle. Automatic capture (a visible three-second countdown) is **off by default since 0.20.19** (F, 2026-11-14), with its own on/off button left of the shutter ("Auto: Off" under it) and the same switch in Help; it was on by default from 0.20.7 to 0.20.18 | Accepted; amended 2026-11-14 |
| 045, 046 | After the shutter, show the real still with Retake and Use Photo. One soft bloom and one haptic at capture; no claims on the captured image before analysis **Amended 2026-11-14 (free hand):** the separate review after the shutter is removed in 0.21; the still lands on Photo Check, which is the one review, with Retake in the toolbar (primary when the eyes measured closed or the verdict is *Better to retake*) | Accepted; amended 2026-11-14 |

## Brand (from the brand decisions log)

- **Name:** Calipic. Never translated or given an article.
- **Idea:** a portrait inside a crop frame that reads as the letter C. The frame is the fixed brand element; the character inside is a slot (33 selectable app icons, default "swept").
- **Colour:** one teal. Accent `#0E6F7C` light / `#4FC3D1` dark; filled buttons `#0E6F7C` light / `#25828E` dark. Status colours are separate from the brand and never colour-only.
- **Type in the product:** system fonts with Dynamic Type. The wordmark's letterforms are a logo only.
- **Voice:** calm, direct, plain. No AI or scanning words, no "guaranteed" or "approved", no pressure to buy. Details in [03-design.md](03-design.md) §4.
- **Never:** beautification, ads, purple or multi-hue gradients, "AI" styling, Face ID or surveillance cues.
- **Still open:** final icon finish and dark/tinted variants; a layered icon for Liquid Glass; teal checked on device against real portraits.
- **English:** American spelling (color, center, gray, license), decided 2026-11-12 (F). A British variant can be added later as its own localisation.
## Decided on 2026-11-12 (founder)

The open questions left by the documentation cleanup, answered one by one.

| # | Question | Decision |
|---|---|---|
| D-1 | The *Choose result* screen | **Remove it.** Photo Check's main button goes to the document's main output; the other output is a second button (roadmap U2) |
| D-2 | Measurements on the photo | **Lines that settle:** head, eye, and chin lines with millimetre labels appear when the photo lands, then fold into a *Measured* chip that brings them back (U3). Replaces the old brand rejection of calliper drawings, because these are real numbers, not decoration |
| D-3 | Stage colour and paper in Dark | **Design round first**, then (round 3, 2026-11-12) **option B, Cutting mat**, on condition that no text sits on the grid. Built in 0.20. After the iPhone review (0.20.1): the mat is a rounded panel and no longer tints the navigation bar, the shadow is deeper, paper chips are rounded. Still to be judged with real portraits on the iPhone (U5) |
| D-4 | Controls in pull-up sheets over a full-height photo or page | **Prototype both** behind a switch, compare on the iPhone, keep the better one (U7, U8). ADR-043's "controls below" stands until then |
| D-5 | When the spike becomes the production app | **After 0.17 and 0.18**, in 0.19 (E1) |
| D-6 | Minimum iOS | **iOS 27 only** (ADR-024 above). Not the recommendation (iOS 26): simpler code and the newest APIs were preferred over reach to iPhones that have not updated |
| D-7 | Draft retention | **Paid photos kept until deleted; locked drafts 30 days unused** (ADR-049 above). Not the recommendation (30 days for all): a paid photo must never be lost |
| D-8 | British or American English | **American** |
| D-9 | Faces in the public repository | **AI-generated people who do not exist are allowed** (founder, 2026-11-13) for the Home sample and the public test photo (`test_data/sample/`). Real people's photos stay out (ADR-027); the founder's own portrait is local only |
| D-10 | Headphones and eyes | **App-level advice, not rules** (0.20.9): every official document lists "No headphones or earbuds" by eye (the camera cannot see them), and the camera review flags eyes that measure closed or turned down (eye outline height over width under 0.16 for either eye or 0.20 on average, calibrated on the founder's recording). Neither blocks. Since 0.20.10 Photo Check also warns "Around your head" when the person outline at head height is wider than 2.70 inter-eye distances (plain heads 2.22–2.63, over-ear headphones 2.74–2.85 on the founder's recordings and ten portraits). A headrest the iPhone's background removal kept (founder's car recording) could not be reproduced on the Mac, so that case is not yet calibrated |

## Open decisions for the founder

None at the moment. Add new ones here as they come up.

