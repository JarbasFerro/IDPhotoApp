# 25 — Wave A document types and the China check (L19-010, part 2)

**Status:** Research result for scoping. Every profile still needs its own sourced research document before release (L19-013, [01 §15](01-product-definition.md)).
**Date:** 2026-11-11
**Builds on:** [24 — Launch country ranking](24-launch-country-ranking.md); founder confirmed the 35-country list on 2026-11-11.

**Evidence levels:**

| Level | Meaning |
|---|---|
| **O** | An official government page was found and summarized |
| **S** | Consistent secondary sources only (photo services, news) |
| **?** | Unclear or conflicting; verify first |

## 1. The finding that changes the plan

**Several of the richest Wave A countries no longer accept home-made photos for their main documents.** They require a certified photographer or booth, or the office takes the photo itself:

| Country | Documents closed to home photos | Why | Level |
|---|---|---|---|
| Germany | Passport, ID card, residence permit | Since May 2025, photos reach the office only digitally, from certified photographers or the office's own terminal; paper and home photos are refused | S (consistent; The Local and others) |
| France | Passport, ID card | Photo by an authorized professional or approved booth | S |
| France | Driving licence (online) | Needs an ANTS e-photo code, which only certified booths and services can issue | S |
| Canada | Passport | Taken in person by a commercial photographer, both for paper and online renewal | **O** (Canada.ca) |
| Switzerland | Passport | Photo taken at the biometric enrolment | S |
| Mexico | Passport | SRE takes the photo at the appointment | S (press, consistent) |
| United States | Driving licences | Taken at the DMV (general knowledge; state by state) | ? |
| United States | Most USCIS filings | Photo taken at the biometrics appointment since policy alert PA-2025-29 (Dec 2025); some form instructions still list mailed photos | S, conflicting |

**What this means:**

- Calipic must never present a profile for these documents. A profile we cannot honestly support damages trust (AGENTS.md §11, constitution).
- In these countries, value comes from **visa photos for other countries** and **secondary documents**: driving licences where self-supplied, ID cards in some places, residence permits, applications abroad.
- App Store messaging per country must say only what is true there. For example: never "German passport photos".

## 2. Where at-home photos are accepted (Wave A)

