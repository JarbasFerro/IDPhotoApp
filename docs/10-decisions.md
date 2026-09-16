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

**Status:** Deferred  
**Decision needed:** free, one-time purchase, freemium, subscription for advanced/frequent users, or hybrid.

**Accepted constraints:**

- StoreKit is preferred;
- no surprise watermark;
- no paywall before explaining a photo problem;
- no dark-pattern countdown/interstitial;
- monetization cannot alter rules correctness.

---

## ADR-016 — Initial launch jurisdictions

**Status:** Accepted for initial country and format
**Date:** 2026-09-15

**Decision:** Start with Spain and the user-requested “foto carnet”, 32 × 26 mm in portrait orientation: width 26 mm, height 32 mm. Use DNI as the first official research reference; exact document-compliance claims require a validated, sourced profile.

**Evidence:** User selected Spain/foto carnet as the first-release scope. [Initial source review](13-spain-foto-carnet.md) records the DNI reference and unresolved requirements.

**Consequences:** Deliver this single format end to end before expanding countries or document variants. Shared dimensions alone do not establish equivalence with passport, driving-licence, or residence-card requirements. Child/baby coverage remains governed by ADR-017. Digital export is an app capability, not evidence of an official online-submission channel.

---

## ADR-017 — Child/baby support

**Status:** Proposed  
**Decision:** architecture supports age-related profile exceptions from the start; launch coverage is decided per profile based on official rules and test evidence.

---

## ADR-018 — Generic/custom photo sizes

**Status:** Proposed  
**Decision:** may use the same deterministic renderer but must be visually distinguished from sourced official profiles and make no compliance claim.

---

## ADR-019 — Remote rule updates

**Status:** Deferred  
**Decision:** initial MVP may ship rules with app updates. Architecture must not prevent future signed catalog updates.

If enabled later: signatures, integrity validation, atomic activation, schema/semantic validation, and known-good rollback are mandatory.

---

## ADR-020 — Analytics / crash reporting

**Status:** Deferred  
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

**Status:** Proposed  
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

**Status:** Accepted  
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

# Open decisions before production implementation

Immediate M1 decisions:

1. ADR-003 — exact Vision face observations/thresholds.
2. ADR-004 — segmentation/refinement implementation details.
3. ADR-005 — final PDF/Core Graphics implementation.
4. ADR-024 — minimum iOS version.
5. ADR-034 — final AVFoundation camera architecture.
6. performance/memory budgets derived from device measurements.
7. ADR-036 to ADR-042 — print composer, background colour policy, Document Tone, alignment estimator, revision pinning, iterative segmentation, Foundation Models boundary (from [the priority feature plan](14-priority-feature-plan.md)).

Product decisions that can proceed in parallel:

1. ADR-015 — monetization.
2. ADR-016 — country/format accepted; complete Spain profile source validation before publication.
3. ADR-017 — child/baby launch coverage.
4. ADR-018 — generic/custom size in MVP.
5. ADR-020 — diagnostics/analytics.
6. ADR-032 — whether optional Foundation Models capability earns a place in MVP/P1.

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
