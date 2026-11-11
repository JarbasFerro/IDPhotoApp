# 24 — Launch country ranking (L19-010, part 1)

**Status:** Research result; the country list is a **proposal** for founder confirmation (decision D-8). Feeds ADR-047.
**Date:** 2026-11-11
**Question:** Which ~20 % of App Store countries give ~80 % of Calipic's market?
**Data:** [`docs/market/country-ranking-2026-11.csv`](market/country-ranking-2026-11.csv), produced by [`scripts/market/rank_countries.py`](../scripts/market/rank_countries.py).

## 1. Answer

The market is more concentrated than 80/20:

| Measure | Countries needed for 80 % | Share of ~175 App Store storefronts |
|---|---|---|
| Spending power (iPhone users × income per person) | **13** (with China and Russia) · **14** (without) | 7–8 % |
| iPhone users (reach) | **26** (with China and Russia) · **33** (without) | 15–19 % |

The proposed **20 % list is 35 countries**. Excluding China and Russia (see §4), they cover **81 % of iPhone users and 89 % of spending power** in the countries we can sell in. Adding China raises world iPhone-user coverage from 59 % to 83 %.

## 2. Method

Calipic's demand is people who need ID photos and own an iPhone. Its revenue is those people willing to pay USD 0.99 (at local price-tier equivalents). Neither quantity is published per country, so two proxies are built from public data:

1. **Reach: estimated iPhone users.**
   - *iPhone users* = population × internet users % × iOS share of mobile web traffic.
   - Population and internet users: World Bank API, most recent value, mostly 2023–2025.
   - iOS share: StatCounter Global Stats, mobile OS share by country, averaged over the 12 months November 2025 to October 2026.
2. **Value: spending power.**
   - *Value* = estimated iPhone users × GNI per capita (World Bank, Atlas method, current USD).
   - This is a proxy for ability to pay, not a revenue estimate.
3. **Cross-check:** AppMagic's [Mobile Market Landscape 2026](https://appmagic.rocks/files/view/upload/Reports/EN_MobileMarkeLandscape2026.pdf), p. 64, gives the top 10 countries by **non-game app revenue** in 2025, App Store + Google Play, China App Store only. In order: USA (about $20 B), China (about $7 B), Japan (about $4.5 B), Germany, United Kingdom, France, Brazil, South Korea, Canada, Australia (about $1–2 B each). Values were read from the chart.
   - Our value ranking contains 9 of these 10 in its own top 11.
   - The exception is Brazil: 7th in AppMagic, but 16th in our value proxy. AppMagic includes Google Play, where Brazil is strong. That is one reason Brazil is in the launch wave (§3).
4. **Universe:**
   - 178 countries with population ≥ 300,000 and complete data. Taiwan was added by hand because the World Bank does not cover it: population about 23.4 M, internet use about 90 %, GNI per capita about USD 34,000, all approximate from Taiwan's official statistics.
   - Countries without an App Store storefront are excluded: Iran, North Korea, Syria, Cuba.

## 3. Proposed list: 35 countries in two waves

Shares below are of the 172 sellable countries, excluding China and Russia.

**Wave A — at 1.0 (15 countries).** This is the 80 % spending-power set plus Brazil (launch language pt-BR, 7th in app revenue).

| # | Country | Est. iPhone users (M) | Share of spending power |
|---|---|---|---|
| 1 | United States | 191.7 | 45.6 % |
| 2 | Japan | 64.2 | 6.6 % |
| 3 | United Kingdom | 33.5 | 4.9 % |
| 4 | Germany | 28.6 | 4.6 % |
| 5 | Canada | 25.1 | 3.8 % |
| 6 | Australia | 16.4 | 2.8 % |
| 7 | France | 21.0 | 2.7 % |
| 8 | Italy | 18.3 | 2.1 % |
| 9 | South Korea | 16.2 | 1.6 % |
| 10 | Switzerland | 5.0 | 1.5 % |
| 11 | Spain | 14.0 | 1.4 % |
| 12 | Saudi Arabia | 12.2 | 1.2 % |
| 13 | Mexico | 31.9 | 1.2 % |
| 14 | Netherlands | 6.3 | 1.2 % |
| 15 | Brazil | 36.7 | 1.0 % |
| | **Wave A total** | **≈ 520** | **82 %** (50 % of iPhone users) |

**Wave B — first updates after 1.0 (20 countries).** These take reach to 80 % of iPhone users. Most of their weight is people, not spending power. They matter for downloads and the "#1" rank more than for revenue.

India (60.1 M), Indonesia (37.4), Vietnam (35.0), Thailand (20.6), Türkiye (18.8), Nigeria (14.8), Malaysia (14.3), Taiwan (11.8), Ukraine (11.7), Egypt (11.5), Pakistan (11.3), South Africa (10.8), Poland (10.5), Colombia (10.4), Morocco (8.7), Philippines (8.6), Kazakhstan (8.4), Ghana (7.2), Bangladesh (6.9), Iraq (6.7).

