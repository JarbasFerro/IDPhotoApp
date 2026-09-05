# 11 — iOS excellence strategy

## 1. Purpose

This document defines the platform-quality bar for ID Photo App.

The goal is to build an iPhone app that could credibly be used as an example of current Apple platform development: native, purposeful, private, accessible, technically precise, and visibly polished.

The goal is **not** to maximize the number of Apple framework logos in the architecture. A product becomes a good Apple-platform example when the right system capabilities disappear into a coherent user experience.

## 2. Current platform context — September 2026

Apple’s current developer baseline includes:

- iOS 27 announced at WWDC26;
- Xcode 27 beta with the iOS 27 SDK;
- Swift 6.4 compiler in Xcode 27 beta;
- refreshed Liquid Glass behavior and SwiftUI improvements;
- expanded App Intents/Siri integration;
- Foundation Models with image input and broader model support;
- new Vision image-understanding and segmentation capabilities;
- Xcode/Instruments improvements for performance and concurrency diagnosis;
- current privacy-manifest / required-reason API requirements.

Because Xcode 27 is still beta at the time of this plan, development may use the beta SDK for technical exploration, but App Store release must use a non-beta toolchain accepted by App Store Connect.

## 3. North-star experience

A user opens the app because they need a bureaucratic deliverable. The product should convert that anxiety into confidence.

Ideal fast path:

1. User selects “Spain — DNI” or another exact profile.
2. The requirements summary tells them only what matters before capture.
3. Camera opens quickly and calmly guides framing/lighting.
4. The shutter feels immediate.
5. On-device analysis produces a result without uploading the face.
6. The crop appears already well aligned.
7. If background separation needs help, the user points/taps rather than manually painting a complicated mask where possible.
8. Status explains what is measurable and what remains a human check.
9. Export is exact.
10. Save/share/print uses familiar iOS system behavior.

The user should feel: **“That was much easier than it should have been.”**

That is the primary delight target.

## 4. Apple design principles mapped to this product

### Purpose

Every element should improve capture, validation, correction, or export. Remove anything that does not.

### Agency

- original photo remains intact;
- user can inspect what the app changed;
- automatic crop can be adjusted;
- automatic background work can be reverted/refined;
- manual-check states remain visible;
- destructive exit/reset is explicit.

### Responsibility

- face images stay on-device by default;
- no false acceptance guarantee;
- no identity-changing retouching;
- minimal permissions;
- no advertising SDK in the sensitive workflow;
- provenance for official rules.

### Familiarity

- native navigation;
- standard share/print/photo-picker flows;
- SwiftUI controls;
- SF Symbols;
- standard search;
- system permission timing;
- standard accessibility behavior.

### Flexibility

- Direct manipulation + accessible adjustment controls;
- Dynamic Type;
- VoiceOver/Voice Control;
- light/dark/increased contrast;
- multiple iPhone screen sizes;
- iOS 26 fallback for optional iOS 27 features.

### Simplicity

- one core workflow;
- few editing controls;
- no photo-editor feature creep;
- no account;
- no cloud setup;
- no technical settings screen for normal users.

### Craft

- camera latency;
- photo transition quality;
- crop geometry;
- animation timing;
- haptic restraint;
- clear error text;
- stable mask edges;
- exact printed dimensions;
- excellent App Store presentation.

### Delight

Delight should come from:

- the camera guiding without nagging;
- the crop landing correctly;
- a difficult mask becoming easy to refine;
- immediate, understandable feedback;
- an export that prints exactly the expected size.

No confetti is required.

## 5. Native platform capability matrix

### 5.1 SwiftUI

Use for:

- app shell;
- navigation;
- profile selection;
- requirements;
- validation results;
- editor chrome/overlays;
- export setup;
- settings/help.

Current-quality rules:

- standard navigation/toolbars first;
- modern presentation APIs;
- semantic system styles;
- avoid UIKit wrappers except where no suitable SwiftUI API exists (camera preview/printing may require boundaries);
- use Observation instead of Combine-heavy view-model plumbing;
- avoid custom design-system abstractions that make new SDK behavior harder to inherit.

