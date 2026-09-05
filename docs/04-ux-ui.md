# 04 — iOS UX / UI

## 1. UX objective

The interface should feel materially simpler than the underlying problem. A person should not need to understand biometric-photo geometry, pixels, DPI, segmentation, or image formats to produce the correct output.

This is a guided iPhone task, not a general-purpose photo editor.

The experience should be credible against current Apple Human Interface Guidelines and WWDC26 design guidance. Native behavior is the baseline; custom presentation exists only when it improves the task.

## 2. Apple design-principle review lens

Every meaningful product/design review should explicitly consider:

- **Purpose** — does this help create a correct ID photo?
- **Agency** — can the user understand and reverse what the app is doing?
- **Responsibility** — are privacy, uncertainty, and identity preservation handled honestly?
- **Familiarity** — are standard iOS patterns used where people already know them?
- **Flexibility** — does the experience work across text sizes, accessibility needs, input methods, and supported iPhones?
- **Simplicity** — can an element or step be removed without losing necessary control?
- **Craft** — are spacing, typography, motion, state transitions, latency, and errors polished?
- **Delight** — does the product create confidence through care rather than through decorative effects?

## 3. UX principles

### UXP-01 — One dominant action per state

Each screen/state should have one obvious next action. Secondary actions remain available without competing visually.

### UXP-02 — Progressive disclosure

Show requirements when they matter. Full official sources and detailed measurements remain accessible without cluttering the fast path.

### UXP-03 — Explain, then fix

Every warning pairs with an actionable recovery: retake, choose another photo, reposition, adjust background, review manually, or continue knowingly.

### UXP-04 — Preserve uncertainty

`manual_check` is a first-class state. The app must not convert uncertainty into green confidence for visual neatness.

### UXP-05 — Preserve user effort

Changing export format, copy count, or compatible document profile should not make the user repeat acquisition/editing.

### UXP-06 — Constrained editor

The editor exposes only controls required to make a compliant output. No filters, stickers, beautification, text overlays, or decorative effects in official mode.

### UXP-07 — What you see is what is exported

The final frame is accurate. Guides/status remain UI overlays and are never baked into output.

### UXP-08 — Native before custom

Prefer `NavigationStack`, system toolbars, sheets, menus, `PhotosPicker`, `ShareLink`, standard alerts/confirmation dialogs, SF Symbols, semantic colors, and platform gestures.

### UXP-09 — No permission surprise

Never request camera access on launch. Ask only after the user chooses camera capture. Normal photo import uses PhotosPicker and should not require full-library access.

### UXP-10 — Accessibility is an interaction mode, not an afterthought

Every core editing operation has a non-precision-gesture alternative and clear semantic state.

## 4. Information architecture

Recommended structure:

```text
Home
├── Create ID photo
│   ├── Country / document profile
│   ├── Requirements
│   ├── Capture or Choose Photo
│   ├── Photo Check
│   ├── Editor
│   └── Export
├── Recent / Favorite Profiles
├── Help
└── Settings
```

Do not add a persistent tab bar merely because it is common. The primary product is a linear task. A `NavigationStack` is the default unless testing demonstrates a genuine parallel-navigation need.

## 5. System appearance and Liquid Glass

### Principle

Use the newest system appearance by using native controls correctly, not by manually painting “Apple-looking” glass everywhere.

Rules:

- build with the latest SDK so standard SwiftUI navigation, toolbars, controls, menus, sheets, and materials inherit current Liquid Glass behavior;
- let photo/content extend edge-to-edge where it improves immersion;
- reserve custom `glassEffect` for a small number of floating interactive surfaces such as an editor control cluster when native toolbar placement cannot solve the task;
- avoid glass-on-glass layering;
- avoid persistent translucent cards covering the portrait;
- status feedback must remain legible over diverse photos;
- custom brand color should tint meaningfully, not flood navigation chrome;
- verify light/dark appearance, increased contrast, Reduce Transparency, and high Dynamic Type sizes.

The newest visual language is a consequence of using the system well, not the product’s visual gimmick.

## 6. Visual language

The app should feel precise, calm, modern, and human.

Use:

- system typography and Dynamic Type;
- large, high-quality portrait previews;
- generous spatial hierarchy;
- SF Symbols for familiar actions/states;
- semantic system colors/materials;
- one restrained brand accent;
- content-driven full-bleed photo surfaces;
- clear toolbars rather than dense card grids;
- subtle haptics and motion only at meaningful transitions.

Avoid:

