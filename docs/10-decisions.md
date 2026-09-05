# 10 — Decision register

## 1. Purpose

Important product and architecture choices must be explicit. This avoids decisions being made accidentally by whichever library or screen happens to be implemented first.

Statuses:

- **Proposed** — current recommended direction, not locked.
- **Accepted** — decision is active and should guide implementation.
- **Rejected** — evaluated and deliberately not chosen.
- **Superseded** — replaced by a newer decision.
- **Deferred** — intentionally postponed.

When evidence changes an accepted decision, add a new decision or revision. Do not silently rewrite history.

---

## ADR-001 — Cross-platform application stack

**Status:** Proposed  
**Decision:** Use Flutter/Dart for the production iOS/Android application, with narrow native bridges where required.  
**Why proposed:** One UI/product codebase, strong custom rendering, suitable for an image-centric editor, lower duplication than separate native applications.  
**Must be proven in M1:**

- camera/photo-picker reliability;
- large-image memory behavior;
- native ML integration;
- deterministic image/PDF export;
- accessibility semantics;
- acceptable binary/startup impact.

**Alternatives:** native Swift + Kotlin; Kotlin Multiplatform shared core with native UIs; React Native.  
**Accept/reject gate:** S1-011 after technical spikes.

---

## ADR-002 — Core image processing location

**Status:** Proposed, expected to become Accepted  
**Decision:** Core face analysis, segmentation, crop/render, and export run on device. No cloud processing is required for MVP.  
**Rationale:** Privacy, offline use, latency, simpler data governance, no need for an account/backend in the primary task.  
**Exception process:** Any future cloud-processing feature requires a separate decision covering user value, transmitted data, consent, retention, security, store disclosure, and fallback behavior.

---

## ADR-003 — Face detection implementation

**Status:** Proposed / implementation TBD  
**Decision shape:** Use a replaceable on-device face-detector adapter, selected from M1 benchmark evidence.  
**Do not decide by:** package popularity alone.  
**Selection criteria:**

- frontal-face recall;
- landmark semantics and accuracy;
- multiple-face behavior;
- children/babies if in supported scope;
- latency/memory;
- offline behavior;
- binary size;
- privacy/network behavior;
- platform consistency;
- licence/maintenance.

**Gate:** S1-004 / S1-011.

---

## ADR-004 — Subject segmentation implementation

**Status:** Proposed / implementation TBD  
**Decision shape:** Use an on-device replaceable segmenter selected by benchmark.  
**Fallback requirement:** If segmentation quality is inadequate, the product must support original-background/retake/manual-refine paths rather than silently exporting artifacts.  
**Gate:** S1-006 / S1-011.

---

## ADR-005 — PDF generation

**Status:** Proposed / implementation TBD  
**Decision shape:** Use a PDF approach that allows exact page geometry and predictable physical-size output.  
**Selection criterion:** Physical measurement matters more than library convenience.  
**Gate:** S1-008.

---

## ADR-006 — Rules as versioned data

**Status:** Accepted  
**Decision:** Country/document specifications live in a versioned validated rules catalog rather than country-specific conditional code.  
**Rationale:** Requirements change, scale internationally, require provenance, and must be testable independently from UI.  
**Consequences:**

- JSON/schema + semantic validation tooling required;
- stable profile IDs/versions required;
- rule provenance required;
- evaluator registry required;
- CI must validate production profiles.

---

## ADR-007 — Compliance result semantics

**Status:** Accepted  
**Decision:** Every evaluable requirement maps to `pass`, `warn`, `fail`, or `manual_check`.  
**Rationale:** The app must expose uncertainty and manual requirements rather than imply automated certification.  
**Consequence:** An overall Ready state never means guaranteed official acceptance.

---

## ADR-008 — Source image mutability

**Status:** Accepted  
**Decision:** The original imported/captured source is immutable. Editing is non-destructive and parameter-driven until a new output is rendered.  
**Rationale:** Prevent data loss, avoid repeated encoding degradation, make reset/profile changes deterministic.

