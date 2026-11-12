# 06 — Markets and documents

Where Calipic launches, which documents it supports, and what the research found. Rule data lives in [Rules/catalog/v1](../Rules/README.md); the sourced research per profile is in [profiles/](profiles/README.md).

## 1. Launch scope (ADR-047)

- **Availability:** every App Store storefront where the app can be sold, except mainland China (founder decision) and Russia (no App Store payments since April 2026).
- **Wave A, at 1.0 (15 countries, 82 % of spending power):** United States, Japan, United Kingdom, Germany, Canada, Australia, France, Italy, South Korea, Switzerland, Spain, Saudi Arabia, Mexico, Netherlands, Brazil.
- **Wave B, first updates (20 countries, takes reach to 80 % of iPhone users):** India, Indonesia, Vietnam, Thailand, Türkiye, Nigeria, Malaysia, Taiwan, Ukraine, Egypt, Pakistan, South Africa, Poland, Colombia, Morocco, Philippines, Kazakhstan, Ghana, Bangladesh, Iraq.
- **Everywhere else:** Custom size, with no country and no official rules.
- **Languages at 1.0:** English, Spanish, Portuguese (Brazil) (founder decision). To serve Wave A in its own languages, six more are needed: Japanese, German, French, Italian, Korean, and Arabic (right-to-left). Dutch is optional at first.

The ranking is reproducible: `scripts/market/rank_countries.py` (World Bank income and population, StatCounter iOS share), with the result in [market/country-ranking-2026-11.csv](market/country-ranking-2026-11.csv). It is an estimate of iPhone users × income per person, not sales data.

## 2. The finding that shapes the catalog

**Several rich countries no longer accept home-made photos for their main documents.** Calipic never offers a profile for these, and App Store text must never promise them:

| Country | Closed to home photos |
|---|---|
| Germany | Passport, ID card, residence permit (digital photos from certified photographers only, since May 2025) |
| France | Passport, ID card, online driving licence (authorized photographer or booth) |
| Canada | Passport (commercial photographer) |
| Switzerland | Passport (taken at enrolment) |
| Mexico | Passport (taken at the appointment) |
| United States | Driving licences (taken at the DMV); most USCIS filings (taken at biometrics) |

In these countries the value is in visa photos for other countries, driving licences where self-supplied, and custom sizes.

## 3. The 22 profiles in catalog v1

| Country | Profiles | Output | Notes |
|---|---|---|---|
| United States | Passport; visa | Print 2 × 2 in; digital presets | Official rule forbids software changes; editing is still offered (ADR-051) |
| United Kingdom | Passport; driving licence | Digital first; print 35 × 45 mm | Print through a shop |
| Japan | Passport; My Number card; driving licence | Print 35 × 45 mm; 24 × 30 mm | |
| Italy | Passport; electronic ID card (CIE) | Print 35 × 45 mm | |
| Spain | DNI; TIE; driving licence | Print 26 × 32 mm | DNI is the engineering reference profile |
| Netherlands | Passport; ID card; driving licence | Print 35 × 45 mm at 400 ppi | Head size depends on age (open point) |
| South Korea | Passport | Print 35 × 45 mm | Official text discourages home prints; kept by the founder |
| Schengen area | Visa | Print 35 × 45 mm | |
| Australia | Passport | Print 35–40 × 45–50 mm | Shop print only (dye-sub) |
| Germany | Driving licence | Print 35 × 45 mm | |
| Switzerland | ID card without chip (commune) | Print 35 × 45 mm | Depends on the commune |
| Saudi Arabia | Resident photo update (Absher) | Digital only | |
| Canada | Visitor visa | Print ≥ 35 × 45 mm | |

Brazil and Mexico are served by custom-size shortcuts: **3 × 4 cm** and **2.5 × 3 cm (tamaño infantil)**. Other shortcuts: 25 × 30, 30 × 40, 35 × 45 mm, 2 × 2 in.

