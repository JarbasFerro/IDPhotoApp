# 26 — UX and design challenge

**Status:** Critique and proposals for founder decision. Nothing here is accepted yet.
**Date:** 2026-11-11
**Evidence:** screenshots of spike 0.14.0 from the UI test run (every main screen), the UX-bearing docs (04, 15–19, 21, 22, brand 02, 07, 11, 12), and the code.
**Chosen in round 1:** Home 1b and Photo Check 2a ([explorations](ui/explorations/README.md)).

## 1. Verdict

The camera is the best screen in the app, and the engineering under every screen is sound. The weak points are elsewhere:

- **The ending is the weakest part.** The docs say the end of the journey decides satisfaction, yet Share is a utility list and the print check does not exist.
- **The app breaks several of its own written rules,** because nothing enforces them.
- **The documentation is too large to steer by.** UX truth is spread over 12 documents, and the one marked "active screen contract" is out of date.

## 2. Where the documentation works against us

| # | Challenge | Evidence | Proposed change |
|---|---|---|---|
| D1 | **Too many documents; the UX truth is scattered** | 71 Markdown files, 17,400 lines. UX guidance sits in 12 documents (2,785 lines). Doc 16, the "active screen contract", mentions the document picker and custom size once: it was not updated for 0.13 or 0.14 | One living screen book: doc 16 plus a generated screenshot gallery (§4, idea 9). Move 04, 15, 17, 18, 19 to `docs/archive/`. A UI change is not done until doc 16 and the gallery are updated |
| D2 | **Quality is defined by rules, not by examples** | Doc 22's checklist cannot tell good from great. There is no reference board. Every screenshot shows colour blocks or a silhouette, so nobody has judged the look of this portrait app with a portrait in it | A consented portrait set for design review (private) and licensed model portraits for anything public. A short reference board: which apps set the bar for which quality |
| D3 | **Rules exist on paper and are broken on screen** | See §3, A1–A4. "No jargon" versus "JPEG · 520 × 640 pixels". "Rules are data" versus hard-coded "Remove headphones; check headwear and glasses" for every country. The docs say *Photo Check* and *Print & Share*; the app says *Your photo* and *Share* | Make the rules executable: a test that fails on banned words in the String Catalog; a name table in doc 16 that the UI tests assert |
| D4 | **The signature moment collides with the trust promise** | The landing moment is "the background fades to white". The catalog records `officialEditingRule: disallowed` for the US, the UK, South Korea, Canada, Saudi Arabia, and the Italian CIE. ADR-051 keeps editing on, and no document says how the person is told | Keep ADR-051 and add honesty. For those documents, replace the background only when the real wall fails our background check, and say so in one line with a one-tap switch to Original |
| D5 | **First launch for a worldwide user is undefined** | Every new user starts on Spain · DNI (`DocumentChoice.defaultProfileID`). In Home 1b the document is a small row, so a US user could finish a DNI-sized photo without noticing | Default from the iPhone's region to that country's main document (new catalog field). With no profile for the region, ask once: "What is the photo for?" |
| D6 | **Pricing is decided and invisible** | ADR-048 sets the first photo free, then USD 0.99. No screen, journey step, or design shows it. Doc 22 lists "paying after the work is done" as a satisfaction killer | A quiet line on Home ("Your first photo is free"); balance in Settings; design the unlock sheet in the next design round |
| D7 | **Eight "wow" moments, treated as equal** | Doc 22 lists W1–W8. The last two (print measures right, finished) are not built, and they are the ones the peak-end argument in doc 19 says matter most | Rank them. Invest next in the ending (Print, Print check, Finished) before polishing the middle further |
| D8 | **Confident verdicts versus uncalibrated checks** | Design 2a says "5 checks passed". AGENTS.md §9 says no measurement is calibrated; every machine check is advisory | A wording ladder in doc 16: **facts** ("Framed to 26 × 32 mm") may say passed; **advisory** checks say "looks fine"; **by-eye** items are the person's. 2a's rows follow it |

## 3. Where the app falls short of its own bar (0.14.0)

