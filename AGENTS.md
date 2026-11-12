# ID Photo App — Implementation contract

This file defines the engineering conventions for human and AI contributors. Start with [docs/00-handoff.md](docs/00-handoff.md). Before changing code, read [docs/04-architecture.md](docs/04-architecture.md), [docs/03-design.md](docs/03-design.md), and [docs/05-decisions.md](docs/05-decisions.md). The plan is [docs/02-roadmap.md](docs/02-roadmap.md).

## 1. Product target

- iPhone / iOS only.
- Native Swift + SwiftUI.
- Build against the newest approved Apple SDK available for the current development/release stage.
- Minimum iOS 27 (ADR-024, decided 2026-11-12). The deployment target is 27.0.
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
- Respect light/dark appearance and Reduce Motion. Other accessibility settings follow the 1.0 baseline in section 6.

## 6. Accessibility baseline (1.0 scope, ADR-050)

For 1.0, accessibility is a baseline rather than a release gate (founder decision, ADR-050). Keep:

- system controls, text styles, and SF Symbols, so Dynamic Type and system settings work where the layout allows;
- an accessibility label on every icon-only control;
- pass/warn/fail/manual state shown with a word or symbol, never by colour alone;
- Reduce Motion respected by every custom animation;
- accessibility features that already exist (Move/Zoom buttons, spoken camera guidance, accessibility actions): do not remove them.

Deferred until after 1.0: full VoiceOver/Voice Control journeys, accessibility audits as a release gate, layouts tuned for accessibility text sizes, and non-gesture equivalents for new features. Never declare accessibility support in App Store metadata that has not been checked.

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
- iOS 27 segmentation-refinement APIs may be used where they materially improve mask correction; when they cannot help, fall back to edge softness, the original background, or a retake.
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
- Drafts (ADR-049) use complete file protection, are excluded from backups, and are deleted after their retention period or on request.
- Every output path goes through the single export gate; a locked (unpaid) photo never leaves the app as a file, print, copy, or share (ADR-048, ADR-049).
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

## 17. Versioning

- The spike app and, later, the production app show `marketing version (build)` on their main screen.
- Marketing version follows `0.<spike or milestone>.<fix>` until release; build number is the git commit count.
- Run `scripts/bump-version.sh <version>` before committing app changes, and tag commits handed to a device with `v<version>`.
- Never ship two different binaries with the same version and build.

## 18. Pull-request acceptance questions

Before considering work complete, ask:

1. Could a standard Apple API/control replace custom code?
2. Does this remain correct offline?
3. Can stale async work overwrite newer state?
4. Does it keep the accessibility baseline in section 6 (ADR-050)?
5. What happens with large 48 MP input?
6. What happens under cancellation/interruption?
7. Are privacy/logging/data-retention implications correct?
8. Is the behavior tested at rule/geometry boundaries?
9. Does it behave well on the oldest iPhone that runs iOS 27?
10. Does this feature make the ID-photo task better, or is it merely showcasing an API?

When the answer changes a foundational decision, update `docs/05-decisions.md` before quietly implementing a workaround.
## 19. Model tiering for AI agents

Contributors may run on a frontier model or on a small/fast model. Tier is chosen by task, not by convenience.

A small/fast model is acceptable only when all of the following hold:

- the task is fully specified: what to change, where, and what "done" means;
- the result is cheap to verify by build, test, grep, diff, or schema check;
- a wrong result is cheap: local, reversible, and unable to silently corrupt later work;
- it needs roughly ten tool calls or fewer, with no branching decisions.

Suitable small-tier work:

- locating definitions, usages, and files (search and inventory, not auditing);
- mechanical edits following a supplied pattern, such as renames or adding listed String Catalog keys;
- extraction, classification, or summary of bounded input;
- boilerplate mirroring an existing file;
- running a build or test suite and reporting the raw failures;
- format conversions and translation drafts that will be reviewed.

Use a frontier model for:

- ambiguous scope, API shape, architecture, or any design judgment;
- reasoning across several files: concurrency, state flow, stale-result handling;
- debugging an unknown cause;
- long or interdependent multi-step work;
- code, security, privacy, or accessibility review, where a missed finding looks identical to a clean result;
- the deterministic domain core (section 10), rule data and provenance (section 11), and Vision calibration (section 9);
- irreversible or outward-facing actions: commits, pushes, version bumps, tags, signing, App Store;
- planning for, or synthesizing results from, other agents.

Operating rules:

- The frontier model plans and writes the brief, including file paths, the exact pattern, and the acceptance check; the small model executes.
- Small-model output must be checkable: `file:line` lists, diffs, or pass/fail with raw output. A prose claim of success is not evidence.
- Gate every small-model edit batch with a build or test run, and spot-check a "no matches" search result before acting on it.
- Escalate rather than retry: after two failed or confused attempts, hand the task to the frontier tier instead of rephrasing.
- Search and summary agents stay read-only.
- One bounded task per small agent. If it would need the whole conversation to succeed, it is the wrong agent.
- Every other section of this file applies to every tier without exception.

## 20. Working with the founder

- Visuals and experience come first. Look at screenshots of every changed screen in Light and Dark before committing.
- Nothing is final. Propose anything that would make the app look, feel, or perform better; record a changed decision in `docs/05-decisions.md` first.
- Commit and push to `main` after each finished batch without asking. Bump the version before committing app changes (section 17).
- Design choices go to the founder as two or three options; save each round in `docs/ui/explorations/`.
- Keep the documents short and current: a change to a screen, a rule, or the plan updates `docs/03-design.md`, `docs/06-markets-and-documents.md`, or `docs/02-roadmap.md` in the same commit. Do not add new planning documents; extend the seven that exist.
- The repository is public: no real faces, device identifiers, account details, or secrets.
