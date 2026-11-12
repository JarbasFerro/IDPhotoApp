import Foundation

// Face geometry and automatic alignment: pure Swift, no Vision or UI imports.
// Image-frame points are normalized to the upright source with a top-left origin (`NormalizedImageSpace`).
// Head measurements are taken in the head-aligned frame (eye line horizontal) and expressed in source
// pixels, so a tilted head is measured along its own axis rather than vertically.

struct ImagePoint: Sendable, Hashable {
    var x: Double
    var y: Double
}

/// Maps between the image frame and the head-aligned frame. The aligned frame has its origin at the
/// eye midpoint, x along the eye line towards the subject's left (image right), y down along the head axis.
struct HeadFrame: Sendable, Hashable {
    /// Eye midpoint in source pixels.
    let center: ImagePoint
    /// Eye-line angle in screen coordinates: positive when the image-right eye is lower (head tilted clockwise).
    let angleRadians: Double

    var rollDegrees: Double { -angleRadians * 180 / .pi }

    func toAligned(_ p: ImagePoint) -> ImagePoint {
        let dx = p.x - center.x, dy = p.y - center.y
        let c = cos(angleRadians), s = sin(angleRadians)
        return ImagePoint(x: dx * c + dy * s, y: -dx * s + dy * c)
    }

    func toImage(_ p: ImagePoint) -> ImagePoint {
        let c = cos(angleRadians), s = sin(angleRadians)
        return ImagePoint(x: center.x + p.x * c - p.y * s, y: center.y + p.x * s + p.y * c)
    }
}

enum CrownMethod: String, Sendable, Hashable {
    /// Top of the person mask along the head axis; used when it agrees with anatomy.
    case mask
    /// Extrapolated from chin and eye line; used when hair, headwear, or a bad mask disagree.
    case anthropometric
}

struct CrownEstimate: Sendable, Hashable {
    /// Distance from the eye midpoint to the crown along the head axis, in source pixels.
    let distanceAboveEyes: Double
    let method: CrownMethod
    /// 0...1; 0.9 when mask and anatomy agree, lower otherwise.
    let confidence: Double
    let maskDistance: Double?
    let anthropometricDistance: Double
    /// True when the mask reaches the image edge above the head: the head is probably cut off.
    let headTouchesEdge: Bool
    /// True when the mask sits well above the anatomical estimate: tall hair or headwear.
    let hairVolume: Bool
}

struct FaceGeometry: Sendable, Hashable {
    let source: SourcePixels
    let faceCount: Int
    /// Vision face rectangle, top-left normalized. Excludes hair.
    let faceBox: NormalizedCrop
    /// Subject's left eye appears on the image's right.
    let leftEye: ImagePoint
    let rightEye: ImagePoint
    let chin: ImagePoint
    let crown: CrownEstimate
    /// Chin distance below the eye midpoint along the head axis, in source pixels.
    let eyeToChinPixels: Double
    let yawDegrees: Double
    let pitchDegrees: Double

    var eyeMidpoint: ImagePoint {
        ImagePoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2)
    }

    var eyeMidpointPixels: ImagePoint {
        ImagePoint(x: eyeMidpoint.x * Double(source.width), y: eyeMidpoint.y * Double(source.height))
    }

    var headFrame: HeadFrame {
        let dx = (leftEye.x - rightEye.x) * Double(source.width)
        let dy = (leftEye.y - rightEye.y) * Double(source.height)
        return HeadFrame(center: eyeMidpointPixels, angleRadians: atan2(dy, dx))
    }

    /// Eye-line roll in degrees, positive counter-clockwise; the solver levels by rotating the opposite way.
    var rollDegrees: Double { headFrame.rollDegrees }

    var interEyeDistancePixels: Double {
        let dx = (leftEye.x - rightEye.x) * Double(source.width)
        let dy = (leftEye.y - rightEye.y) * Double(source.height)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Crown to chin along the head axis, in source pixels.
    var headHeightPixels: Double { max(0, crown.distanceAboveEyes + eyeToChinPixels) }

    /// Crown position in the image frame (normalized), for display.
    var crownPoint: ImagePoint {
        let p = headFrame.toImage(ImagePoint(x: 0, y: -crown.distanceAboveEyes))
        return ImagePoint(x: p.x / Double(source.width), y: p.y / Double(source.height))
    }

    func crownPoint(distance: Double) -> ImagePoint {
        let p = headFrame.toImage(ImagePoint(x: 0, y: -distance))
        return ImagePoint(x: p.x / Double(source.width), y: p.y / Double(source.height))
    }
}

enum CrownEstimator {
    /// Eye line sits roughly 55–58 % of the way from crown to chin on adults, so crown ≈ chin − k·(chin − eye).
    static let defaultAdultRatio = 1.8
    /// Mask and anatomy are considered to agree when they differ by less than this many inter-eye distances.
    static let agreementInterEyeFraction = 0.35

