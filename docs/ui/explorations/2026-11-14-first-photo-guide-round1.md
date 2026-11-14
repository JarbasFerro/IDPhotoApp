# First-photo guide, round 1 (2026-11-14)

Founder feedback on 0.20.14: the coach banner at the top pushes the whole screen down, and the next step is not always clear.

## What the 0.20.14 screens show

- The card is at the top; every target (Take Photo, Print, Continue, Unlock, Print) is at the bottom, so the eye travels the full screen each step.
- Step 1 has three competing actions: the card's Continue, the ringed document card, and Take Photo.
- Photo Check: the orange "2 things to look at" reads as "fix first", while the card says "then tap Print".
- Your sheet: Continue is below the fold, so its ring is not visible.
- Step 6 has two hidden sub-steps (choose At Home / At a Shop, then Print) under one caption; the route cards carry no ring.

## Research (sources in the session notes)

- NN/g: learn by doing; one action per hint, one hint at a time; hints must not look like controls; chained overlays get skipped.
- Chameleon benchmarks: completion peaks at about four steps and drops at five or more; a progress indicator adds about 12%; embedded guidance beats modals (modals dismissed 37.5%).
- Material feature discovery: tap target plus hint text; multi-step guided flows of at most three components.
- TipKit (iOS 27.2 SDK): `popoverTip`, `TipGroup(.ordered)`, `tipBackgroundInteraction`; tips dismiss on outside tap or X and are unreliable on toolbar items, so they cannot carry a mandatory, ordered flow. Keep TipKit for optional tips after the guide.
- Real apps (Duolingo, Wallet, banking card setup): fixed layout, exactly one dominant control, usually a bottom-pinned filled button; bubbles with arrows for in-content targets.

## Options

A. Guide line on the action (recommended). The caption sits directly above the screen's real primary button in the bottom bar, with a thin four-phase progress bar. Nothing at the top. In-content choices (document, print route) get a short arrow hint "↑ Choose where you'll print" in the same line plus the ring.
B. Anchored bubble with an arrow pointing at the target control, floating over the content; progress in the bubble.
C. Spotlight: the screen dims except the target, with the caption beside it.

Supporting changes for any option: four phases instead of six steps (Photo · Check · Sheet · Print), the document confirmed inside the photo step, Photo Check marks items as "worth a look" during the guide rather than a blocking warning, and the target is scrolled into view when a step starts.

**Decision (founder, 2026-11-14):** A, the guide line on the action, with the four phases. Built in 0.20.15. Photo Check's own wording is unchanged; the line says retakes and fixes are free instead. No auto-scroll was needed once the top card was gone.

**Revisited (founder, 2026-11-14, on device with 0.20.17):** the line in the bottom bar made the bar taller and hid the screen, and screens with several things to do (document and photo; paper, copies and Continue) need several tips. Switched to B, anchored bubbles over the screen, one tip at a time with Next on explanations; built in 0.20.18. Colour: highlighter yellow (guide colour round 1).
