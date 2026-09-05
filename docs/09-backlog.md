# 09 — Ordered implementation backlog

## 1. How to use this backlog

This is the initial execution order, not an immutable feature wishlist. Convert items into GitHub issues when active development starts. Keep issue acceptance criteria linked to the stable requirement IDs in `02-requirements.md`.

Priority:

- **P0** — required for viable MVP/release.
- **P1** — strong MVP target.
- **P2** — post-MVP or optional.

Size is relative effort/risk, not calendar time:

- **S** — small/self-contained.
- **M** — moderate.
- **L** — large/cross-cutting.
- **XL** — research-heavy or architectural.

Dependencies are written as backlog IDs.

---

# EPIC 0 — Product and planning lock

## P0-001 — Review and approve MVP scope — P0 / S

Deliverable:

- reviewed `01-product-definition.md`;
- explicit launch/non-goal list;
- unresolved questions moved to `10-decisions.md`.

Done when scope is clear enough that M1 spikes cannot be invalidated by a basic product misunderstanding.

## P0-002 — Select launch rule-research shortlist — P0 / M

Choose a deliberately small first set of high-demand jurisdictions/document profiles.

Acceptance:

- each candidate has identifiable authoritative sources;
- list covers at least one digital-output workflow and one physical-print workflow where practical;
- child/baby support scope is explicitly included or deferred by profile.

## P0-003 — Define compliance wording — P0 / S

Create approved product language distinguishing “measurable checks passed” from “government acceptance guaranteed.”

Acceptance:

- wording exists for Ready, Needs review, Retake recommended, and manual checks;
- no screen may use stronger compliance language without a decision update.

## P0-004 — Decide monetization constraints for MVP — P1 / S

Lock whether MVP is free, paid, freemium, or technically prepared but not monetized.

Guardrails from product definition remain mandatory.

---

# EPIC 1 — Technical feasibility (M1)

## S1-001 — Bootstrap disposable Flutter spike app — P0 / M

Dependencies: P0-001.

Build a non-production spike supporting iOS and Android.

Acceptance:

- runs on physical device on both platforms;
- no production architecture assumed yet;
- results documented before code is promoted/discarded.

## S1-002 — Camera and import spike — P0 / L

Dependencies: S1-001.

Test:

- camera capture;
- native photo picker;
- limited permission behavior;
- orientation normalization;
- HEIC/JPEG/common inputs;
- large source photos;
- save/share output.

Capture latency, peak memory, and known platform differences.

## S1-003 — Face detector benchmark harness — P0 / L

Dependencies: S1-001.

Create a harness that runs candidate detectors against fixture metadata and exports comparable results.

Acceptance:

- same test set can benchmark each candidate;
- output records face count, normalized geometry, landmark support, runtime, error state;
- no private fixture images committed.

## S1-004 — Benchmark candidate face detectors — P0 / XL

Dependencies: S1-003.

Acceptance:

- comparison report;
- candidate selected or explicit additional test needed;
- hard-rule landmark limitations documented.

## S1-005 — Segmentation benchmark harness — P0 / L

Dependencies: S1-001.

Acceptance:

- comparable visual/quantitative outputs;
- timing and memory capture;
- model/version identified.

## S1-006 — Benchmark candidate segmenters — P0 / XL

Dependencies: S1-005.

Evaluate difficult edges and diverse scenarios from test strategy.

Acceptance:

- selected implementation/fallback;
- known unsupported scenarios documented;
- decision records privacy/network behavior.

## S1-007 — Deterministic geometry/export spike — P0 / L

Dependencies: S1-001.

Acceptance:

- known source + parameters yield exact expected output dimensions/crop;
- mm/inch/pixel conversions unit-tested;
- rounding policy proposed.

## S1-008 — PDF print spike — P0 / L

Dependencies: S1-007.

Acceptance:

- generated PDF has exact intended page dimensions;
- representative photo physically measured after actual-size printing;
- selected PDF library/approach documented.

## S1-009 — Accessible editor interaction spike — P0 / M

Dependencies: S1-001.

Prototype:

- drag/pinch;
- move/zoom buttons;
- guide overlays;
- VoiceOver/TalkBack semantics.

