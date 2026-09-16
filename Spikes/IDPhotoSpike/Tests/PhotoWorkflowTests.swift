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
        model.install(try await fixture(), mode: .add)
        model.prepareExport()
        await pipeline.waitForExport()
        model.cancel()
        let result = PhotoExport(id: UUID(), jpegs: [URL(fileURLWithPath: "/unused.jpg")], pdf: URL(fileURLWithPath: "/unused.pdf"),
                                 pages: [], layout: PrintLayout(pages: [], unplaced: [:]))
        await pipeline.completeExport(with: result)
        await pipeline.waitForExportDiscard(result.id)
        #expect(model.exported == nil)
        #expect(model.activity == nil)
    }

    @Test func addingASecondPersonKeepsTheFirstAndGivesEachTheirOwnCopies() async throws {
        let pipeline = DelayedPipeline()
        let model = PhotoWorkflow(pipeline: pipeline)
        let first = try await fixture(), second = try await fixture()
        model.install(first, mode: .add)
        model.adjustment.zoom = 2
        model.install(second, mode: .add)
        #expect(model.entries.map(\.id) == [first.id, second.id])
        #expect(model.selectedID == second.id)
        #expect(model.adjustment.zoom == 1)
        #expect(model.printItems(for: first.id).map(\.copies) == [8])
        #expect(model.printItems(for: second.id).map(\.copies) == [4])
        #expect(model.label(for: second.id) == "Photo 2")
        model.selectedID = first.id
        #expect(model.adjustment.zoom == 2)
        // Export hands over every person, in session order.
        model.prepareExport()
        await pipeline.waitForExport()
        #expect(await pipeline.exportedEdits == [[first.id, second.id]])
        model.cancel()
    }

    @Test func removingTheSelectedPersonDropsTheirCopiesAndSelectsTheNeighbour() async throws {
        let pipeline = DelayedPipeline()
        let model = PhotoWorkflow(pipeline: pipeline)
        let first = try await fixture(), second = try await fixture(), third = try await fixture()
        for photo in [first, second, third] { model.install(photo, mode: .add) }
        model.addPrintItem(format: .europe35x45, photoID: second.id)
        model.selectedID = second.id
        model.removePhoto()
        #expect(model.entries.map(\.id) == [first.id, third.id])
        #expect(model.selectedID == third.id)
        #expect(model.printJob.items.allSatisfy { $0.photoID != second.id })
        #expect(model.printJob.items.count == 2)
        await pipeline.waitForPhotoDiscard(second.id)
        model.selectedID = third.id
        model.removePhoto()
        model.removePhoto()
        #expect(model.entries.isEmpty && model.selectedID == nil && model.printJob.items.isEmpty)
    }

    @Test func replacingAPersonKeepsTheirSizesAndCopies() async throws {
        let pipeline = DelayedPipeline()
        let model = PhotoWorkflow(pipeline: pipeline)
        let first = try await fixture(), replacement = try await fixture()
        model.install(first, mode: .add)
        model.addPrintItem(format: .europe35x45)
        model.printJob.items[0].copies = 6
        model.install(replacement, mode: .replace)
        #expect(model.entries.map(\.id) == [replacement.id])
        #expect(model.printItems(for: replacement.id).map(\.copies) == [6, 4])
        await pipeline.waitForPhotoDiscard(first.id)
    }

    @Test func sixPeopleIsTheLimit() async throws {
        let model = PhotoWorkflow(pipeline: DelayedPipeline())
        for _ in 0..<PhotoWorkflow.maxPhotos { model.install(try await fixture(), mode: .add) }
        #expect(!model.canAddPhoto)
        let extra = try await fixture()
        model.install(extra, mode: .add)
        // The seventh replaces the selected (sixth) one rather than growing the session.
        #expect(model.entries.count == PhotoWorkflow.maxPhotos && model.entries.last?.id == extra.id)
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
    func segment(photo: PreparedPhoto, faceBox: NormalizedCrop?, faceCenter: ImagePoint?) async -> SegmentationResult? { nil }
    func previewImage(photo: PreparedPhoto, adjustment: CropAdjustment) async -> CGImage { photo.preview }
    func toneMetrics(photo: PreparedPhoto, adjustment: CropAdjustment, faceBox: NormalizedCrop?) async -> ToneMetrics {
        ToneMetrics(faceMeanLuminance: 0.5, faceClippedDark: 0, faceClippedBright: 0, backgroundCast: 0)
    }
    func thumbnail(photo: PreparedPhoto, adjustment: CropAdjustment, format: PhotoFormat) async -> CGImage? { nil }
    func export(edits: [PhotoEdit], job: PrintJob) async throws -> PhotoExport {
        exportedEdits.append(edits.map(\.photo.id))
        return try await withCheckedThrowingContinuation { pendingExport = $0 }
    }
    private(set) var exportedEdits: [[UUID]] = []
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
