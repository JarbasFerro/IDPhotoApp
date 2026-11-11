# Profile research — Netherlands passport, ID card, and driving licence

**Status:** Researched (L19-013); search-based official evidence accepted (ADR-051).
**Date:** 2026-11-11
**Profiles:**

- `nl.passport` and `nl.id-card`: print; identical rules from the RvIG Fotomatrix 2020.
- `nl.driving-licence`: print at the municipality. The **online** route uses RDW-recognized photographers only, so it is not a Calipic output.

| Rule | Value | Evidence |
|---|---|---|
| Size | **35 × 45 mm** (width × height) | [Rijksoverheid](https://www.rijksoverheid.nl/themas/migratie-en-reizen/paspoort-en-identiteitskaart/eisen-pasfoto-paspoort-id-kaart), [RvIG](https://www.rvig.nl/reisdocumenten/kwaliteitseisen-fotos-voor-identiteitsbewijzen) |
| Head, chin to crown | **Age 11 and over: 26–30 mm. Up to age 10: 19–30 mm** | [Fotomatrix 2020](https://www.rvig.nl/sites/default/files/2023-02/Fotomatrix%202020.pdf) |
| Face width | 16–20 mm, ear base to ear base | Fotomatrix |
| Background | Light grey, light blue, or white; even, one colour, no gradient | Rijksoverheid |
| Pose | Head straight, eyes level, not tilted, shoulders straight, mouth closed, neutral | Rijksoverheid |
| Print | Colour, high-quality smooth photo paper, **at least 400 dpi** | Rijksoverheid |
| Recency | At most 6 months old | Rijksoverheid |
| Who takes it | Self-made photos are allowed if they meet the rules (secondary sources; no prohibition found) | [25 §2](../25-wave-a-document-types.md) |
| Driving licence online | 901 × 1158 px JPEG, quality 80 %, ≤ 170 KB, from **RDW-recognized photographers** | [RDW](https://www.rdw.nl/zakelijke-partners/erkende-bedrijven/fotograferen-voor-rijbewijzen/fotograferen-voor-rijbewijs) |

**Calipic values:**

- head target by age: Calipic does not know the person's age, so it asks "Is this person 10 or younger?" for this profile only;
- replacement colour light grey (the most neutral of the three);
- print at the 300 ppi pipeline, which is **below the 400 dpi rule**: the NL profile needs a **400 ppi** print path (P12 change).
