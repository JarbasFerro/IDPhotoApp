import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import OSLog

/// Document Tone: Apple's auto-adjustment filters plus a neutral white point from the original background,
/// blended with the source by `strength`. Every operation is global; no region of the face is treated
/// differently from the rest (ADR-011). Portrait Lighting and Studio Light are not used (ADR-038).
final class ToneAdjuster: Sendable {
    static let shared = ToneAdjuster()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
    private let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Tone")

    /// - Parameters:
    ///   - backgroundReference: mean sRGB colour of the original background, used as the neutral point when it is
    ///     light enough to be trusted (a white wall photographed under warm light). Nil skips white balance.
    ///   - faceBox: face rectangle (top-left normalized) used to normalise face exposure within ±0.5 EV.
    func adjusted(image: CGImage, settings: ToneSettings, backgroundReference: BackgroundColor?, faceBox: NormalizedCrop? = nil) -> CGImage? {
        let settings = settings.clamped()
        guard settings.isEnabled, settings.strength > 0 else { return image }
        let interval = signposter.beginInterval("Tone")
        defer { signposter.endInterval("Tone", interval) }
        let source = CIImage(cgImage: image)
        var working = source

        // Neutral white balance: per-channel gains that make the background reference grey without lowering
        // its brightest channel. Gains are computed in linear light because CIColorMatrix runs in the linear
        // working space. (CIWhitePointAdjust tints towards its colour, which is the opposite effect.)
        if let reference = backgroundReference {
            let luminance = 0.2126 * reference.red + 0.7152 * reference.green + 0.0722 * reference.blue
            let linear = [reference.red, reference.green, reference.blue].map(Self.linearised)
            let brightest = linear.max() ?? 0
            if luminance >= 0.55, brightest > 0.02 {
                let gains = linear.map { brightest / max($0, 0.02) }
                let gain = CIFilter.colorMatrix()
                gain.inputImage = working
                gain.rVector = CIVector(x: gains[0], y: 0, z: 0, w: 0)
                gain.gVector = CIVector(x: 0, y: gains[1], z: 0, w: 0)
                gain.bVector = CIVector(x: 0, y: 0, z: gains[2], w: 0)
                gain.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
                working = gain.outputImage ?? working
            }
        }

        // Apple's own global enhancement: tone curve, highlights and shadows, vibrance, red-eye and face balance
        // when faces are found. Crop and level suggestions are excluded; geometry is the solver's job.
        let filters = working.autoAdjustmentFilters(options: [.crop: false, .level: false])
        for filter in filters {
            filter.setValue(working, forKey: kCIInputImageKey)
            if let output = filter.outputImage { working = output }
        }

        // Face exposure: bring the face's mean luminance towards a well-exposed value, at most half a stop.
        if let faceBox, let small = thumbnail(of: working, extent: source.extent) {
            let mean = Self.metrics(of: small, faceBox: faceBox, mask: nil).faceMeanLuminance
            if mean > 0.02 {
                let ev = min(max(log2(Self.targetFaceLuminance / mean), -0.5), 0.5)
                if abs(ev) > 0.05 {
                    let exposure = CIFilter.exposureAdjust()
                    exposure.inputImage = working
                    exposure.ev = Float(ev)
                    working = exposure.outputImage ?? working
                }
            }
        }

        // CIMix returns the input image at amount 1 and the background image at amount 0.
        let mix = CIFilter.mix()
        mix.inputImage = working.cropped(to: source.extent)
        mix.backgroundImage = source
        mix.amount = Float(settings.strength)
        guard let output = mix.outputImage else { return nil }
        return context.createCGImage(output, from: source.extent, format: .RGBA8, colorSpace: srgb)
    }

