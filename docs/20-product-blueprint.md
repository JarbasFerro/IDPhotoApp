# 20 — Product blueprint: functions, screens, and launch scope

**Status:** Active. Start here. This is the single overview of what Calipic does at launch and where each part is specified.
**Date:** 2026-11-11
**State reviewed:** spike app 0.12.7 (95 commits), ADR-001 to ADR-046, BD-001 to BD-039, docs 01–19.
**Companion documents:** [user journeys](21-user-journeys.md), [quality and delight bar](22-quality-and-delight-bar.md), [launch roadmap](23-launch-roadmap.md).
**Founder decisions:** 2026-11-11, recorded in ADR-017, ADR-020, and ADR-047 to ADR-050 (§8). External reviews and what was adopted from them: §10.

This document does not replace the detailed specifications. It indexes them, resolves which one is current, and fills the gaps that block a launch plan: launch screens that were never specified, the business model, and the measures of "best app".

## 1. Goal

> **Calipic is the #1 iPhone app, worldwide, for making ID photos at home and printing them yourself.**

People pick it because it is the easiest way to get a great photo, the result looks like it came from a studio, and the printed copies come out at the exact size the first time. They come back and recommend it because finishing felt good and the app was beautiful to use.

"#1" is measured, not claimed. See §7.

## 2. The winning thesis

Most people who need an ID photo today choose between three imperfect options:

| Option | What goes wrong |
|---|---|
| Photo shop, pharmacy, or booth | Costs money each time, needs a trip, and repeats for every family member. The photo is often unflattering and taken in a hurry. |
| Generic photo editor | The person has to know the rules: dimensions, head size, background, layout. Copies on the sheet come out at the wrong size. |
| Existing ID-photo apps | The competitor scan in [doc 14 §5](14-priority-feature-plan.md) found these recurring complaints: wrong physical size after printing (the most common one-star theme), no 4 × 6 JPEG for retail printing, ads, surprise watermarks or subscriptions at export, cloud upload of a face photo, and generic tool-heavy interfaces. |

Calipic wins on four pillars. Every feature must strengthen at least one of them.

| Pillar | Promise to the person | What makes it true | Evidence that it is true |
|---|---|---|---|
| **1. Effortless** | "I didn't have to learn anything." | Guided camera, automatic framing, plain language, one action per screen, no account. | Launch-to-outcome time; percentage of photos that need no Adjust ([22 §5](22-quality-and-delight-bar.md)). |
| **2. Studio-quality result** | "It looks better than the pharmacy photo." | Live capture guidance, best-frame choice, background replacement with clean hair edges, Document Tone, exact composition. | Blind comparison against shop photos; edge-defect rate ([22 §2](22-quality-and-delight-bar.md)). |
| **3. Exact print at home** | "The copies came out the right size, first try." | Deterministic layout solver, calibration bar, AirPrint paper handling, a lab-ready JPEG, a print check, and cutting help. | Physical measurement across printers; first-print success rate. |
| **4. Delight and trust** | "That felt good, and I trust it." | A few purposeful wow moments, quiet craft, no ads, honest status, privacy on device. | Post-task ease and satisfaction scores; App Store rating; refund and support rate. |

Correctness and privacy are not pillars to trade off. They are constraints on all four ([AGENTS.md](../AGENTS.md)). Accessibility for 1.0 is the native baseline in ADR-050; BD-034 stands as written.

## 3. Who it is for

From [BD-016](brand/99-brand-decisions-log.md) and the [founder answers](brand/00-discovery-answers.md):

1. **People avoiding the cost and trip to a photo shop**: adults renewing a DNI, passport, or licence.
2. **Parents** making photos for children, often for the whole family at once. Children use the same flow as adults, ideally with helper mode (ADR-017).
3. **People preparing visa or residence documents**, often for another country and in a second language, who need a digital file and prints.
4. **People in any App Store country**: the launch catalog covers the most-used documents of the most relevant countries (ADR-047); elsewhere, generic and custom sizes.

Assistive-technology users are a post-launch audience (ADR-050); the 1.0 baseline still applies.

Personas and their step-by-step journeys are in [21-user-journeys.md](21-user-journeys.md).

## 4. Function inventory

