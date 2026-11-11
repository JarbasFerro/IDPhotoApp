# 22 — Quality and delight bar

**Status:** Active; numeric targets are **proposed** until the founder accepts them and calibration confirms they are measurable.
**Date:** 2026-11-11
**Purpose:** Turn "great quality pictures", "aesthetically pleasing", and "wow moments" into criteria a reviewer can test. Builds on [the experience constitution](brand/02-experience-constitution.md), [11 §6](11-ios-excellence-strategy.md), ADR-044 to ADR-046, and [15 §2](15-experience-plan.md).

## 1. The three bars

| Bar | Question | Owner documents |
|---|---|---|
| **Photo quality** | Does the output look like a studio ID photo and meet the profile? | This doc §2, [05](05-rules-engine.md), [spikes 03, 04, 06](spikes/) |
| **Aesthetic quality** | Does every screen feel calm, native, and beautiful? | This doc §3, [brand](brand/README.md), [16 §2](16-screen-experience-spec.md) |
| **Delight and satisfaction** | Do people feel a few clear "wow" moments and finish satisfied? | This doc §4–§6, [21](21-user-journeys.md) |

## 2. Photo quality bar

### 2.1 What a "great" Calipic photo is

1. **Correct**: head size, eye line, and margins inside the profile's bands; exact output dimensions; the right background colour.
2. **Sharp**: eyes in focus; enough source resolution for the printed size.
3. **Evenly lit**: no hard shadow across the face or on the background; no clipped highlights on the skin.
4. **Natural**: true skin tone across all skin tones; no beautification or face reshaping (ADR-011, FR-080).
5. **Clean edges**: no halo, missing hair, or background patches around the head and shoulders.
6. **Straight**: eyes level; head facing the camera.

### 2.2 Internal targets (proposed; calibrate before they become checks)

These are **app quality targets**, not official requirements. Official numbers only come from sourced profile data (AGENTS.md §11). A target becomes a Photo Check row only after calibration shows it is reliable (AGENTS.md §9); until then it is a test-suite gate.

| Property | Proposed internal target | How it is measured |
|---|---|---|
| Effective print resolution | ≥ 300 ppi at the printed size; warn below 200 ppi | Source pixels inside the crop ÷ physical size |
| Eye levelling | Residual roll ≤ 1° after automatic alignment | Landmark eye line on the rendered output |
| Head height and eye line | Inside the profile's band, centred within its middle 50 % when the source allows | Fused crown estimate (ADR-039) on the fixture corpus |
| Face exposure | < 0.1 % clipped pixels in the face region | Histogram of the face mask region ([14 §5.4](14-priority-feature-plan.md)) |
| Background uniformity | Replaced background is one flat colour; original backgrounds flagged when lightness varies visibly across zones | Four-zone background sample |
| Edge quality | Zero visible halo or hair loss in ≥ 95 % of fixture portraits at 100 % print size | Blind rubric review of printed fixtures (B6-007) |
| Skin-tone neutrality | Document Tone never shifts skin hue visibly; reviewers rate it neutral across the Monk Skin Tone range | Paired before/after review on a diverse fixture set |
| Sharpness | Eye region passes the calibrated blur threshold | Laplacian-variance or equivalent on the eye region (A5-005) |

### 2.3 The quality study (L19-007)

The strongest proof of "best app" is a blind comparison:

- **Set:** the founder's beta testers and people they recruit (aim for 20 or more), consenting adults and, where a guardian consents, children, covering the Monk Skin Tone scale, hair types (curly, afro, straight, bald, long), glasses, and religious headwear. No personal photos enter the public repository (ADR-027).
- **Pairs:** for each person, a Calipic photo taken at home by a non-expert vs. a photo-shop or booth ID photo of the same person.
- **Judges:** people who did not take the photos rate "Which would you rather have on your ID?" and "Which looks more professional?".
- **Target:** Calipic preferred or equal in most pairs; report each skin-tone group separately; a group where Calipic loses most pairs is a blocker. With a small set the result is directional; report counts, not percentages.
- **Use:** results guide tuning; only honest aggregate claims may appear in marketing (BD-026).

### 2.4 Where quality actually comes from at home

Image processing cannot fully rescue a bad setup. Order of impact, which is also the order of investment:

