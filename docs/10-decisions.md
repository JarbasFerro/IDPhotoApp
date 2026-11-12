# 10 — Decision register

## 1. Purpose

Important product and architecture choices must be explicit. This avoids decisions being made accidentally by whichever library, framework, or screen is implemented first.

Statuses:

- **Proposed** — recommended direction, not locked.
- **Accepted** — active decision; implementation should follow it.
- **Rejected** — evaluated and deliberately not chosen.
- **Superseded** — replaced by a newer decision.
- **Deferred** — intentionally postponed.

When evidence changes an accepted decision, revise or add a decision with a date/rationale. Do not silently change the architecture.

---

## ADR-001 — Native iOS application stack

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Build the product as a native iPhone application using Swift and SwiftUI. Android and cross-platform frameworks are out of scope.

Development uses the newest practical Xcode/iOS SDK so the app can adopt current Apple platform behavior and APIs.

### Rationale

The product goal changed from cross-platform efficiency to maximum iOS quality. Native architecture gives direct access to:

- current SwiftUI design/navigation behavior;
- Liquid Glass/system materials;
- AVFoundation camera capabilities;
- Vision image understanding/segmentation;
- Core Image/ImageIO/Core Graphics;
- App Intents, Siri, Shortcuts, Spotlight;
- Apple accessibility APIs;
- Instruments/MetricKit;
- Foundation Models/Core AI where justified;
- the least abstraction between product design and iOS behavior.

### Rejected baseline

Flutter/Dart for iOS + Android is rejected for this project direction, not because Flutter is inherently unsuitable but because a portability layer conflicts with the explicit native-platform ambition.

### Consequences

- one iOS codebase;
- no Android parity requirement;
- Apple-frameworks-first dependency policy;
- iOS-specific UX decisions may be made without cross-platform compromise.

---

## ADR-002 — Core image processing location

**Status:** Accepted  
**Decision:** Core face analysis, segmentation, crop/render, and export run on-device. No cloud processing is required for MVP.

**Rationale:** privacy, offline use, latency, simpler governance, and strong fit with Vision/Core Image on Apple Silicon.

Any future cloud-processing feature requires a separate decision covering user value, data transmitted, consent, retention, security, App Privacy disclosure, and fallback behavior.

---

## ADR-003 — Face analysis implementation

**Status:** Proposed, Apple Vision strongly preferred  
**Decision shape:** use Vision as the default implementation and benchmark its current face observations in M1 before locking which landmarks/pose checks are reliable enough for product claims.

**Selection criteria:**

- face detection recall;
- landmark semantics/accuracy;
- multiple-face behavior;
- children/babies where supported;
- latency/memory;
- fully on-device behavior;
- availability across supported iOS targets.

Third-party face SDKs require evidence that Vision cannot meet a material product requirement.

---

## ADR-004 — Subject segmentation implementation

**Status:** Proposed, Apple Vision strongly preferred  
**Decision shape:** use Vision subject/foreground segmentation first. Evaluate iOS 27 tap/scribble/rectangle segmentation as the preferred refinement path if quality and UX are suitable.

**Fallback:** original background where permitted, retake, or safe user refinement. Never silently export obvious segmentation artifacts.

---

## ADR-005 — PDF generation

**Status:** Proposed, Core Graphics preferred  
**Decision shape:** use Core Graphics PDF APIs unless M1 shows a concrete limitation. Exact physical geometry matters more than convenience.

---

## ADR-006 — Rules as versioned data

**Status:** Accepted  
**Decision:** country/document specifications live in a versioned validated rules catalog rather than document-specific Swift conditionals.

Consequences:

- stable profile IDs/versions;
- provenance;
- schema + semantic validation;
- evaluator registry;
- CI validation.

---

## ADR-007 — Compliance result semantics

**Status:** Accepted  
**Decision:** each evaluable requirement maps to `pass`, `warn`, `fail`, or `manual_check`.

`Ready` never means guaranteed official acceptance.

---

## ADR-008 — Source image mutability

**Status:** Accepted  
**Decision:** the original captured/imported source is immutable. Editing is non-destructive and parameter-driven until final render.

---

## ADR-009 — Coordinate-system discipline

**Status:** Accepted  
**Decision:** distinguish source pixels, normalized image coordinates, SwiftUI preview points, output pixels, physical millimetres, and PDF points with explicit value types/conversions.

---

## ADR-010 — Deterministic official output

**Status:** Accepted  
**Decision:** final dimensions, crop geometry, physical scaling, and print layout are deterministic. Generative AI cannot decide official output geometry.

---

## ADR-011 — Identity-preserving editing

**Status:** Accepted  
**Decision:** official-document mode excludes beautification/generative edits that materially change identity or appearance.

Prohibited baseline features include:

- face reshaping;
- eye enlargement;
- synthetic makeup;
- beautification skin smoothing;
- wrinkle removal;
- hair reconstruction;
- clothing replacement.

---

## ADR-012 — Backend for MVP

**Status:** Accepted  
**Decision:** no backend is required for the core MVP.

Possible future reasons:

- signed rule updates;
- explicitly optional account/sync;
- opt-in diagnostics/support;
- entitlement infrastructure if StoreKit is insufficient.

Moving image processing to a server for convenience is not a sufficient reason.

---

## ADR-013 — Account requirement

**Status:** Accepted  
**Decision:** no login/account is required for the core workflow.

---

## ADR-014 — Advertising

**Status:** Accepted  
**Decision:** no intrusive advertising in the create/check/edit/export workflow. Preferred baseline is no third-party advertising SDK.

---

## ADR-015 — Monetization

**Status:** Superseded by ADR-048 (accepted 2026-11-11). The constraints below still apply.  
**Decision needed:** free, one-time purchase, freemium, subscription for advanced/frequent users, or hybrid.

**Accepted constraints:**

- StoreKit is preferred;
- no surprise watermark;
- no paywall before explaining a photo problem;
- no dark-pattern countdown/interstitial;
- monetization cannot alter rules correctness.

---

## ADR-016 — Initial launch jurisdictions

**Status:** Accepted for the reference format (Spain DNI stays the engineering reference profile). Launch scope superseded by ADR-047 (worldwide, accepted 2026-11-11).
**Date:** 2026-09-15

