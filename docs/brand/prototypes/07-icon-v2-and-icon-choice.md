# Calipic — Icon v2 (simpler silhouette, stronger C, teal) and choose-your-icon

**Status:** Candidate for founder review — symbol form not locked (BD-036 stays Working)  
**Date:** 2026-09-17  
**Follows:** [`06-icon-refinement-v1.md`](06-icon-refinement-v1.md)  
**Command:** `scripts/brand/build-icon-v2.py` (stdlib + inkscape; regenerates `icon-v2/` and the v2 masters)

---

## 1. Founder direction applied (2026-09-17)

After reviewing v1 the founder asked for three changes, and then proposed a fourth idea:

1. **A simpler silhouette** — a plain, neutral bust (reference: a generic swept-hair avatar silhouette) instead of the bun + loose strand. The v2 bust is an original drawing in that spirit, not a trace of the reference.
2. **The thicker stroke** — 72 units (v1 used 64).
3. **A wider right-hand gap to reinforce the C** — the right corners now stop after 52° of arc instead of 90°, so the opening runs almost the full height of the frame.
4. **Teal** as the brand colour (recorded in BD-033).
5. **Idea: let people choose their app icon** — see §4.

![v1 vs v2 geometry](icon-v2/sheet-geometry.png)

![Finished teal](icon-v2/sheet-finished.png)

---

## 2. Geometry (1024 canvas)

| Parameter | v1 | v2 master | v2 small (< 60 px) |
|---|---|---|---|
| Frame stroke | 64 | **72** | 82 |
| Net gap top / bottom / left | 30 | 30 | 44 |
| Right corners drawn | 90° (full corner) | **52°** | 52° |
| Right opening, net | 340 | **≈ 490** | ≈ 480 |
| Optical shift to the right | 0 | **14** (balances the open side) | 14 |
| Bust | bun, egg head, strand cut-out, lock | **one plain bust: swept hair, ears, neck, broad shoulders, flat base** | same |
| Signature strand | 22-unit cut-out | removed | removed |

Everything else keeps the v1 rules: identical radii (130), exact mirror symmetry about the horizontal centre line, identical round caps, generated from one `Spec`.

**Measured** (same script as round 1, teal, white mark on field; openness 0 = closed, 1 = open):

| Size | top/bottom gap | left gap | right opening |
|---|---|---|---|
| 180–80 px | 1.00 | 1.00 | 1.00 |
| 60 px | 0.98 | 0.91 | 1.00 |
| 40 px | 0.97 | 0.65 | 1.00 |
| 29 px | 0.71 | 0.95 | 1.00 |

(Master geometry at all sizes; the small master, with 44-unit gaps, is what should ship below 60 px.) Context sheets for the v2 master are in `icon-v2/icon-sizes/sheets/`.

**What the simpler bust buys:** no detail that can fail at small sizes, a more neutral read, and a clear visual hierarchy — frame, person, C — with the C now legible without explanation. **What it costs:** the bust alone is no longer ownable; ownability now rests on the C-frame (and on colour + finish). That trade is consistent with BD-021/BD-022 and makes §4 possible.

---

## 3. Finish

Unchanged from v1: lit single-hue teal field (`#15899A` → `#0A5863`, around the accent `#0E6F7C`), 10 % paper grain on the field, white mark with a faint cool falloff and a soft contact shadow. For iOS 26+ the shipping asset should be layered in Icon Composer (field / mark) so the system supplies highlights and the dark, tinted and clear appearances.

---

## 4. Choose your icon

**Idea (founder):** let people pick the app icon that suits them — a fun touch.

**Why it fits Calipic:** the frame-C is the constant brand element; the person inside is a slot. Swapping the person personalises the icon without diluting recognition, and it dissolves the open neutrality question from the handoff (§4: the v0 silhouette read female-presenting) — no single bust has to represent everyone. It also suits the audience lens in BD-016 (parents making photos for the family).

![Choose-your-icon set](icon-v2/sheet-variants.png)

First set, all sharing one head, ears, neck, shoulders and size — only the hair changes (`hair_paths()` in the script): **swept** (default), **short**, **curly**, **bob**, **long**, **bun**.

Honest assessment of this first pass: swept, short, curly, bob and bun read well down to 60 px; **long** is the weakest (a solid silhouette of straight long hair tends toward a plain block) and needs a designer's hand. Below 60 px all variants converge to "a person in a C" — which is fine: the choice is for the Home Screen, where the icon is 60 pt (120–180 px).

**Implementation notes (not built yet):**

- iOS alternate icons: `UIApplication.shared.setAlternateIconName(_:)`; each alternate is an app-icon set in the asset catalog, listed via `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` (+ `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`). iOS shows a system alert when the icon changes; that is expected and cannot be suppressed.
- Placement: a quiet "App Icon" row in the app's settings/about area with a grid of the icons — never in the capture → check → print path (Experience Constitution: nothing between the person and the finished photo).
- The App Store listing, marketing and the wordmark lock-up always use the **default** icon.
- Keep the set small (6–8) and structurally identical; colour stays teal for all — colour choice is not offered, so the brand colour keeps its recognition job.
- Guardrails from BD-023 still apply to every variant: no Face ID, surveillance, Contacts-avatar or character-illustration look. No skin, no facial features, no accessories that imply religion, age or profession.
- Every alternate needs the same dark / tinted / clear appearances as the default.

---

## 5. Open points

1. Approve the v2 **frame** (stroke 72, 52° right corners, 30-unit gaps)? This is the part that becomes the fixed brand element.
2. Approve the **default bust** (swept) — or choose another default from the set.
3. The variant set itself: which to keep, which to add (e.g. a child, a headscarf-neutral rounded outline, a ponytail), and a redraw of "long".
4. Exact teal values (light `#0E6F7C`, dark `#4FC3D1`, fill roles from PR #10) remain working values until tested on device.
