import CoreGraphics
import Foundation
import Observation
import OSLog

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
    /// Closer or wider framing; applies to custom sizes only (official profiles keep their own target).
    var framing: FramingPreset = .standard
    /// Unlocked with a credit (ADR-048): every output of this photo is free, and its look is final until it is
    /// edited again, which locks it.
    var isUnlocked = false

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
    /// The document every photo in the session is made for. Changing it re-frames each photo (setDocument).
    private(set) var document: DocumentChoice
    /// Editing is offered on every profile (ADR-051); the replacement colour comes from the document.
    var policy: DocumentPolicy { DocumentPolicy(alteration: .allowed, background: document.backgroundColor) }
    var renderTarget: RenderTarget { document.renderTarget }
    var exported: PhotoExport?
    var digitalExport: DigitalExport?
    var errorMessage: String?
    private(set) var errorActivity: Activity?
    /// Timings from the last in-app capture, shown in debug builds.
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
    @ObservationIgnored private let signposter = OSSignposter(subsystem: "com.jarbasferro.calipic", category: "Workflow")

    /// The person's credits. One credit unlocks one photo (ADR-048).
    let credits: CreditStore

    init(pipeline: any PhotoProcessing, document: DocumentChoice = .initial, credits: CreditStore? = nil) {
        self.pipeline = pipeline
        self.document = document
        self.credits = credits ?? CreditStore()
    }

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
        // An unlocked photo's look is final: edits reach it only after `relock`.
        set { if let index = selectedIndex, !entries[index].isUnlocked { entries[index].adjustment = newValue } }
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

    /// Solved on demand; the solver is deterministic and takes microseconds for these jobs.
    var layout: PrintLayout { PrintLayoutSolver.solve(printJob) }

    // MARK: - Import

    func importPhoto(mode: ImportMode = .replace, loader: @escaping @Sendable () async throws -> StagedPhoto?) {
        cancelWork()
        let currentRevision = revision
        activity = .importing
        errorMessage = nil
        errorActivity = nil
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

    // MARK: - A camera still prepared during its review (roadmap P2)

    /// The still the person is looking at, ingested and analysed from a private copy while they decide.
    /// It joins the session only on Use Photo; Retake or Cancel throws it away.
    private struct Ahead {
        let key: URL
        let task: Task<(photo: PreparedPhoto, measured: FaceAnalysis?)?, Never>
    }
    @ObservationIgnored private var ahead: Ahead?

    #if DEBUG
    /// UI tests on a simulator, where Vision cannot run: "--uitesting-measured" gives every photo this synthetic face
    /// so the measuring lines and the framed result can be reviewed in screenshots. Never used in release builds.
    var debugSyntheticFace = false

    /// Landmarks of the local test portrait; used in place of the centred synthetic face when present.
    var debugLocalFace: LocalPortrait.Face?

    static func syntheticAnalysis(for source: SourcePixels, face: LocalPortrait.Face) -> FaceAnalysis {
        let w = Double(source.width), h = Double(source.height)
        func pixels(_ p: [Double]) -> ImagePoint { ImagePoint(x: p[0] * w, y: p[1] * h) }
        let left = pixels(face.leftEye), right = pixels(face.rightEye), chin = pixels(face.chin)
        let iedPx = hypot(left.x - right.x, left.y - right.y)
        let frame = HeadFrame(center: ImagePoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2),
                              angleRadians: atan2(left.y - right.y, left.x - right.x))
        let eyeToChin = frame.toAligned(chin).y
        let crown = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: -frame.toAligned(pixels(face.crown)).y,
                                            interEyeDistancePixels: iedPx)
        let box = NormalizedCrop(x: (frame.center.x - iedPx) / w, y: (frame.center.y - 0.7 * iedPx) / h,
                                 width: 2 * iedPx / w, height: (0.7 * iedPx + eyeToChin) / h)
        let geometry = FaceGeometry(source: source, faceCount: 1, faceBox: box,
                                    leftEye: ImagePoint(x: face.leftEye[0], y: face.leftEye[1]),
                                    rightEye: ImagePoint(x: face.rightEye[0], y: face.rightEye[1]),
                                    chin: ImagePoint(x: face.chin[0], y: face.chin[1]), crown: crown, eyeToChinPixels: eyeToChin,
                                    yawDegrees: 0, pitchDegrees: 0)
        return FaceAnalysis(faceCount: 1, geometry: geometry, solution: nil, visionRollDegrees: frame.rollDegrees)
    }

    static func syntheticAnalysis(for source: SourcePixels) -> FaceAnalysis {
        let w = Double(source.width), h = Double(source.height)
        let iedPx = 0.16 * w, eyeToChin = 1.25 * iedPx
        let frame = HeadFrame(center: ImagePoint(x: 0.5 * w, y: 0.42 * h), angleRadians: 0)
        let left = frame.toImage(ImagePoint(x: iedPx / 2, y: 0)), right = frame.toImage(ImagePoint(x: -iedPx / 2, y: 0))
        let chin = frame.toImage(ImagePoint(x: 0, y: eyeToChin))
        let crown = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: 0.8 * eyeToChin, interEyeDistancePixels: iedPx)
        let geometry = FaceGeometry(source: source, faceCount: 1,
                                    faceBox: NormalizedCrop(x: 0.34, y: 0.3, width: 0.32, height: 0.3),
                                    leftEye: ImagePoint(x: left.x / w, y: left.y / h), rightEye: ImagePoint(x: right.x / w, y: right.y / h),
                                    chin: ImagePoint(x: chin.x / w, y: chin.y / h), crown: crown, eyeToChinPixels: eyeToChin,
                                    yawDegrees: 0, pitchDegrees: 0)
        return FaceAnalysis(faceCount: 1, geometry: geometry, solution: nil, visionRollDegrees: 0)
    }
    #endif

    /// Loads the face model early; call when the camera opens.
    func warmUp() {
        let pipeline = self.pipeline
        Task { await pipeline.warmUp() }
    }

    /// Starts on a copy of the still, so the camera's own file stays valid for Use Photo or a normal import.
    func prepareAhead(_ staged: StagedPhoto) {
        discardAhead()
        let pipeline = self.pipeline
        let source = staged.url
        let task = Task { () -> (photo: PreparedPhoto, measured: FaceAnalysis?)? in
            guard let copy = try? await StagedPhoto.stage(source) else { return nil }
            guard let photo = try? await pipeline.ingest(copy) else { return nil }
            guard !Task.isCancelled else { await pipeline.discard(photoID: photo.id); return nil }
            let measured = try? await pipeline.analyze(photo: photo)
            guard !Task.isCancelled else { await pipeline.discard(photoID: photo.id); return nil }
            return (photo, measured)
        }
        ahead = Ahead(key: staged.directory, task: task)
    }

    /// Retake, Cancel, or the camera closing: the prepared copy is deleted.
    func discardAhead() {
        guard let pending = ahead else { return }
        ahead = nil
        pending.task.cancel()
        let pipeline = self.pipeline
        Task { if let result = await pending.task.value { await pipeline.discard(photoID: result.photo.id) } }
    }

    /// Use Photo. When the still was prepared during the review, its analysis is reused; otherwise a normal import.
    func useCapture(_ staged: StagedPhoto, mode: ImportMode) {
        guard let pending = ahead, pending.key == staged.directory else {
            discardAhead()
            importPhoto(mode: mode) { staged }
            return
        }
        ahead = nil
        cancelWork()
        let currentRevision = revision
        activity = .importing
        errorMessage = nil
        errorActivity = nil
        task = Task {
            guard let result = await pending.task.value else {
                // The early work failed (or was cancelled): fall back to the ordinary path with the camera's file.
                guard revision == currentRevision else { try? FileManager.default.removeItem(at: staged.directory); return }
                activity = nil
                importPhoto(mode: mode) { staged }
                return
            }
            try? FileManager.default.removeItem(at: staged.directory)
            guard revision == currentRevision, !Task.isCancelled else {
                await pipeline.discard(photoID: result.photo.id)
                return
            }
            activity = nil
            install(result.photo, mode: mode, measured: .some(result.measured))
        }
    }

    /// Adds `photo` to the session (or replaces the selected one), selects it, and starts its analysis.
    /// `measured` carries an analysis already done during the camera review (`.some(nil)` means it found nothing).
    func install(_ photo: PreparedPhoto, mode: ImportMode, measured: FaceAnalysis?? = nil) {
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
        analyze(photo, measured: measured)
    }

    /// Runs Vision on the bounded preview and applies the automatic composition once per photo.
    private func analyze(_ photo: PreparedPhoto, measured premeasured: FaceAnalysis?? = nil) {
        analysisTasks[photo.id]?.cancel()
        update(photo.id) { $0.analysis = nil; $0.analysisUnavailable = false; $0.isAnalyzing = true
                            $0.segmentation = nil; $0.backgroundPreview = nil; $0.isSegmenting = true }
        analysisTasks[photo.id] = Task {
            let verdictInterval = signposter.beginInterval("Verdict", id: signposter.makeSignpostID())
            var measured: FaceAnalysis?
            if let premeasured { measured = premeasured } else { measured = try? await pipeline.analyze(photo: photo) }
            #if DEBUG
            if debugSyntheticFace {
                // The portrait's landmarks belong to the first photo only.
                if let face = debugLocalFace, entries.first?.id == photo.id {
                    measured = Self.syntheticAnalysis(for: photo.pixels, face: face)
                } else {
                    measured = Self.syntheticAnalysis(for: photo.pixels)
                }
            }
            #endif
            guard !Task.isCancelled, index(of: photo.id) != nil else { signposter.endInterval("Verdict", verdictInterval); return }
            // Solve for the document chosen now, not when the analysis started (it may have changed meanwhile).
            guard let entry = entries.first(where: { $0.id == photo.id }) else { signposter.endInterval("Verdict", verdictInterval); return }
            let result = measured.map { Self.resolved($0, for: target(for: entry)) }
            update(photo.id) {
                $0.isAnalyzing = false
                $0.analysis = result
                $0.analysisUnavailable = result == nil
                if let solution = result?.solution, result?.faceCount == 1 { $0.adjustment = solution.adjustment }
            }
            signposter.endInterval("Verdict", verdictInterval)
            let geometry = result?.geometry
            let segmented = await pipeline.segment(photo: photo, faceBox: geometry?.faceBox, faceCenter: geometry?.eyeMidpoint)
            guard !Task.isCancelled, index(of: photo.id) != nil else { return }
            update(photo.id) {
                $0.isSegmenting = false
                $0.segmentation = segmented
                // Offer the document's colour by default when the mask is trustworthy and the original is not already plain.
                if let segmented, segmented.quality.state == .pass, segmented.background.state != .pass {
                    $0.adjustment.background = .color(policy.background)
                }
                $0.adjustment.tone = policy.alteration == .allowed ? ToneSettings() : .off
            }
            refreshBackgroundPreview(for: photo.id)
        }
    }

    /// Re-runs the deterministic crop solver for `target` on already measured geometry; no Vision work.
    static func resolved(_ analysis: FaceAnalysis, for target: RenderTarget) -> FaceAnalysis {
        guard let geometry = analysis.geometry else { return analysis }
        return FaceAnalysis(faceCount: analysis.faceCount, geometry: geometry,
                            solution: CropSolver.solve(geometry: geometry, format: target.format, spec: target.spec),
                            visionRollDegrees: analysis.visionRollDegrees, lensSmudgeConfidence: analysis.lensSmudgeConfidence)
    }

    // MARK: - Credits and unlocking (ADR-048)

    /// People on the sheet who still need a credit before anything leaves the app.
    var lockedCount: Int { entries.filter { !$0.isUnlocked }.count }

    /// Spends one credit per locked photo among `ids` and unlocks them. Changes nothing and returns false when
    /// the balance is short. Already unlocked photos cost nothing.
    @discardableResult
    func unlock(_ ids: [UUID]) -> Bool {
        let locked = entries.filter { ids.contains($0.id) && !$0.isUnlocked }.map(\.id)
        guard credits.spend(locked.count) else { return false }
        for id in locked { update(id) { $0.isUnlocked = true } }
        return true
    }

    @discardableResult
    func unlockAll() -> Bool { unlock(entries.map(\.id)) }

    /// Makes a photo editable again. Its next output needs a new credit.
    func relock(_ photoID: UUID) {
        update(photoID) { $0.isUnlocked = false }
        finishExport()
    }

    // MARK: - Document

    /// Switches the session to another document: re-frames every analysed photo for it, moves the default
    /// print sizes along, recolours replaced backgrounds, and drops files made for the previous document.
    func setDocument(_ next: DocumentChoice) {
        guard next != document else { return }
        let previous = renderTarget.format
        cancelWork()
        finishExport()
        document = next
        let target = renderTarget
        for index in entries.indices {
            // Another document is another photo (ADR-048 §2): it is framed again and needs its own credit.
            entries[index].isUnlocked = false
            reframe(at: index)
            if case .color = entries[index].adjustment.background {
                entries[index].adjustment.background = .color(policy.background)
            }
            // Black and white is a custom-size option; official documents return to colour.
            if !next.isCustom { entries[index].adjustment.monochrome = false }
        }
        for index in printJob.items.indices
        where abs(printJob.items[index].trimWidthMM - previous.widthMM) < 0.001
            && abs(printJob.items[index].trimHeightMM - previous.heightMM) < 0.001 {
            printJob.items[index].trimWidthMM = target.format.widthMM
            printJob.items[index].trimHeightMM = target.format.heightMM
        }
        sheetThumbnails = [:]
        for entry in entries { refreshBackgroundPreview(for: entry.id) }
    }

    /// Back to the photo as taken: original background, no tone correction, colour. Framing is kept.
    func useOriginalLook(for photoID: UUID) {
        guard let index = index(of: photoID), !entries[index].isUnlocked else { return }
        update(photoID) {
            $0.adjustment.background = .original
            $0.adjustment.tone = .off
            $0.adjustment.monochrome = false
        }
        refreshBackgroundPreview(for: photoID)
    }

    /// The render target for one person: the document's, framed closer or wider for custom sizes.
    func target(for entry: PhotoEntry) -> RenderTarget {
        document.isCustom ? renderTarget.framed(entry.framing) : renderTarget
    }

    /// Changes how much of the person a custom-size photo shows, re-solving from the measured face.
    func setFraming(_ preset: FramingPreset, for photoID: UUID) {
        guard let index = index(of: photoID), entries[index].framing != preset, !entries[index].isUnlocked else { return }
        entries[index].framing = preset
        reframe(at: index)
        sheetThumbnails = [:]
    }

    /// Re-solves one entry's crop for its current target and keeps the person's look (background, tone, mono).
    private func reframe(at index: Int) {
        var entry = entries[index]
        guard let analysis = entry.analysis else { return }
        let solved = Self.resolved(analysis, for: target(for: entry))
        entry.analysis = solved
        if let solution = solved.solution, solved.faceCount == 1 {
            var adjustment = solution.adjustment
            adjustment.background = entry.adjustment.background
            adjustment.edgeSoftness = entry.adjustment.edgeSoftness
            adjustment.tone = entry.adjustment.tone
            adjustment.monochrome = entry.adjustment.monochrome
            entry.adjustment = adjustment
        }
        entries[index] = entry
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
        let needsWork = edits.tone.isEnabled || edits.monochrome
            || { if case .color = edits.background { return true } else { return false } }()
        let faceBox = entry.analysis?.geometry?.faceBox
        let photo = entry.photo
        previewTasks[photoID] = Task {
            let image = needsWork ? await pipeline.previewImage(photo: photo, adjustment: edits) : nil
            let metrics = await pipeline.toneMetrics(photo: photo, adjustment: edits, faceBox: faceBox)
            guard !Task.isCancelled, let current = self.index(of: photoID) else { return }
            let now = entries[current].adjustment
            guard now.background == edits.background, now.edgeSoftness == edits.edgeSoftness, now.tone == edits.tone,
                  now.monochrome == edits.monochrome else { return }
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
        let monochrome = adjustment.monochrome
        adjustment = automaticAdjustment
        adjustment.background = background
        adjustment.edgeSoftness = softness
        adjustment.tone = tone
        adjustment.monochrome = monochrome
    }

    // MARK: - Export

    /// The export gate: nothing is rendered for a locked photo (ADR-049 §3).
    func prepareExport() {
        guard !entries.isEmpty, activity == nil, lockedCount == 0 else { return }
        cancelWork()
        let currentRevision = revision
        let edits = entries.map { PhotoEdit(photo: $0.photo, adjustment: $0.adjustment) }
        let job = printJob
        let target = renderTarget
        activity = .exporting
        errorMessage = nil
        errorActivity = nil
        task = Task {
            let filesInterval = signposter.beginInterval("FilesReady", id: signposter.makeSignpostID())
            do {
                let result = try await pipeline.export(edits: edits, job: job, target: target)
                guard revision == currentRevision, !Task.isCancelled else {
                    signposter.endInterval("FilesReady", filesInterval)
                    await pipeline.discard(exportID: result.id)
                    return
                }
                exportLease = result.id
                exported = result
                signposter.endInterval("FilesReady", filesInterval)
                digitalExport = nil
                activity = nil
            } catch {
                signposter.endInterval("FilesReady", filesInterval)
                handle(error, revision: currentRevision)
            }
        }
    }

    func prepareDigitalExport(for photoID: UUID) {
        guard let entry = entries.first(where: { $0.id == photoID }), activity == nil, entry.isUnlocked else { return }
        cancelWork()
        let currentRevision = revision
        let edit = PhotoEdit(photo: entry.photo, adjustment: entry.adjustment)
        let target = renderTarget
        activity = .exporting
        errorMessage = nil
        errorActivity = nil
        task = Task {
            do {
                let result = try await pipeline.exportDigital(edit: edit, target: target)
                guard revision == currentRevision, !Task.isCancelled else {
                    await pipeline.discard(exportID: result.id)
                    return
                }
                exportLease = result.id
                digitalExport = result
                exported = nil
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
        digitalExport = nil
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
        let format = renderTarget.format
        printJob.items.append(PrintItem(photoID: photo.id, trimWidthMM: format.widthMM,
                                        trimHeightMM: format.heightMM, copies: copies))
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
        let format = renderTarget.format
        let crop = adjustment.crop(in: photo.pixels, format: format)
        let output = format.output
        return Double(photo.pixels.width) * crop.width < Double(output.width)
            || Double(photo.pixels.height) * crop.height < Double(output.height)
    }

    private func handle(_ error: Error, revision currentRevision: UUID) {
        guard revision == currentRevision else { return }
        let failedActivity = activity
        activity = nil
        if error is CancellationError { return }
        errorActivity = failedActivity
        // Do not surface framework errors, which can contain sensitive local file paths.
        errorMessage = (error as? PhotoError)?.errorDescription
            ?? String(localized: "The operation could not be completed. Try again or choose another photo.")
    }
}
