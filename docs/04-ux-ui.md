# 04 — UX / UI

## 1. UX objective

The interface should feel much simpler than the underlying problem. The user should not need to understand biometric-photo geometry, pixels, DPI, or background rules to produce the correct output.

The main experience is a guided task, not a general-purpose photo editor.

## 2. UX principles

### UXP-01 — One primary task per screen

Each main screen should have one obvious next action.

### UXP-02 — Progressive disclosure

Show only the requirements needed at the current step. Detailed source/legal information remains available but should not clutter the fast path.

### UXP-03 — Explain, then fix

If a photo has a problem, pair the warning with a concrete action: retake, choose another photo, reposition, adjust mask, or review manually.

### UXP-04 — Do not hide uncertainty

A yellow/manual-review state is better than a misleading green state.

### UXP-05 — Preserve user effort

Changing export type, copy count, or paper size must not force the user to repeat capture/editing.

### UXP-06 — Editing should be constrained

The editor is not Photoshop. Only expose controls that help satisfy the selected output requirement.

### UXP-07 — Show the actual final frame

The crop preview must accurately represent what will be exported. Safe-area guides may overlay it, but they must never alter the output.

## 3. Information architecture

Recommended top-level structure:

```text
Home
├── New photo
│   ├── Country
│   ├── Document/use case
│   ├── Requirements
│   ├── Capture / Import
│   ├── Analysis
│   ├── Editor
│   └── Export
├── Recent profiles (not photo history by default)
├── Help
└── Settings
```

Avoid a permanent bottom navigation bar for MVP unless testing proves users need frequent lateral navigation. The core workflow is linear and task-oriented.

## 4. Primary flow

### Screen 1 — Home

Purpose: start quickly.

Content:

- product name/logo;
- primary action: `Create ID photo`;
- recent/favourite document profiles if available;
- optional secondary entry: generic/custom photo size, only if clearly separated from validated official profiles;
- Settings/About access.

Do not ask for permissions here.

### Screen 2 — Country

Purpose: choose jurisdiction.

Content:

- search field;
- suggested/recent countries;
- alphabetical list;
- localized country name;
- optional flag as secondary visual cue, never the only identifier.

### Screen 3 — Document type

Purpose: choose the exact profile.

Each item should show:

- document name;
- short output dimension summary;
- `Official rules verified` or equivalent trust label only when provenance requirements are satisfied;
- last-reviewed detail on demand.

### Screen 4 — Requirements summary

Purpose: tell the user how to prepare the source photo before taking/importing it.

Recommended content:

- large simple illustration/guide;
- background instruction;
- face/pose instruction;
- glasses/headwear/expression summary where relevant;
- photo age/recency guidance if the profile specifies it;
- `Take photo` primary action;
- `Choose existing photo` secondary action;
- `View full requirements` tertiary action.

This screen should reduce avoidable retakes.

### Screen 5A — Camera

Purpose: acquire a usable source.

Possible overlays:

- approximate face oval/frame;
- headroom indicator;
- simple distance guidance;
- lighting warning if available in real time;
- camera switch where appropriate;
- shutter.

Do not promise real-time official compliance unless the implementation actually evaluates the required conditions.

After capture, show confirmation only if needed; otherwise proceed directly to analysis.

### Screen 5B — Native photo picker

Use the platform picker rather than building a custom full photo-library UI unless a strong requirement appears.

### Screen 6 — Analysis

Purpose: provide fast feedback while processing.

The loading state should communicate actual stages only if they help perceived progress, e.g.:

- checking photo;
- finding face;
- preparing background;
- applying document rules.

Avoid fake precision percentages unless work progress is genuinely measurable.

### Screen 7 — Photo check

Purpose: summarize source suitability.

Structure:

- photo preview;
- overall state;
- grouped checks;
- clear next action.

Overall-state examples:

**Ready**
- “The measurable checks look good. Review the remaining manual requirements before export.”

**Needs review**
- “A few items need your attention.”

**Retake recommended**
- “This source photo is unlikely to produce a good result.”

Each check row contains:

- state icon;
- short label;
- one-line explanation;
- optional `How to fix` expansion.

Manual checks are always visible.

### Screen 8 — Editor

Purpose: produce the final composition.

Recommended default layout:

- large photo canvas;
- rule guides;
- compliance status chip/summary;
- compact control tray.

Control groups:

1. **Position** — drag/pinch plus accessible buttons/step controls.
2. **Background** — automatic/original/permitted color choices.
3. **Mask refine** — only when needed.
4. **Adjust** — only allowed limited corrections.
5. **Reset**.

Do not expose generic filters, stickers, effects, face retouching, text, or decorative tools.

The primary action is `Continue` / `Export` once no hard measurable failures remain. The app may allow export with warnings/manual checks if policy permits, but the warning must be explicit.

### Screen 9 — Export choice

Two primary cards/options:

- `Digital photo`
- `Print sheet`

Each explains what the user receives.

### Screen 10A — Digital export

Show:

- final size in pixels and/or physical unit according to profile;
- file format;
- estimated/actual file size if relevant;
- remaining manual checks;
- primary `Save / Share` action.

If a profile defines an upload file-size limit, report whether the generated file satisfies it.

### Screen 10B — Print setup

Show:

- paper size;
- paper orientation if user-selectable;
- number of copies;
- layout preview;
- cutting guides toggle if supported;
- `Generate PDF` primary action.

After PDF generation, show a prominent printing instruction: use **Actual size / 100% scale** and disable fit-to-page scaling.

### Screen 11 — Completion

Keep this lightweight.

Actions:

- share/save again;
- create another format from the same edited photo where safe;
- start a new photo;
- optionally ask for non-intrusive feedback.

