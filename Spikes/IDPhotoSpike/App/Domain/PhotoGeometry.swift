import Foundation

/// Dimensions of the orientation-corrected source, never raw EXIF storage axes.
struct SourcePixels: Sendable, Equatable {
    let width: Int
    let height: Int
}

struct OutputPixels: Sendable, Hashable {
    let width: Int
    let height: Int
}

/// Top-left origin, relative to the upright source image. May extend outside 0...1 when bleed is added;
/// the renderer paints white where no source pixels exist.
struct NormalizedCrop: Sendable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    /// Grows the crop by a physical bleed on every side, expressed as a fraction of the trim size.
    func expanded(byFractionX fx: Double, fractionY fy: Double) -> NormalizedCrop {
        NormalizedCrop(x: x - width * fx, y: y - height * fy, width: width * (1 + 2 * fx), height: height * (1 + 2 * fy))
    }
}

struct PhotoFormat: Sendable, Hashable, Identifiable {
    let id: String
    let widthMM: Double
    let heightMM: Double
    let output: OutputPixels

    // Engineering presets, not published rules-catalog entries.
    // 20 pixels/mm preserves each aspect ratio exactly. Resolution is an app choice.
    static let pixelsPerMM = 20.0
    static let spainPrototype = PhotoFormat(id: "es-26x32", widthMM: 26, heightMM: 32, output: OutputPixels(width: 520, height: 640))
    static let europe35x45 = PhotoFormat(id: "eu-35x45", widthMM: 35, heightMM: 45, output: OutputPixels(width: 700, height: 900))
    static let square51 = PhotoFormat(id: "us-51x51", widthMM: 50.8, heightMM: 50.8, output: OutputPixels(width: 1_016, height: 1_016))
    static let presets: [PhotoFormat] = [spainPrototype, europe35x45, square51]

    /// Resolves a format for a trim size; unknown sizes get the same pixels-per-millimetre policy.
    static func format(widthMM: Double, heightMM: Double) -> PhotoFormat {
        if let preset = presets.first(where: { abs($0.widthMM - widthMM) < 0.001 && abs($0.heightMM - heightMM) < 0.001 }) {
            return preset
        }
        return PhotoFormat(id: "custom-\(widthMM)x\(heightMM)", widthMM: widthMM, heightMM: heightMM,
                           output: OutputPixels(width: Int((widthMM * pixelsPerMM).rounded()),
                                                height: Int((heightMM * pixelsPerMM).rounded())))
    }

    var aspectRatio: Double { widthMM / heightMM }
    var pixelsPerInch: Double { Double(output.width) / widthMM * 25.4 }
    static func pdfPoints(mm: Double) -> Double { mm / 25.4 * 72 }
}

struct CropAdjustment: Sendable, Equatable {
    var zoom: Double = 1
    /// Fractions of the available horizontal/vertical travel, not source coordinates.
    var horizontal: Double = 0.5
    var vertical: Double = 0.5

    func clamped() -> Self {
        Self(zoom: Self.bound(zoom, 1...4), horizontal: Self.bound(horizontal, 0...1),
             vertical: Self.bound(vertical, 0...1))
    }

    func crop(in source: SourcePixels, format: PhotoFormat = .spainPrototype) -> NormalizedCrop {
        precondition(source.width > 0 && source.height > 0)
        let edit = clamped()
        let sourceAspect = Double(source.width) / Double(source.height)
        let width = min(1, format.aspectRatio / sourceAspect) / edit.zoom
        let height = min(1, sourceAspect / format.aspectRatio) / edit.zoom
        return NormalizedCrop(x: (1 - width) * edit.horizontal,
                              y: (1 - height) * edit.vertical, width: width, height: height)
    }

    func translated(x: Double, y: Double, previewWidth: Double, source: SourcePixels) -> Self {
        guard previewWidth > 0 else { return self }
        let rect = crop(in: source)
        let imageWidth = previewWidth / rect.width
        let previewHeight = previewWidth / PhotoFormat.spainPrototype.aspectRatio
        let imageHeight = previewHeight / rect.height
        var result = self
        if imageWidth - previewWidth > 0.01 {
            result.horizontal -= x / (imageWidth - previewWidth)
        }
        if imageHeight - previewHeight > 0.01 {
            result.vertical -= y / (imageHeight - previewHeight)
        }
        return result.clamped()
    }

    private static func bound(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}
