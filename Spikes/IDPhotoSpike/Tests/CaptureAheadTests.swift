import Foundation
import Testing
@testable import IDPhotoSpike

/// A camera still is prepared while the person reviews it (roadmap P2): Use Photo reuses that work, Retake drops it.
@MainActor
struct CaptureAheadTests {
    private func pipeline() async throws -> PhotoPipeline {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CaptureAheadTests-\(UUID().uuidString)")
        // No prepareSession(): it wipes the shared incoming folder that parallel tests stage into.
        return PhotoPipeline(root: root)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<500 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
    }

    @Test func usePhotoInstallsThePreparedStillAndRemovesTheCameraFile() async throws {
        let model = PhotoWorkflow(pipeline: try await pipeline(), credits: CreditStore(startingBalance: 1))
        let staged = try await SyntheticFixture.staged(width: 80, height: 100)
        model.prepareAhead(staged)
        model.useCapture(staged, mode: .replace)
        await waitUntil { model.entries.count == 1 && model.entries.first?.isAnalyzing == false }
        #expect(model.entries.count == 1)
        #expect(model.entries.first?.isAnalyzing == false)
        #expect(model.activity == nil)
        #expect(!FileManager.default.fileExists(atPath: staged.directory.path))
    }

    @Test func retakeLeavesTheSessionUntouchedAndANewStillImportsNormally() async throws {
        let model = PhotoWorkflow(pipeline: try await pipeline(), credits: CreditStore(startingBalance: 1))
        let first = try await SyntheticFixture.staged(width: 80, height: 100)
        model.prepareAhead(first)
        model.discardAhead()
        #expect(model.entries.isEmpty)
        // A still that was never prepared (or whose preparation was dropped) still goes through the ordinary import.
        let second = try await SyntheticFixture.staged(width: 80, height: 100)
        model.useCapture(second, mode: .replace)
        await waitUntil { model.entries.count == 1 && model.entries.first?.isAnalyzing == false }
        #expect(model.entries.count == 1)
        #expect(FileManager.default.fileExists(atPath: first.directory.path)) // the camera still owns its own file
    }
}