Status key: **Shipped (spike)** = working in `Spikes/IDPhotoSpike` 0.12.7, still pending physical-device or production evidence where noted. **Partial** = exists but short of the launch contract. **Launch** = required for 1.0, not built. **Post-launch** = planned after 1.0. **Decision** = blocked on an open decision in §8.

### 4.1 Document profiles and requirements

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-01 | Current profile: Spain · DNI photo, 26 × 32 mm, white background | Correct format without research | Shipped (spike); copy is literal UI text | [13](13-spain-foto-carnet.md), [16 §3](16-screen-experience-spec.md) |
| F-02 | Versioned, sourced profile catalog with review dates | Rules stay current and traceable | Launch | [05](05-rules-engine.md), FR-110–FR-116, R7-001–R7-018 |
| F-03 | Country and document picker with search, recents, and favourites | Find "my" document in seconds | Launch (picker); recents and favourites Post-launch | [04 §Screen 2](04-ux-ui.md), FR-010–FR-016, U10-002, U10-013 |
| F-04 | Worldwide launch catalog: most-used photo documents of the most relevant App Store countries, Wave A at 1.0 | Serve people wherever they are | Launch; country list proposed in [24](24-launch-country-ranking.md), **Decision D-8** | [ADR-047](10-decisions.md), L19-010, L19-013 |
| F-05 | Short requirements preflight before every capture or import | Avoid an unusable photo before it is taken | Shipped (spike) | [16 §7](16-screen-experience-spec.md), ADR-043 |
| F-06 | Full requirements with source link and review date | Trust and exceptions (glasses, headwear) | Shipped (spike); must move to profile data | [16 §4](16-screen-experience-spec.md) |
| F-07 | Per-profile alteration policy (background replacement and tone allowed or not) | Never sell an output the office cannot use | Partial: policy gate exists, policy data missing | ADR-037, ADR-038, FR-151, R7-016 |
| F-08 | Children use the adult flow with helper mode; baby relaxations never block, only warn | Parents' main job | Accepted for 1.0; age relaxations as profile data Post-launch | ADR-017, [14 §5.6](14-priority-feature-plan.md) |
| F-09 | Custom size, clearly marked unofficial | Useful in countries without a profile | **Decision D-8** (recommended) | ADR-018, ADR-047 §5 |

### 4.2 Capture and import

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-10 | Guided camera: one oval, one phone-movement instruction, green when ready | Gets a good source photo without knowing the rules | Shipped (spike); physical calibration pending | [16 §6](16-screen-experience-spec.md), ADR-044 |
| F-11 | Spoken guidance and VoiceOver shutter summary | Capture without seeing the screen | Shipped (spike) | C9-004, ADR-030 |
| F-12 | Optional automatic capture, 3-2-1 countdown | Hands-free selfie | Shipped (spike) | ADR-045 |
| F-13 | Shutter bloom, haptic, and captured-photo review (Retake / Use Photo) | Confidence at the decisive moment | Shipped (spike) | ADR-045, ADR-046 |
| F-14 | Front and back camera switch | Better quality with the back camera | Shipped (spike) | ADR-034 |
| F-15 | **Helper mode**: someone else holds the phone; guidance addresses the photographer, using the back camera | Best-quality path at home; essential for children | Launch (new) | [21 J3](21-user-journeys.md), L19-001 |
| F-16 | **Find a good spot** coaching: window light, plain wall, distance from the wall | The biggest quality factor at home is setup | Launch (new) | [21 J1](21-user-journeys.md), L19-002 |
| F-17 | Best-frame selection from a short burst | Eyes open and sharp without retakes | Post-launch | [14 §5.7](14-priority-feature-plan.md), L19-011 |
| F-18 | PhotosPicker import with no broad library permission | Use an existing photo | Shipped (spike) | ADR-035, FR-030–FR-035 |

