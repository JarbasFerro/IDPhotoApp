import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

// macOS fixture harness for spike 03. Compiles the spike's domain geometry and Vision adapter unchanged
// (see scripts/face-harness.sh) and runs them over private portraits that never enter the repository.
// Usage: face-harness <pictures folder> <output folder>
// Output: report.txt plus fixture-N-annotated.jpg and fixture-N-aligned.jpg per picture.

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    FileHandle.standardError.write(Data("usage: face-harness <pictures folder> <output folder>\n".utf8))
    exit(2)
}
let inputFolder = URL(fileURLWithPath: arguments[1])
let outputFolder = URL(fileURLWithPath: arguments[2])
try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
let pictures = try FileManager.default.contentsOfDirectory(at: inputFolder, includingPropertiesForKeys: nil)
    .filter { ["jpg", "jpeg", "heic", "png"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

var lines = ["FACE-REPORT-BEGIN",
             "idx | source px | faces | IED px | roll eye/vision | yaw | pitch | crown method conf | mask-anthro (IED) | implied k | head % | eye % | zoom | rot | overall | non-pass"]

for (index, url) in pictures.enumerated() {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int,
          let preview = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: 1_600] as CFDictionary)
    else {
        lines.append("\(index) | unreadable")
        continue
    }
    let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
    let swapped = (5...8).contains(orientation)
    let pixels = SourcePixels(width: swapped ? height : width, height: swapped ? width : height)

    let started = Date()
    let analysis: FaceAnalysis
    do {
        analysis = try await FaceAnalyzer.analyze(preview: preview, source: pixels)
    } catch {
        lines.append("\(index) | analysis failed: \(error)")
        continue
    }
    let elapsed = Date().timeIntervalSince(started)
    guard let g = analysis.geometry, let solution = analysis.solution else {
        lines.append("\(index) | \(pixels.width)x\(pixels.height) | \(analysis.faceCount) | no geometry (\(String(format: "%.2f", elapsed)) s)")
        continue
    }
    let iedPx = g.interEyeDistancePixels
    let divergence = g.crown.maskDistance.map { ($0 - g.crown.anthropometricDistance) / iedPx }
    let impliedK = g.crown.maskDistance.map { ($0 + g.eyeToChinPixels) / g.eyeToChinPixels }
    let nonPass = solution.checks.filter { $0.state != .pass }.map { "\($0.kind.rawValue):\($0.state.rawValue)" }.joined(separator: ",")
    lines.append(String(format: "%d | %dx%d | %d | %.0f | %.1f/%.1f | %.1f | %.1f | %@ %.2f | %@ | %@ | %.0f | %.0f | %.2f | %.1f | %@ | %@ | %.2f s",
                        index, g.source.width, g.source.height, analysis.faceCount, iedPx, g.rollDegrees, analysis.visionRollDegrees ?? 0,
                        g.yawDegrees, g.pitchDegrees, g.crown.method.rawValue, g.crown.confidence,
                        divergence.map { String(format: "%.2f", $0) } ?? "–", impliedK.map { String(format: "%.2f", $0) } ?? "–",
                        solution.headHeightFraction * 100, solution.eyeLineFraction * 100, solution.adjustment.zoom,
                        solution.adjustment.rotationDegrees, solution.overall.rawValue, nonPass, elapsed))

    if let mask = await FaceAnalyzer.personMask(ImageRequestHandler(preview)) {
        try writeJPEG(mask, to: outputFolder.appendingPathComponent("fixture-\(index)-mask.jpg"))
        lines.append("    mask \(mask.width)x\(mask.height) bitsPerComponent \(mask.bitsPerComponent) alpha \(mask.alphaInfo.rawValue)")
    }
    let crop = solution.adjustment.crop(in: pixels)
    try writeAnnotated(preview: preview, geometry: g, crop: crop, to: outputFolder.appendingPathComponent("fixture-\(index)-annotated.jpg"))
    try writeAligned(preview: preview, crop: crop, rotationDegrees: solution.adjustment.rotationDegrees,
                     to: outputFolder.appendingPathComponent("fixture-\(index)-aligned.jpg"))
}
lines.append("FACE-REPORT-END")
print(lines.joined(separator: "\n"))
try lines.joined(separator: "\n").write(to: outputFolder.appendingPathComponent("report.txt"), atomically: true, encoding: .utf8)

// MARK: - Drawing helpers

func writeJPEG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

/// Eyes (yellow), chin (orange), mask crown (blue), anthropometric crown (red dashed), chosen crown (green), crop (white/black).
func writeAnnotated(preview: CGImage, geometry g: FaceGeometry, crop: NormalizedCrop, to url: URL) throws {
    let width = preview.width, height = preview.height
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
    context.draw(preview, in: CGRect(x: 0, y: 0, width: width, height: height))
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
    context.setLineDash(phase: 0, lengths: [])
    for eye in [g.leftEye, g.rightEye] {
        context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 0, alpha: 1)); context.setLineWidth(3)
        context.strokeEllipse(in: CGRect(x: eye.x * w - 8, y: eye.y * h - 8, width: 16, height: 16))
    }
    let cropRect = CGRect(x: crop.x * w, y: crop.y * h, width: crop.width * w, height: crop.height * h)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)); context.setLineWidth(4); context.stroke(cropRect)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)); context.setLineWidth(1.5); context.stroke(cropRect)
    guard let image = context.makeImage() else { return }
    try writeJPEG(image, to: url)
}

/// Same mapping as the spike pipeline's renderer: crop to the output rectangle, rotating the source about the crop centre.
func writeAligned(preview: CGImage, crop: NormalizedCrop, rotationDegrees: Double, to url: URL) throws {
    let output = PhotoFormat.spainPrototype.output
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: output.width, height: output.height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
    let width = Double(output.width), height = Double(output.height)
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.interpolationQuality = .high
    if rotationDegrees != 0 {
        context.translateBy(x: width / 2, y: height / 2)
        context.rotate(by: rotationDegrees * .pi / 180)
        context.translateBy(x: -width / 2, y: -height / 2)
    }
    context.draw(preview, in: CGRect(x: -crop.x / crop.width * width, y: -(1 - crop.y - crop.height) / crop.height * height,
                                     width: width / crop.width, height: height / crop.height))
    guard let image = context.makeImage() else { return }
    try writeJPEG(image, to: url)
}
