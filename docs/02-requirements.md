# 02 — Requirements

This document defines the initial functional and non-functional requirements. IDs are stable references for design, code, tests, issues, and release gates.

## 1. Requirement conventions

Priorities:

- **P0** — required for MVP/release viability.
- **P1** — strongly desired for MVP; may move only with an explicit decision.
- **P2** — post-MVP or opportunistic.

A requirement is not complete until its acceptance criteria are testable.

---

## 2. App launch and onboarding

### FR-001 — Launch without account — P0

The user can enter the core app without registration, login, email, phone number, or cloud account.

Acceptance criteria:

- first launch reaches product entry flow without authentication;
- no account is required to take/import, process, or export a supported photo;
- optional services that later require an account are clearly separated.

### FR-002 — First-use privacy explanation — P0

Explain that identity photos are processed locally by default and identify any optional feature that would transmit data.

Acceptance criteria:

- short, plain-language first-use explanation;
- detailed privacy information remains accessible from Settings/About;
- no permission is requested before the user initiates a feature requiring it.

### FR-003 — Optional onboarding — P1

Onboarding can be skipped and must not block the first core task.

---

## 3. Country and document selection

### FR-010 — Country selection — P0

The user can select the relevant country/jurisdiction from the published rule catalog.

### FR-011 — Document/use-case selection — P0

After country selection, show supported document profiles such as passport, visa, national ID, residence permit, driving licence, or non-official photo format.

### FR-012 — Search — P1

Search countries and document names using localized names plus common aliases.

### FR-013 — Recent profiles — P1

Show recently used profiles locally on device.

### FR-014 — Requirement preview — P0

Before image selection, show a concise requirement summary including output size, background guidance, and major pose/expression constraints.

### FR-015 — Source/provenance view — P0

For every official profile, show source label/URL metadata, revision/review date, and app rule version.

### FR-016 — Unsupported profile handling — P0

If a profile is not supported, do not silently substitute a similar standard. Offer generic/manual sizing only when clearly labelled as non-validated.

---

## 4. Image acquisition

### FR-020 — Camera capture — P0

Allow capture with the device camera using platform permission flows.

Acceptance criteria:

- permission requested only after tapping camera action;
- denied/restricted states provide recovery instructions;
- preview respects device orientation;
- captured image enters the same normalized pipeline as imports.

### FR-021 — Photo-library import — P0

Allow selecting an existing image using platform-native pickers.

### FR-022 — Limited-library support — P0

Support modern OS limited-photo-library permission models without requiring full-library access.

### FR-023 — File validation — P0

Reject unsupported, unreadable, corrupt, or excessively small images with actionable errors.

### FR-024 — Orientation normalization — P0

Normalize pixel orientation before analysis while preserving required metadata separately.

### FR-025 — Multiple faces — P0

If multiple plausible faces are detected, prevent automatic continuation until the intended subject can be resolved safely; MVP may require retake/import of a single-subject image rather than manual face selection.

### FR-026 — No face detected — P0

Explain likely causes and let the user retry, choose another image, or enter a limited manual crop path if product policy permits.

---

## 5. Source-photo analysis

### FR-030 — Face detection — P0

Detect the primary face and a minimum landmark set needed for composition checks.

### FR-031 — Face confidence — P0

Store confidence/quality information from the detector and do not treat low-confidence results as precise measurements.

### FR-032 — Image sharpness/blur screening — P0

Estimate whether blur is likely to compromise the output.

### FR-033 — Exposure screening — P0

Detect severe underexposure/overexposure and clipped regions where practical.

### FR-034 — Resolution sufficiency — P0

Determine whether source resolution can produce the requested digital/print output without unacceptable upscaling.

### FR-035 — Head-size check — P0

Where a document rule defines measurable head size or face occupancy, calculate and compare against the specified tolerance.

### FR-036 — Head-position check — P0

Where measurable, validate vertical/horizontal head position and required top/bottom spacing.

### FR-037 — Rotation/tilt warning — P1

