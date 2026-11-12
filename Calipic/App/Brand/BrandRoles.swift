import SwiftUI

/// The Calipic brand colour is teal (BD-033). The values live in the asset catalog, written by
/// scripts/brand/generate-brand-assets.py. Status colours never derive from these.
enum Brand {
    /// Accent role: text, glyphs, selection.
    static let accent = Color("BrandAccent")
    /// Accent fill role: filled buttons and badges under a white label. Deep enough in every appearance for the
    /// native white label to reach 4.5:1, which the accent itself does not in Dark.
    static let accentFill = Color("BrandAccentFill")
}

extension View {
    /// The screen's primary filled button: `.borderedProminent`, filled with the fill role instead of the accent,
    /// which is too light in Dark for the native white label.
    func brandProminentButtonStyle() -> some View {
        buttonStyle(.borderedProminent).tint(Brand.accentFill)
    }

    /// Destructive or neutral toolbar items keep the label colour they have by default and never wear the brand
    /// tint.
    func brandNeutralToolbarItem() -> some View {
        tint(Color.primary)
    }
}

extension Color {
    /// Accent role outside tinted controls, where `.tint` does not reach.
    static var brandAccent: Color { Brand.accent }

    /// Fill under a white glyph outside a button (badges).
    static var brandAccentFill: Color { Brand.accentFill }
}
