import SwiftUI

/// The Calipic brand colour is teal (BD-033). The values are still working values and live in the asset catalog
/// as test system B, written by scripts/brand/generate-brand-assets.py. Status colours never derive from these.
enum Brand {
    /// Accent role: text, glyphs, selection.
    static let accent = Color(BrandCandidate.b.assetName)
    /// Accent fill role: filled buttons and badges under a white label.
    static let accentFill = Color(BrandCandidate.b.fillAssetName)
}

extension View {
    /// The screen's primary filled button: `.borderedProminent`, filled with the fill role instead of the accent,
    /// which is too light in Dark for the native white label.
    func brandProminentButtonStyle() -> some View {
        buttonStyle(.borderedProminent).tint(BrandCandidate.current?.fillColor ?? Brand.accentFill)
    }

    /// Destructive or neutral toolbar items keep the label colour they have by default and never wear the brand
    /// tint.
    func brandNeutralToolbarItem() -> some View {
        tint(Color.primary)
    }
}

extension Color {
    /// Accent role outside tinted controls, where `.tint` does not reach.
    static var brandAccent: Color { BrandCandidate.current?.color ?? Brand.accent }

    /// Fill under a white glyph outside a button (badges).
    static var brandAccentFill: Color { BrandCandidate.current?.fillColor ?? Brand.accentFill }
}
