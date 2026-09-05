# M1 — AVFoundation → Vision → segmentation → Core Image → exact export

This directory contains the first **disposable native-iOS feasibility project** for ID Photo App. It is intentionally not the production application and not the final UI.

## What this spike proves

One button-driven physical-device run exercises this path:

1. AVFoundation rear-camera authorization at point of use.
2. `AVCaptureSession` configured on a serial-executor actor.
3. High-resolution still request using the active format's largest supported photo dimensions.
4. Orientation-normalized Core Image source.
5. Vision `DetectFaceRectanglesRequest`.
6. Vision `GeneratePersonInstanceMaskRequest`, selecting the person instance beneath the primary face.
7. On iOS 27, a non-blocking feasibility probe of `GenerateIterativeSegmentationRequest` seeded at the detected face center. Its downloadable model assets are requested on demand.
8. Core Image white-background composite.
9. Deterministic **900 × 1200 px** test crop/render in sRGB.
10. One final JPEG encode.
11. Independent ImageIO reopen and verification of exact pixel size, JPEG UTI, and absence of GPS metadata.
12. A shareable JSON evidence record containing device/OS identity and measured stage timings.

The 900 × 1200 crop is **not an official ID-photo rule**. It exists only to prove deterministic high-resolution rendering and exact export. Official geometry remains a later rules-engine concern.

## Requirements

- Xcode 27.
- A physical iPhone running iOS 26 or later.
- iOS 27 is required only for the iterative-segmentation refinement probe.
- A development team selected in Signing & Capabilities for the `M1PipelineSpike` target.
- Network access may be needed the first time iOS 27 downloads the iterative-segmentation model assets. The main automatic person-segmentation/export path remains on-device.

Do not use Simulator as evidence for camera latency, segmentation performance, memory, thermal behavior, or M1 feasibility.

## Run procedure

1. Open `M1PipelineSpike.xcodeproj` in Xcode 27.
2. Select the `M1PipelineSpike` scheme.
3. Select a connected physical iPhone.
4. In Signing & Capabilities, select your Apple development team if Xcode has not already done so.
5. Build and run.
6. Tap **Start Camera**. Camera permission should appear only now, not at app launch.
7. Frame one clearly visible person from the chest/shoulders upward against a normal background.
8. Tap **Capture + Run M1**.
9. Wait for the screen to show either `M1 core pipeline PASS` or an explicit failure.
10. Inspect the rendered preview for obvious mask alignment errors.
11. Share the JSON evidence file and verified JPEG if the run needs review. Do **not** commit personal/family test photos to this public repository.

On the first iOS 27 iterative-segmentation run, model download can dominate that optional probe's timing. Run again after assets are available to record steady-state segmentation timing.

## Automatic pass gate

`M1 core pipeline PASS` requires:

- at least one Vision face detected;
- a person-instance mask generated;
- Core Image composition/render completes;
- the JPEG reopens as exactly **900 × 1200 px**;
- the reopened type identifier is JPEG;
- GPS metadata is absent.

The iOS 27 iterative-refinement probe is separately recorded. Failure to download or run that beta refinement API does not falsify the automatic iOS 26-compatible core pipeline; it does block promoting iterative refinement as an M1-confirmed production choice.

## Evidence recorded

The JSON record includes:

- `hw.machine` hardware identifier;
- operating-system version;
- requested and resolved AVFoundation still dimensions;
- camera entry → preview-rendering latency;
- still-capture latency;
- normalized source dimensions;
- face count and normalized primary-face box;
- face detection latency;
- person segmentation latency;
- iOS 27 iterative-segmentation result and latency;
- render + JPEG + reopen latency;
- total pipeline latency;
- post-export dimensions/type/GPS result.

No source photo, thumbnail, face embedding, or landmark array is written to the evidence JSON.

## Physical-device review that remains human-observed

The automatic report cannot decide image quality by itself. For the first M1 acceptance run, record these observations in the PR or issue alongside the JSON:

- live preview visibly responsive and correctly oriented;
- no obvious UI hang while capture/processing runs;
- foreground mask aligns acceptably around hair, ears, shoulders, and glasses if present;
- white background is composited without obvious source offset/rotation;
- exported preview looks correctly oriented;
- repeated run succeeds at least 10 times without a stuck capture session;
- background → foreground interruption recovers;
- approximate peak memory and thermal state recorded from Xcode/Instruments for the repeated-run test.

A second performance pass on an older iOS-26-compatible iPhone is still required before ADR-024 (minimum iOS version) can be finalized.

## Current status

- Source implementation: **created for M1 review**.
- Automated unit evidence: **not executed in this remote environment; run in Xcode 27**.
- Physical current-iPhone evidence: **pending**.
- Older-supported-iPhone baseline: **pending**.
- Production promotion decision: **not made**.

M1 must not be marked complete until physical-device evidence exists. This repository intentionally keeps that distinction explicit.
