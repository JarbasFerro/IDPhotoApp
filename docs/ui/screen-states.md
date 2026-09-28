# Screen states and recovery contract

**Scope:** Current Spain DNI spike. [Main screen specification](../16-screen-experience-spec.md) defines geometry, visual hierarchy, and ordinary-state copy. This table describes the exceptional content and route. **Shipped** means present in the SwiftUI spike on 2026-09-28; **target** means design work still open. Cancellation by the person is a quiet return, while a failure gives a specific cause and recovery.

Every state uses the system background/material, native progress or alert when appropriate, and a symbol plus words for status. VoiceOver reads the changed headline or status once without stealing focus from an active system permission, picker, share, or print sheet. The parent photo, edits, and print choices remain in memory unless the person explicitly removes a photo. Long operations carry the workflow revision so late work cannot replace newer content.

| Screen and trigger | Visual and exact key message | Primary recovery; secondary route | Status |
|---|---|---|---|
| Home private storage starting | Native spinner below disabled Take/Choose; **Preparing private photo storage…** | Actions enable once initialized; initialization failure needs a named retry surface | Progress shipped; failure target |
| Home import running | Spinner row **Opening photo…** and **Cancel**; session card remains | Cancel stops current job and returns to Home | Shipped |
| Home import failed | System alert **Unable to complete** plus underlying plain error | **Choose Another Photo** returns through preflight; **OK** retains session | Shipped; headline specificity target |
| Home session full | Take/Choose disabled, existing session card visible | Open Your Sheet and remove a person; visible limit explanation | Disabled shipped; explanation target |
| Preflight cancelled | No error surface | **Cancel** returns to exact prior Home/Check/Sheet context | Shipped |
| Preflight source switched | Same three requirement rows | **Choose Photo Instead** or **Take Photo Instead** opens requested source after sheet dismissal; retain add/replace mode | Shipped |
| Requirements unavailable/stale source | Sourced rules remain visible when cached; source link/review date communicate provenance | Retry opening source when online; manual confirmation at receiving office | Versioned-source state target |
| Camera permission pending | Dark camera canvas and native progress; no readiness claim | Wait for system prompt | Shipped |
| Camera denied or restricted | **Camera access is off** and short permission explanation | **Open Settings**; **Choose Photo Instead** opens PhotosPicker after camera dismisses | Shipped |
| Camera absent | **No camera on this device** | **Choose Photo Instead** opens PhotosPicker | Shipped and UI tested in Simulator |
| Camera interrupted | Preview context retained; **Camera paused. It resumes when the interruption ends.**; shutter/countdown disabled | Resume when active; Cancel remains available | Shipped; device check pending |
| Camera capture fails | Error alert, no duplicate shutter work | **Try Again**; **Choose Photo** | Shipped; device check pending |
| Camera readiness unknown/needs attention | One compact white oval around the expected head position; one arrow grows from the oval edge for a stable phone movement, paired with the same written/spoken instruction above the white shutter. Lighting leaves the oval neutral. | Move, raise/lower, tilt, or change phone distance; manual shutter and Help remain available. | Shipped; physical direction calibration pending. |
| Camera measured checks clear | The oval turns green with **Ready to take photo**; first stable Ready briefly settles with one haptic, then rests. Green is a camera readiness cue, never acceptance assurance. | Take Photo; review manual requirements on Check; Auto acts only on measured camera checks. | Shipped; real-device review pending. |
| PhotosPicker cancelled | No failure badge or alert | Return to prior route with session unchanged | Shipped |
| Imported file corrupt/unsupported/too small | Underlying import error in Home alert, not a false Check success | **Choose Another Photo**; **OK** keeps prior photos | Shipped; more specific headline target |
| Photo Check analyzing | Source portrait; spinner; **Checking your photo…** / **Finding your face and preparing the background.** | Wait or Retake; stale revision ignored | Shipped |
| Photo Check measurable pass | Prepared portrait; pass symbol; **Looks good** plus by-eye checks | **Continue** to output choice; **Adjust**, **Retake**, **Requirements** | Shipped; never means office acceptance |
| Photo Check warn/manual | Warn/manual symbol and row detail; **A few things to check** | **Continue** with caution or **Adjust**/**Retake** | Shipped |
| Photo Check fail | Fail symbol and specific row; **Better to retake** | **Retake** via preflight; Continue remains for cases that can still be rendered | Shipped; blocking geometry target |
| Photo Check analysis unavailable/no face/multiple faces | Explicit manual/fail row instead of fabricated pass | Retake or Choose Photo via preflight; retain current source until replacement | Shipped by presentation mapping; fixture coverage target |
| Photo Check person removed while route open | **This photo was removed** and neutral unavailable symbol | System Back to prior route | Shipped; explicit Home/Sheet action target |
| Adjust mask processing | Portrait retained; **Separating the background…** near Background | Keep Original available | Shipped |
| Adjust mask poor/unavailable | Status line describing edge concern or **The background could not be separated in this photo, so the original is kept.**; White disabled if unavailable | **Original**, adjust source, or Retake after Done | Shipped |
| Adjust tone forbidden/unavailable | Light and colour hidden when forbidden, toggle disabled when unavailable | Keep source rendering; no promise of correction | Shipped |
| Adjust precision/large text | Portrait above scrolling controls; Move and zoom disclosure and Details sliders | Labeled Move/Zoom buttons or sliders; Done retains edits | Shipped; broader size review pending |
| Choose result person removed | **This photo was removed** neutral unavailable content | System Back; explicit Home/Sheet action target | Partial |
| Digital JPEG preparing | Spinner **Preparing your photo…** | Wait; navigation Back cancels or discards stale result | Shipped |
| Digital JPEG verified | Check symbol; **Your digital photo is ready.**; portrait, dimensions, manual note | **Share JPEG**; **Done** returns Home with session | Shipped |
| Digital JPEG render/verification failure | **Photo not ready**, underlying cause or **The photo could not be prepared. Try again.** | **Try Again**; Back to output choice retains edit | Shipped |
| Digital system share cancelled | Ready JPEG stays visible | Share JPEG again or Done | Shipped by system presentation; device lifetime check pending |
| Sheet empty/incomplete layout | Native list with no misleading page; **Nothing to print** / count warning | Add a person, add copies, choose larger paper, or allow more pages as applicable; Continue disabled | Partial; concrete disabled reason target |
| Sheet custom paper invalid | Numeric fields show 50–500 mm requirement beside input | Correct value then **Apply custom size** | Shipped; keyboard/large text review pending |
| Print files preparing | Spinner **Preparing your files…** | Wait; navigation Back cancels/discards stale export | Shipped |
| Print export fails | **Files not ready**, cause, **Try Again** | Retry with current sheet; Back preserves source and print choices | Shipped |
| Print/share dismissed | Same verified cards and file links remain | Print, Share PDF, Share JPEG, or Done | Shipped by system presentation; physical check pending |
| App Icon change refused | System alert **We couldn't change the icon.** / **Try again in a moment.** | Dismiss and choose again; current selection stays truthful | Shipped |

## Verification hooks

`PhotoPipelineTests` checks direct JPEG export creates no print artifacts and verifies the output. `PhotoWorkflowTests` checks selected-person export and stale result discard. `IDPhotoSpikeUITests` walks the preflight, direct digital, print, camera-unavailable recovery, accessibility text path, and icon sheet. Controlled fixture screenshots and visual notes are in [screen evidence](screen-evidence.md). Physical camera, file lifetime during real share extensions, and actual-size print measurement cannot be concluded from Simulator.
