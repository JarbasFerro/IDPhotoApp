# 08 — iOS privacy and security

## 1. Privacy posture

Identity photos are sensitive personal data. The product is designed so the normal workflow does not need to transmit or permanently retain them.

Default posture:

- on-device processing;
- no account;
- no cloud upload for the core workflow;
- no advertising SDK;
- no biometric identity template storage;
- no permanent photo history by default;
- no EXIF geolocation in normal exports;
- no image/landmark data in logs or analytics;
- minimal permissions through point-of-use system APIs;
- privacy manifest included from production project bootstrap.

The intended user-facing truth should remain simple:

> **Your photo is processed on your iPhone for the normal workflow.**

## 2. Apple privacy architecture

### `PrivacyInfo.xcprivacy`

The production app target includes a privacy manifest from the beginning.

It must accurately declare:

- data collected by the app, if any;
- required-reason API usage by app code;
- the actual behavior of linked SDKs/frameworks where applicable.

Every third-party SDK must provide/reconcile its own privacy manifest requirements where Apple requires it.

### Required-reason APIs

Before adopting an API or dependency, verify current Apple required-reason API policy.

Rules:

- declare only approved reasons that actually match product behavior;
- do not select a reason merely to silence App Store validation;
- re-audit after major dependency/SDK changes;
- use Xcode privacy reports where available to inspect aggregate app/SDK behavior.

### Tracking / fingerprinting

The app has no product need for cross-app tracking or device fingerprinting.

Advertising/attribution SDKs are therefore disfavored by architecture, not merely disabled by configuration.

## 3. Data inventory

### 3.1 Source photo

Purpose: create requested ID output.

Location: app memory and/or app-private temporary storage.

Retention: active job only unless a future resume/history feature is explicitly enabled.

Network: none in the core workflow.

### 3.2 Derived face/image data

Includes:

- Vision face bounding boxes;
- landmarks/pose;
- quality scores;
- segmentation masks;
- crop parameters;
- preview caches.

Treat as sensitive working data.

Default retention: active job / short-lived private cache only.

### 3.3 Exported photo/PDF

Created only from explicit user action.

The user chooses the destination through native iOS share/save/print mechanisms.

The app should not silently keep a separate permanent copy after successful export.

### 3.4 Preferences

May include:

- language/locale override if offered;
- recent/favorite profile IDs;
- installed rule-catalog version;
- non-sensitive product settings;
- entitlement state as appropriate.

### 3.5 Telemetry

If enabled later, only structured privacy-reviewed events.

Never include:

- photo bytes;
- thumbnails;
- image hashes used as identifiers;
- face embeddings;
- landmark arrays;
- EXIF/GPS;
- sensitive file paths;
- person/document identity;
- free-form context containing sensitive data.

## 4. Baseline data flow

```text
AVFoundation camera / PhotosPicker
              │
              ▼
      private source asset
              │
       ┌──────┼─────────┐
       │      │         │
       ▼      ▼         ▼
  downsample Vision  segmentation
  analysis   face      mask
       │      │         │
       └──────┼─────────┘
              ▼
      deterministic rules
              │
              ▼
      Core Image renderer
              │
              ▼
     generated image / PDF
              │
              ▼
   user Share / Save / Print
```

No network arrow exists in the core flow.

## 5. Permission strategy

### Camera

Use AVFoundation authorization only after the user chooses `Take Photo`.

`NSCameraUsageDescription` must be short, specific, and truthful.

No camera permission request on launch/onboarding.

### Photos

Use PhotosUI/`PhotosPicker` for normal import.

The standard flow should therefore not request broad Photo Library permission merely to select one image.

If a future feature requires Photo Library write/read authorization, introduce it through a separate explicit requirement/decision.

### Files / printing

Use system share/document/print UI. Do not create broad file-system access patterns.

### Network

Future rule updates, StoreKit, support content, or privacy-safe diagnostics may use network access. None justify sending user face photos by default.

## 6. File protection and temporary data

Sensitive temporary data should:

- live in app-private directories;
- use appropriate iOS Data Protection/file-protection class for the workflow;
- use non-identifying unpredictable filenames;
- avoid filenames containing person/document details;
- be deleted when no longer needed;
- be cleaned after abandoned/interrupted jobs;
- be excluded from backup when ephemeral;
- never be written into shared/public locations without user export action.

