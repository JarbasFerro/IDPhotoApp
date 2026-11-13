import Foundation

/// How wide the person's outline is around the head, in inter-eye distances, from the person mask. Something attached
/// beside the head (over-ear headphones, a hood, a headrest the mask kept) makes it wider than any head.
///
/// Calibrated on the founder's recordings and ten portraits (0.20.10), as the median over rows from the eye line up
/// to 0.6 × eye-to-chin above it: plain heads 2.22–2.63 (children and full hair included), over-ear headphones
/// 2.74–2.85. Advisory: a warning to look, never a failure.
enum HeadOutline {
    /// Above this median width the head is wider than a head.
    static let wideLimit = 2.70

    /// Median of the per-row widths, already divided by the inter-eye distance; nil without rows.
    static func medianWidth(_ widths: [Double]) -> Double? {
        let sorted = widths.filter(\.isFinite).sorted()
        guard !sorted.isEmpty else { return nil }
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    static func isWide(_ width: Double) -> Bool { width > wideLimit }
}
