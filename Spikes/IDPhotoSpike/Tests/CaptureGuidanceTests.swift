import Foundation
import Testing
@testable import IDPhotoSpike

struct CaptureGuidanceTests {
    private func face(height: Double, centerX: Double = 0.5, centerY: Double = 0.45, roll: Double? = 0, yaw: Double? = 0,
                      count: Int = 1) -> FaceFrameSummary {
        let width = height * 0.75
        return FaceFrameSummary(faceCount: count,
                                bounds: NormalizedCrop(x: centerX - width / 2, y: centerY - height / 2, width: width, height: height),
                                rollDegrees: roll, yawDegrees: yaw)
    }

    private func feed(_ tracker: inout GuidanceTracker, _ frame: FaceFrameSummary, times: Int) -> CaptureHint {
        var hint = tracker.hint
        for _ in 0..<times { hint = tracker.update(frame) }
        return hint
    }

    @Test func hintsNeedSeveralFramesBeforeTheySwitch() {
        var tracker = GuidanceTracker()
        #expect(tracker.hint == .noFace)
        #expect(feed(&tracker, face(height: 0.12), times: 4) == .noFace)
        #expect(feed(&tracker, face(height: 0.12), times: 1) == .moveCloser)
        // A single odd frame does not change the hint.
        #expect(feed(&tracker, .empty, times: 1) == .moveCloser)
        #expect(feed(&tracker, face(height: 0.12), times: 1) == .moveCloser)
    }

    @Test func goodFramingGoesThroughHoldStillToReady() {
        var tracker = GuidanceTracker()
        let good = face(height: 0.3)
        #expect(feed(&tracker, good, times: 5) == .holdStill)
        #expect(feed(&tracker, good, times: 9) == .holdStill)
        #expect(feed(&tracker, good, times: 1) == .ready)
        // Losing the face for a few frames keeps "ready" until the switch threshold, then reports it.
        #expect(feed(&tracker, .empty, times: 4) == .ready)
        #expect(feed(&tracker, .empty, times: 1) == .noFace)
    }

    @Test func sizeHysteresisPreventsToggling() {
        var tracker = GuidanceTracker()
        _ = feed(&tracker, face(height: 0.15), times: 5)
        #expect(tracker.hint == .moveCloser)
        // Just over the limit is not enough to leave "move closer".
        #expect(feed(&tracker, face(height: 0.19), times: 6) == .moveCloser)
        #expect(feed(&tracker, face(height: 0.22), times: 5) == .holdStill)
    }

    @Test func eachConditionHasItsOwnHintInPriorityOrder() {
        var tracker = GuidanceTracker()
        #expect(feed(&tracker, face(height: 0.3, count: 2), times: 5) == .multipleFaces)
        tracker = GuidanceTracker()
        #expect(feed(&tracker, face(height: 0.5), times: 5) == .moveBack)
        tracker = GuidanceTracker()
        #expect(feed(&tracker, face(height: 0.3, centerX: 0.8), times: 5) == .centerFace)
        tracker = GuidanceTracker()
        #expect(feed(&tracker, face(height: 0.3, roll: 20), times: 5) == .keepLevel)
        tracker = GuidanceTracker()
        #expect(feed(&tracker, face(height: 0.3, yaw: 30), times: 5) == .faceCamera)
        tracker = GuidanceTracker()
        // Unknown angles do not block readiness.
        #expect(feed(&tracker, face(height: 0.3, roll: nil, yaw: nil), times: 15) == .ready)
    }

    @Test func phoneAttitudeHintsComeBeforeHeadHintsAndClearWhenLevel() {
        var tracker = GuidanceTracker()
        var frame = face(height: 0.3, roll: 20)
        frame.device = DeviceLevel(rollDegrees: 6, pitchDegrees: 0)
        #expect(feed(&tracker, frame, times: 5) == .levelPhone)
        frame.device = DeviceLevel(rollDegrees: 1, pitchDegrees: 20)
        #expect(feed(&tracker, frame, times: 5) == .uprightPhone)
        frame.device = DeviceLevel(rollDegrees: 1, pitchDegrees: 5)
        #expect(feed(&tracker, frame, times: 5) == .keepLevel)
        frame.rollDegrees = 0
        #expect(feed(&tracker, frame, times: 5) == .holdStill)
        #expect(tracker.readiness.level == .ok && tracker.readiness.face == .ok)
        #expect(tracker.readiness.light == .unknown && tracker.readiness.distance == .unknown)
    }

