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
    /// iOS 26 lens-smudge confidence 0...1; nil when the request is unavailable.
    var lensSmudgeConfidence: Double? = nil
    /// Eye outline height over width for each eye (`EyeOpenness`); nil when the outlines were not found.
    var eyeOpenness: (left: Double, right: Double)? = nil

    /// Width of the person's outline around the head in inter-eye distances (`HeadOutline`); nil without a mask.
    var headOutlineWidth: Double? = nil

    /// The eyes look closed or turned down (advisory, shown on the camera's review).
    var eyesLookClosed: Bool { eyeOpenness.map { EyeOpenness.looksClosed(left: $0.left, right: $0.right) } ?? false }

    static func == (lhs: FaceAnalysis, rhs: FaceAnalysis) -> Bool {
        lhs.faceCount == rhs.faceCount && lhs.geometry == rhs.geometry && lhs.solution == rhs.solution
            && lhs.visionRollDegrees == rhs.visionRollDegrees && lhs.lensSmudgeConfidence == rhs.lensSmudgeConfidence
            && lhs.eyeOpenness?.left == rhs.eyeOpenness?.left && lhs.eyeOpenness?.right == rhs.eyeOpenness?.right
            && lhs.headOutlineWidth == rhs.headOutlineWidth
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(faceCount); hasher.combine(geometry); hasher.combine(solution)
        hasher.combine(eyeOpenness?.left); hasher.combine(eyeOpenness?.right)
    }

    /// Above this, the source photo probably came through a dirty lens.
    static let smudgeThreshold = 0.75
}

/// Vision adapter. Converts observations to top-left normalized domain geometry immediately (FR-042)
/// and pins request revisions so iOS 26 and iOS 27 produce identical geometry (ADR-040).
enum FaceAnalyzer {
    private static let signposter = OSSignposter(subsystem: "com.jarbasferro.calipic", category: "FaceAnalysis")

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
        let smudge = (try? await handler.perform(DetectLensSmudgeRequest())).map { Double($0.confidence) }

        let size = CGSize(width: preview.width, height: preview.height)
        guard let face = faces.max(by: { $0.boundingBox.cgRect.width * $0.boundingBox.cgRect.height
                                            < $1.boundingBox.cgRect.width * $1.boundingBox.cgRect.height }),
              let landmarks = face.landmarks else {
            return FaceAnalysis(faceCount: faces.count, geometry: nil, solution: nil, visionRollDegrees: nil, lensSmudgeConfidence: smudge)
        }

