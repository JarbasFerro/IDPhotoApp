import Foundation

// Background policy and mask-quality scoring: pure Swift, no Vision or Core Image imports.
// Pixel statistics are gathered by the imaging layer; the decisions live here so they are testable.

struct BackgroundColor: Sendable, Hashable {
    /// sRGB components 0...1.
    let red: Double
    let green: Double
    let blue: Double

    /// Spain DNI: "fondo uniforme blanco y liso". Other jurisdictions supply their own colour through the profile.
    static let white = BackgroundColor(red: 1, green: 1, blue: 1)
}

enum BackgroundChoice: Sendable, Hashable {
    case original
    case color(BackgroundColor)
}

/// Measured on a downsampled mask; all values are fractions 0...1.
struct MaskStatistics: Sendable, Hashable {
    /// Foreground fraction of the whole image.
    var coverage: Double
    /// Foreground fraction inside the face rectangle; a good mask covers the face completely.
    var faceCoverage: Double
    /// Fraction of image pixels with intermediate values, relative to coverage. Wide soft bands mean uncertain edges.
    var uncertainRatio: Double
    /// Foreground fraction on the top image row; foreground there means the head or hair is cut off.
    var topEdgeForeground: Double
}

struct MaskQuality: Sendable, Hashable {
    enum Reason: String, Sendable, Hashable { case faceNotCovered, implausibleCoverage, softEdges, headCutOff }
    let state: CheckState
    let reasons: [Reason]

    /// Deterministic thresholds; calibrated on the private corpus and revisited in S1-018's rubric.
    static func assess(_ s: MaskStatistics) -> MaskQuality {
        var reasons: [Reason] = []
        var state = CheckState.pass
        if s.faceCoverage < 0.9 { reasons.append(.faceNotCovered); state = .fail }
        if s.coverage < 0.05 || s.coverage > 0.95 { reasons.append(.implausibleCoverage); state = .fail }
        if s.uncertainRatio > 0.25 { reasons.append(.softEdges); if state == .pass { state = .warn } }
        if s.topEdgeForeground > 0.02 { reasons.append(.headCutOff); if state == .pass { state = .warn } }
        return MaskQuality(state: state, reasons: reasons)
    }
}

/// Luminance statistics of the original background region (mask below threshold), sRGB 0...1.
struct BackgroundAssessment: Sendable, Hashable {
    let meanLuminance: Double
    let luminanceDeviation: Double
    /// Fraction of the image that counted as background; small samples are unreliable.
    let sampleFraction: Double

    enum Issue: String, Sendable, Hashable { case dark, slightlyUneven, uneven }

    var issues: [Issue] {
        var result: [Issue] = []
        if meanLuminance < 0.80 { result.append(.dark) }
        if luminanceDeviation > 0.15 { result.append(.uneven) } else if luminanceDeviation > 0.08 { result.append(.slightlyUneven) }
        return result
    }

    /// Relative to a plain light requirement; a replacement colour is recommended for `warn` and `fail`.
    var state: CheckState {
        guard sampleFraction >= 0.05 else { return .manualCheck }
        let issues = issues
        if issues.isEmpty { return .pass }
        if issues.contains(.uneven) { return .fail }
        return .warn
    }
}