Estimate significant in-plane head/camera rotation and warn when it likely violates requirements.

### FR-038 — Occlusion risk — P1

Where reliable, warn about likely eye/face occlusion. Never hard-fail solely from a low-confidence classifier.

### FR-039 — Expression/eye-state guidance — P1

May provide warnings when confidence is adequate, but rules involving expression, gaze, mouth position, glasses reflection, or subjective appearance must support `manual_check` rather than false certainty.

### FR-040 — Analysis report — P0

Present results as individual checks with `pass`, `warn`, `fail`, or `manual_check` state and a human-readable remedy.

---

## 6. Background processing

### FR-050 — Subject segmentation — P0

Generate a foreground/background mask suitable for ID-photo output.

### FR-051 — Rule-aware background action — P0

Do not automatically replace a background if the selected profile forbids or makes such alteration inappropriate. The rule profile determines what actions are offered.

### FR-052 — Background replacement — P0

Where allowed, replace the background using a permitted solid or controlled background value.

### FR-053 — Edge quality — P0

Preserve fine hair and edge detail as far as the chosen model/algorithm can reliably support.

### FR-054 — Manual mask correction — P1

Provide a simple correction mode for erase/restore operations when automatic segmentation is visibly wrong.

### FR-055 — Segmentation uncertainty — P0

When confidence/quality is inadequate, show the original-background path or recommend a new source image rather than hiding defects.

### FR-056 — No identity alteration — P0

Background tools must not alter facial structure, skin texture, hairline, ears, clothing boundary, or other identity-bearing pixels beyond operations needed at the segmentation boundary.

---

## 7. Crop, alignment, and composition

### FR-060 — Rule-derived crop — P0

Generate the crop from document-profile dimensions and measured subject geometry.

### FR-061 — Aspect-ratio lock — P0

The final crop maintains the exact required aspect ratio.

### FR-062 — Deterministic geometry — P0

Given identical source pixels, rule version, and edit parameters, the crop/output geometry is deterministic.

### FR-063 — Automatic alignment — P0

Provide an initial crop/position that targets rule constraints.

### FR-064 — Manual adjustment — P0

Allow translation and permitted scale adjustment without breaking aspect ratio.

### FR-065 — Live compliance overlays — P1

Show head/eye guides or safe zones when they materially help the user understand composition.

### FR-066 — Constraint feedback — P0

If manual movement causes a measurable rule failure, update the check state immediately or after a bounded debounce.

### FR-067 — Original preservation — P0

All crop/edit operations remain parameterized and non-destructive until export.

---

## 8. Editing policy

### FR-070 — Basic corrections — P1

Permitted corrections may include limited brightness/contrast or white-balance normalization only if they do not misrepresent appearance and are allowed by product policy.

### FR-071 — No beautification for official mode — P0

No skin smoothing, face reshaping, eye enlargement, makeup synthesis, wrinkle removal, or generative facial edits in official-document mode.

### FR-072 — Reset — P0

Each editing stage has a clear reset to automatic/original state.

### FR-073 — Before/after — P1

Allow comparison with the normalized original without confusing the original with the export result.

---

## 9. Digital export

### FR-080 — Exact pixel dimensions — P0

When a profile specifies pixel dimensions, export exactly those dimensions.

### FR-081 — Physical dimensions + resolution — P0

When a profile specifies physical dimensions and DPI/PPI expectations, calculate pixel dimensions deterministically and record the conversion rule.

### FR-082 — File format — P0

Support output formats required by published profiles; JPEG is baseline, PNG where appropriate.

### FR-083 — File-size constraint — P1

Where an official profile imposes a maximum/minimum file size, provide controlled JPEG quality iteration while preserving dimensions and avoiding needless quality loss.

### FR-084 — Color profile — P1

Normalize/export using a well-defined color space compatible with common submission systems and test it across platforms.

### FR-085 — Metadata policy — P0

