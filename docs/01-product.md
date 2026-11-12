# 01 — Product

What Calipic is, who it is for, and how we will know it is the best. The plan to get there is in [02-roadmap.md](02-roadmap.md).

## 1. Goal

> **Calipic is the #1 iPhone app, worldwide, for making ID photos at home and printing them yourself.**

People choose it because it is the easiest way to get a great photo, the result looks like it came from a studio, and the printed copies come out at the exact size the first time. They recommend it because finishing felt good and the app was beautiful to use.

## 2. Why people need it

| Today's option | What goes wrong |
|---|---|
| Photo shop, pharmacy, or booth | Costs money each time, needs a trip, repeats for every family member, and the photo is often unflattering |
| Generic photo editor | The person has to know the rules: size, head height, background, layout. Copies print at the wrong size |
| Other ID-photo apps | Wrong size after printing (the most common one-star theme), ads, surprise watermarks or subscriptions at export, cloud upload of a face, tool-heavy screens |

## 3. Four pillars

Every feature must strengthen at least one.

| Pillar | Promise | What makes it true |
|---|---|---|
| **1. Effortless** | "I didn't have to learn anything." | Guided camera, automatic framing, plain words, one main action per screen, no account |
| **2. Studio-quality result** | "It looks better than the pharmacy photo." | Live capture guidance, clean background replacement, even light, exact composition |
| **3. Exact print at home** | "The copies came out the right size, first try." | Deterministic layout, a 50 mm check line, clear print instructions, a shop route, a print check |
| **4. Delight and trust** | "That felt good, and I trust it." | A few purposeful moments, quiet craft, no ads, honest status, photos stay on the iPhone |

Correctness and privacy are not traded against the pillars. They are constraints on all four ([AGENTS.md](../AGENTS.md)).

## 4. Who it is for

1. Adults renewing an ID card, passport, or licence who want to avoid the trip and the cost.
2. Parents making photos for children, often several at once. Children use the same flow as adults.
3. People preparing visa or residence documents, often for another country, who need a digital file and prints.
4. Anyone who needs a small photo of a given size (school, club, work): **Custom size**, with no country and no official rules.

## 5. What the app does (state at spike 0.16.0)

| Area | Built | Not built yet |
|---|---|---|
| Documents | 22 official profiles as versioned data, each with sources; picker with search; first document from the iPhone's region; custom size in mm or inches with shortcuts | Recents and favourites; Wave B countries |
| Capture | Guided camera (one oval, one instruction, green when ready), spoken guidance, optional automatic capture, front and back camera, review with Retake; import from Photos without library permission | Helper mode (someone else holds the phone); "find a good spot" coaching; best frame from a burst |
| Preparation | Face finding, eye levelling, automatic crop to the profile's composition; background replacement in the profile's colour; even light and colour (Document Tone); black and white for custom sizes | Hair-edge repair; glare and shadow advice; calibration of checks on real faces |
| Photo Check | One verdict; measured checks; the document's own by-eye checks; hold to compare with the original; honest note when rules ask for an unedited photo | Showing the measurements; true-size view |
| Adjust | Drag, pinch, straighten; Move and Zoom buttons; background and light controls; framing presets for custom sizes | A more direct, tool-like editor ([03-design.md](03-design.md) Part B) |
| Outputs | Digital photo per profile preset; print sheet for up to 6 people with several sizes and copy counts; 7 papers plus custom; cut marks and a 50 mm check line; home printing; shop route; print document | Print check after printing; cutting guide; a finished moment |
| Credits | 1 free credit; 1 credit unlocks one photo for all outputs; packs of 1, 5, 10; unlock on the Print and Digital Photo screens; editing an unlocked photo relocks it | Real purchases (StoreKit); restore; balance kept across reinstalls |
| App | English, Spanish, Portuguese (Brazil); Settings with credits, app icon (33 characters), privacy, version | Drafts that survive closing the app; Help; Siri and Shortcuts |

**Not in the product:** accounts, cloud storage, ads, subscriptions, beautification or face retouching, identity-changing AI, clothing replacement, any claim that a photo will be accepted, Android, web, iPad-specific screens.

## 6. Pricing (ADR-048)

- A new person starts with **1 credit**.
- **1 credit unlocks 1 person's photo** for one document: the digital file and any number of prints and reprints.
- Everything before the first output is free: capture, retakes, checks, adjusting, building the sheet.
- After unlocking, framing and edits are final. Editing again relocks the photo, and the changed photo uses another credit.
- Packs: **1 credit USD 0.99 · 5 credits USD 3.99 · 10 credits USD 6.99.** No subscription, no ads.
- The app shows credits, not money. A price appears only on the Credits screen where a pack is bought.

## 7. The main journey

Target for a first-time user: under 90 seconds from launch to a shared digital photo, and a correct print on the first try.

1. **Home.** The document is already right for the person's country, or they choose it once.
2. **Before your photo.** Three things to get right (shown in full the first time for a document).
3. **Camera.** The oval and one instruction guide them; the shutter or the countdown takes the photo.
4. **Photo Check.** The photo settles into the official frame. One verdict. Continue, adjust, or retake.
5. **Your sheet** (print) or **Digital Photo**.
6. **Print.** Three steps that make the size come out right; unlock with a credit; print at home or at a shop.
7. **Check the print, cut, done.** *(not built)*

Other journeys to protect: a family on one sheet (2–6 people); a digital photo only for an online form; a photo imported from the library; printing at a shop; a custom size for school; coming back later to print more copies.

## 8. Honesty rules

- **Ready never means accepted.** The app says what it measured and what the person must check by eye. The office that receives the photo decides.
- **Facts, advice, by eye.** Only facts say a thing is done ("Framed to 26 × 32 mm"). Measurements that are not calibrated say "looks fine". What only a person can judge is "to check by eye".
- **Unknown stays unknown.** A rule we could not source is never guessed from another country.
- **Editing is offered on every profile** (ADR-051). Where a document's rules ask for an unedited photo, Photo Check says what Calipic changed and offers the original in one tap.
- **Privacy is behaviour.** Photos stay on the iPhone. No account, no analytics SDK, no ads.

## 9. How we measure "best"

Measured with beta testers the founder knows (10–20 people, so report counts, not percentages), then with App Store data.

| Measure | Target |
|---|---|
| First-time task success without help | ≥ 8 of 10 |
| Median time from launch to a shared digital photo, first time | ≤ 90 s |
| Photos that reach Continue without opening Adjust | ≥ 8 of 10 |
| Preferred or equal to a shop photo of the same person, judged blind | Most pairs; no skin-tone group where it loses most pairs |
| First home print at the correct size (line 50 ± 0.5 mm) | Every tester's printer, first try or after one fix from the print check |
| Ease and satisfaction (1–5) | ≥ 8 of 10 rate both 4 or 5 |
| Understands what a credit paid for | ≥ 8 of 10; nobody surprised that edits became final |
| Understands that Ready is not a guarantee | Every tester |
| Crash-free sessions in TestFlight | ≥ 99.5 % |
| App Store rating, first 90 days | ≥ 4.7 |
| Rank for "ID photo" / "passport photo" | Top 3 in one Wave A country within 6 months; #1 within 12 |