In-memory processing is preferred where efficient, but forcing 48 MP sources to remain entirely memory-resident can increase crash risk. Private temporary files are acceptable when lifecycle is deliberate.

## 7. Original-photo safety

Never modify the source Photos asset in place.

Captured/imported input becomes an immutable internal source reference. Edits are parameters until a new output file is rendered.

Export failures must leave source and prior successful outputs untouched.

## 8. Metadata policy

### Import

Read only what supports correct processing, including:

- orientation;
- image dimensions;
- format;
- color profile information where needed.

Do not collect metadata “just in case.”

### Export

Normal official-photo exports should strip:

- GPS/location;
- unnecessary capture/device metadata;
- original comments/software strings where unnecessary;
- private/source file identifiers.

Write only metadata intentionally required for interoperability/profile requirements.

Test actual encoded output metadata.

## 9. Face / biometric policy

The app detects/analyzes a face locally to format a photo. It does not need to identify the person.

Do not create persistent face embeddings/templates for recognition.

No identity matching or database comparison.

Future identity verification/recognition requires a completely separate privacy/security/legal review.

## 10. Foundation Models / Core AI privacy boundary

Optional intelligence must not silently change the data flow.

### On-device Foundation Models

May be considered for explanation/coaching if useful.

Requirements:

- feature works without uploading face data;
- user-facing compliance remains deterministic;
- model-unavailable fallback;
- logs do not contain prompts with sensitive image/path content.

### Private Cloud Compute / external model providers

Not part of baseline architecture.

Any future cloud-model use requires a new ADR covering:

- exact image/text transmitted;
- user value;
- explicit UI disclosure/consent as appropriate;
- retention/provider terms;
- region/availability;
- fallback;
- App Privacy disclosures;
- child-photo implications.

## 11. Logging

Use Apple unified logging (`Logger`) with privacy annotations/redaction.

Production logs must never contain:

- images/base64;
- thumbnails;
- landmarks;
- local source filenames/paths when sensitive;
- EXIF dumps;
- names/document numbers;
- model prompts containing sensitive photo context;
- secrets/tokens.

Prefer stable error codes and coarse safe diagnostics.

## 12. Diagnostics / MetricKit / crash reporting

Start with:

- development Instruments;
- privacy-safe `Logger` events;
- `OSSignposter` intervals;
- MetricKit only if production value justifies it.

Before adding third-party crash/analytics:

- inspect default collection;
- disable screenshots/session replay;
- prevent photo attachments;
- sanitize breadcrumbs;
- document retention/vendor data flow;
- validate privacy manifest/required-reason behavior;
- confirm App Privacy answers.

## 13. Allowed telemetry examples

Potential structured values:

```text
app_version
os_major_version
profile_id
profile_version
processing_stage
processing_duration_bucket
validation_state_category
export_type
structured_error_code
performance_bucket
```

Never use telemetry to reconstruct a person’s face or image.

## 14. Secrets and signing

Never commit:

- Apple signing certificates/private keys;
- App Store Connect API private keys;
- provisioning credentials;
- backend keys/tokens;
- analytics/service credentials;
- rule-signing private keys.

Use Apple/Xcode Cloud/GitHub secret stores or local Keychain/environment configuration as appropriate.

If a secret is committed, rotate it. Deleting the file later does not undo exposure.

## 15. Dependency security

Apple-frameworks-first reduces attack/privacy surface.

Every non-Apple dependency requires review for:

- necessity;
- why Apple APIs are insufficient;
- maintenance/reputation;
- license;
- vulnerabilities;
- transitive dependencies;
- network calls;
- data collection;
- privacy manifest;
- required-reason APIs;
- permissions;
- binary size;
- replaceability.

High-scrutiny categories:

- camera;
- ML/AI;
- analytics/crash;
- attribution/ads;
- image codecs/editing;
- PDF;
- storage/networking.

## 16. Advertising policy

Preferred baseline: no advertising SDK.

Reasons:

- product motivation includes ad-heavy competitor frustration;
- identity photos are sensitive;
- ad/attribution SDKs increase privacy and dependency surface;
- monetization can use StoreKit directly if needed.

Any future advertising proposal requires a new explicit ADR and cannot receive photo/derived face content.

## 17. Threat model

### T-01 — Accidental image upload

Controls:

- no upload endpoint in core architecture;
- local Apple frameworks;
- dependency review;
- network inspection testing;
- telemetry allowlist.

### T-02 — Sensitive data in logs/diagnostics

Controls:

- privacy-marked Logger fields;
- typed errors;
- no image/path/EXIF dumps;
- diagnostics test review.

### T-03 — Temporary file exposure

Controls:

- app-private directories;
- iOS Data Protection;
- backup exclusion where appropriate;
- cleanup lifecycle;
- no shared files before explicit export.

### T-04 — Oversized/malformed image denial of service

Controls:

- ImageIO header inspection;
- bounded/downsampled analysis decode;
- pixel/dimension guardrails;
- typed failure;
- memory profiling.

### T-05 — Source overwrite/data loss

Controls:

- immutable source;
- separate output URLs;
- atomic writes where appropriate;
- tests.

### T-06 — Incorrect/malicious rule catalog

Controls:

- schema/semantic validation;
- source provenance;
- bundled known-good rules for MVP;
- signed/atomic/rollback model if remote updates are added.

### T-07 — Dependency compromise

Controls:

- minimal dependencies;
- lockfile review;
- update/vulnerability process;
- avoid opaque binary SDKs;
- Apple framework preference.

### T-08 — False compliance / trust failure

Controls:

- pass/warn/fail/manual states;
- conservative thresholds;
- manual checks remain visible;
- sourced rules;
- no acceptance guarantee;
- regression/calibration tests.

### T-09 — Optional AI invents rules

Controls:

- deterministic rule engine remains authoritative;
- constrained official context;
- explicit AI-assistance presentation;
- evaluations;
- no model output writes directly into rule catalog or hard compliance result.

## 18. Remote rule updates

If added later, treat remote content as untrusted until verified.

Recommended:

1. app contains trusted public verification key;
2. protected/offline private key signs catalog/manifest;
3. client verifies signature/hash;
4. schema compatibility validation;
5. semantic validation;
6. staging;
7. atomic activation;
8. previous version retained;
9. failure keeps known-good active rules.

Private signing key never ships in app or repository.

## 19. Payments

If monetized:

- StoreKit is default;
- entitlement data stays separate from photos;
- no login unless genuine portability need arises;
- no photo transmission for entitlement validation;
- offline/grace behavior defined.

## 20. Child photos

Parent use increases the need for:

- local processing;
- no photo history default;
- no ad profiling;
- no cloud model training on user photos;
- short-lived derived data;
- clear deletion behavior.

Any cloud feature involving child photos requires separate legal/privacy review.

## 21. Privacy UX

Explain privacy at meaningful points rather than through one giant onboarding screen.

Recommended:

- concise first-use privacy statement;
- permission explanation at point of use;
- Settings → Privacy/About explanation;
- deletion controls if persistent job data ever exists;
- explicit disclosure before any optional future off-device feature.

Avoid consent bundling for unrelated purposes.

## 22. Release privacy checklist

Before every App Store release:

- [ ] `PrivacyInfo.xcprivacy` valid.
- [ ] Required-reason APIs re-audited.
- [ ] Third-party SDK privacy manifests reviewed.
- [ ] Runtime network calls inspected.
- [ ] Core flow works with network disabled.
- [ ] Camera purpose string accurate.
- [ ] No unnecessary Photo Library permission.
- [ ] App Privacy answers match binary.
- [ ] Privacy policy matches actual data flow.
- [ ] Temp cleanup verified.
- [ ] EXIF/GPS stripping verified.
- [ ] Logs/diagnostics sampled for sensitive leakage.
- [ ] No test endpoint/credential.
- [ ] Remote rules signature logic verified if enabled.
- [ ] Optional AI data flow re-reviewed if changed.

Apple policy changes over time; compare this list to current official documentation at release time.

## 23. Security/privacy release blockers

Release is blocked by:

- unexplained photo/derived-data network transmission;
- committed active secret;
- critical unmitigated dependency vulnerability affecting shipped path;
- source overwrite/data-loss risk;
- invalid/inaccurate privacy manifest;
- inaccurate App Privacy disclosure;
- sensitive image/face data in telemetry/crash logs;
- public/shared temporary source storage without explicit user action;
- insecure remote-rule activation;
- optional AI transmitting sensitive data contrary to product disclosure.