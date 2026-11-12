import SwiftUI

/// The look chosen in design round 3 (option B, "Cutting mat"; decision D-3): photos and pages lie on a teal-grey
/// mat with a fine grid, paper is slightly dimmed in Dark, paper casts a tight contact shadow, and measurements are
/// written in a monospaced face like an instrument readout. See docs/ui/explorations/README.md.
///
/// Two rules keep the mat honest and legible:
/// - **The grid is decoration, not a scale.** It is never shown where something on screen is true size
///   (Check your print), so nobody measures against it.
/// - **No bare text on the grid.** Captions and counts sit below the mat; anything that must sit on it (the
///   measurement chip) carries its own solid background. The grid also stays out of the area above the mat's
///   content, so navigation bar items sit on the plain tint.
extension Design.Surface {
    /// The mat's colour: `#DCE8E6` in Light, `#0E2C2E` in Dark.
    static let mat = Color("StageMat")
    /// The mat's grid lines, used at low opacity.
    static let matLine = Color("StageMatLine")
}

/// The mat: tint everywhere, grid lines inside its own bounds only, fading in over the first points.
struct MatSurface: View {
    /// Points between fine lines; every fifth line is stronger.
    private static let pitch: CGFloat = 6
    private static let fadeIn: CGFloat = 14
    @Environment(\.colorScheme) private var scheme
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let hairline = 1 / max(displayScale, 1)
            let fine = Design.Surface.matLine.opacity(scheme == .dark ? 0.05 : 0.07)
            let strong = Design.Surface.matLine.opacity(scheme == .dark ? 0.13 : 0.17)
            // Centred, so the pattern is symmetric about the photo or page whatever the width.
            let originX = (size.width / 2).truncatingRemainder(dividingBy: Self.pitch * 5)
            var index = 0
            var x = originX - Self.pitch * 5
            while x <= size.width {
                if x >= 0 {
                    let rect = CGRect(x: (x * displayScale).rounded() / displayScale, y: 0, width: hairline, height: size.height)
                    context.fill(Path(rect), with: .color(index % 5 == 0 ? strong : fine))
                }
                x += Self.pitch; index += 1
            }
            index = 0
            var y: CGFloat = 0
            while y <= size.height {
                let rect = CGRect(x: 0, y: (y * displayScale).rounded() / displayScale, width: size.width, height: hairline)
                context.fill(Path(rect), with: .color(index % 5 == 0 ? strong : fine))
                y += Self.pitch; index += 1
            }
        }
        .mask(
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: Self.fadeIn)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(Color.black.padding(.top, Self.fadeIn))
        )
        .background(Design.Surface.mat)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Lays this block on the cutting mat. The tint runs up behind the navigation bar (and past it, for
    /// overscroll); the grid stays within the block. `bleed` is the horizontal padding of the enclosing content,
    /// so the mat reaches the screen edges. The bottom corners are rounded like a grouped surface.
    func onMat(bleed: CGFloat = 0, runsUnderBar: Bool = true) -> some View {
        background {
            let shape = UnevenRoundedRectangle(bottomLeadingRadius: Design.Radius.group, bottomTrailingRadius: Design.Radius.group)
            ZStack(alignment: .bottom) {
                if runsUnderBar {
                    Design.Surface.mat.padding(.top, -1_200)
                }
                MatSurface().clipShape(shape)
            }
            .padding(.horizontal, -bleed)
        }
    }

    /// Paper never glares in Dark: photos and pages are shown at about 94 % white. Display only; exported files
    /// and prints are untouched.
    func paperDimmedInDark() -> some View { modifier(PaperDim()) }

    /// The one shadow for paper lying on a surface: a sharp contact edge plus a small soft spread.
    func paperShadow(lifted: Bool = false) -> some View { modifier(PaperShadow(lifted: lifted)) }
}

private struct PaperDim: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.overlay { if scheme == .dark { Color.black.opacity(0.06).allowsHitTesting(false) } }
    }
}

private struct PaperShadow: ViewModifier {
    /// A photo still being checked floats a little higher; it lands when the verdict arrives.
    let lifted: Bool
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .shadow(color: .black.opacity(dark ? 0.7 : 0.30), radius: 0.5, y: 0.5)
            .shadow(color: .black.opacity(dark ? 0.5 : 0.20), radius: lifted ? 9 : 3, y: lifted ? 6 : 2)
    }
}

extension Design.Typography {
    /// A measurement shown as a readout ("34 mm", "35 × 45 mm", "10 × 15 cm"): monospaced design, so quantities
    /// have their own voice. Sentences that merely contain a number keep the text face with monospaced digits.
    static func readout(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}
