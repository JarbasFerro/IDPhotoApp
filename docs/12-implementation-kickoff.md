# 12 — Implementation kickoff

**Date:** 2026-09-15  
**Status:** M1 implementation started on 2026-09-16. Spain foto carnet scope and first physical test device confirmed; Xcode 27 verified. See [the first spike report](spikes/01-import-crop-export.md).

## 1. Starting point

The repository began with specifications and an ordered backlog. It now includes a disposable native application and tests in `Spikes/IDPhotoSpike/`; production scaffolding remains pending M1 evidence. Native Swift/SwiftUI, on-device processing, deterministic output, and privacy/accessibility requirements are already established. We should turn those decisions into small, verifiable deliveries.

This document operationalizes [the delivery plan](06-delivery-plan.md) and [backlog](09-backlog.md). It does not replace [AGENTS.md](../AGENTS.md) or accept unrelated proposed ADRs. The user-confirmed launch scope is recorded in ADR-016. Production implementation remains gated on M1 feasibility evidence.

### Local environment verified

| Item | Observed state |
|---|---|
| Checkout | `main`, cloned from `JarbasFerro/IDPhotoApp`; initial HEAD `c493a77` |
| macOS | 26.6.2, Apple Silicon |
| Default developer directory | `/Library/Developer/CommandLineTools` |
| Xcode | Verified 2026-09-16: 27.0, build 27A266a, at `/Applications/Xcode.app`; license/first-run setup completed by the user |
| Locally observed iOS SDK | iOS 27 SDK; iOS 26.5 and 27 simulator runtimes available |
| First physical test device | User-provided iPhone 15 Pro Max, iOS 26.6.2; pairing/signing and device launch not yet verified |