        func normalized(_ point: CGPoint) -> ImagePoint { ImagePoint(x: point.x / size.width, y: point.y / size.height) }
        func centroid(_ region: FaceObservation.Landmarks2D.Region) -> ImagePoint? {
            let points = region.pointsInImageCoordinates(size, origin: .upperLeft)
            guard !points.isEmpty else { return nil }
            let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            return normalized(CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count)))
        }
        guard let eyeA = centroid(landmarks.leftPupil) ?? centroid(landmarks.leftEye),
              let eyeB = centroid(landmarks.rightPupil) ?? centroid(landmarks.rightEye) else {
            return FaceAnalysis(faceCount: faces.count, geometry: nil, solution: nil, visionRollDegrees: nil)
        }
        // Vision names eyes from the viewer's side. The domain stores the subject's left eye, which appears
        // on the image's right, so order by x rather than trusting the label.
        let (rightEye, leftEye) = eyeA.x < eyeB.x ? (eyeA, eyeB) : (eyeB, eyeA)
        let box = face.boundingBox.toImageCoordinates(size, origin: .upperLeft)
        let faceBox = NormalizedCrop(x: box.minX / size.width, y: box.minY / size.height,
                                     width: box.width / size.width, height: box.height / size.height)

        // Head frame in source pixels; the preview is a uniformly scaled copy of the source.
        let scale = Double(source.width) / size.width
        let eyeMidPx = ImagePoint(x: (leftEye.x + rightEye.x) / 2 * Double(source.width),
                                  y: (leftEye.y + rightEye.y) / 2 * Double(source.height))
        let dx = (leftEye.x - rightEye.x) * Double(source.width)
        let dy = (leftEye.y - rightEye.y) * Double(source.height)
        let frame = HeadFrame(center: eyeMidPx, angleRadians: atan2(dy, dx))
        let ied = (dx * dx + dy * dy).squareRoot()

        // Chin: the contour point farthest down the head axis, not simply the lowest on screen.
        let contour = landmarks.faceContour.pointsInImageCoordinates(size, origin: .upperLeft)
        guard let chinPx = contour.map({ ImagePoint(x: $0.x * scale, y: $0.y * scale) })
                .max(by: { frame.toAligned($0).y < frame.toAligned($1).y }) else {
            return FaceAnalysis(faceCount: faces.count, geometry: nil, solution: nil, visionRollDegrees: nil)
        }
        let eyeToChin = frame.toAligned(chinPx).y
        let chin = ImagePoint(x: chinPx.x / Double(source.width), y: chinPx.y / Double(source.height))

        let maskCrown = mask.flatMap { maskCrown($0, frame: frame, halfWidth: 0.6 * ied, source: source) }
        let crown = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: maskCrown?.distance,
                                            maskTouchesEdge: maskCrown?.touchesEdge ?? false, interEyeDistancePixels: ied)
        let geometry = FaceGeometry(source: source, faceCount: faces.count, faceBox: faceBox, leftEye: leftEye,
                                    rightEye: rightEye, chin: chin, crown: crown, eyeToChinPixels: eyeToChin,
                                    yawDegrees: face.yaw.converted(to: .degrees).value,
                                    pitchDegrees: face.pitch.converted(to: .degrees).value)
        let solution = CropSolver.solve(geometry: geometry, format: format, spec: spec)
        func openness(_ region: FaceObservation.Landmarks2D.Region) -> Double? {
            EyeOpenness.ratio(region.pointsInImageCoordinates(size, origin: .upperLeft).map { (Double($0.x), Double($0.y)) })
        }
        let eyes = openness(landmarks.leftEye).flatMap { left in openness(landmarks.rightEye).map { (left: left, right: $0) } }
        return FaceAnalysis(faceCount: faces.count, geometry: geometry, solution: solution,
                            visionRollDegrees: face.roll.converted(to: .degrees).value, lensSmudgeConfidence: smudge,
                            eyeOpenness: eyes,
                            headOutlineWidth: mask.flatMap { headOutlineWidth($0, eyeMidpoint: eyeMidPx, interEye: ied,
                                                                               eyeToChin: eyeToChin, source: source) })
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

    /// Median width of the mask run through the eye midpoint on nine rows from the eye line up to 0.6 × eye-to-chin
    /// above it, in inter-eye distances (`HeadOutline`). All lengths are in source pixels.
    static func headOutlineWidth(_ mask: CGImage, eyeMidpoint: ImagePoint, interEye: Double, eyeToChin: Double,
                                 source: SourcePixels) -> Double? {
        guard interEye > 0 else { return nil }
        let width = 384
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
        let cellW = Double(source.width) / Double(width), cellH = Double(source.height) / Double(height)
        func on(_ x: Int, _ y: Int) -> Bool { bytes[y * width + x] >= 128 }
        var widths: [Double] = []
        let column = Int(eyeMidpoint.x / cellW)
        for step in 0...8 {
            let y = eyeMidpoint.y - Double(step) / 8 * 0.6 * eyeToChin
            let row = Int(y / cellH)
            guard row >= 0, row < height, column >= 0, column < width, on(column, row) else { continue }
            var left = column, right = column
            while left > 0, on(left - 1, row) { left -= 1 }
            while right < width - 1, on(right + 1, row) { right += 1 }
            widths.append(Double(right - left + 1) * cellW / interEye)
        }
        return HeadOutline.medianWidth(widths)
    }

    /// Farthest foreground pixel above the eyes along the head axis, within a band of `halfWidth` source pixels
    /// either side of the axis. Distances are in source pixels.
    static func maskCrown(_ mask: CGImage, frame: HeadFrame, halfWidth: Double, source: SourcePixels)
        -> (distance: Double, touchesEdge: Bool)? {
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
        // The mask spans the whole image regardless of its own pixel aspect; bitmap row 0 is the top scanline.
        let cellW = Double(source.width) / Double(width), cellH = Double(source.height) / Double(height)
        var best: (distance: Double, point: ImagePoint)?
        for row in 0..<height {
            for column in 0..<width where bytes[row * width + column] >= 128 {
                let p = ImagePoint(x: (Double(column) + 0.5) * cellW, y: (Double(row) + 0.5) * cellH)
                let aligned = frame.toAligned(p)
                guard abs(aligned.x) <= halfWidth, aligned.y < 0 else { continue }
                if best == nil || -aligned.y > best!.distance { best = (-aligned.y, p) }
            }
        }
        guard let best else { return nil }
        let edge = 1.5 * max(cellW, cellH)
        let touchesEdge = best.point.y <= edge || best.point.x <= edge
            || best.point.x >= Double(source.width) - edge
        return (best.distance, touchesEdge)
    }
}
