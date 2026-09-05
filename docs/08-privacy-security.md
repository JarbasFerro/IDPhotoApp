# 08 — Privacy and security

## 1. Privacy posture

Identity photos are sensitive personal data in ordinary use. The product should be designed so that the main workflow does not need to transmit or permanently retain them.

Default posture:

- process on device;
- no account required;
- no cloud upload for the core workflow;
- no advertising SDK access to images;
- no biometric face-template storage;
- no unnecessary photo history;
- no EXIF geolocation in exports unless an explicit future requirement justifies it;
- no raw image data in analytics or crash logs.

## 2. Data inventory

### 2.1 Source photo

Purpose: create the requested output.

Default location: device-local application memory/private temporary storage.

Retention: only as long as needed for the active job unless the user explicitly chooses a future save/resume feature.

Network transmission: none for the core workflow.

### 2.2 Derived analysis data

Examples:

- face bounding box;
- landmarks;
- quality scores;
- segmentation mask;
- crop parameters.

These are treated as sensitive working data because they derive from a face image.

Default retention: active job only; temporary cache where needed for performance.

### 2.3 Exported photo

Created only on user action.

The user chooses save/share destination through platform mechanisms.

The app should not silently retain another permanent copy after successful export unless a clearly communicated history feature is enabled.

### 2.4 Preferences

Examples:

- language;
- recent document-profile IDs;
- favourite profiles;
- analytics preference;
- installed rule-catalog version.

These contain no photo pixels and can be stored persistently.

### 2.5 Telemetry

If used, only structured, privacy-reviewed events are allowed. No image, thumbnail, face embedding, local file path, EXIF, person identity, document number, or free-form sensitive content.

## 3. Data-flow baseline

```text
Camera / Photo Picker
        │
        ▼
Private local source reference
        │
        ├──> bounded analysis bitmap ──> face/quality analysis
        │                                │
        │                                └──> derived measurements
        │
        ├──> segmentation ──> temporary mask
        │
        └──> final renderer + edit parameters
                         │
                         ▼
                  generated output
                         │
                         ▼
               user-triggered Save/Share
```

No network arrow exists in the baseline core flow.

## 4. Permission strategy

### Camera

Request only after the user taps `Take photo`.

Permission text must explain the actual purpose plainly.

### Photos/media

Prefer platform-native pickers that minimize broad library access. Do not request full-library access just to select one image if the platform offers a scoped picker.

### Storage/files

Use platform-native save/share/document mechanisms. Avoid legacy broad external-storage permissions.

### Network

The app may need network access later for rule updates, purchase infrastructure, help pages, or privacy-safe telemetry. None of those justify uploading source photos.

## 5. Temporary-file policy

Temporary image data must:

- live in application-private cache/temp locations;
- use unpredictable file names where filenames are needed;
- avoid names containing person/document identity;
- be deleted on successful job completion where no longer required;
- be cleaned on cancellation/abandonment according to lifecycle policy;
- be eligible for startup/periodic stale-cache cleanup;
- not be backed up to cloud device backup if the platform allows excluding ephemeral files.

In-memory processing is preferred where reasonable, but forcing all operations into memory can create stability risk with large photos. Private temporary files are acceptable when they improve safety/performance and are managed deliberately.

## 6. Original-photo safety

The app must never overwrite the source asset.

Import/capture produces an immutable internal source reference. All transforms are non-destructive until a new export file is generated.

Any write failure during export must leave both source and previous successful outputs untouched.

## 7. Metadata policy

On import, read only metadata needed for correct processing, especially orientation and possibly color-space information.

On export:

- strip GPS/geolocation;
- strip device serial-like/private metadata;
- strip unnecessary original timestamps/comments/software fields where appropriate;
- write only metadata intentionally required for image correctness/interoperability;
- test actual output metadata, not just intended encoder options.

## 8. Face and biometric data policy

The app may detect faces/landmarks locally to perform composition checks. It should not create persistent face embeddings/templates for identification.

The product is not a face-recognition system. It does not need to know who the person is, compare identities, or match a face against a database.

Any future proposal to add identity matching, cloud face analysis, or persistent biometric templates requires a separate privacy/security/legal review and is outside the current architecture.

## 9. Analytics policy

Analytics is optional from an architecture perspective and must earn its place.

If enabled, use a strict allowlist schema.

Potentially allowed:

```text
app_version
os_major_version
screen_name
profile_id
profile_version
processing_stage
processing_duration_bucket
validation_state_category
export_type
structured_error_code
```

Not allowed:

```text
photo bytes
photo hashes intended to identify an image
thumbnails
face coordinates/landmarks in telemetry
face embeddings
EXIF GPS
full local paths
person names
document numbers
raw user-entered text
arbitrary diagnostic attachments containing images
```

Avoid unique device fingerprinting beyond what a strictly necessary service may already provide and what privacy/store requirements permit.

## 10. Crash reporting

Before adopting a crash SDK:

- inspect what it collects by default;
- disable screenshot/session replay for image screens;
- prevent attachment of photos;
- sanitize exception messages and breadcrumbs;
- avoid logging local photo paths;
- confirm consent/disclosure requirements;
- document data retention/vendor terms.

Prefer stable internal error codes to verbose context that risks leaking data.

## 11. Logging

Production logs must never contain:

- image bytes/base64;
- face landmark arrays;
- source file names if they can reveal identity;
- full paths;
- GPS/EXIF dumps;
- user names/document identifiers;
- signed URLs or credentials.

