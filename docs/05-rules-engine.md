# 05 — Rules engine

## 1. Purpose

Country/document photo requirements must be treated as governed data, not scattered conditional logic. The rules engine is responsible for representing, validating, evaluating, versioning, and explaining those requirements.

The image pipeline should not know that a specific crop is “a passport photo.” It should receive a typed `DocumentProfile` describing output and composition constraints.

## 2. Core principles

1. **Every official rule has provenance.**
2. **Every profile has a stable ID and version.**
3. **Rules distinguish machine-checkable constraints from manual requirements.**
4. **Rules are validated syntactically and semantically before publication.**
5. **Profiles can evolve without changing the image-processing code.**
6. **Unknown values are explicit; they are never invented from similar profiles.**
7. **Source wording and app interpretation are separate concepts.**

## 3. Profile identity

Recommended stable ID convention:

```text
<jurisdiction>.<document-family>.<variant>
```

Examples only:

```text
country-passport-standard
country-visa-tourist
country-national-id-standard
custom-cv-standard
```

Do not encode dimensions into the ID because dimensions can change while the logical profile remains the same.

## 4. Proposed canonical schema

Illustrative structure; exact JSON Schema will be implemented in M4.

```json
{
  "schemaVersion": 1,
  "profileId": "example.passport.standard",
  "profileVersion": "1.0.0",
  "status": "active",
  "jurisdiction": {
    "countryCode": "XX",
    "regionCode": null
  },
  "document": {
    "type": "passport",
    "variant": "standard",
    "nameKey": "profile.example.passport.name"
  },
  "effective": {
    "from": null,
    "to": null,
    "lastReviewed": "YYYY-MM-DD"
  },
  "output": {
    "physicalWidthMm": null,
    "physicalHeightMm": null,
    "pixelWidth": null,
    "pixelHeight": null,
    "preferredPpi": null,
    "formats": ["jpeg"],
    "fileSizeBytes": {
      "min": null,
      "max": null
    },
    "colorSpace": "srgb"
  },
  "background": {
    "requirement": "manual_check",
    "replacementAllowed": false,
    "allowedColors": [],
    "instructionsKey": "rule.example.background"
  },
  "composition": {
    "headHeight": null,
    "faceHeight": null,
    "eyeLine": null,
    "horizontalCentering": null,
    "topMargin": null
  },
  "qualityChecks": [],
  "manualChecks": [],
  "specialCases": [],
  "sources": [],
  "notes": []
}
```

This example deliberately leaves unknown values as `null` instead of supplying guessed defaults.

## 5. Numeric constraint model

A common model should represent:

- exact value;
- inclusive min/max range;
- recommended range distinct from hard range;
- percentage of photo dimension;
- physical units;
- pixels;
- normalized coordinates.

Example concept:

```text
NumericConstraint
- unit
- exact?
- minInclusive?
- maxInclusive?
- recommendedMin?
- recommendedMax?
- tolerancePolicy?
```

Never represent “between 29 mm and 34 mm” as a hard-coded UI sentence and then re-parse it for validation.

## 6. Composition definitions

The schema must define exactly what landmarks are used.

Terms that sound obvious are not interchangeable:

- crown / top of hair;
- top of skull;
- chin;
- eye line;
- face bounding box;
- head bounding box including hair;
- shoulder line.

For each measurable composition rule, the rule definition must specify the measurement semantics the engine expects.

Example:

```text
HeadHeightConstraint
- landmarkStart: crown_estimate
- landmarkEnd: chin
- unit: percent_output_height
- min/max
```

If a detector cannot reliably provide the required landmark semantics, that rule should fall back to `manual_check` or a less authoritative warning.

## 7. Rule types

Recommended categories:

### 7.1 Output rules

- physical width/height;
- pixel width/height;
- accepted file format;
- min/max file size;
- color mode/profile;
- resolution expectations.

### 7.2 Composition rules

- head/face size;
- face horizontal centering;
- eye line;
- headroom/top margin;
- shoulder/body inclusion;
- permitted rotation/pose where measurable.

### 7.3 Background rules

- color description;
- uniformity;
- shadow restrictions;
- whether digital background alteration is permitted or product-policy approved;
- allowed replacement colors if the app offers replacement.

### 7.4 Quality rules

- minimum resolution;
- blur/sharpness guidance;
- exposure/contrast;
- image age/recency if specified;
- print/scanning limitations.