Strip unnecessary sensitive metadata such as geolocation. Retain only metadata required for output correctness or explicitly selected by product policy.

### FR-086 — Save/share — P0

Use native share/save flows.

### FR-087 — Export validation — P0

After encoding, re-open/inspect the generated file to confirm actual pixel dimensions and encoding succeeded before reporting success.

### FR-088 — No surprise watermark — P0

Do not add a watermark unless that limitation was clearly disclosed before the user invested effort in the workflow.

---

## 10. Print-sheet export

### FR-090 — Paper selection — P0

Support an initial set of common paper/photo sizes driven by configuration.

### FR-091 — Physical-size accuracy — P0

Each placed photo has a mathematically correct physical size at 100% print scale.

### FR-092 — Layout optimization — P0

Fit the maximum practical number of copies while respecting configurable margins, gutters, cut spacing, and orientation.

### FR-093 — Copy count — P1

Allow the user to request a copy count and choose a layout accordingly.

### FR-094 — Cut guides — P1

Optional non-intrusive cut marks may be generated outside photo content.

### FR-095 — PDF output — P0

Generate a print-ready PDF with a defined page size. The UI must warn users to disable printer/page scaling and print at 100%/actual size.

### FR-096 — Raster print sheet — P1

Optionally export a high-resolution raster sheet for photo-kiosk workflows where PDF is inconvenient.

### FR-097 — Physical calibration test — P0

Release QA must physically print representative sheets on multiple printer paths and measure output sizes.

---

## 11. Rules and content

### FR-100 — Versioned rule profiles — P0

Each country/document profile has a stable ID and semantic/internal version.

### FR-101 — Provenance — P0

Each official rule includes source metadata and reviewed date.

### FR-102 — Effective dates — P1

Rule schema supports effective-from/effective-to fields where requirements change over time.

### FR-103 — Localization — P0

User-facing profile names, instructions, warnings, and manual-check text are localizable independently from numeric constraints.

### FR-104 — Rule validation — P0

Invalid or incomplete profiles cannot be loaded silently. Schema validation failures must fail safely in development/CI and exclude invalid profiles from production publication.

### FR-105 — Catalog update mechanism — P1

Architecture supports signed/versioned rule-catalog updates without requiring a full app release, but MVP may initially ship catalog updates with app releases until remote-update security is implemented.

---

## 12. Privacy and local data

### FR-110 — Local processing default — P0

Core image processing occurs on-device unless a future feature has a documented exception.

### FR-111 — Temporary working files — P0

Working files are deleted when no longer required and are not written to shared/public storage unnecessarily.

### FR-112 — No background upload — P0

No image upload occurs without a user action and explicit product behavior requiring it.

### FR-113 — Local recent history — P1

If recent jobs are stored, provide a setting to disable/clear them and define retention behavior.

### FR-114 — Analytics minimization — P0

Analytics events must not contain image pixels, face embeddings, file paths, person names, document numbers, or arbitrary user-entered sensitive text.

---

## 13. Settings and help

### FR-120 — Language — P1

Use system language by default and allow in-app override if supported by framework/product policy.

### FR-121 — Privacy controls — P0

Provide clear access to privacy information, analytics/crash-reporting controls where required, and local-data clearing.

### FR-122 — About rule data — P0

Explain that official requirements can change and provide last-reviewed information.

### FR-123 — Troubleshooting — P1

Provide guidance for camera permissions, export permissions, printing scale, and rejected photos.

---

## 14. Accessibility

### NFR-A11Y-001 — Screen-reader semantics — P0

All primary controls and status checks have meaningful accessibility labels and roles.

### NFR-A11Y-002 — Scalable text — P0

Primary flows remain usable at large accessibility text sizes without clipped critical content.

### NFR-A11Y-003 — Status independence from color — P0

Pass/warn/fail/manual states use text/icon semantics, not color alone.

### NFR-A11Y-004 — Touch targets — P0

Interactive targets meet platform minimum guidance.

### NFR-A11Y-005 — Editor alternatives — P1