1. **Light**: a window in front of the face beats every filter → F-16 *Find a good spot*, live "Find more light" guidance.
2. **Camera and distance**: the back camera at a moderate distance (no wide-angle nose distortion) → F-15 helper mode; the "Bring the phone closer / farther" cue.
3. **Moment**: eyes open, neutral expression, still → review screen, optional burst (F-17).
4. **Background**: plain wall → replacement and edge refinement (F-21, F-22).
5. **Tone**: global evening (F-23), never retouching.

## 3. Aesthetic bar

### 3.1 Principles (already accepted)

The portrait is the hero; the UI outside it is extremely minimal (BD-018); one teal accent (BD-033); system typography and native Liquid Glass (BD-003, BD-005); Light and Dark are equal (BD-019); quiet completion (rule 11).

### 3.2 Screen-level aesthetic review

Every screen passes these before release, checked against named screenshots in [ui/screen-evidence.md](ui/screen-evidence.md):

| Check | Pass condition |
|---|---|
| Hero | The first thing the eye lands on is the photo, the sheet, or the one action. |
| One action | Exactly one prominent button per state. |
| Text budget | At default size, no screen in the fast path shows more than about 40 words of body copy. |
| Alignment and rhythm | Spacing comes from `DesignTokens.swift` and native layout; no ad hoc offsets. |
| Real photo legibility | Text and controls stay readable over real photos in bright, dim, and backlit scenes. |
| Both appearances | Light and Dark screenshots reviewed side by side; nothing looks like an afterthought in either. |
| Large text | Default and larger standard sizes reflow without clipping; the portrait keeps its true aspect. Accessibility sizes after 1.0 (ADR-050). |
| Apple side-by-side | Placed next to a comparable Apple app screen (Camera, Wallet, Photos edit), it looks like it belongs. |

### 3.3 Known aesthetic gaps in 0.12.x (from current screenshots)

| Screen | Gap | Proposed direction |
|---|---|---|
| Home, fresh install | Text-led; nothing photographic; the screen does not show what the person will get. | Show a small sample result in the 26:32 frame (illustrated brand bust or a licensed model photo) above the actions; replace with the person's own last result once a session exists. |
| Home footer | The trust lines, App Icon row, and version compete with the actions. | Move App Icon into Settings & About (S-19); keep one trust line; keep the version as the last tertiary line (AGENTS.md §17). |
| Photo Check | Rows are dense at default size; the status headline and rows have equal visual weight. | Headline larger; rows collapse to one line with details on tap when everything passes. |
| Your sheet | Reads like a settings list below the preview. | Larger page preview with the paper shadow; people as a row of circles (as in doc 15 §3); options under one disclosure. |
| Print & Share | Two cards of similar weight. | Make the action the person chose (Print) dominant; the digital photos card secondary. |
| Synthetic fixture | Screenshots use colour-block fixtures, which hide real-photo problems. | Add a licensed, consented portrait fixture set for screenshot and App Store capture (ADR-027). |

## 4. The wow-moment map

A wow moment here is a **visible cause-and-effect that makes the person feel the app did something hard for them**. Calm, never confetti ([11 §6](11-ios-excellence-strategy.md), rule 11). Every moment must work under Reduce Motion (an instant state change or a fade) and must never block an action.

| ID | Moment | Where | What the person perceives | Status | Acceptance |
|---|---|---|---|---|---|
| W1 | **Calm start** | Home | A beautiful, quiet screen that shows the result they will get; no account, no permission prompt. | Partial (needs the fresh-install visual) | First-time testers describe it as "simple" or "clean" unprompted. |
| W2 | **It found me** | Camera | The oval follows the instruction; it turns green and settles with one haptic when ready. | Shipped (spike) | Guidance never flickers (hysteresis); ready appears within 2 s of correct positioning on a physical phone. |
| W3 | **The landing** — the signature moment | Photo Check | The ordinary photo springs into the official frame, the room behind fades to the profile's background colour, and the light evens out. For profiles whose rules forbid alteration ([25 §4](25-wave-a-document-types.md)), only the framing lands; the photo itself is untouched. | Shipped (spike) | Starts within 1 s of Use Photo on the oldest supported iPhone; no layout jump; testers mention the transformation unprompted. |
| W4 | **Hold to compare** | Photo Check, Adjust | Press and hold shows the original; release shows the improvement. | Shipped (spike) | Discovered by ≥ 50 % of testers via the caption or a single tip. |
| W5 | **The sheet fills** | Your sheet | Copies glide into place; adding a person re-flows the page. | Shipped (spike) | Animation keyed by person and copy; no fade-swap; 60/120 fps on device. |
| W6 | **Your files are ready** | Print & Share, Digital Photo | One quiet tick and a success haptic, only after files are verified. | Shipped (spike) | Never shown before verification passes. |
| W7 | **It came out right** | Print check (New) | After printing, confirming the 50 mm bar ends with *Your photos are the right size*. | New (L19-003) | Bar 50 ± 0.5 mm on every test printer ([20 §7](20-product-blueprint.md)); the No path fixes the cause in one reprint. |
| W8 | **Finished** | Cutting guide (New) → Home | The cut guide matches the person's own sheet; Done leaves them with a calm summary. | New (L19-004) | Testers cut a sheet correctly on the first attempt. |