- fake camera hardware chrome;
- decorative gradients competing with faces;
- excessive cards within cards;
- permanently visible technical measurements;
- tiny caption-style action labels;
- custom back buttons;
- custom share sheets;
- custom photo-library browsers;
- copied Android/cross-platform interaction conventions.

## 7. Primary flow

### Screen 1 — Home

Purpose: start immediately.

Content:

- product identity;
- dominant `Create ID Photo` action;
- recent/favorite document profiles when available;
- subtle access to Help/Settings through appropriate navigation/toolbar placement.

Optional iOS integration may allow Siri/Shortcuts/Spotlight to deep-link directly to a document profile, but the in-app home remains complete on its own.

Do not ask for permissions.

### Screen 2 — Country and document profile

Prefer one searchable selection experience rather than forcing multiple screens if testing shows a combined picker is faster.

Use:

- SwiftUI searchable navigation;
- recent/favorite sections;
- localized country/document names;
- output size as secondary information;
- verified-source status only when provenance policy is satisfied.

Flags may be supplementary but never the sole identifier.

### Screen 3 — Requirements summary

Purpose: prevent avoidable capture failures.

Show only the high-value pre-capture guidance:

- pose/expression;
- background;
- glasses/headwear where relevant;
- lighting/shadow guidance;
- photo-recency requirements where relevant;
- child/baby exceptions where applicable.

Primary action: `Take Photo`.
Secondary action: `Choose Photo`.
Tertiary: `View Full Requirements`.

### Screen 4A — Guided camera

The camera is one of the product’s signature experiences.

Design:

- edge-to-edge live preview;
- minimal overlay;
- large system-style shutter control;
- camera-switch control only when useful;
- a lightweight composition guide;
- one or two high-confidence live messages at a time;
- no technical score dashboard while framing.

Live guidance may include:

- move farther/closer;
- center your face;
- raise/lower the phone;
- improve lighting;
- only one face;
- hold still.

Use feedback only when confidence is high enough to help. Do not flicker warnings frame-to-frame. Apply hysteresis/debouncing.

Camera guidance optimizes the **source photo**, not the final official crop. The user should leave enough room for downstream formatting.

Accessibility:

- all controls have VoiceOver/Voice Control labels;
- guidance is spoken without becoming an incessant stream;
- visual guide is not required to complete capture;
- shutter remains a predictable accessible control;
- no critical state conveyed only by color.

### Screen 4B — PhotosPicker

Use the system picker. Do not replicate the Photos app.

After selection, transition directly into analysis unless an explicit confirmation solves a proven problem.

### Screen 5 — Analysis transition

The analysis should feel immediate and truthful.

If processing is short, avoid a separate loading screen; transition directly to the result with progressive state.

If longer, show meaningful stage names such as:

- Checking photo
- Finding face
- Preparing background
- Applying document rules

Do not show fake percentages.

Use animation that respects Reduce Motion.

### Screen 6 — Photo Check

Structure:

- prominent portrait preview;
- overall state;
- concise check list;
- one primary next action.

Overall states:

**Ready**
> The measurable checks look good. Review the remaining manual requirements before export.

**Needs Review**
> A few items need your attention.

**Retake Recommended**
> This source photo is unlikely to produce a good result.

Each check row includes:

- SF Symbol/status treatment;
- short label;
- plain-language explanation;
- `How to Fix` detail where useful.

Manual checks remain visible.

### Screen 7 — Editor

The editor is the second signature experience.

Default structure:

- full-bleed/large portrait canvas;
- official crop frame and composition guides;
- minimal floating/toolbar controls;
- concise current status;
- primary `Continue` action when no hard measurable failure remains.

Controls:

1. **Position** — direct drag/pinch plus accessible adjustment actions.
2. **Background** — automatic/original/permitted colors.
3. **Refine** — only when segmentation requires user help.
4. **Reset** — return to automatic composition.
5. **Details** — show exact measurements/status on demand, not permanently.

On iOS 27, evaluate Vision’s tap/scribble/rectangle segmentation refinement for a more natural mask-correction experience. It should feel like pointing out what is foreground/background rather than painting pixels manually.

Gesture behavior:

- drag translates;
- pinch scales;
- optional rotation only if official rules and usability justify it;
- use live rule feedback;
- hard constraints only prevent impossible output (for example, empty crop pixels).

Accessible alternatives:

- VoiceOver adjustable action for zoom where appropriate;
- explicit Move Up/Down/Left/Right actions;
- Zoom In/Out;
- Reset Position;
- Background choices with readable names;
- mask-refinement controls accessible without freehand drawing when possible.