    @Test func distanceAndPitchHints() {
        var tracker = GuidanceTracker()
        var frame = face(height: 0.3)
        frame.distanceCM = 30
        #expect(feed(&tracker, frame, times: 5) == .tooClose)
        #expect(tracker.readiness.distance == .attention)
        frame.distanceCM = 65
        frame.pitchDegrees = 16
        #expect(feed(&tracker, frame, times: 5) == .eyeLevel)
        #expect(tracker.readiness.face == .attention && tracker.readiness.distance == .ok)
        frame.pitchDegrees = -4
        #expect(feed(&tracker, frame, times: 5) == .holdStill)
    }

    @Test func lightingHintsPointTowardsTheLight() {
        var tracker = GuidanceTracker()
        var frame = face(height: 0.3)
        frame.lighting = LightingSummary(faceMean: 0.45, leftRightRatio: 1.6, backgroundRatio: 1.0)
        #expect(feed(&tracker, frame, times: 5) == .turnLeft)
        frame.lighting = LightingSummary(faceMean: 0.45, leftRightRatio: 0.6, backgroundRatio: 1.0)
        #expect(feed(&tracker, frame, times: 5) == .turnRight)
        frame.lighting = LightingSummary(faceMean: 0.30, leftRightRatio: 1.0, backgroundRatio: 2.5)
        #expect(feed(&tracker, frame, times: 5) == .backlit)
        frame.lighting = LightingSummary(faceMean: 0.10, leftRightRatio: 1.0, backgroundRatio: 1.0)
        #expect(feed(&tracker, frame, times: 5) == .moreLight)
        #expect(tracker.readiness.light == .attention)
        frame.lighting = LightingSummary(faceMean: 0.45, leftRightRatio: 1.1, backgroundRatio: 1.2)
        #expect(feed(&tracker, frame, times: 5) == .holdStill)
        #expect(tracker.readiness.light == .ok)
        // Without a luminance measurement, the sensor gain limit alone asks for light.
        var dark = face(height: 0.3)
        dark.lowLight = true
        tracker = GuidanceTracker()
        #expect(feed(&tracker, dark, times: 5) == .moreLight)
    }

    @Test func lightingAnalysisReadsSubjectSidesAndBackground() throws {
        // 200 x 200 luma: dark background (40), face box 60..140 with image-left 80 and image-right 160.
        let width = 200, height = 200
        var luma = [UInt8](repeating: 40, count: width * height)
        for y in 60..<140 { for x in 60..<140 { luma[y * width + x] = x < 100 ? 80 : 160 } }
        let summary = try #require(luma.withUnsafeBufferPointer {
            FaceLighting.analyze(luma: $0, width: width, height: height, bytesPerRow: width, face: (x: 60, y: 60, width: 80, height: 80))
        })
        // Image-right is the subject's left, so the ratio is above one.
        #expect(summary.leftRightRatio > 1.8 && summary.leftRightRatio < 2.2, "\(summary.leftRightRatio)")
        #expect(summary.backgroundRatio < 0.5)
        #expect(abs(summary.faceMean - 120.0 / 255) < 0.03)
        // Bright ring means backlight.
        var backlit = luma
        for y in 0..<height { for x in 0..<width where !(60..<140 ~= x && y >= 60) { backlit[y * width + x] = 250 } }
        let ratio = try #require(backlit.withUnsafeBufferPointer {
            FaceLighting.analyze(luma: $0, width: width, height: height, bytesPerRow: width, face: (x: 60, y: 60, width: 80, height: 80))
        }).backgroundRatio
        #expect(ratio > 1.9)
    }

    @Test func distanceFromInterpupillaryDistance() throws {
        let focal = try #require(FaceLighting.focalLengthPixels(fieldOfViewDegrees: 60, longSidePixels: 640))
        #expect(abs(focal - 554.3) < 0.5)
        let distance = try #require(FaceLighting.distanceCM(interpupillaryPixels: 55, focalLengthPixels: focal))
        #expect(abs(distance - 63.5) < 0.5)
        #expect(FaceLighting.distanceCM(interpupillaryPixels: 0, focalLengthPixels: focal) == nil)
        #expect(FaceLighting.focalLengthPixels(fieldOfViewDegrees: 0, longSidePixels: 640) == nil)
    }

    @Test func capturedDataStagesLikeAnImport() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CameraStaging-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try await SyntheticFixture.staged(width: 600, height: 800)
        let data = try Data(contentsOf: source.url)
        try FileManager.default.removeItem(at: source.directory)
        let staged = try await StagedPhoto.stage(data: data)
        let photo = try await PhotoPipeline(root: root).ingest(staged)
        #expect(photo.pixels == SourcePixels(width: 600, height: 800))
        #expect(!FileManager.default.fileExists(atPath: staged.directory.path))
        await #expect(throws: PhotoError.self) { try await StagedPhoto.stage(data: Data()) }
    }
}