### 4.3 Automatic preparation and checks

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-20 | Face detection, crown estimate, eye levelling, automatic crop | Correct head size and position, no manual cropping | Shipped (spike); calibration pending | ADR-039, ADR-040, [spike 03](spikes/03-face-alignment.md) |
| F-21 | Background separation and replacement with the profile colour | Studio background at home | Shipped (spike), white only; profile colours are P0 for worldwide | ADR-037, [spike 04](spikes/04-background-replacement.md) |
| F-22 | Hair-edge refinement (iOS 27 tap-to-fix, with an iOS 26 fallback) | Clean edges in difficult cases | Launch (P1) | ADR-041, B6-005, B6-006 |
| F-23 | Document Tone: global exposure and white-balance correction | Even, natural light without retouching | Shipped (spike) | ADR-038, [spike 06](spikes/06-document-tone.md) |
| F-24 | Photo Check: one headline and up to five plain-language rows (pass / warn / fail / manual check) | Know what is wrong and how to fix it | Shipped (spike) | [16 §8](16-screen-experience-spec.md), ADR-007 |
| F-25 | Hold to compare with the original | See the improvement; trust the edit | Shipped (spike) | [16 §8](16-screen-experience-spec.md) |
| F-26 | Landing transition: the source settles into the official frame and the background fades to white | The signature "it did it for me" moment | Shipped (spike) | [22 §4 W3](22-quality-and-delight-bar.md) |

### 4.4 Adjust

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-30 | Drag, pinch, and straighten within the exact frame | Fix the framing directly | Shipped (spike) | [16 §9](16-screen-experience-spec.md) |
| F-31 | Labelled Move/Zoom buttons and accessible sliders | Equal function without gestures | Shipped (spike) | ADR-030, FR-075 |
| F-32 | Auto/Reset, Compare, Background Original/White, Light and colour | Undo any automatic decision | Shipped (spike) | [16 §9](16-screen-experience-spec.md) |

### 4.5 Outputs

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-40 | Digital Photo: one verified JPEG for the checked person | Upload online without a print setup | Shipped (spike) at 520 × 640 px app preset | ADR-043, [16 §11](16-screen-experience-spec.md) |
| F-41 | Per-profile digital submission presets (pixel and file-size limits) | Passes online-form validation | Launch for launch profiles | R7-018, X11-004, [14 §5.5](14-priority-feature-plan.md) |
| F-42 | Print sheet: up to 6 people, several sizes each, per-size copy counts | One sheet for the whole family | Shipped (spike) | ADR-036, FR-140–FR-148 |
| F-43 | Paper catalog (4 × 6 in, 13 × 18, 9 × 13, A6, A5, A4, Letter) and custom paper | Use the paper you have | Shipped (spike) | [spike 02](spikes/02-print-composer.md) |
| F-44 | Automatic layout with adaptive bleed, corner cut marks, 50 mm check bar, multi-page overflow | Most copies per sheet; easy cutting | Shipped (spike) | [14 §3.2](14-priority-feature-plan.md) |
| F-45 | AirPrint with bordered-paper preference and an "Actual Size" instruction | The home printer does not rescale | Shipped (spike); printer evidence pending | P12-010, ADR-026 |
| F-46 | Lab-ready sheet JPEG at 300 ppi and PDF via Share | Print at a shop or kiosk instead | Shipped (spike); shop instructions missing | P12-009, L19-005 |
| F-47 | **Print check**: after printing, confirm the 50 mm bar and get the specific fix if it is wrong | Turns the #1 complaint into a moment of confidence | Launch (new) | [21 J1](21-user-journeys.md), L19-003 |
| F-48 | **Cutting guide**: short visual help for scissors or a trimmer | Neat copies; finishing the real job | Launch (new) | L19-004 |

