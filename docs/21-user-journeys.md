# 21 — User journeys

**Status:** Active. Describes the launch experience end to end. Steps marked **New** are not in the spike yet and are listed in [the blueprint](20-product-blueprint.md) and [the roadmap](23-launch-roadmap.md).
**Date:** 2026-11-11
**Screens and functions:** IDs refer to [20 §4–5](20-product-blueprint.md). Moments W1–W8 refer to [22 §4](22-quality-and-delight-bar.md).

## 1. Why journeys matter here

An ID photo is an errand, not a hobby. People arrive with mild anxiety ("will it be rejected?", "will it print at the right size?") and leave satisfied only when the **physical or digital result is done**. A journey therefore ends at a cut photo in an envelope or a file accepted by an upload form, not at an export button ([constitution rule 10](brand/02-experience-constitution.md)).

Each journey below lists, per step: the screen, what the person does, what Calipic does, how the person should feel, and what happens when it goes wrong.

## 2. Personas

| Persona | Situation | Main worry | What "great" looks like |
|---|---|---|---|
| **Lucía, 34, Madrid** | Renewing her DNI next week. Has a home inkjet and 10 × 15 photo paper. | "The shop photo always looks awful, and it costs money." | A photo she likes, printed at home in 5 minutes. |
| **Marcos and Ana, parents of a 9-month-old and a 6-year-old** | Family trip; need passport photos for both children and themselves. | "The baby won't sit still. Four trips to the shop is too much." | One session, one sheet with every family member, no shop. |
| **Priya, 27, moving to a new country** | Visa application needs an online upload and two printed copies. | "The upload form rejected my last photo for file size." | A file that passes the form, plus prints, in a language she reads. |
| **Daniel, 58, VoiceOver user** | Needs a driving-licence photo; his partner can help hold the phone. | "Apps like this are all drag-and-pinch." | Completes the whole flow with VoiceOver, helper holding the phone. |
| **Returning user** | Made photos last month; needs two more copies. | "Do I have to start over?" | Opens the app, reprints from the saved session in under a minute. |

## 3. The emotional curve we design for

```text
Feeling
  ▲                                         W5 sheet fills        W7 print measures right
  │                     W3 the landing ✦          ✦                    ✦      W8 done
  │         W2 green oval ✦                              ✦ W6 files ready        ✦
  │  W1 calm start ✦
  │ ✦
  │ anxious start                     (dip: a warning)
  └────────────────────────────────────────────────────────────────────────▶ Time
   Home   Preflight   Camera   Review   Photo Check   Result   Sheet   Print   Cut
```

Rules derived from the curve:

- The **peak** is the landing on Photo Check (W3): the ordinary photo becomes an official-looking portrait. Nothing may delay or obscure it: no paywall, no tip, no permission prompt.
- The **end** is the print measuring correctly (W7) and the finished copies (W8). Peak-end research ([19 §1.2](19-capture-wow-moment-research.md)) says these two moments define the memory, so nothing negative may follow them: no upsell and no review prompt on the same screen.
- **Dips** (a warning, a bad print) are allowed, but each must carry an obvious fix within one tap ([constitution rule 8](brand/02-experience-constitution.md)).

## 4. Journeys

### J1 — First photo, printed at home (Lucía) — the core journey

