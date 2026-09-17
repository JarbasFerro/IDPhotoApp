# Calipic — Identity exploration handoff

**Status:** Active handoff / resume point  
**Date:** 2026-09-17  
**Purpose:** Allow another LLM/designer to continue the Calipic identity work without reconstructing the prior conversation.

---

## 1. Read these first

Before changing the identity, read:

1. `docs/brand/01-brand-foundations.md`
2. `docs/brand/02-experience-constitution.md`
3. `docs/brand/03-color-strategy-research.md`
4. `docs/brand/04-market-prioritization.md`
5. `docs/brand/05-creative-territories.md`
6. `docs/brand/99-brand-decisions-log.md`
7. this document

The brand direction is already substantially defined. Do not reopen settled strategic questions unless there is a concrete reason.

---

## 2. Current identity direction

The current synthesis is:

> **A recognizable portrait inside a crop/frame system that also reads as the letter C, used inside an almost invisible native-iOS product experience, with physical printing as the satisfying completion of the task.**

The current symbol is **provisional, not final**. It is good enough to carry into color and product-context testing. Do not spend the next iteration endlessly polishing the logo in isolation.

> **Update — 2026-09-17 (founder note).** The v0 icon is only a draft. The territory is provisionally frozen (BD-036), but the drawing still needs a lot of form refinement, and the final icon is expected to get finishing touches — shadows, depth, texture — rather than stay a flat glyph. The steps in §7 still run first on v0 with geometry held fixed; their findings are provisional and must be re-run on the refined icon before lock. See the BD-036 amendment.

### Current icon assets

- `docs/brand/assets/calipic-icon-draft-v0.png` — raster snapshot of the latest visual draft from the exploration session.
- `docs/brand/assets/calipic-icon-draft-v0.svg` — editable geometry draft intended as a reconstruction starting point, not a final production SVG.

Use the PNG as the visual reference and the SVG as the structural/geometry reference.

---

## 3. Icon concept

The icon combines two ideas:

1. **ID-photo / portrait framing** — it should immediately belong to the identity-photo category.
2. **Calipic / C** — the outer frame should clearly resolve into a capital `C` through a deliberately wider opening on the right.

The icon must work before the viewer understands the wordplay. First impression: `portrait / ID photo`. Second impression: `C`.

### Do not turn it into

- Face ID;
- surveillance/facial-recognition imagery;
- a generic Contacts/avatar icon;
- a generic camera aperture;
- an AI/sparkle symbol;
- a bureaucratic/passport-agency seal;
- registration-mark graphics;
- calipers or measurement-tool clip art.

---

## 4. Current portrait silhouette

The selected direction is a simplified, elegant bust silhouette rather than a generic circle + semicircle avatar.

Current characteristics:

- front-facing bust;
- hair gathered into a small bun;
- one distinctive curved loose lock / negative-space strand flowing down the left side of the face;
- no facial features;
- smooth neck and shoulder transition;
- refined rather than cute;
- enough personality to be memorable without becoming a character illustration;
- monochrome and legible at small size.

The current silhouette happens to read as female-presenting. That is acceptable for the draft because it gives the mark more personality, but the final identity should be evaluated for international/category neutrality before lock.

The hair strand is currently the most useful signature detail. Preserve the concept during refinement unless testing proves it fails at small sizes.

---

## 5. Frame construction — important

This is the most important geometry instruction for future SVG work.

### Structural idea

The frame should look like a rounded crop/focus frame that has **small gaps around it**, except on the **right side**, where the opening is much wider. The unequal right opening is what creates the `C`.

The user explicitly rejected a nearly closed crop frame where the C could only be noticed after explanation.

### Required geometry

- uniform stroke width everywhere;
- identical corner radii where geometrically equivalent;
- identical endpoint treatment everywhere;
- endpoints are round and visually identical;
- exact top/bottom mirror symmetry across the horizontal centerline;
- equal small gap at the top center and bottom center;
- a similarly small interruption at the left center;
- the right-side opening is **substantially larger** than those small gaps;
- top-right and bottom-right elements are mirrored exactly;
- optical centering matters more than naive mathematical centering after the geometry is clean.

### Visual hierarchy

The viewer should perceive:

1. portrait frame;
2. portrait/person;
3. capital C.

The C must still be clearly visible without destroying the crop-frame reading.

---

## 6. SVG draft notes

`calipic-icon-draft-v0.svg` intentionally uses simple primitives and paths so an LLM or designer can manipulate it safely.

It is **not** a traced production master. Before final identity lock, rebuild/refine the master in true vector geometry and verify:

- exact symmetry;
- pixel-grid behavior at small raster sizes;
- consistent optical stroke weight;
- curve continuity;
- silhouette/frame spacing;
- visual center;
- minimum-size survival of the hair strand;
- no accidental tangencies between silhouette and frame;
- clean behavior in monochrome and reversed-out versions.

Do not convert the current raster directly into an auto-traced path and call it final.

---

## 7. What happens next