**Decision:** Start with Spain and the user-requested “foto carnet”, 32 × 26 mm in portrait orientation: width 26 mm, height 32 mm. Use DNI as the first official research reference; exact document-compliance claims require a validated, sourced profile.

**Evidence:** User selected Spain/foto carnet as the first-release scope. [Initial source review](13-spain-foto-carnet.md) records the DNI reference and unresolved requirements.

**Consequences:** Deliver this single format end to end before expanding countries or document variants. Shared dimensions alone do not establish equivalence with passport, driving-licence, or residence-card requirements. Child/baby coverage remains governed by ADR-017. Digital export is an app capability, not evidence of an official online-submission channel.

---

## ADR-017 — Child/baby support

**Status:** Accepted (founder, 2026-11-11)  
**Decision:** Children use the same flow, profiles, and checks as adults; there is no child mode at 1.0. Helper mode (someone else holds the phone, back camera) is the recommended way to photograph a child. Checks that some countries relax for babies (for example eyes open or neutral expression) show as warnings or manual checks and never block output. Baby support is not advertised at launch. The architecture keeps age-related profile exceptions possible; adding them as profile data is post-launch work, per profile and only from official sources.

---

## ADR-018 — Generic/custom photo sizes

**Status:** Accepted (founder, 2026-11-11) for 1.0.  
**Decision:** may use the same deterministic renderer but must be visually distinguished from sourced official profiles and make no compliance claim.

**Founder direction:** people can choose a custom photo size **without choosing a country**. Example: a school asks for three new photos of each child every year.

1. **Entry:** **Custom size** is a first-class choice in *Choose document* (S-02) and on Home's document card, separate from countries.
2. **Size:** width × height in mm or inches. A few common sizes are offered as shortcuts, labelled as sizes and never as documents (for example 25 × 30 mm, 30 × 40 mm, 35 × 45 mm, 2 × 2 in). Recently used custom sizes are remembered on the device.
3. **Framing:** head-and-shoulders by default, using non-official proportions. Closer and Wider framing in Adjust.
4. **Background and tone:** free choice, because no rule applies. Background is Original, White, or Light grey; Document Tone is on by default and can be turned off.
5. **Checks:** only photographic checks (sharpness, eyes, light, enough resolution for the print size). Never *Ready* for a document and never a source or requirement claim. The headline is, for example, *Looks good for printing*. Requirements say: *No official rules apply. Use the size your school or organisation asked for.*
6. **Outputs:** the same as for any profile. People can be mixed on the print sheet (for example three children, three copies each), and there is a digital JPEG at the chosen size and 300 ppi.
7. **Price:** one credit per person, as for any photo (ADR-048).
8. **Confirmed by the founder (2026-11-11):** named shortcuts **3 × 4 cm** (Brazil) and **2.5 × 3 cm (tamaño infantil)** (Mexico), and a **Black and white** output option. Data: [Rules/catalog/v1/custom-size-shortcuts.json](../Rules/catalog/v1/custom-size-shortcuts.json).

---

## ADR-019 — Remote rule updates

**Status:** Deferred  
**Decision:** initial MVP may ship rules with app updates. Architecture must not prevent future signed catalog updates.

If enabled later: signatures, integrity validation, atomic activation, schema/semantic validation, and known-good rollback are mandatory.

---

## ADR-020 — Analytics / crash reporting

**Status:** Accepted for 1.0 (founder, 2026-11-11): no analytics or crash-reporting SDK and no in-app telemetry. Success is measured with beta testers the founder knows: TestFlight feedback and crash reports, observed first-use sessions, and a short questionnaire ([22 §6](22-quality-and-delight-bar.md)). After launch: App Store Connect and Xcode Organizer. MetricKit stays an option.  
**Decision shape:** begin with Apple-native logging/development diagnostics. Evaluate MetricKit. Add a third-party SDK only if value materially exceeds privacy/dependency cost.

Never include:

- photos/thumbnails;
- embeddings;
- landmarks;
- sensitive paths;
- EXIF/GPS;
- document numbers.

---

## ADR-021 — Photo/job history

**Status:** Superseded by ADR-049 (drafts, accepted 2026-11-11). Recent and favourite profiles remain a post-launch idea (U10-013).  
**Decision:** MVP stores recent/favorite document profiles, not a permanent face-photo gallery by default.

---

## ADR-022 — Primary output formats

**Status:** Proposed  
**Decision:** JPEG baseline for digital official photos; PNG where required/appropriate; PDF for dimensionally controlled print sheets.

Use ImageIO/Core Graphics/Core Image primitives unless a requirement proves they are insufficient.

---

## ADR-023 — State management

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Use SwiftUI + Observation (`@Observable`) and Swift Concurrency. Do not add a third-party state-management architecture by default.

### Required behavior

- explicit feature/workflow state;
- `@MainActor` UI-facing mutation where appropriate;
- cancellation/stale-result protection;
- initializer/typed environment dependency injection;
- no hidden global mutable `PhotoJob`;
- views contain presentation logic, not image/rule algorithms.

### Revisit trigger

Only reconsider if real production complexity demonstrates a structural problem that native tools cannot handle cleanly.

---

## ADR-024 — Minimum iOS version

**Status:** Proposed  
**Date:** 2026-09-05

### Proposal

Use **iOS 26.0** as the initial minimum deployment target while compiling with the latest iOS 27 SDK. Adopt iOS 27-only capabilities using availability checks.

### Why not immediately require iOS 27?

The app can demonstrate current iOS 27 capabilities without needlessly excluding recent iPhone users. This also forces optional latest-OS features to degrade gracefully.

### Why not support much older iOS?

This is a new app with a native-quality target and heavy use of current camera, Vision, SwiftUI, privacy, and intelligence APIs. Compatibility work should not compromise architecture/UX without a material reach benefit.

### Gate

Finalize after M1 testing on physical devices and final iOS 27/Xcode 27 availability.

---

## ADR-025 — Source/provenance standard

**Status:** Accepted  
**Decision:** official profiles require authoritative source metadata and last-reviewed date; unknown values remain explicit.

