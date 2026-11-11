# 23 — Launch roadmap: from spike 0.12.7 to App Store 1.0

**Status:** Active. Replaces the stale "immediate next step" sections in [06 §16](06-delivery-plan.md), [12](12-implementation-kickoff.md), and [README](../README.md).
**Date:** 2026-11-11
**Milestones:** keeps M0–M8 from [06](06-delivery-plan.md); this document says where we are and what comes next. Function and screen IDs refer to [20](20-product-blueprint.md).

## 1. Where we are (2026-11-11)

| Area | State |
|---|---|
| App | `Spikes/IDPhotoSpike` 0.12.7. The complete Spain DNI flow works end to end on an iPhone: guided camera with review, import, automatic alignment, white background, Document Tone, Photo Check, Adjust, digital JPEG, multi-person print sheets with AirPrint, English/Spanish/Portuguese (Brazil), and the app icon picker. |
| Milestone | Late **M1** (feasibility). The UX work of M5 has been explored early inside the spike (docs 15–17). **M2 has not started**: there is no production project. |
| Evidence missing for M1 exit | Physical print measurements; directional camera calibration on both cameras; on-device Vision and segmentation benchmarks across skin tones and hair types; performance, memory, and thermal baselines on an older iPhone; iOS 27 runtime checks; ADR-024 (minimum iOS). |
| Product decisions open | D-1 launch market and profiles, D-2 pricing, D-3 children, D-4 session persistence, D-5 measurement, D-6 accessibility ranking in BD-034 ([20 §8](20-product-blueprint.md)). |
| Not built for launch | Versioned rule catalog and profile picker; extra launch profiles; digital presets; StoreKit credits; Settings & About; Help; Print check; Cutting guide; helper mode; setup coaching; edge refinement; App Intents; App Store assets. |

## 2. Phases to launch

Phases run mostly in order; work marked ∥ can run in parallel. Each phase ends with a gate. A version is tagged and handed to the device at the end of each phase (AGENTS.md §17).

| Phase | Milestone | Goal | Main work (backlog IDs) | Exit gate | Version |
|---|---|---|---|---|---|
| **P0 — Decide** | M0 close | Lock the decisions that shape scope | Accept or amend ADR-047 (market/profiles) and ADR-048 (pricing); decide D-3 to D-6; accept the proposed targets in [20 §7](20-product-blueprint.md) and [22](22-quality-and-delight-bar.md) | All six decisions recorded in doc 10 or the brand log | docs only |
| **P1 — Prove on device** | M1 exit | Close the physical evidence gaps | S1-014 performance baseline on an older iPhone; S1-015 ADR-024; P12-005 physical print round on ≥ 3 printers (inkjet, laser, photo printer) and 2 papers; camera direction calibration on both cameras (ADR-044); S1-017/S1-018 fixture benchmarks with a consented, diverse set; decide eye-line and scrim prototypes (ADR-045) | M1 exit checklist in 06 §4 complete; S1-016 ADRs locked | 0.13 |
| **P2 — Production foundation** | M2 | Promote the spike into the production project | F2-001–F2-011: project, Swift 6, module boundaries, typed errors, privacy-safe logging and signposts, CI, privacy manifest; promote Domain/Imaging/Camera code by review, not copy; keep all tests green | Production app reaches spike parity on device; CI green | 0.20 |
| **P3 — Rules and profiles** | M4 | Profiles become data; launch profiles exist | R7-001–R7-018: schema, validators, loader, provenance, evaluators, alteration policy, digital presets; U10-002 profile picker (S-02); U10-011 provenance detail; research and validate each launch profile from D-1 (one profile document per profile, like [13](13-spain-foto-carnet.md)) | Every launch profile passes the [01 §15](01-product-definition.md) release gate; no literal rule text left in UI code | 0.30 |
| **P4 — Quality** ∥ P3 | M3 | Reach the photo-quality bar | Calibrate checks (A5-005, A5-006, A5-007); edge refinement B6-005/B6-006 (S-11); segmentation fixtures B6-007; helper mode L19-001; *Find a good spot* L19-002; consented portrait fixtures; quality study L19-007, first round | [22 §2.2](22-quality-and-delight-bar.md) targets met on the fixture set; first blind study run | 0.40 |
| **P5 — Complete the experience** | M5–M6 | Every launch screen, journey, and moment | New screen contracts in doc 16 for S-02, S-04 additions, S-11, S-16–S-20; build them; Print check L19-003; Cutting guide L19-004; Print at a shop L19-005; Home fresh-install visual L19-008; aesthetic gaps in [22 §3.3](22-quality-and-delight-bar.md); U10-014 complete state pass; TipKit tips; App Intents AI13-001–AI13-005 | Journeys J1–J8 pass their acceptance in [21 §5](21-user-journeys.md) in a moderated test | 0.50 |
| **P6 — Pricing** | M5 | Fair credits through StoreKit | L19-006 / AS18-006: consumable credits, free first result, restore, pricing sheet S-18; App Store review notes; legal copy | Purchase, cancel, restore, interrupted-purchase, and Ask to Buy behaviour tested in sandbox and TestFlight; no path loses work | 0.60 |
| **P7 — Harden** | M7 | Release-grade quality | Epics 15–17: accessibility audits, privacy (network inspection, EXIF tests, App Privacy answers), performance and 48 MP stress, stale-result audit; full localization review by native speakers in es-ES and pt-BR | No P0/P1 defects; all audits green; the [11 §13](11-ios-excellence-strategy.md) checklist passes | 0.90 |
| **P8 — Beta** | M8 | Real people, real printers | AS18-007/AS18-008: internal then external TestFlight in the launch markets; second task-test round; second quality study; printer round with testers' own printers | [20 §7](20-product-blueprint.md) targets met or explicitly waived by the founder | 0.95 (RC) |
| **P9 — Launch** | M8 | Ship and win the category | L19-010 ASO and market research (from [brand 04 §9](brand/04-market-prioritization.md)); AS18-001–AS18-005 name lock, Icon Composer icon, screenshots of W3/W5/W7, privacy policy and support page; AS18-009 provenance audit; AS18-011 submission; AS18-012 phased release | Approved; phased release at 100 %; weekly review of ratings and one-star themes for 90 days | **1.0** |

