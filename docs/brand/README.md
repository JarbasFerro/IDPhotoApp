# Calipic brand system

This directory defines the strategic, verbal, visual, interaction, and implementation rules that make Calipic feel like one coherent product.

The goal is not to create a decorative brand layer on top of iOS. Calipic should feel unmistakably itself while remaining deeply native to iPhone. The system therefore starts with product character and experience principles before specifying logo, color, typography, motion, or design tokens.

## Status

**Working brand name:** Calipic  
**Brand system status:** Discovery / foundation draft  
**Technical repository name:** remains `IDPhotoApp` for now  
**Technical project identifiers:** unchanged until a separate implementation decision is made

## Existing product constraints inherited by the brand system

The brand system must preserve the product decisions already documented elsewhere in the repository:

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
- internationalization and localization are structural requirements.

Brand decisions may refine the expression of these principles, but should not silently contradict them.

## Documentation architecture

### Phase 1 — Define the brand core

1. [`00-discovery-questionnaire.md`](00-discovery-questionnaire.md)  
   Open questions, assumptions, and founder decisions needed before identity work is locked.

2. [`01-brand-foundations.md`](01-brand-foundations.md)  
   Purpose, promise, positioning, audience, personality, differentiation, emotional territory, and brand boundaries.

3. [`02-experience-constitution.md`](02-experience-constitution.md)  
   Short set of durable rules that every Calipic experience should satisfy.

4. `03-ux-principles.md`  
   Product-level behavioral principles derived from the brand and the existing UX architecture.

### Phase 2 — Define the visual language

5. `04-visual-identity.md`  
   Logo, wordmark, app icon, color system, typographic expression, graphic language, composition, and misuse rules.

6. `05-product-design-language.md`  
   How Calipic expresses itself inside native iOS interfaces: hierarchy, spacing, surfaces, photo treatment, controls, states, and component behavior.

7. `06-photography-and-image-language.md`  
   Marketing photography, in-product imagery, user-photo treatment, before/after examples, and manipulation boundaries.

8. `07-iconography-and-symbols.md`  
   SF Symbols policy, custom-symbol exceptions, rendering modes, weights, semantic consistency, and animation.

### Phase 3 — Make the system executable

9. `08-design-tokens.md`  
   Semantic colors, spacing, radii, typography roles, materials, motion values, icon sizing, and SwiftUI mapping.

10. `09-motion-and-haptics.md`  
    Motion grammar, transitions, timing, spring behavior, haptics, reduced-motion alternatives, and sensory-feedback policy.

11. `10-voice-and-writing.md`  
    Product voice, vocabulary, instruction patterns, error language, confidence language, localization principles, and terminology.

12. `11-accessibility-standard.md`  
    Brand expression under Dynamic Type, VoiceOver, Voice Control, Reduce Motion, Reduce Transparency, Increased Contrast, and Differentiate Without Color.

### Phase 4 — Govern and extend

13. `12-app-store-and-marketing.md`  
    App Store screenshots, preview video, website, press assets, product mockups, launch imagery, and social presence.

14. `13-brand-qa-checklist.md`  
    Review checklist for screens, copy, assets, new features, App Store materials, and implementation pull requests.

15. [`99-brand-decisions-log.md`](99-brand-decisions-log.md)  
    Durable record of accepted, rejected, and deferred brand decisions.

## Source-of-truth hierarchy

When documents disagree, use this order:

1. accepted architectural/product ADRs and safety/privacy requirements;
2. the Calipic Experience Constitution;
3. Brand Foundations;
4. Product Design Language and Voice & Writing standards;
5. implementation tokens and component specifications;
6. one-off campaign or marketing executions.

A campaign, mockup, or visual experiment must never redefine the product's core behavior by accident.

## Working principle

> Calipic should not look like a branded shell around iOS. It should feel like a focused Apple-platform product whose precision, restraint, photography, and language consistently reveal the Calipic character.

This statement is a working hypothesis until the foundation questions are answered.