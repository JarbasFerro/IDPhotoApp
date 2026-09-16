import CoreGraphics
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

enum PhotoError: Error, LocalizedError, Sendable {
    case unreadable, tooLarge, renderFailed, verificationFailed, expired, emptySheet

    var errorDescription: String? {
        switch self {
        case .unreadable: String(localized: "This photo could not be opened. Choose a JPEG, HEIC, or PNG image.")
        case .tooLarge: String(localized: "This image is too large for this prototype. Choose a photo under 80 megapixels and 150 MB.")
        case .renderFailed: String(localized: "The photo could not be prepared. Try again or choose another photo.")
        case .verificationFailed: String(localized: "The exported file could not be verified. Please try again.")
        case .expired: String(localized: "This photo is no longer available. Choose it again.")
        case .emptySheet: String(localized: "No photo fits on this paper. Choose a larger paper or fewer copies.")
        }
    }
}

struct PreparedPhoto: Sendable {
    let id: UUID
    let pixels: SourcePixels
    let preview: CGImage
}

struct PhotoExport: Sendable, Identifiable {
    let id: UUID
    let jpeg: URL
    let pdf: URL
    let pages: [URL]
    let layout: PrintLayout
}

protocol PhotoProcessing: Sendable {
    func ingest(_ staged: StagedPhoto) async throws -> PreparedPhoto
    func analyze(photo: PreparedPhoto) async throws -> FaceAnalysis
    func segment(photo: PreparedPhoto, faceBox: NormalizedCrop?, faceCenter: ImagePoint?) async -> SegmentationResult?
    func previewImage(photo: PreparedPhoto, adjustment: CropAdjustment) async -> CGImage
    func toneMetrics(photo: PreparedPhoto, adjustment: CropAdjustment, faceBox: NormalizedCrop?) async -> ToneMetrics
    func export(photo: PreparedPhoto, adjustment: CropAdjustment, job: PrintJob) async throws -> PhotoExport
    func discard(photoID: UUID) async
    func discard(exportID: UUID) async
}

