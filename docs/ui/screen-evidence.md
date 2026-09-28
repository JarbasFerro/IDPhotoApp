# Calipic screen layouts and visual review

**Date:** 2026-09-28
**Device evidence:** iPhone 17 Pro simulator, iOS 26.5, synthetic four-colour photo. The screenshot set linked below was captured by `IDPhotoSpikeUITests`; no personal photo is stored here.
**Contract:** [Screen experience specification](../16-screen-experience-spec.md), especially §§2–13 and the exact control inventory in §17.

## Layout constraints

These diagrams describe order and safe-area behavior; native controls choose their own final dimensions. The portrait always retains 26:32. The sheet preview retains the selected paper ratio. Each button target is at least 44 pt. Body text wraps instead of truncating. At accessibility text sizes, the entire surface scrolls and the primary action remains reachable. In RTL, navigation and directional arrangements follow system layout direction; image content and physical dimensions do not mirror.

| Surface | Compact and large iPhone layout | Accessibility text / appearance behavior |
|---|---|---|
| Home | Navigation title → promise → stacked Take/Choose buttons → optional progress → session card → document card → privacy → App Icon/version. Larger phones gain vertical breathing room, not extra columns. | Scroll all content; keep actions full width and early. Light/Dark use semantic backgrounds; session portraits remain small and subordinate. |
| Preflight | Inline title + Cancel → three native list rows under Spain DNI header → short manual-check footer → Full requirements/source-switch rows → bottom Open Camera/Choose Photo. | Native list scrolls behind bottom safe-area button; the button never covers the last row. |
| Requirements | Inline title + Done → three native list sections. Guidance source is a true link. | Long translated guidance expands row height; review date is a footnote, not a badge. |
| Camera | Full-bleed preview → one compact oval with an arrow growing from its edge for one phone movement → top Cancel/Help → one lower message → white shutter/Switch. The oval turns green at measured readiness. | The lower dark fade supports guidance without covering the face. Cue, text, and spoken instruction agree; the oval settles once on readiness. Green never promises acceptance. Physical camera direction review is required. |
| Camera Help | Inline title → three capture tips → Automatic capture toggle and explanation → Done. | Native Form scrolls with larger text; no required tutorial gate or control over the camera subject. |
| Photo Check | Inline title and toolbar actions → largest flexible 26:32 portrait → short caption → status headline/rows → bottom Continue/Adjust/Retake. | At accessibility text sizes switch to one scroll view including actions. Status details stack below titles and use symbols plus state words. |
| Adjust | Inline title + Done → 26:32 crop → drag/pinch hint → Reset/Compare → Background → Light and colour → Move and zoom → Details. All controls stay below the portrait. | Native sheet scrolls; no overlay crosses the face or toolbar. Move/zoom buttons substitute for gestures; conditional sliders remain in Details. |
| Choose result | Inline title → small portrait beside choice heading → full-width Digital Photo and Print Sheet cards → manual-check footer. | Cards expand vertically; no fixed side-by-side action layout. Back preserves edit and person. |
| Digital Photo | Inline title → progress, error, or check result → portrait → JPEG metadata → manual-check text → Share JPEG → Done. | Result scrolls; the ready seal is decorative and never an official approval mark. ShareLink uses the system activity UI. |
| Your Sheet | Inline title → true-proportion page preview/count → each person's Stepper sizes → add person → paper fields → cutting options → bottom Continue. | List rows expand; keyboard must not cover Apply custom size. Print preview may scroll horizontally across pages. |
| Print Share | Inline title → progress/error or quiet success → print card with page preview and actual-size instruction → digital JPEG thumbnails → Done. | Share/Print remain native. Individual portrait JPEG and full-page JPEG have different labels. |
| App Icon | Inline title + Done → People then Just for fun adaptive icon grid → explanatory footnote. | Icon previews remain square; names wrap to two lines; selected trait and badge agree. |

## Captured implementation and review

The UI tests keep attachments in the `.xcresult` bundle. Permanent captures are exported to `docs/ui/screenshots/` from the successful run below. Their synthetic four-colour fixture deliberately makes framing and overlap easy to see, but it cannot establish real-photo legibility or camera behavior.

| Screen | Capture | Review |
|---|---|---|
| Home | [Home](screenshots/home.png) | Promise, two acquisition actions, document and privacy content visible in scroll order. |
| Preflight | [Preflight](screenshots/preparation.png) | Short guidance appears before PhotosPicker; full guidance and source switch remain available. |
| Photo Check | [Photo Check](screenshots/photo-check.png) | Portrait, status, and actions have distinct hierarchy. [Large text](screenshots/photo-check-large-text.png) is scrollable. |
| Adjust, initial | [Adjust top](screenshots/adjust-top.png) | Portrait begins below inline title and Done, with no overlap; controls continue by native scrolling. |
| Adjust, expanded | [Adjust controls](screenshots/adjust-controls.png) | Move/zoom and Details are reachable after scrolling. |
| Choose result | [Output choice](screenshots/output-choice.png) | Digital and print routes are separate, with manual-check note. |
| Digital result | [Digital result](screenshots/digital-result.png) | Verified JPEG and system share action appear without print setup. |
| Your Sheet | [Sheet](screenshots/your-sheet.png) | Paper ratio, copy counts, and bottom Continue are visible. |
| Print Share | [Print Share](screenshots/print-share.png) | Printed page and digital files are labeled separately; [large text](screenshots/print-share-large-text.png) scrolls. |
| App Icon | [App Icon](screenshots/app-icon.png) | Native sheet presents square previews and selection states. |
| Camera fixture | [Guidance](screenshots/camera-guidance.png), [directional cue](screenshots/camera-directional-cue.png), [first-use tip](screenshots/camera-tip.png), [Help](screenshots/camera-help.png) | The compact green ready oval and single message are rendered over a synthetic bust on Simulator. The off-center case shows the attached arrow and phone instruction. No message covers the head; both camera states and Help passed UI accessibility audits. |

The camera cannot be fully validated in Simulator because it has no camera. Physical iPhone screenshots supplied during review exposed stacked messages, overlapping shapes, an oversized oval, and face-directed cues. The revised oval and phone cue were inspected through the synthetic fixtures above; the personal screenshots were not copied into the repository. Physical validation must confirm the smaller oval suits real faces, hair, headwear, and both camera positions, and that each arrow corresponds to actual phone movement. The simulator's unavailable-state recovery is covered by UI test. Requirements is covered by its own UI test and screen contract, with a named visual capture still to add. Light/Dark variants, broader accessibility text sizes, VoiceOver interaction on device, camera lighting/thermal behavior, system share-file lifetime on device, and a physical Actual Size print measurement remain device/print acceptance work. Those results must be added here before claiming release visual completion.
