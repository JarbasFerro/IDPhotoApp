import CoreGraphics
import Foundation
import Observation

/// One person's photo in the session with everything the editor knows about it.
struct PhotoEntry: Identifiable {
    let photo: PreparedPhoto
    var adjustment = CropAdjustment()
    var analysis: FaceAnalysis?
    /// Vision could not run (for example in the simulator); manual crop remains available.
    var analysisUnavailable = false
    var isAnalyzing = false
    var segmentation: SegmentationResult?
    var isSegmenting = false
    /// Preview with the chosen background and tone applied; nil means show the plain preview.
    var backgroundPreview: CGImage?
    /// Exposure and colour-cast assessment of the current preview.
    var toneAssessment: ToneAssessment?

    var id: UUID { photo.id }
}

@MainActor
@Observable
final class PhotoWorkflow {
    /// Photos in the session, in the order they were added. Every one can appear on the print sheet.
    private(set) var entries: [PhotoEntry] = []
    /// The photo the editor controls.
    var selectedID: UUID?
    /// Changes whenever a photo finishes importing, so the flow can move to its Photo Check.
    private(set) var lastInstalled: InstallEvent?

    struct InstallEvent: Hashable { let id: UUID; let sequence: Int }
    var printJob = PrintJob(paper: .photo4x6, items: [])
    /// Sheet-preview crops per print item, rendered on demand.
    private(set) var sheetThumbnails: [UUID: CGImage] = [:]
    /// When true the editor shows the untouched preview (before/after comparison).
    var showsOriginal = false
    let policy = DocumentPolicy.spainEngineering
    var exported: PhotoExport?
    var errorMessage: String?
    /// Timings from the last in-app capture, shown in debug builds for the camera spike.
    var lastCameraMetrics: CameraMetrics?
    private(set) var activity: Activity?
    private(set) var isInitialized = false

    enum Activity { case importing, exporting }
    /// Whether an incoming photo replaces the selected one or joins the session as another person.
    enum ImportMode { case replace, add }

    static let maxPhotos = 6

    @ObservationIgnored private let pipeline: any PhotoProcessing
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var analysisTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var previewTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored private var thumbnailTask: Task<Void, Never>?
    @ObservationIgnored private var revision = UUID()
    @ObservationIgnored private var exportLease: UUID?

    init(pipeline: any PhotoProcessing) { self.pipeline = pipeline }

    func setInitialized() { isInitialized = true }

    // MARK: - Selected entry

