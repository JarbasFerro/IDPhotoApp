# 20 — Product blueprint: functions, screens, and launch scope

**Status:** Active. Start here. This is the single overview of what Calipic does at launch and where each part is specified.
**Date:** 2026-11-11
**State reviewed:** spike app 0.12.7 (95 commits), ADR-001 to ADR-046, BD-001 to BD-039, docs 01–19.
**Companion documents:** [user journeys](21-user-journeys.md), [quality and delight bar](22-quality-and-delight-bar.md), [launch roadmap](23-launch-roadmap.md).

This document does not replace the detailed specifications. It indexes them, resolves which one is current, and fills the gaps that block a launch plan: launch screens that were never specified, the business model, and the measures of "best app".

## 1. Goal

> **Calipic is the #1 iPhone app for making ID photos at home and printing them yourself.**

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

Correctness, privacy, and accessibility are not pillars to trade off. They are constraints on all four ([AGENTS.md](../AGENTS.md), [BD-034](brand/99-brand-decisions-log.md)).

## 3. Who it is for

From [BD-016](brand/99-brand-decisions-log.md) and the [founder answers](brand/00-discovery-answers.md):

1. **People avoiding the cost and trip to a photo shop**: adults renewing a DNI, passport, or licence.
2. **Parents** making photos for babies and children, often for the whole family at once.
3. **People preparing visa or residence documents**, often for another country and in a second language, who need a digital file and prints.
4. **Accessibility users**: the full journey must work with VoiceOver, Voice Control, and large text ([ADR-030](10-decisions.md)).

Personas and their step-by-step journeys are in [21-user-journeys.md](21-user-journeys.md).

## 4. Function inventory

Status key: **Shipped (spike)** = working in `Spikes/IDPhotoSpike` 0.12.7, still pending physical-device or production evidence where noted. **Partial** = exists but short of the launch contract. **Launch** = required for 1.0, not built. **Post-launch** = planned after 1.0. **Decision** = blocked on an open decision in §8.

### 4.1 Document profiles and requirements

| ID | Function | User value | Status | Specified in |
|---|---|---|---|---|
| F-01 | Current profile: Spain · DNI photo, 26 × 32 mm, white background | Correct format without research | Shipped (spike); copy is literal UI text | [13](13-spain-foto-carnet.md), [16 §3](16-screen-experience-spec.md) |
| F-02 | Versioned, sourced profile catalog with review dates | Rules stay current and traceable | Launch | [05](05-rules-engine.md), FR-110–FR-116, R7-001–R7-018 |
| F-03 | Country and document picker with search, recents, and favourites | Find "my" document in seconds | Launch (picker); recents and favourites Post-launch | [04 §Screen 2](04-ux-ui.md), FR-010–FR-016, U10-002, U10-013 |
| F-04 | Launch profile set beyond Spain | Serve the commercial launch market | **Decision D-1** | [ADR-047](10-decisions.md) (proposed) |
| F-05 | Short requirements preflight before every capture or import | Avoid an unusable photo before it is taken | Shipped (spike) | [16 §7](16-screen-experience-spec.md), ADR-043 |
| F-06 | Full requirements with source link and review date | Trust and exceptions (glasses, headwear) | Shipped (spike); must move to profile data | [16 §4](16-screen-experience-spec.md) |
| F-07 | Per-profile alteration policy (background replacement and tone allowed or not) | Never sell an output the office cannot use | Partial: policy gate exists, policy data missing | ADR-037, ADR-038, FR-151, R7-016 |
| F-08 | Child and baby mode (age relaxations, "no hands or toys" check) | Parents' main job | **Decision D-3** | ADR-017, [14 §5.6](14-priority-feature-plan.md) |

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
| F-21 | Background separation and replacement with the profile colour | Studio background at home | Shipped (spike), white only | ADR-037, [spike 04](spikes/04-background-replacement.md) |
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
| F-50 | Session: people, edits, and sheet are kept after Done, until the person clears them | Come back to print more copies | Shipped (spike) in memory; persistence **Decision D-4** | ADR-021 |
| F-51 | **Pricing and credits**: first result free, one free credit, then inexpensive credits; no subscription | Fair, transparent price | **Decision D-2**; Launch | BD-029, [ADR-048](10-decisions.md) (proposed), L19-006 |
| F-52 | Restore purchases and keep the credit balance across reinstalls and devices (consumables need a specific design; see ADR-048) | Trust and App Review compliance | Launch | AS18-006, L19-006 |
| F-53 | Settings and About: privacy explanation, App Icon, restore, help, version, legal | Durable needs in one place | Partial: App Icon and version on Home | U10-012, FR-003 |
| F-54 | Help: taking a good photo at home, printing, cutting, using a shop | Self-service support | Launch | L19-002, L19-004, L19-005 |
| F-55 | Choose your app icon (33 characters) | Personal delight outside the task | Shipped (spike) | BD-038 |
| F-56 | App Intents and App Shortcut "Take an ID photo"; Spotlight for profiles | Start from Siri or the Action button | Launch (P1) | ADR-031, AI13-001–AI13-005 |
| F-57 | Localization: English, Spanish, Portuguese (Brazil) | Launch languages | Shipped (spike) | BD-031 |
| F-58 | Rating request at a calm moment after a confirmed good print, never in the task | Ratings drive the App Store rank behind "#1" | Launch | L19-009, [22 §6](22-quality-and-delight-bar.md) |