Source preference:

1. issuing government/authority;
2. official embassy/delegated provider;
3. adopted technical standard;
4. clearly marked authoritative secondary source when primary is unavailable.

---

## ADR-026 — Print accuracy policy

**Status:** Accepted  
**Decision:** print output is verified physically, not only mathematically. UI explains Actual Size / 100% printing and scaling risk.

---

## ADR-027 — Test image privacy

**Status:** Accepted  
**Decision:** private family/user identity photos are not committed to the public repository. Public fixtures must be synthetic, appropriately licensed, or explicitly consented for intended use.

---

## ADR-028 — Apple-frameworks-first dependency policy

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Prefer first-party Apple frameworks when they satisfy the requirement at the necessary quality.

Primary stack includes:

- SwiftUI;
- Observation;
- Swift Concurrency;
- AVFoundation;
- PhotosUI;
- Vision;
- Core Image;
- ImageIO;
- Core Graphics;
- Accelerate where measured benefit exists;
- App Intents/Core Spotlight;
- StoreKit;
- Swift Testing/XCUITest;
- Instruments/MetricKit;
- Foundation Models/Core AI only where approved.

A third-party dependency requires a written reason covering why Apple APIs are insufficient, privacy/network behavior, required-reason APIs, maintenance, license, binary size, performance, and removal plan.

---

## ADR-029 — Current iOS design system and Liquid Glass

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Use native SwiftUI controls/navigation as the default path to current iOS visual behavior. Do not build a custom “Liquid Glass design system.”

Custom glass effects are limited to cases where they improve hierarchy/interaction beyond system components.

### Rationale

Apple’s own guidance says standard SwiftUI/UIKit controls adopt current Liquid Glass behavior when built with the latest SDK. Over-customization would reduce familiarity, accessibility, and future adaptability.

---

## ADR-030 — Accessibility baseline

**Status:** Accepted; scope for 1.0 narrowed by ADR-050 (founder, 2026-11-11). The full baseline below returns after 1.0.  
**Date:** 2026-09-05

### Decision

Accessibility is part of feature acceptance criteria.

Core workflow must support as applicable:

- VoiceOver;
- Voice Control;
- Dynamic Type including accessibility sizes;
- Reduce Motion;
- Increased Contrast;
- Differentiate Without Color;
- non-gesture alternatives for crop/position controls.

No production milestone may defer the entire accessibility implementation to M7.

---

## ADR-031 — App Intents and system exposure

**Status:** Accepted for architecture; feature set Proposed  
**Date:** 2026-09-05

### Decision

Design the app so useful actions can be exposed through App Intents/Siri/Shortcuts/Spotlight without exposing sensitive photo data.

Initial candidate intents:

- create an ID photo;
- open a document profile.

Do not index personal face photos/landmarks as App Entities.

---

## ADR-032 — Foundation Models / generative AI boundary

**Status:** Accepted boundary; feature itself Deferred/P1  
**Date:** 2026-09-05

### Decision

Foundation Models may be used for optional explanation/coaching/natural-language interaction, but never as the source of truth for official dimensions or deterministic pass/fail geometry.

### Mandatory properties if shipped

- on-device first;
- structured deterministic diagnostics remain visible;
- clean model-unavailable fallback;
- no silent override of official source text;
- controlled evaluation suite;
- no cloud fallback without a new privacy decision.

The product should not include AI solely for marketing value.

---

## ADR-033 — Swift Testing

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Use Swift Testing for new domain/unit/integration tests where supported. Use XCUITest for UI/system-boundary automation.

Image output tests remain fixture/golden based and may use custom comparison helpers.

---

## ADR-034 — Camera implementation

**Status:** Proposed, AVFoundation expected  
**Date:** 2026-09-05

### Decision shape

Use AVFoundation for the in-app guided camera rather than a generic image-picker camera because real-time capture guidance is a signature product need.

M1 must validate startup latency, high-resolution stills, interruptions, memory, thermal behavior, and accessible interaction before final lock.

---

## ADR-035 — Photo import permissions

**Status:** Accepted  
**Date:** 2026-09-05

### Decision

Use PhotosUI/PhotosPicker for normal photo import. Do not request broad Photo Library access unless a future feature specifically requires it.

---

## ADR-036 — Print sheet composer and paper catalog

**Status:** Proposed  
**Date:** 2026-09-16

### Context

The user requires customizable paper sizes, placement re-optimized per paper, mixed photos per page with per-photo copies, overflow pages, and bleed/cut marks. Consumer printing scales silently (borderless +~2 %, AirPrint snaps to the smallest containing paper, kiosks fill-crop) and iOS cannot create custom AirPrint papers.

### Decision

Implement a versioned `PaperSize` catalog plus custom sizes; a deterministic two-stage guillotine row solver in the domain layer; adaptive 0–1 mm bleed, 4 mm margin to the bleed edge, 2 mm gutter, corner ticks, and a 50 mm calibration bar; PDF with page box equal to the paper and a 300 ppi exact-aspect JPEG per page; `UIPrintInfo.outputType = .photo` with a `choosePaper` delegate preferring bordered papers. Zero-gutter "Max copies" is opt-in.

### Evidence

[14-priority-feature-plan.md §2.5, §3.1–3.5](14-priority-feature-plan.md); printer-vendor borderless documentation; AirPrint paper-selection behaviour; packing-algorithm survey.

### Alternatives considered

MaxRects/Skyline packing (better density, non-guillotine cuts); through-lines instead of ticks (marks survive cut errors on the photo); borderless-first printing (dimensional error).

### Consequences

Print geometry becomes a tested domain module; physical measurement remains the release gate (ADR-026).

### Revisit trigger

Apple adds custom AirPrint paper support or documented scaling control.

---

## ADR-037 — Background replacement colour is profile data

**Status:** Proposed  
**Update 2026-11-11:** alteration gating is superseded by ADR-051. Background replacement and tone are offered on every profile, and the background colour remains profile data.  
**Date:** 2026-09-16

### Decision

