# 23 — Launch roadmap: from spike 0.12.7 to App Store 1.0

**Status:** Active. Replaces the stale "immediate next step" sections in [06 §16](06-delivery-plan.md) and [12](12-implementation-kickoff.md).
**Date:** 2026-11-11 (updated the same day with the founder decisions in ADR-047 to ADR-050)
**Milestones:** keeps M0–M8 from [06](06-delivery-plan.md); this document says where we are and what comes next. Function and screen IDs refer to [20](20-product-blueprint.md).

## 1. Where we are (2026-11-11)

| Area | State |
|---|---|
| App | `Spikes/IDPhotoSpike` 0.12.7. The complete Spain DNI flow works end to end on an iPhone: guided camera with review, import, automatic alignment, white background, Document Tone, Photo Check, Adjust, digital JPEG, multi-person print sheets with AirPrint, English/Spanish/Portuguese (Brazil), and the app icon picker. |
| Milestone | Late **M1** (feasibility). The UX work of M5 has been explored early inside the spike (docs 15–17). **M2 has not started**: there is no production project. |
| Evidence missing for M1 exit | Physical print measurements; directional camera calibration on both cameras; on-device Vision and segmentation benchmarks across skin tones and hair types; performance, memory, and thermal baselines on an older iPhone; iOS 27 runtime checks; ADR-024 (minimum iOS). |
| Decisions taken (2026-11-11) | Worldwide launch with a tiered profile catalog (ADR-047); first photo free, then USD 0.99 per photo with an unlock confirmation (ADR-048); drafts with a locked export gate (ADR-049); accessibility reduced to a native baseline (ADR-050); children use the adult flow (ADR-017); measurement with known beta testers (ADR-020). |
| Decisions | All product decisions taken on 2026-11-11 ([20 §8](20-product-blueprint.md)): 35 countries in two waves, mainland China excluded, the first 13 profiles, English, Spanish, and Portuguese (Brazil), custom size without a country, capture protection. |
| Not built for launch | Versioned rule catalog and profile picker; Tier 1 profiles; profile background colours; digital presets; StoreKit credits and unlock confirmation; drafts and export gate; Settings & About; Help; Print check; Cutting guide; helper mode; setup coaching; edge refinement; App Intents; App Store assets. |

## 2. Phases to launch

Phases run mostly in order; work marked ∥ can run in parallel. Each phase ends with a gate. A version is tagged and handed to the device at the end of each phase (AGENTS.md §17).

| Phase | Milestone | Goal | Main work (backlog IDs) | Exit gate | Version |
|---|---|---|---|---|---|
| **P0 — Decide** | M0 close | Lock the remaining scope decisions | L19-010 part 1 done ([24](24-launch-country-ranking.md)); part 2 documents per Wave A country; D-7 languages; D-8 confirmation; D-10 China check; accept the targets in [20 §7](20-product-blueprint.md) | D-7, D-8, D-10 recorded in doc 10; Wave A document list confirmed | docs only |
| **P1 — Prove on device** | M1 exit | Close the physical evidence gaps | S1-014 performance baseline on an older iPhone; S1-015 ADR-024; P12-005 printer round on ≥ 3 printers (inkjet, laser, photo printer) × 2 papers, with tolerances written down **before** measuring (bar 50 ± 0.5 mm with a ruler; tile sizes with calipers); camera direction calibration on both cameras (ADR-044); S1-017/S1-018 fixture benchmarks with a consented, diverse set; decide eye-line and scrim prototypes (ADR-045) | M1 exit checklist in 06 §4 complete; S1-016 ADRs locked | 0.13 |
| **P2 — Production foundation** | M2 | Promote the spike into the production project | F2-001–F2-011: one project, Swift 6, module boundaries as folders, typed errors, privacy-safe logging and signposts, CI, privacy manifest; promote Domain/Imaging/Camera code by review, not copy; keep all tests green; give accepted new functions FR IDs in [02](02-requirements.md) | Production app reaches spike parity on device; CI green | 0.20 |
| **P3 — Rules and profiles** (critical path) | M4 | Profiles become data; the Tier 1 catalog exists | R7-001–R7-018: schema, validators, loader, provenance, evaluators, alteration policy, **background colour per profile** (ADR-037), digital presets; U10-002 profile picker (S-02) with the **Custom size** entry (L19-018); custom size if D-8 says so (ADR-018); L19-013 research and validation of every Tier 1 profile; localization of profile text per D-7 | Every Tier 1 profile passes the [01 §15](01-product-definition.md) release gate (those that do not move to Tier 2); no literal rule text left in UI code | 0.30 |
| **P4 — Quality** ∥ P3 | M3 | Reach the photo-quality bar | Calibrate checks (A5-005, A5-006, A5-007); shadow and glare advisories L19-014, L19-015; edge refinement B6-005/B6-006 (S-11); segmentation fixtures B6-007; helper mode L19-001; *Find a good spot* L19-002; consented portrait fixtures; quality study L19-007, first round | [22 §2.2](22-quality-and-delight-bar.md) targets met on the fixture set; first study round run | 0.40 |
| **P5 — Complete the experience** | M5–M6 | Every launch screen, journey, and moment | New screen contracts in doc 16 for S-02, S-04 additions, S-11, S-16–S-20 and Continue on Home; build them; **drafts and export gate L19-012**; capture protection L19-017 (device spike early, in P1); Print check L19-003; Cutting guide L19-004; Print at a shop L19-005; Home visual L19-008; aesthetic gaps in [22 §3.3](22-quality-and-delight-bar.md); U10-014 complete state pass; TipKit tips; App Intents AI13-001–AI13-005 (through the export gate) | Journeys J1–J7 pass their acceptance in [21 §5](21-user-journeys.md) with first-time testers; export-gate test green | 0.50 |
| **P6 — Pricing** ∥ P5 | M5 | Credits through StoreKit | L19-006: persistence design spike first, then consumable at USD 0.99, one free credit, ledger with reserve/commit/release, unlock confirmation S-18, restore; App Review notes; legal copy | Purchase, cancel, pending, Ask to Buy, interruption, crash-between-reserve-and-commit, and reinstall (with and without iCloud) tested in sandbox and TestFlight; no double charge; no path loses work or a paid photo | 0.60 |
| **P7 — Harden** | M7 | Release-grade quality | Epics 16–17: privacy (network inspection, EXIF tests, drafts retention and file protection, App Privacy answers), performance and 48 MP stress, stale-result audit; accessibility baseline check (ADR-050); localization review by native speakers for every shipped language; EU accessibility-law status confirmed (ADR-050) | No P0/P1 defects; privacy and performance audits green | 0.90 |
| **P8 — Beta** | M8 | Real people, real printers | AS18-007/AS18-008: TestFlight with the founder's beta testers, spread across Tier 1 countries where possible; observed first-use sessions and the questionnaire ([22 §6](22-quality-and-delight-bar.md)); second quality study round; testers' own printers (several brands) and shop or kiosk prints | [20 §7](20-product-blueprint.md) targets met or explicitly waived by the founder | 0.95 (RC) |
| **P9 — Launch** | M8 | Ship worldwide and win the category | ASO per Tier 1 country from L19-010; AS18-001–AS18-005 name lock, Icon Composer icon, screenshots of W3/W5/W7, privacy policy and support page; per-territory checks (for example China mainland requirements); AS18-009 provenance audit; AS18-011 submission; AS18-012 phased release | Approved; phased release at 100 %; weekly review of ratings and one-star themes for 90 days | **1.0** |

