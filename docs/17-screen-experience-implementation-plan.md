# 17 — Screen experience implementation plan

**Status:** In implementation; simulator flow and documentation pass underway, physical-device gates open
**Date:** 2026-09-28
**Inputs:** [screen specification](16-screen-experience-spec.md), [ADR-043](10-decisions.md#adr-043--revised-capture-output-and-adjustment-flow), [test strategy](07-test-strategy.md)

## 1. Outcome and scope

Turn the screen specification into an implementable contract and then update the iPhone spike to match it. This plan covers the seven gaps found in the review: current-versus-target clarity; designed exceptional states; complete copy/control inventory; capture and output flow; conflicting design directions; profile provenance; and visual/acceptance evidence.

The current `Spikes/IDPhotoSpike` app remains the implementation target. This is a UI/workflow change, not a rewrite of deterministic geometry, rule evaluation, or image rendering. Keep native SwiftUI controls, the immutable source, revision-based stale-result protection, on-device processing, and system share/print surfaces.

### Progress on 2026-09-28

| Item | Implemented or recorded | Remaining acceptance |
|---|---|---|
| 1. Current versus target | Spec §1 ledger and screen contracts | Keep ledger current as the spike evolves. |
| 2. Exceptional states | Camera recovery, import retry, digital export retry, and status text improvements | Complete the per-screen state matrix and controlled triggers for every branch. |
| 3. Copy/control inventory | Spec §17 and Spanish/Brazilian Portuguese keys for new screens | Audit all legacy and dynamic check-row variants against the catalog. |
| 4. Revised flow | Preflight, optional camera tip, output choice, direct verified JPEG, existing print route | Physical share lifetime and camera interaction. |
| 5. Document reconciliation | ADR-043, historical note in doc 15, updated doc 04 and spike README | Recheck after the visual pass. |
| 6. Provenance | Current label narrowed to Spain DNI; source link and manual check appear | Move source/review metadata from literal UI copy to versioned profile data before release; verify source freshness. |
| 7. Visual evidence | Layout appendix and named simulator captures | Complete Light/Dark, accessibility text, camera/device, and physical print evidence. |

## 2. Accepted product decisions and implementation defaults

[ADR-043](10-decisions.md#adr-043--revised-capture-output-and-adjustment-flow) records the founder's five choices:

| Decision | Implementation interpretation |
|---|---|
| Digital Photo and Print Sheet after Photo Check | A short output-choice screen shows two native choices. **Digital Photo** exports the currently checked person directly; **Print Sheet** opens the session composer, where other people may be added. A multi-person digital sharing action can remain available from the result without forcing print setup. |
| Brief requirements before camera or PhotosPicker | Every acquisition entry point passes through one compact preflight summary for the current profile. Its primary action continues to the already chosen source; a secondary action can switch source. Full requirements open within the same navigation presentation, avoiding nested sheets. |
| Native Adjust sheet | Portrait first, scrolling native controls below, Details closed initially. No floating glass cluster over the face. |
| Spain · DNI photo | Use this as the current profile label in Home, preflight, Requirements, Check, and output context. Do not describe the profile as passport-approved until passport rules have separate provenance. |
| Optional camera help | Camera opens directly after preflight; a short one-time optional tip may explain the ring, and the persistent Instructions control opens Help at any time. Auto remains an explicit choice and camera permission stays at point of use. |

These interpretations are routine layout defaults for implementation. Task testing may simplify the output choice or preflight presentation without changing the accepted user outcomes. No other product decision is needed to begin.

## 3. The seven work items

### 1 — Distinguish current UI from target UI

**Documentation:** Refactor `docs/16-screen-experience-spec.md` into a screen index and a repeatable screen template. Each element row gets: identifier, current behavior, target behavior, implementation status, source file, and acceptance evidence. Keep a compact change log at the top. Do not leave unmarked imperative prose that might describe either today's app or a future version. Link the accepted decision in `docs/10-decisions.md`.

**App impact:** None solely for classification. The rows become the work list for later app changes.

**Done when:** A reviewer can select any visible control or state and tell whether it already exists, is changing, or is planned later; every proposed change has a code owner and a check. `README.md` links to the revised spec and this plan.

### 2 — Design exceptional states completely

**Documentation:** Replace the coverage-only matrix in spec §14 with one state table per screen. Each row specifies trigger, visible headline and explanation, main visual, primary/secondary actions, disabled controls, navigation destination, announcement/focus behavior, and how the user recovers. Cover Home startup/import, preflight, camera permission/interruption/failure, picker cancellation and bad files, Photo Check's four result classes, unavailable analysis, Adjust segmentation/tone limits, incomplete/empty sheet, export failure, and print/share cancellation. Distinguish an error from a user cancellation.

**App files:** `Features/AppFlow.swift`, `HomeView.swift`, `PhotoCheckView.swift`, `AdjustSheet.swift`, `SheetView.swift`, new output views, `Camera/CameraView.swift`, `Features/PhotoWorkflow.swift`, and typed error presentation. Keep long-running operations revision-bound; no stale success or alert can replace the current job.

**Done when:** Each state has a useful next action in the spec and a reproducible app fixture or manual trigger. Error routes retain the source photo and edits unless removal was explicitly chosen. Camera denial leads directly to import after dismissal. System share/print cancellation returns to a ready result.

### 3 — Complete the copy and control inventory

**Documentation:** Add an inventory appendix to `docs/16-screen-experience-spec.md`, organized by screen and state. For every visible title, paragraph, button, picker option, hint, badge, error and helper text, record the exact English source copy, `Localizable.xcstrings` key, SF Symbol (if any), role, condition for appearance, destination/action, VoiceOver label/value/hint, and Voice Control name. Include every `CameraPresentation` hint and `CheckPresentation` headline/row variant. If copy is calculated, document its template and formatting inputs rather than a single example number. Clearly mark sourced requirement text and review date.

**App files:** `App/Resources/Localizable.xcstrings`; affected SwiftUI views and presentation mappers. Maintain Spanish and Brazilian Portuguese where those translations already exist. Use Foundation number/measurement styles and plural inflection; do not freeze examples such as “520 × 640” into a rule claim.

**Done when:** A script or review can cross-check each inventoried key against the catalog, all newly shown strings are localized, no control depends on a symbol alone for its name, and a copy reviewer can read the entire flow without opening Swift files. No vague placeholders such as “short explanation” remain in a shipping-state row.

### 4 — Implement the revised capture and output flow

**Documentation:** Redraw the flow in spec §1 and write screen contracts for the new preflight summary, output choice, and direct digital result. Revise Home, Photo Check, Sheet, Share, and camera Help contracts to match ADR-043. Define back behavior, whether a person is selected, how another person is added, and where prepared work remains after Done.

**Navigation and UI:** Add typed routes/presentation state in `Features/AppFlow.swift`. Route every Take/Choose/Retake/Add person entry through one preflight view; preserve its acquisition mode (`replace` or `add`) and selected person. Use a native sheet or pushed destination with no nested modal. Change Photo Check's primary action from **Add to sheet** to **Continue**, leading to a choice with **Digital Photo** and **Print Sheet**. The print route keeps `SheetView`; a direct digital result shows the prepared portrait, output dimensions/format, remaining manual checks, and native ShareLink. Camera Help remains reachable from the live preview; remove the forced two-page gate. Update Home document naming to **Spain · DNI photo**.

**Pipeline:** `PhotoProcessing.export(edits:job:)` currently creates JPEGs, PDF, and page JPEGs together. Introduce a typed export request/result or separate digital/print methods in `Imaging/PhotoPipeline.swift`, and update `Features/PhotoWorkflow.swift` to prepare only the selected output. Reuse the same renderer and post-export verification; do not render a PDF for the digital path. Keep one export lease per result, cancel/discard stale jobs, and retain temporary files until the system share/print activity is finished. Preserve edit state when switching paths. Update protocol fakes and integration tests.

**Done when:** From Photo Check, a person can share a verified JPEG without opening Sheet or generating a PDF; the existing multi-person print path still produces verified PDF/page files; switching paths does not repeat acquisition or lose edits. Permission is requested only after choosing camera. The optional tip cannot block shutter use.

### 5 — Reconcile the design documents

**Documentation:** Keep [ADR-043](10-decisions.md#adr-043--revised-capture-output-and-adjustment-flow) authoritative for the five decisions. Mark `docs/15-experience-plan.md` as historical where its future glass cluster, mandatory intro, and sheet-first flow conflict; update forward-looking sections of `docs/04-ux-ui.md` to describe the newly accepted preflight and output choice. Review `docs/brand/11-design-tokens.md` and `docs/brand/12-voice-and-writing.md` only for changes actually required by the new screens. Keep brand decisions in `docs/brand/99-brand-decisions-log.md` intact unless the product change truly changes an accepted brand rule.

**App impact:** Finish Adjust with native controls below the photo; do not spend time building a floating glass prototype as a default implementation. Prefer a system disclosure and accessible move/zoom actions.

**Done when:** Searching the active planning documents for “glass control cluster,” “mandatory introduction,” and the old sheet-only flow reveals either historical context or an explicit supersession pointer, with no competing active instruction.

### 6 — Make provenance visible and claims narrow

**Documentation:** Audit every mention of “passport,” “official,” “compliant,” “ready,” and background replacement in the spec and copy inventory. For the current profile, show **Spain · DNI photo** and only the sourced dimensions/requirements. Requirements should show the source link, exact last-reviewed date from profile data, relevant exceptions, and an explicit manual-check list. Document what happens when the source is unavailable or the profile review is outdated. Separate print dimensions from an office's decision to accept the photo.

**App files:** `HomeView.swift`/`RequirementsView`, preflight, Check, digital result, `Localizable.xcstrings`, and the eventual versioned profile data. Avoid making country-specific claims in UI code when the rule catalog is introduced. A static display string is acceptable in the spike only until the versioned profile replaces it; document that handoff. Do not expand the rule evaluator based on copy alone.

**Done when:** No active screen labels the current profile “DNI and passport”; every official claim can be traced to an identified rule/source and review date; manual requirements stay visible at Check and before output; no pass state promises acceptance. Source-validation work remains a separate release dependency.

### 7 — Add visual layouts and objective acceptance evidence

**Documentation/artifacts:** For Home, preflight, camera/Help, Photo Check, Adjust, output choice, digital result, Sheet, print result, Requirements, and App Icon, add annotated visual layouts to the screen spec or a linked `docs/ui/` appendix. Show default compact iPhone, large iPhone, accessibility text, and relevant Light/Dark variants. Annotate safe areas, order, portrait/page aspect, action placement, minimum targets, wrapping/scrolling behavior, and which pieces may collapse. Use controlled synthetic fixtures and avoid personal photos. Do not turn system control sizes into fixed pixel mocks; specify constraints and observed results.

**Verification:** Extend `UITests/IDPhotoSpikeUITests.swift` and `BrandContextUITests.swift` for direct digital and print routes, preflight, permission recovery, large text, and VoiceOver labels. Capture named screenshots for the required layouts; add focused visual review for contrast, clipping, hidden controls, and real-photo legibility. Use Swift Testing for typed route/result logic and export request semantics. Run the existing spike suite after each code batch. Test camera guidance on a physical older/current iPhone class, share-file lifetime on device, and print a physical calibration sheet at Actual Size.

**Done when:** Every major screen has an annotated target, a matching captured implementation, a documented review of differences, and no clipping/overlap/inert action at the supported text sizes. UI accessibility audit passes; physical print measurements and camera behavior are recorded separately from simulator evidence.

## 4. Delivery order and gates

| Stage | Work | Gate before moving on |
|---|---|---|
| A. Contract | Items 1, 3, 5, and 6: classify current/target, record exact copy and provenance, reconcile documents. Draft state tables and annotated layouts for the new flow. | No competing active design direction; every new screen has action/state/copy rows; source claims reviewed. |
| B. Flow | Item 4: preflight, optional camera help, output choice, separate digital/print export requests. | Unit/integration tests prove output separation, cancellation, verification, file lifetime, and preserved edits; UI tests complete both paths. |
| C. Screen states | Item 2 plus Adjust, Check, Sheet, Share refinements from the tables. | Each recovery can be triggered and completes; no stale task changes a newer screen; accessibility actions cover crop and list removal. |
| D. Visual finish | Item 7: target layouts, screenshots, appearance and accessibility review, physical device/print checks. | Matched target/implementation evidence; issue list closed or explicitly deferred; no P0/P1 regression under `docs/07-test-strategy.md`. |

Build/test gates occur after each app edit batch, not after a long combined redesign. Do not add tests that merely mirror view code; tests should prove navigation, preserved work, output correctness, recovery, and accessibility. Documentation-only changes use link/catalog checks and review of the affected screen tables. Follow the project's version/tag rules when a build is handed to a physical device.

## 5. Expected files and change boundaries

| Area | Likely files |
|---|---|
| Decisions and contract | `docs/10-decisions.md`, `docs/15-experience-plan.md`, `docs/16-screen-experience-spec.md`, `docs/04-ux-ui.md`, this plan, `README.md` |
| Navigation and new surfaces | `App/Features/AppFlow.swift`, `HomeView.swift`, `PhotoCheckView.swift`, new preflight/output-choice/digital-result views, `Camera/CameraView.swift` |
| Existing surfaces | `App/Features/AdjustSheet.swift`, `SheetView.swift`, `ShareView.swift`, `CheckPresentation.swift` |
| Export lifecycle | `App/Features/PhotoWorkflow.swift`, `App/Imaging/PhotoPipeline.swift`, export/verification fakes and controlled-image tests |
| Language and evidence | `App/Resources/Localizable.xcstrings`, `UITests/IDPhotoSpikeUITests.swift`, `UITests/BrandContextUITests.swift`, new synthetic-fixture screenshots in a documentation-only artifact location |

The production app's broader profile picker, remote rule maintenance, iOS 27 mask refinement, monetization, and optional intelligence remain outside this screen-pass implementation. The new interfaces should accept profile data cleanly later without claiming that those capabilities already ship.
