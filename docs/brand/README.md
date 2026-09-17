# Calipic brand system

This directory defines the strategic, verbal, visual, interaction, and implementation rules that make Calipic feel like one coherent product.

The goal is not to create a decorative brand layer on top of iOS. Calipic should feel unmistakably itself while remaining deeply native to iPhone. The system starts with product character and experience principles before finalizing logo, color, typography, motion, or design tokens.

## Status

**Product/brand name:** Calipic  
**Consumer naming direction:** `Calipic — ID Photos`  
**Brand-system status:** Strategic foundation approved; visual identity prototyping/research in progress  
**Technical repository name:** remains `IDPhotoApp` for now  
**Technical project identifiers:** unchanged until a separate implementation decision

## Approved strategic direction

Calipic should be known for:

- being exceptionally simple and intuitive;
- completing the job from portrait to correct digital output or physical print;
- being beautiful through restraint rather than decoration;
- treating privacy/on-device processing as a primary promise;
- feeling completely native to iPhone;
- producing satisfaction through an easy, finished real-world outcome.

Approved personality:

> **Elegant · Friendly · Photographic · Practical · Sophisticated**

Strong anti-traits:

> **Complicated · AI-branded · Generic · Childish · Cheap**

When design goals conflict, prioritize:

1. native iOS familiarity;
2. beauty;
3. accessibility.

Correctness, privacy, and rule integrity remain non-negotiable constraints rather than ranked preferences.

## Existing product constraints inherited by the brand system

The brand system must preserve the product decisions documented elsewhere in the repository:

- iPhone / iOS only;
- native SwiftUI and Apple platform conventions;
- privacy-first, on-device core workflow;
- deterministic correctness over false confidence;
- content before chrome;
- system typography, semantic materials, and SF Symbols by default;
- native Liquid Glass behavior rather than a custom glass theme;
- accessibility as product behavior, not post-release polish;
- restrained motion and haptics that communicate state;
- no identity-changing retouching in official-photo workflows;
- no intrusive advertising or conversion pressure in the correction path;
- internationalization and localization as structural requirements.

Brand decisions may refine the expression of these principles, but may not silently contradict them.

## Current documents

### Discovery and strategy

- [`00-discovery-questionnaire.md`](00-discovery-questionnaire.md) — original discovery framework.
- [`00-discovery-answers.md`](00-discovery-answers.md) — founder answers from 2026-09-17.
- [`01-brand-foundations.md`](01-brand-foundations.md) — approved strategic direction, positioning, audience, personality, voice, commercial posture, visual boundaries.
- [`02-experience-constitution.md`](02-experience-constitution.md) — durable product/brand experience rules.
- [`99-brand-decisions-log.md`](99-brand-decisions-log.md) — authoritative accepted/working/deferred decision record.

### Active research

- [`03-color-strategy-research.md`](03-color-strategy-research.md) — evidence-led evaluation of color perception, accessibility, semantics, and first color candidates.
- [`04-market-prioritization.md`](04-market-prioritization.md) — launch-market evidence and current U.S.-first commercial lens.
- [`05-creative-territories.md`](05-creative-territories.md) — four controlled identity territories and prototype matrix.

## Current creative hypothesis

The most promising synthesis to prototype is:

> **A highly ownable face + crop-frame symbol, inside an almost invisible native iOS interface, with print as the satisfying final transformation.**

The four creative territories are:

1. **Portrait Frame** — category recognition and core symbol.
2. **Quiet Studio** — product UI/design philosophy.
3. **Photo to Print** — completion and marketing proposition.
4. **Optical Order** — geometric ownability and calibration meaning.

No final symbol or color is approved yet.

## Planned documentation

### Visual system

- `06-visual-identity.md` — final symbol, wordmark, app icon, color system, composition and misuse rules.
- `07-product-design-language.md` — hierarchy, spacing, surfaces, photo treatment, controls, states, component behavior.
- `08-photography-and-image-language.md` — marketing photography, in-product imagery, manipulation boundaries, representation.
- `09-iconography-and-symbols.md` — SF Symbols policy and custom-symbol exceptions.

### Executable design system

- `10-design-tokens.md` — semantic colors, spacing, radii, typography roles, materials, motion values, icon sizing and SwiftUI mapping.
- `11-motion-and-haptics.md` — motion grammar, transitions, haptics and Reduce Motion behavior.
- `12-voice-and-writing.md` — product voice, vocabulary, instructions, errors, confidence language and localization.
- `13-accessibility-standard.md` — brand expression under Dynamic Type, VoiceOver, Voice Control, Reduce Motion, Reduce Transparency, Increased Contrast and Differentiate Without Color.

### Brand extension and governance

- `14-app-store-and-marketing.md` — App Store screenshots, preview video, website, press assets and launch imagery.
- `15-brand-qa-checklist.md` — review checklist for screens, copy, assets, features and implementation PRs.

## Source-of-truth hierarchy

When documents disagree, use this order:

1. accepted architectural/product decisions and safety/privacy requirements;
2. accepted entries in `99-brand-decisions-log.md`;
3. the Calipic Experience Constitution;
4. Brand Foundations;
5. final Visual Identity / Product Design Language / Voice standards;
6. implementation tokens and component specifications;
7. one-off campaign or marketing executions.

A campaign, mockup, or visual experiment must never redefine the product's core behavior by accident.

## Next milestone

Produce controlled visual prototypes rather than isolated moodboards.

The first prototype round should compare:

- four symbol constructions based on portrait + frame geometry;
- four color systems (deep distinctive blue, restrained violet, graphite + cool accent, dark cyan/teal);
- the same key surfaces in Light and Dark Mode;
- App Store/Home Screen small-size recognition;
- camera, Photo Check, editor, print-sheet and credit-purchase contexts.

Color and symbol should be chosen together after testing, not independently.