---

## ADR-009 — Coordinate-system discipline

**Status:** Accepted  
**Decision:** Distinguish source pixels, normalized image coordinates, preview logical pixels, output pixels, physical millimetres, and PDF points with explicit conversion utilities/value types.  
**Rationale:** Prevent the most common class of crop/print scaling errors.  
**Consequence:** UI coordinates must not leak into rule definitions.

---

## ADR-010 — Deterministic official output

**Status:** Accepted  
**Decision:** Final dimensions, crop geometry, physical scaling, and print layout are deterministic algorithms. Generative AI may not determine final official-photo geometry.  
**Rationale:** Correctness, repeatability, testability, auditability.

---

## ADR-011 — Identity-preserving editing

**Status:** Accepted  
**Decision:** Official-document mode excludes beautification and generative edits that change facial identity or appearance materially.  
**Includes prohibited baseline features:** face reshaping, eye enlargement, synthetic makeup, skin smoothing as beautification, wrinkle removal, hair reconstruction, clothing replacement.  
**Rationale:** Trust and risk of producing unacceptable/misrepresentative identity photos.

---

## ADR-012 — Backend for MVP

**Status:** Accepted  
**Decision:** No application backend is required for the core MVP.  
**Possible future reasons to add one:** signed rule updates, optional account/sync, explicitly opt-in support diagnostics, entitlement infrastructure where store-native capability is insufficient.  
**Not a valid reason alone:** convenience of moving image processing off-device.

---

## ADR-013 — Account requirement

**Status:** Accepted  
**Decision:** No account/login is required for the core workflow.  
**Rationale:** Low-friction occasional-use product and privacy minimization.

---

## ADR-014 — Advertising in core workflow

**Status:** Accepted  
**Decision:** No intrusive advertising inside the critical create/check/edit/export workflow. Preferred baseline is no third-party advertising SDK.  
**Rationale:** The product is partly motivated by poor ad-heavy alternatives; photo/face privacy also makes ad SDKs undesirable.  
**Future change:** requires a new explicit privacy/product decision.

---

## ADR-015 — Monetization model

**Status:** Deferred  
**Decision needed:** free, one-time purchase, freemium, subscription for advanced/frequent use, or hybrid.  
**Guardrails already accepted:**

- no surprise watermark at export;
- no paywall before explaining a detected photo problem;
- no dark-pattern countdown/interstitial workflow;
- monetization cannot alter rules correctness.

**Gate:** before store/IAP implementation, not before M1 technical work.

---

## ADR-016 — Initial launch jurisdictions

**Status:** Deferred  
**Decision needed:** deliberately small first country/document set based on demand and authoritative-source availability.  
**Rule:** breadth cannot take priority over source quality.  
**Gate:** P0-002 before M4 production profile creation.

---

## ADR-017 — Child/baby support at launch

**Status:** Proposed  
**Decision:** Architecture supports age-related profile exceptions from the start; exact launch coverage is decided per jurisdiction/profile based on sourced rules and test capacity.  
**Rationale:** Parents are a meaningful use case, but requirements and source-photo conditions can differ materially.  
**Open question:** which launch profiles have sufficiently clear child/baby requirements and test fixtures?

---

## ADR-018 — Generic/custom photo sizes

**Status:** Proposed / scope decision pending  
**Decision:** Use the same deterministic renderer for generic formats, but visually distinguish them from official validated profiles and make no compliance claim.  
**Open question:** include in MVP or first post-MVP release?

---

## ADR-019 — Remote rules updates

**Status:** Deferred  
**Decision:** Initial MVP may ship rules with app releases. Architecture should not prevent future signed catalog updates.  
**If enabled:** signatures, integrity checks, schema/semantic validation, atomic activation, and known-good rollback are mandatory.  
**Rationale:** Avoid building operational/security complexity before schema stabilizes.

