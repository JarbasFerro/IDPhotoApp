import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class PhotoWorkflow {
    var photo: PreparedPhoto?
    var adjustment = CropAdjustment()
    var printJob = PrintJob(paper: .photo10x15, items: [])
    private(set) var analysis: FaceAnalysis?
    private(set) var isAnalyzing = false
    private(set) var segmentation: SegmentationResult?
    private(set) var isSegmenting = false
    /// Preview with the chosen background and tone applied; nil means show the plain preview.
    private(set) var backgroundPreview: CGImage?
    /// Exposure and colour-cast assessment of the current preview.
    private(set) var toneAssessment: ToneAssessment?
    /// When true the editor shows the untouched preview (before/after comparison).
    var showsOriginal = false
    let policy = DocumentPolicy.spainEngineering
    /// Vision could not run (for example in the simulator); manual crop remains available.
    private(set) var analysisUnavailable = false
    var exported: PhotoExport?
    var errorMessage: String?
    /// Timings from the last in-app capture, shown in debug builds for the camera spike.
    var lastCameraMetrics: CameraMetrics?
    private(set) var activity: Activity?
    private(set) var isInitialized = false

    enum Activity { case importing, exporting }

    @ObservationIgnored private let pipeline: any PhotoProcessing
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?
    @ObservationIgnored private var revision = UUID()
    @ObservationIgnored private var exportLease: UUID?

    init(pipeline: any PhotoProcessing) { self.pipeline = pipeline }

    func setInitialized() { isInitialized = true }

    /// Solved on demand; the solver is deterministic and takes microseconds for spike-sized jobs.
    var layout: PrintLayout { PrintLayoutSolver.solve(printJob) }

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
                resetPrintJob(for: result)
                activity = nil
                analyze(result)
                if let previous { await pipeline.discard(photoID: previous.id) }
            } catch {
                handle(error, revision: currentRevision)
            }
        }
    }

    /// Runs Vision on the bounded preview and applies the automatic composition once per photo.
    private func analyze(_ photo: PreparedPhoto) {
        analysisTask?.cancel()
        analysis = nil
        analysisUnavailable = false
        isAnalyzing = true
        segmentation = nil
        backgroundPreview = nil
        isSegmenting = true
        analysisTask = Task {
            let result = try? await pipeline.analyze(photo: photo)
            guard !Task.isCancelled, self.photo?.id == photo.id else { return }
            isAnalyzing = false
            analysis = result
            analysisUnavailable = result == nil
            if let solution = result?.solution, result?.faceCount == 1 {
                adjustment = solution.adjustment
            }
            let geometry = result?.geometry
            let segmented = await pipeline.segment(photo: photo, faceBox: geometry?.faceBox, faceCenter: geometry?.eyeMidpoint)
            guard !Task.isCancelled, self.photo?.id == photo.id else { return }
            isSegmenting = false
            segmentation = segmented
            // Spain requires white; offer it by default when the mask is trustworthy and the original is not already plain.
            if let segmented, segmented.quality.state == .pass, segmented.background.state != .pass {
                adjustment.background = .color(.white)
            }
            adjustment.tone = policy.alteration == .allowed ? ToneSettings() : .off
            refreshBackgroundPreview()
        }
    }

    var canReplaceBackground: Bool {
        guard let segmentation else { return false }
        return segmentation.quality.state != .fail
    }

    var canAdjustTone: Bool { policy.alteration != .forbidden && photo != nil }

    /// Recomposites the preview when the background choice, softness, or tone changes.
    func refreshBackgroundPreview() {
        previewTask?.cancel()
        guard let photo else { backgroundPreview = nil; toneAssessment = nil; return }
        var edits = adjustment
        if case .color = edits.background, !canReplaceBackground { edits.background = .original }
        let needsWork = edits.tone.isEnabled || { if case .color = edits.background { return true } else { return false } }()
        let faceBox = analysis?.geometry?.faceBox
        previewTask = Task {
            let image = needsWork ? await pipeline.previewImage(photo: photo, adjustment: edits) : nil
            let metrics = await pipeline.toneMetrics(photo: photo, adjustment: edits, faceBox: faceBox)
            guard !Task.isCancelled, self.photo?.id == photo.id, self.adjustment.background == edits.background,
                  self.adjustment.edgeSoftness == edits.edgeSoftness, self.adjustment.tone == edits.tone else { return }
            backgroundPreview = image
            toneAssessment = ToneAssessment.assess(metrics)
        }
    }

    /// Automatic composition when a single face was found; otherwise the default crop.
    var automaticAdjustment: CropAdjustment {
        analysis?.faceCount == 1 ? (analysis?.solution?.adjustment ?? CropAdjustment()) : CropAdjustment()
    }

    func resetCrop() {
        let background = adjustment.background, softness = adjustment.edgeSoftness, tone = adjustment.tone
        adjustment = automaticAdjustment
        adjustment.background = background
        adjustment.edgeSoftness = softness
        adjustment.tone = tone
    }

    func prepareExport() {
        guard let photo, activity == nil else { return }
        cancelWork()
        let currentRevision = revision
        let edits = adjustment
        let job = printJob
        activity = .exporting
        errorMessage = nil
        task = Task {
            do {
                let result = try await pipeline.export(photo: photo, adjustment: edits, job: job)
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

    /// Cancels import/export work only; a running face analysis for the current photo continues.
    private func cancelWork() {
        revision = UUID()
        task?.cancel()
        task = nil
        activity = nil
    }

    func cancel() {
        cancelWork()
        analysisTask?.cancel()
        analysisTask = nil
        previewTask?.cancel()
        isAnalyzing = false
        isSegmenting = false
    }

    func removePhoto() {
        cancel()
        let previous = photo
        photo = nil
        adjustment = CropAdjustment()
        analysis = nil
        analysisUnavailable = false
        segmentation = nil
        backgroundPreview = nil
        toneAssessment = nil
        showsOriginal = false
        printJob.items = []
        if let previous { Task { await pipeline.discard(photoID: previous.id) } }
    }

    // MARK: - Print job editing

    func resetPrintJob(for photo: PreparedPhoto) {
        printJob = PrintJob(paper: printJob.paper, items: [
            PrintItem(photoID: photo.id, trimWidthMM: PhotoFormat.spainPrototype.widthMM,
                      trimHeightMM: PhotoFormat.spainPrototype.heightMM, copies: 8)
        ], options: printJob.options)
    }

    func addPrintItem(format: PhotoFormat) {
        guard let photo else { return }
        printJob.items.append(PrintItem(photoID: photo.id, trimWidthMM: format.widthMM,
                                        trimHeightMM: format.heightMM, copies: 4))
    }

    func removePrintItems(at offsets: IndexSet) {
        printJob.items.remove(atOffsets: offsets)
    }

    func movePrintItems(from source: IndexSet, to destination: Int) {
        printJob.items.move(fromOffsets: source, toOffset: destination)
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