## S1-010 — Establish device/performance baseline — P0 / M

Dependencies: S1-002, S1-004, S1-006.

Record performance budgets and minimum practical device/OS assumptions.

## S1-011 — Lock ADR-001 through ADR-005 — P0 / M

Dependencies: S1-002 through S1-010.

Update `10-decisions.md` with evidence and accepted choices.

---

# EPIC 2 — Production foundation (M2)

## F2-001 — Bootstrap production app — P0 / M

Dependencies: S1-011.

Acceptance:

- clean production Flutter project if ADR-001 accepted;
- application/bundle identifiers configured;
- iOS/Android launch on physical devices;
- README updated with local setup.

## F2-002 — Configure strict static analysis/linting — P0 / S

Dependencies: F2-001.

## F2-003 — Establish module/folder boundaries — P0 / M

Dependencies: F2-001.

Create domain/application/infrastructure/feature structure from architecture doc.

## F2-004 — Add core result/error model — P0 / M

Dependencies: F2-003.

Implement typed application errors and user-safe mapping boundaries.

## F2-005 — Add localization infrastructure — P0 / M

Dependencies: F2-001.

Acceptance:

- no production strings hard-coded in screens;
- English baseline;
- pseudo/long-string test path documented.

## F2-006 — Add design tokens/theme shell — P0 / M

Dependencies: F2-001.

Typography, spacing, radius, status semantics, light/dark strategy if supported.

## F2-007 — Add navigation shell — P0 / M

Dependencies: F2-001.

No final UI required; routes reflect intended workflow.

## F2-008 — Add settings persistence abstraction — P0 / M

Dependencies: F2-003.

Store only non-sensitive baseline settings.

## F2-009 — Configure CI — P0 / L

Dependencies: F2-001, F2-002.

Checks:

- formatting;
- static analysis;
- unit tests;
- rule validator once available;
- Android debug build;
- iOS build where runner/signing constraints allow.

## F2-010 — Add dependency review record/process — P1 / S

Create lightweight documentation/template for third-party package adoption.

---

# EPIC 3 — Domain geometry and image job model

## D3-001 — Implement coordinate-space value types — P0 / L

Dependencies: F2-003.

Types/conversions for source pixels, normalized image space, output pixels, physical mm, PDF points.

## D3-002 — Implement physical-unit conversion and rounding — P0 / M

Dependencies: D3-001.

Boundary/unit tests mandatory.

## D3-003 — Implement aspect/crop primitives — P0 / L

Dependencies: D3-001.

## D3-004 — Implement `PhotoJob` domain model — P0 / M

Dependencies: F2-003.

Source remains immutable; edits parameterized.

## D3-005 — Implement `EditParameters` — P0 / M

Dependencies: D3-004.

## D3-006 — Implement validation-state model — P0 / M

Dependencies: F2-004.

`pass / warn / fail / manual_check` plus overall derivation.

## D3-007 — Implement print-grid geometry engine — P0 / L

Dependencies: D3-002.

Tests packing, margins, gutters, page orientations, copy counts.

---

# EPIC 4 — Image acquisition and normalization (M3)

## I4-001 — Define image acquisition port — P0 / S

Dependencies: F2-003.

## I4-002 — Implement camera adapter — P0 / L

Dependencies: I4-001, ADR choices.

Permission timing and error recovery included.

## I4-003 — Implement native photo-picker adapter — P0 / M

Dependencies: I4-001.

## I4-004 — Implement image header/type validation — P0 / M

Dependencies: I4-002/I4-003.

## I4-005 — Implement orientation normalization — P0 / L

Dependencies: I4-004.

## I4-006 — Implement bounded analysis decode — P0 / L

Dependencies: I4-005.

## I4-007 — Implement source/temp-file lifecycle — P0 / L

Dependencies: I4-001, privacy policy.

Acceptance:

- private locations;
- cleanup;
- no source overwrite;
- stale-cache cleanup strategy.

---

# EPIC 5 — Face and quality analysis

## A5-001 — Define domain-neutral face detector port — P0 / S

Dependencies: D3-001.

## A5-002 — Implement selected detector adapter — P0 / L

