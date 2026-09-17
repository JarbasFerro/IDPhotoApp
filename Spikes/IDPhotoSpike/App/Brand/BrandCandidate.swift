import SwiftUI

/// Provisional brand accent candidates for controlled product-context testing (docs/brand/prototypes). These are
/// test values, not decisions: nothing is selected unless the app is launched with `-brandCandidate A|B|C|D`, and
/// without it the app keeps the system default tint. Status colours never derive from the candidate.
enum BrandCandidate: String, CaseIterable, Sendable {
    /// Deep blue.
    case a = "A"
    /// Dark cyan / blue-teal.
    case b = "B"
    /// Graphite + restrained cool accent.
    case c = "C"
    /// Warm challenger (amber-ochre).
    case d = "D"

    /// Read once at launch, from the launch-argument domain only (`-brandCandidate B`), so a stray stored default
    /// can never tint the app and nothing is persisted.
    static let current: BrandCandidate? = {
        #if DEBUG
        parse(UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)["brandCandidate"] as? String)
        #else
        nil
        #endif
    }()

    /// Letter case is ignored; anything else selects nothing.
    static func parse(_ argument: String?) -> BrandCandidate? {
        argument.flatMap { BrandCandidate(rawValue: $0.uppercased()) }
    }

    var assetName: String { "BrandAccent\(rawValue)" }

    /// Accent role (text, glyphs, selection): asset-catalog colour with Light/Dark and Increase Contrast variants.
    var color: Color { Color(assetName) }

    var fillAssetName: String { "BrandAccentFill\(rawValue)" }

    /// Accent fill role (filled buttons): deep enough in every appearance for the native white label to reach
    /// 4.5:1, which the accent itself does not in Dark. Values come from scripts/brand/generate-brand-assets.py.
    var fillColor: Color { Color(fillAssetName) }
}