Region defaults (which document a new user starts on) are in `catalog.json` → `regionDefaults`. A region without a default is asked once.

## 4. Rules for adding or changing a profile

1. Research the official source first and write it up in `docs/profiles/` with links and the date. Official pages found through search count as sourced (ADR-051).
2. Record what is unknown as unknown. Never copy a value from another country because the sizes match.
3. Encode it in `Rules/catalog/v1/` and run `python3 scripts/rules/validate_catalog.py Rules/catalog/v1`.
4. Rebuild the app's copy: `python3 scripts/rules/build_app_catalog.py`.
5. Add the profile's name and any new by-eye checks to the String Catalog in all three languages.
6. A profile that is not sourced in time waits for the next release. It never ships with weaker evidence.

## 5. Open points

- **Netherlands:** age-dependent head size is not modelled.
- **Australia and United Kingdom:** the print route goes through a shop; the shop instructions need a real-print round.
- **Wave B:** research not started. Start with India, Türkiye, Poland, and Taiwan (highest value per research hour), and check for each country which documents still accept home photos before writing any rule.
- **Per-territory checks before submission:** storefront-specific requirements, and wording per country that promises only documents we support there.

## 6. Method and sources

**Ranking method.** Reach = population × internet users × iOS share of mobile web traffic (World Bank; StatCounter, average of November 2025 to October 2026). Value = reach × income per person (World Bank GNI per capita, Atlas method). Cross-checked against AppMagic's 2025 top ten countries by non-game app revenue: nine of the ten are in our top eleven; Brazil is the exception and is in Wave A for that reason. Taiwan was added by hand (population about 23.4 M, internet use about 90 %, GNI per capita about USD 34,000). Countries with no App Store storefront are left out: Iran, North Korea, Syria, Cuba. Reproduce with:

```sh
python3 scripts/market/rank_countries.py --cache /tmp/calipic-market-cache --out docs/market/country-ranking-2026-11.csv
```

**Ranking sources**

- World Bank Open Data API: [population](https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&mrnev=1&per_page=400), [internet users](https://api.worldbank.org/v2/country/all/indicator/IT.NET.USER.ZS?format=json&mrnev=1&per_page=400), [GNI per capita, Atlas](https://api.worldbank.org/v2/country/all/indicator/NY.GNP.PCAP.CD?format=json&mrnev=1&per_page=400), fetched 2026-11-11.
- StatCounter Global Stats, [mobile operating system market share](https://gs.statcounter.com/os-market-share/mobile/), per country, Nov 2025 – Oct 2026, fetched 2026-11-11.
- AppMagic, [Mobile Market Landscape 2026](https://appmagic.rocks/files/view/upload/Reports/EN_MobileMarkeLandscape2026.pdf), pp. 13 and 64.
- Russia payments: [9to5Mac](https://9to5mac.com/?p=1046418), [RevenueCat](https://www.revenuecat.com/blog/growth/russia-app-store-payment-block), [Engadget](https://engadget.com/big-tech/russia-closes-loophole-to-fully-block-payments-for-apple-services-163228262.html).
- China ICP filing: [Apple Developer Forums](https://developer.apple.com/forums/thread/743661), [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/), [TechSpot](https://www.techspot.com/news/100368-new-chinese-law-forces-apple-lock-down-regional.html).

**Sources for §2 and the document scoping.** Most are consistent secondary sources (photo services and news); Canada's passport rule and the US online-renewal rule come from official pages. Each profile's own research document carries its official sources.

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
- Spain: [caib.es](https://www.caib.es/sites/civitasmanualsisuport/f/148484), [the DNI profile](profiles/spain-dni.md).
- China: [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/), [HiCom Asia](https://www.hicom-asia.com/launch-app-china-app-stores-icp-filing/), [Computing](https://www.computing.co.uk/news/4131589/apple-enforces-chinese-government-licence-requirement), [exitchina.org](https://exitchina.org/en/leaving-china/passport/).
