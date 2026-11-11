# Profile research — Wave A second group (verification list)

**Status:** Researched (L19-013); search-based official evidence accepted (ADR-051). Result: **7 profiles + 2 custom-size shortcuts**, confirmed by the founder on 2026-11-11.
**Date:** 2026-11-11
**Input:** the "verify, then research" list in [25 §3](../25-wave-a-document-types.md).

## 1. Summary

| Item | Result | Proposed |
|---|---|---|
| Australia · passport | Print only; **dye-sublimation, not inkjet**, glossy ≥ 200 gsm, "professionally printed photos only" | Profile, **shop print only** (dye-sub kiosk) |
| UK · driving licence | Online renewal reuses the passport photo or a digital upload; by post, 45 × 35 mm print, light grey or cream, within one month; home prints unlikely to be accepted | Profile, digital + **shop print** |
| Japan · driving licence | 3.0 × 2.4 cm (height × width), photo paper only | Profile, print |
| Germany · driving licence | Still a **printed** 35 × 45 mm biometric photo. The May 2025 digital-only rule does not apply; Data-Matrix (ID-card) photos are refused | Profile, print. **Germany's first profile** |
| Switzerland · ID card without chip (commune) | Paper photo per the fedpol photo criteria; whether you may bring your own photo depends on the canton or commune | Profile, print, with a Help note |
| Saudi Arabia · resident photo update (Absher) | Digital upload, fully white background, men bareheaded, AI-checked; national-ID spec ≤ 1 MB, 2:3, within 6 months, no glasses | Profile, **digital only** |
| Canada · visitor visa (TRV) | Printed, at least 35 × 45 mm, head 31–36 mm, quality photo paper | Profile, print |
| Brazil · 3 × 4 | The CIN photo is taken at the service desk in most states; a 3 × 4 is asked only for small children or sick people. Many other uses: exams, schools, consulates | **Custom-size shortcut "3 × 4 cm"**, not an official profile |
| Mexico | US visas from Mexico use the DS-160 upload (covered by `us.visa`). "Tamaño infantil" 2.5 × 3 cm is used by many procedures, some in **black and white** | **Custom-size shortcut "2.5 × 3 cm (tamaño infantil)"** plus a **black-and-white** option for custom sizes |

With these, Wave A has **20 profiles**, and Germany gets one.

## 2. Details

### Australia · passport (`au.passport`)

