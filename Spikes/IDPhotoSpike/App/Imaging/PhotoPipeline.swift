import CoreGraphics
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

enum PhotoError: Error, LocalizedError, Sendable {
    case unreadable, tooLarge, renderFailed, verificationFailed, expired

    var errorDescription: String? {
        switch self {
        case .unreadable: String(localized: "This photo could not be opened. Choose a JPEG, HEIC, or PNG image.")
        case .tooLarge: String(localized: "This image is too large for this prototype. Choose a photo under 80 megapixels and 150 MB.")
        case .renderFailed: String(localized: "The photo could not be prepared. Try again or choose another photo.")
        case .verificationFailed: String(localized: "The exported file could not be verified. Please try again.")
        case .expired: String(localized: "This photo is no longer available. Choose it again.")
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
}

protocol PhotoProcessing: Sendable {
    func ingest(_ staged: StagedPhoto) async throws -> PreparedPhoto
    func export(photo: PreparedPhoto, adjustment: CropAdjustment) async throws -> PhotoExport
    func discard(photoID: UUID) async
    func discard(exportID: UUID) async
}

/// Serializes expensive work off the main actor and bounds decoded image sizes.
actor PhotoPipeline: PhotoProcessing {
    private let root: URL
    private let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "ImagePipeline")

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

    func export(photo: PreparedPhoto, adjustment: CropAdjustment) throws -> PhotoExport {
        let interval = signposter.beginInterval("Export")
        defer { signposter.endInterval("Export", interval) }
        try Task.checkCancellation()
        let original = photoDirectory(photo.id).appendingPathComponent("original")
        guard FileManager.default.fileExists(atPath: original.path) else { throw PhotoError.expired }
        let source = try open(original)
        let format = PhotoFormat.spainPrototype
        let crop = adjustment.crop(in: photo.pixels)
        // Decode enough pixels for this crop/output, rather than the entire 48 MP original.
        let requiredWidth = Double(format.output.width) / crop.width
        let requiredHeight = Double(format.output.height) / crop.height
        let longEdge = Int(ceil(max(requiredWidth, requiredHeight)))
        let image = try thumbnail(source, maxPixelSize: min(longEdge, max(photo.pixels.width, photo.pixels.height)))
        let rendered = try render(image, crop: crop, output: format.output)
        try Task.checkCancellation()
        let id = UUID()
        let directory = exportDirectory(id)
        try PhotoFiles.createPrivateDirectory(directory)
        let result = PhotoExport(id: id, jpeg: directory.appendingPathComponent("Foto-carnet.jpg"),
                                 pdf: directory.appendingPathComponent("Foto-carnet-A6.pdf"))
        do {
            try writeJPEG(rendered, to: result.jpeg)
            try Self.verifyJPEG(result.jpeg, expected: format.output)
            try Task.checkCancellation()
            try writePDF(rendered, to: result.pdf)
            try Self.verifyPDF(result.pdf)
            try PhotoFiles.protect(result.jpeg)
            try PhotoFiles.protect(result.pdf)
            try Task.checkCancellation()
            return result
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func discard(photoID: UUID) { try? FileManager.default.removeItem(at: photoDirectory(photoID)) }
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

    private func render(_ image: CGImage, crop: NormalizedCrop, output: OutputPixels) throws -> CGImage {
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
        // CGContext uses a bottom-left origin. Crop coordinates are explicitly top-left.
        context.draw(image, in: CGRect(x: -crop.x / crop.width * width,
            y: -(1 - crop.y - crop.height) / crop.height * height,
            width: width / crop.width, height: height / crop.height))
        guard let result = context.makeImage() else { throw PhotoError.renderFailed }
        return result
    }

    private func writeJPEG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw PhotoError.renderFailed }
        // New image + explicit metadata whitelist; never copy source dictionaries.
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: 0.95,
            kCGImagePropertyOrientation: 1,
            kCGImagePropertyDPIWidth: PhotoFormat.spainPrototype.pixelsPerInch,
            kCGImagePropertyDPIHeight: PhotoFormat.spainPrototype.pixelsPerInch
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.renderFailed }
    }

    private func writePDF(_ image: CGImage, to url: URL) throws {
        let interval = signposter.beginInterval("PDF")
        defer { signposter.endInterval("PDF", interval) }
        let layout = PrintLayout()
        var box = CGRect(x: 0, y: 0, width: layout.pageWidth, height: layout.pageHeight)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { throw PhotoError.renderFailed }
        context.beginPDFPage(nil)
        for origin in layout.origins {
            context.draw(image, in: CGRect(x: origin.x, y: origin.y,
                                          width: layout.photoWidth, height: layout.photoHeight))
        }
        context.endPDFPage()
        context.closePDF()
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

    static func verifyPDF(_ url: URL) throws {
        let layout = PrintLayout()
        guard let document = CGPDFDocument(url as CFURL), document.numberOfPages == 1,
              let page = document.page(at: 1) else { throw PhotoError.verificationFailed }
        let box = page.getBoxRect(.mediaBox)
        guard abs(box.width - layout.pageWidth) < 0.01, abs(box.height - layout.pageHeight) < 0.01 else {
            throw PhotoError.verificationFailed
        }
    }
}