### 7.5 Appearance/manual rules

Usually manual unless robustly measurable:

- expression;
- mouth position;
- eye visibility;
- glasses/reflections;
- headwear;
- hair/face obstruction;
- uniform/clothing restrictions;
- shadows;
- gaze;
- child/baby exceptions.

## 8. Evaluation capability levels

Each canonical rule should declare how the app handles it:

```text
machine_hard
machine_advisory
manual
informational
unsupported
```

Meaning:

- `machine_hard`: deterministic/reliable enough to pass/fail against a defined tolerance.
- `machine_advisory`: model can identify risk but not safely make a definitive judgement.
- `manual`: shown to user for review.
- `informational`: instruction not associated with a pass/fail state.
- `unsupported`: known requirement that the current app cannot evaluate or assist with; still surfaced transparently if relevant.

This capability belongs to the combination of rule + current implementation, not necessarily the legal requirement itself.

## 9. Provenance model

Every official profile requires at least one source record.

Suggested fields:

```text
Source
- sourceId
- authorityName
- title
- url
- accessedDate
- publishedOrUpdatedDate? 
- language
- sourceType: official | delegated_authority | authoritative_secondary
- archivedReference? 
- notes?
```

Each canonical rule should optionally reference the source ID(s) supporting it. This permits audits when one source supports dimensions and another supports appearance requirements.

## 10. Source hierarchy

Preferred order:

1. official government/issuing authority;
2. official embassy/consulate or delegated application provider where authoritative for the process;
3. published technical standard adopted by the authority;
4. authoritative secondary source only when primary material is unavailable and the limitation is recorded.

Commercial “passport photo size” websites should never silently become the primary source for an official profile.

## 11. Review workflow for adding a profile

### Step 1 — Research

Collect official sources and record access/update dates.

### Step 2 — Extract

Convert requirements into canonical rule fields. Preserve ambiguity in notes rather than resolving it by assumption.

### Step 3 — Interpret

For every statement, decide:

- machine-hard;
- machine-advisory;
- manual;
- informational;
- unsupported.

### Step 4 — Independent review

A second review should compare the profile against the source before release for high-value official profiles.

### Step 5 — Fixtures

Create rule-level tests for dimensions and constraint boundaries.

### Step 6 — Visual fixtures

Where composition constraints are implemented, create annotated synthetic/consented fixtures that should clearly pass and fail around thresholds.

### Step 7 — Publish

Only validated profiles are included in production catalog.

## 12. Semantic validation

JSON Schema alone is insufficient. The build-time semantic validator must catch contradictions such as:

- width defined but height missing;
- min > max;
- exact value outside min/max;
- physical dimensions specified without enough information for a digital output mode when pixel dimensions are also mandated;
- unsupported output format;
- background replacement enabled but no permitted policy/value exists;
- source list empty for an official profile;
- `lastReviewed` missing;
- effective-to earlier than effective-from;
- duplicate profile IDs/versions;
- localization keys missing;
- composition constraints referencing unsupported landmark semantics;
- hard machine check with no evaluator registered.

CI must fail on semantic errors.

## 13. Evaluator registry

Domain logic should map rule type to evaluator implementation.

Concept:

```text
RuleEvaluator<T extends Rule>
- evaluate(rule, photoMeasurements, context) -> ValidationCheck
```

Examples:

```text
PixelDimensionEvaluator
HeadHeightEvaluator
EyeLineEvaluator
CenteringEvaluator
ResolutionEvaluator
FileSizeEvaluator
BackgroundEvaluator (likely advisory/manual in many cases)
```

A profile can contain many rules without a large country-specific `switch` statement.

## 14. Measurement model

Analysis produces measurements independent of a specific document profile.

Example:

```text
PhotoMeasurements
- imageWidthPx
- imageHeightPx
- sharpnessScore? 
- exposureMetrics? 
- primaryFace
  - faceBoxNormalized
  - eyePositionsNormalized?
  - chinPositionNormalized?
  - crownEstimateNormalized?
  - pose?
  - confidence
- backgroundMetrics?
```

The same measurements can be evaluated against another profile without re-running all analysis if the source image has not changed.

## 15. Tolerances

Legal/source requirements and implementation tolerances must be separate.

Example:

- source hard limit: 32–36 mm head height;
- measurement algorithm has estimated uncertainty;
- product may warn near the boundary instead of producing a hard pass/fail.

Recommended policy:

```text
clearly inside range -> pass
near boundary within measurement uncertainty -> warn
clearly outside range -> fail
cannot measure reliably -> manual_check
```

Do not expand the source's official limits and then display the expanded range as the official requirement.

## 16. Crop solving

The crop solver receives:

- source dimensions;
- face/head geometry;
- output aspect ratio;
- composition constraints;
- optional preferred target within allowed range.

It returns candidate crop parameters plus constraint diagnostics.

The solver should optimize toward a stable preferred composition, not randomly choose any point inside the legal range.

Possible objective priorities:

1. satisfy all hard constraints;
2. center within recommended target ranges;
3. preserve maximum source resolution;
4. minimize unnecessary upscaling;
5. avoid cropping shoulders/hair where the rule does not require it.

The exact optimizer can initially be deterministic algebra rather than a generic numerical solver if rule complexity remains simple.

## 17. Background specification

Do not reduce background to a single RGB value.

Potential fields:

```text
BackgroundRule
- requiredAppearance: white | light | plain | uniform | specified_color | source_text_only
- colors[]? 
- uniformity: required | recommended | unspecified
- shadows: forbidden | discouraged | unspecified
- replacementPolicy: allowed | disallowed | unknown
- evaluatorCapability
- instructionKey
```

If the issuing authority says “plain light background” rather than an exact RGB value, the product should not claim one invented RGB value is the official standard.

## 18. Child/baby variants

The schema must support special cases such as age-related exceptions without burying them inside prose.

Concept:

```text
SpecialCase
- condition: age_lt / age_lte / document_variant / other
- parameter
- overrides[]
- instructions[]
- sources[]
```

Do not infer child exceptions across jurisdictions. Each must be sourced.

## 19. Generic/custom sizes

Generic formats should live in the same rendering system but must be visually differentiated from official validated profiles.

For a custom profile:

- user can choose width/height;
- optional DPI/PPI;
- optional background;
- simple crop guides;
- no claim of official compliance;
- source/provenance not required because the user is defining the format.

## 20. Rule catalog versioning

There are two levels:

- **schema version** — structure understood by the app;
- **catalog/profile version** — content changes.

Profile version should change when a meaningful rule or interpretation changes. Cosmetic translation fixes can follow a documented content-version policy.

The application must be able to identify exactly which profile version created an export for diagnostics.

## 21. Remote update design (future)

If remote updates are enabled:

1. app downloads manifest over TLS;
2. manifest references catalog version/hash;
3. catalog is downloaded;
4. cryptographic signature/integrity is verified;
5. schema + semantic validation runs locally;
6. catalog is written to a staging location;
7. activation is atomic;
8. previous known-good catalog is retained;
9. invalid update is rejected without affecting existing profiles.

A compromised network/CDN must not be sufficient to inject arbitrary rule data.

## 22. Rule regression tests

For every profile:

- schema valid;
- semantic valid;
- output dimensions expected;
- every localization key exists;
- every official profile has source metadata;
- each source has review/access date;
- each machine-hard rule has evaluator coverage;
- thresholds have boundary tests;
- if physical dimensions exist, mm/pixel conversion fixtures are tested where applicable;
- print layouts derived from the profile are dimensionally tested.

## 23. Rule review dashboard/tooling (post-MVP candidate)

As catalog size grows, hand-editing JSON becomes risky. Consider an internal rule-authoring tool that:

- edits typed fields;
- validates in real time;
- stores source URLs/date;
- previews crop guides;
- generates boundary fixtures;
- compares profile versions;
- requires review before publish;
- exports canonical version-controlled data.

This should come after the schema stabilizes; building it too early may encode the wrong model.

## 24. Definition of done for a new official profile

A profile is publishable only when:

- jurisdiction/document identity is unambiguous;
- output dimensions are sourced;
- background requirement is sourced;
- composition/manual requirements are captured;
- exceptions relevant to supported users are captured;
- source metadata is complete;
- last-reviewed date exists;
- schema validation passes;
- semantic validation passes;
- evaluator capability is assigned to every rule;
- boundary/unit tests pass;
- visual fixture tests exist for implemented geometry checks;
- user-facing localized instruction keys exist;
- another reviewer has checked the source-to-rule mapping for release-critical profiles.
