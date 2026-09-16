import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import OSLog
import Vision

enum SegmentationMethod: String, Sendable, Hashable { case foregroundInstance, personSegmentation }

struct SegmentationResult: Sendable, Hashable {
    /// 8-bit mask at the preview's pixel size, white = foreground.
    let mask: CGImage
    let method: SegmentationMethod
    let statistics: MaskStatistics
    let quality: MaskQuality
    /// How the original background looks where the mask says background.
    let background: BackgroundAssessment
}

/// Vision segmentation adapter. Produces a preview-resolution mask, scores it, and assesses the original
/// background. Never throws for a missing mask: the caller falls back to the original background (FR-064).
enum BackgroundSegmenter {
    private static let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Segmentation")

    static func segment(preview: CGImage, faceBox: NormalizedCrop?, faceCenter: ImagePoint?) async -> SegmentationResult? {
        let interval = signposter.beginInterval("Segmentation")
        defer { signposter.endInterval("Segmentation", interval) }
        let handler = ImageRequestHandler(preview)
        let size = CGSize(width: preview.width, height: preview.height)
        var candidates: [(CGImage, SegmentationMethod)] = []

        if let observation = try? await handler.perform(GenerateForegroundInstanceMaskRequest()) {
            var instances = observation.allInstances
            if let faceCenter {
                // Vision points are lower-left normalized.
                let hit = observation.instanceAtPoint(NormalizedPoint(x: faceCenter.x, y: 1 - faceCenter.y))
                if !hit.isEmpty { instances = hit }
            }
            if !instances.isEmpty, let buffer = try? observation.generateScaledMask(for: instances, scaledToImageFrom: handler),
               let image = BackgroundCompositor.shared.grayImage(from: buffer, size: size) {
                candidates.append((image, .foregroundInstance))
            }
        }
        if Task.isCancelled { return nil }
        if let person = await FaceAnalyzer.personMask(handler),
           let image = BackgroundCompositor.shared.resampled(person, to: size) {
            candidates.append((image, .personSegmentation))
        }
        guard !candidates.isEmpty else { return nil }

        // Prefer the foreground-instance mask when it covers the face; otherwise the person model.
        let scored = candidates.map { candidate -> (CGImage, SegmentationMethod, MaskStatistics, MaskQuality) in
            let stats = statistics(of: candidate.0, faceBox: faceBox)
            return (candidate.0, candidate.1, stats, MaskQuality.assess(stats))
        }
        let rank: (CheckState) -> Int = { [.pass: 0, .warn: 1, .manualCheck: 2, .fail: 3][$0] ?? 3 }
        guard let best = scored.min(by: { rank($0.3.state) < rank($1.3.state) }) else { return nil }
        let background = assessBackground(preview: preview, mask: best.0)
        return SegmentationResult(mask: best.0, method: best.1, statistics: best.2, quality: best.3, background: background)
    }

    // MARK: - Statistics on a downsampled copy

    static func statistics(of mask: CGImage, faceBox fullFaceBox: NormalizedCrop?) -> MaskStatistics {
        // Vision's face rectangle is a little wider than the head, so measure coverage on an inset box.
        let faceBox = fullFaceBox.map {
            NormalizedCrop(x: $0.x + 0.15 * $0.width, y: $0.y + 0.10 * $0.height, width: 0.70 * $0.width, height: 0.80 * $0.height)
        }
        let (bytes, width, height) = graySamples(mask, width: 256)
        guard width > 0, height > 0 else {
            return MaskStatistics(coverage: 0, faceCoverage: 0, uncertainRatio: 0, topEdgeForeground: 0)
        }
        var foreground = 0, uncertain = 0, faceForeground = 0, facePixels = 0, topForeground = 0
        for row in 0..<height {
            for column in 0..<width {
                let v = bytes[row * width + column]
                if v >= 128 { foreground += 1; if row == 0 { topForeground += 1 } }
                if v >= 40 && v <= 215 { uncertain += 1 }
                if let faceBox {
                    let x = (Double(column) + 0.5) / Double(width), y = (Double(row) + 0.5) / Double(height)
                    if x >= faceBox.x && x <= faceBox.x + faceBox.width && y >= faceBox.y && y <= faceBox.y + faceBox.height {
                        facePixels += 1
                        if v >= 128 { faceForeground += 1 }
                    }
                }
            }
        }
        let total = Double(width * height)
        let coverage = Double(foreground) / total
        return MaskStatistics(coverage: coverage,
                              faceCoverage: facePixels > 0 ? Double(faceForeground) / Double(facePixels) : 1,
                              uncertainRatio: coverage > 0 ? Double(uncertain) / total / coverage : 0,
                              topEdgeForeground: Double(topForeground) / Double(width))
    }

