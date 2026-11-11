# Profile research — Japan passport and My Number card

**Status:** Draft profile research (L19-013). Needs browser confirmation (§4) before release.
**Date:** 2026-11-11
**Profiles:**

- `jp.passport`: print.
- `jp.mynumber`: print, plus a digital preset for online application.

**Evidence levels:**

| Level | Meaning |
|---|---|
| **O-s** | Official page (MOFA or J-LIS), as quoted in a search restricted to that domain |
| **?** | Not established |

## 1. Alteration

| Profile | What the official pages say | Evidence |
|---|---|---|
| My Number | "Images edited with image-editing software may not be accepted." Edits that hinder face-to-face identity checks are not allowed | O-s: [顔写真のチェックポイント](https://www.kojinbango-card.go.jp/apprec/apply/facephoto/) |
| Passport | No editing wording found in this pass | ? |

**Alteration policy (both):**

| Operation | Policy | Reason |
|---|---|---|
| Background replacement | **Off** | Disallowed or unknown |
| Tone and colour | **Off** | Disallowed or unknown |
| Rotation | **Off** | Unknown |
| Crop and scale | Allowed | Inherent to producing the size |

## 2. Passport (`jp.passport`)

| Rule | Value | Evidence |
|---|---|---|
| Size | **45 × 35 mm** (height × width), no border | O-s: [MOFA photo standard (PDF)](https://www.mofa.go.jp/mofaj/files/100171389.pdf) |
| Head | Crown to chin **34 ± 2 mm** | O-s |
| Margins | The PDF's diagram lists 4 ± 2 mm and 7 ± 2 mm, 17 ± 2 mm, and "2 or more" mm | O-s, labels not read |
| Background | No background objects; white recommended; no pattern or texture | O-s: [パスポート申請](https://www.mofa.go.jp/mofaj/toko/passport/pass_2.html) |
| Recency | Taken within 6 months before applying | O-s |
| Clothing | No turtleneck or hood covering the chin or face | O-s |
| Head-size fallback | If the crown is unclear, treat a point above the eyes, at the same distance as eyes-to-chin, as the crown | O-s. **Useful for the crown estimator (A5-005)** |
| Basis | ICAO recommendations; page updated 2025-03-03 | O-s |
| Home printing | Not stated | ? |

The diagram values are probably the top margin (4 ± 2), the bottom margin (7 ± 2), and the face centre from the side edge (17 ± 2); the browser check must confirm the labels.

## 3. My Number card (`jp.mynumber`)

| Rule | Value | Evidence |
|---|---|---|
| Print size | **4.5 × 3.5 cm** (height × width) | O-s: [記入例 (PDF)](https://www.kojinbango-card.go.jp/hpsv/wpmng/documents/kisairei.pdf) |
| Smartphone photo | **Allowed** | O-s: [FAQ](https://www.kojinbango-card.go.jp/faq_photo11/) |
| Online file | JPEG/JPG (**HEIC not accepted**), RGB; width and height **480–6000 px**; **20 KB–7 MB** | O-s: [FAQ photo size](https://www.kojinbango-card.go.jp/faq_photo2/) |
| Pose | Within 6 months, facing front, no hat, plain background without shadows, chairs, or patterns. Black-and-white is allowed | O-s |
| Head size | ? not captured in this pass | ? |

**Proposed digital preset:** JPEG, 1050 × 1350 px (35:45 at about 760 ppi), head geometry as for the passport, no alteration, 20 KB–7 MB. Never HEIC.

## 4. Before release: browser confirmation

- [ ] [MOFA photo standard PDF](https://www.mofa.go.jp/mofaj/files/100171389.pdf): read the diagram labels; glasses, head coverings, children
- [ ] MOFA passport pages: editing or retouching rule; home printing
- [ ] [J-LIS 顔写真のチェックポイント](https://www.kojinbango-card.go.jp/apprec/apply/facephoto/): head size and margins, editing wording, children
- [ ] [J-LIS FAQ](https://www.kojinbango-card.go.jp/faq_photo2/): pixels and file size
- [ ] Japanese text for the profile names: パスポート and マイナンバーカード, shown next to the English names ([25 §6](../25-wave-a-document-types.md))
