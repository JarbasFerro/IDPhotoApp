# Profile research — United Kingdom passport

**Status:** Researched (L19-013); search-based official evidence accepted (ADR-051).
**Date:** 2026-11-11
**Profile:** `gb.passport`. The **digital** route (online application) is primary. The print route is secondary and sent to a shop, not printed at home.

**Evidence levels:**

| Level | Meaning |
|---|---|
| **O-s** | Official GOV.UK or HM Passport Office page, as quoted in a search restricted to gov.uk (accepted, ADR-051) |
| **?** | Not established |

## 1. Editing

**Official wording (reference):**

- Photos must be "unaltered by computer software"; "you can't 'correct' your passport photo". Sources: [Digital photos](https://www.gov.uk/photos-for-passports), [Rules for digital passport photos](https://www.passport.service.gov.uk/help/photo-rules).
- The online service crops the photo itself, so do not crop tightly.

**Calipic (ADR-051):** background replacement and tone are offered, with **Original** one tap away. The replacement colour for this profile is **light grey or cream**, not white.

## 2. Digital route (online application)

| Rule | Value | Evidence |
|---|---|---|
| Pixels | At least **600 × 750** (width × height) | O-s |
| File size | 50 KB to 10 MB. One GOV.UK document says 5 MB: **stay under 5 MB** | O-s, conflicting |
| Colour, focus | Colour, clear, in focus | O-s |
| Recency | Taken **within the last month** | O-s |
| Background | Plain and light-coloured, no texture or pattern, no objects. Cream or light grey works best. The accessible standard says any plain light colour is accepted | O-s: [Photo standards (accessible)](https://www.gov.uk/government/publications/photographic-standards/photo-standards-accessible) |
| Light | Even; natural light facing a window is best | O-s |
| Setup | Stand **50 cm in front of the background** (no shadow behind). The helper stands **1.5 m away** to fit head, shoulders, and upper body | O-s: [How to take a digital passport photo](https://www.passport.service.gov.uk/photo/how-to-take-a-photo) |
| Who takes it | Taken on your own device, with someone else's help | O-s |

**Proposed Calipic preset:**

- JPEG, **1200 × 1500 px** (4:5);
- head, shoulders, and upper body framed with margin;
- 50 KB–5 MB.

These numbers are taken directly from the rules above (≥ 600 × 750, ≤ 5 MB). Validate with a beta tester who applies online.

## 3. Print route (paper application)

| Rule | Value | Evidence |
|---|---|---|
| Size | **45 mm high × 35 mm wide** | O-s: [Guidance for photographers](https://www.gov.uk/government/publications/passport-photos-guide-for-photographers/guidance-for-photographers) |
| Head | **29–34 mm**, chin to crown | O-s |
| Paper | High-quality photographic paper, medium/low gloss or matt | O-s |
| Home printing | **Generally not accepted:** "photos printed at home are not usually clear enough to measure facial biometrics" | O-s |
| Copies and countersignature | Two identical photos. One is countersigned for first passports, lost/stolen/damaged replacements, and child renewals for children aged 11 or under | O-s |

**Consequence:** for the UK print route, Calipic offers **Print at a shop** (L19-005) with the 300 ppi lab JPEG, not home printing. The home-print path is hidden for this profile, with one line explaining why.

## 4. Children

| Age | Rule | Calipic check |
|---|---|---|
| Under 1 | Eyes need not be open | `manual_check`, never fail |
| Under 6 (sources disagree whether from age 0 or 1) | Neutral expression, closed mouth, and looking at the camera may be waived | `manual_check`, never fail |
| All children | A supporting hand must not be visible; no toys or dummies | `manual_check` |

Evidence: O-s, [Photo standards](https://assets.publishing.service.gov.uk/media/69a831faa2495f2d259f1447/Photo_standards_v51.0.pdf), [Guidance for photographers](https://www.gov.uk/government/publications/passport-photos-guide-for-photographers/guidance-for-photographers).

## 5. Optional verification (not required, ADR-051)

- [ ] [Get a passport photo: Digital photos](https://www.gov.uk/photos-for-passports): pixels, file size (5 MB vs 10 MB), "unaltered", recency
- [ ] [Rules for digital passport photos](https://www.passport.service.gov.uk/help/photo-rules) and [How to take a digital passport photo](https://www.passport.service.gov.uk/photo/how-to-take-a-photo): background, distances, cropping
- [ ] [Photo standards v51](https://assets.publishing.service.gov.uk/media/69a831faa2495f2d259f1447/Photo_standards_v51.0.pdf): head size, children, glasses, head coverings
- [ ] [Guidance for photographers](https://www.gov.uk/government/publications/passport-photos-guide-for-photographers/guidance-for-photographers): paper, home printing, countersignature
- [ ] Glasses and head-covering rules (not captured in this pass)