| # | Screen | Person does | Calipic does | Feeling / moment | If it goes wrong |
|---|---|---|---|---|---|
| 1 | Home S-01 | Opens the app for the first time. | Shows the promise, Take Photo, Choose Photo, and the current document. No account, no permission prompt, no carousel. Fresh-install visual shows what the result looks like. | Calm, "this looks easy and nice" (W1). | — |
| 2 | Choose document S-02 **New** | Confirms *Spain · DNI*; it is pre-selected from region and language. | Shows size and background in one line. | Certain she has the right format. | Profile not available: explains which documents are supported; offers generic sizes, marked as not official (ADR-018). |
| 3 | Preflight S-04 | Taps Take Photo. Reads three tips. Opens **Find a good spot** (**New**). | Tips: face a window, stand about one arm's length from a plain light wall, no strong light behind you. Asks **Who is taking the photo?** Me / Someone helping (**New**). Shows the price once, plainly, if her free result is used (ADR-048). | Prepared, not lectured. | Cancel returns Home with nothing changed. |
| 4 | Camera S-05 | Holds the phone at eye level. | Oval, one phone instruction at a time ("Raise the phone"), spoken when VoiceOver is on. Oval turns green and settles with a haptic: *Ready to take photo*. | "It's helping me" (W2). | Permission denied: explains and offers Choose Photo. Dim light: "Find more light on your face". |
| 5 | Camera | Presses the shutter (or Auto counts 3-2-1). | Soft bloom, one haptic, system shutter sound. | Immediate response. | Capture fails: Try Again; nothing lost. |
| 6 | Review S-07 | Looks at her eyes and expression; taps Use Photo. | Shows the real still, no claims. | In control. | Eyes closed: Retake returns to the live camera. |
| 7 | Photo Check S-09 | Watches. | The photo **lands**: wide source → crop springs to the official framing → background fades to white, light evens out (W3). Headline: *Looks good*, plus by-eye checks. | **"Wow, that looks professional."** Peak. | *A few things to check*: rows explain fixes. *Better to retake*: Retake one tap away. |
| 8 | Photo Check | Presses and holds the portrait. | Shows the original while held (W4). | Proof of the improvement; trust. | — |
| 9 | Choose result S-12 | Taps **Print Sheet**. | Explains that edits are kept for either path. If the free result is spent, the Pricing sheet appears here, before any file is made (ADR-048). | Fair. | Purchase cancelled: returns to Choose result; edits kept. |
| 10 | Your sheet S-14 | Leaves 4 × 6 selected; raises copies to 8. | Photos glide into new positions as copies change (W5). Shows "12 of 12 copies placed". | Playful, satisfying. | Copies don't fit: offers larger paper, fewer copies, or another page. |
| 11 | Print & Share S-15 | Taps Print. | Prepares and verifies files: *Your files are ready* (W6). AirPrint prefers bordered paper. One line: load the chosen paper and avoid any "fit" or "borderless" option. Not every print dialog shows a scaling control, so the copy names what to avoid rather than a switch that may not exist. Sending to the printer is a separate state from a correct print. | Confident. | Export fails: *Files not ready* + Try Again. Printer not found: share PDF or JPEG instead. |
| 12 | Print check S-16 **New** | Measures the bar with a ruler (or holds the print to the camera, post-launch). Answers *Yes, 50 mm*. | Confirms: *Your photos are the right size* with a quiet tick (W7). | **"It actually came out right."** End peak. | *No*: asks the measured value, explains the cause (Fit to Page, borderless, wrong paper), and offers a reprint with the fixed settings. |
| 13 | Cutting guide S-17 **New** | Follows three steps: cut along the tick marks, rows first, then columns. | Shows the cut order on her actual sheet layout. | Finished the real job (W8). | — |
| 14 | Home | Taps Done. | Keeps the session (D-4). Later, at a calm moment after a confirmed good print, may ask once for a rating (L19-009). | Satisfied. | — |

**Target:** steps 1–11 in under 3 minutes for a first-time user; a digital-only variant (J4) in under 90 s.

### J2 — The family sheet (Marcos and Ana)

1. Home → Take Photo → preflight → **Someone helping** → back camera.
2. Each person is captured in turn. After each Photo Check, **Add another person** (from Your sheet or Choose result) keeps the earlier people and their edits.
3. Your sheet shows a circle per person. Each person can have their own sizes (for example 26 × 32 for DNI and 35 × 45 for a passport) and copy counts. The layout solver mixes them on one page.
4. One print, one cutting session. **Moment:** watching four faces arrange themselves on one sheet (W5) is the family "wow", and no mainstream iOS competitor does it clearly ([14 §5.3](14-priority-feature-plan.md)).
5. Pricing: one credit per person (ADR-048, proposed). The price for four people is shown before the sheet is made, never as a surprise.