| Rule | Value | Evidence |
|---|---|---|
| Size | 35–40 mm wide × 45–50 mm high | [passports.gov.au — Passport photos](https://www.passports.gov.au/help/passport-photos) |
| Head | 32–36 mm, chin to crown | same |
| Print | Dye-sublimation (not inkjet), heavy glossy paper ≥ 200 gsm; "professionally printed photos only" | same; [Camera operator guidelines 2026](https://www.passports.gov.au/sites/default/files/documents/2026-06/Camera%20operator%20guidelines_0.pdf) |
| Copies and recency | Two photos, less than 6 months old | same |
| Editing (reference) | Filters and retouching can cause problems | same |

**Calipic:**

- **Print at a shop** only, with the lab JPEG and an instruction to use a dye-sublimation kiosk;
- the home-print path is hidden, with one line explaining why;
- the target size is 35 × 45 mm, inside the allowed range.

### UK · driving licence (`gb.driving-licence`)

| Rule | Value | Evidence |
|---|---|---|
| Online renewal | Digital photo, or the photo from a valid UK passport | [GOV.UK — Change the photo on your driving licence](https://www.gov.uk/renew-photo-driving-licence), [DVLA blog](https://dvladigital.blog.gov.uk/2022/12/13/how-to-renew-your-driving-licence-online/) |
| Post (D1) | Recent printed passport-type photo, 45 × 35 mm, colour, light grey or cream, within one month; do not trim; home prints unlikely to be accepted | [nidirect — The photo for your driving licence](https://www.nidirect.gov.uk/articles/photo-your-driving-licence) (Northern Ireland's rules; Great Britain's equivalent assumed) |

**Calipic:** same geometry and digital preset as [UK passport](uk-passport.md); print through a shop.

### Japan · driving licence (`jp.driving-licence`)

| Rule | Value | Evidence |
|---|---|---|
| Size | **3.0 × 2.4 cm** (height × width) | [NPA](https://www.npa.go.jp/policies/application/license_renewal/japan.html), [Tokyo Metropolitan Police](https://www.keishicho.metro.tokyo.lg.jp/menkyo/koshin/koshin/koshin02_2.html) |
| Pose | Within 6 months, no hat, frontal, plain background, chest up | same |
| Print | Photo paper only ("photos printed on anything other than photo paper are not accepted"); name, and per the NPA the date taken, written on the back | same |
| Note | In Tokyo, a brought photo becomes the licence photo only at the Fuchū, Samezu, and Kōtō centres | Tokyo Metropolitan Police |

### Germany · driving licence (`de.driving-licence`)

| Rule | Value | Evidence |
|---|---|---|
| Format | Printed biometric photo, **35 × 45 mm**; the digital-only rule for passports and ID cards does not apply | [Märkisch-Oderland press release 23/2025](https://www.maerkisch-oderland.de/service-aktuelles/aktuelles/pressemitteilungen/pressemitteilung-23-2025), [Landkreis Uckermark](https://www.uckermark.de/Service-Aktuelles/Aktuelle-Informationen/Fahrerlaubnisbeh%C3%B6rde-Lichtbild-f%C3%BCr-den-F%C3%BChrerschein-weiterhin-auf-Papier-ausgedruckt-n%C3%B6tig.php?object=tx%2C3615.5.1&ModID=7&FID=3615.10394.1&NavID=3615.12&La=1&kat=3615.3&sfkat=1&sfmonat=1&sfjahr=1), [Kreis Tübingen](https://www.kreis-tuebingen.de/bauen_verkehr/verkehr/feb/lichtbild+fuer+den+fuehrerschein) |
| Not accepted | Photos with a Data-Matrix code (made for ID cards) | Tübingen, Uckermark |
| Biometric geometry | Same biometric standard as the German passport photo (ICAO) | |
| Variation | Some offices also accept an online upload; check locally | district pages |

### Switzerland · ID card without chip (`ch.id-card`)

| Rule | Value | Evidence |
|---|---|---|
| Photo | Paper photo meeting the fedpol photo criteria; some communes accept digital photos or take the photo | [fedpol — Beantragen](https://www.fedpol.admin.ch/de/beantragen), [fedpol photo criteria (PDF)](https://www.fedpol.admin.ch/dam/de/sd-web/ZA--3ny9zRWt/fotomustertafel.pdf) |
| Own photo | Allowed in some cantons under strict conditions | [ch.ch](https://www.ch.ch/de/reisen-und-auswandern/ins-ausland-reisen/pass-und-identitatskarte/pass-und-identitatskarte-bestellen/) |
| Size | 35 × 45 mm (as the passport photo standard); confirm in the fedpol PDF | [EDA](https://www.eda.admin.ch/countries/usa/en/home/services/identity-documents.html) |
| Note | The biometric ID card (from 2 November 2026) is captured like the passport, so it is not a Calipic profile | fedpol |

**Calipic:** Help says "Ask your commune whether you may bring your own photo."

### Saudi Arabia · resident photo update via Absher (`sa.resident-photo`)

| Rule | Value | Evidence |
|---|---|---|
| Channel | Absher app or portal, "Update Resident Photo"; AI-checked; biometric check through Nafath | [Ajel English](https://english.ajel.sa/news/oh5i5jjk6), [Ajel English](https://english.ajel.sa/news/v0mkcn268) |
| Rules | Proper lighting and dimensions; **completely white** background; men bareheaded; nothing added on the face | same |
| File (national-ID spec, assumed to apply) | ≤ 1 MB, 2:3 ratio, within 6 months, no glasses, not modified by computer programs | [Absher](https://www.absher.sa/wps/portal/individuals/static/NewServices/!ut/p/z0/04_Sj9CPykssy0xPLMnMz0vMAfIjo8ziDQ1dLDyM3A18_F093QwCzYOCDX383Q3dTcz0g1Pz9AuyHRUBY0dtkA!!/) |

**Calipic:** digital preset JPEG **800 × 1200 px (2:3)**, ≤ 1 MB, white replacement colour. No print.

### Canada · visitor visa (`ca.visitor-visa`)

| Rule | Value | Evidence |
|---|---|---|
| Size | Frame at least **35 × 45 mm** | [IRCC — TRV photo specifications](https://www.canada.ca/en/immigration-refugees-citizenship/services/application/application-forms-guides/temporary-resident-visa-application-photograph-specifications.html) |
| Head | **31–36 mm**, chin to crown | same |
| Print | Quality photographic paper; digital photos must not be altered | same |
| Photographer details | Required for permanent residents and passports; not found for the visitor visa | [PR photo specifications](https://www.canada.ca/content/dam/ircc/migration/ircc/english/information/applications/guides/pdf/5445eb-e.pdf) |

### Brazil and Mexico → custom-size shortcuts

| Shortcut | Why | Evidence |
|---|---|---|
| **3 × 4 cm** | CIN photos are usually taken at the desk (a 3 × 4 is asked only for small children or sick people in MG, BA, ES). 3 × 4 remains the everyday size for exams, schools, and Brazilian consulates abroad | [MG](https://ouvidoriageral.mg.gov.br/lista-de-documentos-carteira-de-identidade-nacional-cin), [BA](https://servicos.ba.gov.br/detalhe/servico/2158), [ES](https://facafacil.es.gov.br/Servicos/Detalhes/3178?IdUnidade=2), [MRE consular passport](https://www.gov.br/mre/pt-br/embaixada-malabo/servicos-consulares/passaporte/passaportes-1) |
| **2.5 × 3 cm (tamaño infantil)** | Used by many Mexican procedures, for example the INM exit and return permit (colour, white background, ears visible, no glasses, no instant photos) and the SECTEI certificate (three copies, **black and white**, matte) | [INM](https://www.inm.gob.mx/static/tramites/Estancia/Permisos_y_Certificaciones/PermisoSalidaRegreso.pdf), [SECTEI](https://ead.cdmx.gob.mx/tramitecer/tramcert2025.pdf) |
| US visa from Mexico | The DS-160 upload is required; if it fails, bring a print. Covered by `us.visa` | [DS-160 FAQ](https://travel.state.gov/content/travel/en/us-visas/visa-information-resources/forms/ds-160-online-nonimmigrant-visa-application/ds-160-faqs.html), [US Embassy Mexico (E-1)](https://mx.usembassy.gov/e-1-treaty-investor-visas/) |

**New custom-size option:** **Black and white** (ADR-018), needed by procedures such as SECTEI.