/// Serializes expensive work off the main actor and bounds decoded image sizes.
actor PhotoPipeline: PhotoProcessing {
    private let root: URL
    private let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "ImagePipeline")
    /// Preview-resolution masks per prepared photo; dropped with the photo. Never written to disk.
    private var masks: [UUID: CGImage] = [:]
    /// Mean colour of the original background per photo, the neutral reference for Document Tone.
    private var backgroundReferences: [UUID: BackgroundColor] = [:]
    private var faceBoxes: [UUID: NormalizedCrop] = [:]

    init(root: URL = FileManager.default.temporaryDirectory.appendingPathComponent("IDPhotoSpike")) {
        self.root = root
    }

    /// Call once before allowing imports. Tests pass isolated roots.
    func prepareSession() throws {
        if FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.removeItem(at: root)
        }
        let incoming = FileManager.default.temporaryDirectory.appendingPathComponent("IDPhotoIncoming")
        if FileManager.default.fileExists(atPath: incoming.path) {
            try FileManager.default.removeItem(at: incoming)
        }
        try PhotoFiles.createPrivateDirectory(root)
    }

    func ingest(_ staged: StagedPhoto) throws -> PreparedPhoto {
        let interval = signposter.beginInterval("Ingest")
        defer { signposter.endInterval("Ingest", interval) }
        defer { try? FileManager.default.removeItem(at: staged.directory) }
        try Task.checkCancellation()
        let source = try open(staged.url)
        let properties = try properties(source)
        guard let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else { throw PhotoError.unreadable }
        guard width <= 16_384, height <= 16_384, Int64(width) * Int64(height) <= 80_000_000 else {
            throw PhotoError.tooLarge
        }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        guard (1...8).contains(orientation) else { throw PhotoError.unreadable }
        let swapped = (5...8).contains(orientation)
        let pixels = SourcePixels(width: swapped ? height : width, height: swapped ? width : height)
        let preview = try thumbnail(source, maxPixelSize: min(1_600, max(width, height)))
        try Task.checkCancellation()
        let id = UUID()
        let directory = photoDirectory(id)
        try PhotoFiles.createPrivateDirectory(directory)
        do {
            try FileManager.default.copyItem(at: staged.url, to: directory.appendingPathComponent("original"))
            try PhotoFiles.protect(directory.appendingPathComponent("original"))
            try Task.checkCancellation()
            return PreparedPhoto(id: id, pixels: pixels, preview: preview)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    /// Face geometry and the automatic crop, from the bounded preview; never touches the original file.
    func analyze(photo: PreparedPhoto) async throws -> FaceAnalysis {
        try await FaceAnalyzer.analyze(preview: photo.preview, source: photo.pixels)
    }

    /// Foreground mask for background replacement, kept in memory for this photo.
    func segment(photo: PreparedPhoto, faceBox: NormalizedCrop?, faceCenter: ImagePoint?) async -> SegmentationResult? {
        faceBoxes[photo.id] = faceBox
        let result = await BackgroundSegmenter.segment(preview: photo.preview, faceBox: faceBox, faceCenter: faceCenter)
        if let result, result.quality.state != .fail {
            masks[photo.id] = result.mask
            backgroundReferences[photo.id] = ToneAdjuster.backgroundReference(of: photo.preview, mask: result.mask)
        } else {
            masks[photo.id] = nil
            backgroundReferences[photo.id] = nil
        }
        return result
    }

    /// Test hook: install a mask without running Vision.
    func setMask(_ mask: CGImage?, for photoID: UUID) { masks[photoID] = mask }

    /// The preview with the selected background applied, for the editor.
    func previewImage(photo: PreparedPhoto, adjustment: CropAdjustment) -> CGImage {
        applyBackground(to: photo.preview, photoID: photo.id, adjustment: adjustment)
    }

    /// Tone first (so a replaced background stays exactly the profile colour), then the background composite.
    private func applyBackground(to image: CGImage, photoID: UUID, adjustment: CropAdjustment) -> CGImage {
        var working = image
        if adjustment.tone.isEnabled {
            working = ToneAdjuster.shared.adjusted(image: working, settings: adjustment.tone,
                                                   backgroundReference: backgroundReferences[photoID],
                                                   faceBox: faceBoxes[photoID]) ?? working
        }
        guard case .color(let color) = adjustment.background, let mask = masks[photoID] else { return working }
        let interval = signposter.beginInterval("Composite")
        defer { signposter.endInterval("Composite", interval) }
        return BackgroundCompositor.shared.composite(image: working, mask: mask, color: color,
                                                     softness: adjustment.clamped().edgeSoftness) ?? working
    }

    /// Tone metrics on the preview with the current edits, for the status card.
    func toneMetrics(photo: PreparedPhoto, adjustment: CropAdjustment, faceBox: NormalizedCrop?) -> ToneMetrics {
        let image = applyBackground(to: photo.preview, photoID: photo.id, adjustment: adjustment)
        return ToneAdjuster.metrics(of: image, faceBox: faceBox, mask: masks[photo.id])
    }

    /// Digital JPEG plus the print sheet (PDF and one JPEG per page) described by `job`.
    func export(photo: PreparedPhoto, adjustment: CropAdjustment, job: PrintJob) throws -> PhotoExport {
        let interval = signposter.beginInterval("Export")
        defer { signposter.endInterval("Export", interval) }
        try Task.checkCancellation()
        let original = photoDirectory(photo.id).appendingPathComponent("original")
        guard FileManager.default.fileExists(atPath: original.path) else { throw PhotoError.expired }
        let source = try open(original)
        let format = PhotoFormat.spainPrototype
        let rendered = try render(source, photo: photo, adjustment: adjustment, format: format, bleedMM: 0)
        try Task.checkCancellation()

        let layoutInterval = signposter.beginInterval("Layout")
        let layout = PrintLayoutSolver.solve(job)
        signposter.endInterval("Layout", layoutInterval)
        guard !layout.pages.isEmpty else { throw PhotoError.emptySheet }
        var rasters: [PrintLayout.RasterKey: CGImage] = [:]
        for key in layout.rasterKeys {
            guard let item = job.items.first(where: { $0.id == key.itemID }) else { continue }
            try Task.checkCancellation()
            let itemFormat = PhotoFormat.format(widthMM: item.trimWidthMM, heightMM: item.trimHeightMM)
            rasters[key] = try render(source, photo: photo, adjustment: adjustment, format: itemFormat,
                                      bleedMM: PrintLayoutSolver.millimeters(key.bleedMicrometers))
        }

        let id = UUID()
        let directory = exportDirectory(id)
        try PhotoFiles.createPrivateDirectory(directory)
        let label = String(localized: "50 mm · print at Actual Size · measure before cutting")
        do {
            let jpeg = directory.appendingPathComponent("Foto-carnet.jpg")
            try writeJPEG(rendered, to: jpeg, pixelsPerInch: format.pixelsPerInch)
            try Self.verifyJPEG(jpeg, expected: format.output)
            try Task.checkCancellation()
            let pdfInterval = signposter.beginInterval("PDF")
            let pdf = directory.appendingPathComponent("Foto-carnet-sheet.pdf")
            try SheetRenderer.writePDF(layout, rasters: rasters, to: pdf, calibrationLabel: label)
            try SheetRenderer.verifyPDF(pdf, layout: layout)
            signposter.endInterval("PDF", pdfInterval)
            try Task.checkCancellation()
            let pages = try SheetRenderer.writeJPEGPages(layout, rasters: rasters, in: directory,
                                                         baseName: "Foto-carnet-sheet", calibrationLabel: label)
            try SheetRenderer.verifyJPEGPages(pages, layout: layout)
            for url in [jpeg, pdf] + pages { try PhotoFiles.protect(url) }
            try Task.checkCancellation()
            return PhotoExport(id: id, jpeg: jpeg, pdf: pdf, pages: pages, layout: layout)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func discard(photoID: UUID) {
        masks[photoID] = nil
        backgroundReferences[photoID] = nil
        faceBoxes[photoID] = nil
        try? FileManager.default.removeItem(at: photoDirectory(photoID))
    }
    func discard(exportID: UUID) { try? FileManager.default.removeItem(at: exportDirectory(exportID)) }

    private func photoDirectory(_ id: UUID) -> URL { root.appendingPathComponent("photos/" + id.uuidString) }
    private func exportDirectory(_ id: UUID) -> URL { root.appendingPathComponent("exports/" + id.uuidString) }

    private func open(_ url: URL) throws -> CGImageSource {
        guard let source = CGImageSourceCreateWithURL(url as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source) as String?,
              [UTType.jpeg.identifier, UTType.heic.identifier, UTType.heif.identifier, UTType.png.identifier].contains(type),
              CGImageSourceGetCount(source) > 0 else { throw PhotoError.unreadable }
        return source
    }

    private func properties(_ source: CGImageSource) throws -> [CFString: Any] {
        guard let value = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            throw PhotoError.unreadable
        }
        return value
    }

    private func thumbnail(_ source: CGImageSource, maxPixelSize: Int) throws -> CGImage {
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary) else { throw PhotoError.unreadable }
        return image
    }

    /// Renders the trim crop plus `bleedMM` on every side at the format's pixels-per-millimetre.
    private func render(_ source: CGImageSource, photo: PreparedPhoto, adjustment: CropAdjustment,
                        format: PhotoFormat, bleedMM: Double) throws -> CGImage {
        let trim = adjustment.crop(in: photo.pixels, format: format)
        let crop = trim.expanded(byFractionX: bleedMM / format.widthMM, fractionY: bleedMM / format.heightMM)
        let pixelsPerMM = Double(format.output.width) / format.widthMM
        let output = OutputPixels(width: Int(((format.widthMM + 2 * bleedMM) * pixelsPerMM).rounded()),
                                  height: Int(((format.heightMM + 2 * bleedMM) * pixelsPerMM).rounded()))
        // Decode enough pixels for this crop/output, rather than the entire 48 MP original.
        let requiredWidth = Double(output.width) / crop.width
        let requiredHeight = Double(output.height) / crop.height
        let longEdge = Int(ceil(max(requiredWidth, requiredHeight)))
        let decoded = try thumbnail(source, maxPixelSize: min(longEdge, max(photo.pixels.width, photo.pixels.height)))
        // The mask was made from the preview; Core Image scales it to the decoded size before blending.
        let image = applyBackground(to: decoded, photoID: photo.id, adjustment: adjustment)
        let rendered = try render(image, crop: crop, output: output, rotationDegrees: adjustment.clamped().rotationDegrees)
        // Sharpening belongs at output resolution, after resampling.
        return ToneAdjuster.shared.sharpened(image: rendered, settings: adjustment.tone) ?? rendered
    }

    private func render(_ image: CGImage, crop: NormalizedCrop, output: OutputPixels, rotationDegrees: Double = 0) throws -> CGImage {
        let interval = signposter.beginInterval("Render")
        defer { signposter.endInterval("Render", interval) }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: output.width, height: output.height,
                bitsPerComponent: 8, bytesPerRow: 0, space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw PhotoError.renderFailed }
        let width = Double(output.width)
        let height = Double(output.height)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        if rotationDegrees != 0 {
            // Level the eyes: rotate the source about the crop centre, which maps to the output centre.
            context.translateBy(x: width / 2, y: height / 2)
            context.rotate(by: rotationDegrees * .pi / 180)
            context.translateBy(x: -width / 2, y: -height / 2)
        }
        // CGContext uses a bottom-left origin. Crop coordinates are explicitly top-left.
        context.draw(image, in: CGRect(x: -crop.x / crop.width * width,
            y: -(1 - crop.y - crop.height) / crop.height * height,
            width: width / crop.width, height: height / crop.height))
        guard let result = context.makeImage() else { throw PhotoError.renderFailed }
        return result
    }

    private func writeJPEG(_ image: CGImage, to url: URL, pixelsPerInch: Double) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw PhotoError.renderFailed }
        // New image + explicit metadata whitelist; never copy source dictionaries.
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: 0.95,
            kCGImagePropertyOrientation: 1,
            kCGImagePropertyDPIWidth: pixelsPerInch,
            kCGImagePropertyDPIHeight: pixelsPerInch
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.renderFailed }
    }

    static func verifyJPEG(_ url: URL, expected: OutputPixels) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              props[kCGImagePropertyPixelWidth] as? Int == expected.width,
              props[kCGImagePropertyPixelHeight] as? Int == expected.height,
              (props[kCGImagePropertyOrientation] as? Int ?? 1) == 1,
              props[kCGImagePropertyGPSDictionary] == nil,
              props[kCGImagePropertyIPTCDictionary] == nil,
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else { throw PhotoError.verificationFailed }
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        guard exif[kCGImagePropertyExifUserComment] == nil,
              exif[kCGImagePropertyExifDateTimeOriginal] == nil,
              tiff[kCGImagePropertyTIFFMake] == nil,
              tiff[kCGImagePropertyTIFFModel] == nil else { throw PhotoError.verificationFailed }
    }
}
