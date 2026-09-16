import CoreGraphics
import Foundation
import OSLog
import Vision

struct FaceAnalysis: Sendable, Hashable {
    let faceCount: Int
    let geometry: FaceGeometry?
    let solution: CropSolution?
    /// Vision's own roll estimate, kept for comparison with the eye-line roll used by the solver.
    let visionRollDegrees: Double?
}

/// Vision adapter. Converts observations to top-left normalized domain geometry immediately (FR-042)
/// and pins request revisions so iOS 26 and iOS 27 produce identical geometry (ADR-040).
enum FaceAnalyzer {
    private static let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "FaceAnalysis")

    static func analyze(preview: CGImage, source: SourcePixels, format: PhotoFormat = .spainPrototype,
                        spec: CompositionSpec = .icaoEngineeringDefault) async throws -> FaceAnalysis {
        let interval = signposter.beginInterval("FaceAnalysis")
        defer { signposter.endInterval("FaceAnalysis", interval) }
        let handler = ImageRequestHandler(preview)
        let faces = try await handler.perform(DetectFaceLandmarksRequest(.revision3))
        try Task.checkCancellation()
        // Segmentation is a crown prior, never a hard dependency: some environments (notably the simulator)
        // cannot create an inference context, and the estimator then falls back to anatomy.
        let mask = await personMask(handler)
        try Task.checkCancellation()

        let size = CGSize(width: preview.width, height: preview.height)
        guard let face = faces.max(by: { $0.boundingBox.cgRect.width * $0.boundingBox.cgRect.height
                                            < $1.boundingBox.cgRect.width * $1.boundingBox.cgRect.height }),
              let landmarks = face.landmarks else {
            return FaceAnalysis(faceCount: faces.count, geometry: nil, solution: nil, visionRollDegrees: nil)
        }

        func normalized(_ point: CGPoint) -> ImagePoint { ImagePoint(x: point.x / size.width, y: point.y / size.height) }
        func centroid(_ region: FaceObservation.Landmarks2D.Region) -> ImagePoint? {
            let points = region.pointsInImageCoordinates(size, origin: .upperLeft)
            guard !points.isEmpty else { return nil }
            let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            return normalized(CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count)))
        }
        guard let eyeA = centroid(landmarks.leftPupil) ?? centroid(landmarks.leftEye),
              let eyeB = centroid(landmarks.rightPupil) ?? centroid(landmarks.rightEye),
              let chinPoint = landmarks.faceContour.pointsInImageCoordinates(size, origin: .upperLeft).max(by: { $0.y < $1.y })
        else {
            return FaceAnalysis(faceCount: faces.count, geometry: nil, solution: nil, visionRollDegrees: nil)
        }
        // Vision names eyes from the viewer's side. The domain stores the subject's left eye, which appears
        // on the image's right, so order by x rather than trusting the label.
        let (rightEye, leftEye) = eyeA.x < eyeB.x ? (eyeA, eyeB) : (eyeB, eyeA)
        let chin = normalized(chinPoint)
        let box = face.boundingBox.toImageCoordinates(size, origin: .upperLeft)
        let faceBox = NormalizedCrop(x: box.minX / size.width, y: box.minY / size.height,
                                     width: box.width / size.width, height: box.height / size.height)

        // Eye-line roll in screen space: positive = counter-clockwise, so levelling rotates by the negative.
        let dx = (leftEye.x - rightEye.x) * Double(source.width)
        let dy = (leftEye.y - rightEye.y) * Double(source.height)
        let roll = atan2(-dy, dx) * 180 / .pi
        let iedPreviewPixels = ((leftEye.x - rightEye.x) * size.width * (leftEye.x - rightEye.x) * size.width
                                + (leftEye.y - rightEye.y) * size.height * (leftEye.y - rightEye.y) * size.height).squareRoot()
        let eyeMid = ImagePoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2)
        let maskTop = mask.flatMap { maskTop($0, columnCenter: eyeMid.x, halfWidth: 0.6 * iedPreviewPixels / size.width) }
        let iedSourcePixels = (dx * dx + dy * dy).squareRoot()
        let crown = CrownEstimator.estimate(chinY: chin.y, eyeY: eyeMid.y, maskTopY: maskTop,
                                            interEyeDistancePixels: iedSourcePixels, sourceHeight: source.height)
        let geometry = FaceGeometry(source: source, faceCount: faces.count, faceBox: faceBox, leftEye: leftEye,
                                    rightEye: rightEye, chin: chin, crown: crown, rollDegrees: roll,
                                    yawDegrees: face.yaw.converted(to: .degrees).value,
                                    pitchDegrees: face.pitch.converted(to: .degrees).value)
        let solution = CropSolver.solve(geometry: geometry, format: format, spec: spec)
        return FaceAnalysis(faceCount: faces.count, geometry: geometry, solution: solution,
                            visionRollDegrees: face.roll.converted(to: .degrees).value)
    }

    /// Accurate person mask, falling back to the balanced model and then to no mask.
    static func personMask(_ handler: ImageRequestHandler) async -> CGImage? {
        for level in [GeneratePersonSegmentationRequest.QualityLevel.accurate, .balanced] {
            let request = GeneratePersonSegmentationRequest()
            request.qualityLevel = level
            if let observation = try? await handler.perform(request), let image = try? observation.cgImage {
                return image
            }
        }
        return nil
    }

    /// Topmost row (normalized, top-left) where more than half of the column band is foreground.
    static func maskTop(_ mask: CGImage, columnCenter: Double, halfWidth: Double) -> Double? {
        let width = 192
        let height = max(1, Int((Double(width) * Double(mask.height) / Double(mask.width)).rounded()))
        var bytes = [UInt8](repeating: 0, count: width * height)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let space = CGColorSpace(name: CGColorSpace.linearGray),
                  let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.interpolationQuality = .medium
            context.draw(mask, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        let x0 = max(0, Int((columnCenter - halfWidth) * Double(width)))
        let x1 = min(width - 1, Int((columnCenter + halfWidth) * Double(width)))
        guard x1 >= x0 else { return nil }
        // Bitmap memory row 0 is the top scanline even though Core Graphics draws with a bottom-left origin.
        for row in 0..<height {
            var foreground = 0
            for x in x0...x1 where bytes[row * width + x] >= 128 { foreground += 1 }
            if Double(foreground) > 0.5 * Double(x1 - x0 + 1) {
                return Double(row) / Double(height)
            }
        }
        return nil
    }
}