The replacement colour, uniformity/contrast rule, and `replacementPolicy` come from the document profile. Spain (DNI) defaults to white per the official wording; UK-style cream/grey and German neutral-grey rules are represented as data. Profiles also carry `alterationPolicy` so jurisdictions requiring unaltered photos default replacement off with an explanation.

### Evidence

Official wording for Spain, UK, Germany, Canada, ICAO TR; see [14-priority-feature-plan.md §2.2](14-priority-feature-plan.md).

### Consequences

No global "make white" behaviour; the compositor is colour-agnostic; semantic validation rejects replacement enabled without a colour.

---

## ADR-038 — Tonal correction policy (Document Tone)

**Status:** Proposed  
**Date:** 2026-09-16

### Context

The user requested Apple presets "like Studio Light". Studio Light is a read-only, user-toggled video effect; Portrait Lighting exists in Core Image only as private filters; PhotoKit exposes no lighting adjustment.

### Decision

Ship a single global, reversible correction built from `autoAdjustmentFilters`, neutral white balance, an exposure clamp, and mild export-time sharpening, with strength and before/after. No Portrait Lighting or Studio Light claims, no private filters, no face-local retouching (ADR-011). Gated by profile `alterationPolicy`.

### Evidence

Implemented in [spike 06](spikes/06-document-tone.md) (2026-09-16): synthetic warm scene neutralised at strength 1 with face luminance preserved and no clipping; eight private portraits keep or lift face luminance with cast within ±0.015. Studio Light confirmed on device to be a video-format effect unavailable to photo sessions (36 of 57 front-camera formats support it, none of them still formats). Warm-light photos are still open.

### Revisit trigger

Apple publishes a still-image relighting API, or product evidence shows the correction is not worth its policy cost.

---

## ADR-039 — Face alignment estimator

**Status:** Proposed  
**Date:** 2026-09-16

### Decision

Eye line and chin come from pinned-revision Vision landmarks; crown is a fused estimate (segmentation-mask top vs anthropometric extrapolation from eye line and chin, with a hair-volume divergence rule); the solver levels eyes within the permitted roll range, scales to the head-height target, then places by eye-line/top-margin bands; crown/chin handles are always exposed and overrides logged for calibration. Spain uses labelled ICAO engineering defaults until official numbers exist.

### Evidence

No Apple API returns the top of the head; ICAO TR and German rules define crown ignoring hair. See [14-priority-feature-plan.md §2.3, §3.8](14-priority-feature-plan.md).

---

## ADR-040 — Vision request revision pinning

**Status:** Proposed  
**Date:** 2026-09-16

### Decision

Pin `DetectFaceLandmarksRequest` and `DetectFaceRectanglesRequest` to `.revision3` on all supported OS versions until a calibrated migration to revision 4 (iOS 27, 98 landmarks, tighter boxes) is evaluated with fixtures. Segmentation and iterative-segmentation revisions are recorded per result.

### Rationale

FR-072 determinism across iOS 26 and 27.

---

## ADR-041 — iOS 27 iterative segmentation as the refinement path

**Status:** Proposed; refines ADR-004  
**Date:** 2026-09-16

### Decision

Use `GenerateIterativeSegmentationRequest` (seed box plus include/exclude points, on-demand model assets) as the Refine interaction on iOS 27, availability-gated; iOS 26 falls back to candidate-mask switching, choke/feather, original background, or retake. Official correctness never depends on the iOS 27 API (FR-065).

---

## ADR-042 — Foundation Models image input is advisory only

**Status:** Proposed; refines ADR-032  
**Date:** 2026-09-16

### Decision

If the optional Photo Coach ships, it uses on-device `SystemLanguageModel` with image attachments for explanation and coaching only (for example glare or shadow hints), with `@Generable` structured output, an Evaluations-framework suite, and a clean unavailable path. `PrivateCloudComputeLanguageModel` is not used for identity photos without a new privacy decision (FR-135).

---

## ADR-043 — Revised capture, output, and adjustment flow

**Status:** Accepted

**Date:** 2026-09-28

### Context

The current Spain spike sends every prepared photo through the print-sheet composer before sharing, hides essential pre-capture requirements behind a Home card, and requires a two-page camera introduction on first use. The earlier experience plan also proposes floating glass editor controls while the newer screen specification proposes native controls below the photo. These differences leave the next UI pass ambiguous.

### Decision

1. After Photo Check, offer **Digital Photo** and **Print Sheet**. A digital JPEG can be shared without configuring paper. The print path keeps the multi-person sheet composer.
2. Show a brief, relevant requirements summary before starting either camera capture or PhotosPicker import. Keep the full sourced guidance available from that summary and Home.
3. Use a native scrolling **Adjust** sheet with controls below the photo. Do not plan a floating glass control cluster over the portrait.
4. Name the current profile **Spain · DNI photo** until passport-specific requirements have been sourced and validated. Matching image dimensions alone do not expand the claim.
5. Replace the mandatory two-page first-use camera tutorial with a brief optional tip and persistent camera Help. Camera permission remains at the Take Photo point of use.

### Evidence

The founder selected each option in the 2026-09-28 screen-spec review. The decision responds to `docs/16-screen-experience-spec.md`, `docs/15-experience-plan.md`, and the provenance limitation in `docs/13-spain-foto-carnet.md`.

### Consequences

The navigation and export workflow need distinct digital and print paths, while both reuse the immutable source and current adjustments. Requirements need a lightweight preflight presentation. Camera Help remains available after first use. Copy, String Catalog entries, UI tests, screenshots, and the screen specification must be revised together. Historical stage descriptions in `docs/15-experience-plan.md` remain evidence of the earlier iterations; its future glass-cluster and mandatory-intro proposals are superseded by this ADR.

### Revisit trigger

Task testing shows that the extra output choice or preflight summary slows or confuses users, or a validated profile makes a different acquisition/export sequence necessary.

---

## ADR-044 — Calm guided camera composition

**Status:** Accepted

**Date:** 2026-09-28

### Context

A physical iPhone screenshot showed C-shaped marks, a dense readiness ring around the shutter, and stacked help/status text covering the subject. The visual treatment made capture harder to understand even when live analysis reported readiness.

### Decision