## 3. Critical path

```text
P0 decisions ──▶ P1 device evidence ──▶ P2 production project ──▶ P3 rules + launch profiles ──▶ P5 experience ──▶ P7 harden ──▶ P8 beta ──▶ P9 launch
                                                     └──────▶ P4 quality (∥ P3) ──┘          └─▶ P6 pricing (∥ P5)
```

The longest uncertain items are **profile research and validation** (P3, per launch market) and **real-world quality across skin tones and hair** (P4). Start both as soon as P0 is decided; neither depends on the production project.

## 4. Next three work batches

1. **Founder decision session (P0).** Review ADR-047, ADR-048, and D-3 to D-6 in [20 §8](20-product-blueprint.md); accept or adjust the proposed targets. Output: decisions recorded in doc 10.
2. **Physical evidence round (P1).** On the iPhone 15 Pro Max and one older supported iPhone: camera direction calibration on front and back cameras; first-frame and shutter latency; 48 MP import memory; three printers × two papers measured at Actual Size; record results in the spike reports.
3. **Start profile research for the D-1 set (P3 ∥).** One sourced profile document per launch profile, including the alteration policy (is background replacement allowed?) and digital submission limits.

## 5. What does not change

The quality bar, privacy, accessibility, and deterministic-core rules in [AGENTS.md](../AGENTS.md) apply in every phase. A phase does not end early because a date approaches; scope is cut instead, in this order: P1 features in §4 of the blueprint → extra paper presets → App Intents → the post-launch functions. Pillars 1–3 in [20 §2](20-product-blueprint.md) are never cut.

## 6. After 1.0 (candidate order)

1. More profiles in the English expansion markets (Canada, UK, Australia), then Germany, France, Italy, Mexico ([brand 04 §7](brand/04-market-prioritization.md)).
2. Best-frame burst (F-17) and camera-based print check (reading the printed bar with the camera).
3. Recents and favourites (U10-013); Spotlight for profiles.
4. Optional on-device coaching with Foundation Models, if it passes FM14-001–FM14-005 and stays advisory (ADR-032, ADR-042).
