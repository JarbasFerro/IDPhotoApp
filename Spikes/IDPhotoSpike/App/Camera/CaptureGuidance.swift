import Foundation

// Live capture guidance: pure Swift, no AVFoundation. Inputs come from cheap face metadata per frame, a slower
// Vision pass every few frames (pitch, distance, lighting) and the motion sensors; outputs are one calm hint at
// a time, debounced with hysteresis so nothing flickers (FR-022, C9-003).
//
// Reference frame: the photo records the head relative to the camera, so the head pose in the image is what is
// checked. The phone's absolute attitude is never a requirement; it only decides whether a pose error is worded
// as "move the phone" (the phone is tilted) or as "move your head" (the phone is fine).

/// Phone attitude from the motion sensors, degrees, used only to attribute a relative pose error to the phone.
/// Roll: lean left/right about the lens axis (0 = level). Pitch: lean back (+) or forward (−) from vertical.
struct DeviceLevel: Sendable, Hashable {
    var rollDegrees: Double
    var pitchDegrees: Double
}

/// Face illumination measured on the live frame, 0...1 luminance.
struct LightingSummary: Sendable, Hashable {
    var faceMean: Double
    /// Mean of the subject's left half of the face divided by the right half; above 1 the light comes from the
    /// subject's left.
    var leftRightRatio: Double
    /// Mean of the background ring around the head divided by the face mean; large values mean backlight.
    var backgroundRatio: Double
}

/// One frame's face metadata in the displayed preview frame: normalized, top-left origin.
struct FaceFrameSummary: Sendable, Hashable {
    var faceCount: Int
    /// Largest face, normalized to the visible preview.
    var bounds: NormalizedCrop?
    var rollDegrees: Double?
    var yawDegrees: Double?
    /// From the slow Vision pass; positive means the face appears tilted up (camera below the eyes).
    var pitchDegrees: Double?
    /// Camera-to-face distance from the interpupillary distance, centimetres.
    var distanceCM: Double?
    var lighting: LightingSummary?
    /// The sensor is at (or near) its gain limit.
    var lowLight = false
    var device: DeviceLevel?

    static let empty = FaceFrameSummary(faceCount: 0, bounds: nil, rollDegrees: nil, yawDegrees: nil)
}

enum CaptureHint: String, Sendable, Hashable, CaseIterable {
    case noFace, multipleFaces, moveCloser, moveBack, tooClose, centerFace
    case levelPhone, uprightPhone, keepLevel, faceCamera, eyeLevel
    case backlit, moreLight, turnLeft, turnRight
    case holdStill, ready
}

/// Which readiness segment a hint belongs to, for the four-part indicator.
enum ReadinessGroup: String, Sendable, Hashable, CaseIterable { case framing, pose, light, distance }

struct CaptureReadiness: Sendable, Hashable {
    enum State: Sendable, Hashable { case unknown, attention, ok }
    /// One face, large enough and centred.
    var framing: State = .unknown
    /// Head roll, yaw and pitch relative to the camera.
    var pose: State = .unknown
    var light: State = .unknown
    var distance: State = .unknown

    subscript(group: ReadinessGroup) -> State {
        switch group {
        case .framing: framing
        case .pose: pose
        case .light: light
        case .distance: distance
        }
    }
}

struct CaptureGuidanceThresholds: Sendable, Hashable {
    /// Face rectangle height as a fraction of the visible preview height. The source photo is cropped later, so
    /// arm's-length framing (face about a fifth to two fifths of a tall phone screen) is enough; the first device
    /// run showed 0.30 forced the phone uncomfortably close.
    var minFaceHeight = 0.18
    var maxFaceHeight = 0.42
    /// Margin added when leaving a size hint, so a face near the limit does not toggle.
    var sizeHysteresis = 0.03
    var horizontalTolerance = 0.12
    var verticalTolerance = 0.15
    /// Preferred face centre, slightly above the middle so shoulders fit below.
    var targetCenterY = 0.45
    var maxRollDegrees = 8.0
    var maxYawDegrees = 15.0
    /// Face pitch relative to the camera beyond this means the camera is above or below the eyes, or leaning.
    var maxPitchDegrees = 10.0
    /// Phone attitude beyond which a head roll or pitch error is blamed on the phone rather than the head.
    var deviceRollAttribution = 4.0
    var devicePitchAttribution = 8.0
    /// Below this the wide front lens distorts the nose and hides the ears.
    var minDistanceCM = 45.0
    /// |ln(left/right)| beyond this is a one-sided light; 0.29 is a 4:3 ratio.
    var maxLightImbalance = 0.29
    /// Background brighter than the face by this factor is backlight.
    var backlightRatio = 1.8
    /// Face luminance (0...1) below this is too dark for a document photo.
    var minFaceLuminance = 0.22
    /// Consecutive frames a new hint must persist before it is shown.
    var switchFrames = 5
    /// Consecutive good frames before "hold still" becomes "ready".
    var readyFrames = 15

