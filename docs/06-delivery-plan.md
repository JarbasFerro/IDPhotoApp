# 06 — Delivery plan

## 1. Delivery strategy

The project should be built in gated milestones. Each milestone reduces a specific category of risk before the next layer of product complexity is added.

The sequence is intentionally different from “build screens first.” The highest-risk parts are image correctness, rules, segmentation, export fidelity, and platform behavior; these should be proven early.

## 2. Milestone overview

| Milestone | Goal | Primary exit condition |
|---|---|---|
| M0 | Product definition | Scope, requirements, risks, and initial launch assumptions are documented |
| M1 | Technical feasibility | Core technical choices are benchmarked and architecture decisions are locked |
| M2 | App foundation | Buildable iOS/Android app with CI, navigation, localization, and core domain skeleton |
| M3 | Image pipeline | Import/capture, normalization, detection, analysis, segmentation, and deterministic render work end to end |
| M4 | Rules engine | Versioned, sourced profiles drive validation and crop geometry |
| M5 | Product UX | Complete guided workflow is usable and accessible |
| M6 | Export/print | Digital outputs and physical print sheets are dimensionally verified |
| M7 | Hardening | Privacy, reliability, accessibility, performance, localization, and QA gates pass |
| M8 | Release | Store submission and controlled production launch |

---

## 3. M0 — Product definition

### Objective

Turn the product idea into explicit constraints before coding.

### Work

- lock product principles;
- define MVP and non-goals;
- decide initial target user groups;
- define official-profile publication policy;
- define quality-state semantics;
- decide whether generic/custom photo sizes belong in MVP;
- decide initial monetization guardrails;
- identify initial launch markets for rule research;
- define success metrics and privacy constraints;
- create prioritized backlog.

### Exit criteria

- README and docs 01–10 reviewed;
- no unresolved ambiguity that blocks M1 spikes;
- launch-country research shortlist exists;
- official-profile source standard is accepted;
- project decision log is active.

---

## 4. M1 — Technical feasibility and architecture lock

### Objective

Prove that the proposed stack can deliver the required image quality, performance, and platform integration before building production architecture around it.

### Spike A — Flutter/platform integration

Build a disposable app that:

- launches on iOS and Android;
- requests camera only on user action;
- captures/imports images;
- handles EXIF rotation;
- imports large images;
- writes a generated output;
- uses platform share/save.

Measure memory, copies, and latency.

### Spike B — Face detection

Compare practical on-device candidates.

Dataset dimensions should include:

- frontal adult faces;
- different skin tones;
- glasses;
- facial hair;
- different hair types;
- weak/strong lighting;
- children/babies where ethically sourced and consented;
- small faces/high-resolution source photos;
- rotations and difficult backgrounds.

Record:

- detection success;
- landmark availability/quality;
- false positives;
- latency;
- memory;
- binary/model size;
- platform consistency.

### Spike C — Segmentation

Compare candidate on-device segmentation solutions using a visual scoring rubric.

Important cases:

- fine hair;
- curly hair;
- light hair on light background;
- dark hair on dark background;
- glasses;
- ears;
- shoulders/clothing edges;
- veils/head coverings;
- child/baby hair;
- shadows;
- textured walls.

### Spike D — Geometry/render

Create a headless deterministic test that:

- reads fixture image;
- applies known crop parameters;
- renders exact target dimensions;
- compares output geometry with expected values;
- runs identically on CI-compatible environment.

### Spike E — PDF/print

Generate representative print sheets and physically verify dimensions.

### Spike F — Editor/accessibility

Prototype drag/pinch plus accessible movement/zoom controls and screen-reader labeling.

### Spike G — Performance budget

Establish actual budgets for:

- app startup;
- photo normalization;
- face detection;
- segmentation;
- preview refresh;
- final export;
- peak memory.

### Exit criteria

- architecture stack accepted/rejected in decision log;
- face-detection implementation selected or shortlist narrowed with clear decision rule;
- segmentation implementation selected or fallback defined;
- print-generation approach physically validated;
- minimum supported OS versions selected;
- performance budgets written down;
- no unresolved feasibility blocker for MVP.

---

## 5. M2 — Foundation

### Objective

Create the maintainable production skeleton after M1 decisions are locked.

### Workstreams

#### Repository/app bootstrap

- create Flutter app (if ADR accepted);
- configure bundle/application IDs;
- environments/flavors only if needed;
- strict analysis/linting;
- dependency policy;
- folder/module structure.

#### App shell

- navigation;
- theme/design tokens;
- localization framework;
- settings repository;
- error/result primitives;
- logging abstraction;
- dependency injection approach.

#### CI

- format/lint/static analysis;
- unit tests;
- rules validation placeholder;
- Android debug build;
- iOS build where infrastructure permits;
- artifact/report retention.

#### Domain skeleton

- coordinate types;
- document profile interfaces;
- `PhotoJob`;
- validation states;
- geometry primitives;
- typed error taxonomy.

### Exit criteria

- clean checkout builds;
- automated checks pass;
- app launches on physical iOS/Android device;
- localization test string works;
- architecture boundaries are enforceable by review/lints/tests;
- no production image logic hidden in UI widgets.

---

## 6. M3 — Image pipeline

### Objective

Implement a reliable source-to-preview pipeline independently of full rules catalog UX.

### Order

1. image acquisition abstraction;
2. orientation normalization;
3. image metadata and validation;
4. analysis-resolution decode;
5. face detection adapter;
6. derived face geometry;
7. blur/resolution/exposure checks;
8. segmentation adapter;
9. preview renderer;
10. deterministic high-resolution render;
11. cancellation/stale-result handling;
12. typed errors and recovery.

### Exit criteria

