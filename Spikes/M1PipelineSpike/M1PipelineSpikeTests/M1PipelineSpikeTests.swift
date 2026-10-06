import CoreImage
import ImageIO
import Testing
@testable import M1PipelineSpike

struct M1PipelineSpikeTests {
    @Test
    func jpegReopensWithExactPixelGeometryAndNoGPS() throws {
        let context = CIContext()
        let image = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5))
            .cropped(to: CGRect(x: 0, y: 0, width: 900, height: 1200))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("m1-exact-export-\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: url) }

        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let qualityKey = kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption
        try context.writeJPEGRepresentation(
            of: image,
            to: url,
            colorSpace: colorSpace,
            options: [qualityKey: 0.95]
        )

        let verification = try ExportVerifier.verifyJPEG(
            at: url,
            expectedWidth: 900,
            expectedHeight: 1200
        )

        #expect(verification.passed)
        #expect(verification.width == 900)
        #expect(verification.height == 1200)
        #expect(!verification.containsGPSMetadata)
    }

    @Test
    func spikeCropSolverStaysInsideSourceAndPreservesTargetAspect() {
        let source = CGRect(x: 0, y: 0, width: 4032, height: 3024)
        let face = CGRect(x: 0.74, y: 0.42, width: 0.12, height: 0.20)
        let crop = SpikeCropSolver.cropRect(
            sourceExtent: source,
            normalizedFaceBoundingBox: face,
            targetAspectRatio: 3.0 / 4.0
        )

        #expect(source.contains(crop))
        #expect(abs((crop.width / crop.height) - 0.75) < 0.001)
    }
}
