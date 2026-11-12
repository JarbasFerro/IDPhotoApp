# Design explorations

Visual options made before building screens in SwiftUI. Every round is saved here as an image, and the chosen direction is recorded in this file. The current design contract and the direction for the next rounds are in [03-design.md](../../03-design.md).

Rounds 1 and 2 were made in Claude Design, in the founder's account. That standalone service stops working by 14 December 2026, so the images here are the record.

**Rules for every round:** system type and surfaces, one restrained teal, the photo as the main object, Light and Dark as equals, status with a word or symbol. Never a real person's face in a committed image.

## Round 1 — Home and Photo Check (2026-11-11)

![Round 1](2026-11-11-home-photo-check-round1.png)

Problems addressed: Home shows nothing photographic and its footer competes with the actions; Photo Check gives the verdict and the detail rows the same weight.

| ID | Screen | Direction |
|---|---|---|
| 1a | Home | Sample first: the result is the hero; the document is one pill under it |
| 1b | Home | Photo and sheet: shows the printed result; one primary button |
| 1c | Home | Document first: "What is the photo for?", popular documents and Custom size as chips |
| 2a | Photo Check | Verdict first: one large answer; details fold into two rows |
| 2b | Photo Check | Photo on a stage with its real size; passed checks as chips |
| 2c | Photo Check | You confirm: measurements collapse to one line; by-eye items become a checklist |

In all Home options, App Icon and the other settings move behind the top-right button, and the version stays on Home (AGENTS.md §17).

**Decision (founder, 2026-11-11):** Home **1b** and Photo Check **2a**. Built in spike 0.15.0.

## Round 2 — Your sheet, Print, and unlocking a photo (2026-11-12)


![Round 2](2026-11-12-sheet-print-unlock-round2.png)

Problems addressed:

- Your sheet reads like a settings list.
- Share is named for the wrong job, and the scaling instruction is small grey text.
- The price and the point of no return have no design (ADR-048).

| ID | Screen | Direction |
|---|---|---|
| 3a | Your sheet | Paper first: the sheet as hero, people as circles, two rows for copies and paper |
| 3b | Your sheet | Tray: the largest paper; people, copies, and paper chips in one tray at thumb height |
| 3c | Your sheet | People cards: one row per person with their own copies; smaller paper |
| 4a | Print | Steps on the page: load paper, Actual Size, measure the line; Print at Home, Print at a Shop, More Formats |
| 4b | Print | Two doors (At home, At a shop); choosing home opens a *Before you print* sheet with the scaling instruction |
| 4c | Check your print | The step after printing: "Does the line measure 50 mm?" with Yes, No, Skip |
| 5a | Unlock sheet | Confirmation sheet for the free first photo |
| 5b | Unlock sheet | The same sheet for one paid photo (USD 0.99) |
| 5c | Unlock sheet | The same sheet for a family: one line per person and a total |
| 5d | Unlock, alternative | No sheet: price and the final-edits line on the Print screen itself |

5a, 5b, and 5c are three states of one design; 5d is the alternative to it. 4c follows either 4a or 4b.

**Decision (founder, 2026-11-12):** Your sheet **3b**, Print **4a**, unlock **5d**. With it, the price display changed: the app shows **credits**, not money. A person starts with 1 credit; packs are 1 for USD 0.99, 5 for USD 3.99, and 10 for USD 6.99 ([ADR-048](../../05-decisions.md)). Built in spike 0.16.0. 4c (*Check your print*) is not built yet; it is item U1 in the [roadmap](../../02-roadmap.md).