### 4.6 Session, business, and app

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-50 | Session: people, edits, and sheet kept while the app runs | Come back to print more copies | Shipped (spike) in memory; replaced by F-60 | ADR-049 |
| F-51 | **Pricing**: first photo free (one free credit), then USD 0.99 per photo; no subscription, no ads | Fair, transparent price | Launch | BD-029, [ADR-048](10-decisions.md), L19-006 |
| F-52 | Restore purchases; keep the balance and the used free credit across reinstalls and devices | Trust and App Review compliance | Launch; design spike first | ADR-048 §7, AS18-006, L19-006 |
| F-59 | **Unlock confirmation** (point of no return): photo, open warnings, cost or total, "edits become final; printing again is free" | Edit freely, pay once, no surprise | Launch | ADR-048 §4, L19-006 |
| F-60 | **Drafts**: every person and sheet saved automatically; Continue on Home; Delete and Delete all; 30-day retention | Finish later, add family, reprint free | Launch | ADR-049, L19-012 |
| F-61 | **Export gate**: one service for every output path; a locked photo never leaves the app | No bypass of the credit | Launch | ADR-049 §3, L19-012 |
| F-53 | Settings and About: privacy explanation, App Icon, restore, help, version, legal | Durable needs in one place | Partial: App Icon and version on Home | U10-012, FR-003 |
| F-54 | Help: taking a good photo at home, printing, cutting, using a shop | Self-service support | Launch | L19-002, L19-004, L19-005 |
| F-55 | Choose your app icon (33 characters) | Personal delight outside the task | Shipped (spike) | BD-038 |
| F-56 | App Intents and App Shortcut "Take an ID photo"; Spotlight for profiles | Start from Siri or the Action button | Launch (P1) | ADR-031, AI13-001–AI13-005 |
| F-57 | Localization: English for Wave A (D-7); Spanish and Portuguese (Brazil) exist in the spike | Effortless in your language | English Launch; es and pt-BR **Decision D-12** | BD-031, ADR-047 |
| F-58 | Rating request at a calm moment after a confirmed good print, never in the task | Ratings drive the App Store rank behind "#1" | Launch | L19-009, [22 §6](22-quality-and-delight-bar.md) |

### 4.7 Not in the product

Unchanged from [01 §8.3](01-product-definition.md) and [11 §7](11-ios-excellence-strategy.md): accounts, cloud storage, ads, beautification, identity-changing AI, clothing replacement, guaranteed-acceptance claims, widgets and Live Activities without a task need, Android, web, and iPad-specific UI.

## 5. Screen catalog at launch

"Spike" means the screen exists and its current contract is in [doc 16](16-screen-experience-spec.md). "New" means it needs a screen contract in doc 16 before implementation, using the doc 16 template (composition, states, copy inventory, accessibility).

| # | Screen | Purpose | Status | Contract |
|---|---|---|---|---|
| S-01 | Home | Start a photo; **Continue** drafts; see the profile and trust promise | Spike; needs the profile chooser entry, Continue (drafts), and a fresh-install visual ([22 §3](22-quality-and-delight-bar.md)) | 16 §3 |
| S-02 | Choose document (profile picker) | Pick country and document; search; recents | **New** | 04 Screen 2 → 16 |
| S-03 | Photo requirements | Sourced rules, exceptions, review date | Spike | 16 §4 |
| S-04 | Before your photo (preflight), including *Find a good spot* and *Who is taking the photo?* (self / helper) | Set up for success | Spike; setup coaching and helper choice **New** | 16 §7 |
| S-05 | Guided camera | Capture with live guidance | Spike; helper-mode wording **New** | 16 §6 |
| S-06 | Camera Help | Capture tips; automatic capture | Spike | 16 §5 |
| S-07 | Captured photo review | Retake or Use Photo | Spike | 16 §6.1 |
| S-08 | PhotosPicker | System import | System | 16 §7 |
| S-09 | Photo Check | Prepared portrait, landing, checks, compare | Spike | 16 §8 |
| S-10 | Adjust (sheet) | Correct framing, background, light | Spike; refinement entry **New** | 16 §9 |
| S-11 | Fix the edges (refinement) | Tap to fix hair or shoulder edges | **New** (P1) | 16 §15 |
| S-12 | Choose result | Digital Photo or Print Sheet | Spike | 16 §11 |
| S-13 | Digital Photo | Verified JPEG and share | Spike; per-profile preset **New** | 16 §11 |
| S-14 | Your sheet | People, sizes, copies, paper, cutting options | Spike | 16 §10 |
| S-15 | Print & Share | Print, PDF, page JPEGs, digital photos | Spike; shop path **New** | 16 §11 |
| S-16 | Print check | Did the bar measure 50 mm? Fixes if not | **New** | — |
| S-17 | Cutting guide | How to cut neatly | **New** | — |
| S-18 | Unlock confirmation and credits | Point of no return before the first output; balance, buy, restore | **New** | ADR-048 → 16 |
| S-19 | Settings & About | Privacy, help, icon, credits and restore, Delete all drafts, version, legal | **New** (App Icon row moves here; the version also stays on Home per AGENTS.md §17) | 04 → 16 |
| S-20 | Help topics | Home setup, printing, cutting, shop printing | **New** | — |
| S-21 | App Icon | Choose the Home Screen icon | Spike | 16 §12 |
| — | System surfaces | Share sheet, print controller, StoreKit purchase sheet, permission alerts | System | 16 §13 |

