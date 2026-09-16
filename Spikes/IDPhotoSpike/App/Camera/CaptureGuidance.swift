import Foundation

// Live capture guidance: pure Swift, no AVFoundation. Inputs come from cheap face metadata per frame;
// outputs are one calm hint at a time, debounced with hysteresis so nothing flickers (FR-022, C9-003).

/// One frame's face metadata in the displayed preview frame: normalized, top-left origin.
struct FaceFrameSummary: Sendable, Hashable {
    var faceCount: Int
    /// Largest face, normalized to the visible preview.
    var bounds: NormalizedCrop?
    var rollDegrees: Double?
    var yawDegrees: Double?

    static let empty = FaceFrameSummary(faceCount: 0, bounds: nil, rollDegrees: nil, yawDegrees: nil)
}

enum CaptureHint: String, Sendable, Hashable, CaseIterable {
    case noFace, multipleFaces, moveCloser, moveBack, centerFace, keepLevel, faceCamera, holdStill, ready
}

struct CaptureGuidanceThresholds: Sendable, Hashable {
    /// Face rectangle height as a fraction of the preview height. The face box excludes hair, so 0.30–0.55 leaves
    /// room above the head for the official crop.
    var minFaceHeight = 0.30
    var maxFaceHeight = 0.55
    /// Margin added when leaving a size hint, so a face near the limit does not toggle.
    var sizeHysteresis = 0.03
    var horizontalTolerance = 0.12
    var verticalTolerance = 0.15
    /// Preferred face centre, slightly above the middle so shoulders fit below.
    var targetCenterY = 0.45
    var maxRollDegrees = 8.0
    var maxYawDegrees = 15.0
    /// Consecutive frames a new hint must persist before it is shown.
    var switchFrames = 5
    /// Consecutive good frames before "hold still" becomes "ready".
    var readyFrames = 15

    static let `default` = CaptureGuidanceThresholds()
}

/// Debounced hint tracker. Feed one summary per frame; read `hint`.
struct GuidanceTracker: Sendable, Hashable {
    private(set) var hint: CaptureHint = .noFace
    private var candidate: CaptureHint = .noFace
    private var streak = 0
    private var goodStreak = 0
    let thresholds: CaptureGuidanceThresholds

    init(thresholds: CaptureGuidanceThresholds = .default) { self.thresholds = thresholds }

    @discardableResult
    mutating func update(_ frame: FaceFrameSummary) -> CaptureHint {
        let raw = rawHint(for: frame)
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
        let centerX = box.x + box.width / 2, centerY = box.y + box.height / 2
        if abs(centerX - 0.5) > t.horizontalTolerance || abs(centerY - t.targetCenterY) > t.verticalTolerance { return .centerFace }
        if let roll = frame.rollDegrees, abs(roll) > t.maxRollDegrees { return .keepLevel }
        if let yaw = frame.yawDegrees, abs(yaw) > t.maxYawDegrees { return .faceCamera }
        return .ready
    }
}
