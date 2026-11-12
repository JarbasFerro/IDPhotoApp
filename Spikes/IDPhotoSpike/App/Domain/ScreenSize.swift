import Foundation

/// Real millimetres on the iPhone's own screen, so a print can be laid on the display and compared
/// (docs/03-design.md U1). Pure: the caller supplies the model identifier and the screen's native scale.
///
/// Points per millimetre = (physical pixels per inch ÷ 25.4) ÷ native scale. The native scale is the screen's
/// physical pixels per point; it already accounts for Display Zoom and for models whose panel is downsampled
/// (for example the iPhone 12 mini), so the formula stays right in those cases.
enum ScreenSize {
    /// Millimetres in an inch.
    static let millimetresPerInch = 25.4

    /// ID-1 card width (ISO/IEC 7810): bank cards, most ID cards and driving licences. Used to calibrate a screen
    /// whose density is not in the table.
    static let cardWidthMM = 85.60
    static let cardHeightMM = 53.98

    /// Physical pixels per inch of iPhone displays, by hardware model identifier (Apple technical specifications).
    /// A model missing here gets no true-size view until the person calibrates with a card; never a guess.
    static let pixelsPerInch: [String: Double] = [
        "iPhone12,1": 326, // iPhone 11
        "iPhone12,3": 458, // iPhone 11 Pro
        "iPhone12,5": 458, // iPhone 11 Pro Max
        "iPhone12,8": 326, // iPhone SE (2nd generation)
        "iPhone13,1": 476, // iPhone 12 mini
        "iPhone13,2": 460, // iPhone 12
        "iPhone13,3": 460, // iPhone 12 Pro
        "iPhone13,4": 458, // iPhone 12 Pro Max
        "iPhone14,2": 460, // iPhone 13 Pro
        "iPhone14,3": 458, // iPhone 13 Pro Max
        "iPhone14,4": 476, // iPhone 13 mini
        "iPhone14,5": 460, // iPhone 13
        "iPhone14,6": 326, // iPhone SE (3rd generation)
        "iPhone14,7": 460, // iPhone 14
        "iPhone14,8": 458, // iPhone 14 Plus
        "iPhone15,2": 460, // iPhone 14 Pro
        "iPhone15,3": 460, // iPhone 14 Pro Max
        "iPhone15,4": 460, // iPhone 15
        "iPhone15,5": 460, // iPhone 15 Plus
        "iPhone16,1": 460, // iPhone 15 Pro
        "iPhone16,2": 460, // iPhone 15 Pro Max
        "iPhone17,1": 460, // iPhone 16 Pro
        "iPhone17,2": 460, // iPhone 16 Pro Max
        "iPhone17,3": 460, // iPhone 16
        "iPhone17,4": 460, // iPhone 16 Plus
        "iPhone17,5": 460, // iPhone 16e
        "iPhone18,1": 460, // iPhone 17 Pro
        "iPhone18,2": 460, // iPhone 17 Pro Max
        "iPhone18,3": 460, // iPhone 17
        "iPhone18,4": 460, // iPhone Air
    ]

    /// Points per millimetre from the density table, or nil for an unknown model or an impossible scale.
    static func pointsPerMillimetre(model: String, nativeScale: Double) -> Double? {
        guard let ppi = pixelsPerInch[model], nativeScale > 0 else { return nil }
        return ppi / millimetresPerInch / nativeScale
    }

    /// Points per millimetre from a card the person matched on screen. The card stands upright, because its long
    /// side (85.60 mm) is wider than a phone held upright; the outline's width in points is the short side, 53.98 mm.
    static func pointsPerMillimetre(cardShortSidePoints: Double) -> Double? {
        guard cardShortSidePoints > 0 else { return nil }
        return cardShortSidePoints / cardHeightMM
    }

    /// A calibration is plausible only between the least and most dense screens any iPhone could have at its scale:
    /// 3 to 10 points per millimetre (about 230 to 760 ppi at 3×). Anything else is a slip of the finger.
    static let plausibleRange = 3.0...10.0
}

/// What the print check needs to know: how to draw true size here, and where that knowledge came from.
enum ScreenScale: Equatable, Sendable {
    /// From the density table for this model.
    case known(pointsPerMM: Double)
    /// From a card the person matched on screen.
    case calibrated(pointsPerMM: Double)
    /// Neither: the check falls back to a ruler.
    case unknown

    var pointsPerMM: Double? {
        switch self {
        case .known(let value), .calibrated(let value): value
        case .unknown: nil
        }
    }

    /// The table wins over a stored calibration; a stored value outside the plausible range is ignored.
    static func resolve(model: String, nativeScale: Double, storedCalibration: Double?) -> ScreenScale {
        if let value = ScreenSize.pointsPerMillimetre(model: model, nativeScale: nativeScale) { return .known(pointsPerMM: value) }
        if let stored = storedCalibration, ScreenSize.plausibleRange.contains(stored) { return .calibrated(pointsPerMM: stored) }
        return .unknown
    }
}