## 3. Critical path

```text
P0 Tier 1 list ──▶ P3 profile research + rules (longest) ───────────────▶ P5 experience ──▶ P7 harden ──▶ P8 beta ──▶ P9 launch
P1 device evidence ──▶ P2 production project ──┘   └──▶ P4 quality (∥ P3) ──┘   └─▶ P6 pricing (∥ P5)
```

With a worldwide launch, **profile research and validation** (L19-013) is the longest item, followed by **real-world quality across skin tones and hair** (P4). Profile research needs no code: start it the day the Tier 1 list is confirmed, in parallel with P1 and P2. If research capacity is short, cut the size of Tier 1, never the release gate.

## 4. Next three work batches

1. **Profile research (P3 ∥, under way).** US passport and US visa are drafted ([profiles/us-passport-and-visa.md](profiles/us-passport-and-visa.md)): framing only, with no background or tone changes. They need browser confirmation of the official pages. Next: UK passport (digital and print), then Japan passport and My Number card.
2. **Physical evidence round (P1).** On the iPhone 15 Pro Max and one older supported iPhone: camera direction calibration on front and back cameras; first-frame and shutter latency; 48 MP import memory; capture-protection spike (L19-017); three printers × two papers measured at Actual Size against tolerances written down first; record results in the spike reports.
3. **Start profile research (P3 ∥).** One sourced profile document per profile, in the order of [25 §3](25-wave-a-document-types.md). **Answer the alteration question first** (are background replacement and tone allowed?), because it decides the experience for that profile. Then: background colour, children's rules, and digital submission limits. In parallel, verify the P2 list (Australia inkjet, driving licences, Saudi Absher, Brazil 3 × 4, Mexico).

## 5. What does not change

The quality bar, privacy, and deterministic-core rules in [AGENTS.md](../AGENTS.md) apply in every phase; accessibility follows the 1.0 baseline (ADR-050). A phase does not end early because a date approaches; scope is cut instead, in this order: Tier 1 size → P1 features in §4 of the blueprint → extra paper presets → App Intents → the post-launch functions. Pillars 1–3 in [20 §2](20-product-blueprint.md), the unlock confirmation, and the export gate are never cut.

## 6. After 1.0 (candidate order)

1. Tier 2 profiles, in L19-010 order.
2. Accessibility release: Epic 15 audits, J8 VoiceOver and Voice Control journeys, accessibility text sizes (ADR-050).
3. Baby relaxations as profile data (ADR-017); best-frame burst (F-17); camera-based print check.
4. Credit packs if beta or launch data show families need them (ADR-048).
5. Recents and favourites (U10-013); Spotlight for profiles.
6. Optional on-device coaching with Foundation Models, if it passes FM14-001–FM14-005 and stays advisory (ADR-032, ADR-042).
