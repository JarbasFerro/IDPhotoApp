import Foundation

/// Whether the eyes look open, from the eye outlines' height over width (Vision landmarks). Calibrated on the founder's
/// recording (0.20.8): open eyes measured 0.25–0.37 on every good frame and on ten sample portraits; a capture taken
/// while looking down at the screen measured 0.08 and 0.21. Advisory: it asks for a look on the review, never blocks.
enum EyeOpenness {
    /// Either eye below this reads as closed or turned down.
    static let minimumEither = 0.16
    /// The two eyes together below this read the same way (one eye half-closed by a downward glance).
    static let minimumMean = 0.20

    /// Height over width of an outline's bounding box; nil without enough points.
    static func ratio(_ points: [(x: Double, y: Double)]) -> Double? {
        guard points.count > 2, let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(), maxX > minX else { return nil }
        return (maxY - minY) / (maxX - minX)
    }

    /// True when the eyes look closed or turned away from the lens.
    static func looksClosed(left: Double, right: Double) -> Bool {
        min(left, right) < minimumEither || (left + right) / 2 < minimumMean
    }
}
