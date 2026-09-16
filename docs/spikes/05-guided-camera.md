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

Not yet measured, all of it on the phone: HEIF file size at 48 MP versus 12 MP front, orientation in all four device orientations, front-camera preview mirroring versus the unmirrored still, guidance behaviour and hint stability at arm's length, hardware button capture, interruption by a phone call, backgrounding and return, repeated sessions for thermal behaviour, and memory while camera, Vision, and segmentation run together.

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