    /// All distances in source pixels along the head axis.
    static func estimate(eyeToChin: Double, maskAboveEyes: Double?, maskTouchesEdge: Bool = false,
                         interEyeDistancePixels: Double, ratio: Double = defaultAdultRatio) -> CrownEstimate {
        let anthropometric = max(0, (ratio - 1) * eyeToChin)
        guard let maskAboveEyes, interEyeDistancePixels > 0 else {
            return CrownEstimate(distanceAboveEyes: anthropometric, method: .anthropometric, confidence: 0.5,
                                 maskDistance: maskAboveEyes, anthropometricDistance: anthropometric,
                                 headTouchesEdge: false, hairVolume: false)
        }
        let divergence = maskAboveEyes - anthropometric
        let tolerance = agreementInterEyeFraction * interEyeDistancePixels
        if abs(divergence) <= tolerance {
            return CrownEstimate(distanceAboveEyes: maskAboveEyes, method: .mask, confidence: maskTouchesEdge ? 0.4 : 0.9,
                                 maskDistance: maskAboveEyes, anthropometricDistance: anthropometric,
                                 headTouchesEdge: maskTouchesEdge, hairVolume: false)
        }
        // Mask far above anatomy: hair volume or headwear; ICAO measures the crown ignoring hair.
        // Mask far below anatomy: the mask missed the head; anatomy is the safer guess.
        let hairVolume = divergence > 0
        return CrownEstimate(distanceAboveEyes: anthropometric, method: .anthropometric, confidence: hairVolume ? 0.6 : 0.4,
                             maskDistance: maskAboveEyes, anthropometricDistance: anthropometric,
                             headTouchesEdge: maskTouchesEdge, hairVolume: hairVolume)
    }
}

/// Composition bands. Values for Spain are ICAO Portrait Quality engineering defaults, not official DNI numbers.
struct CompositionSpec: Sendable, Hashable {
    var headHeightRange: ClosedRange<Double> = 0.60...0.90
    var headHeightTarget = 0.74
    /// Eye midpoint measured from the top of the photo as a fraction of its height.
    var eyeLineRange: ClosedRange<Double> = 0.30...0.50
    var eyeLineTarget = 0.42
    var horizontalTolerance = 0.05
    /// ICAO roll limit for the finished portrait; larger measured tilts are reported.
    var maxRollDegrees = 8.0
    /// Tilts up to this are levelled automatically; beyond it the photo is measured but not rotated.
    var maxAutoLevelDegrees = 15.0
    var maxYawDegrees = 5.0
    var maxPitchDegrees = 5.0
    var minimumInterEyePixels = 90.0
    var recommendedInterEyePixels = 120.0
    /// Minimum space between the crown and the top edge, as a fraction of photo height.
    var minimumHeadroom = 0.04

    static let icaoEngineeringDefault = CompositionSpec()
}

enum CheckState: String, Sendable, Hashable { case pass, warn, fail, manualCheck }

struct AlignmentCheck: Sendable, Hashable, Identifiable {
    enum Kind: String, Sendable, Hashable {
        case faceCount, resolution, roll, yaw, pitch, headHeight, eyeLine, centering, crown, headroom, zoomRange
    }
    let kind: Kind
    let state: CheckState
    let measured: Double?
    var id: Kind { kind }
}

struct CropSolution: Sendable, Hashable {
    let adjustment: CropAdjustment
    let checks: [AlignmentCheck]
    /// Chin-to-crown height as a fraction of the crop height actually achieved.
    let headHeightFraction: Double
    let eyeLineFraction: Double

    var overall: CheckState {
        if checks.contains(where: { $0.state == .fail }) { return .fail }
        if checks.contains(where: { $0.state == .warn }) { return .warn }
        if checks.contains(where: { $0.state == .manualCheck }) { return .manualCheck }
        return .pass
    }
}