Use a per-command developer directory to access installed Xcode without changing the Mac's global selection:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version
```

Apple's [SDK and system requirements](https://developer.apple.com/xcode/system-requirements), checked on 2026-09-15, list Xcode 27 with Swift 6.4, iOS 27 SDK, and macOS 26.6 or later. Existing references to Xcode 27 being beta are stale. Reconcile those references when recording the selected build toolchain; retain Swift 6 language mode and the proposed iOS 26 minimum pending ADR-024 evidence.

Xcode 27 is now verified and selected per command through `DEVELOPER_DIR`. The prototype targets iOS 26 and compiles with the iOS 27 SDK. Completing the planned iOS 27 refinement evaluation still needs its own API experiments and physical-device evidence. Record the exact compiler, SDK, OS, and build for every result; do not infer them from the standalone `swift` command.

## 2. Product inputs and working proposals

| Decision | Confirmed input or working proposal | Needed before |
|---|---|---|
| Launch jurisdictions/documents, ADR-016 | Confirmed: Spain, foto carnet, 32 × 26 mm in portrait (width 26 mm, height 32 mm). DNI is the initial official research reference | Profile validation and publication |
| Test hardware | Confirmed: iPhone 15 Pro Max / iOS 26.6.2 for first benchmarks. Additional device classes and iOS 27 coverage remain to be arranged | Full physical M1 conclusions |
| Child/baby support, ADR-017 | Adult scenarios first in the prototype; launch coverage remains per-profile and evidence-based | Launch scope lock |
| Custom sizes, ADR-018 | Use explicitly nonofficial test profiles in the harness; defer the public custom-size feature decision | Production scope lock |
| Monetization, ADR-015 | Keep payment integration outside the initial feasibility work | Release business model and StoreKit work |
| Test fixtures | Synthetic geometry images plus appropriately licensed/consented face fixtures | Vision quality benchmarks |

Launch format and the first device are confirmed user inputs; the other scope choices remain proposals. See [Spain profile research](13-spain-foto-carnet.md) for sourced requirements and explicit unknowns. Synthetic geometry fixtures can validate rendering, but cannot alone establish real-world face-analysis or segmentation quality.

## 3. First implementation batches

Each row is a reviewable batch, potentially split into smaller PRs. IDs refer to the existing backlog. These are proposed deliveries, not GitHub issues already created.

| Order | Scope and backlog mapping | Deliverable and acceptance evidence |
|---|---|---|
| 1 | Toolchain and disposable harness — S1-001 | `Spikes/IDPhotoSpike/` SwiftUI Xcode project, Swift 6 strict concurrency, shared scheme, test target, minimal privacy manifest and String Catalog, reproducible build instructions. Record simulator build/test separately from the required physical-device launch. |
| 2 | Ingest and exact render — S1-003, S1-009 | PhotosPicker → private immutable source → bounded analysis/preview → explicit crop → JPEG. Reopen output to verify dimensions, orientation, format, and stripped sensitive metadata. Cover 24/48 MP inputs, cancellation, malformed files, color handling, and cleanup. |
| 3 | Camera — S1-002 | AVFoundation preview and still capture into the same ingest path. Verify point-of-use permission, denial/restriction, orientation/mirroring, interruptions, repeated entry/exit, and capture quality. Record first-frame/shutter latency and device memory/thermal evidence. |
| 4 | Face analysis — S1-004, S1-005 | Fixture benchmark harness, normalized coordinate mapping, reliability report, and explicit manual/advisory limits. Do not equate a face bounding box with an official crown-to-chin measurement. |
| 5 | Segmentation — S1-006, S1-007; S1-008 if justified | Automatic masks and a safe correction/retake path, with edge-quality rubric and fixture review. Evaluate iOS 27 refinement separately with iOS 26 fallback. Original background remains available; replacement must respect profile policy. |
| 6 | Accessible crop and PDF — S1-011, S1-010 | Crop gestures plus move/zoom controls usable with VoiceOver/Voice Control. Generate a dimensioned PDF from known geometry; verify page/photo sizes numerically and physically at 100% scaling with recorded tolerance. |
| 7 | Feasibility review — S1-014, S1-015, S1-016 | Device benchmark report, justified budgets, limitations/fallbacks, and evidence-backed updates to ADR-003/004/005/024/034. Review reusable prototype code explicitly before promotion. |

Rows 2–6 share the harness and image contracts; they need not become a single large prototype change. Profile research can proceed alongside them. App Intents remain a small P1 proof; optional Foundation Models work remains outside the critical path.

### First demonstrable result

Using a clearly labeled engineering test profile with width 26 mm and height 32 mm, import a fixture, preserve its source, show an adjustable portrait crop, export a JPEG, and verify the generated file. Follow with a PDF placing each photo at exactly 26 × 32 mm; measure the physical print at 100% scaling. This is an engineering demonstration, not an official-compliance feature or the complete MVP. Camera, segmentation, print, and accessible editing remain required feasibility work.

### Evidence recorded for every spike

- Question being tested and the relevant backlog acceptance criteria.
- Commit, Xcode/compiler/SDK, device model, OS build, and fixture IDs.
- Reproduction commands and manual steps; fixture licensing/storage instructions.
- Correctness results, latency distribution, peak memory, repeated-run/thermal observations where relevant, and known limitations.
- Decision: adopt, revise, defer optional capability, or unresolved; next action and affected ADR.

Proposed report location: `docs/spikes/`. Never include private photos, landmark arrays, sensitive paths, or identifiers in committed reports or logs. Do not set performance numbers without device evidence, or mark hardware criteria complete from simulator results.

## 4. Production sequence after M1

Keep the logical boundaries in [the architecture](03-architecture.md); start with one application project and folders, adding packages only when a boundary needs enforcement.

1. **M2 — Foundation:** application and test targets, shared build scheme/CI, Observation workflow model, typed dependencies, cancellation/revision identity, private-file lifecycle, privacy declarations, and localization/accessibility foundations.
2. **M3 — Pipeline:** promote reviewed acquisition/analysis/segmentation/rendering implementations behind narrow adapters. Preserve originals; distinguish analysis, preview, and export resolutions.
3. **M4 — One sourced profile end to end:** implement catalog validation, explicit units/coordinates, crop solver, and four-state rule evaluation. Research requirements early enough to guide M3 contracts. Complete one official workflow before expanding the catalog.
4. **M5 — Core interaction:** profile selection → requirements → capture/import → checks → correction → export, with cancellation, errors, permission recovery, and equivalent accessible actions.
5. **M6 — Export/print:** profile-driven JPEG/PNG and PDF sheets, native sharing/printing, output reinspection, physical print verification, and temporary-file cleanup after consumers finish.
6. **M7–M8 — Release:** full device/accessibility/privacy regression, the Spain profile, TestFlight usability, final provenance audit, and App Store preparation under the existing release gates.

Do not estimate a release date until device access is operational and M1 findings are known. Estimate each implementation batch after its inputs are available.

## 5. Correctness decisions to resolve before code hardens

- **Background policy representation:** the illustrative JSON uses `replacementAllowed: false`, while the rules design specifies `allowed | disallowed | unknown`. Use an explicit three-state policy in the implemented schema; unknown must not silently authorize replacement. Finalize in M4 schema work with source provenance.
- **Measurement semantics:** crown, hair extent, chin, and face bounds are distinct. Hard compliance checks require evidence for the exact measurement definition; uncertain or subjective checks remain advisory/manual.
- **Early rule contracts:** M3 needs typed output/composition inputs even though the complete catalog/evaluator lands in M4. Use labeled test profiles during feasibility; never ship illustrative values as official requirements.
- **M1 dependency wording:** S1-016 currently depends broadly on S1-002 through S1-015, including optional work. When activating tickets, clarify that P1/P2 experiments may have a documented defer outcome, while required camera, Vision, rendering, PDF, accessibility, and device evidence still gate production.
- **Async invalidation:** changing the image, profile, or edits invalidates older results. Cover both cancellation and late callbacks in tests before integrating the workflow.
- **Export lifetime:** retain shared files long enough for system consumers, then clean up; test cancellation, backgrounding, relaunch cleanup, and failure paths.

## 6. Immediate next task

The user's post-spike priorities (custom paper, optimized multi-photo sheets with bleed and cut marks, background replacement, automatic tone, face/eye alignment, iOS 26/27 adoption) are planned in [the priority feature plan](14-priority-feature-plan.md), which adds spikes S1-017 to S1-021 and ADR-036 to ADR-042. S1-019 (print composer) is implemented in the spike app with simulator evidence on iOS 26.0 and 27.0 ([spike 02](spikes/02-print-composer.md)); its physical print measurement is the next hardware task. S1-017 (face alignment) is implemented with macOS Vision evidence on five private portraits ([spike 03](spikes/03-face-alignment.md)); S1-018 (segmentation and white background) is implemented with macOS Vision evidence on eight private portraits ([spike 04](spikes/04-background-replacement.md)); the guided camera (S1-020) is implemented in version 0.5.0 ([spike 05](spikes/05-guided-camera.md)) with first device timings recorded; Document Tone (S1-021) is implemented in version 0.6.0 ([spike 06](spikes/06-document-tone.md)); several people per sheet in the UI landed in version 0.7.0 ([spike 02 addendum](spikes/02-print-composer.md)). The iOS 27 tap-to-refine path waits for an iOS 27 device; the physical print measurement and the M1 device baseline are the next hardware tasks. Capture aids landed in 0.8.x. The [experience plan](15-experience-plan.md) is under way: stage A (four-step flow, Spanish and English) shipped as 0.9.0 and stage B (moments) as 0.10.0; stages C (look) and D (ease and reach) follow, then promotion to the M2 production project.

The disposable harness and import/crop/export prototype are implemented; see [run instructions](../Spikes/IDPhotoSpike/README.md) and [validation results](spikes/01-import-crop-export.md). Complete physical launch on the iPhone 15 Pro Max / iOS 26.6.2, record performance, and proceed with the camera/Vision spikes. Broader physical-device coverage and the full M1 exit gate remain pending.

Spain foto carnet research has started with DNI as the first official reference; record source review and remaining unknowns before publishing an official profile. Full production scaffolding follows M1 exit evidence, as required by the existing implementation contract.
