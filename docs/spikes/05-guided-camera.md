# M1 spike 05 — Guided camera

**Implemented:** 2026-09-16 (app versions 0.5.0 to 0.5.2)  
**Status:** Camera controller, preview, guidance, capture-to-staging, and the no-camera/denied states implemented; simulator checks cover the deterministic parts. Every hardware measurement is pending the physical iPhone 15 Pro Max.  
**Backlog:** S1-020 (implementation half of S1-002); FR-020 to FR-023, C9-001 to C9-004. Design: [14-priority-feature-plan.md §3.9](../14-priority-feature-plan.md), [11-ios-excellence-strategy.md](../11-ios-excellence-strategy.md) Signature 1. Decision: ADR-034.

## Question

Can an AVFoundation session start quickly, guide the user with one calm hint per moment, and deliver a full-quality still into the same private pipeline as an import, with permission asked only at point of use and honest recovery when the camera is denied, unavailable, or interrupted?

## Implementation

- `App/Camera/CaptureGuidance.swift` — pure Swift. `FaceFrameSummary` (face count, largest face in preview-normalized coordinates, roll, yaw) feeds `GuidanceTracker`, which returns one `CaptureHint`: no face, more than one person, move closer or farther (face height 18–42 % of the visible preview, with 3 % hysteresis), centre, keep level (roll > 8°), face the camera (yaw > 15°), hold still, ready. A new hint needs 5 consecutive frames; "ready" needs 15 good frames, so nothing flickers (FR-022).
- `App/Camera/CameraController.swift` — `@MainActor @Observable` controller. Authorization is requested only when the user opens the camera; denied and unavailable are explicit states. Configuration, start, stop, and capture run on a private serial queue; the threading contract is documented at the top of the file, and the two `@unchecked Sendable`/`nonisolated(unsafe)` uses carry their safety argument. Session preset `.photo`, front camera first, `maxPhotoDimensions` capped at the largest format up to 12.6 MP, prioritization `.balanced`, responsive capture when supported, stills never mirrored. Horizon-level preview and capture rotation come from `AVCaptureDevice.RotationCoordinator`. Face metadata (`AVCaptureMetadataOutput`, `.face`) is delivered on the main queue and converted through the preview layer, so guidance geometry matches what the user sees. Interruptions, interruption end, and runtime errors update the state. Start-up and shutter-to-data times are recorded for the spike report.
- `App/Camera/CameraView.swift` — edge-to-edge preview under a dashed head oval (green when ready), one hint capsule, Cancel, a 76 pt shutter, and Switch Camera. Volume buttons, the Action button, and Camera Control trigger capture through `onCameraCaptureEvent`. Hints are announced to VoiceOver once per change. Denied shows Open Settings and Choose Photo Instead; no camera shows Choose Photo Instead. Backgrounding stops the session; returning restarts it.
- `App/Imaging/PhotoFiles.swift` — `StagedPhoto.stage(data:)` writes captured HEIF or JPEG bytes into the same protected staging directory used by imports, so capture enters the identical ingest, analysis, segmentation, and export path (FR-020).
- `App/Imaging/FaceAnalyzer.swift` — `DetectLensSmudgeRequest` (iOS 26) runs with the other requests; a confidence at or above 0.75 shows "The lens may be smudged" in the status card for captured and imported photos alike.
- Info.plist: `NSCameraUsageDescription` states that the camera is used only to take the ID photo and that photos stay on the iPhone.

## Environment

- Xcode 27.0 (27A266a), Swift 6.4, Swift 6 language mode, strict concurrency; iOS 27 SDK; deployment target iOS 26.0.
- Simulators: iPhone 17 Pro on iOS 26.0 and "IDPhoto iPhone 15 Pro Max iOS 27" on iOS 27.0. Neither has a camera, so the app shows the no-camera screen there.
- Physical device: iPhone 15 Pro Max, iOS 26.6.2, provisioned by the user. First camera run on 2026-09-16 (version 0.5.0).

## Validation evidence