**Invisible wows** (felt, not seen; they need performance budgets, not animation): the camera opens instantly (273 ms measured on iPhone 15 Pro Max; budget to be set on an older device), the shutter never lags, nothing asks for an account, nothing is uploaded, and there are no ads.

**Rejected as wow** (keep them out): confetti, custom earcons, "biometric verified" badges, segmentation glows on the face, countdown pressure, gamified streaks ([ADR-046](10-decisions.md), [11 §7](11-ios-excellence-strategy.md)).

## 5. Satisfaction killers to design out

| Killer | Rule |
|---|---|
| Paying after the work is done, or a surprise watermark | Price known before capture; editing free; the credit is spent only at the first output, after a confirmation that shows the price and says edits become final; reprints free; never a watermark on outputs (ADR-048, FR-098). |
| Wrong print size | Calibration bar, Actual Size instruction, bordered-paper preference, print check (F-45, F-47). |
| A warning without a fix | Every warn/fail row ends with a feasible action (rule 8). |
| Losing work | Edits survive Back, purchase cancellation, retake of another person, and app restarts (drafts, ADR-049). |
| Regret after paying | The point of no return is stated before the credit is spent and again before **Edit photo** on an unlocked person (ADR-048 §4–5). |
| A review prompt or upsell after success | Never on the same screen as W6–W8; a rating request only on a later, calm Home visit after a confirmed good print (L19-009). |
| Jargon | No pixels, DPI, mask, segmentation, ICAO, or bleed in the fast path ([15 §2](15-experience-plan.md)). |
| Rejection by the office | Narrow, sourced claims; manual checks always visible; never "guaranteed". |

## 6. Measuring satisfaction

| Instrument | When | Target (proposed) |
|---|---|---|
| Observed first-use session with the founder's beta testers, 8–12 per round, including people who have never seen the app (ADR-020) | Before each beta round and before launch | ≥ 8 of 10 complete unaided; SEQ median ≥ 6/7 |
| Short questionnaire after the session: ease and satisfaction (1–5), what a credit bought, what *Ready* means | Same session | ≥ 8 of 10 rate 4–5 and explain the credit correctly; every tester understands *Ready* is not a guarantee |
| "Which moment did you like most?" (open question after the task) | Same session | W3 or W7 named most often; nobody names a frustration as their strongest memory |
| Physical print round | Each print-related change | Bar 50 ± 0.5 mm on every test printer at Actual Size |
| Crash-free sessions | Beta (TestFlight, Xcode Organizer) | ≥ 99.5 % |
| TestFlight feedback prompt (opt-in, in Settings, never in the task) | Beta | Qualitative themes tracked |
| App Store rating and reviews | Post-launch | ≥ 4.7; one-star themes reviewed weekly for the first 90 days |
| Rating request policy | Post-launch | Shown at most once per version via `RequestReviewAction`, only on a later Home visit after the person has confirmed a correct print or shared a digital photo |

## 7. Review gate

A feature that touches capture, Photo Check, outputs, or Home is ready for release when it:

1. meets its rows in §2.2 (photo quality) on the fixture corpus;
2. passes §3.2 (aesthetic review) with named screenshots in Light and Dark (accessibility text sizes after 1.0, ADR-050);
3. keeps or improves its wow moment in §4, with Reduce Motion verified;
4. introduces none of the killers in §5.
