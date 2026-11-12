import Foundation

// Document Tone policy and assessment: pure Swift. The adjustment itself is global and reversible
// (ADR-011, ADR-038); nothing here knows about faces beyond a rectangle used for measurement.

/// Whether a jurisdiction permits software adjustment of the photo (FR-151).
enum AlterationPolicy: String, Sendable, Hashable {
    case allowed, discouraged, forbidden
}

/// Profile-level policy inputs the editor needs today. The rules catalog replaces this in M4 (R7-016).
struct DocumentPolicy: Sendable, Hashable {
    let alteration: AlterationPolicy
    let background: BackgroundColor

    /// Spain DNI wording requires a plain white background and says nothing against tonal correction;
    /// `allowed` is an engineering default, not an official statement.
    static let spainEngineering = DocumentPolicy(alteration: .allowed, background: .white)
}

struct ToneSettings: Sendable, Hashable {
    var isEnabled = true
    /// 0...1 blend between the source and the fully corrected image.
    var strength = 0.6

    static let off = ToneSettings(isEnabled: false, strength: 0.6)

    func clamped() -> ToneSettings {
        ToneSettings(isEnabled: isEnabled, strength: strength.isFinite ? min(max(strength, 0), 1) : 0.6)
    }
}

/// Luminance statistics of the face region and the whole image, sRGB 0...1.
struct ToneMetrics: Sendable, Hashable {
    var faceMeanLuminance: Double
    /// Fraction of face pixels at or below 2/255 and at or above 253/255.
    var faceClippedDark: Double
    var faceClippedBright: Double
    /// Mean red minus mean blue over the background region; positive is warm, negative is cool.
    var backgroundCast: Double
}

struct ToneAssessment: Sendable, Hashable {
    enum Issue: String, Sendable, Hashable { case underexposed, overexposed, clipped, colourCast }
    let issues: [Issue]

    var state: CheckState {
        if issues.contains(.clipped) { return .warn }
        return issues.isEmpty ? .pass : .warn
    }

    /// ICAO Portrait Quality: no more than 0.1 % of facial pixels saturated at either end.
    static let clippingLimit = 0.001

    static func assess(_ m: ToneMetrics) -> ToneAssessment {
        var issues: [Issue] = []
        if m.faceMeanLuminance < 0.30 { issues.append(.underexposed) }
        if m.faceMeanLuminance > 0.80 { issues.append(.overexposed) }
        if m.faceClippedDark > clippingLimit || m.faceClippedBright > clippingLimit { issues.append(.clipped) }
        if abs(m.backgroundCast) > 0.06 { issues.append(.colourCast) }
        return ToneAssessment(issues: issues)
    }
}