---

## ADR-020 — Analytics and crash reporting

**Status:** Deferred  
**Decision needed:** whether MVP ships analytics, crash reporting, both, or neither.  
**Constraints:**

- strict structured allowlist;
- no photos/thumbnails/face embeddings/landmarks in telemetry;
- no photo screenshots/session replay;
- no sensitive file paths/EXIF;
- vendor behavior must match store/privacy declarations.

**Gate:** before dependency adoption, not at release cleanup.

---

## ADR-021 — Photo/job history

**Status:** Proposed  
**Decision:** MVP stores recent/favourite document profiles, not a permanent face-photo gallery by default.  
**Rationale:** Lower privacy/storage burden.  
**Future resume/history:** requires retention/deletion UX and a privacy decision.

---

## ADR-022 — Primary output formats

**Status:** Proposed  
**Decision:** JPEG baseline for digital official photos; PNG only where appropriate/required. PDF baseline for dimensionally controlled print sheets.  
**Gate:** validate against launch profile requirements and M1 PDF/image export spike.

---

## ADR-023 — State management library

**Status:** Deferred  
**Decision:** Do not select a Flutter state-management package before M1 architecture lock.  
**Required properties:** explicit transitions, testable controllers/view models, cancellation/stale-result handling, lifecycle safety, no hidden global mutable job.  
**Rationale:** Choose for project needs, not convention.

---

## ADR-024 — Minimum OS versions

**Status:** Deferred  
**Decision criteria:** framework support, native ML/photo-picker APIs, security, market coverage, performance, and device-test capacity.  
**Gate:** M1 after physical-device tests.

---

## ADR-025 — Source/provenance standard

**Status:** Accepted  
**Decision:** Official profiles require authoritative source metadata and last-reviewed date; unknown values remain explicit and are not copied from similar commercial profiles.  
**Preferred source hierarchy:** issuing government/authority → official embassy/delegated provider → adopted technical standard → clearly marked authoritative secondary source when primary is unavailable.

---

## ADR-026 — Print accuracy policy

**Status:** Accepted  
**Decision:** Print output correctness is verified physically, not only mathematically. UI instructs users to print at Actual size / 100% and avoid fit-to-page scaling.  
**Rationale:** Correct PDF geometry can still be altered by viewer/printer settings.

---

## ADR-027 — Test image privacy

**Status:** Accepted  
**Decision:** Private/real family/user identity photos are not committed to the public repository. Public test data must be synthetic, appropriately licensed, or explicitly consented for the intended use. Sensitive local datasets stay outside Git and are documented separately.

---

# Open decisions before production implementation

These are the immediate decisions that M1 must resolve:

1. ADR-001 — Flutter production stack.
2. ADR-003 — face detector.
3. ADR-004 — segmenter.
4. ADR-005 — PDF library/approach.
5. ADR-022 — final baseline codec/export implementations.
6. ADR-023 — state management after architecture needs are proven.
7. ADR-024 — minimum OS versions.

These product/content decisions can proceed in parallel:

1. ADR-015 — monetization model.
2. ADR-016 — launch jurisdictions.
3. ADR-017 — child/baby launch coverage.
4. ADR-018 — generic/custom size in MVP.
5. ADR-020 — analytics/crash reporting.

# Decision template

Use this template for new decisions:

```markdown
## ADR-XXX — Title

**Status:** Proposed | Accepted | Rejected | Superseded | Deferred  
**Date:** YYYY-MM-DD  
**Owners:** ...

### Context

What problem/constraint requires a decision?

### Decision

What are we choosing?

### Evidence

Benchmarks, user research, platform constraints, prototypes, source links, test results.

### Alternatives considered

What credible alternatives were evaluated?

### Consequences

What becomes easier/harder? What new work or constraints follow?

### Revisit trigger

What evidence/event should cause us to reconsider?
```
