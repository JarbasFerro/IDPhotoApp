import Foundation

/// Dimensions of the orientation-corrected source, never raw EXIF storage axes.
struct SourcePixels: Sendable, Equatable {
    let width: Int
    let height: Int
}

struct OutputPixels: Sendable, Equatable {
    let width: Int
    let height: Int
}

/// Top-left origin, relative to the upright source image.
struct NormalizedCrop: Sendable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct PhotoFormat: Sendable {
    let widthMM: Double
    let heightMM: Double
    let output: OutputPixels

    // Engineering preset, not a published rules-catalog entry.
    // 20 pixels/mm preserves 13:16 exactly. Resolution is an app choice.
    static let spainPrototype = PhotoFormat(
        widthMM: 26, heightMM: 32, output: OutputPixels(width: 520, height: 640)
    )

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

struct PrintLayout: Sendable {
    // A6 portrait, six copies. Geometry is in PDF points, independent of raster PPI.
    let pageWidth = PhotoFormat.pdfPoints(mm: 105)
    let pageHeight = PhotoFormat.pdfPoints(mm: 148)
    let photoWidth = PhotoFormat.pdfPoints(mm: 26)
    let photoHeight = PhotoFormat.pdfPoints(mm: 32)
    let gutter = PhotoFormat.pdfPoints(mm: 4)

    var origins: [(x: Double, y: Double)] {
        let left = (pageWidth - photoWidth * 2 - gutter) / 2
        let bottom = (pageHeight - photoHeight * 3 - gutter * 2) / 2
        return (0..<3).flatMap { row in
            (0..<2).map { column in
                (left + Double(column) * (photoWidth + gutter),
                 bottom + Double(row) * (photoHeight + gutter))
            }
        }
    }
}
