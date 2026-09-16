import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import IDPhotoSpike

struct BackgroundTests {
    @Test func maskQualityThresholds() {
        let good = MaskStatistics(coverage: 0.35, faceCoverage: 0.99, uncertainRatio: 0.08, topEdgeForeground: 0)
        #expect(MaskQuality.assess(good).state == .pass)
        let soft = MaskStatistics(coverage: 0.35, faceCoverage: 0.99, uncertainRatio: 0.4, topEdgeForeground: 0)
        #expect(MaskQuality.assess(soft).state == .warn && MaskQuality.assess(soft).reasons == [.softEdges])
        let cut = MaskStatistics(coverage: 0.35, faceCoverage: 0.99, uncertainRatio: 0.05, topEdgeForeground: 0.1)
        #expect(MaskQuality.assess(cut).state == .warn && MaskQuality.assess(cut).reasons == [.headCutOff])
        let missedFace = MaskStatistics(coverage: 0.35, faceCoverage: 0.6, uncertainRatio: 0.05, topEdgeForeground: 0)
        #expect(MaskQuality.assess(missedFace).state == .fail)
        let everything = MaskStatistics(coverage: 0.99, faceCoverage: 1, uncertainRatio: 0, topEdgeForeground: 1)
        #expect(MaskQuality.assess(everything).state == .fail)
    }

    @Test func backgroundAssessmentStates() {
        #expect(BackgroundAssessment(meanLuminance: 0.9, luminanceDeviation: 0.03, sampleFraction: 0.5).state == .pass)
        #expect(BackgroundAssessment(meanLuminance: 0.6, luminanceDeviation: 0.03, sampleFraction: 0.5).state == .warn)
        #expect(BackgroundAssessment(meanLuminance: 0.9, luminanceDeviation: 0.12, sampleFraction: 0.5).state == .warn)
        #expect(BackgroundAssessment(meanLuminance: 0.9, luminanceDeviation: 0.12, sampleFraction: 0.5).issues == [.slightlyUneven])
        #expect(BackgroundAssessment(meanLuminance: 0.5, luminanceDeviation: 0.3, sampleFraction: 0.5).state == .fail)
        #expect(BackgroundAssessment(meanLuminance: 0.9, luminanceDeviation: 0.01, sampleFraction: 0.01).state == .manualCheck)
    }