Dependencies: A5-001, S1-011.

## A5-003 — Normalize detector geometry — P0 / M

Dependencies: A5-002.

Convert immediately into domain coordinate types.

## A5-004 — Implement no-face/multiple-face states — P0 / M

Dependencies: A5-002.

## A5-005 — Implement source resolution check — P0 / M

Dependencies: D3-002.

## A5-006 — Implement blur/sharpness check — P0 / L

Dependencies: benchmark/calibration plan.

## A5-007 — Implement exposure check — P0 / L

## A5-008 — Implement pose/rotation advisory — P1 / L

Only if M1 detector accuracy supports useful warnings.

## A5-009 — Build analysis orchestration use case — P0 / L

Dependencies: A5-002, A5-005, A5-006, A5-007.

Supports cancellation/stale-result rejection.

---

# EPIC 6 — Segmentation/background

## B6-001 — Define segmenter port — P0 / S

## B6-002 — Implement selected segmenter adapter — P0 / L

Dependencies: S1-011.

## B6-003 — Implement mask representation/cache — P0 / L

Dependencies: B6-002, privacy/temp lifecycle.

## B6-004 — Implement background compositor — P0 / L

Dependencies: B6-003.

Must not alter face/foreground outside defined mask blend.

## B6-005 — Implement segmentation uncertainty/failure path — P0 / M

Dependencies: B6-002.

## B6-006 — Implement manual mask correction — P1 / XL

Dependencies: B6-003, UX prototype.

## B6-007 — Add segmentation regression fixture suite — P0 / L

Dependencies: B6-004.

---

# EPIC 7 — Rules engine (M4)

## R7-001 — Define canonical JSON Schema — P0 / L

Dependencies: P0-002, D3-002.

## R7-002 — Implement schema validator — P0 / M

Dependencies: R7-001.

## R7-003 — Implement semantic validator — P0 / L

Dependencies: R7-001.

## R7-004 — Implement typed rule loader — P0 / L

Dependencies: R7-001, F2-005.

## R7-005 — Implement provenance model — P0 / M

Dependencies: R7-001.

## R7-006 — Implement evaluator registry — P0 / L

Dependencies: D3-006, R7-004.

## R7-007 — Implement output-dimension evaluator — P0 / M

Dependencies: R7-006.

## R7-008 — Implement head-size evaluator — P0 / L

Dependencies: R7-006, A5-003.

## R7-009 — Implement head-position/centering evaluator — P0 / L

Dependencies: R7-006, A5-003.

## R7-010 — Implement resolution evaluator — P0 / M

Dependencies: R7-006, A5-005.

## R7-011 — Implement manual-check rules — P0 / M

Dependencies: R7-006.

## R7-012 — Implement background policy rule — P0 / M

Dependencies: R7-006, B6-004.

## R7-013 — Implement automatic crop solver — P0 / XL

Dependencies: D3-003, R7-008, R7-009.

Must produce diagnostics when constraints are infeasible.

## R7-014 — Add initial official profiles — P0 / XL

Dependencies: R7-001 through R7-013, P0-002.

One profile is not “done” until provenance and fixtures pass.

## R7-015 — Add rules validation to CI — P0 / M

Dependencies: R7-002, R7-003.

---

# EPIC 8 — Renderer and editor

## E8-001 — Implement preview renderer — P0 / L

Dependencies: D3-005, B6-004, R7-013.

## E8-002 — Implement high-resolution final renderer — P0 / XL

Dependencies: E8-001, I4-007.

## E8-003 — Implement crop/position gestures — P0 / L

Dependencies: S1-009, E8-001.

## E8-004 — Implement accessible move/zoom controls — P0 / M

Dependencies: E8-003.

## E8-005 — Implement live rule feedback while editing — P0 / L

Dependencies: E8-003, R7-006.

## E8-006 — Implement guide overlays — P1 / M

Dependencies: rule semantics.

## E8-007 — Implement reset/automatic position — P0 / S

Dependencies: R7-013.

## E8-008 — Implement before/after comparison — P1 / M

## E8-009 — Implement limited tonal corrections if approved — P1 / L