/// Deterministic algebra in the head-aligned frame: scale to the head-height target, place by eye line and
/// headroom, centre on the eye midpoint, map the crop centre back to the image, level the eyes when the tilt
/// is small enough, then express the crop in the editor's zoom/travel/rotation model.
enum CropSolver {
    static func solve(geometry g: FaceGeometry, format: PhotoFormat = .spainPrototype,
                      spec: CompositionSpec = .icaoEngineeringDefault) -> CropSolution {
        let width = Double(g.source.width), height = Double(g.source.height)
        var checks: [AlignmentCheck] = []

        checks.append(AlignmentCheck(kind: .faceCount, state: g.faceCount == 1 ? .pass : .fail, measured: Double(g.faceCount)))
        let ied = g.interEyeDistancePixels
        checks.append(AlignmentCheck(kind: .resolution,
                                     state: ied >= spec.recommendedInterEyePixels ? .pass : (ied >= spec.minimumInterEyePixels ? .warn : .fail),
                                     measured: ied))
        let roll = g.rollDegrees
        checks.append(AlignmentCheck(kind: .roll, state: abs(roll) <= spec.maxRollDegrees ? .pass : .warn, measured: roll))
        checks.append(AlignmentCheck(kind: .yaw, state: abs(g.yawDegrees) <= spec.maxYawDegrees ? .pass : .warn, measured: g.yawDegrees))
        checks.append(AlignmentCheck(kind: .pitch, state: abs(g.pitchDegrees) <= spec.maxPitchDegrees ? .pass : .warn, measured: g.pitchDegrees))
        checks.append(AlignmentCheck(kind: .crown, state: g.crown.hairVolume ? .manualCheck : (g.crown.confidence >= 0.8 ? .pass : .warn),
                                     measured: g.crown.confidence))
        if g.crown.headTouchesEdge {
            checks.append(AlignmentCheck(kind: .headroom, state: .fail, measured: 0))
        }

        // Rotation levels the eyes about the crop centre; large tilts are measured but left for a retake.
        let levels = abs(roll) <= spec.maxAutoLevelDegrees
        let rotation = levels ? -roll : 0

        // Scale from head length along the head axis, bounded by the source.
        let headPx = max(g.headHeightPixels, 1)
        var cropH = headPx / spec.headHeightTarget
        var cropW = cropH * format.aspectRatio
        let maxScale = min(width / cropW, height / cropH, 1)
        if maxScale < 1 { cropW *= maxScale; cropH *= maxScale }

        // Aligned frame: eyes at the origin, crown at -crownAbove, chin at +eyeToChin.
        let crownAbove = g.crown.distanceAboveEyes, eyeToChin = g.eyeToChinPixels
        var top = -spec.eyeLineTarget * cropH
        let minTop = max(eyeToChin + 0.06 * cropH - cropH, -spec.eyeLineRange.upperBound * cropH)
        let maxTop = min(-crownAbove - spec.minimumHeadroom * cropH, -spec.eyeLineRange.lowerBound * cropH)
        if minTop <= maxTop { top = min(max(top, minTop), maxTop) }

        // Map the aligned crop centre back to the image and keep the rectangle inside the source.
        let alignedCenter = ImagePoint(x: 0, y: top + cropH / 2)
        let center = levels ? g.headFrame.toImage(alignedCenter)
                            : ImagePoint(x: g.eyeMidpointPixels.x, y: g.eyeMidpointPixels.y + alignedCenter.y)
        var x = center.x - cropW / 2, y = center.y - cropH / 2
        x = min(max(x, 0), max(0, width - cropW))
        y = min(max(y, 0), max(0, height - cropH))

        let headFraction = headPx / cropH
        // With levelling, the eyes sit where the aligned frame put them; otherwise measure in the image frame.
        let eyeFraction = levels ? (-top - (center.y - cropH / 2 - y)) / cropH : (g.eyeMidpointPixels.y - y) / cropH
        checks.append(AlignmentCheck(kind: .headHeight, state: band(headFraction, spec.headHeightRange), measured: headFraction))
        checks.append(AlignmentCheck(kind: .eyeLine, state: band(eyeFraction, spec.eyeLineRange), measured: eyeFraction))
        let eyeX = levels ? center.x : g.eyeMidpointPixels.x
        let centering = abs((eyeX - x) / cropW - 0.5)
        checks.append(AlignmentCheck(kind: .centering, state: centering <= spec.horizontalTolerance ? .pass : .warn, measured: centering))
        let headroom = (eyeFraction * cropH - crownAbove) / cropH
        if !g.crown.headTouchesEdge {
            checks.append(AlignmentCheck(kind: .headroom, state: headroom >= spec.minimumHeadroom ? .pass : .warn, measured: headroom))
        }

        // Express as the editor's model: zoom relative to the largest crop of this aspect, travel fractions.
        let sourceAspect = width / height
        let baseWidth = min(1, format.aspectRatio / sourceAspect) * width
        let zoom = baseWidth / cropW
        let crop = NormalizedCrop(x: x / width, y: y / height, width: cropW / width, height: cropH / height)
        var adjustment = CropAdjustment(
            zoom: zoom,
            horizontal: crop.width >= 0.999_999 ? 0.5 : crop.x / (1 - crop.width),
            vertical: crop.height >= 0.999_999 ? 0.5 : crop.y / (1 - crop.height),
            rotationDegrees: rotation)
        let clamped = adjustment.clamped()
        checks.append(AlignmentCheck(kind: .zoomRange, state: abs(clamped.zoom - zoom) < 0.000_1 ? .pass : .warn, measured: zoom))
        adjustment = clamped
        return CropSolution(adjustment: adjustment, checks: checks, headHeightFraction: headFraction, eyeLineFraction: eyeFraction)
    }

    private static func band(_ value: Double, _ range: ClosedRange<Double>) -> CheckState {
        if range.contains(value) {
            let margin = 0.03
            return (value - range.lowerBound < margin || range.upperBound - value < margin) ? .warn : .pass
        }
        return .fail
    }
}
