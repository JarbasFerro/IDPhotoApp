import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import IDPhotoSpike

struct ToneTests {
    @Test func assessmentThresholds() {
        let fine = ToneMetrics(faceMeanLuminance: 0.5, faceClippedDark: 0, faceClippedBright: 0, backgroundCast: 0.02)
        #expect(ToneAssessment.assess(fine).state == .pass)
        let dark = ToneMetrics(faceMeanLuminance: 0.2, faceClippedDark: 0, faceClippedBright: 0, backgroundCast: 0)
        #expect(ToneAssessment.assess(dark).issues == [.underexposed])
        let blown = ToneMetrics(faceMeanLuminance: 0.6, faceClippedDark: 0, faceClippedBright: 0.01, backgroundCast: 0)
        #expect(ToneAssessment.assess(blown).issues == [.clipped] && ToneAssessment.assess(blown).state == .warn)
        let warm = ToneMetrics(faceMeanLuminance: 0.6, faceClippedDark: 0, faceClippedBright: 0, backgroundCast: 0.1)
        #expect(ToneAssessment.assess(warm).issues == [.colourCast])
        #expect(ToneSettings(isEnabled: true, strength: .nan).clamped().strength == 0.6)
        #expect(ToneSettings(isEnabled: true, strength: 3).clamped().strength == 1)
    }

    /// Warm-cast scene: light beige background, mid-tone face patch, darker "shirt".
    private func scene() throws -> (image: CGImage, mask: CGImage, faceBox: NormalizedCrop) {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: 400, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.setFillColor(CGColor(srgbRed: 0.90, green: 0.84, blue: 0.72, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
        context.setFillColor(CGColor(srgbRed: 0.30, green: 0.32, blue: 0.45, alpha: 1)); context.fill(CGRect(x: 100, y: 0, width: 200, height: 200))
        context.setFillColor(CGColor(srgbRed: 0.72, green: 0.55, blue: 0.45, alpha: 1)); context.fill(CGRect(x: 140, y: 200, width: 120, height: 150))
        let gray = try #require(CGColorSpace(name: CGColorSpace.linearGray))
        let mask = try #require(CGContext(data: nil, width: 400, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: gray, bitmapInfo: CGImageAlphaInfo.none.rawValue))
        mask.setFillColor(CGColor(gray: 0, alpha: 1)); mask.fill(CGRect(x: 0, y: 0, width: 400, height: 500))
        mask.setFillColor(CGColor(gray: 1, alpha: 1)); mask.fill(CGRect(x: 100, y: 0, width: 200, height: 350))
        return (try #require(context.makeImage()), try #require(mask.makeImage()), NormalizedCrop(x: 0.35, y: 0.3, width: 0.3, height: 0.3))
    }

    @Test func strengthZeroIsIdentityAndFullStrengthNeutralisesTheCast() throws {
        let s = try scene()
        let reference = try #require(ToneAdjuster.backgroundReference(of: s.image, mask: s.mask))
        #expect(reference.red > reference.blue) // warm
        let unchanged = try #require(ToneAdjuster.shared.adjusted(image: s.image, settings: ToneSettings(isEnabled: true, strength: 0), backgroundReference: reference))
        #expect(unchanged === s.image)
        let off = try #require(ToneAdjuster.shared.adjusted(image: s.image, settings: .off, backgroundReference: reference))
        #expect(off === s.image)

        let full = try #require(ToneAdjuster.shared.adjusted(image: s.image, settings: ToneSettings(isEnabled: true, strength: 1), backgroundReference: reference, faceBox: s.faceBox))
        #expect(full.width == 400 && full.height == 500)
        let before = ToneAdjuster.metrics(of: s.image, faceBox: s.faceBox, mask: s.mask)
        let after = ToneAdjuster.metrics(of: full, faceBox: s.faceBox, mask: s.mask)
        #expect(abs(after.backgroundCast) < abs(before.backgroundCast), "\(before.backgroundCast) -> \(after.backgroundCast)")
        // Global correction: the face stays a face, no clipping is introduced.
        #expect(abs(after.faceMeanLuminance - before.faceMeanLuminance) < 0.15)
        #expect(after.faceClippedBright <= ToneAssessment.clippingLimit && after.faceClippedDark <= ToneAssessment.clippingLimit)

        let half = try #require(ToneAdjuster.shared.adjusted(image: s.image, settings: ToneSettings(isEnabled: true, strength: 0.5), backgroundReference: reference, faceBox: s.faceBox))
        let halfMetrics = ToneAdjuster.metrics(of: half, faceBox: s.faceBox, mask: s.mask)
        #expect(abs(halfMetrics.backgroundCast) < abs(before.backgroundCast) && abs(halfMetrics.backgroundCast) > abs(after.backgroundCast) - 0.001)
    }

    @Test func sharpeningKeepsSizeAndIsIdentityWhenOff() throws {
        let s = try scene()
        let sharp = try #require(ToneAdjuster.shared.sharpened(image: s.image, settings: ToneSettings()))
        #expect(sharp.width == 400 && sharp.height == 500)
        #expect(ToneAdjuster.shared.sharpened(image: s.image, settings: .off) === s.image)
    }

    @Test func exportAppliesToneBeforeWhiteBackgroundSoWhiteStaysWhite() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("ToneTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let photo = try await pipeline.ingest(SyntheticFixture.staged())
        let gray = try #require(CGColorSpace(name: CGColorSpace.linearGray))
        let mask = try #require(CGContext(data: nil, width: photo.preview.width, height: photo.preview.height, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: gray, bitmapInfo: CGImageAlphaInfo.none.rawValue))
        mask.setFillColor(CGColor(gray: 0, alpha: 1)); mask.fill(CGRect(x: 0, y: 0, width: photo.preview.width, height: photo.preview.height))
        mask.setFillColor(CGColor(gray: 1, alpha: 1))
        mask.fill(CGRect(x: photo.preview.width / 4, y: 0, width: photo.preview.width / 2, height: photo.preview.height * 3 / 5))
        await pipeline.setMask(try #require(mask.makeImage()), for: photo.id)
        var edits = CropAdjustment()
        edits.background = .color(.white)
        edits.tone = ToneSettings(isEnabled: true, strength: 1)
        let job = PrintJob(paper: .photo10x15, items: [PrintItem(photoID: photo.id, trimWidthMM: 26, trimHeightMM: 32, copies: 1)])
        let export = try await pipeline.export(photo: photo, adjustment: edits, job: job)
        let source = try #require(CGImageSourceCreateWithURL(export.jpeg as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(try pixel(image, x: 5, y: 5).allSatisfy { $0 >= 245 })
        try PhotoPipeline.verifyJPEG(export.jpeg, expected: PhotoFormat.spainPrototype.output)
        let metrics = await pipeline.toneMetrics(photo: photo, adjustment: edits, faceBox: nil)
        #expect(metrics.faceMeanLuminance > 0 && metrics.faceMeanLuminance < 1)
        await pipeline.discard(exportID: export.id)
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