Do not trap the user in an upsell after successful completion.

## 5. Secondary flows

### 5.1 Change document profile mid-job

Changing to another profile should preserve the normalized source and non-destructive edits where compatible, then recompute crop/rules. The user must be warned if a background or edit allowed in the first profile is not allowed in the second.

### 5.2 Permission denied

Never show a dead-end error.

Camera permission denied:

- explain why permission is needed;
- offer `Open Settings` where supported;
- offer `Choose existing photo`.

Photo permission constrained:

- use native limited picker;
- do not demand full-library permission without a feature need.

### 5.3 No face / multiple faces

No face:

- show example of acceptable source;
- retry;
- choose another photo.

Multiple faces:

- explain that the app needs a single subject for reliable ID formatting;
- choose another image/retake;
- only add manual face selection later if validated as safe and useful.

### 5.4 Segmentation failure

Options depend on rule profile:

- use original background if acceptable;
- refine mask manually;
- retake on a simpler background.

Never output an obviously broken edge without warning.

### 5.5 Low resolution

Explain whether:

- digital output is impossible;
- print output is likely to be soft;
- a smaller supported format remains possible.

Avoid silent aggressive upscaling.

### 5.6 Offline

Core flow continues. If future remote catalog update or support content needs network, explain that separately without blocking shipped rules.

## 6. Design language

The app should feel trustworthy, modern, and utilitarian rather than playful or bureaucratic.

Recommended visual characteristics:

- neutral base palette;
- one clear brand accent;
- status colors with icons/text redundancy;
- generous whitespace;
- large portrait previews;
- subtle separators rather than dense cards everywhere;
- restrained motion;
- no fake camera chrome;
- no banner/interstitial advertising in the core flow.

## 7. Status design

Use consistent semantics across the entire app:

| State | Meaning | UX treatment |
|---|---|---|
| Pass | Machine-checkable requirement appears satisfied | positive icon + concise confirmation |
| Warn | Risk or low-confidence issue | warning icon + action/review guidance |
| Fail | Measurable requirement clearly not satisfied | blocking/error icon + fix action |
| Manual check | App cannot safely validate | neutral review icon + user checklist |

The overall status is derived from individual checks; it must not hide them.

## 8. Photo editor interaction model

### Gestures

- drag = translate photo/subject within frame;
- pinch = scale within safe limits;
- optional two-finger rotation only if document policy and UX tests justify it; otherwise avoid exposing it.

### Accessibility alternatives

Provide buttons/controls for:

- move up/down/left/right;
- zoom in/out;
- reset automatic position;
- select background;
- enter mask correction.

### Constraint behavior

Do not hard-lock every movement just because it crosses a recommended boundary; this can feel broken. Prefer live failure/warning feedback, with hard bounds only where output would become impossible (for example empty pixels inside crop).

## 9. Camera guidance strategy

The camera should optimize for source quality rather than attempt to duplicate the full final crop.

Useful guidance:

- one person only;
- camera at face height;
- stand away from wall to reduce shadows;
- even frontal lighting;
- neutral expression where required;
- enough room around shoulders/head;
- avoid digital zoom;
- clean lens.

For baby/child profiles, guidance must adapt where official rules differ.

## 10. Error-writing rules

Every error should answer:

1. What happened?
2. Why does it matter?
3. What can the user do now?

Bad:

> Error 204: segmentation confidence insufficient.

Better:

> We could not separate the hair cleanly from the background. Try a photo taken farther from the wall, use the original background, or correct the edge manually.

## 11. Localization UX

- Never embed numeric values inside non-localizable images.
- Country/document names require localized aliases.
- Units should follow profile requirements first, then optionally show user-familiar equivalents.
- Avoid fixed-width controls based on English labels.
- Screenshots/illustrations should not contain baked-in explanatory text where possible.

## 12. Accessibility checklist by screen

For every screen:

- logical focus order;
- descriptive page title/announcement;
- every icon button has a label;
- image preview has useful semantics without describing sensitive visual identity unnecessarily;
- warnings announced after analysis;
- status is not color-only;
- editor has non-gesture controls;
- text scales without hiding primary actions;
- landscape behavior is intentionally supported or intentionally constrained with rationale.

## 13. Empty/loading/error states that must be designed

Before implementation is considered UI-complete, designs must exist for:

- no recent profiles;
- no search results;
- rules catalog unavailable/corrupt;
- camera permission denied/restricted;
- photo-picker cancellation;
- image decode failure;
- unsupported image type;
- image too small;
- no face;
- multiple faces;
- detector failure;
- segmentation failure;
- processing cancelled;
- export failure;
- storage/share failure;
- PDF generation failure;
- offline remote-update failure;
- invalid/outdated profile warning.

## 14. UX validation plan

Test prototypes with tasks, not preference questions.

Representative tasks:

1. “Create a passport photo from a photo already on your phone.”
2. “The app says the photo is blurry. What would you do?”
3. “Move the face into the correct position.”
4. “Tell me which checks the app cannot verify for you.”
5. “Create a page with six printable copies.”
6. “Find the source/date for this document requirement.”
7. “Recover after denying camera permission.”

Measure:

- task completion;
- time on task;
- wrong turns;
- misunderstanding of status;
- whether users incorrectly interpret `Ready` as guaranteed government acceptance;
- editor accessibility and gesture discoverability.

## 15. Design deliverables before production UI implementation

Required artifacts:

- complete screen map;
- low-fidelity wireframes for all primary/error states;
- clickable prototype of the main flow;
- design tokens;
- component inventory;
- editor interaction prototype;
- accessibility annotations;
- localization stress-test screens;
- final visual design for the primary path;
- App Store / Google Play screenshot plan later in M8.
