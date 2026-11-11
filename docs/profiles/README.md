# Profile research index

One document per official profile (L19-013). Each profile must pass the release gate in [01 §15](../01-product-definition.md). Official pages found through search count as sources (ADR-051). The research order is in [25 §3](../25-wave-a-document-types.md).

## Status

| Profile | Document | Status | Output | Official editing rule (reference) | Home print |
|---|---|---|---|---|---|
| Spain · DNI | [13](../13-spain-foto-carnet.md) | Researched (reference profile) | Print 26 × 32 mm | Not stated | Yes |
| US · passport | [us-passport-and-visa](us-passport-and-visa.md) | Researched | Print 2 × 2 in + online-renewal digital | No software, app, filter, or AI changes | Yes, on photo paper |
| US · visa | [us-passport-and-visa](us-passport-and-visa.md) | Researched | Digital 600 × 600 + print 2 × 2 in | As passport | When a post asks |
| UK · passport | [uk-passport](uk-passport.md) | Researched | Digital ≥ 600 × 750 (primary) + print 35 × 45 | Unaltered by software | **No**: shop print |
| Japan · passport | [japan-passport-and-my-number](japan-passport-and-my-number.md) | Researched | Print 35 × 45 | Not stated | Not stated |
| Japan · My Number card | [japan-passport-and-my-number](japan-passport-and-my-number.md) | Researched | Print 35 × 45 + digital | Edited images may not be accepted | Not stated |
| Italy · passport, CIE | [italy-passport-and-cie](italy-passport-and-cie.md) | Researched | Print 35 × 45 | CIE: not cropped, straightened, or retouched | Not stated |
| Spain · TIE, driving licence | [spain-tie-and-driving-licence](spain-tie-and-driving-licence.md) | Researched | Print 32 × 26 | Not stated | Not stated |
| Netherlands · passport, ID card, driving licence | [netherlands-passport-id-driving-licence](netherlands-passport-id-driving-licence.md) | Researched | Print 35 × 45 at **≥ 400 dpi** | Not stated | Allowed (self-made accepted) |
| South Korea · passport | [south-korea-passport](south-korea-passport.md) | Researched; kept by the founder | Print 3.5 × 4.5 | No edited or composited backgrounds | Officially "unsuitable"; kept anyway |
| Schengen visa | [schengen-visa](schengen-visa.md) | Researched | Print 35 × 45 | ICAO | Not stated |
| Australia · passport | [wave-a-second-group](wave-a-second-group.md) | Researched | Print 35–40 × 45–50 | Filters and retouching cause problems | **No**: dye-sub shop print only |
| UK · driving licence | [wave-a-second-group](wave-a-second-group.md) | Researched | Digital + print 35 × 45 | As UK passport | Shop print |
| Japan · driving licence | [wave-a-second-group](wave-a-second-group.md) | Researched | Print 24 × 30 | Not stated | Photo paper only |
| Germany · driving licence | [wave-a-second-group](wave-a-second-group.md) | Researched | Print 35 × 45 | Not stated | Yes (biometric print) |
| Switzerland · ID card (commune) | [wave-a-second-group](wave-a-second-group.md) | Researched | Print 35 × 45 | Not stated | Depends on the commune |
| Saudi Arabia · resident photo (Absher) | [wave-a-second-group](wave-a-second-group.md) | Researched | Digital 2:3, ≤ 1 MB | Not modified by programs | — |
| Canada · visitor visa | [wave-a-second-group](wave-a-second-group.md) | Researched | Print ≥ 35 × 45 | Digital must not be altered | Quality photo paper |

All 13 approved profiles are researched, and the verification list too ([wave-a-second-group](wave-a-second-group.md)).

**Confirmed by the founder (2026-11-11):**

- the 7 profiles above;
- Brazil and Mexico served by custom-size shortcuts **3 × 4 cm** and **2.5 × 3 cm (tamaño infantil)**;
- a **black-and-white** custom-size option.

Wave A has **22 profile files** (several items cover more than one document). They are encoded as rule data in [Rules/catalog/v1](../../Rules/README.md).

**Open technical points:**

- **Netherlands:** prints need 400 dpi, and the head size depends on age (L19-020).
- **Australia and the UK:** the print route goes through a shop (L19-005).

## Editing

Calipic offers background replacement and Document Tone on every profile (founder decision, ADR-051). The official wording is recorded above for reference. *Original* is always one tap away.