Waves A and B together: 35 countries, 81 % of iPhone users and 89 % of spending power (excluding China and Russia).

Every other country can still use the app at 1.0 with generic and custom sizes (ADR-047 §5).

## 4. Special cases

| Country | Rank | Situation | Proposal |
|---|---|---|---|
| **China mainland** | #1 by iPhone users (about 356 M, 25 % of the world); #2 by spending power | Apple asks for an ICP filing for new apps on the China storefront. Whether it applies to developers outside mainland China is unclear ([Apple forum](https://developer.apple.com/forums/thread/743661), [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/)). China also needs Simplified Chinese and its own photo profiles. | New decision **D-10**: run a compliance check (ICP, app filing, content rules) before deciding. Not in Wave A. |
| **Russia** | #5 by iPhone users | Apple has accepted **no App Store payments in Russia since 1 April 2026**, in-app purchases included ([9to5Mac](https://9to5mac.com/?p=1046418), [RevenueCat](https://www.revenuecat.com/blog/growth/russia-app-store-payment-block)). | Excluded from both waves: no revenue is possible. The app stays available there with the free photo. |
| **Iran, North Korea, Syria, Cuba** | — | No App Store storefront | Excluded |
| **Taiwan** | Top 10 by total app revenue in AppMagic (games included); #15 by our value proxy | Traditional Chinese needed | Wave B; first candidate to move up if research capacity allows |

## 5. What this means for languages (D-7)

Wave A, in one language each:

- English: US, UK, Canada, Australia;
- Japanese;
- German: Germany, Switzerland;
- French: France, Canada, Switzerland;
- Italian: Italy, Switzerland;
- Korean;
- Spanish: Spain, Mexico;
- Arabic: Saudi Arabia, which means right-to-left layout (AGENTS.md §15 already requires RTL compatibility);
- Dutch: Netherlands;
- Portuguese (Brazil).

So Wave A needs **6 languages beyond en, es and pt-BR**: ja, de, fr, it, ko, ar. Dutch is optional at first, because English is widely read in the Netherlands. Wave B adds hi, id, vi, th, tr, ms, zh-Hant, uk, pl and others.

## 6. Caveats

- These are proxies. StatCounter counts page views, not devices. Internet use is not smartphone ownership. GNI per capita is not willingness to pay for an app. The ranking is robust at the top; positions 25–40 are close and could swap with other data.
- ID-photo demand per person differs by country: how often documents are renewed, whether people supply their own photo, and whether the office takes it. That is the subject of part 2 (§7) and may move countries between waves.
- Apple's local price equalization makes USD 0.99 cheaper in lower-income countries, so the value proxy understates them somewhat.
- AppMagic chart values are read from a chart image and approximate. Third-party firms disagree on country revenue totals.

## 7. Next step (L19-010, part 2)

For each Wave A country, list the documents for which people supply their own photo:

- passport, national ID, residence permit, driving licence;
- for each, whether a photo shop, a booth, or a home print is accepted;
- for each, whether a digital upload exists.

Add the most-requested visa photos (US visa, Schengen visa). The output is the Wave A profile list and its research order for L19-013.

## 8. Reproduce

```sh
python3 scripts/market/rank_countries.py --cache /tmp/calipic-market-cache --out docs/market/country-ranking-2026-11.csv
```

Responses are cached, so a rerun with the same cache gives identical output. A rerun with a new cache picks up the latest World Bank and StatCounter data. Change `FROM`/`TO` in the script to move the StatCounter window.

## Sources

- World Bank Open Data API: [population](https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&mrnev=1&per_page=400), [internet users](https://api.worldbank.org/v2/country/all/indicator/IT.NET.USER.ZS?format=json&mrnev=1&per_page=400), [GNI per capita, Atlas](https://api.worldbank.org/v2/country/all/indicator/NY.GNP.PCAP.CD?format=json&mrnev=1&per_page=400), fetched 2026-11-11.
- StatCounter Global Stats, [mobile operating system market share](https://gs.statcounter.com/os-market-share/mobile/), per country, Nov 2025 – Oct 2026, fetched 2026-11-11.
- AppMagic, [Mobile Market Landscape 2026](https://appmagic.rocks/files/view/upload/Reports/EN_MobileMarkeLandscape2026.pdf), pp. 13 and 64.
- Russia payments: [9to5Mac](https://9to5mac.com/?p=1046418), [RevenueCat](https://www.revenuecat.com/blog/growth/russia-app-store-payment-block), [Engadget](https://engadget.com/big-tech/russia-closes-loophole-to-fully-block-payments-for-apple-services-163228262.html).
- China ICP filing: [Apple Developer Forums](https://developer.apple.com/forums/thread/743661), [AppInChina](https://appinchina.co/blog/how-can-i-publish-on-the-apple-app-store-china/), [TechSpot](https://www.techspot.com/news/100368-new-chinese-law-forces-apple-lock-down-regional.html).
