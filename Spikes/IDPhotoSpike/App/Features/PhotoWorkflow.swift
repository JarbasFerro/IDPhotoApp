import Foundation
import Observation

@MainActor
@Observable
final class PhotoWorkflow {
    var photo: PreparedPhoto?
    var adjustment = CropAdjustment()
    var exported: PhotoExport?
    var errorMessage: String?
    private(set) var activity: Activity?
    private(set) var isInitialized = false

    enum Activity { case importing, exporting }

    @ObservationIgnored private let pipeline: any PhotoProcessing
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var revision = UUID()
    @ObservationIgnored private var exportLease: UUID?

    init(pipeline: any PhotoProcessing) { self.pipeline = pipeline }

    func setInitialized() { isInitialized = true }

    func importPhoto(loader: @escaping @Sendable () async throws -> StagedPhoto?) {
        cancel()
        let currentRevision = revision
        activity = .importing
        errorMessage = nil
        task = Task {
            do {
                guard let staged = try await loader() else { throw PhotoError.unreadable }
                // ingest owns the staged directory even when already cancelled.
                let result = try await pipeline.ingest(staged)
                guard revision == currentRevision, !Task.isCancelled else {
                    await pipeline.discard(photoID: result.id)
                    return
                }
                let previous = photo
                photo = result
                adjustment = CropAdjustment()
                activity = nil
                if let previous { await pipeline.discard(photoID: previous.id) }
            } catch {
                handle(error, revision: currentRevision)
            }
        }
    }

    func prepareExport() {
        guard let photo, activity == nil else { return }
        cancel()
        let currentRevision = revision
        let edits = adjustment
        activity = .exporting
        errorMessage = nil
        task = Task {
            do {
                let result = try await pipeline.export(photo: photo, adjustment: edits)
                guard revision == currentRevision, !Task.isCancelled else {
                    await pipeline.discard(exportID: result.id)
                    return
                }
                exportLease = result.id
                exported = result
                activity = nil
            } catch {
                handle(error, revision: currentRevision)
            }
        }
    }

    func finishExport() {
        guard let id = exportLease else { return }
        exportLease = nil
        exported = nil
        Task { await pipeline.discard(exportID: id) }
    }

    func cancel() {
        revision = UUID()
        task?.cancel()
        task = nil
        activity = nil
    }

    func removePhoto() {
        cancel()
        let previous = photo
        photo = nil
        adjustment = CropAdjustment()
        if let previous { Task { await pipeline.discard(photoID: previous.id) } }
    }

    var sourceIsSmall: Bool {
        guard let photo else { return false }
        let crop = adjustment.crop(in: photo.pixels)
        let output = PhotoFormat.spainPrototype.output
        return Double(photo.pixels.width) * crop.width < Double(output.width)
            || Double(photo.pixels.height) * crop.height < Double(output.height)
    }

    private func handle(_ error: Error, revision currentRevision: UUID) {
        guard revision == currentRevision else { return }
        activity = nil
        if error is CancellationError { return }
        // Do not surface framework errors, which can contain sensitive local file paths.
        errorMessage = (error as? PhotoError)?.errorDescription
            ?? String(localized: "The operation could not be completed. Try again or choose another photo.")
    }
}
