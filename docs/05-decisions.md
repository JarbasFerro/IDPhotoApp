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
| 024 | **Minimum iOS 26**, built with the newest SDK; iOS 27-only features are availability-gated | Proposed; confirm after device tests on iOS 26 |
| 031 | App Intents ("Take an ID photo", open a document) are wanted for 1.0 and must go through the export gate. No face photos in Spotlight | Accepted for architecture; not built |
| 032, 042 | On-device language models may explain or coach. They never decide dimensions, crop, or pass/fail. No Private Cloud Compute for identity photos | Accepted boundary; not built |
| 047 | **Worldwide launch.** Wave A (15 countries) at 1.0, Wave B (20) in the first updates; mainland China and Russia excluded. Never offer a profile for a document closed to home photos. Details: [06](06-markets-and-documents.md) | Accepted (F) |
| 048 | **Pricing in credits.** 1 free credit; 1 credit unlocks one person's photo for all outputs and reprints; packs 1 / 5 / 10 for USD 0.99 / 3.99 / 6.99; the app shows credits, not money; unlock happens in place on Print and Digital Photo; edits are final after unlocking and editing relocks. No subscription. The word "unlock" is accepted for this action | Accepted (F), amended 2026-11-12 |
| 048 (integrity, not built) | Reserve the credit on unlock, commit after the first verified output, release on failure; never charge twice; balance and "free credit used" mirrored in iCloud key-value storage and reconciled with StoreKit history; spending works offline | Accepted; to build |
| 049 | **Drafts and one export gate.** Every person in progress is saved on the device (source, edit recipe, document, lock state) with complete file protection, excluded from backups, deleted after 30 days unused or on request. Every path out of the app goes through one export service that refuses locked photos. Locked previews are display resolution only and capture-protected | Accepted (F); gate exists for print and digital files, drafts not built |
| 050 | **Accessibility is a native baseline for 1.0:** system controls and text styles, a label on every icon-only control, status never by colour alone, Reduce Motion respected, existing accessible features kept. Full VoiceOver journeys, audits as a gate, and layouts tuned for accessibility sizes come after 1.0 | Accepted (F) |
| 051 | **Editing on every profile.** Background replacement and Document Tone are offered even where official rules ask for an unedited photo; the app says so honestly and offers the original in one tap. The background is replaced only when the real wall fails the check. Official pages found through search count as sources | Accepted (F) |

## Photo and rules

| ADR | Decision | Status |
|---|---|---|
| 002 | All image processing happens on the device | Accepted |
| 003, 040 | Apple Vision for face analysis; landmark and rectangle requests pinned to revision 3 until a calibrated move to revision 4 | Accepted in practice |
| 004, 041 | Apple Vision for segmentation. On iOS 27, iterative segmentation is the planned repair tool; iOS 26 falls back to edge softness, original background, or retake | Accepted in practice; repair not built |
| 006, 025 | Rules are versioned data with provenance and a last-reviewed date. Source preference: issuing authority, official delegate, adopted standard, marked secondary source | Accepted |
| 007 | Check states are `pass`, `warn`, `fail`, `manual_check`. A measurement is a hard check only after calibration for that exact rule; today every machine check is advisory | Accepted |
| 008 | The original source photo is never modified | Accepted |
| 009 | Geometry always carries its coordinate space: source pixels, normalized image, preview points, output pixels, millimetres, PDF points | Accepted |
| 010 | Official outputs are deterministic: the same inputs give the same file | Accepted |
| 011, 038 | No change to the person's identity: no retouching, reshaping, or generated content. Document Tone is one global, reversible correction of exposure and colour | Accepted |
| 026 | Print accuracy is proven by measuring real prints, not by math alone | Accepted; printer round not done |
| 027 | No private or family face photos in the repository. Fixtures are synthetic, licensed, or consented | Accepted |
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
| 043 | A short requirements summary before capture or import; Adjust is a native sheet; no mandatory tutorial | Accepted; flow under review ([02-roadmap.md](02-roadmap.md) U2) |
| 044 | Camera: one oval, one instruction about moving the **phone**, a plain white shutter, green when the live checks settle. Automatic capture is optional, in Help | Accepted |
| 045, 046 | After the shutter, show the real still with Retake and Use Photo. One soft bloom and one haptic at capture; no claims on the captured image before analysis | Accepted |

## Brand (from the brand decisions log)

- **Name:** Calipic. Never translated or given an article.
- **Idea:** a portrait inside a crop frame that reads as the letter C. The frame is the fixed brand element; the character inside is a slot (33 selectable app icons, default "swept").
- **Colour:** one teal. Accent `#0E6F7C` light / `#4FC3D1` dark; filled buttons `#0E6F7C` light / `#25828E` dark. Status colours are separate from the brand and never colour-only.
- **Type in the product:** system fonts with Dynamic Type. The wordmark's letterforms are a logo only.
- **Voice:** calm, direct, plain. No AI or scanning words, no "guaranteed" or "approved", no pressure to buy. Details in [03-design.md](03-design.md) §4.
- **Never:** beautification, ads, purple or multi-hue gradients, "AI" styling, Face ID or surveillance cues.
- **Still open:** final icon finish and dark/tinted variants; a layered icon for Liquid Glass; teal checked on device against real portraits; British or American English spelling (the catalog mixes both).

## Open decisions for the founder

These come from the proposals in the roadmap. Nothing here is decided.

| # | Question | Recommendation |
|---|---|---|
| O-1 | Remove the *Choose result* screen and let Photo Check offer the outputs directly? | Yes |
| O-2 | Show the measurements on the photo (lines and millimetres)? An older brand note rejected callipers as decoration; this would be functional, not decorative | Yes, as a prototype judged on device |
| O-3 | Allow a warm neutral "stage" colour behind photos instead of system grey, and a slightly dimmed paper white in Dark? | Yes, test both in one design round |
| O-4 | Put the Your sheet tray and the Adjust controls in native sheets with detents over a full-height photo or page? (ADR-043 chose controls below the photo) | Prototype behind a flag, then decide |
| O-5 | When to turn the spike into the production app (rename, bundle ID, CI for Swift tests) | After the next two UI batches; see roadmap E1 |
| O-6 | Final minimum iOS (ADR-024) | Keep iOS 26 if the device check passes |
| O-7 | Draft retention: 30 days unused (proposed default) | Keep |
| O-8 | British or American English | American for the US-first store lens |