### 4.7 Not in the product

Unchanged from [01 §8.3](01-product-definition.md) and [11 §7](11-ios-excellence-strategy.md): accounts, cloud storage, ads, beautification, identity-changing AI, clothing replacement, guaranteed-acceptance claims, widgets and Live Activities without a task need, Android, web, and iPad-specific UI.

## 5. Screen catalog at launch

"Spike" means the screen exists and its current contract is in [doc 16](16-screen-experience-spec.md). "New" means it needs a screen contract in doc 16 before implementation, using the doc 16 template (composition, states, copy inventory, accessibility).

| # | Screen | Purpose | Status | Contract |
|---|---|---|---|---|
| S-01 | Home | Start a photo; resume the session; see the profile and trust promise | Spike; needs the profile chooser entry and a fresh-install visual ([22 §3](22-quality-and-delight-bar.md)) | 16 §3 |
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
| S-18 | Pricing (credits sheet) | Price, balance, buy, restore | **New** (after D-2) | — |
| S-19 | Settings & About | Privacy, help, icon, restore, version, legal | **New** (App Icon row moves here; the version also stays on Home per AGENTS.md §17) | 04 → 16 |
| S-20 | Help topics | Home setup, printing, cutting, shop printing | **New** | — |
| S-21 | App Icon | Choose the Home Screen icon | Spike | 16 §12 |
| — | System surfaces | Share sheet, print controller, StoreKit purchase sheet, permission alerts | System | 16 §13 |

There is deliberately no onboarding carousel ([constitution rule 1](brand/02-experience-constitution.md)). BD-029's "tutorial result free" is satisfied by making the first completed result free, not by adding a tutorial screen. See ADR-048.

## 6. App map at launch

```text
Home ─┬─ Choose document ── Requirements
      ├─ Settings & About ─┬─ Help topics (home setup · printing · cutting · shop)
      │                    ├─ App Icon
      │                    └─ Pricing / Restore
      └─ Take Photo / Choose Photo
            │
            ▼
      Before your photo (setup tips · self or helper)
            │
      ┌─────┴──────┐
   Guided camera   PhotosPicker
   └ Review ───────┘
            ▼
      Photo Check ── Adjust ── Fix the edges
            ▼
      Choose result
      ├─ Digital Photo ── Share JPEG
      └─ Your sheet ── Print & Share ── Print check ── Cutting guide
                                         └─ (Pricing sheet before the first paid output)
```

Navigation remains one `NavigationStack`, system sheets for contained choices, and no tab bar ([16 §2.1](16-screen-experience-spec.md)).

## 7. Success measures and launch targets

The targets below are **proposed** and need founder acceptance. ADR-020 keeps analytics deferred, so pre-launch numbers come from moderated task tests, TestFlight feedback, and physical print tests; post-launch numbers come from App Store Connect and privacy-reviewed, on-device-aggregated signals only.

