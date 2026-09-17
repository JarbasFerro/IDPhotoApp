# Calipic — Color recommendation (synthesis of prototype round 1)

**Status:** Recommendation for founder decision — does **not** change BD-033  
**Date:** 2026-09-17  
**Inputs:** [`01-color-matrix.md`](01-color-matrix.md), [`02-icon-size-context.md`](02-icon-size-context.md), [`03-accessibility-color.md`](03-accessibility-color.md), [`04-product-context.md`](04-product-context.md)  
**Icon used:** draft v0 stand-in, flat. The drawing will be substantially refined and finished (shadows, depth, texture) before lock (BD-036). Everything below is a colour finding, not a drawing finding.

---

## 1. Short answer

Carry **two finalists** into the icon-refinement round, not one:

1. **B — dark cyan / blue-teal** (`#0E6F7C` light) — recommended lead.
2. **A — deep blue** (`#1F3FA8` light) — recommended runner-up and safe fallback.

Keep **C — graphite** as the *neutral system* that either finalist sits on (ink, monochrome and reversed variants), not as a competing brand colour. Retire **D — warm amber-ochre** as an in-app accent.

Do not lock the hue yet. Lock it on the refined icon, after the same scripts are re-run on it.

---

## 2. What the four evidence documents agree on

| Question | A deep blue | B blue-teal | C graphite + cool | D amber-ochre |
|---|---|---|---|---|
| Matrix ranking (01) | 2 | **1** | 3 | 4 |
| Shelf presence at 60 px and below (02) | strong; best mark contrast (9.0:1) | strong; most distinctive hue (5.9:1) | crisp but no colour identity; accent field weakest tile | blends into warm icon cluster (4.2:1) |
| Light-mode text/control contrast (03) | passes | passes | accent misses 4.5:1 (fix: `#51728E`) | misses 4.5:1 (fix: `#A45E00`) |
| Separation from status colours (03, 04) | clear of pass/warn/fail; **dark value close to system blue** | clear in normal vision; **dark value nears system green under tritanopia**; separable from `pass` in app | closest to the neutral `manual_check` grey | **collides with `warn`**; with pass/fail under protan/deutan |
| Product context (04) | never competes with a status | stays separable from `pass` | most restrained; least recognisable | near-identical to `warn` in Dark |
| Brand risk named in 03 research | "generic utility app" | "AI / wellness / SaaS feel" | "insufficient App Store differentiation" | warmth near skin tones |

Consistent across all four documents:

- **Treatment 2 (white mark on accent field) is the app-icon treatment.** It is the only one that holds a solid tile on every wallpaper and keeps a readable hue at 29 px. Treatment 1 loses its edge on light wallpapers (1.17:1) — depth/finishing on the final icon may partly recover that, so re-test.
- **D fails the status-independence rule** (03 research §6) in normal vision. It answered its question: the set does not lack shelf recognition enough to justify the conflict.
- **C is a foundation, not an accent.** This matches the research conclusion in `03-color-strategy-research.md` §4.9.

---

## 3. Why B leads, and what could overturn it

B is the more ownable of the two. In the Home Screen and App Store sheets, A sits beside several familiar blue system/utility icons and reads as "one more blue app" — exactly the failure mode the research predicted. B is clearly not system blue, still calm and photographic, and keeps skin tones primary in the product screens.

B loses if any of these is true on the refined icon:

- the dark-mode value still reads "tech/SaaS" once the icon has depth (tune `#4FC3D1` toward a deeper, less minty value first);
- on-device testing shows the tritanopia convergence with `pass` green matters in practice (mitigated already: status is never colour-only);
- the founder's read of the refined icon is that teal is less *elegant/sophisticated* than deep blue — BD-034 ranks beauty above accessibility, and this is a judgement the evidence cannot make.

A's open issue is different: its dark value `#7C98F5` drifts toward periwinkle/violet at small sizes and sits near system blue. If A is chosen, the dark value needs re-deriving (less red, lower lightness) before anything else.

---

## 4. Findings that apply whichever hue wins

1. **Accent needs two roles, not one.** Every dark-appearance accent fails as a *button fill* under a white label (1.4–2.7:1). The colour system must define `accent` (text, glyphs, selection) and `accentFill` + `onAccentFill` (filled buttons) separately, per appearance and contrast setting.
2. **A root tint is nearly all the in-app branding required.** One tint touches one filled button and a few labels per screen; that already stops the app looking like default iOS. It is not enough for recognition — that has to come from the symbol, the crop-frame motif, the print sheet and the voice. This supports the handoff hypothesis ("very little").
3. **Destructive/neutral toolbar actions should not take the brand tint** (the Photo Check trash button currently does).
4. **Status colours are now structurally independent** (`StatusStyle.swift`), so the accent can change without touching pass/warn/fail/manual-check.

---

## 5. Input for the icon refinement (from 02, colour-independent)

The founder has flagged that v0 needs substantial form refinement and finishing. The size tests give that work concrete targets on the 1024 canvas:

- **Frame, C and bust read at every size down to 29 px.** The wide right opening is the most robust part of the construction — keep it.
- **Top/bottom/left gaps:** 4 units net never resolves at any shipping size, so the "three equal small gaps" are invisible in practice. ~26 units net to read at 60 px, ~38 at 40 px — or accept that small sizes show a plain C-frame.
- **Hair strand:** 12 units holds to 87 px, degrades at 58–80 px, fails at ≤ 40 px (reads as damage at 29 px). Needs ≥ ~22 units to hold at 60 px; plan a simplified small-size master without it.
- **Bust-to-frame clearance:** 36 units visually touches at 29 px; aim for ≥ 50.
- **Depth/texture:** must survive grayscale and the iOS 26 dark/tinted/clear icon appearances; finishing should help T1's edge problem and must not reduce mark/field contrast below ~4.5:1.

---

## 6. Limits of this round

- Flat v0 stand-in; all renders must be regenerated on the refined icon (`scripts/brand/*.sh <icon.svg>`).
- Product screenshots use a four-colour test card, not faces: skin-tone interaction is reasoned, not observed. The guided camera is not reachable on the simulator.
- The credit-purchase screen required by `03-color-strategy-research.md` §9 does not exist yet and was not tested.
- Increase Contrast system colours in 03 are from documentation memory; confirm on device. No physical-device, bright/dim ambient test yet.
- The candidate letters here (A–D) are this round's test systems (BD-037), not the candidate letters in the research document §8.

---

## 7. Proposed next steps

1. **Icon refinement round on the frozen territory** — true-vector master, the geometry targets in §5, a small-size variant, neutrality review of the silhouette, then finishing (shadows, depth, texture); deliver in B and A.
2. Re-run all four scripts on the refined icon; update 01–04; founder picks the hue → BD-033 Accepted.
3. Define the semantic colour roles (§4.1) with Light/Dark/Increase Contrast values; replace the `-brandCandidate` test hook with the real `AccentColor`.
4. Product-context re-test with real portraits across skin tones, on device.
5. Then wordmark → visual-identity specification → product design language → tokens (handoff steps 5–8).
