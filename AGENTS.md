# ID Photo App — Implementation contract

This file defines non-negotiable engineering conventions for human and AI contributors. Read the planning documents before changing production code, especially `docs/03-architecture.md`, `docs/04-ux-ui.md`, `docs/07-test-strategy.md`, `docs/08-privacy-security.md`, `docs/10-decisions.md`, and `docs/11-ios-excellence-strategy.md`.

## 1. Product target

- iPhone / iOS only.
- Native Swift + SwiftUI.
- Build against the newest approved Apple SDK available for the current development/release stage.
- Current deployment proposal: iOS 26 minimum, with iOS 27-only features availability-gated until ADR-024 is finalized.
- Do not introduce Android, Flutter, React Native, web, or other portability layers without a new accepted ADR.

## 2. Native-first rule

Before writing a custom component or adding a dependency, check whether an Apple framework already provides the capability at the needed quality.

Preferred stack:

- SwiftUI
- Observation (`@Observable`)
- Swift Concurrency
- AVFoundation
- PhotosUI / `PhotosPicker`
- Vision
- Core Image
- ImageIO
- Core Graphics
- Accelerate only after profiling demonstrates value
- App Intents / Core Spotlight where useful
- StoreKit for monetization
- Swift Testing + XCUITest
- Instruments / OSLog / OSSignposter

Third-party packages require an ADR or dependency review explaining why Apple APIs are insufficient.

## 3. Swift and concurrency

- Use Swift 6 language mode.
- Keep strict concurrency checking enabled.
- UI-facing mutable state should normally be isolated to `@MainActor`.
- Types crossing concurrency boundaries should be `Sendable` where appropriate.
- Do not add `@unchecked Sendable` to silence compiler errors without a documented proof of safety.
- Propagate cancellation through image-analysis/render tasks.
- Every long-running photo operation must be tied to a job/revision identity so stale results cannot update newer state.
- Avoid `Task.detached` unless actor inheritance is deliberately inappropriate and the reason is documented.
- Do not block the main actor with image decoding, Vision, segmentation, PDF generation, or high-resolution rendering.

## 4. SwiftUI architecture

- Views describe UI and interaction; they do not own document-rule math or image algorithms.
- Use `@Observable` feature/workflow models rather than introducing a third-party state framework.
- Prefer initializer injection and a small typed `AppEnvironment` over global singletons.
- Use SwiftUI `Environment` only for genuinely app-wide dependencies/settings.
- Use `NavigationStack`, system sheets, alerts, confirmation dialogs, search, toolbars, menus, and share experiences unless a documented product need requires otherwise.
- Never build custom controls merely to imitate Apple system controls.

## 5. Current iOS design language

- Standard SwiftUI controls should inherit current system appearance and Liquid Glass behavior from the SDK.
- Do not create an app-wide custom “Liquid Glass” theme.
- Custom glass effects are exceptional and must improve hierarchy or interaction over a standard system solution.
- The photo/content remains visually primary.
- Use system typography, Dynamic Type, semantic colors/materials, and SF Symbols by default.
- Motion and haptics must communicate state or cause/effect; avoid decorative motion/haptic noise.
- Respect Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, light/dark appearance, and accessibility text sizes.

## 6. Accessibility is part of implementation

A critical feature is incomplete if it only works through sight or precision gestures.

For relevant UI:

- provide useful VoiceOver labels, values, traits, focus behavior, and announcements;
- provide Voice Control-friendly names;
- support Dynamic Type around the photo/editor;
- provide non-gesture move/zoom controls for crop adjustment;
- never encode pass/warn/fail/manual state using color alone;
- test Reduce Motion and contrast/transparency settings;
- keep interactive targets forgiving and consistent with current HIG guidance.

Do not defer the accessibility implementation to release hardening.

## 7. Camera and import

- Use AVFoundation for the guided in-app camera.
- Request camera permission only after the user chooses `Take Photo`.
- Use PhotosUI/`PhotosPicker` for normal import; do not request broad Photo Library access merely to select an image.
- Real-time camera analysis runs at intentionally bounded resolution/frequency.
- Live guidance must be actionable, high-confidence, and debounced/hysteretic so it does not flicker.
- Final still capture quality is independent from the lower-cost preview analysis path.
- Instrument camera entry-to-first-frame and shutter-to-result latency.

## 8. Image pipeline