There is deliberately no onboarding carousel ([constitution rule 1](brand/02-experience-constitution.md)). BD-029's "tutorial result free" is satisfied by making the first photo free, not by adding a tutorial screen. See ADR-048.

## 6. App map at launch

```text
Home ─┬─ Continue: drafts and unlocked photos (ADR-049)
      ├─ Choose document ── Requirements
      ├─ Settings & About ─┬─ Help topics (home setup · printing · cutting · shop)
      │                    ├─ App Icon
      │                    ├─ Credits: balance · buy · restore
      │                    └─ Delete all drafts
      └─ Take Photo / Choose Photo
            │
            ▼
      Before your photo (setup tips · self or helper)
            │
      ┌─────┴──────┐
   Guided camera   PhotosPicker
   └ Review ───────┘
            ▼
      Photo Check ── Adjust ── Fix the edges          free, saved as a draft
            ▼
      Choose result
      ├─ Digital Photo ── [Unlock] ── Share JPEG
      └─ Your sheet ── [Unlock everyone still locked] ── Print & Share ── Print check ── Cutting guide

[Unlock] = confirmation at the point of no return (S-18): price or total, edits become final, reprints free.
It appears only for people not yet unlocked; reprinting an unlocked photo goes straight through.
```

Navigation remains one `NavigationStack`, system sheets for contained choices, and no tab bar ([16 §2.1](16-screen-experience-spec.md)).

## 7. Success measures and launch targets

Measurement follows the founder's decision (ADR-020): no analytics SDK and no in-app telemetry. Before launch, numbers come from beta testers the founder knows, observed using the app for the first time, plus TestFlight feedback and printed sheets. After launch, they come from App Store Connect and Xcode Organizer.

Known testers tend to be kind. So measure what they **do** (time, retakes, the measured print) more than what they say. Include people who have never seen the app, and spread testers across skin tones, hair types, glasses, ages (children included), phones, and printers. With 10–20 testers the results are directional, not statistics: report counts ("8 of 10"), not percentages.

| Measure | Why it matters for "#1" | Proposed target (beta round) | Source |
|---|---|---|---|
| First-time task success, unaided: launch → printed or shared photo | Ease | ≥ 8 of 10 testers | Observed session |
| Median time from launch to a shared digital photo, first time | Ease | ≤ 90 s (60 s stretch) | Observed session |
| Photos that reach Continue without opening Adjust | Automation quality | ≥ 8 of 10 | Session notes, fixture runs |
| Preference against a shop or booth photo of the same person, judged by other testers who don't know which is which | Studio quality | Calipic preferred or equal in most pairs; no skin-tone group where it loses most pairs | Quality study L19-007 |
| First home print at the correct size (bar 50 mm ± 0.5 mm) | Exact print | Every tester's printer, first try or after one Print check fix | Testers' own printers + the P1 printer round |
| Ease and satisfaction (1–5 each) | Satisfaction | ≥ 8 of 10 rate both 4 or 5 | Questionnaire |
| Understands what was paid for, after the unlock confirmation | Fair pricing | ≥ 8 of 10 explain it correctly; nobody surprised that edits became final | Questionnaire |
| Understands that *Ready* is not a guarantee of acceptance | Trust | Every tester; one misunderstanding means a copy fix and a retest | Questionnaire |
| Crash-free sessions | Reliability | ≥ 99.5 % in TestFlight | TestFlight, Xcode Organizer |
| App Store rating, first 90 days | Rank and trust | ≥ 4.7 | App Store Connect |
| Refund requests and support contacts per 100 purchases | Honest pricing | Tracked; target set after beta | App Store Connect, support inbox |
| Category rank for "ID photo" / "passport photo" | Literal "#1" | Top 3 in at least one Tier 1 country within 6 months; #1 within 12 | App Store, ASO tools |

## 8. Decisions

### 8.1 Taken by the founder on 2026-11-11

