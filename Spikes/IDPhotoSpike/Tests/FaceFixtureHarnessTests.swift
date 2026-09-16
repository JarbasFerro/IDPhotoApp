import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import IDPhotoSpike

/// Runs the face pipeline over private portraits in `<repo>/pics` (git-ignored) and writes annotated
/// previews plus aligned exports to `<repo>/Artifacts/face-report` (git-ignored). Skipped when the
/// folder is absent, so CI never depends on personal photos (ADR-027).
struct FaceFixtureHarnessTests {
    static let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let picturesFolder = repoRoot.appendingPathComponent("pics")
    static let reportFolder = repoRoot.appendingPathComponent("Artifacts/face-report")

    static var pictures: [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: picturesFolder, includingPropertiesForKeys: nil)) ?? []
        return urls.filter { ["jpg", "jpeg", "heic", "png"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    @Test(.enabled(if: !FaceFixtureHarnessTests.pictures.isEmpty, "No private fixtures in pics/"))
    func privatePortraitsAlignAndReport() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FaceHarness-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let pipeline = PhotoPipeline(root: root)
        // The iOS simulators available here cannot create a Vision inference context; the macOS harness
        // (scripts/face-harness.sh) provides the real-face evidence until a physical device runs this test.
        do {
            _ = try await pipeline.analyze(photo: try await pipeline.ingest(stage(Self.pictures[0])))
        } catch {
            withKnownIssue("Vision inference is unavailable in this environment") { throw error }
            return
        }
        try FileManager.default.createDirectory(at: Self.reportFolder, withIntermediateDirectories: true)
        var lines = ["FACE-REPORT-BEGIN",
                     "idx | source px | faces | IED px | roll eye/vision | yaw | pitch | crown method conf | mask-anthro (IED) | implied k | head % | eye % | zoom | rot | overall | non-pass"]
        for (index, url) in Self.pictures.enumerated() {
            let staged = try stage(url)
            let photo = try await pipeline.ingest(staged)
            let analysis = try await pipeline.analyze(photo: photo)
            #expect(analysis.faceCount == 1, "fixture \(index): \(analysis.faceCount) faces")
            guard let g = analysis.geometry, let solution = analysis.solution else {
                lines.append("\(index) | no geometry")
                continue
            }
            #expect(g.eyeToChinPixels > 0 && g.crown.distanceAboveEyes > 0, "fixture \(index): chin/eye/crown order")
            #expect(g.crownPoint.y >= -0.01 && g.chin.y <= 1)
            let crop = solution.adjustment.crop(in: g.source)
            #expect(crop.x >= -0.000_001 && crop.y >= -0.000_001 && crop.x + crop.width <= 1.000_001 && crop.y + crop.height <= 1.000_001)
            let iedPx = g.interEyeDistancePixels
            let divergence = g.crown.maskDistance.map { ($0 - g.crown.anthropometricDistance) / iedPx }
            let impliedK = g.crown.maskDistance.map { ($0 + g.eyeToChinPixels) / g.eyeToChinPixels }
            let nonPass = solution.checks.filter { $0.state != .pass }.map { "\($0.kind.rawValue):\($0.state.rawValue)" }.joined(separator: ",")
            lines.append(String(format: "%d | %dx%d | %d | %.0f | %.1f/%.1f | %.1f | %.1f | %@ %.2f | %@ | %@ | %.0f | %.0f | %.2f | %.1f | %@ | %@",
                                index, g.source.width, g.source.height, analysis.faceCount, iedPx, g.rollDegrees, analysis.visionRollDegrees ?? 0,
                                g.yawDegrees, g.pitchDegrees, g.crown.method.rawValue, g.crown.confidence,
                                divergence.map { String(format: "%.2f", $0) } ?? "–", impliedK.map { String(format: "%.2f", $0) } ?? "–",
                                solution.headHeightFraction * 100, solution.eyeLineFraction * 100, solution.adjustment.zoom,
                                solution.adjustment.rotationDegrees, solution.overall.rawValue, nonPass))
            try writeAnnotated(photo: photo, geometry: g, crop: crop, to: Self.reportFolder.appendingPathComponent("fixture-\(index)-annotated.jpg"))
            let export = try await pipeline.export(photo: photo, adjustment: solution.adjustment,
                                                   job: PrintJob(paper: .photo4x6, items: [PrintItem(photoID: photo.id, trimWidthMM: 26, trimHeightMM: 32, copies: 1)]))
            try? FileManager.default.removeItem(at: Self.reportFolder.appendingPathComponent("fixture-\(index)-aligned.jpg"))
            try FileManager.default.copyItem(at: export.jpeg, to: Self.reportFolder.appendingPathComponent("fixture-\(index)-aligned.jpg"))
            await pipeline.discard(exportID: export.id)
            await pipeline.discard(photoID: photo.id)
        }
        lines.append("FACE-REPORT-END")
        print(lines.joined(separator: "\n"))
        try lines.joined(separator: "\n").write(to: Self.reportFolder.appendingPathComponent("report.txt"), atomically: true, encoding: .utf8)
    }

    private func stage(_ url: URL) throws -> StagedPhoto {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("IDPhotoIncoming").appendingPathComponent(UUID().uuidString)
        try PhotoFiles.createPrivateDirectory(directory)
        let staged = StagedPhoto(directory: directory)
        try FileManager.default.copyItem(at: url, to: staged.url)
        return staged
    }

    /// Preview with eyes (circles), chin (short line), mask crown (long line), anthropometric crown (dashed), chosen crown (thick), and crop.
    private func writeAnnotated(photo: PreparedPhoto, geometry g: FaceGeometry, crop: NormalizedCrop, to url: URL) throws {
        let width = photo.preview.width, height = photo.preview.height
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.draw(photo.preview, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Flip to top-left coordinates for annotation.
        context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
        let w = Double(width), h = Double(height)
        func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ color: CGColor, _ lineWidth: CGFloat, dashed: Bool = false) {
            context.setStrokeColor(color); context.setLineWidth(lineWidth)
            context.setLineDash(phase: 0, lengths: dashed ? [8, 6] : [])
            context.move(to: CGPoint(x: x0 * w, y: y0 * h)); context.addLine(to: CGPoint(x: x1 * w, y: y1 * h)); context.strokePath()
        }
        // Crown and chin markers are drawn perpendicular to the head axis.
        let frame = g.headFrame
        func axisLine(distanceAboveEyes: Double, halfLength: Double, _ color: CGColor, _ lineWidth: CGFloat, dashed: Bool = false) {
            let a = frame.toImage(ImagePoint(x: -halfLength, y: -distanceAboveEyes))
            let b = frame.toImage(ImagePoint(x: halfLength, y: -distanceAboveEyes))
            line(a.x / Double(g.source.width), a.y / Double(g.source.height), b.x / Double(g.source.width), b.y / Double(g.source.height), color, lineWidth, dashed: dashed)
        }
        let half = 1.2 * g.interEyeDistancePixels
        if let mask = g.crown.maskDistance { axisLine(distanceAboveEyes: mask, halfLength: half, CGColor(srgbRed: 0, green: 0.4, blue: 1, alpha: 1), 3) }
        axisLine(distanceAboveEyes: g.crown.anthropometricDistance, halfLength: half, CGColor(srgbRed: 1, green: 0.2, blue: 0.2, alpha: 1), 3, dashed: true)
        axisLine(distanceAboveEyes: g.crown.distanceAboveEyes, halfLength: half, CGColor(srgbRed: 0, green: 0.8, blue: 0.2, alpha: 1), 6)
        axisLine(distanceAboveEyes: -g.eyeToChinPixels, halfLength: half / 2, CGColor(srgbRed: 1, green: 0.6, blue: 0, alpha: 1), 4)
        line(g.rightEye.x, g.rightEye.y, g.leftEye.x, g.leftEye.y, CGColor(srgbRed: 1, green: 1, blue: 0, alpha: 1), 3)
        for eye in [g.leftEye, g.rightEye] {
            context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 0, alpha: 1)); context.setLineWidth(3); context.setLineDash(phase: 0, lengths: [])
            context.strokeEllipse(in: CGRect(x: eye.x * w - 8, y: eye.y * h - 8, width: 16, height: 16))
        }
        context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)); context.setLineWidth(4); context.setLineDash(phase: 0, lengths: [])
        context.stroke(CGRect(x: crop.x * w, y: crop.y * h, width: crop.width * w, height: crop.height * h))
        context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)); context.setLineWidth(1.5)
        context.stroke(CGRect(x: crop.x * w, y: crop.y * h, width: crop.width * w, height: crop.height * h))
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
    }
}
