import SwiftUI

extension View {
    /// The screen's primary filled button: `.borderedProminent`, filled with the active candidate's fill role
    /// instead of its accent. Without a candidate the tint stays nil, i.e. the plain system look.
    func brandProminentButtonStyle() -> some View {
        buttonStyle(.borderedProminent).tint(BrandCandidate.current?.fillColor)
    }

    /// Destructive or neutral toolbar items keep the label colour they have by default and never wear the brand
    /// tint. Without a candidate nothing is applied.
    func brandNeutralToolbarItem() -> some View {
        tint(BrandCandidate.current == nil ? nil : Color.primary)
    }
}

extension Color {
    /// Fill under a white glyph outside a button (badges): the candidate's fill role, or the accent as before.
    static var brandAccentFill: Color { BrandCandidate.current?.fillColor ?? .accentColor }
}