    static func assessBackground(preview: CGImage, mask: CGImage) -> BackgroundAssessment {
        let width = 256
        let height = max(1, Int((Double(width) * Double(preview.height) / Double(preview.width)).rounded()))
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.draw(preview, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        let (maskBytes, maskWidth, maskHeight) = graySamples(mask, width: width)
        guard drawn, maskWidth == width, maskHeight == height else {
            return BackgroundAssessment(meanLuminance: 0, luminanceDeviation: 1, sampleFraction: 0)
        }
        var sum = 0.0, sumSquares = 0.0, count = 0
        for index in 0..<(width * height) where maskBytes[index] < 40 {
            let r = Double(rgba[index * 4]) / 255, g = Double(rgba[index * 4 + 1]) / 255, b = Double(rgba[index * 4 + 2]) / 255
            let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
            sum += luminance; sumSquares += luminance * luminance; count += 1
        }
        guard count > 0 else { return BackgroundAssessment(meanLuminance: 0, luminanceDeviation: 1, sampleFraction: 0) }
        let mean = sum / Double(count)
        let variance = max(0, sumSquares / Double(count) - mean * mean)
        return BackgroundAssessment(meanLuminance: mean, luminanceDeviation: variance.squareRoot(),
                                    sampleFraction: Double(count) / Double(width * height))
    }

    /// Gray samples with bitmap row 0 at the top of the image.
    private static func graySamples(_ image: CGImage, width: Int) -> ([UInt8], Int, Int) {
        let height = max(1, Int((Double(width) * Double(image.height) / Double(image.width)).rounded()))
        var bytes = [UInt8](repeating: 0, count: width * height)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.linearGray),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? (bytes, width, height) : ([], 0, 0)
    }
}

/// Core Image compositing with one shared, Metal-backed context (AGENTS.md §8).
final class BackgroundCompositor: Sendable {
    static let shared = BackgroundCompositor()
    // CIContext is documented as thread-safe; it is immutable after creation.
    nonisolated(unsafe) private let context = CIContext(options: [.cacheIntermediates: false])
    private let gray = CGColorSpace(name: CGColorSpace.linearGray)!
    private let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

    /// Replaces everything outside the mask with `color`. `softness` 0...1 widens the feather from 0.5 to 3 px
    /// at a 1600 px long edge and scales with the image. A 1 px choke removes the background fringe first.
    func composite(image: CGImage, mask: CGImage, color: BackgroundColor, softness: Double) -> CGImage? {
        let source = CIImage(cgImage: image)
        let extent = source.extent
        let scale = max(extent.width, extent.height) / 1_600
        var ciMask = CIImage(cgImage: mask)
        ciMask = ciMask.transformed(by: CGAffineTransform(scaleX: extent.width / ciMask.extent.width,
                                                          y: extent.height / ciMask.extent.height))
        let choke = CIFilter.morphologyMinimum()
        choke.inputImage = ciMask
        choke.radius = Float(1 * scale)
        let feather = CIFilter.gaussianBlur()
        feather.inputImage = (choke.outputImage ?? ciMask).clampedToExtent()
        feather.radius = Float((0.5 + 2.5 * min(max(softness, 0), 1)) * scale)
        guard let processedMask = feather.outputImage?.cropped(to: extent) else { return nil }
        let background = CIImage(color: CIColor(red: color.red, green: color.green, blue: color.blue, colorSpace: srgb) ?? .white)
            .cropped(to: extent)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = source
        blend.backgroundImage = background
        blend.maskImage = processedMask
        guard let output = blend.outputImage else { return nil }
        return context.createCGImage(output, from: extent, format: .RGBA8, colorSpace: srgb)
    }

    /// Converts a Vision float mask into an 8-bit gray image at the given size.
    func grayImage(from buffer: CVPixelBuffer, size: CGSize) -> CGImage? {
        var image = CIImage(cvPixelBuffer: buffer)
        image = image.transformed(by: CGAffineTransform(scaleX: size.width / image.extent.width, y: size.height / image.extent.height))
        return context.createCGImage(image, from: CGRect(origin: .zero, size: size), format: .L8, colorSpace: gray)
    }

    func resampled(_ mask: CGImage, to size: CGSize) -> CGImage? {
        var image = CIImage(cgImage: mask)
        image = image.transformed(by: CGAffineTransform(scaleX: size.width / image.extent.width, y: size.height / image.extent.height))
        return context.createCGImage(image, from: CGRect(origin: .zero, size: size), format: .L8, colorSpace: gray)
    }
}