    /// Blue 400 × 500 image with a white "person" mask covering the centre; face box inside the mask.
    private func fixture() throws -> (image: CGImage, mask: CGImage, faceBox: NormalizedCrop) {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let image = try #require(CGContext(data: nil, width: 400, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
                                           space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        image.setFillColor(CGColor(srgbRed: 0.1, green: 0.2, blue: 0.8, alpha: 1))
        image.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
        let gray = try #require(CGColorSpace(name: CGColorSpace.linearGray))
        let mask = try #require(CGContext(data: nil, width: 400, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: gray, bitmapInfo: CGImageAlphaInfo.none.rawValue))
        mask.setFillColor(CGColor(gray: 0, alpha: 1)); mask.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
        mask.setFillColor(CGColor(gray: 1, alpha: 1)); mask.fill(CGRect(x: 100, y: 0, width: 200, height: 350)) // person from bottom
        return (try #require(image.makeImage()), try #require(mask.makeImage()), NormalizedCrop(x: 0.35, y: 0.4, width: 0.3, height: 0.3))
    }

    @Test func statisticsDescribeTheMask() throws {
        let f = try fixture()
        let stats = BackgroundSegmenter.statistics(of: f.mask, faceBox: f.faceBox)
        #expect(abs(stats.coverage - 0.35) < 0.02)
        #expect(stats.faceCoverage > 0.98)
        #expect(stats.uncertainRatio < 0.05)
        #expect(stats.topEdgeForeground == 0)
        #expect(MaskQuality.assess(stats).state == .pass)
    }

    @Test func originalBackgroundIsAssessedWhereTheMaskIsBackground() throws {
        let f = try fixture()
        let dark = BackgroundSegmenter.assessBackground(preview: f.image, mask: f.mask)
        // Uniform but dark: replacement recommended, not a hard failure.
        #expect(dark.sampleFraction > 0.6 && dark.meanLuminance < 0.3 && dark.state == .warn && dark.issues == [.dark], "\(dark)")
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let light = try #require(CGContext(data: nil, width: 400, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
                                           space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        light.setFillColor(CGColor(srgbRed: 0.92, green: 0.92, blue: 0.9, alpha: 1)); light.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
        let plain = BackgroundSegmenter.assessBackground(preview: try #require(light.makeImage()), mask: f.mask)
        #expect(plain.state == .pass, "\(plain)")
    }

    @Test func compositeReplacesBackgroundAndLeavesTheFaceUntouched() throws {
        let f = try fixture()
        let output = try #require(BackgroundCompositor.shared.composite(image: f.image, mask: f.mask, color: .white, softness: 0.5))
        #expect(output.width == 400 && output.height == 500)
        let corner = try pixel(output, x: 10, y: 10)
        #expect(corner.allSatisfy { $0 >= 250 }, "\(corner)")
        let original = try pixel(f.image, x: 200, y: 250)
        let center = try pixel(output, x: 200, y: 250)
        #expect(zip(center, original).allSatisfy { abs(Int($0) - Int($1)) <= 1 }, "\(center) vs \(original)")
        // Every pixel of the face region (well inside the mask) is identical to the source.
        for x in stride(from: 150, through: 250, by: 25) {
            for y in stride(from: 210, through: 330, by: 30) {
                #expect(zip(try pixel(output, x: x, y: y), original).allSatisfy { abs(Int($0) - Int($1)) <= 1 })
            }
        }
        // The edge is feathered: a pixel just outside the mask is lighter than the source but not pure white.
        let edge = try pixel(output, x: 99, y: 400)
        #expect(edge[2] > original[2] - 1)
    }

    @Test func exportUsesTheInstalledMaskForWhiteBackground() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("BackgroundTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let photo = try await pipeline.ingest(SyntheticFixture.staged())
        // Person occupies the lower middle; corners of the four-colour fixture are background.
        let gray = try #require(CGColorSpace(name: CGColorSpace.linearGray))
        let mask = try #require(CGContext(data: nil, width: photo.preview.width, height: photo.preview.height, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: gray, bitmapInfo: CGImageAlphaInfo.none.rawValue))
        mask.setFillColor(CGColor(gray: 0, alpha: 1)); mask.fill(CGRect(x: 0, y: 0, width: photo.preview.width, height: photo.preview.height))
        mask.setFillColor(CGColor(gray: 1, alpha: 1))
        mask.fill(CGRect(x: photo.preview.width / 4, y: 0, width: photo.preview.width / 2, height: photo.preview.height * 3 / 5))
        await pipeline.setMask(try #require(mask.makeImage()), for: photo.id)

        var edits = CropAdjustment()
        edits.background = .color(.white)
        let job = PrintJob(paper: .photo4x6, items: [PrintItem(photoID: photo.id, trimWidthMM: 26, trimHeightMM: 32, copies: 1)])
        let white = try await pipeline.export(photo: photo, adjustment: edits, job: job)
        let whiteSource = try #require(CGImageSourceCreateWithURL(white.jpeg as CFURL, nil))
        let whiteImage = try #require(CGImageSourceCreateImageAtIndex(whiteSource, 0, nil))
        #expect(try pixel(whiteImage, x: 5, y: 5).allSatisfy { $0 >= 245 })
        #expect(try pixel(whiteImage, x: whiteImage.width / 2, y: whiteImage.height - 5).contains { $0 < 200 }) // person area keeps colour

        let original = try await pipeline.export(photo: photo, adjustment: CropAdjustment(), job: job)
        let originalSource = try #require(CGImageSourceCreateWithURL(original.jpeg as CFURL, nil))
        let originalImage = try #require(CGImageSourceCreateImageAtIndex(originalSource, 0, nil))
        #expect(try pixel(originalImage, x: 5, y: 5).contains { $0 < 200 })
        let preview = await pipeline.previewImage(photo: photo, adjustment: edits)
        #expect(try pixel(preview, x: 3, y: 3).allSatisfy { $0 >= 245 })
        await pipeline.discard(exportID: white.id)
        await pipeline.discard(exportID: original.id)
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            let context = try #require(CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                                 space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
        }
        return Array(bytes[0..<3])
    }
}