| Country | Document | Size | Output | At home? | Level | Notes |
|---|---|---|---|---|---|---|
| United States | Passport (mail or in person) | 2 × 2 in (51 × 51 mm) | Print | Yes | S | Large volume |
| United States | Passport online renewal | Digital upload: JPG/PNG/HEIC/HEIF, 54 KB–10 MB, color, < 6 months; no scans of prints | Digital | Yes (not excluded) | **O** (travel.state.gov) | **No filters, apps, or AI changes** → background replacement and tone **not allowed**; framing only ([profile](profiles/us-passport-and-visa.md)) |
| United States | US visa (DS-160) | Square JPEG 600–1200 px, ≤ 240 KB; some posts also want a 2 × 2 in print | Digital + print | Generally yes; the consulate decides | S | Cross-border: applicants in every country |
| United Kingdom | Passport (online) | Digital, at least 600 × 750 px; the service crops | Digital | **Yes, explicitly**: taken on your own device with someone's help | S (citing GOV.UK) | Plain light background (cream or light grey best); **unaltered**; within 1 month ([profile](profiles/uk-passport.md)) |
| United Kingdom | Passport (paper) and driving licence (paper) | 35 × 45 mm | Print | Yes | S | |
| Japan | Passport | 35 × 45 mm | Print (digital only in pilots) | Yes | S | MOFA updated rules in March 2025 |
| Japan | My Number card | 35 × 45 mm, or smartphone upload via the portal | Print + digital | Yes | S | |
| Japan | Driving licence | 24 × 30 mm | ? | ? | ? | Often taken at the centre; verify |
| Italy | Passport, electronic ID card (CIE) | 35 × 45 mm | Print (digital in some cities) | Likely (photo-quality paper) | S | |
| Spain | DNI | 26 × 32 mm (32 × 26 written height × width) | Print | Yes | **O** ([13](13-spain-foto-carnet.md)) | Reference profile |
| Spain | TIE (foreigners' card), driving licence | 26 × 32 mm | Print | Likely | S | Passport size to verify (sources disagree) |
| Netherlands | Passport, ID card, driving licence | 35 × 45 mm, smooth photo paper | Print | **Yes**: no rule forbids self-made photos | S (consistent) | |
| South Korea | Passport | 35 × 45 mm; online renewal upload via Government 24 | Print + digital | Likely | S | One source says no compositing or AI → alteration policy (§4); no glasses |
| Australia | Passport | 35–40 × 45–50 mm, head 32–36 mm, two prints | Print only, no upload | ? | S, conflicting | Several sources say inkjet is not accepted. If true, home inkjet is out, but **Print at a shop** (L19-005) fits. Verify with DFAT first |
| Saudi Arabia | Resident ID (iqama) photo update via Absher | White background, AI-checked upload; size disputed | Digital | Yes (upload) | S (Saudi press) | Passport and citizen ID unknown |
| Switzerland | ID card (when applied for alone at the commune) | 35 × 45 mm | Print or digital, by commune | Varies | S | |
| Germany | Driving licence; visas for other countries | 35 × 45 mm | Print | ? | ? | Verify whether driving-licence offices still take paper |
| Canada | Visitor visa and other immigration (IRCC) | 35 × 45 mm | Digital | ? | ? | Passport closed (§1); verify IRCC rules |
| Mexico | US visa from Mexico; "tamaño infantil" for paperwork | 2 × 2 in / 25 × 30 mm | Digital / print | ? | ? | The main Mexican demand may be US visas; check whether US posts in Mexico photograph applicants on site |
| Brazil | Foto 3 × 4 (CIN in some states, CNH in São Paulo and some states, professional bodies, exams) | 30 × 40 mm | Print | Yes where accepted | S | Most Detran offices capture the photo digitally; passport photo likely taken at the Federal Police (verify) |
| Schengen area | Schengen visa (any Wave A resident who needs one) | 35 × 45 mm | Print | Likely | ? | Rules from the EU visa code and each consulate; verify |

## 3. Proposed Wave A profile list and research order

Ordered by spending power ([24](24-launch-country-ranking.md)) × at-home acceptance × evidence level.

**Research first (P1, 13 profiles):**

1. US passport: print 2 × 2 in, plus the online-renewal digital preset.
2. US visa: DS-160 digital preset plus 2 × 2 in print.
3. UK passport: digital preset plus 35 × 45 mm print.
4. Japan passport.
5. Japan My Number card.
6. Italy passport and CIE (two profiles with shared rules if the sources match).
7. Spain DNI (done), TIE, and driving licence.
8. Netherlands passport, ID card, and driving licence.
9. South Korea passport (print plus Government 24 preset).
10. Schengen visa.

**Verify, then research (P2):**

- Australia passport (inkjet question);
- UK driving licence;
- Japan driving licence;
- Germany driving licence;
- Switzerland ID card;
- Saudi resident photo (Absher preset);
- Brazil 3 × 4 (CIN and CNH where accepted);
- Canada visitor visa;
- Mexico: US visa practice and tamaño infantil.

**Excluded (closed to home photos, §1):** Germany passport, ID, and residence permit; France passport, ID, and e-photo documents; Canada passport; Switzerland passport; Mexico passport; US driving licences; USCIS filings photographed at biometrics.

Wave A then has about 13 profiles for launch, plus up to 9 more after verification. This is a realistic research load for P3. **Approved by the founder on 2026-11-11 (D-11).** Every other need is served by the custom size without a country (ADR-018).

## 4. Consequences for the product

1. **Alteration policy is decisive in the biggest market.** The US State Department says online-renewal photos must not be changed with software, apps, filters, or AI. One source says Korea forbids background compositing. The UK requires light grey or cream, not white. For these profiles:
   - automatic **background replacement and Document Tone may be off by default**, per profile (ADR-037, F-07);
   - the result then depends on capture quality: helper mode, *Find a good spot*, and a plain light wall (F-15, F-16).
   - The W3 "background fades to white" moment cannot be the universal wow. For unaltered profiles it becomes "it framed me perfectly". The profile research must answer the alteration question first.
2. **Digital output is as important as print.** Online channels exist in the UK, the US, Japan, Korea, and Saudi Arabia. Per-profile digital presets (F-41) become P0 for those profiles.
3. **Print at a shop** (L19-005) matters more. Australia may not accept inkjet; elsewhere, booths and shops are the fallback when home printing is not allowed.
4. **Cross-border visa profiles** (US visa, Schengen visa) are high value: they serve people in every country, including those whose national documents are closed.
5. **Honest country messaging:** App Store screenshots and keywords per country list only the supported documents. Never "German passport", "French ID card", or "Canadian passport".

## 5. China check (D-10)

| Question | Finding | Level |
|---|---|---|
| Can a foreign developer sell a paid app on the China storefront? | Apple requires an ICP filing number for apps offered in mainland China. A foreign company without a Chinese entity generally cannot obtain one in its own name; the usual route is a local partner. Commercial activity, such as paid apps and in-app purchases, may need an **ICP commercial licence**, which has stricter capital, staffing, and ownership conditions. Without a valid number the app is not offered in mainland China. | S (consistent across [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/), [HiCom Asia](https://www.hicom-asia.com/launch-app-china-app-stores-icp-filing/), [Computing](https://www.computing.co.uk/news/4131589/apple-enforces-chinese-government-licence-requirement)); not confirmed with MIIT or legal counsel |
| Is demand for at-home ID photos there like ours? | Chinese passport photos (33 × 48 mm) are commonly taken at the exit-entry hall when applying in person; online renewal in about 50 pilot cities accepts an uploaded photo. Everyday ID-photo needs (1-inch and 2-inch photos for exams and job applications) are served by WeChat mini-programs and local shops. | S / ? |
| Product fit | Needs Simplified Chinese, Chinese profiles, a different App Store strategy, and a Chinese partner for compliance. | — |

**Decision (founder, 2026-11-11):** mainland China is excluded. Do not offer Calipic on the mainland China storefront at 1.0 or in Wave B. Untick mainland China in App Store Connect availability (P9). Hong Kong, Macao, and Taiwan are separate storefronts and are not affected (Taiwan is in Wave B). Revisit only if a Chinese publishing partner appears and the commercial licence question is answered by counsel.

## 6. Languages (D-7, decided 2026-11-11)

No new languages are added for Wave A. 1.0 ships in **English, Spanish, and Portuguese (Brazil)** (D-12, founder 2026-11-11). Consequences for the other Wave A countries:

- Requirement and profile text for Japan, Korea, Italy, the Netherlands, and Saudi Arabia appears in English. Profile names may keep their official local name next to the English one (for example "My Number card (マイナンバーカード)"), so people recognize their document.
- App Store metadata can still be localized per storefront later at low cost (title, subtitle, keywords, screenshots text). That is ASO work, not app localization (P9 decision).

## Sources

- US: [travel.state.gov — Uploading a digital photo](https://travel.state.gov/content/travel/en/passports/how-apply/online-renewal-photo.html); DS-160 specs summarized from [compliantphoto.com](https://compliantphoto.com/us-visa) and [getstudioless.com](https://getstudioless.com/guides/ds-160-visa-photo); USCIS biometrics photos from [immiva.com](https://immiva.com/blog/uscis-passport-photo-requirements-2026) and [pixid.studio](https://www.pixid.studio/guide/uscis-photo).
- UK: [smartphone-id.com](https://www.smartphone-id.com/en-gb/passport-photo-myself), [pixpassport.com](https://www.pixpassport.com/blog/uk-digital-passport-photo) (both citing GOV.UK and HM Passport Office).
- Germany: [The Local](https://www.thelocal.de/20241111/explained-the-changes-to-german-passport-and-id-card-photos-in-2025), [photogov.net](https://photogov.net/knowledge/requirements/german-passport/).
- France: [quickprint.fr](https://quickprint.fr/impression-technologie/ou-faire-photo-identite), [passportphotosnap.com — e-photo](https://www.passportphotosnap.com/fr/blog/numero-ephoto).
- Canada: [Canada.ca — Renew a passport online](https://www.canada.ca/en/immigration-refugees-citizenship/services/canadian-passports/renew-adult-passport/submit-form-fees/renew-online.html).
- Australia: [photogov.net](https://photogov.net/knowledge/requirements/australian-passport-photo/), [smartphone-id.com](https://www.smartphone-id.com/en-au/print-passport-photos-in-australia), [visafoto.com](https://visafoto.com/australia/passport-photo-printing).
- Italy: [idphotosnap.com](https://idphotosnap.com/blog/italian-passport-photo-requirements-2026), [passlens.com](https://passlens.com/blog/italy-passport-photo-guide).
- Japan: [pixid.studio](https://www.pixid.studio/guide/japan), [id-photo.ai — My Number](https://www.id-photo.ai/en-JP/documents/jp-my-number), [sakutto.ai](https://sakutto.ai/en/articles/id-photo-size-guide).
- South Korea: [passlens.com](https://passlens.com/blog/south-korea-passport-photo-guide), [snapassport.com](https://snapassport.com/guide/south-korea-passport).
- Switzerland: [EDA — Passport and identity card](https://www.eda.admin.ch/countries/usa/en/home/services/identity-documents.html).
- Netherlands: [BNNVARA Kassa](https://www.bnnvara.nl/kassa/artikelen/mag-je-zelf-pasfotos-maken-voor-een-rijbewijs-paspoort-of-id-kaart), [thuispasfoto.nl](https://thuispasfoto.nl/blog/pasfoto-eisen).
- Mexico: [Vanguardia](https://vanguardia.com.mx/informacion/aun-se-llevan-fotos-para-el-pasaporte-sre-aclara-si-tienes-que-llevarlas-a-tu-cita-HK22825121), [Wise](https://wise.com/mx/blog/requisitos-pasaporte-mexicano).
- Brazil: [foto3x4.com](https://foto3x4.com/blogs/guia-definitivo-da-foto-para-documentos-no-brasil-2024-2026-como-tirar-a-foto-3x4-perfeita-em-casa-e-evitar-rejeicoes), [passportphotosnap.com — CNH](https://www.passportphotosnap.com/pt-br/foto-cnh).
- Saudi Arabia: [Ajel English](https://english.ajel.sa/news/oh5i5jjk6), [Indian in Saudi Arabia](https://indianinsaudiarabia.com/posts/update-iqama-photo-online-absher/).
- Spain: [caib.es](https://www.caib.es/sites/civitasmanualsisuport/f/148484), [13 — Spain foto carnet](13-spain-foto-carnet.md).
- China: [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/), [HiCom Asia](https://www.hicom-asia.com/launch-app-china-app-stores-icp-filing/), [Computing](https://www.computing.co.uk/news/4131589/apple-enforces-chinese-government-licence-requirement), [exitchina.org](https://exitchina.org/en/leaving-china/passport/).
