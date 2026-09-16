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