Use one continuous oval for head placement, one actionable instruction near the shutter, and a plain white system-style shutter. Readiness is expressed through a green oval, words, and VoiceOver. Put optional Automatic capture in a one-page native Help Form, accessible from a native glass top control. The four-second first-use tip occupies the instruction slot and expires automatically. Use Liquid Glass only for native camera controls where it keeps the photo visually primary. Manual capture remains possible when checks need attention.

The 2026-09-28 follow-up adds spatial feedback to this guide. Physical-device screenshots then showed that the oval was too large and face-directed instructions were confusing. The oval is smaller; a short arrow grows from its edge for one stable **phone** movement. Left/right account for lens facing and whether the displayed preview is mirrored. Raise/lower, tilt up/down, and closer/farther have distinct spoken and visible instructions; the size cue shows the portrait expanding or shrinking. When measured checks settle, the oval becomes green and briefly glows with one haptic. Green means camera checks look ready, never official acceptance. Lighting leaves the oval neutral. Reduce Motion removes the animation. The guide fades at shutter press; Photo Check keeps its existing source-to-crop landing transition. The oval guides head placement but never promises an exact final crop.

### Evidence

The founder requested a Face ID setup-inspired redesign, then reviewed four physical-device states and requested smaller geometry and phone-directed guidance. Simulator fixtures and camera UI tests cover visible placement and accessibility; final directional calibration on both physical cameras remains required.

### Consequences

The old C-frame, readiness arcs, floating Auto toggle, and two-page ring tutorial are superseded. Help copy, String Catalog, screen specification, and camera screenshots follow this decision. Live analysis and its accessibility summary remain in place.

### Revisit trigger

Physical-device task tests show that the oval misguides positioning, the single hint is hard to read over real backgrounds, or the hidden Auto setting becomes difficult to discover.

---

## ADR-045 — Biometric guided selfie capture with relative horizon and instant freeze-frame review

**Status:** Accepted, refined 2026-09-30
**Date:** 2026-09-28

### Context

While ADR-044 established a calmer single-oval camera composition, deep research into ICAO Doc 9303/ISO 19794-5 standards, Apple Face ID enrollment, and identity verification leaders (Stripe Identity, Persona, Onfido) revealed critical interaction gaps:
1. **Background Clutter:** The bare full-screen preview leaves the user distracted by peripheral room clutter.
2. **Mental Math on Leveling:** Pure text cues (*"Tilt phone upright"*, *"Level the phone"*) cause cognitive friction. Leveling to Earth gravity is physically flawed for selfies because a tilted head with an equally tilted phone produces a level portrait in sensor space ($\\Delta \\theta = 0^\\circ$).
3. **Capture Anxiety vs. Hand Shake:** Full auto-capture snaps prematurely before users settle their expression; conversely, a raw shutter tap without readiness arming risks camera shake.
4. **Post-Capture Verification:** Jumping directly from capture to the full Photo Check / crop screen denies the user a fast inline inspection of their eyes/expression.

### Decision

1. Prototype a gentle peripheral scrim and subtle eye-level line inside the compact oval. Assess both on a physical phone, including visibility of eyes and shoulders. Keep one actionable phone-movement cue at a time. Green means measured live checks have settled, not official acceptance.
2. Keep the familiar manual shutter. Optional three-second automatic capture remains in Help. Neither path is blocked by a visual readiness state.
3. After capture, show the actual still image with **Retake** and **Use Photo**. Retake returns to live preview; Use Photo proceeds to Photo Check. Do not show verification chips or claimed compliance before analysis.

### Evidence

[18-camera-selfie-experience-research.md](18-camera-selfie-experience-research.md); ICAO Doc 9303 and ISO/IEC 19794-5 biometric standards; UX benchmarks from Apple Face ID, Stripe Identity, Persona, and Onfido Motion.

### Consequences

`CameraView.swift` and `CameraFramingGuide.swift` implement the capture review and visual prototypes. Physical-device testing decides whether the scrim and eye-level line remain.

### Revisit trigger

Physical-device task tests show that the still review adds more friction than value, or the scrim/eye-level line obscures useful image detail.

---

## ADR-046 — Multi-sensory capture climax and the "WOW moment"

**Status:** Accepted, refined 2026-09-30
**Date:** 2026-09-29

### Context

Under the Peak-End Rule, a user's long-term evaluation of an app is anchored at its emotional climax. In an ID photo app, taking the photo is that decisive peak. The current spike relies on a flat 120ms white flash and generic system sound. This feels utilitarian rather than extraordinary, leaving the app vulnerable to user dread about administrative bureaucracy.

### Decision

Shutter press gets one soft visual bloom and one haptic. AVFoundation supplies the system shutter sound; no custom earcon is added. Once the actual still is ready, show it for review with Retake and Use Photo. Do not add a segmentation effect or biometric verification claims to the captured image. Respect Reduce Motion and follow capture completion rather than a fixed choreography deadline.

### Evidence

[19-capture-wow-moment-research.md](19-capture-wow-moment-research.md); Kahneman's Peak-End Rule; Apple HIG on sensory feedback; Apple VisionKit Subject Lifting; Leica/Hasselblad acoustic leaf shutter physics.

### Consequences

The camera uses the existing native capture path and a restrained SwiftUI bloom. No new audio or haptics dependency is needed.

### Revisit trigger

Physical-device review finds the bloom distracting, or capture-to-review latency is too long for a calm experience.

---

## ADR-047 — Worldwide launch and the launch profile catalog

**Status:** Accepted (founder, 2026-11-11). Supersedes ADR-016's launch scope and the earlier three-profile proposal.
**Date:** 2026-11-11

### Context

ADR-016 made Spain DNI 26 × 32 mm the first format, and the spike delivers it end to end. BD-032 names the United States as the commercial lens. The goal is to be the #1 at-home ID-photo app ([20 §1](20-product-blueprint.md)), and the founder wants that goal worldwide rather than in one market.

### Decision

