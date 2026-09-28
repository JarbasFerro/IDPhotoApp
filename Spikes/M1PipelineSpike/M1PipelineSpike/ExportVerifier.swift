import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ExportVerifier {
    static func verifyJPEG(
        at url: URL,
        expectedWidth: Int,
        expectedHeight: Int
    ) throws -> ExportVerification {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PipelineError.cannotDecodeCapture
        }

        let properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?) ?? [:]
        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? -1
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? -1
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue
        let containsGPS = properties[kCGImagePropertyGPSDictionary] != nil
        let typeIdentifier = (CGImageSourceGetType(source) as String?) ?? "unknown"

        let passed = width == expectedWidth
            && height == expectedHeight
            && typeIdentifier == UTType.jpeg.identifier
            && !containsGPS

        return ExportVerification(
            width: width,
            height: height,
            typeIdentifier: typeIdentifier,
            containsGPSMetadata: containsGPS,
            orientation: orientation,
            expectedWidth: expectedWidth,
            expectedHeight: expectedHeight,
            passed: passed
        )
    }
}
