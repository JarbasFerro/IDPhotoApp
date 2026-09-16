import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import IDPhotoSpike

struct PhotoPipelineTests {
    private func isolatedRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("PipelineTests-" + UUID().uuidString)
    }

    @Test func stagingSurvivesProviderFileRemoval() async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let provider = try await SyntheticFixture.staged()
        let originalBytes = try Data(contentsOf: provider.url)
        let staged = try await StagedPhoto.stage(provider.url)
        #expect(try Data(contentsOf: provider.url) == originalBytes)
        try FileManager.default.removeItem(at: provider.directory)
        #expect(try Data(contentsOf: staged.url) == originalBytes)
        let photo = try await PhotoPipeline(root: root).ingest(staged)
        #expect(photo.pixels == SourcePixels(width: 800, height: 1_000))
        #expect(!FileManager.default.fileExists(atPath: staged.directory.path))
    }

    @Test(arguments: [UTType.png, UTType.heic])
    func importsOtherFormatsAndConvertsWideGamutToSRGB(encoding: UTType) async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let staged = try await SyntheticFixture.staged(encoding: encoding, wideGamut: true)
        let photo = try await pipeline.ingest(staged)
        let result = try await pipeline.export(photo: photo, adjustment: CropAdjustment())
        try PhotoPipeline.verifyJPEG(result.jpeg, expected: PhotoFormat.spainPrototype.output)
        let source = try #require(CGImageSourceCreateWithURL(result.jpeg as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.colorSpace?.name == CGColorSpace.sRGB)
    }

    @Test(arguments: Array(1...8))
    func orientationExportMetadataAndOriginalPreservation(orientation: Int) async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let staged = try await SyntheticFixture.staged(orientation: orientation)
        let original = try Data(contentsOf: staged.url)
        let photo = try await pipeline.ingest(staged)
        #expect(!FileManager.default.fileExists(atPath: staged.directory.path))
        #expect(photo.pixels == (orientation >= 5 ? SourcePixels(width: 1_000, height: 800)
                                                  : SourcePixels(width: 800, height: 1_000)))
        #expect(max(photo.preview.width, photo.preview.height) <= 1_600)
        let result = try await pipeline.export(photo: photo, adjustment: CropAdjustment())
        try PhotoPipeline.verifyJPEG(result.jpeg, expected: PhotoFormat.spainPrototype.output)
        try PhotoPipeline.verifyPDF(result.pdf)
        let copy = root.appendingPathComponent("photos/" + photo.id.uuidString + "/original")
        #expect(try Data(contentsOf: copy) == original)
        let source = try #require(CGImageSourceCreateWithURL(result.jpeg as CFURL, nil))
        let props = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect(props[kCGImagePropertyGPSDictionary] == nil)
        let rendered = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        // Orientation and crop must match the same upright preview users adjusted.
        for point in [(0.15, 0.15), (0.85, 0.15), (0.15, 0.85), (0.85, 0.85)] {
            let crop = CropAdjustment().crop(in: photo.pixels)
            let expected = try pixel(photo.preview, x: crop.x + crop.width * point.0, y: crop.y + crop.height * point.1)
            let actual = try pixel(rendered, x: point.0, y: point.1)
            #expect(zip(actual, expected).allSatisfy { abs(Int($0) - Int($1)) <= 15 })
        }
        await pipeline.discard(photoID: photo.id)
        #expect(!FileManager.default.fileExists(atPath: copy.path))
        // Export lifetime is independent of source lifetime until sharing ends.
        #expect(FileManager.default.fileExists(atPath: result.jpeg.path))
        await pipeline.discard(exportID: result.id)
        #expect(!FileManager.default.fileExists(atPath: result.jpeg.path))
    }

    @Test func cropAtTopAndBottomUsesCorrectCoordinateOrigin() async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let photo = try await pipeline.ingest(SyntheticFixture.staged())
        for y in [0.0, 1.0] {
            let edit = CropAdjustment(zoom: 4, horizontal: 0, vertical: y)
            let result = try await pipeline.export(photo: photo, adjustment: edit)
            let source = try #require(CGImageSourceCreateWithURL(result.jpeg as CFURL, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
            let crop = edit.crop(in: photo.pixels)
            let expected = try pixel(photo.preview, x: crop.x + crop.width / 2, y: crop.y + crop.height / 2)
            let actual = try pixel(image, x: 0.5, y: 0.5)
            #expect(zip(actual, expected).allSatisfy { abs(Int($0) - Int($1)) <= 15 })
        }
    }

    @Test func corruptInputIsRejectedAndStagingRemoved() async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let directory = root.appendingPathComponent("staging")
        try PhotoFiles.createPrivateDirectory(directory)
        let staged = StagedPhoto(directory: directory)
        try Data("not an image".utf8).write(to: staged.url)
        await #expect(throws: PhotoError.self) { try await pipeline.ingest(staged) }
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func alreadyCancelledImportReleasesStaging() async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        let staged = try await SyntheticFixture.staged()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await pipeline.ingest(staged)
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath: staged.directory.path))
    }

    @Test func largeSourcePreviewRemainsBounded() async throws {
        let root = isolatedRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        // Synthetic 48 MP fixture, generated at runtime; no photo is committed.
        let staged = try await SyntheticFixture.staged(width: 8_000, height: 6_000)
        let photo = try await pipeline.ingest(staged)
        #expect(photo.pixels == SourcePixels(width: 8_000, height: 6_000))
        #expect(max(photo.preview.width, photo.preview.height) == 1_600)
        let result = try await pipeline.export(photo: photo, adjustment: CropAdjustment(zoom: 4))
        try PhotoPipeline.verifyJPEG(result.jpeg, expected: PhotoFormat.spainPrototype.output)
    }

    /// Rasterizes into an explicit RGBA layout. Returned coordinates are top-left.
    private func pixel(_ image: CGImage, x: Double, y: Double) throws -> [UInt8] {
        let width = 40, height = 40
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            let context = try #require(CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let index = (min(height - 1, Int(y * Double(height))) * width + min(width - 1, Int(x * Double(width)))) * 4
        return Array(bytes[index..<(index + 3)])
    }
}
