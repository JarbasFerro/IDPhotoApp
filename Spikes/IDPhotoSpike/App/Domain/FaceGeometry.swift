import Foundation

// Face geometry and automatic alignment: pure Swift, no Vision or UI imports.
// All points are normalized to the upright source image with a top-left origin
// (`NormalizedImageSpace`). Distances are computed in source pixels through `SourcePixels`
// because normalized axes are anisotropic.

struct ImagePoint: Sendable, Hashable {
    var x: Double
    var y: Double
}

enum CrownMethod: String, Sendable, Hashable {
    /// Top of the person mask inside the face column; used when it agrees with anatomy.
    case mask
    /// Extrapolated from chin and eye line; used when hair, headwear, or a bad mask disagree.
    case anthropometric
}

struct CrownEstimate: Sendable, Hashable {
    let y: Double
    let method: CrownMethod
    /// 0...1; 0.9 when mask and anatomy agree, lower otherwise.
    let confidence: Double
    let maskY: Double?
    let anthropometricY: Double
    /// True when the mask reaches the top row of the image: the head is probably cut off.
    let headTouchesTop: Bool
    /// True when the mask sits well above the anatomical estimate: tall hair or headwear.
    let hairVolume: Bool
}

struct FaceGeometry: Sendable, Hashable {
    let source: SourcePixels
    let faceCount: Int
    /// Vision face rectangle, top-left normalized. Excludes hair.
    let faceBox: NormalizedCrop
    let leftEye: ImagePoint
    let rightEye: ImagePoint
    let chin: ImagePoint
    let crown: CrownEstimate
    let rollDegrees: Double
    let yawDegrees: Double
    let pitchDegrees: Double

    var eyeMidpoint: ImagePoint {
        ImagePoint(x: (leftEye.x + rightEye.x) / 2, y: (leftEye.y + rightEye.y) / 2)
    }

    var interEyeDistancePixels: Double {
        let dx = (leftEye.x - rightEye.x) * Double(source.width)
        let dy = (leftEye.y - rightEye.y) * Double(source.height)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Chin to crown in source pixels.
    var headHeightPixels: Double { max(0, chin.y - crown.y) * Double(source.height) }
}

enum CrownEstimator {
    /// Eye line sits roughly 55–58 % of the way from crown to chin on adults, so crown ≈ chin − k·(chin − eye).
    static let defaultAdultRatio = 1.8
    /// Mask and anatomy are considered to agree when they differ by less than this many inter-eye distances.
    static let agreementInterEyeFraction = 0.35

    static func estimate(chinY: Double, eyeY: Double, maskTopY: Double?, interEyeDistancePixels: Double,
                         sourceHeight: Int, ratio: Double = defaultAdultRatio) -> CrownEstimate {
        let anthropometric = max(0, chinY - ratio * (chinY - eyeY))
        guard let maskTopY, interEyeDistancePixels > 0 else {
            return CrownEstimate(y: anthropometric, method: .anthropometric, confidence: 0.5, maskY: maskTopY,
                                 anthropometricY: anthropometric, headTouchesTop: false, hairVolume: false)
        }
        let touchesTop = maskTopY <= 0.003
        let divergencePixels = (maskTopY - anthropometric) * Double(sourceHeight)
        let tolerance = agreementInterEyeFraction * interEyeDistancePixels
        if abs(divergencePixels) <= tolerance {
            return CrownEstimate(y: maskTopY, method: .mask, confidence: touchesTop ? 0.4 : 0.9, maskY: maskTopY,
                                 anthropometricY: anthropometric, headTouchesTop: touchesTop, hairVolume: false)
        }
        // Mask far above anatomy: hair volume or headwear; ICAO measures the crown ignoring hair.
        // Mask far below anatomy: the mask missed the head; anatomy is the safer guess.
        let hairVolume = divergencePixels < 0
        return CrownEstimate(y: anthropometric, method: .anthropometric, confidence: hairVolume ? 0.6 : 0.4,
                             maskY: maskTopY, anthropometricY: anthropometric, headTouchesTop: touchesTop,
                             hairVolume: hairVolume)
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
    var maxRollDegrees = 8.0
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

/// Deterministic algebra: level the eyes, scale to the head-height target, place by eye line and headroom,
/// centre horizontally, then express the crop in the editor's zoom/travel model.
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
        checks.append(AlignmentCheck(kind: .roll, state: abs(g.rollDegrees) <= spec.maxRollDegrees ? .pass : .warn, measured: g.rollDegrees))
        checks.append(AlignmentCheck(kind: .yaw, state: abs(g.yawDegrees) <= spec.maxYawDegrees ? .pass : .warn, measured: g.yawDegrees))
        checks.append(AlignmentCheck(kind: .pitch, state: abs(g.pitchDegrees) <= spec.maxPitchDegrees ? .pass : .warn, measured: g.pitchDegrees))
        checks.append(AlignmentCheck(kind: .crown, state: g.crown.hairVolume ? .manualCheck : (g.crown.confidence >= 0.8 ? .pass : .warn),
                                     measured: g.crown.confidence))
        if g.crown.headTouchesTop {
            checks.append(AlignmentCheck(kind: .headroom, state: .fail, measured: 0))
        }

        // Rotation levels the eyes around the crop centre; large tilts are reported instead of corrected.
        let rotation = abs(g.rollDegrees) <= spec.maxRollDegrees ? -g.rollDegrees : 0

        // Scale from head height (pixels), then keep the crop inside the source.
        let headPx = max(g.headHeightPixels, 1)
        var cropH = headPx / spec.headHeightTarget
        var cropW = cropH * format.aspectRatio
        let maxScale = min(width / cropW, height / cropH, 1)
        if maxScale < 1 { cropW *= maxScale; cropH *= maxScale }

        // Vertical: eye line at target, adjusted so the crown keeps headroom and the chin stays inside.
        let eye = ImagePoint(x: g.eyeMidpoint.x * width, y: g.eyeMidpoint.y * height)
        let crownY = g.crown.y * height, chinY = g.chin.y * height
        var y = eye.y - spec.eyeLineTarget * cropH
        let minY = max(chinY + 0.06 * cropH - cropH, eye.y - spec.eyeLineRange.upperBound * cropH)
        let maxY = min(crownY - spec.minimumHeadroom * cropH, eye.y - spec.eyeLineRange.lowerBound * cropH)
        if minY <= maxY { y = min(max(y, minY), maxY) }
        y = min(max(y, 0), max(0, height - cropH))
        var x = eye.x - cropW / 2
        x = min(max(x, 0), max(0, width - cropW))

        let headFraction = headPx / cropH
        let eyeFraction = (eye.y - y) / cropH
        checks.append(AlignmentCheck(kind: .headHeight, state: band(headFraction, spec.headHeightRange), measured: headFraction))
        checks.append(AlignmentCheck(kind: .eyeLine, state: band(eyeFraction, spec.eyeLineRange), measured: eyeFraction))
        let centering = abs((eye.x - x) / cropW - 0.5)
        checks.append(AlignmentCheck(kind: .centering, state: centering <= spec.horizontalTolerance ? .pass : .warn, measured: centering))
        let headroom = (crownY - y) / cropH
        if !g.crown.headTouchesTop {
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