- controlled fixture images flow through the complete pipeline;
- source remains immutable;
- output reproduces expected crop parameters;
- multiple/no-face cases handled;
- segmentation failure has safe fallback;
- no UI-thread blocking beyond established budget;
- image memory remains within M1 budget on target devices.

---

## 7. M4 — Rules engine and initial rule catalog

### Objective

Make product behavior driven by explicit, sourced document profiles.

### Work

- JSON Schema;
- semantic validator;
- typed profile loader;
- provenance model;
- evaluator registry;
- output-size rules;
- head-size/position evaluators;
- manual-check representation;
- background policy representation;
- rule-version display;
- initial launch profiles;
- boundary fixtures;
- CI validation.

### Exit criteria

- adding a supported profile requires no country-specific UI/crop code;
- every launch profile has sources and review date;
- invalid profiles fail CI;
- every machine-hard rule has tests;
- manual requirements appear explicitly in validation results;
- profile version can be traced into diagnostics/export metadata where appropriate.

---

## 8. M5 — Complete product UX

### Objective

Turn technical capability into a fast, understandable end-to-end user journey.

### Build order

1. home;
2. country/profile selection;
3. requirement summary;
4. camera/import entry;
5. analysis state;
6. photo-check report;
7. editor;
8. export choice;
9. digital export UI;
10. print setup UI;
11. completion;
12. settings/help.

### Cross-cutting work

- design system/components;
- all empty/error states;
- accessibility semantics;
- scalable text;
- localization stress testing;
- privacy explanations;
- source/provenance UI;
- first-use guidance;
- no-permission dead ends.

### User testing gate

Run task-based usability testing before calling M5 complete.

Minimum questions to validate:

- Can users select the correct document profile?
- Do users understand `manual_check`?
- Do users know whether “Ready” is a guarantee? They must understand it is not.
- Can users correct crop without instruction?
- Can users recover from bad source photos?
- Can users create a print sheet?

### Exit criteria

- complete core workflow works without developer explanation;
- usability blockers resolved;
- no inaccessible gesture-only critical action;
- localization does not break primary layouts;
- all defined states implemented.

---

## 9. M6 — Export and print fidelity

### Objective

Prove that what the user saves/prints matches the selected rules exactly.

### Digital export

- exact dimensions;
- encoding;
- color profile;
- metadata stripping;
- file-size constraints;
- post-export verification;
- save/share behavior.

### Print export

- page-size model;
- grid packing;
- copy count;
- margins/gutters;
- cut guides;
- PDF page geometry;
- 100% print instruction;
- physical measurements.

### Exit criteria

- all output fixtures pass;
- digital files re-open with exact expected dimensions;
- PDF page boxes are correct;
- multiple real printer paths produce measured photo sizes within documented tolerance when printed at actual size;
- failure modes are user-readable.

---

## 10. M7 — Hardening

### Objective

Remove release risk.

### QA dimensions

- regression;
- physical devices;
- older supported OS;
- memory pressure;
- app background/foreground interruption;
- rotation/orientation;
- corrupt/huge images;
- privacy permissions;
- offline mode;
- accessibility;
- localization;
- performance;
- dependency security/licences;
- store disclosure accuracy.

### Privacy/security review

- confirm no unexpected network calls during core flow;
- inspect SDK behavior;
- verify temp-file deletion;
- verify EXIF/GPS stripping;
- verify logs/crash payloads contain no image/sensitive data;
- review permission strings;
- threat-model rule updates if enabled.

### Exit criteria

- release criteria in requirements pass;
- no open P0;
- no correctness/privacy/data-loss P1;
- launch rules re-audited;
- store disclosures match actual binaries/SDK behavior;
- release candidate signed and distributed to test group.

---

## 11. M8 — Store release

### Objective

Release safely and observe real-world reliability without compromising privacy.

### Work

- final name/branding lock;
- icons/splash assets;
- screenshots/localized listing;
- privacy policy;
- support page/contact;
- pricing/IAP configuration if applicable;
- App Store / Play metadata;
- privacy/data-safety forms;
- age rating;
- export compliance declarations as applicable;
- staged/phased rollout where available;
- crash/quality monitoring;
- rule-support runbook.

### Exit criteria

- both stores approve or platform-specific issues are understood;
- production version available to intended cohort;
- release monitoring active;
- rollback/hotfix process tested/documented;
- next rule/feature wave begins only after first-release quality is stable.

---

## 12. Workstream ownership model

Even if one developer initially performs all work, track these as distinct disciplines:

- Product/specification
- UX/UI
- Mobile application
- Image/ML pipeline
- Rules/content research
- QA/validation
- Privacy/security
- Release/store operations

This prevents “coding is done” from hiding incomplete rule research, store compliance, or physical print testing.

## 13. Suggested issue hierarchy

Use GitHub issues with labels rather than encoding every implementation detail only in documents.

Recommended labels:

```text
priority:P0
priority:P1
priority:P2
area:product
area:ux
area:architecture
area:image-pipeline
area:rules
area:export
area:privacy
area:accessibility
area:qa
area:release
type:feature
type:bug
type:spike
type:chore
type:decision
```

Milestones should mirror M0–M8.

## 14. Change-control rule

If an implementation discovery changes a foundational assumption—such as cloud processing becoming necessary, background removal proving unreliable, or a store policy affecting monetization—do not quietly work around it. Update:

1. the relevant requirement;
2. `docs/10-decisions.md`;
3. affected acceptance criteria;
4. backlog priority/dependencies;
5. privacy/security analysis if data flow changes.

## 15. Immediate next development step

Do **not** start by implementing final home screens. The next repository change after planning should create M1 spike scaffolding and a fixture/benchmark methodology. Production app bootstrap follows only after the spike results support the architecture decision.