    static let `default` = CaptureGuidanceThresholds()
}

/// Debounced hint tracker. Feed one summary per frame; read `hint` and `readiness`.
struct GuidanceTracker: Sendable, Hashable {
    private(set) var hint: CaptureHint = .noFace
    private(set) var readiness = CaptureReadiness()
    private var candidate: CaptureHint = .noFace
    private var streak = 0
    private var goodStreak = 0
    let thresholds: CaptureGuidanceThresholds

    init(thresholds: CaptureGuidanceThresholds = .default) { self.thresholds = thresholds }

    @discardableResult
    mutating func update(_ frame: FaceFrameSummary) -> CaptureHint {
        let raw = rawHint(for: frame)
        readiness = Self.readiness(for: frame, thresholds: thresholds)
        if raw == candidate { streak += 1 } else { candidate = raw; streak = 1 }
        goodStreak = raw == .ready ? goodStreak + 1 : 0

        if raw == .ready {
            // Good framing: ask the user to hold still, then confirm.
            if goodStreak >= thresholds.readyFrames { hint = .ready }
            else if streak >= thresholds.switchFrames, hint != .ready { hint = .holdStill }
        } else if raw != hint, streak >= thresholds.switchFrames {
            hint = raw
        }
        return hint
    }

    /// Hints in priority order: presence, size, distance, position, head pose relative to the camera, light.
    private func rawHint(for frame: FaceFrameSummary) -> CaptureHint {
        let t = thresholds
        if frame.faceCount == 0 || frame.bounds == nil { return .noFace }
        if frame.faceCount > 1 { return .multipleFaces }
        guard let box = frame.bounds else { return .noFace }
        // Hysteresis: when already asking to move, require the face to clear the limit by a margin.
        let minHeight = t.minFaceHeight + (hint == .moveCloser ? t.sizeHysteresis : 0)
        let maxHeight = t.maxFaceHeight - (hint == .moveBack ? t.sizeHysteresis : 0)
        if box.height < minHeight { return .moveCloser }
        if box.height > maxHeight { return .moveBack }
        if let distance = frame.distanceCM, distance < t.minDistanceCM { return .tooClose }
        let centerX = box.x + box.width / 2, centerY = box.y + box.height / 2
        if abs(centerX - 0.5) > t.horizontalTolerance || abs(centerY - t.targetCenterY) > t.verticalTolerance { return .centerFace }
        // Relative pose errors, attributed to whichever is tilted: the phone or the head.
        if let roll = frame.rollDegrees, abs(roll) > t.maxRollDegrees {
            return abs(frame.device?.rollDegrees ?? 0) > t.deviceRollAttribution ? .levelPhone : .keepLevel
        }
        if let yaw = frame.yawDegrees, abs(yaw) > t.maxYawDegrees { return .faceCamera }
        if let pitch = frame.pitchDegrees, abs(pitch) > t.maxPitchDegrees {
            return abs(frame.device?.pitchDegrees ?? 0) > t.devicePitchAttribution ? .uprightPhone : .eyeLevel
        }
        if let light = frame.lighting {
            if light.backgroundRatio > t.backlightRatio, light.faceMean < 0.45 { return .backlit }
            if light.faceMean < t.minFaceLuminance { return .moreLight }
            let imbalance = log(max(light.leftRightRatio, 0.01))
            if abs(imbalance) > t.maxLightImbalance { return imbalance > 0 ? .turnLeft : .turnRight }
        } else if frame.lowLight {
            return .moreLight
        }
        return .ready
    }