| Check | Result |
|---|---|
| Unit suites (both simulators) | 49 Swift Testing tests pass: guidance needs several frames to switch, good framing goes through hold-still to ready, size hysteresis prevents toggling, each condition maps to its own hint in priority order, unknown angles do not block readiness, and captured data stages and ingests exactly like an import |
| UI flows (both simulators) | Five XCUITests pass, including the new one: Take Photo on a simulator shows the no-camera screen and Choose Photo Instead returns to the import path |
| Build | No concurrency warnings; the delegate conformance uses `@preconcurrency` with a main-queue delivery contract rather than silencing the checker |

First device run (user, version 0.5.0): preview, hints, shutter, and hand-off to analysis worked. Two defects were found and fixed in 0.5.1: the size thresholds (face 30–55 % of the screen) forced the phone uncomfortably close, now 18–42 % with a smaller guide oval; and locking then unlocking the phone froze the preview because the interruption-ended notification marked the session running after the app had stopped it, so the controller now restarts the session explicitly and `start()` is safe to call again.

Shutter latency (user report, 0.5.1): a long delay between pressing the shutter and the photo being taken. Cause: the still was requested at the sensor's largest dimensions (48 MP on the rear camera) with `.quality` prioritization, which triggers multi-second computational processing, and there was no acknowledgement of the press. Changes in 0.5.2: stills capped at the largest format up to 12.6 MP (4032 × 3024) with `.balanced` prioritization, a 120 ms white flash and a haptic on press, and the measured start-up and shutter-to-data times shown in debug builds (camera overlay and main screen) so the next device run yields numbers.

Device measurement (user, iPhone 15 Pro Max, iOS 26.6.2, version 0.5.2): camera start 273 ms, shutter to staged photo data 506 ms, and the press now feels immediate. This satisfies FR-021 for the first device class; the remaining hardware checks are listed below.

Guidance defect (user screenshots, 0.6.0 and 0.6.1): "Keep your head level" stayed on with a visibly level head. Cause: the roll and yaw were read from the raw `AVMetadataFaceObject`, whose angles are relative to the unrotated (landscape) sensor picture, so a level head in portrait reads 90°. Fixed in 0.6.2 by taking the angles from the layer-transformed face object, which the preview layer expresses in preview space. Confirm on the phone that a level head now reaches "Hold still" and "Ready".

Not yet measured, all of it on the phone: HEIF file size at 48 MP versus 12 MP front, orientation in all four device orientations, front-camera preview mirroring versus the unmirrored still, guidance behaviour and hint stability at arm's length, hardware button capture, interruption by a phone call, backgrounding and return, repeated sessions for thermal behaviour, and memory while camera, Vision, and segmentation run together.

## Addendum, 2026-09-16: capture aids, phase 1 (version 0.8.0)

Goal: help the user get the camera at eye level, the phone and the head level on three axes, the light from the front, and the face well exposed, before the shutter. Everything runs on iOS 26 with public API; each aid is a measured signal, not a guess.