| ID | Decision | Outcome | Record |
|---|---|---|---|
| D-1 | Launch market and profiles | **Worldwide.** The most-used photo documents of the most relevant App Store countries, in tiers. Tier 1 ships at 1.0, and each profile still passes the [01 §15](01-product-definition.md) gate. | ADR-047 |
| D-2 | Pricing | **First photo free (one free credit), then USD 0.99 per photo.** Editing is free until the unlock confirmation (point of no return). Reprints of an unlocked photo are free. | ADR-048 |
| D-3 | Children | **Same flow as adults.** Helper mode is recommended; baby relaxations only warn; baby support is not advertised. | ADR-017 |
| D-4 | Persistence | **Drafts** saved without spending credits. A locked draft can never leave the app (one export gate). 30-day retention is the proposed default. | ADR-049 |
| D-5 | Measurement | **Beta testers the founder knows.** TestFlight and observed sessions; no analytics SDK. | ADR-020 |
| D-6 | Accessibility | **Not a priority for 1.0.** A native baseline is kept, and BD-034 stands. | ADR-050 |
| D-7 | Languages | **Wave A launches with English only.** No new languages for Wave A. | ADR-047, [25 §6](25-wave-a-document-types.md) |
| D-8 | Launch countries | **35 countries confirmed:** Wave A (15) at 1.0, Wave B (20) after ([24](24-launch-country-ranking.md)). | ADR-047 |
| D-9 | Locked-preview protection | **Block screenshots and screen recording of locked previews** (as banking apps do). Device spike first, with a public-API fallback; no watermark. | ADR-049 |

### 8.2 Still open

| ID | Decision | Why it matters | Recommendation |
|---|---|---|---|
| D-10 | China mainland | 25 % of the world's iPhone users, but a paid app needs an ICP filing that a foreign developer generally cannot get without a Chinese partner, and possibly a commercial licence | **Exclude the mainland China storefront** at 1.0 and in Wave B; revisit only with a Chinese partner and legal advice ([25 §5](25-wave-a-document-types.md)) |
| D-11 | Wave A profiles and custom size | Sets the P3 research load | Research the 13 profiles in [25 §3](25-wave-a-document-types.md) first, then verify the P2 list; ship the custom size (ADR-018) |
| D-12 | Spanish and Portuguese (Brazil) in 1.0 | Already translated in the spike, but every new string then needs two translations and native review | Keep them if their markets (Spain, Mexico, Brazil) matter at launch; otherwise ship English only and add them with Wave B |

## 9. Documentation map and source of truth

When documents disagree, the order is: accepted ADRs and brand decisions → [AGENTS.md](../AGENTS.md) → this blueprint for scope → doc 16 for current screen behavior → older planning docs.

| Need | Read |
|---|---|
| What the app is and does at launch | **This document** |
| Who uses it and how, step by step | [21 — User journeys](21-user-journeys.md) |
| What "great photo", "beautiful", and "wow" mean, and how they are tested | [22 — Quality and delight bar](22-quality-and-delight-bar.md) |
| What happens next until launch | [23 — Launch roadmap](23-launch-roadmap.md) |
| Which countries, and why | [24 — Launch country ranking](24-launch-country-ranking.md) |
| Which documents per country; China | [25 — Wave A document types](25-wave-a-document-types.md) |
| Product principles, MVP rationale, risks | [01](01-product-definition.md) |
| Functional requirements (FR-xxx) | [02](02-requirements.md) |
| Architecture | [03](03-architecture.md) |
| UX principles; future screens (picker, editor) | [04](04-ux-ui.md) |
| Rules engine and profile schema | [05](05-rules-engine.md), [13](13-spain-foto-carnet.md) |
| Milestones M0–M8 and gates | [06](06-delivery-plan.md) |
| Tests, privacy | [07](07-test-strategy.md), [08](08-privacy-security.md) |
| Backlog | [09](09-backlog.md) |
| Decisions | [10](10-decisions.md), [brand log](brand/99-brand-decisions-log.md) |
| Platform capability map | [11](11-ios-excellence-strategy.md) |
| Feature research: print, alignment, background, tone | [14](14-priority-feature-plan.md), [spikes](spikes/) |
| Current screen contract | [16](16-screen-experience-spec.md), [screen states](ui/screen-states.md), [evidence](ui/screen-evidence.md) |
| Brand, voice, tokens | [brand/](brand/README.md) |
| External reviews of 2026-11-11 (records; see §10) | [ChatGPT](20-product-outcome-and-launch-review-ChatGPT.md), [Gemini](20-product-outcome-and-launch-review-Gemini.md) |
| Historical plans (context only) | [12](12-implementation-kickoff.md), [15](15-experience-plan.md), [17](17-screen-experience-implementation-plan.md), [18](18-camera-selfie-experience-research.md), [19](19-capture-wow-moment-research.md) |