1. **Availability:** Calipic 1.0 is offered in every App Store territory where it can legally be distributed. Territories with extra requirements are checked one by one before submission (for example, China mainland requires an ICP filing number in App Store Connect; verify the current rule).
2. **Profile catalog:** 1.0 supports the most-used photo documents of the countries that matter most on the App Store. The ranking method, recorded in L19-010:
   - rank countries by App Store relevance (iPhone users and App Store spending), from a named, dated data source;
   - within each country, include the documents for which people supply their own photo (passport, national ID card, residence permit, driving licence where self-supplied); skip documents whose photo is taken at the office;
   - add the most-requested cross-border documents: visa photos for the most-visited destinations (for example the United States visa and the Schengen visa).
3. **Tiers (data in [24](24-launch-country-ranking.md); list confirmed by the founder 2026-11-11, D-8). Wave A is Tier 1 and Wave B is Tier 2:**
   - **Wave A at 1.0:** the 15 countries holding 82 % of spending power. United States, Japan, United Kingdom, Germany, Canada, Australia, France, Italy, South Korea, Switzerland, Spain, Saudi Arabia, Mexico, Netherlands, Brazil.
   - **Wave B in the first updates:** 20 more countries that take reach to 80 % of iPhone users.
   - Together: 35 countries, about 20 % of storefronts.
   - **Russia** is excluded: there have been no App Store payments there since April 2026.
   - **China mainland is excluded** (founder, 2026-11-11, D-10): the app is not offered on the mainland China storefront ([25 §5](25-wave-a-document-types.md)). Hong Kong, Macao, and Taiwan are separate storefronts.
   - **Documents per Wave A country:** [25](25-wave-a-document-types.md). Several main documents no longer accept home-made photos (for example the German and French passports and ID cards, and the Canadian passport); Calipic never offers profiles for those.
4. **Release gate unchanged:** every profile needs its own sourced research document (like [13](13-spain-foto-carnet.md)), alteration policy, background colour (ADR-037), digital preset where one exists, and last-reviewed date. A profile not validated in time moves to Tier 2; it never ships with weaker provenance. Never copy a profile from another country because the sizes match (AGENTS.md §11).
5. **Countries without a profile:** generic print sizes stay available on the sheet. A custom size (ADR-018), clearly marked as unofficial, is recommended so the app is useful in every territory.
6. **App Store lens:** the United States stays the lens for English screenshots, keywords, and pricing tests (BD-032). Spain DNI stays the engineering reference profile.

### Evidence

Founder decision 2026-11-11; BD-032; [brand 04](brand/04-market-prioritization.md) §3, §7, §9. Many profiles share a geometry family (35 × 45 mm, 2 × 2 in, 3 × 4 cm), so the engineering cost per profile is mostly data. Research and validation costs are not shared.

### Alternatives considered

- Spain only, or Spain + US + Brazil: lower risk; rejected by the founder in favour of a worldwide goal.
- A generic "ICAO 35 × 45" profile: rejected. Profiles are per country and document; a shared size is not a shared rule set.

### Consequences

- Profile research becomes the longest item on the critical path ([23](23-launch-roadmap.md) P3). It starts as soon as the country list is fixed.
- Background colour as profile data (ADR-037) becomes P0: several countries do not use pure white.
- Localization (D-7 and D-12, founder 2026-11-11): no new languages for Wave A. 1.0 ships **English, Spanish, and Portuguese (Brazil)** (BD-031). Profile names may show the official local name next to the English one ([25 §6](25-wave-a-document-types.md)).
- Alteration policy decides the experience in the biggest market: the US online-renewal rules forbid changes by apps, filters, or AI, so background replacement and Document Tone may be off for some profiles ([25 §4](25-wave-a-document-types.md)).
- The fixture set must cover a global user base ([22 §2](22-quality-and-delight-bar.md)).

### Revisit trigger

L19-010 data changes the country order; an official source forbids at-home preparation or editing; research capacity cannot validate Tier 1 in time (cut Tier 1 rather than lowering the gate).

---

## ADR-048 — Pricing: one free photo, then one credit per photo

**Status:** Accepted (founder, 2026-11-11); **amended 2026-11-12** (credit packs, credits on screen, unlock in place: see the amendment below, which wins where it differs from §1, §4, and §8). Resolves ADR-015 and amends BD-029: one free credit in total, not a free result plus a free credit.
**Date:** 2026-11-11

### Context

BD-029 set the direction: credits, no subscription. ADR-015's constraints forbid surprise watermarks, paywalls before a photo problem is explained, and dark patterns. The founder set the price and asked that people can edit as much as they need, with a clear warning at the point of no return.

### Decision

1. **Price:** the first photo is free (one free credit). Each further photo costs one credit at **USD 0.99**: a StoreKit consumable whose local prices follow Apple's equalization for that price point. No subscription, no ads.
2. **What a credit unlocks:** one person's finished photo for one document profile: its digital file and any number of print copies and sheets, at every print size of that person on the sheet. Sharing or printing an unlocked photo again is always free.
3. **When it is spent:** at the person's first output of any kind (digital file, sheet PDF, page JPEG, or print). Before that, everything is free: capture, retakes, import, Photo Check, Adjust, sheet layout, and drafts (ADR-049).
4. **Point of no return:** before spending, a confirmation sheet shows the photo, any open warnings or manual checks, and the cost (the free photo, one credit from the balance, or USD 0.99 per person still locked, with a total when several people are on the sheet). It states: *After this, the photo's framing and edits are final. Changing them later uses a new credit. Printing or sharing it again is free.* Actions: **Unlock and continue** and **Keep editing**.
5. **After unlocking:** the photo's render recipe (source, crop, background, tone) is frozen. Output choices stay free: digital or print, paper, copies, sizes on the sheet. **Edit photo** on an unlocked person creates a new draft that needs its own credit when output; the app says so before opening it.
6. **Integrity:** the credit is reserved on confirmation, committed only after the first output file is verified (FR-096), and released if generation fails or is cancelled. A crash or relaunch never charges twice and never loses a paid photo; the ledger is idempotent per unlock ID. Pending purchases and Ask to Buy leave the draft locked and intact. Spending a credit works offline; buying one needs the App Store.
7. **Free credit and restore:** one free credit per Apple ID where possible. "Free credit used" and the paid balance are mirrored in the iCloud key-value store and reconciled with StoreKit transaction history (`SKIncludeConsumableInAppPurchaseHistory`); no Calipic account, no backend. With iCloud off, a reinstall may grant the free credit again; that leak is accepted. Design spike before P6.
8. **Where the price is visible:** the App Store listing ("First photo free, then USD 0.99 per photo"); once in preflight after the free credit is used; the confirmation sheet; Settings. Never a countdown, "limited offer", or upsell after success.