    private var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return entries.firstIndex { $0.id == selectedID }
    }

    private func index(of photoID: UUID) -> Int? { entries.firstIndex { $0.id == photoID } }

    var selected: PhotoEntry? { selectedIndex.map { entries[$0] } }
    var photo: PreparedPhoto? { selected?.photo }
    var adjustment: CropAdjustment {
        get { selected?.adjustment ?? CropAdjustment() }
        set { if let index = selectedIndex { entries[index].adjustment = newValue } }
    }
    var analysis: FaceAnalysis? { selected?.analysis }
    var analysisUnavailable: Bool { selected?.analysisUnavailable ?? false }
    var isAnalyzing: Bool { selected?.isAnalyzing ?? false }
    var segmentation: SegmentationResult? { selected?.segmentation }
    var isSegmenting: Bool { selected?.isSegmenting ?? false }
    var backgroundPreview: CGImage? { selected?.backgroundPreview }
    var toneAssessment: ToneAssessment? { selected?.toneAssessment }
    var canAddPhoto: Bool { entries.count < Self.maxPhotos }

    /// "Photo 2" style label; positions are stable while the session lasts.
    func label(for photoID: UUID) -> String {
        guard let index = index(of: photoID) else { return String(localized: "Photo") }
        return String(localized: "Photo \(index + 1)")
    }

    /// Solved on demand; the solver is deterministic and takes microseconds for spike-sized jobs.
    var layout: PrintLayout { PrintLayoutSolver.solve(printJob) }

    // MARK: - Import

    func importPhoto(mode: ImportMode = .replace, loader: @escaping @Sendable () async throws -> StagedPhoto?) {
        cancelWork()
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
                activity = nil
                install(result, mode: mode)
            } catch {
                handle(error, revision: currentRevision)
            }
        }
    }

    /// Adds `photo` to the session (or replaces the selected one), selects it, and starts its analysis.
    func install(_ photo: PreparedPhoto, mode: ImportMode) {
        let entry = PhotoEntry(photo: photo)
        if mode == .add, canAddPhoto || selectedIndex == nil {
            entries.append(entry)
            appendDefaultPrintItem(for: photo, copies: entries.count == 1 ? 8 : 4)
        } else if let index = selectedIndex {
            let previous = entries[index]
            stopWork(for: previous.id)
            entries[index] = entry
            // The replacement inherits the sizes and copies chosen for the person it replaces.
            for itemIndex in printJob.items.indices where printJob.items[itemIndex].photoID == previous.id {
                printJob.items[itemIndex].photoID = photo.id
            }
            Task { await pipeline.discard(photoID: previous.id) }
        } else {
            entries.append(entry)
            appendDefaultPrintItem(for: photo, copies: 8)
        }
        selectedID = photo.id
        showsOriginal = false
        lastInstalled = InstallEvent(id: photo.id, sequence: (lastInstalled?.sequence ?? 0) + 1)
        analyze(photo)
    }

    /// Runs Vision on the bounded preview and applies the automatic composition once per photo.
    private func analyze(_ photo: PreparedPhoto) {
        analysisTasks[photo.id]?.cancel()
        update(photo.id) { $0.analysis = nil; $0.analysisUnavailable = false; $0.isAnalyzing = true
                            $0.segmentation = nil; $0.backgroundPreview = nil; $0.isSegmenting = true }
        analysisTasks[photo.id] = Task { [policy] in
            let result = try? await pipeline.analyze(photo: photo)
            guard !Task.isCancelled, index(of: photo.id) != nil else { return }
            update(photo.id) {
                $0.isAnalyzing = false
                $0.analysis = result
                $0.analysisUnavailable = result == nil
                if let solution = result?.solution, result?.faceCount == 1 { $0.adjustment = solution.adjustment }
            }
            let geometry = result?.geometry
            let segmented = await pipeline.segment(photo: photo, faceBox: geometry?.faceBox, faceCenter: geometry?.eyeMidpoint)
            guard !Task.isCancelled, index(of: photo.id) != nil else { return }
            update(photo.id) {
                $0.isSegmenting = false
                $0.segmentation = segmented
                // Spain requires white; offer it by default when the mask is trustworthy and the original is not already plain.
                if let segmented, segmented.quality.state == .pass, segmented.background.state != .pass {
                    $0.adjustment.background = .color(.white)
                }
                $0.adjustment.tone = policy.alteration == .allowed ? ToneSettings() : .off
            }
            refreshBackgroundPreview(for: photo.id)
        }
    }

    private func update(_ photoID: UUID, _ change: (inout PhotoEntry) -> Void) {
        guard let index = index(of: photoID) else { return }
        change(&entries[index])
    }

    var canReplaceBackground: Bool {
        guard let segmentation else { return false }
        return segmentation.quality.state != .fail
    }

    var canAdjustTone: Bool { policy.alteration != .forbidden && photo != nil }

    /// Recomposites the selected photo's preview when the background choice, softness, or tone changes.
    func refreshBackgroundPreview() {
        guard let selectedID else { return }
        refreshBackgroundPreview(for: selectedID)
    }

    private func refreshBackgroundPreview(for photoID: UUID) {
        previewTasks[photoID]?.cancel()
        guard let index = index(of: photoID) else { return }
        let entry = entries[index]
        var edits = entry.adjustment
        let canReplace = entry.segmentation.map { $0.quality.state != .fail } ?? false
        if case .color = edits.background, !canReplace { edits.background = .original }
        let needsWork = edits.tone.isEnabled || { if case .color = edits.background { return true } else { return false } }()
        let faceBox = entry.analysis?.geometry?.faceBox
        let photo = entry.photo
        previewTasks[photoID] = Task {
            let image = needsWork ? await pipeline.previewImage(photo: photo, adjustment: edits) : nil
            let metrics = await pipeline.toneMetrics(photo: photo, adjustment: edits, faceBox: faceBox)
            guard !Task.isCancelled, let current = self.index(of: photoID) else { return }
            let now = entries[current].adjustment
            guard now.background == edits.background, now.edgeSoftness == edits.edgeSoftness, now.tone == edits.tone else { return }
            entries[current].backgroundPreview = image
            entries[current].toneAssessment = ToneAssessment.assess(metrics)
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

    // MARK: - Export

    func prepareExport() {
        guard !entries.isEmpty, activity == nil else { return }
        cancelWork()
        let currentRevision = revision
        let edits = entries.map { PhotoEdit(photo: $0.photo, adjustment: $0.adjustment) }
        let job = printJob
        activity = .exporting
        errorMessage = nil
        task = Task {
            do {
                let result = try await pipeline.export(edits: edits, job: job)
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

    // MARK: - Cancellation and removal

    /// Cancels import/export work only; running analyses continue.
    private func cancelWork() {
        revision = UUID()
        task?.cancel()
        task = nil
        activity = nil
    }

    private func stopWork(for photoID: UUID) {
        analysisTasks[photoID]?.cancel()
        analysisTasks[photoID] = nil
        previewTasks[photoID]?.cancel()
        previewTasks[photoID] = nil
    }

    /// Cancels everything in flight; entries keep whatever results have already arrived.
    func cancel() {
        cancelWork()
        for id in Set(analysisTasks.keys).union(previewTasks.keys) { stopWork(for: id) }
        thumbnailTask?.cancel()
        for index in entries.indices { entries[index].isAnalyzing = false; entries[index].isSegmenting = false }
    }

    /// Removes the selected photo and its print items; the neighbour becomes selected.
    func removePhoto() {
        guard let index = selectedIndex else { return }
        cancelWork()
        let removed = entries.remove(at: index)
        stopWork(for: removed.id)
        printJob.items.removeAll { $0.photoID == removed.id }
        sheetThumbnails = sheetThumbnails.filter { key, _ in printJob.items.contains { $0.id == key } }
        selectedID = entries.isEmpty ? nil : entries[min(index, entries.count - 1)].id
        showsOriginal = false
        Task { await pipeline.discard(photoID: removed.id) }
    }

    // MARK: - Print job editing

    private func appendDefaultPrintItem(for photo: PreparedPhoto, copies: Int) {
        printJob.items.append(PrintItem(photoID: photo.id, trimWidthMM: PhotoFormat.spainPrototype.widthMM,
                                        trimHeightMM: PhotoFormat.spainPrototype.heightMM, copies: copies))
    }

    func addPrintItem(format: PhotoFormat, photoID: UUID? = nil) {
        guard let photoID = photoID ?? selectedID, index(of: photoID) != nil else { return }
        printJob.items.append(PrintItem(photoID: photoID, trimWidthMM: format.widthMM,
                                        trimHeightMM: format.heightMM, copies: 4))
    }

    func printItems(for photoID: UUID) -> [PrintItem] { printJob.items.filter { $0.photoID == photoID } }

    func removePrintItems(at offsets: IndexSet) {
        printJob.items.remove(atOffsets: offsets)
    }

    func removePrintItem(id: UUID) {
        printJob.items.removeAll { $0.id == id }
        sheetThumbnails[id] = nil
    }

    func movePrintItems(from source: IndexSet, to destination: Int) {
        printJob.items.move(fromOffsets: source, toOffset: destination)
    }

    /// Renders (or re-renders) the small crops the sheet preview draws inside each placement.
    func refreshSheetThumbnails() {
        thumbnailTask?.cancel()
        let items = printJob.items
        let edits = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, PhotoEdit(photo: $0.photo, adjustment: $0.adjustment)) })
        thumbnailTask = Task {
            var result: [UUID: CGImage] = [:]
            for item in items {
                guard let edit = edits[item.photoID] else { continue }
                let format = PhotoFormat.format(widthMM: item.trimWidthMM, heightMM: item.trimHeightMM)
                if let image = await pipeline.thumbnail(photo: edit.photo, adjustment: edit.adjustment, format: format) {
                    result[item.id] = image
                }
                if Task.isCancelled { return }
            }
            sheetThumbnails = result
        }
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