Haptics:

Use `sensoryFeedback` sparingly for meaningful events such as snapping into a recommended range or successful completion. Do not buzz continuously during drag.

### Screen 8 — Export choice

Use a clear native list/card decision:

- `Digital Photo`
- `Print Sheet`

Do not introduce a generic “Export Center.”

### Screen 9A — Digital export

Show:

- final dimensions;
- format;
- file-size constraint status if relevant;
- remaining manual checks.

Primary action should use a native share/save path (`ShareLink`/system share sheet or appropriate Photos/files export action).

Do not invent a proprietary file browser.

### Screen 9B — Print setup

Show:

- paper size;
- copy count;
- orientation where meaningful;
- print-sheet preview;
- cut-guide choice if supported.

Primary action: `Print / Share PDF`.

The system printing interface is preferred. Explicitly tell users to preserve Actual Size / 100% scaling when printing outside the app.

### Screen 10 — Completion

Completion should be quiet and useful.

Actions may include:

- share/save again;
- make another compatible format from the same prepared source;
- create a new photo.

No forced review prompt or full-screen upsell immediately after success.

## 8. Navigation and presentation rules

- Use `NavigationStack` for the task flow.
- Use system sheets for contained secondary decisions.
- Use confirmation dialogs for destructive/choice-heavy actions when appropriate.
- Avoid nested sheets.
- Avoid custom modal transitions unless the system cannot express the desired relationship.
- Place primary actions consistently with current iOS toolbar conventions.
- Use destructive role styling for destructive actions.
- Preserve swipe-back behavior unless an active editing state genuinely requires confirmation.
- When abandoning unsaved work, ask only if meaningful effort would be lost.

## 9. Search

Search exists where users need to find a country/document profile, not as universal decoration.

Use native searchable behavior and current iOS search conventions.

Search should match:

- localized country name;
- document name;
- common aliases;
- country code if useful;
- visa/passport/common-language terms.

Core Spotlight may expose supported document profiles to system search. Never index personal photos or face-derived metadata.

## 10. App Intents / Siri UX

Only expose durable, understandable actions.

Good candidates:

- “Create an ID photo”
- “Create a passport photo”
- “Open Spain passport photo requirements”

System entry should land at the earliest sensible point with context preselected, then continue in the normal app flow.

Do not make Siri responsible for taking or approving a sensitive official photo.

## 11. Optional Foundation Models experience

An optional on-device helper may explain structured diagnostics or answer plain-language questions.

Examples:

- “Why is this marked Needs Review?”
- “What does head height mean?”
- “How should I take this photo again?”

Boundaries:

- deterministic checks remain visible and authoritative;
- generated text is presented as assistance, not a new compliance result;
- the feature disappears cleanly when model capability is unavailable;
- no cloud fallback without a separate privacy/product decision;
- evaluation is required before release.

Do not add a chat tab merely to advertise AI.

## 12. Status design

| State | Meaning | Treatment |
|---|---|---|
| Pass | measurable requirement appears satisfied | positive symbol + text |
| Warn | risk or uncertain measurable issue | warning symbol + remediation |
| Fail | measurable requirement clearly fails | error symbol + fix/retake action |
| Manual check | cannot be safely validated automatically | review symbol + checklist |

Color supplements meaning but never carries it alone.

## 13. Error design

Every error answers:

1. What happened?
2. Why does it matter?
3. What can I do now?

Bad:

> Segmentation confidence insufficient.

Better:

> We couldn’t separate the hair cleanly from the background. Try a photo farther from the wall, keep the original background if allowed, or refine the edge.

Use system alerts only for events that genuinely interrupt the workflow. Inline errors are preferred when recovery belongs to the current screen.

## 14. Permission states

### Camera denied

Explain the purpose and provide:

- `Open Settings` when appropriate;
- `Choose Photo` as immediate alternative.

### Photo import

Normal PhotosPicker use should avoid broad Photo Library permission entirely.

Never block the product behind permissions not required for the selected path.

## 15. Accessibility requirements

### VoiceOver

- meaningful screen titles;
- logical focus order;
- concise status announcements after analysis;
- no redundant reading of every decorative guide;
- editor adjustments expose current value/state;
- move/zoom controls are operable without direct manipulation.

### Voice Control

- visible/semantic labels map to predictable spoken names;
- avoid multiple ambiguous `Edit`/`More` actions on one screen.

### Dynamic Type