### Evidence

Founder decision 2026-11-11; BD-029, ADR-014, ADR-015, FR-096, FR-098, constitution rule 11, [21 §3](21-user-journeys.md).

### Alternatives considered

Credit per sheet (penalizes families); free edits after unlocking (a bypass: unlock once, then swap the person); credit packs (deferred, see revisit trigger); subscription (rejected by BD-029).

### Consequences

Needs: a StoreKit consumable, a credit ledger with reserve, commit, and release, the confirmation sheet (S-18), restore in Settings, the export gate (ADR-049), and App Review notes explaining the free photo. A six-person sheet costs six credits (USD 5.94, or USD 4.95 when one is the free photo); the total appears before anything is spent (J2). Screenshot protection of locked previews is decision D-9.

### Revisit trigger

Beta testers misunderstand what a credit covers or regret the point of no return; the packs below do not make a family sheet feel fairly priced.

### Amendment (founder, 2026-11-12): credit packs, credits on screen, unlock in place

Decided with design round 2 ([explorations](ui/explorations/README.md): 3b, 4a, 5d).

1. **Packs replace the single price (§1).** A new person starts with **1 credit**. More credits are StoreKit consumables in three packs; local prices follow Apple's equalization.

   | Pack | Reference price | Per credit |
   |---|---|---|
   | 1 credit | USD 0.99 | USD 0.99 |
   | 5 credits | USD 3.99 | USD 0.80 |
   | 10 credits | USD 6.99 | USD 0.70 |

2. **The app speaks in credits, not money (§4, §8).** Cost and balance appear as credits everywhere: "1 photo · 1 credit", "You have 1 credit". A money amount appears in one place only: the **Credits** screen, beside the pack being bought, using StoreKit's localized price. The App Store listing still states the prices. No price in preflight.
3. **Unlock in place, no confirmation sheet (§4; design 5d).** The Print and Digital Photo screens show an unlock card while a photo is locked: the number of photos to unlock, the cost in credits, the point-of-no-return sentence (*Includes the digital photo and any number of prints. After this, framing and edits are final.*), and the balance. Actions: **Unlock and Print** (or **Unlock and Save**) and **Keep Editing**. With too few credits, the primary action becomes **Get Credits** and opens the Credits screen; the work stays intact. S-18 is no longer a separate confirmation sheet; it is the unlock card plus the Credits screen.
4. **The balance is always one tap away:** a credits button at the bottom of Home and a row in Settings, both opening Credits.
5. **Editing after unlocking (§5) asks first:** *This photo is final. Editing it locks it again. The changed photo will use another credit.* Going ahead relocks the photo; nothing is charged until it is output again.
6. **Unchanged:** what a credit unlocks (§2), when it is spent (§3), integrity (§6), the free credit and restore (§7), no subscription, no ads, no countdowns or upsell after success.

A six-person sheet now needs the starting credit plus one pack of five (USD 3.99), instead of USD 4.95.

**Open points:** the unlock card does not repeat the open warnings from Photo Check, which §4 asked the confirmation sheet to show; decide with beta feedback whether the card needs them. Changing the document relocks every photo (the photo is a different product), and the app does not warn about that yet.

**State in spike 0.16.0:** the ledger, packs, unlock card, Credits screen, relock-on-edit, and the export gate for print and digital files are built. StoreKit is not connected: a pack is added without payment and the screen says so. Credits are spent immediately rather than reserved and committed, and the unlocked state lasts only until the app closes, because drafts (ADR-049) are not built.

---

## ADR-049 — Drafts and locked export

**Status:** Accepted (founder, 2026-11-11), including capture protection of locked previews (D-9). Supersedes ADR-021.
**Date:** 2026-11-11

### Context

People come back to finish later, add a family member, or print more copies. The founder decided drafts are saved without spending credits, and a draft must not become a usable file without a credit, with no bypass.

### Decision

1. **Drafts:** every person in progress is saved automatically on the device: source photo, edit recipe, profile, and lock state, plus the sheet that contains them. Home shows **Continue** with open drafts and unlocked photos. There is no photo gallery.
2. **Storage and retention:** app-private storage with complete file protection, excluded from device and iCloud backups, never visible in the Files app. Deleted after **30 days without use** (proposed default), or immediately with **Delete** on a draft or **Delete all** in Settings. Unlocked photos follow the same rules; free reprints last as long as the draft exists.
3. **One export gate:** every path that can take a photo out of the app goes through one export service: digital JPEG, sheet PDF, page JPEG, AirPrint, share sheet, Save to Photos, copy, drag and drop, context-menu actions, App Intents or Shortcuts results, and Quick Look. The service refuses to render a locked person. An unlock is bound to the draft ID and a hash of its render recipe, so changing the photo invalidates it (ADR-048 §5). Views hide output actions for locked people, but enforcement lives in the export service, not in views.
4. **Locked previews:** rendered at display resolution only; no copy, drag, share, or context-menu save. Drafts store the source and recipe, never a finished full-resolution output.
5. **Tests:** an export-gate test enumerates every output path and proves a locked person cannot leave the app through any of them (L19-012).

### Capture protection (D-9, founder, 2026-11-11)