    static func readiness(for frame: FaceFrameSummary, thresholds t: CaptureGuidanceThresholds) -> CaptureReadiness {
        var result = CaptureReadiness()
        if frame.faceCount == 1, let box = frame.bounds {
            let sizeOK = box.height >= t.minFaceHeight && box.height <= t.maxFaceHeight
            let centreOK = abs(box.x + box.width / 2 - 0.5) <= t.horizontalTolerance
                && abs(box.y + box.height / 2 - t.targetCenterY) <= t.verticalTolerance
            result.framing = sizeOK && centreOK ? .ok : .attention
            let rollOK = frame.rollDegrees.map { abs($0) <= t.maxRollDegrees } ?? true
            let yawOK = frame.yawDegrees.map { abs($0) <= t.maxYawDegrees } ?? true
            let pitchOK = frame.pitchDegrees.map { abs($0) <= t.maxPitchDegrees } ?? true
            result.pose = rollOK && yawOK && pitchOK ? .ok : .attention
            if let distance = frame.distanceCM { result.distance = distance >= t.minDistanceCM ? .ok : .attention }
            if let light = frame.lighting {
                let backlit = light.backgroundRatio > t.backlightRatio && light.faceMean < 0.45
                let dark = light.faceMean < t.minFaceLuminance
                let uneven = abs(log(max(light.leftRightRatio, 0.01))) > t.maxLightImbalance
                result.light = backlit || dark || uneven ? .attention : .ok
            } else if frame.lowLight {
                result.light = .attention
            }
        } else if frame.faceCount > 1 {
            result.framing = .attention
        } else {
            result.framing = .attention
        }
        return result
    }
}

/// Luminance statistics of a face inside a grayscale (luma) plane. Pure Swift so the thresholds are testable.
enum FaceLighting {
    /// - Parameters:
    ///   - luma: 8-bit luminance rows, `bytesPerRow` apart, top-left origin, upright (subject's left on the image's right).
    ///   - face: face rectangle in pixels, top-left origin.
    static func analyze(luma: UnsafeBufferPointer<UInt8>, width: Int, height: Int, bytesPerRow: Int,
                        face: (x: Int, y: Int, width: Int, height: Int)) -> LightingSummary? {
        guard width > 0, height > 0, face.width >= 8, face.height >= 8 else { return nil }
        let step = max(1, face.width / 24)
        // Inner face box: trims hair and background from the metadata rectangle.
        let fx0 = max(0, face.x + face.width / 6), fx1 = min(width, face.x + face.width * 5 / 6)
        let fy0 = max(0, face.y + face.height / 5), fy1 = min(height, face.y + face.height * 9 / 10)
        guard fx1 > fx0, fy1 > fy0 else { return nil }
        let midX = (fx0 + fx1) / 2
        var imageLeft = 0.0, imageRight = 0.0, leftCount = 0, rightCount = 0
        var y = fy0
        while y < fy1 {
            let row = y * bytesPerRow
            var x = fx0
            while x < fx1 {
                let value = Double(luma[row + x])
                if x < midX { imageLeft += value; leftCount += 1 } else { imageRight += value; rightCount += 1 }
                x += step
            }
            y += step
        }
        guard leftCount > 0, rightCount > 0 else { return nil }
        let faceMean = (imageLeft + imageRight) / Double(leftCount + rightCount)

        // Background ring: a band around the head box, excluding the head and shoulders below the chin.
        let rx0 = max(0, face.x - face.width / 2), rx1 = min(width, face.x + face.width * 3 / 2)
        let ry0 = max(0, face.y - face.height / 2), ry1 = min(height, face.y + face.height / 2)
        var ring = 0.0, ringCount = 0
        y = ry0
        while y < ry1 {
            let row = y * bytesPerRow
            var x = rx0
            while x < rx1 {
                let insideHead = x >= face.x && x < face.x + face.width && y >= face.y
                if !insideHead { ring += Double(luma[row + x]); ringCount += 1 }
                x += step
            }
            y += step
        }
        let background = ringCount > 0 ? ring / Double(ringCount) : faceMean
        // The image is unmirrored, so the subject's left cheek is on the image's right.
        let subjectLeft = imageRight / Double(rightCount), subjectRight = imageLeft / Double(leftCount)
        return LightingSummary(faceMean: faceMean / 255,
                               leftRightRatio: subjectLeft / max(subjectRight, 1),
                               backgroundRatio: background / max(faceMean, 1))
    }

    /// Distance from interpupillary distance: 63 mm is the adult mean.
    static func distanceCM(interpupillaryPixels: Double, focalLengthPixels: Double) -> Double? {
        guard interpupillaryPixels > 1, focalLengthPixels > 1 else { return nil }
        return 6.3 * focalLengthPixels / interpupillaryPixels
    }

    /// Focal length in pixels from the horizontal field of view and the long side of the frame.
    static func focalLengthPixels(fieldOfViewDegrees: Double, longSidePixels: Double) -> Double? {
        guard fieldOfViewDegrees > 1, fieldOfViewDegrees < 179, longSidePixels > 0 else { return nil }
        return (longSidePixels / 2) / tan(fieldOfViewDegrees * .pi / 360)
    }
}