### 5.2 Liquid Glass

Use primarily by inheritance from standard system components.

Potential custom use:

- compact floating editor controls over an edge-to-edge portrait;
- only if readability and interaction are better than toolbar/safe-area controls.

Do not:

- put every panel inside custom glass;
- use decorative glass behind static content;
- hide important contrast under translucent surfaces;
- copy screenshots of Apple apps without understanding component behavior.

### 5.3 AVFoundation

This is a signature technical area.

Goals:

- responsive startup;
- stable preview;
- excellent still quality;
- correct orientation;
- low-latency transition from shutter to analysis;
- good interruption recovery;
- efficient high-resolution path;
- no camera session when not in camera flow.

Live guidance should use low-cost analysis frames while final still quality remains independent.

### 5.4 PhotosUI / PhotosPicker

Use system selection instead of full library access.

This is both a UX and privacy best practice.

### 5.5 Vision

Primary computer-vision framework.

Use/benchmark for:

- face detection;
- face landmarks/pose where useful;
- person/foreground segmentation;
- image-quality capabilities where suitable;
- iOS 27 tap/scribble/rectangle segmentation refinement.

Product rule:

A Vision-derived measurement is not automatically a compliance rule. Each measurement needs calibration, thresholds, and evidence.

### 5.6 Core Image + ImageIO + Core Graphics

Use as the deterministic rendering backbone.

Goals:

- avoid repeated `UIImage` materialization;
- downsample efficiently;
- keep operations composable;
- reuse rendering context;
- exact crop/scale;
- clean background composition;
- accurate export metadata;
- exact PDF geometry.

Use Accelerate/vImage only when profiling demonstrates benefit.

### 5.7 App Intents / Siri / Shortcuts

High-value system integration examples:

- “Create an ID photo”;
- “Open passport photo for Spain”;
- start a known document profile from the Action button through a Shortcut where the user configures it.

The integration should shorten entry into the task, not duplicate the whole app in Siri.

Use AppIntentsTesting for adopted intents where applicable.

### 5.8 Core Spotlight

Index supported document profiles and help topics where useful.

Do not index:

- user photos;
- face geometry;
- private file names;
- personal document metadata.

### 5.9 Foundation Models

Potential role: optional **Photo Coach** or explanation layer.

Good candidate tasks:

- explain a deterministic warning in simpler terms;
- answer a question using supplied official-rule context;
- summarize what the user needs to fix before retaking;
- help select a document profile from natural language.

Bad candidate tasks:

- decide crop size;
- invent official rules;
- mark an image compliant based on free-form model judgement;
- change appearance;
- upload sensitive images without a separate explicit decision.

If implemented:

- use structured inputs/outputs;
- constrain context to sourced information;
- evaluate with a test set;
- include model-unavailable path;
- prefer on-device execution;
- never hide the deterministic result behind generated prose.

### 5.10 Core AI / custom models

Do not use merely because it is new.

Consider only if Vision cannot achieve a specific high-value requirement and a custom model can run privately/on-device with measurable accuracy and acceptable size/performance.

### 5.11 TipKit

Possible uses:

- teach first-time crop interaction;
- explain manual checks;
- point out a background-refinement gesture once.

Do not turn the workflow into a sequence of tutorial popovers.

### 5.12 StoreKit

Use for monetization if needed.

Possible product-friendly models:

- one-time unlock;
- free limited exports + paid pack;
- subscription only if recurring value (many countries, frequent professional use, rule-update service, etc.) genuinely supports it.

No dark patterns.

### 5.13 SwiftData

Not required by default.

Use only if we decide to persist structured job history/resume data. Favorites/recent profile IDs can start simpler.

### 5.14 Swift Testing

Default for new pure Swift tests.

Use parameterized tests heavily for:

- mm/pixel conversions;
- profile dimensions;
- rule boundaries;
- crop solver cases;
- print layout;
- result-state derivation.

### 5.15 Instruments

Required engineering tool, not optional optimization polish.

Use:

