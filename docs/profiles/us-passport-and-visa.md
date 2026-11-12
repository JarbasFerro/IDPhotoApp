# Profile research — United States passport and US visa

**Status:** Researched. Accepted on search-based official evidence (ADR-051): travel.state.gov refuses automated reading, so the official wording comes from search results restricted to that domain.
**Date:** 2026-11-11
**Profiles:** `us.passport` (print, plus the online-renewal digital preset) and `us.visa` (digital, plus print where a post asks for it).
**Evidence:**

| Level | Meaning |
|---|---|
| **O** | Official State Department page |
| **O-s** | Official page, as quoted in a domain-restricted search result (accepted, ADR-051) |
| **?** | Not stated on the official pages found |

## 1. Editing

**Official wording (reference):**

- The State Department "does not accept photos changed with computer software, phone apps, or filters". It checks every photo "for digital enhancement or alteration" and bars changes made with AI.
- For online renewal: "upload an original digital image with no changes, such as filters". The application lets the person "reposition or crop" the photo.
- Sources: [Passport Photos](https://travel.state.gov/en/passports/apply/help/photos.html), [Uploading a Digital Photo](https://travel.state.gov/content/travel/en/passports/how-apply/online-renewal-photo.html).

**Calipic (founder decision, ADR-051):**

- Background replacement and Document Tone are offered as on every profile, with **Original** one tap away. The accepted risk is that an edited photo may be rejected.
- Capture rules still apply:
  - no Portrait mode, depth effect, or beauty filter;
  - the output is never mirrored.

## 2. US passport — printed photo (`us.passport`, print)

| Rule | Value | Evidence |
|---|---|---|
| Size | **2 × 2 in (51 × 51 mm)** | O-s: [Passport Photos](https://travel.state.gov/en/passports/apply/help/photos.html) |
| Head size | **1 to 1⅜ in (25–35 mm)**, from the bottom of the chin to the **top of the hair**. Hair may extend past the edge if the whole head is shown at the right size | O-s: [Passport Photos](https://travel.state.gov/en/passports/apply/help/photos.html), [Photo FAQ](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/frequently-asked-questions.html) |
| Eye height | ? for passport. The visa composition template gives 56–69 % of the image height from the bottom (about 1⅛–1⅜ in on 2 × 2 in) | O-s (visa): [Composition Template](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/photo-composition-template.html) → use as an **advisory** target only |
| Background | "plain white or off-white", free of shadows, textures, or objects; even lighting, not one side lit and the other shadowed | O-s |
| Recency | Taken within the last 6 months | O-s (stated on the digital-photo page) |
| Expression | Neutral expression, both eyes open and visible, mouth closed | O-s |
| Glasses | Not allowed (policy since 2016). Rare medical exception with a signed medical statement | O-s: [Eyeglasses policy](https://travel.state.gov/content/dam/visas/policy_updates/16-STATE-106142.pdf) |
| Head coverings | ? in these results; to confirm (religious and medical exceptions are expected) | ? |
| Who takes it | No professional needed; a friend or family member may take it. Selfies are not forbidden but are discouraged | O-s: [Photo FAQ](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/frequently-asked-questions.html) |
| Printing | Matte or glossy photo-quality paper; sharp, not grainy ("use a higher quality printer ink, paper, or print setting"); no photocopies, scans, or photos of photos | O-s. **Home printing is acceptable** if the quality holds |
| Babies and children | No other person in the photo, not even a parent's hands or arms. Lay the baby on a plain white or off-white sheet, or cover a car seat with one. A baby's eyes may be not entirely open; all other children must have their eyes open | O-s: [Passport Photos](https://travel.state.gov/en/passports/apply/help/photos.html), [Photo FAQ](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/frequently-asked-questions.html) |
| Regulation | 22 CFR 51.26: photographs "as prescribed by the Department" that are a good likeness. Specifications live in the Department's instructions, not the regulation | [22 CFR 51.26](https://www.law.cornell.edu/cfr/text/22/51.26) |

## 3. US passport — online renewal digital preset

| Rule | Value | Evidence |
|---|---|---|
| Format | JPG, JPEG, PNG, HEIC, or HEIF | O-s: [Uploading a Digital Photo](https://travel.state.gov/content/travel/en/passports/how-apply/online-renewal-photo.html) |
| File size | 54 KB to 10 MB | O-s |
| Colour, recency | Colour; within the last 6 months | O-s |
| Pixel size | ? not stated | — |
| Not allowed | Photos of printed photos, scans, filters or any changes | O-s |
| Cropping | The application lets the person reposition and crop | O-s |
| Portal | Only opr.travel.state.gov; the separate Photo Tool is not for renewal | O-s |

**Proposed Calipic preset (to validate with a beta tester who renews online):**

- square JPEG, 1200 × 1200 px;
- composed with the visa template geometry (head 50–69 %, eyes 56–69 % from the bottom), so the portal's cropper has room;
- size checked to stay between 54 KB and 10 MB.

## 4. US visa (`us.visa`)

| Rule | Value | Evidence |
|---|---|---|
| Digital image | **Square**, minimum 600 × 600, maximum 1200 × 1200 px | O-s: [Composition Template](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/photo-composition-template.html) |
| Head height | 50–69 % of the image height (top of hair to bottom of chin) | O-s |
| Eye height | 56–69 % of the image height, from the bottom | O-s: Composition Template |
| Format and file size | JPEG, ≤ 240 KB (stated in the Diversity Visa instructions). The Photo Tool page says crop to exactly 600 × 600 | O-s: [DV-2026 instructions](https://travel.state.gov/content/dam/visas/Diversity-Visa/DV-Instructions-Translations/DV-2026-Instructions-Translations/DV%202026%20Plain%20Language%20Instructions%20and%20FAQs.pdf) |
| Glasses | Not allowed, except rare medical cases | O-s |
| Background, expression, alteration | As for the passport | O-s: [Photo Requirements](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos.html) |
| Printed photo | 2 × 2 in when a post asks for one at the interview | O-s (FAQ); varies by post |
| Infants | No supporting hands or arms in the frame | O-s: Photo FAQ |

**Proposed Calipic preset:** JPEG **600 × 600 px, ≤ 240 KB**, head 50–69 %, eyes 56–69 %. This satisfies both the composition template and the stricter DV and Photo Tool wording. A 2 × 2 in print is available from the same unlocked photo.

## 5. What Calipic can check, and how firmly

| Check | Kind (ADR-007) | Notes |
|---|---|---|
| Output size, pixels, file size, format | `pass`/`fail` (deterministic) | Verified by reopening the file |
| Head height 25–35 mm or 50–69 % | `warn` until calibrated, then `pass`/`fail` | The US measures to the **top of the hair**, not the crown estimate: calibrate the hair-top estimate (A5-005) |
| Eye height 56–69 % | `warn` | Advisory for the passport, because the rule is stated only for visas |
| Background white or off-white, uniform, no shadow | `warn` | Replacement is available; setup tips still give the best result |
| Even lighting | `warn` | |
| Eyes open, mouth closed, neutral expression | `warn` / `manual_check` | Babies: eyes may be partly open → manual check, never fail |
| No glasses | `manual_check` | Vision does not detect glasses reliably enough |
| No other person, hands, or toys | `manual_check` | Always shown for children |
| Not mirrored, no Portrait mode | Enforced by the capture pipeline | |
| Photo taken within 6 months | Satisfied by capture date; shown as a manual check for imported photos | |

## 6. Consequences for other documents

*Find a good spot* recommends a white or off-white wall. That gives the best result with or without replacement.

## 7. Optional verification (not required, ADR-051)

- [ ] [Passport Photos](https://travel.state.gov/en/passports/apply/help/photos.html): size, head size, background, alteration wording, babies, head coverings
- [ ] [Uploading a Digital Photo](https://travel.state.gov/content/travel/en/passports/how-apply/online-renewal-photo.html): formats, 54 KB–10 MB, cropping, no changes
- [ ] [Visa Photo Requirements](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos.html) and [Composition Template](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/photo-composition-template.html): pixels, head and eye percentages, file size
- [ ] [Photo FAQ](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/photos/frequently-asked-questions.html): who may take the photo, babies, hair
- [ ] [Eyeglasses policy](https://travel.state.gov/content/dam/visas/policy_updates/16-STATE-106142.pdf)
- [ ] Head-covering rules (religious and medical), from the passport page
- [ ] A beta tester eligible for online renewal confirms the digital preset is accepted
