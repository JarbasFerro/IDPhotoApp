import CoreGraphics
import Foundation
import Testing
@testable import IDPhotoSpike

@MainActor
struct PhotoWorkflowTests {
    @Test func lateImportCannotOverwriteReplacement() async throws {
        let pipeline = DelayedPipeline()
        let model = PhotoWorkflow(pipeline: pipeline)
        let first = try await fixture()
        let second = try await fixture()
        model.importPhoto { StagedPhoto(directory: URL(fileURLWithPath: "/unused-first")) }
        await pipeline.waitForImports(1)
        model.importPhoto { StagedPhoto(directory: URL(fileURLWithPath: "/unused-second")) }
        await pipeline.waitForImports(2)
        await pipeline.completeImport(index: 1, with: second)
        await waitUntil { model.photo?.id == second.id }
        await pipeline.completeImport(index: 0, with: first)
        await pipeline.waitForPhotoDiscard(first.id)
        #expect(model.photo?.id == second.id)
        #expect(model.activity == nil)
    }

    @Test func cancelledExportCannotPresentAFileAndIsDiscarded() async throws {
        let pipeline = DelayedPipeline()
        let model = PhotoWorkflow(pipeline: pipeline)
        model.photo = try await fixture()
        model.prepareExport()
        await pipeline.waitForExport()
        model.cancel()
        let result = PhotoExport(id: UUID(), jpeg: URL(fileURLWithPath: "/unused.jpg"), pdf: URL(fileURLWithPath: "/unused.pdf"),
                                 pages: [], layout: PrintLayout(pages: [], unplaced: [:]))
        await pipeline.completeExport(with: result)
        await pipeline.waitForExportDiscard(result.id)
        #expect(model.exported == nil)
        #expect(model.activity == nil)
    }

    private func fixture() async throws -> PreparedPhoto {
        let staged = try await SyntheticFixture.staged(width: 80, height: 100)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        return try await PhotoPipeline(root: root).ingest(staged)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<10_000 {
            if condition() { return }
            await Task.yield()
        }
        Issue.record("Workflow did not reach expected state")
    }
}

private actor DelayedPipeline: PhotoProcessing {
    private var imports: [CheckedContinuation<PreparedPhoto, any Error>] = []
    private var pendingExport: CheckedContinuation<PhotoExport, any Error>?
    private var discardedPhotos: Set<UUID> = []
    private var discardedExports: Set<UUID> = []

    func ingest(_ staged: StagedPhoto) async throws -> PreparedPhoto {
        // Intentionally ignores cancellation, like a framework callback arriving late.
        try await withCheckedThrowingContinuation { imports.append($0) }
    }
    func analyze(photo: PreparedPhoto) async throws -> FaceAnalysis {
        FaceAnalysis(faceCount: 0, geometry: nil, solution: nil, visionRollDegrees: nil)
    }
    func export(photo: PreparedPhoto, adjustment: CropAdjustment, job: PrintJob) async throws -> PhotoExport {
        try await withCheckedThrowingContinuation { pendingExport = $0 }
    }
    func discard(photoID: UUID) { discardedPhotos.insert(photoID) }
    func discard(exportID: UUID) { discardedExports.insert(exportID) }
    func completeImport(index: Int, with result: PreparedPhoto) { imports[index].resume(returning: result) }
    func completeExport(with result: PhotoExport) { pendingExport?.resume(returning: result); pendingExport = nil }

    func waitForImports(_ count: Int) async {
        for _ in 0..<10_000 { if imports.count >= count { return }; await Task.yield() }
        Issue.record("Import did not start")
    }
    func waitForExport() async {
        for _ in 0..<10_000 { if pendingExport != nil { return }; await Task.yield() }
        Issue.record("Export did not start")
    }
    func waitForPhotoDiscard(_ id: UUID) async {
        for _ in 0..<10_000 { if discardedPhotos.contains(id) { return }; await Task.yield() }
        Issue.record("Stale photo was not discarded")
    }
    func waitForExportDiscard(_ id: UUID) async {
        for _ in 0..<10_000 { if discardedExports.contains(id) { return }; await Task.yield() }
        Issue.record("Stale export was not discarded")
    }
}