| # | Problem | Evidence in the screenshots | Fix |
|---|---|---|---|
| A1 | **The most important instruction is the quietest text** | On Share, "Print at Actual Size (100 %), not Fit to Page" is grey footnote text beside a thumbnail. The docs call wrong print size the top one-star cause | Make it a step: a short *Before you print* moment with one illustration, then the print dialog. Follow with the Print check (L19-003) |
| A2 | **Eight screens for the common path** | Home → Before your photo → Camera → Review → Your photo → Choose result → Your sheet → Share | Show the full *Before your photo* once per document, then only as Camera Help. Remove *Choose result*: Photo Check offers the document's main output as the primary button and the other as secondary (Saudi Arabia is digital only; the UK is digital first) |
| A3 | **Photo Check: five actions and dense rows** | Continue, Adjust, Retake, an info button, a delete button, and four two-line rows; the headline has the same weight as the rows | Design 2a. Delete moves into a menu |
| A4 | **The same disclaimer on four screens, in generic words** | "The receiving office decides acceptance" on Photo Check, Choose result, Digital Photo, and Requirements. "Remove headphones. Check headwear, glasses…" repeats too, and is wrong for the US (no glasses at all). The catalog's own checks appear only in Requirements | Say it once, on Photo Check, in the document's own checks from the catalog |
| A5 | **Jargon in the fast path** | "One JPEG to share or upload", "JPEG · 520 × 640 pixels", "Page JPEG", "Share PDF" | "Digital photo", "For online forms", "Print at a shop". Formats move under *More formats* |
| A6 | **Inconsistent surfaces and controls** | Photo Check, Choose result, and Share sit on white; Your sheet and Before your photo on grouped grey. *Done* is a small pill on Digital Photo and full width on Share. *Continue* wears a share icon on Your sheet | One screen template in code (background, title, bottom action bar) and one rule for button icons |
| A7 | **Share is named for the wrong job** | Title "Share"; three near-equal buttons (Print, Share PDF, Page JPEG); the digital photo's tap target is a tiny badge | "Print" as the screen's job: *Print at home* primary, *Print at a shop* secondary, the rest under *More formats* |
| A8 | **No sense of progress or continuity** | Plain push transitions; nothing says how many steps remain; the photo is redrawn on each screen | The photo as one continuous object (idea 6) and a quiet three-step marker: Photo · Check · Print |
| A9 | **People are "Photo 1", "Photo 2"** | Your sheet with two people | Larger face thumbnails as the identity; optional names |

**Keep as is:** the camera screen. It is calm, shows one instruction, and has clear states.

## 4. Improvement ideas, ranked

Impact is on the four pillars in [20 §2](20-product-blueprint.md). Effort: S = under a day, M = a few days, L = a week or more.

| # | Idea | Solves | Impact | Effort |
|---|---|---|---|---|
| 1 | **Region-aware first document**, with a one-time "What is the photo for?" when the region has no profile | D5 | High: prevents a wrong-size photo for most of the world | S |
| 2 | **Honest editing:** replace the background only when the wall fails the check; one line and a one-tap Original for documents whose rules forbid edits | D4 | High: fewer rejections, same wow when needed | M |
| 3 | **The ending:** *Before you print* step, Print check, *Finished* moment; Share becomes Print | A1, A7, D7 | High: the peak-end of the journey and the top one-star cause | L |
| 4 | **Shorter path:** preflight once per document; merge *Choose result* into Photo Check | A2 | High: two fewer screens every time | M |
| 5 | **Plain words everywhere,** enforced by a banned-word test; the disclaimer once, from catalog checks | A4, A5, D3 | Medium: clearer and more trustworthy | S |
| 6 | **The photo as one object:** zoom transitions from Check to the sheet, where the photo becomes its copies; consistent paper look (white, 6 pt radius, soft shadow, a quiet stage) | A8 | Medium–high: the app's main source of personality | M |
| 7 | **Price in plain sight:** "Your first photo is free" on Home; unlock sheet designed as a calm confirmation | D6 | High for trust at the paying moment | S now, M with StoreKit |
| 8 | **One screen template** and button-icon rules in code | A6 | Medium: coherence across every screen | S |
| 9 | **Screenshot gallery per release:** every screen, light and dark, exported from the UI tests into `docs/ui/gallery/` and reviewed side by side | D1, D2 | Medium: makes visual review routine | S |
| 10 | **Real portraits** for design review and App Store images | D2 | High: needed to judge the look at all | M (people and consent, not code) |
| 11 | **Actual size on screen:** a toggle on Photo Check that shows the photo at its true physical size | Trust in pillar 3 | Medium: a small, honest wow | S–M (needs a per-model screen density table) |
| 12 | **Wording ladder** for verdicts (facts, advisory, by eye) | D8 | Medium: keeps 2a honest | S |

**Suggested order:** 1, 5, 7, 8, and 12 go into the build of Home 1b and Photo Check 2a, because they touch the same screens. Then 4 and 9. Then design round 2 (Your sheet, Print, unlock sheet) with 3 and 6. Idea 2 needs a founder decision first, because it adjusts ADR-051. Idea 10 needs people.

## 5. Proposed documentation changes

1. Bring doc 16 up to date with 0.13 and 0.14, and add the name table and the wording ladder.
2. Archive 04, 15, 17, 18, and 19 under `docs/archive/`, with one line in each pointing to doc 16.
3. Add the banned-word list to [brand 12](brand/12-voice-and-writing.md) and enforce it with a test.
4. Add `primaryForRegion` to the catalog schema (idea 1).
5. Rank the wow moments in doc 22 and mark which are built.
