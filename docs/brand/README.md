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
- [`05-creative-territories.md`](05-creative-territories.md) — four controlled identity territories and the original prototype matrix (its symbol-variant round is superseded by BD-036).
- [`06-identity-exploration-handoff.md`](06-identity-exploration-handoff.md) — resume point for the identity work: provisional icon direction, frame geometry rules, and the ordered next steps.

### Prototype evidence

- [`prototypes/`](prototypes/README.md) — controlled color, icon-size, accessibility and product-context test evidence. In progress; every render must be reproducible from a script under `scripts/brand/` (planned path, delivered with the prototype PRs).
- `assets/calipic-icon-draft-v0.svg` / `.png` — **draft only** (see "Symbol status" below).

### Draft standards

- [`11-design-tokens.md`](11-design-tokens.md) — draft executable tokens: spacing, radii, strokes, type roles, sizes and motion as SwiftUI constants (`App/Brand/DesignTokens.swift`), rules for adding one, and what is deliberately not tokenised. Colours stay in `Brand` and `StatusStyle`.
- [`12-voice-and-writing.md`](12-voice-and-writing.md) — draft product voice, vocabulary, instruction, error and compliance language, localization notes.
- [`15-brand-qa-checklist.md`](15-brand-qa-checklist.md) — draft review checklist for screens, copy, assets, features and implementation PRs.

## Current creative hypothesis

The most promising synthesis to prototype is:

> **A highly ownable face + crop-frame symbol, inside an almost invisible native iOS interface, with print as the satisfying final transformation.**

The four creative territories are:

1. **Portrait Frame** — category recognition and core symbol.
2. **Quiet Studio** — product UI/design philosophy.
3. **Photo to Print** — completion and marketing proposition.
4. **Optical Order** — geometric ownability and calibration meaning.

### Symbol status (2026-09-17)

The symbol **territory** is provisionally frozen by BD-036: a portrait/bust silhouette inside a rounded crop frame whose wider right-side opening reads as a capital `C`. There is no further broad symbol exploration round.

The **drawing** is not frozen. `assets/calipic-icon-draft-v0.*` is only a draft stand-in. The founder expects substantial form refinement, and expects the final icon to receive finishing touches — shadows, depth, texture — rather than remain a flat glyph. Color and context tests currently run on the flat v0 and must be re-run on the refined icon before anything is locked.

No final symbol or color is approved yet.

## Planned documentation

Numbering note (2026-09-17): `06` is taken by the identity handoff, so the planned visual-system documents now start at `07`. `12` and `15` keep their numbers because drafts exist under those names; the documents around them were renumbered so that nothing collides. File names without a link do not exist yet.

### Visual system

- `07-visual-identity.md` — final symbol, wordmark, app icon, color system, composition and misuse rules.
- `08-product-design-language.md` — hierarchy, spacing, surfaces, photo treatment, controls, states, component behavior.
- `09-photography-and-image-language.md` — marketing photography, in-product imagery, manipulation boundaries, representation.
- `10-iconography-and-symbols.md` — SF Symbols policy and custom-symbol exceptions.

### Executable design system

- [`11-design-tokens.md`](11-design-tokens.md) — semantic colors, spacing, radii, typography roles, materials, motion values, icon sizing and SwiftUI mapping. **Draft exists.**
- [`12-voice-and-writing.md`](12-voice-and-writing.md) — product voice, vocabulary, instructions, errors, confidence language and localization. **Draft exists.**
- `13-motion-and-haptics.md` — motion grammar, transitions, haptics and Reduce Motion behavior.
- `14-accessibility-standard.md` — brand expression under Dynamic Type, VoiceOver, Voice Control, Reduce Motion, Reduce Transparency, Increased Contrast and Differentiate Without Color.

### Brand extension and governance

- [`15-brand-qa-checklist.md`](15-brand-qa-checklist.md) — review checklist for screens, copy, assets, features and implementation PRs. **Draft exists.**
- `16-app-store-and-marketing.md` — App Store screenshots, preview video, website, press assets and launch imagery.

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

Produce controlled test evidence — not moodboards, and not another broad symbol round (BD-036). The order of work is defined in [`06-identity-exploration-handoff.md`](06-identity-exploration-handoff.md) §7.

With the v0 icon geometry held fixed, the current round compares:

- four color systems: deep distinctive blue; dark cyan / blue-teal; graphite + restrained cool accent; and one evidence-backed differentiated alternative. The test batch uses a warm deep amber-ochre challenger, drawn from the conditional yellow/orange challenger line in `03-color-strategy-research.md` §8; its closeness to the `warn` status family is a known risk recorded in BD-037. Purple/violet is not in the batch, per the handoff's instruction to avoid contemporary purple/gradient AI branding;
- realistic icon sizes and contexts: App Store result, Home Screen, Spotlight/Search, Settings-style small icon, large marketing presentation;
- Light Mode, Dark Mode, Increased Contrast, grayscale and common color-vision deficiencies;
- Home, Guided Camera, Photo Check, Editor and Print Sheet / Completion contexts (handoff Step 4). The credit-purchase screen required by `03-color-strategy-research.md` §9 is not in the handoff's list and is still owed before color lock.

The hex values used are recorded in BD-037 as **test values only**. BD-033 is unchanged: no brand color is approved.

Evidence lands in [`prototypes/`](prototypes/README.md). Its synthesis document is a recommendation to the founder, not a decision.

In parallel, the icon drawing needs form refinement and finishing (see "Symbol status" above). Any finding made on the flat v0 must be re-run on the refined icon before color or symbol is locked.

Color and symbol should be chosen together after testing, not independently.