- Time Profiler;
- Allocations/Leaks;
- Swift Concurrency instrument;
- hangs/responsiveness workflow;
- signpost intervals;
- run comparison before/after performance changes.

### 5.16 MetricKit

Evaluate for privacy-compatible production performance diagnostics. Prefer Apple-native telemetry before adding third-party monitoring.

### 5.17 Icon Composer + SF Symbols

App icon should be built/tested with the current Apple icon tooling.

In-app icons use SF Symbols unless a custom symbol communicates a domain-specific concept better.

## 6. Signature experiences

A potential WWDC/Design-Award-quality product usually has a small number of moments that are both technically strong and visibly understandable.

For this app, focus on four.

### Signature 1 — The guided camera

The user sees a clean full-screen camera. Guidance appears only when necessary, stabilizes rather than flickers, and disappears when conditions improve.

Technical quality:

- quick launch;
- real-time Vision analysis at controlled resolution/frequency;
- debounced guidance;
- accessible spoken guidance;
- high-resolution still capture independent from preview analysis.

### Signature 2 — The automatic composition transition

After capture, the app smoothly transitions from the original source to the official crop and explains what was checked.

The transition should communicate cause/effect, not simply animate for effect.

### Signature 3 — Background refinement

If automatic segmentation is imperfect, iOS 27 Vision refinement should make correction feel like identifying the subject rather than using a desktop masking tool.

This could become the clearest demonstration of new system image-understanding capability.

### Signature 4 — Exact print sheet

The app turns one prepared portrait into a print-ready sheet with an excellent preview and native print/share behavior.

The detail that matters: the physical result is correct.

## 7. Features we should explicitly *not* add for showcase value

Unless a real user need appears:

- widget;
- Live Activity;
- watchOS companion;
- iMessage app;
- social feed;
- arbitrary generative image editing;
- chatbot as the home screen;
- gamification;
- custom keyboard;
- full Photos library browser;
- custom share UI;
- AR gimmicks;
- excessive 3D/spatial effects.

Restraint is part of the design quality.

## 8. Accessibility excellence plan

### Camera

- VoiceOver shutter and camera controls;
- spoken guidance rate-limited;
- enough information to capture without interpreting the overlay;
- clear permission recovery.

### Photo Check

- overall status announced;
- each check has label + state + remediation;
- manual requirements distinguishable without color.

### Editor

- gesture path for sighted direct manipulation;
- explicit directional/zoom controls;
- adjustable accessibility actions where useful;
- focus does not jump unpredictably after render updates;
- crop status described semantically;
- mask refinement offers non-freehand option if technically possible.

### Export

- exact output dimensions are readable;
- print layout can be understood without relying solely on the visual thumbnail;
- share/print uses system accessibility.

### Test modes

At minimum test:

- VoiceOver;
- Voice Control;
- Dynamic Type accessibility sizes;
- Bold Text;
- Increase Contrast;
- Differentiate Without Color;
- Reduce Motion;
- Reduce Transparency;
- dark appearance.

## 9. Privacy excellence plan

The app’s privacy story should be technically true and easy to explain:

> Your face photo is processed on your iPhone for the normal workflow.

Engineering consequences:

- PhotosPicker over broad library access;
- AVFoundation permission at point of use;
- no account;
- no required backend;
- private temporary files;
- file protection;
- EXIF/GPS removal from normal exports;
- no photos in logs/analytics;
- privacy manifest from project bootstrap;
- no advertising SDK;
- third-party SDK burden of proof is high.

If optional intelligence ever uses Private Cloud Compute or another cloud provider, it becomes a separate feature with explicit data-flow review and user-facing explanation.

## 10. Performance excellence plan

Performance is part of UX.

Measure rather than guess.

Critical intervals:

- app launch → interactive;
- camera requested → first frame;
- shutter → source available;
- source → face result;
- source → segmentation result;
- source → first prepared preview;
- editor gesture → preview update;
- export request → file ready;
- print-sheet request → PDF ready.

Critical resources:

- peak resident memory with large input;
- memory while camera + Vision operate together;
- CPU/GPU cost of repeated preview rendering;
- thermal behavior in repeated family-photo sessions;
- energy impact of real-time guidance.

Do not run maximum Vision analysis on every camera frame. Use an intentional cadence and cancel stale work.

## 11. App Store quality strategy

Product page should communicate three things quickly:

1. Choose the exact ID format.
2. iPhone guides/prepares the photo privately.
3. Save digitally or print at exact size.

Avoid claims such as:

- “guaranteed passport approval”;
- “official government app”;
- “AI-certified photo.”

Use screenshots that show the product’s signature experiences rather than feature-list collages.

## 12. Review cadence

### Every pull request touching UI

Ask:

- system control or custom?
- accessibility equivalent?
- appearance variants?
- unnecessary glass?
- unnecessary animation?
- localization impact?

### Every pull request touching image/ML

Ask:

- main-actor blocking?
- unnecessary full-resolution decode/copy?
- cancellation?
- memory budget?
- privacy/logging?
- deterministic fallback?

### Every milestone

Review current Apple documentation and release notes. This matters especially while Xcode 27/iOS 27 are pre-release.

### Every WWDC

Run a platform refresh review:

- HIG changes;
- SwiftUI changes;
- Vision/Core Image changes;
- camera guidance;
- privacy requirements;
- App Intents/Siri;
- accessibility APIs;
- StoreKit;
- testing/performance tools;
- deployment target strategy.

## 13. “Would Apple show this?” checklist

A strict review before 1.0:

- [ ] The app’s purpose is understandable in seconds.
- [ ] The primary path has no unnecessary screen.
- [ ] It looks native without copying a specific Apple app.
- [ ] Standard controls receive current platform appearance naturally.
- [ ] Custom Liquid Glass is rare and purposeful.
- [ ] Camera startup/capture feels immediate on target devices.
- [ ] Image processing does not visibly block the UI.
- [ ] Privacy claim matches network/data behavior.
- [ ] No broad Photos permission is requested for simple import.
- [ ] Core flow works offline.
- [ ] VoiceOver can complete the workflow.
- [ ] Crop can be corrected without direct manipulation.
- [ ] Dynamic Type does not hide critical actions.
- [ ] Motion remains coherent under Reduce Motion.
- [ ] Status is not color-only.
- [ ] Every official rule has provenance.
- [ ] No generative output defines official geometry.
- [ ] Segmentation failure is honest/recoverable.
- [ ] Export dimensions are re-verified after encoding.
- [ ] Printed physical size is measured on real output.
- [ ] App Intents shorten a real task rather than exist as a demo.
- [ ] Optional Foundation Models features survive controlled evaluation.
- [ ] There is no unnecessary third-party SDK.
- [ ] Performance was verified in Instruments on physical iPhones.
- [ ] The icon is built/tested with current Apple tooling.
- [ ] App Store screenshots tell a coherent product story.
- [ ] The product has a moment of delight created by exceptional usefulness, not decoration.

## 14. Current primary Apple resources

These should be treated as living references, not one-time reading:

- Human Interface Guidelines — https://developer.apple.com/design/human-interface-guidelines/
- Design principles — https://developer.apple.com/design/human-interface-guidelines/design-principles
- WWDC26 Design guide — https://developer.apple.com/wwdc26/guides/design/
- WWDC26 iOS guide — https://developer.apple.com/wwdc26/guides/ios/
- WWDC26 SwiftUI guide — https://developer.apple.com/wwdc26/guides/swiftui/
- Liquid Glass — https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass
- Vision — https://developer.apple.com/documentation/vision
- Foundation Models — https://developer.apple.com/documentation/FoundationModels
- App Intents — https://developer.apple.com/documentation/appintents
- Privacy manifests — https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Required-reason APIs — https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Xcode system requirements — https://developer.apple.com/xcode/system-requirements/
- Apple Design — https://developer.apple.com/design/

## 15. Final principle

The project should not attempt to look futuristic.

It should look **inevitable** on iPhone: as though the platform, camera, on-device intelligence, accessibility system, and document rules were always meant to work together this way.