| Measure | Why it matters for "#1" | Proposed launch target | Source |
|---|---|---|---|
| First-time task success: launch → printed or shared photo, unaided | Ease | ≥ 90 % of test participants | Moderated task test (U10-017) |
| Median time from launch to a shared digital photo, first time | Ease | ≤ 90 s (the 60 s goal from doc 15 stays the stretch target) | Task test |
| Photos that reach Continue without opening Adjust | Automation quality | ≥ 80 % on the fixture and beta set | Fixture runs, beta |
| Blind preference vs. a photo-shop ID photo of the same person | Studio quality | Calipic preferred or equal in ≥ 70 % of pairs | Quality study L19-007 |
| First home print at the correct size (bar = 50 mm ± 0.5 mm) | Exact print | ≥ 95 % across the test printer set | Physical tests (ADR-026, P12-005) |
| Post-task ease (Single Ease Question, 1–7) | Satisfaction | Median ≥ 6 | Task test |
| "Would you use Calipic again / recommend it?" | Satisfaction | ≥ 80 % yes | Task test, TestFlight |
| App Store rating, first 90 days | Rank and trust | ≥ 4.7 | App Store Connect |
| Refund requests and support contacts per 100 purchases | Honest pricing | Tracked; target set after beta | App Store Connect, support inbox |
| Category rank for "ID photo" / "passport photo" in launch markets | Literal "#1" | Top 3 in the primary market within 6 months; #1 within 12 | App Store, ASO tools |

## 8. Open decisions that block launch

| ID | Decision | Why it blocks | Recommendation | Record |
|---|---|---|---|---|
| D-1 | Launch market and launch profile set | ADR-016 says Spain first; BD-032 names the US as the commercial lens; pt-BR is a launch language with no Brazil profile | Launch with three validated profiles: **Spain DNI 26 × 32**, **US passport 2 × 2 in**, **Brazil 3 × 4 cm**. Use the US as the App Store lens. Each must pass the release gate in [01 §15](01-product-definition.md). | [ADR-047](10-decisions.md) (proposed) |
| D-2 | Pricing details: what one credit buys, price points, when payment is asked | BD-029 accepts credits as direction; ADR-015 is still "Deferred"; paywall placement decides satisfaction | One credit = one finished output set for one person (digital + any sheets of that person) within the session. Show the price before capture. Ask for payment at Choose result, never at the end after files are made. No watermark. | [ADR-048](10-decisions.md) (proposed) |
| D-3 | Child and baby support at launch | Parents are a primary audience | Include helper mode for all; ship child relaxations only for profiles whose sources define them | ADR-017 |
| D-4 | Keep the session across app restarts | Coming back to print more copies | Keep the last session in protected local storage for 30 days, with a clear Remove; no gallery | ADR-021 |
| D-5 | Privacy-preserving measurement | Without data we cannot prove "#1" | Use App Store Connect analytics, MetricKit, and opt-in TestFlight feedback only; no third-party SDK | ADR-020 |
| D-6 | Clarify BD-034's ranking (native → beauty → accessibility) | Read literally, it ranks accessibility below beauty, while AGENTS.md §6 and constitution rule 9 make accessibility mandatory | Amend BD-034: accessibility is a constraint like correctness and privacy; the ranking only chooses among already accessible options | [brand log](brand/99-brand-decisions-log.md) |

## 9. Documentation map and source of truth

When documents disagree, the order is: accepted ADRs and brand decisions → [AGENTS.md](../AGENTS.md) → this blueprint for scope → doc 16 for current screen behavior → older planning docs.

| Need | Read |
|---|---|
| What the app is and does at launch | **This document** |
| Who uses it and how, step by step | [21 — User journeys](21-user-journeys.md) |
| What "great photo", "beautiful", and "wow" mean, and how they are tested | [22 — Quality and delight bar](22-quality-and-delight-bar.md) |
| What happens next until launch | [23 — Launch roadmap](23-launch-roadmap.md) |
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
| Historical plans (context only) | [12](12-implementation-kickoff.md), [15](15-experience-plan.md), [17](17-screen-experience-implementation-plan.md), [18](18-camera-selfie-experience-research.md), [19](19-capture-wow-moment-research.md) |

Update this document when a function changes status, a screen is added, or a decision in §8 is taken.