Where gestures adjust crop/position, provide accessible controls or stepper-like alternatives for users unable to perform precise pinch/drag gestures.

---

## 15. Performance

Exact budgets are to be baselined during M1 on representative devices.

### NFR-PERF-001 — Responsive UI — P0

Image processing does not block the main/UI thread long enough to create visible hangs.

### NFR-PERF-002 — Bounded memory — P0

Large camera images are decoded/processsed using bounded-resolution stages where full resolution is unnecessary; export uses a memory-safe full-resolution path.

### NFR-PERF-003 — Processing targets — P1

Technical spike will set median/p95 budgets for face detection, segmentation, preview render, and export on low/mid/high device tiers.

### NFR-PERF-004 — Startup — P1

Cold startup should avoid loading heavy ML models until needed unless profiling proves preload improves total UX without excessive memory cost.

---

## 16. Reliability and compatibility

### NFR-REL-001 — Offline core — P0

Previously shipped document profiles and all core editing/export functions work without network access.

### NFR-REL-002 — Crash safety — P0

Unexpected failures during processing never overwrite the source image.

### NFR-REL-003 — Recoverable job — P1

Where practical, preserve non-sensitive edit parameters after app interruption so the user does not lose work.

### NFR-REL-004 — Platform support policy — P0

Minimum iOS/Android versions are explicitly selected at M1 based on framework support, market coverage, ML APIs, security updates, and test capacity.

---

## 17. Security

### NFR-SEC-001 — Dependency review — P0

Every third-party SDK/package is reviewed for maintenance, licence, privacy behavior, binary size, native permissions, and security history before adoption.

### NFR-SEC-002 — No secrets in repo — P0

Signing keys, API keys, certificates, service credentials, and production secrets are never committed.

### NFR-SEC-003 — Supply-chain scanning — P1

CI should include dependency vulnerability/license checks where practical.

### NFR-SEC-004 — Signed remote rules — P0 if remote updates ship

If the rules catalog becomes remotely updateable, app clients must verify authenticity/integrity before activation and retain a known-good fallback.

---

## 18. Observability

### NFR-OBS-001 — Privacy-safe errors — P0

Diagnostics identify pipeline stage and error class without sending image content.

### NFR-OBS-002 — Structured events — P1

If analytics is enabled, use a documented event schema with stable names and no free-form photo-related payloads.

### NFR-OBS-003 — Local debug bundle — P2

For development/support, consider an explicitly user-triggered diagnostic bundle containing app version, device class, rule profile ID/version, and non-sensitive error traces—but never photos by default.

---

## 19. Localization

### NFR-I18N-001 — No hard-coded UI strings — P0

Production UI strings live in localization resources.

### NFR-I18N-002 — Long-text tolerance — P0

Layouts support materially longer translated strings.

### NFR-I18N-003 — RTL readiness — P1

Architecture and layouts should not make irreversible assumptions that block right-to-left languages.

### NFR-I18N-004 — Rule-language separation — P0

Numeric/legal rule data is not duplicated per language; translated explanations reference the same canonical rule IDs.

---

## 20. Release requirements

### REL-001 — No P0/P1 blocker — P0

No open P0 defects; no P1 defect affecting correctness, privacy, data loss, export fidelity, or primary navigation.

### REL-002 — Rule audit — P0

Every launch profile has current source evidence and completed validation fixtures.

### REL-003 — Physical-device test — P0

Run end-to-end capture/import/export on the supported device matrix, not simulators alone.

### REL-004 — Print measurement — P0

Print-sheet dimensions pass physical measurement tests.

### REL-005 — Store assets/legal — P0

Privacy policy, permission strings, store privacy disclosures, screenshots, support information, age rating, and required platform declarations are reviewed before submission.

### REL-006 — Rollback/kill strategy — P1

Have a documented response for a bad rule profile or severe processing bug. If remote rule controls do not exist, define expedited app-release procedure and in-app warning options available to the shipped build.
