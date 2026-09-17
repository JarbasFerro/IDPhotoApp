# Calipic — Visual identity

**Status:** Draft standard — consolidates accepted decisions; items marked *(working)* are not locked  
**Date:** 2026-09-17  
**Sources of truth:** `99-brand-decisions-log.md` (BD-033, BD-036, BD-037, BD-038, BD-039), the generators in `scripts/brand/`, and the evidence in `prototypes/01`–`09`. When this document and the decisions log disagree, the log wins.

---

## 1. The idea in one sentence

A portrait inside a crop frame that reads as the letter **C**, in one restrained teal, inside an otherwise native iOS product. First read: ID photo. Second read: C.

---

## 2. Symbol

**Master files (generated — never hand-edit):** `assets/calipic-icon-v2-master.svg` (≥ 60 px), `assets/calipic-icon-v2-small.svg` (< 60 px). Generator: `scripts/brand/build-icon-v2.py`.

### 2.1 The frame — the fixed brand element (Accepted, BD-036)

On a 1024 canvas:

| Property | Master | Small master |
|---|---|---|
| Stroke, uniform, round caps | 72 | 82 |
| Frame centre-line box | 664 × 664, corner radius 130 on all four corners | same |
| Gaps top / bottom / left (visible, between caps) | 30 / 30 / 30 | 44 |
| Right corners | drawn for 52° only → the wide opening that makes the C | same |
| Symmetry | exact mirror about the horizontal centre line | same |
| Optical shift | whole mark 14 units to the right, balancing the open side | same |

The frame never changes: not for characters, campaigns, seasons or locales.

### 2.2 The character — a slot (BD-038)

Default: **swept** — a plain front-facing bust (swept hair, ears, neck, broad shoulders, flat print-like base 52 units above the frame's inner edge). People may choose another character for their own Home Screen; the App Store, marketing and every lock-up use the default. Rules for characters: same base line and size; no skin, no realistic facial features (simple negative-space cut-outs are allowed); a character stays only if identifiable at 180 px; the BD-023 guardrails apply (no Face ID, surveillance, Contacts-avatar or mascot-illustration look).

### 2.3 Finish *(working)*

App icon only: a lit single-hue teal field (`#15899A` → `#0A5863`), a soft top-left light, a white mark with a faint cool falloff and a soft contact shadow. No bevels, gloss, sparkle or multi-hue gradients. Paper grain is part of the study but is not shipped in the asset catalog (size). Dark and tinted appearances: see `prototypes/07` (in progress). A layered Icon Composer asset for Liquid Glass remains open.

### 2.4 Clear space and minimum size

- Clear space around the symbol: one frame-stroke × 2 (144 units on the 1024 canvas) on every side; the app-icon tile already includes it.
- Minimum: 29 px with the small master. Below 60 px always use the small master. The character is decoration below 60 px; the C-frame must still read.

---

## 3. Wordmark and lock-ups (Accepted, BD-039)

Drawn from the same stroke, caps and 52° opening as the frame; the capital C is the frame. Files: `assets/calipic-wordmark.svg`, `calipic-lockup-integrated.svg` (**primary**: the symbol is the C; 36-unit stroke), `calipic-lockup-horizontal.svg`, `calipic-lockup-stacked.svg`. Construction, clear space (½ cap height) and the descriptor rule are in `prototypes/09-wordmark.md`. The wordmark never appears inside the app icon, and in-product UI uses system typography, not the wordmark's letterforms.

---

## 4. Colour

### 4.1 Brand colour (hue Accepted, values *working* — BD-033)

| Role | Light | Dark | Use |
|---|---|---|---|
| Accent | `#0E6F7C` | `#4FC3D1` | text-weight accents, glyphs, selection, the mark |
| Accent fill | `#0E6F7C` | `#25828E` | filled buttons and badges under a white label (≥ 4.5:1; ≥ 7:1 in Increase Contrast) |
| Ink | `#111111` / system label | system label | the mark in monochrome; all body UI uses system colours |

Increase Contrast values live in the asset catalog (`BrandAccentB`, `BrandAccentFillB`), written by `scripts/brand/generate-brand-assets.py`, which fails if a fill drops below its contrast minimum. In code: `Brand.accent`, `Brand.accentFill` (`App/Brand/BrandRoles.swift`).

### 4.2 Rules

- Surfaces are system-neutral. Teal is for the primary action, selection, the mark and a very small number of signature details — never large fields around a portrait.
- **Status colours are independent of the brand** and never colour-only: pass / warn / fail / manual check come from `StatusStyle` with a symbol and text.
- Destructive and neutral toolbar items never take the brand tint.
- No purple, no multi-hue gradients, no "AI" colour treatment.
- Light and Dark are equal citizens (BD-019).

---

## 5. Typography

In-product: system typography with Dynamic Type, always (BD-003). The wordmark's letterforms are a logo, not a typeface: never set headlines, buttons or body text in them. Marketing may pair the wordmark with the system font on Apple surfaces or a neutral grotesque elsewhere; no display faces.

---

## 6. Motif

The crop frame with small gaps and an open right side appears in the product in exactly one place: the guided-camera framing guide, in the photo's 26:32 proportions, taking the guide's status colour and never teal over a portrait. It was tried and **rejected in the crop editor** (it read as a broken guide and as chrome) — see `prototypes/08-frame-motif-in-product.md`. Executable spacing, radii, type roles and motion live in `11-design-tokens.md`. Rejected motifs stay rejected: registration marks, calipers, passport-agency seals (BD-020).

---

## 7. Misuse

Do not: close the right side of the frame; equalise the right opening with the small gaps; change stroke weight between frame segments; rotate, outline, add a shadow to or fill the flat mark; put the mark on a photograph or a busy background without a solid field; recolour it outside §4; place a character outside the set; put the wordmark in the app icon; typeset "Calipic" in another font as a logo; translate the name; use the symbol as a generic "user" or "profile" glyph inside the app (that is what SF Symbols are for — BD-004).

---

## 8. Still open

1. Finish lock, dark / tinted / clear appearances, Icon Composer layered asset.
2. Teal values verified on device in bright and dim light and against real portraits.
3. Wordmark: designer's optical pass.
4. App Store presentation (screenshots, preview) — `16-app-store-and-marketing.md`, planned.