Debug builds may expose more technical detail but should still avoid committing/logging real sensitive fixture content unnecessarily.

## 12. Secrets management

Never commit:

- Apple/Google signing keys;
- `.p12`, keystores, provisioning secrets;
- API tokens;
- service account files;
- backend signing keys;
- analytics secrets;
- store credentials.

Use CI secret stores and local environment/configuration mechanisms. `.gitignore` provides baseline exclusions but is not a security control by itself.

If a secret is ever committed, assume compromise and rotate it; deleting the file in a later commit is not sufficient.

## 13. Dependency security

Every package/SDK must be evaluated for:

- necessity;
- maintenance state;
- licence;
- known vulnerabilities;
- network behavior;
- data collection;
- native permissions;
- transitive dependencies;
- update cadence;
- ownership/reputation;
- replaceability.

High-risk dependencies include camera, ML, analytics, ad, attribution, image-codec, PDF, and storage SDKs because they touch sensitive data or platform capabilities.

## 14. Advertising policy

The intended product direction is ad-free in the critical workflow.

If ads are ever considered:

- no ad SDK may receive photo content;
- no ad overlay on the camera/editor;
- no interstitial before showing a critical compliance warning;
- ad tracking must not be a hidden condition for using the core feature;
- privacy/store impact must be reassessed.

Given the product motivation and sensitivity of face photos, avoiding third-party advertising SDKs entirely is the preferred baseline.

## 15. Threat model

### T-01 — Accidental cloud upload

Risk: SDK or implementation sends photo/derived data to a server.

Controls:

- local-only interfaces by default;
- dependency review;
- network inspection tests;
- no upload endpoint in MVP architecture;
- structured telemetry allowlist.

### T-02 — Sensitive data in logs/crashes

Controls:

- safe typed errors;
- log redaction;
- no file paths/image metadata dumps;
- crash SDK configuration/testing.

### T-03 — Temporary file exposure

Controls:

- application-private directories;
- scoped platform storage;
- cleanup policy;
- no public cache/gallery writes.

### T-04 — Malicious/incorrect remote rules

Only applicable if remote catalog updates ship.

Controls:

- signed catalogs;
- integrity hashes;
- schema + semantic validation;
- atomic activation;
- known-good fallback;
- version rollback path.

### T-05 — Dependency compromise

Controls:

- minimized dependency count;
- version review/update policy;
- lockfiles;
- vulnerability monitoring where practical;
- no unreviewed native binary SDKs.

### T-06 — Oversized/malformed image denial of service

Controls:

- validate headers;
- bounded analysis decode;
- safe codec libraries;
- pixel-count limits/guardrails;
- typed failure instead of unbounded allocation.

### T-07 — Path/file overwrite

Controls:

- application-generated output paths;
- native save/share APIs;
- never modify imported asset in place;
- atomic output writes where practical.

### T-08 — False compliance/security-of-trust failure

Risk: user relies on a false green status.

Controls:

- explicit machine/manual states;
- provenance;
- conservative tolerances;
- no acceptance guarantee;
- rule regression tests;
- review dates.

## 16. Remote rule update security

If implemented later, use a threat model in which CDN/network content can be hostile.

Recommended model:

1. release app contains trusted public verification key;
2. catalog/manifest is signed by an offline/protected private key;
3. client verifies signature and hash;
4. schema compatibility checked;
5. semantic validation runs;
6. content staged;
7. activation atomic;
8. previous version retained;
9. failed verification never alters active rules.

Do not place the signing private key in the mobile app or repository.

## 17. Payments

If paid features are introduced:

- use platform-compliant in-app purchase/store mechanisms where required;
- keep entitlement state separate from photo content;
- do not require account creation unless entitlement portability genuinely needs it;
- never transmit a photo as part of purchase verification;
- design offline/grace behavior explicitly.

## 18. Child photos

The app may be used by parents to create photos for children. This increases the importance of:

- local processing;
- no photo-history default;
- no advertising/behavioral profiling based on the image;
- no cloud model training on user photos;
- clear deletion behavior.

Any future cloud feature handling child photos requires separate legal/privacy review.

## 19. Privacy UX requirements

The product must explain privacy at meaningful decision points without overwhelming the user.

Recommended:

- short first-use statement;
- permission prompts only in context;
- Settings → Privacy page;
- clear `Delete local data` action if persistent job data is later introduced;
- specific disclosure before any optional feature sends an image/data off-device;
- no bundled consent for unrelated purposes.

## 20. Store/privacy review checklist

Before each store release:

- inventory every SDK and its data behavior;
- inspect current runtime network calls;
- verify platform permission strings;
- verify store privacy/data-safety disclosures match the binary;
- verify privacy policy matches actual data flows;
- verify analytics/crash configuration;
- verify photo picker/camera permissions;
- verify no test endpoint/credential remains;
- verify metadata stripping;
- verify remote-rule verification if enabled;
- verify deletion/retention statements.

Platform rules change over time, so this checklist must be reviewed against current official platform requirements at release time rather than relying only on this planning document.

## 21. Security release blockers

Release is blocked by:

- unexplained photo/derived-data network transmission;
- committed active secret;
- known critical dependency vulnerability affecting shipped path without mitigation;
- source-image overwrite/data-loss risk;
- insecure remote-rule activation;
- inaccurate store privacy declarations;
- crash/analytics payload containing sensitive image data;
- public/shared temporary storage of source images without necessity.
