import SwiftUI

/// Single source of truth for how a status looks. The colours are system semantic colours and are intentionally
/// independent of any brand tint: a future accent must never change what pass, warn or fail look like.
/// Colour is never the only signal; every use pairs it with a symbol and text.
enum StatusStyle {
    static let pass = Color.green
    static let warn = Color.orange
    static let fail = Color.red
    /// Not measurable, or not measured yet: deliberately neutral.
    static let neutral = Color.secondary

    static func color(for state: CheckState) -> Color {
        switch state {
        case .pass: pass
        case .warn: warn
        case .fail: fail
        case .manualCheck: neutral
        }
    }

    static func color(for headline: PhotoCheckSummary.Headline) -> Color {
        switch headline {
        case .checking: neutral
        case .good: pass
        case .review: warn
        case .retake: fail
        }
    }

    static func symbol(for state: CheckState) -> String { AlignmentPresentation.symbol(for: state) }
}