### J3 — Baby or child, with a helper (Marcos holds the phone)

| Step | What changes for children |
|---|---|
| Preflight | Helper mode is recommended automatically when a child profile or age is chosen. Tips: lay the baby on a white sheet and photograph from above; or seat the child against a plain wall. |
| Camera | Back camera. Instructions address the photographer ("Move closer", "Hold the phone level") rather than the subject. Optional short burst to catch open eyes (post-launch, F-17). |
| Photo Check | Child relaxations come from the profile only when the source defines them (D-3). Manual checks list "no hands, toys, or pacifier in the photo". |
| Failure | "Eyes closed" or "Head turned" are warnings with a one-tap Retake; no blame language. |

### J4 — Digital upload (Priya)

1. Choose document → the visa or passport profile with its **digital submission preset** (pixel range, file-size limit; F-41).
2. Capture and Photo Check as J1.
3. Choose result → **Digital Photo**: the JPEG is encoded to the preset (for example under a byte limit) and verified by reopening the file. The screen states the pixel size and file size in plain words.
4. Share to Files, Mail, or the browser upload. Optional: also make a print sheet from the same edit without retaking.
5. **If the form rejects the file:** Help explains the preset and offers a re-export with a different size when the profile allows it.

### J5 — Printing at a shop or kiosk instead of at home

Some people have no printer. From Print & Share, **Print at a shop** (**New**, L19-005) shares the lab-ready 4 × 6 or 10 × 15 JPEG at 300 ppi and shows short instructions: order a standard print of that size, ask for no cropping or "fit" if the shop offers it, then measure the bar. A standard shop print usually costs much less than an ID-photo service, and one print holds every copy, which is the money-saving proof for J1's persona.

### J6 — Recovery journeys

| Situation | What Calipic does | The person stays in control because |
|---|---|---|
| Camera access denied | Explains, offers Open Settings and Choose Photo Instead. | Never a dead end. |
| Imported photo has no face, several faces, or is too small | Specific message and Choose Another Photo; existing people are kept. | Nothing is lost. |
| Background edges look wrong around hair | Adjust → Background shows the warning; **Fix the edges** (P1) lets them tap the area; Original stays available. | The automatic result is never forced. |
| Photo Check says *Better to retake* | Explains the cause in one sentence; Retake is one tap; Continue remains for renderable cases. | The app never blocks a human decision (UXP-04). |
| Print came out the wrong size | Print check diagnoses the likely cause and reprints with corrected settings. | The #1 competitor complaint becomes a fix. |
| Purchase fails or is cancelled | Returns to Choose result with all edits; Restore in Settings. | Work is never held hostage. |

### J7 — Returning user

Home shows **Your sheet** with the saved people (D-4). Tapping it opens the sheet with the same layout; the person changes copies and prints. Reprinting an already paid output costs nothing more (ADR-048, proposed). Siri or the Action button can open the camera directly ("Take an ID photo", F-56).

### J8 — VoiceOver and Voice Control (Daniel)

- Every step in J1 is reachable with VoiceOver; focus order is title → main object → status → primary action ([16 §2.4](16-screen-experience-spec.md)).
- Camera: spoken phone-movement instructions with rate limiting; the shutter value summarizes readiness in words. In helper mode, the instructions address the person holding the phone.
- Photo Check: each row reads topic, state, and explanation; **Compare with original** is an accessibility action.
- Adjust: Move Up/Down/Left/Right, Zoom In/Out, and Reset Position replace gestures; Voice Control uses the visible names.
- Print check: the measured value can be entered with a Stepper as well as by choosing Yes/No.

## 5. Journey acceptance

A journey is ready for release when:

1. a moderated task test with first-time participants completes it unaided at the rate in [20 §7](20-product-blueprint.md);
2. each "If it goes wrong" branch can be triggered and recovers as described ([screen states](ui/screen-states.md));
3. VoiceOver completes J1 and J4;
4. J1 and J2 produce physically correct prints on the printer test set;
5. the moments in the journey meet their acceptance criteria in [22 §4](22-quality-and-delight-bar.md).
