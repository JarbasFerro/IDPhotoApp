import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import IDPhotoSpike

/// 0.14: custom-size options (ADR-018) and per-document page resolution (L19-020).
struct CustomSizeOptionsTests {
    /// Crown-to-eye share of head height used by the crown estimator (crown-to-chin = 1.8 × eye-to-chin).
    private let crownToEye = 0.8 / 1.8

    @Test(arguments: FramingPreset.allCases)
    func framingPresetsKeepHeadroomAndChin(_ preset: FramingPreset) {
        let headroom = preset.eyeLineTarget - crownToEye * preset.headHeightTarget
        let chin = preset.eyeLineTarget + (1 - crownToEye) * preset.headHeightTarget
        #expect(headroom >= 0.07, "headroom \(headroom)")
        #expect(chin <= 0.95, "chin \(chin)")
    }

    @Test(arguments: FramingPreset.allCases)
    func framedTargetsSitInsideTheirOwnBands(_ preset: FramingPreset) {
        let spec = DocumentChoice.custom(widthMM: 30, heightMM: 40).renderTarget.framed(preset).spec
        #expect(spec.headHeightRange.contains(spec.headHeightTarget))
        // Not within the 0.03 warning margin of either band edge: the person's own choice never warns.
        #expect(spec.headHeightTarget - spec.headHeightRange.lowerBound >= 0.03)
        #expect(spec.headHeightRange.upperBound - spec.headHeightTarget >= 0.03)
    }

    @Test func standardFramingIsTheUnchangedTarget() {
        let target = DocumentChoice.custom(widthMM: 30, heightMM: 40).renderTarget
        #expect(target.framed(.standard) == target)
    }

    @Test func customSizesOfferWhiteAndLightGrey() throws {
        #expect(DocumentChoice.custom(widthMM: 25, heightMM: 30).replacementColors == [.white, .lightGrey])
        let uk = try #require(ProfileCatalog.bundled.profile("gb.passport.standard"))
        #expect(DocumentChoice.official(uk).replacementColors == [.lightGrey])
        #expect(BackgroundColor(hex: "#E6E6E6") == .lightGrey)
    }

    @Test func netherlandsPagesAre400ppiAndOthers300() throws {
        let nl = try #require(ProfileCatalog.bundled.profile("nl.passport.standard"))
        #expect(DocumentChoice.official(nl).renderTarget.pagePixelsPerInch == 400)
        let es = try #require(ProfileCatalog.bundled.profile("es.national-id.dni"))
        #expect(DocumentChoice.official(es).renderTarget.pagePixelsPerInch == 300)
        #expect(DocumentChoice.custom(widthMM: 30, heightMM: 40).renderTarget.pagePixelsPerInch == 300)
    }

    @Test func pageJPEGSizeFollowsTheResolution() {
        let page = PrintPage(widthMM: 101.6, heightMM: 152.4, bleedMM: 0, placements: [], calibrationBar: nil)
        #expect(SheetRenderer.jpegPixelSize(for: page) == OutputPixels(width: 1_200, height: 1_800))
        #expect(SheetRenderer.jpegPixelSize(for: page, pixelsPerInch: 400) == OutputPixels(width: 1_600, height: 2_400))
    }

    @Test func monochromeExportIsNeutralGrey() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Mono-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let photo = try await pipeline.ingest(SyntheticFixture.staged())
        var edit = CropAdjustment()
        edit.monochrome = true
        let target = DocumentChoice.custom(widthMM: 30, heightMM: 40).renderTarget
        let result = try await pipeline.exportDigital(edit: PhotoEdit(photo: photo, adjustment: edit), target: target)
        let source = try #require(CGImageSourceCreateWithURL(result.jpeg as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.width == 600 && image.height == 800)
        var spread = 0
        for (x, y) in [(0.5, 0.5), (0.2, 0.3), (0.8, 0.7), (0.5, 0.15)] {
            let rgb = try pixel(image, x: x, y: y)
            spread = max(spread, Int(rgb.max()!) - Int(rgb.min()!))
        }
        // JPEG chroma can drift by a step or two; a coloured fixture would differ by far more.
        #expect(spread <= 4, "channel spread \(spread)")
        await pipeline.discard(exportID: result.id)
    }

    private func pixel(_ image: CGImage, x: Double, y: Double) throws -> [UInt8] {
        var data = [UInt8](repeating: 0, count: 4)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                             space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.draw(image, in: CGRect(x: -x * Double(image.width), y: -(1 - y) * Double(image.height),
                                      width: Double(image.width), height: Double(image.height)))
        return Array(data[0..<3])
    }
}

@MainActor
struct FramingWorkflowTests {
    @Test func framingAppliesToCustomSizesOnly() throws {
        let model = PhotoWorkflow(pipeline: PhotoPipeline(root: FileManager.default.temporaryDirectory
            .appendingPathComponent("Framing-" + UUID().uuidString)))
        let context = try #require(CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        let preview = try #require(context.makeImage())
        var entry = PhotoEntry(photo: PreparedPhoto(id: UUID(), pixels: SourcePixels(width: 4, height: 4), preview: preview))
        entry.framing = .closer
        model.setDocument(.custom(widthMM: 30, heightMM: 40))
        #expect(model.target(for: entry).spec.headHeightTarget == FramingPreset.closer.headHeightTarget)
        let es = try #require(ProfileCatalog.bundled.profile("es.national-id.dni"))
        model.setDocument(.official(es))
        #expect(model.target(for: entry) == model.renderTarget)
    }
}