- Preserve the original source as immutable.
- Prefer ImageIO/`CGImageSource` for metadata inspection/downsampling.
- Prefer `CGImage` / `CIImage` through the processing pipeline instead of materializing full-resolution `UIImage` values repeatedly.
- Reuse an appropriate `CIContext`; do not create one per frame/render.
- Separate analysis resolution, preview resolution, and final export resolution.
- Encode lossy output only at the final stage where practical.
- Post-export verification reopens the generated file and checks dimensions/format/metadata invariants.
- Never burn guides/status UI into the official photo.

## 9. Vision and optional intelligence

- Apple Vision is the default face-analysis and segmentation framework.
- Vision observations must be converted to domain-neutral normalized geometry immediately.
- A computer-vision measurement becomes a hard compliance check only after calibration demonstrates adequate reliability for that exact rule semantics.
- Low-confidence/subjective checks become `warn` or `manual_check`, not invented certainty.
- iOS 27 segmentation-refinement APIs may be used where they materially improve mask correction and have an iOS 26 fallback.
- Foundation Models/Core AI are optional assistance layers only. They may explain or coach; they may not determine official dimensions, crop geometry, or authoritative pass/fail results.

## 10. Deterministic domain core

The following must be deterministic pure/domain logic wherever practical:

- physical-unit conversion;
- coordinate conversion;
- crop solving;
- rule evaluation;
- output dimensions;
- print layout;
- result-state derivation.

Explicit coordinate spaces:

- source pixels;
- normalized image space;
- preview points;
- output pixels;
- physical millimetres;
- PDF points.

Do not pass anonymous geometry across layers without knowing its coordinate space.

## 11. Rules and compliance language

- Country/document rules are versioned data, not country-specific UI code.
- Every official profile has provenance and a last-reviewed date.
- Unknown requirements remain explicit; never guess from another country/profile.
- Valid states are `pass`, `warn`, `fail`, and `manual_check`.
- `Ready` means measurable checks appear satisfied; it never means guaranteed government acceptance.
- Generative output may not override a sourced rule.

## 12. Privacy and security

- Core workflow stays on-device and works offline.
- No account or backend is required for the core workflow.
- No advertising SDK.
- Include and maintain `PrivacyInfo.xcprivacy`.
- Required-reason API declarations must match actual approved use.
- Use private/protected storage for temporary sensitive files and delete them when no longer needed.
- Strip GPS/unnecessary sensitive metadata from normal exports.
- Never log or transmit photos, thumbnails, face embeddings, landmark arrays, sensitive local paths, or document/person identifiers.
- Personal/family face photos must never be committed to the public repository.

## 13. Testing

New code must have the appropriate test layer.

Use:

- Swift Testing for domain/unit/integration logic;
- parameterized boundary tests for geometry/rules;
- controlled image fixtures for rendering/export;
- XCUITest for stable system/user flows;
- accessibility audits and physical-device manual tests;
- Instruments for performance-sensitive work;
- physical print measurements for print geometry.

Do not accept simulator-only evidence for camera, memory, thermal, or final performance decisions.

## 14. Performance

Measure first; do not invent budgets.

Use signposts around:

- camera first frame;
- capture result;
- image ingest/downsample;
- face analysis;
- segmentation;
- first prepared preview;
- final render;
- PDF generation;
- export completion.

Profile on at least one older supported and one current iPhone class.

## 15. Localization

- User-facing strings belong in String Catalogs (`.xcstrings`).
- Use Foundation format styles for measurements/numbers/dates.
- Avoid layouts sized around English strings.
- Preserve RTL structural compatibility.
- Do not bake explanatory text into graphics when avoidable.

## 16. Dependency changes

Any new non-Apple dependency must document:

- product need;
- why Apple APIs are insufficient;
- license;
- maintainer/release health;
- transitive dependencies;
- network/data collection;
- privacy manifest / required-reason APIs;
- binary-size/performance impact;
- replacement/removal strategy.

`Package.resolved` should be committed for the application so dependency versions remain reproducible.

## 17. Pull-request acceptance questions

Before considering work complete, ask:

1. Could a standard Apple API/control replace custom code?
2. Does this remain correct offline?
3. Can stale async work overwrite newer state?
4. Does VoiceOver/Voice Control have equivalent functionality?
5. What happens with large 48 MP input?
6. What happens under cancellation/interruption?
7. Are privacy/logging/data-retention implications correct?
8. Is the behavior tested at rule/geometry boundaries?
9. Does iOS 26 fallback safely when an iOS 27 feature is unavailable?
10. Does this feature make the ID-photo task better, or is it merely showcasing an API?

When the answer changes a foundational decision, update `docs/10-decisions.md` before quietly implementing a workaround.