- **Reference frame** (user's conclusion after the first 0.8.0 run, adopted in 0.8.1): the photo records the head relative to the camera, so the checks are the head's roll, yaw and pitch in the frame. The phone's absolute attitude is not a requirement; a tilted phone with a matching tilted head is a level portrait. Core Motion (15 Hz) is used only to attribute a relative error: head rolled in the frame with the phone tilted over 4° says "Level the phone to match your head", otherwise "Keep your head level"; face pitch beyond 10° with the phone leaning over 8° says "Straighten the phone; it is leaning", otherwise "Hold the phone at eye level". An eye line through the guide rotates with the detected head roll and turns green when level in the frame.
- **Slow Vision pass** (`FrameAnalyzer`, `AVCaptureVideoDataOutput`, luma-only 420 frames, late frames dropped, at most five processed frames per second): face landmarks revision 3 on the upright, unmirrored frame give face **pitch** ("Hold the phone at eye level" beyond 10°) and the pupils. Interpupillary distance in pixels with the active format's field of view gives the **distance** ("Too close: move back, or ask someone to take it" under 45 cm, where the wide lens distorts the nose). The luma plane gives the **lighting**: subject-left versus subject-right cheek ratio ("Turn slightly to your left/right, towards the light" beyond 4:3), background ring versus face ("Move away from the bright light behind you"), and face mean ("Find more light on your face"; also raised when the sensor is at 80 % of its maximum ISO).
- **Face-metered exposure**: exposure and focus points of interest follow the largest face (throttled to movements over 8 % or 1.5 s), so skin sets the exposure rather than the wall.
- **Forgiving by design** (user feedback after 0.8.1, adopted in 0.8.2): the target user is unskilled, so "Ready" must be reachable with a reasonable attempt. Tolerances: face 16–46 % of the screen, centre within 16 % horizontally and 20 % vertically, head roll 12° (the solver levels up to 15° afterwards), yaw 20°, pitch 15°, distance 40 cm, backlight 2.2×, face luminance 0.18, and a third of a second of good frames before "Ready". One-sided light (beyond 3:2) no longer blocks: it becomes a "Tip" capsule under the hint while the frame is otherwise good, and colours the lighting segment orange.
- **Readiness row**: four segments (framing, head position relative to the camera, lighting, distance) under the hint; grey when unmeasured, green when within tolerance, orange when not. The single hint remains the only text.
- **Auto capture** (toggle "Auto", off by default since 0.10.2, remembered): three seconds of "Ready" with a visible 3, 2, 1 countdown inside the shutter ring, the hint "Look at the lens", and a tick per second; any hint change cancels it. The ring reveals its four checks one at a time in hint order. A two-page instructions screen (ring, then Auto with its switch) precedes the camera on every launch until dismissed for good; the camera session starts only after it.
- Hint priority: presence, size, distance, position, head roll (phone or head wording), yaw, head pitch (phone or height wording), backlight, darkness, hold still, ready; one-sided light is a tip.
- Debug overlay prints roll, tilt, face pitch, distance, L/R ratio, background ratio, face luminance, and the analysis time per frame, so a device screenshot validates the signs and thresholds.

Simulator evidence: twelve guidance unit tests cover the priority order, hysteresis, relative pose with phone-or-head attribution, the framing segment, distance, pitch, lighting direction, the luma analysis on a synthetic frame, and the focal-length arithmetic. Live analysis cannot run in the simulator (no camera, no Vision inference context); the analyser stops after the first failure.

Device evidence needed: sign of face pitch (raise versus lower), direction of the eye line versus the actual head tilt, sign of the lighting direction with the front and back cameras, the per-frame analysis time and thermal behaviour over a two-minute session, whether the readiness segments flicker, and whether the auto-capture countdown feels right.

## Findings

1. **Face metadata is the right source for live guidance.** It costs nothing extra, arrives at frame rate, and includes roll and yaw when the device provides them; Vision on video frames stays reserved for a later, measured decision (C9-002).
2. **Swift 6 and AVFoundation need a written threading contract.** The session objects live on a serial queue; the delegates are documented as single-resume; the compiler accepts the design with two annotated exceptions rather than blanket unchecked conformances.
3. **Same staging path for camera and import** means every downstream feature (alignment, background, print) is exercised by both sources without special cases.
4. **Simulators cannot exercise this spike** beyond states and staging; the acceptance evidence is a device session with the user.

## Limits and next evidence

1. Run on the iPhone 15 Pro Max: record start-up and capture milliseconds (exposed on the controller), check orientation and mirroring, verify hint stability, hardware buttons, a phone-call interruption, and background/return.
2. Decide the default camera: front (self-capture) versus back (someone else takes it); the code starts front.
3. Deferred Start (iOS 26) is left at system defaults; measure whether opting into manual deferred start improves first-frame time.
4. Lens-smudge threshold 0.75 is Apple's example value and is untested on this corpus; the macOS harness prints the confidence per picture for calibration.
5. Live guidance does not yet check lighting or lens smudge before capture; both are candidates once the device baseline exists.
6. The head oval is a composition aid only; the official crop still comes from analysis after capture.

**Outcome:** Keep, pending device evidence. The camera code stays in the spike until the measurements above are recorded and ADR-034 can move to Accepted.