Update this document when a function changes status, a screen is added, or a decision in §8 is taken.

## 10. External reviews: what we follow

Two other models reviewed the repository on 2026-11-11: [ChatGPT](20-product-outcome-and-launch-review-ChatGPT.md) and [Gemini](20-product-outcome-and-launch-review-Gemini.md). They agree with this blueprint on the four pillars, the last-mile print gap, home-setup coaching, helper capture, and the stale status docs. Their files stay as dated records; this table is the disposition.

### 10.1 Adopted

| Point | From | Where it now lives |
|---|---|---|
| Keep separate statuses: implemented in the spike ≠ validated on device ≠ validated in real printing ≠ release-accepted | ChatGPT §9 | Rule for §4: "Shipped (spike)" never means validated. Evidence is recorded in spike reports and phase gates ([23](23-launch-roadmap.md)). |
| Credit integrity: no double charge, no lost paid output, pending purchases, offline behaviour | ChatGPT §8 L06 | ADR-048 §6 |
| Files ready ≠ sent to the printer ≠ a correct print | ChatGPT §5 | F-47, J1 step 11–12, L19-003 |
| Fix the print tolerance before testing, not after seeing results | ChatGPT §7 | [23](23-launch-roadmap.md) P1 |
| Small-sample formative targets ("8 of 10") instead of large-study percentages | ChatGPT §7 | §7 (fits the beta-tester decision) |
| Check that testers understand *Ready* is not a guarantee | ChatGPT §7 | §7 |
| Move accepted functions into doc 02 as FR IDs once production starts | ChatGPT §9 | [23](23-launch-roadmap.md) P2 |
| README leads with the promise and the real status | both | [README](../README.md) |
| Concrete home-setup copy: face a window, plain wall about 0.5–1 m behind you | Gemini §2.A | L19-002 starting copy, to be validated with testers |
| Shadow and side-light detector; glasses-glare advisory (warn or manual check only, AGENTS.md §9) | Gemini §2.B | L19-014, L19-015 |
| Background colour per profile, not hard-coded white | Gemini §2.B | ADR-037, P0 for worldwide |
| Quick sheet presets ("one person, 8 copies", "family") | Gemini §2.B | L19-016 (P2) |
| Printer-brand diversity and shop/kiosk prints in beta | Gemini §4 | [23](23-launch-roadmap.md) P8 |
| Bar tolerance 50 ± 0.5 mm (readable with a ruler) | Gemini §4 | §7; tile tolerances are measured with calipers in the engineering round |

### 10.2 Not adopted

| Point | From | Why |
|---|---|---|
| Spain-only launch | ChatGPT §3 | Founder chose worldwide (ADR-047) |
| Accessibility as a mandatory release constraint; separate accessibility studies | ChatGPT §2, §7 | Founder decision (ADR-050) |
| A generic "EU/ICAO 35 × 45" profile | Gemini §2.B | Profiles are per country and document (AGENTS.md §11); 35 × 45 stays a generic size |
| Six Swift packages up front | Gemini §4 | Conflicts with [12 §4](12-implementation-kickoff.md): one project, packages only when a boundary needs enforcing |
| "100 % unit-test coverage" as a gate | Gemini §4 | Coverage is not evidence; boundary and fixture tests are (AGENTS.md §13) |
| "≥ 95 % crash-free" | Gemini §4 | Too low for a paid utility; target ≥ 99.5 % (§7) |
| Pure #FFFFFF as part of the wow description | Gemini §2.D | The background colour comes from the profile |
| Status banners for docs 15, 18, 19 | both | Already present |