Do **not** make another broad logo exploration. The symbol territory is selected provisionally.

Proceed in this order.

### Step 1 — Controlled color matrix

Keep the icon geometry fixed. Test exactly the same mark using the color systems already identified in `03-color-strategy-research.md`.

Primary candidates:

1. deep distinctive blue;
2. dark cyan / blue-teal;
3. graphite + restrained cool accent;
4. one evidence-backed alternative that is clearly differentiated from the first three.

Rules:

- do not select color from an isolated swatch;
- test the full icon and real product surfaces;
- avoid contemporary purple/gradient AI branding;
- keep the interface neutral enough that human skin tones remain visually primary;
- status colors (`pass`, `warn`, `fail`, `manual_check`) must remain semantically independent from brand accent color.

### Step 2 — Real app-icon size testing

Render each serious candidate at realistic contexts/sizes:

- App Store result size;
- iPhone Home Screen;
- Spotlight/Search;
- Settings/list-style small icon contexts;
- large marketing presentation.

Place it among contemporary high-quality iOS icons rather than evaluating it alone on a blank artboard.

Reject any solution that only works at 1024 px.

### Step 3 — Light / Dark / accessibility color tests

For finalists verify:

- Light Mode;
- Dark Mode;
- Increased Contrast;
- grayscale;
- common color-vision deficiencies;
- icon over visually busy Home Screens;
- photo-centric product screens.

### Step 4 — Product-context test

Apply the same identity direction to representative Calipic screens without redesigning iOS itself:

1. Home;
2. Guided Camera;
3. Photo Check;
4. Editor;
5. Print Sheet / Completion.

The purpose is to answer:

> How little explicit branding is required for the product to still feel recognizably Calipic?

Current answer hypothesis: very little.

Native iOS components, system typography, semantic materials, SF Symbols, accessibility behavior, and current system interaction patterns remain the baseline.

### Step 5 — Wordmark

Only after symbol + color are stable, develop:

- `Calipic`;
- `Calipic — ID Photos`;
- symbol + wordmark lockup.

Do not create an over-stylized display wordmark. The standalone symbol should carry most of the identity. System typography remains the in-product UI baseline.

### Step 6 — Formal visual identity specification

Then complete the future `docs/brand/visual-identity` specification covering at minimum:

- master symbol geometry;
- optical corrections;
- safe area;
- minimum size;
- app icon composition;
- monochrome and reversed variants;
- semantic color system;
- Light/Dark variants;
- brand/marketing typography if any;
- framing/crop motif;
- misuse examples;
- photography interaction;
- accessibility constraints;
- App Store presentation.

### Step 7 — Product design language

After the visual identity stabilizes, define how Calipic behaves and looks inside iOS:

- whitespace and density;
- hierarchy;
- surfaces/materials;
- photo framing;
- status presentation;
- buttons and toolbars;
- sheets;
- cards only where structurally useful;
- editor controls;
- print previews;
- motion;
- haptics.

### Step 8 — Executable design system

Finally translate approved rules into:

- semantic colors;
- typography roles;
- spacing scale;
- corner radii;
- materials;
- motion values;
- icon sizing;
- SwiftUI tokens/components;
- accessibility variants.

---

## 8. Decision hierarchy during exploration

When otherwise-good choices conflict, use the accepted order:

1. native iOS familiarity;
2. beauty;
3. accessibility.

Correctness, privacy, and truthful compliance language are non-negotiable constraints and are not traded away for any of the three.

---

## 9. Brand character reminder

Calipic should feel:

- elegant;
- friendly;
- photographic;
- practical;
- sophisticated;
- quietly premium.

It must not feel:

- complicated;
- AI-branded;
- generic;
- childish;
- cheap;
- colorful for its own sake;
- crowded;
- confusing;
- visually uninteresting.

Outside the photograph, visual expression should remain extremely restrained.

---

## 10. Commercial/product context that affects identity

Do not design the identity as if Calipic were a generic photo editor.

The user-facing promise is centered on:

- an exceptionally simple ID-photo workflow;
- correct digital output;
- physical print output as a first-class destination;
- on-device privacy as a primary promise;
- no AI theater;
- no intrusive advertising;
- intended credit model: tutorial result free + initial free credit, then inexpensive paid credits;
- launch-language target: English, Spanish, Portuguese (Brazil).

Current consumer-facing naming direction:

> **Calipic — ID Photos**

---

## 11. Immediate resume instruction for another LLM

If continuing from this file, do this next:

> Use `docs/brand/assets/calipic-icon-draft-v0.png` as the visual reference and `calipic-icon-draft-v0.svg` as the editable construction reference. Do not redesign the symbol yet. Build a controlled color matrix for the same icon using the candidate color systems from `03-color-strategy-research.md`, then evaluate each at realistic iOS icon sizes and in Light/Dark product contexts. Document findings before selecting a final color.

The next deliverable should therefore be **evidence from controlled color/context testing**, not another moodboard and not another open-ended logo round.