Dependencies: explicit decision; otherwise do not build.

---

# EPIC 9 — Main UX (M5)

## U9-001 — Home screen — P0 / M

## U9-002 — Country picker — P0 / M

Dependencies: R7-004.

## U9-003 — Document profile picker — P0 / M

Dependencies: R7-004.

## U9-004 — Requirement summary screen — P0 / M

Dependencies: R7-004, localization.

## U9-005 — Camera/import choice and permission recovery — P0 / M

Dependencies: I4-002, I4-003.

## U9-006 — Analysis/progress state — P0 / S

Dependencies: A5-009, B6-002.

## U9-007 — Photo-check report — P0 / L

Dependencies: D3-006, R7-006.

## U9-008 — Editor screen — P0 / XL

Dependencies: E8-001 through E8-007.

## U9-009 — Export choice — P0 / S

## U9-010 — Source/provenance details — P0 / M

Dependencies: R7-005.

## U9-011 — Settings/privacy/help — P0 / M

## U9-012 — Recent/favourite profiles — P1 / M

Dependencies: F2-008.

## U9-013 — Full error/empty-state pass — P0 / L

Dependencies: primary screens.

## U9-014 — Task-based usability test — P0 / L

Dependencies: U9-001 through U9-013.

Resolve high-severity comprehension/navigation issues before M5 exit.

---

# EPIC 10 — Digital export (M6)

## X10-001 — Define export image codec port — P0 / S

## X10-002 — Implement exact-dimension JPEG export — P0 / L

Dependencies: E8-002.

## X10-003 — Implement PNG export where profiles allow/require — P1 / M

## X10-004 — Implement metadata stripping — P0 / M

Dependencies: X10-002.

## X10-005 — Implement file-size constraint loop — P1 / L

Dependencies: X10-002, rule profiles needing it.

## X10-006 — Implement post-export verification — P0 / M

Dependencies: X10-002.

## X10-007 — Implement native save/share — P0 / M

Dependencies: X10-002.

## X10-008 — Digital export screen — P0 / M

Dependencies: U9-009, X10-006.

---

# EPIC 11 — Print export (M6)

## P11-001 — Define supported paper profiles — P0 / M

Dependencies: D3-007.

## P11-002 — Implement layout packing use case — P0 / L

Dependencies: D3-007.

## P11-003 — Implement PDF generator — P0 / L

Dependencies: S1-008, P11-002, E8-002.

## P11-004 — Implement copy count/orientation — P1 / M

## P11-005 — Implement optional cut guides — P1 / M

## P11-006 — Print setup/preview screen — P0 / L

Dependencies: P11-002, P11-003.

## P11-007 — Add actual-size print warning/instructions — P0 / S

## P11-008 — Physical print validation campaign — P0 / L

Dependencies: P11-003.

Record actual measured results.

---

# EPIC 12 — Privacy, security, and observability

## S12-001 — Implement safe logging facade — P0 / M

Dependencies: F2-004.

## S12-002 — Verify temp-file deletion/backup exclusion — P0 / M

Dependencies: I4-007.

## S12-003 — Verify export metadata stripping — P0 / M

Dependencies: X10-004.

## S12-004 — Decide analytics/crash reporting — P0 / M

Dependency: architecture/privacy review.

Decision can be “none for MVP.”

## S12-005 — Implement privacy-safe telemetry if approved — P1 / L

Dependencies: S12-004.

## S12-006 — Network inspection test — P0 / M

Acceptance: core import/capture/edit/export flow transmits no photo/derived sensitive data.

## S12-007 — Dependency/privacy audit — P0 / M

Run before release and after high-risk SDK changes.

## S12-008 — Add secrets/signing setup documentation — P0 / M

No secrets committed.

## S12-009 — Remote rules signing — P2 / XL

Only if remote catalog updates are included. If not, defer entirely.

---

# EPIC 13 — Accessibility and localization

## L13-001 — Screen-reader primary flow — P0 / L

## L13-002 — Large-text layout pass — P0 / M

## L13-003 — Non-color status audit — P0 / S

## L13-004 — Editor non-gesture controls — P0 / M

Tracked also by E8-004.