    /// sRGB transfer function inverse (0...1).
    static func linearised(_ value: Double) -> Double {
        let v = min(max(value, 0), 1)
        return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    /// Mean face luminance the exposure step aims for (sRGB), a mid-light skin rendering that avoids clipping.
    static let targetFaceLuminance = 0.52

    private func thumbnail(of image: CIImage, extent: CGRect) -> CGImage? {
        let scale = 256 / max(extent.width, 1)
        let scaled = image.cropped(to: extent).transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return context.createCGImage(scaled, from: scaled.extent, format: .RGBA8, colorSpace: srgb)
    }

    /// Mild export-time sharpening; radius and intensity scale with strength and stay far from halo territory.
    func sharpened(image: CGImage, settings: ToneSettings) -> CGImage? {
        let settings = settings.clamped()
        guard settings.isEnabled, settings.strength > 0 else { return image }
        let source = CIImage(cgImage: image)
        let unsharp = CIFilter.unsharpMask()
        unsharp.inputImage = source
        unsharp.radius = 1.2
        unsharp.intensity = Float(0.35 * settings.strength)
        guard let output = unsharp.outputImage?.cropped(to: source.extent) else { return nil }
        return context.createCGImage(output, from: source.extent, format: .RGBA8, colorSpace: srgb)
    }

    // MARK: - Measurement

    /// Luminance statistics over the face rectangle and colour cast over the background (mask below 40/255).
    static func metrics(of image: CGImage, faceBox: NormalizedCrop?, mask: CGImage?) -> ToneMetrics {
        let width = 256
        let height = max(1, Int((Double(width) * Double(image.height) / Double(image.width)).rounded()))
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return ToneMetrics(faceMeanLuminance: 0.5, faceClippedDark: 0, faceClippedBright: 0, backgroundCast: 0) }
        var maskBytes: [UInt8] = []
        if let mask {
            maskBytes = [UInt8](repeating: 0, count: width * height)
            _ = maskBytes.withUnsafeMutableBytes { buffer -> Bool in
                guard let space = CGColorSpace(name: CGColorSpace.linearGray),
                      let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                              bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue)
                else { return false }
                context.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
                return true
            }
        }
        let face = faceBox ?? NormalizedCrop(x: 0.3, y: 0.25, width: 0.4, height: 0.4)
        var faceSum = 0.0, faceCount = 0, dark = 0, bright = 0
        var backgroundRed = 0.0, backgroundBlue = 0.0, backgroundCount = 0
        for row in 0..<height {
            for column in 0..<width {
                let index = (row * width + column) * 4
                let r = Double(rgba[index]) / 255, g = Double(rgba[index + 1]) / 255, b = Double(rgba[index + 2]) / 255
                let x = (Double(column) + 0.5) / Double(width), y = (Double(row) + 0.5) / Double(height)
                if x >= face.x && x <= face.x + face.width && y >= face.y && y <= face.y + face.height {
                    let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    faceSum += luminance; faceCount += 1
                    if rgba[index] <= 2 && rgba[index + 1] <= 2 && rgba[index + 2] <= 2 { dark += 1 }
                    if rgba[index] >= 253 && rgba[index + 1] >= 253 && rgba[index + 2] >= 253 { bright += 1 }
                }
                if !maskBytes.isEmpty, maskBytes[row * width + column] < 40 {
                    backgroundRed += r; backgroundBlue += b; backgroundCount += 1
                }
            }
        }
        return ToneMetrics(
            faceMeanLuminance: faceCount > 0 ? faceSum / Double(faceCount) : 0.5,
            faceClippedDark: faceCount > 0 ? Double(dark) / Double(faceCount) : 0,
            faceClippedBright: faceCount > 0 ? Double(bright) / Double(faceCount) : 0,
            backgroundCast: backgroundCount > 0 ? (backgroundRed - backgroundBlue) / Double(backgroundCount) : 0)
    }

    /// Mean sRGB colour of the background region, or nil when too little background is visible.
    static func backgroundReference(of image: CGImage, mask: CGImage) -> BackgroundColor? {
        let width = 128
        let height = max(1, Int((Double(width) * Double(image.height) / Double(image.width)).rounded()))
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        var maskBytes = [UInt8](repeating: 0, count: width * height)
        let drawn = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        } && maskBytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.linearGray),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        var r = 0.0, g = 0.0, b = 0.0, count = 0
        for index in 0..<(width * height) where maskBytes[index] < 40 {
            r += Double(rgba[index * 4]) / 255; g += Double(rgba[index * 4 + 1]) / 255; b += Double(rgba[index * 4 + 2]) / 255; count += 1
        }
        guard Double(count) / Double(width * height) >= 0.05 else { return nil }
        return BackgroundColor(red: r / Double(count), green: g / Double(count), blue: b / Double(count))
    }
}