Locked previews are protected from screenshots and screen recording, the way banking and private-messaging apps protect their content. iOS has no public API for this. The common technique hosts the content inside the layer of a secure text-entry field, which the system leaves blank in captures. It is undocumented, reported unstable in an iOS 17 beta ([Apple forum](https://developer.apple.com/forums/thread/736112)), and App Review guideline 2.5.1 asks that APIs be used for their intended purpose ([Apple forum](https://developer.apple.com/forums/thread/792624)). Therefore:

1. **Device spike first** (L19-017), on iOS 26 and 27, on physical devices. The technique does not work in Simulator. **Result 2026-11-11:** works on iOS 27.2 (iPhone 15 Pro Max); iOS 26 still to check.
2. **Fallback that uses public API:** hide locked previews while the scene reports it is being captured (`UITraitCollection.sceneCaptureState`, `UIScreen.isCaptured`): recording, mirroring, AirPlay. Screenshots can only be detected after the fact (`userDidTakeScreenshotNotification`); use that to explain calmly, never to blame.
3. **Unlocked photos are not protected.** The person paid, and App Store marketing screenshots use unlocked photos.
4. **Residual leak, accepted:** a photo of the screen taken with another camera.

No watermark is needed (FR-098).

### Consequences

Doc 08 and the in-app privacy text must say that face photos stay on this iPhone as drafts until deleted or after 30 days without use. App Store privacy answers do not change: nothing is collected. Relaunch, low storage, and locked-device file protection need tests. Resolves D-4.

### Revisit trigger

Testers expect drafts on a new phone (backups), or want a different retention period.

---

## ADR-050 — Accessibility scope for 1.0

**Status:** Accepted (founder, 2026-11-11). Narrows ADR-030 and AGENTS.md §6 for 1.0; BD-034 stands as written.
**Date:** 2026-11-11

### Context

ADR-030 and AGENTS.md §6 made full accessibility part of every feature's acceptance. The founder decided accessibility is not a priority before launch.

### Decision

1. **Kept for 1.0** (mostly free with native SwiftUI, and clearer for everyone): system controls and text styles; a name on every icon-only button; status shown with a word or symbol, never colour alone; Reduce Motion respected by custom animations; existing accessible features stay (Move/Zoom buttons, spoken camera guidance, accessibility actions already built).
2. **Deferred until after 1.0:** VoiceOver and Voice Control end-to-end journeys (J8), accessibility audits as a release gate (Epic 15), layouts tuned for accessibility text sizes, recruiting assistive-technology users, and non-gesture equivalents for new features (for example S-11 *Fix the edges*).
3. Accessibility no longer blocks a phase gate in [23](23-launch-roadmap.md). A regression of a kept item is still a defect.

### Consequences

- App Store accessibility declarations list only what has actually been checked.
- The European Accessibility Act can apply to in-app sales as an e-commerce service; micro-enterprises are exempt from its service requirements. Confirm Calipic's status before EU launch.
- Persona Daniel (J8) and the accessibility audience in [20 §3](20-product-blueprint.md) move to post-launch.

### Revisit trigger

After 1.0; App Review or legal requirements; reviews or support contacts from people who cannot complete the task.

---

## ADR-051 — Background and tone editing on every profile; search-based profile evidence

**Status:** Accepted (founder, 2026-11-11). Supersedes the alteration gating in ADR-037 and ADR-038 for official profiles.
**Date:** 2026-11-11

### Context

Profile research ([profiles](profiles/README.md)) found the following official wording on editing:

- the US State Department does not accept photos changed with software, apps, filters, or AI;
- the UK requires photos "unaltered by computer software";
- Japan's My Number card says edited images "may not be accepted";
- Spain and the Japanese passport say nothing.

travel.state.gov also refuses automated reading, so official wording was gathered through domain-restricted search.

### Decision

1. Calipic offers **background replacement and Document Tone on every profile**, official ones included, with the current defaults. Each profile document records the official editing wording as reference, but it does not switch features on or off.
2. **Original** background and tone stay one tap away in Adjust, as today.
   - **Honest editing (founder, 2026-11-11; spike 0.15.0):** the background is replaced only when the real wall fails the app's background check.
   - When a document's official rules ask for an unedited photo and Calipic changed something, Photo Check says so in one line and offers **Use Original Photo** ([26 D4](26-ux-design-challenge.md)).
3. **Evidence standard:** profile research based on official pages found through search counts as sourced for the [01 §15](01-product-definition.md) release gate. Browser confirmation is optional, not required.

### Consequences

- **Risk the founder accepts:** authorities that check for editing, such as the US State Department, which says it checks every photo, may reject an edited photo.
- Watch support contacts and one-star reviews for rejections. *Ready* still never means guaranteed acceptance (AGENTS.md §11).
- L19-019 (background and light checks) drops to P1: capture quality still matters, but replacement covers most walls.

### Revisit trigger

Beta testers or reviews report rejections attributed to edited backgrounds or tone.

---

# Open decisions before production implementation

Immediate M1 decisions:

1. ADR-003 — exact Vision face observations/thresholds.
2. ADR-004 — segmentation/refinement implementation details.
3. ADR-005 — final PDF/Core Graphics implementation.
4. ADR-024 — minimum iOS version.
5. ADR-034 — final AVFoundation camera architecture.
6. performance/memory budgets derived from device measurements.
7. ADR-036 to ADR-042 — print composer, background colour policy, Document Tone, alignment estimator, revision pinning, iterative segmentation, Foundation Models boundary (from [the priority feature plan](14-priority-feature-plan.md)).

Product decisions taken by the founder on 2026-11-11: ADR-017 (children), ADR-020 (measurement), ADR-047 (worldwide launch; 35-country list confirmed; no new languages for Wave A), ADR-048 (pricing), ADR-049 (drafts and capture protection), ADR-050 (accessibility scope).

Product decisions still open (see [the product blueprint §8](20-product-blueprint.md)):

Also decided 2026-11-11: mainland China excluded (D-10); the first 13 Wave A profiles in [25 §3](25-wave-a-document-types.md) approved (D-11); custom size without a country accepted (ADR-018); Spanish and Portuguese (Brazil) kept in 1.0 (D-12).

Still open:

1. ADR-032 — whether optional Foundation Models capability earns a place in MVP/P1.

# Decision template

```markdown
## ADR-XXX — Title

**Status:** Proposed | Accepted | Rejected | Superseded | Deferred  
**Date:** YYYY-MM-DD

### Context

What problem/constraint requires a decision?

### Decision

What are we choosing?

### Evidence

Benchmarks, user research, Apple documentation, prototypes, source links, test results.

### Alternatives considered

What credible alternatives were evaluated?

### Consequences

What becomes easier/harder? What new work or constraints follow?

### Revisit trigger

What evidence/event should cause reconsideration?
```