## L13-005 — Pseudo-localization stress test — P0 / M

## L13-006 — RTL smoke test — P1 / M

## L13-007 — Add launch languages after translation QA — P1 / L per language set

Language count should not exceed review capacity.

---

# EPIC 14 — Reliability/performance hardening (M7)

## H14-001 — Large-image stress suite — P0 / L

## H14-002 — Memory profiling — P0 / L

## H14-003 — Background/foreground interruption tests — P0 / M

## H14-004 — Cancellation/stale-result tests — P0 / M

## H14-005 — Offline end-to-end test — P0 / M

## H14-006 — Corrupt-input failure injection — P0 / M

## H14-007 — Rules-catalog corruption/version tests — P0 / M

## H14-008 — Performance regression benchmark — P1 / L

Compare to M1 budgets.

## H14-009 — Full supported-device matrix run — P0 / L

## H14-010 — Release candidate defect triage — P0 / L

No release with disallowed open severity.

---

# EPIC 15 — Store/release (M8)

## R15-001 — Finalize product name/brand — P0 / M

Must precede final store assets, bundle-facing naming, privacy/support publication.

## R15-002 — App icons/splash assets — P0 / M

## R15-003 — Privacy policy/support content — P0 / M

Must describe actual shipped behavior, not planned behavior.

## R15-004 — Configure signing/release pipelines — P0 / L

## R15-005 — Configure purchases if applicable — P1 / XL

Depends on monetization decision.

## R15-006 — Store privacy/data-safety declarations — P0 / M

Audit against actual SDK/runtime behavior immediately before submission.

## R15-007 — Store listing/screenshots — P0 / L

## R15-008 — Internal/beta distribution — P0 / M

## R15-009 — Release-candidate acceptance test — P0 / L

## R15-010 — Submit iOS — P0 / M

## R15-011 — Submit Android — P0 / M

## R15-012 — Controlled rollout/monitoring — P0 / M

## R15-013 — Release runbook — P0 / M

Include bad-rule response, crash spike response, store hotfix steps, and support workflow.

---

# EPIC 16 — Post-MVP candidates

These do not enter MVP unless an explicit scope decision changes.

## PM-001 — Signed remote rule catalog — P2 / XL

## PM-002 — Internal rule-authoring tool — P2 / XL

## PM-003 — Additional languages — P2 / L

## PM-004 — Additional jurisdiction waves — P2 / L per wave

## PM-005 — Custom/generic dimension editor — P1/P2 depending MVP decision / L

## PM-006 — Raster print-kiosk export — P2 / M

## PM-007 — Resume/recent photo jobs — P2 / L

Requires privacy/retention UX.

## PM-008 — Optional cloud sync/account — P2 / XL

Requires new privacy/security architecture.

## PM-009 — Business/kiosk/batch mode — P2 / XL

## PM-010 — Printing fulfilment — P2 / XL

---

## 17. Critical dependency chain

The shortest path to a trustworthy MVP is approximately:

```text
P0-001
  ↓
S1 feasibility spikes
  ↓
S1-011 architecture lock
  ↓
F2 foundation
  ↓
D3 geometry + I4 acquisition
  ↓
A5 face analysis + B6 segmentation
  ↓
R7 rules + crop solver
  ↓
E8 renderer/editor
  ↓
U9 complete UX
  ↓
X10 digital + P11 print export
  ↓
H14 hardening + S12 privacy
  ↓
R15 release
```

Do not allow attractive lower-priority features to bypass this dependency chain.

## 18. First issues to create

When issue tracking begins, create these first:

1. `P0-001 Review and approve MVP scope`
2. `P0-002 Select launch rule-research shortlist`
3. `S1-001 Bootstrap disposable Flutter spike app`
4. `S1-002 Camera and import spike`
5. `S1-003 Face detector benchmark harness`
6. `S1-005 Segmentation benchmark harness`
7. `S1-007 Deterministic geometry/export spike`
8. `S1-008 PDF print spike`
9. `S1-009 Accessible editor interaction spike`
10. `S1-011 Lock architecture decisions`

No production feature issue should be marked “ready” until its upstream decision/spike dependencies are closed.