- surrounding controls support accessibility text sizes;
- do not scale the actual photo/crop geometry based on Dynamic Type;
- layouts reflow rather than clip;
- primary action remains reachable.

### Reduce Motion

- replace spatial/morphing transitions with simpler fades where necessary;
- no important information encoded only in motion.

### Differentiate Without Color / Increased Contrast

- use symbols, text, borders/shape where needed;
- verify status chips and overlays on varied photos.

### Touch targets

Controls should meet current HIG target guidance and remain forgiving near the photo editor.

## 16. Localization

Use String Catalogs from the beginning.

- no baked-in text in instructional images where avoidable;
- document names support official/localized aliases;
- numbers and measurements use Foundation formatting;
- long German/French/Portuguese strings must not break layouts;
- RTL should be tested even if not a launch language;
- screenshots/localized App Store assets are planned per launch locale.

## 17. Empty/loading/error states that must exist

Before UI is complete, design and implement:

- no recent profiles;
- no search results;
- rule catalog failure;
- camera unauthorized/restricted;
- camera interruption;
- camera unavailable;
- PhotosPicker cancellation;
- decode failure;
- unsupported/corrupt image;
- image too small;
- no face;
- multiple faces;
- Vision failure;
- segmentation failure;
- iOS 27 refinement unavailable;
- processing cancelled;
- background/foreground app interruption;
- export failure;
- disk-space failure;
- share/print cancellation/failure;
- invalid/outdated profile warning.

## 18. Animation and sensory-feedback policy

Animation should communicate hierarchy/state change, not advertise polish.

Use:

- native transitions;
- matched transitions only when the source/destination relationship is clear;
- short status transitions;
- subtle alignment/export haptics.

Avoid:

- looping decorative motion;
- confetti for official-document completion;
- dramatic zoom transitions that obscure navigation;
- constant haptics while tracking continuous gestures.

Every motion path is reviewed with Reduce Motion enabled.

## 19. App icon and brand

Use Icon Composer for the final app icon and test it across current appearance treatments.

Brand strategy:

- simple, recognizable silhouette/layers;
- works small;
- no tiny text;
- no passport/government emblem that implies official affiliation;
- identity should complement the iOS visual system rather than fight it.

SF Symbols should cover most in-app utility iconography. Custom symbols must match system optical weight and alignment.

## 20. UX validation

Use task testing, not preference polling.

Representative tasks:

1. Create a passport photo from Photos.
2. Recover after camera permission is denied.
3. Understand why a photo is marked blurry.
4. Correct face position without verbal instruction.
5. Correct face position using VoiceOver/non-gesture controls.
6. Identify which checks remain manual.
7. Create six printable copies.
8. Find the official source and review date.
9. Start the app through a Shortcut and understand where you landed.

Measure:

- completion;
- time on task;
- wrong turns;
- accidental exits;
- misunderstanding of Ready/manual-check semantics;
- gesture discoverability;
- VoiceOver completion;
- large-text layout failures;
- perceived confidence without overclaiming acceptance.

## 21. Design review checklist

Before a screen is accepted:

- Is every element necessary?
- Is the dominant action obvious?
- Could a standard iOS control replace a custom one?
- Does content remain primary over glass/chrome?
- Does it work in light/dark/increased contrast?
- Does it work with accessibility text sizes?
- Does VoiceOver expose equivalent functionality?
- Does Voice Control have usable names?
- Does Reduce Motion remain coherent?
- Are loading and error states truthful?
- Are permissions requested only at point of use?
- Does the screen remain understandable if all optional AI features are removed?

## 22. Design deliverables before final production UI

Required:

- screen/state map;
- low-fidelity wireframes;
- current-HIG component inventory;
- main-flow prototype;
- camera interaction prototype;
- editor direct-manipulation prototype;
- VoiceOver editor interaction prototype;
- Liquid Glass/system-material study using real SwiftUI controls rather than static mockups;
- design tokens only for product-specific values not already represented by system semantics;
- accessibility annotations;
- localization stress tests;
- Icon Composer exploration;
- final visual design for primary path;
- App Store screenshot/story plan.

## 23. Primary Apple references

- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Design principles: https://developer.apple.com/design/human-interface-guidelines/design-principles
- WWDC26 Design guide: https://developer.apple.com/wwdc26/guides/design/
- Liquid Glass: https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass
- SwiftUI: https://developer.apple.com/wwdc26/guides/swiftui/
- Apple Design Resources: https://developer.apple.com/design/resources/

Re-review this document after major HIG/SDK changes instead of treating it as frozen visual law.