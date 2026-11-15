import SwiftUI

/// The look chosen in design round 3 (option B, "Cutting mat"; decision D-3): photos and pages lie on a teal-grey
/// mat with a fine grid, paper is slightly dimmed in Dark, paper casts a tight contact shadow, and measurements are
/// written in a monospaced face like an instrument readout. See docs/ui/explorations/README.md.
///
/// Two rules keep the mat honest and legible:
/// - **The grid is decoration, not a scale.** It is never shown where something on screen is true size
///   (Check your print), so nobody measures against it.
/// - **No bare text on the grid.** Captions and counts sit below the mat; anything that must sit on it (the
///   measurement chip) carries its own background. JourneyScreen extends the mat behind the navigation bar;
///   unconverted screens retain the inset panel until their 0.21 pass.
extension Design.Surface {
    /// The mat's colour: `#DCE8E6` in Light, `#0E2C2E` in Dark.
    static let mat = Color("StageMat")
    /// The mat's grid lines, used at low opacity.
    static let matLine = Color("StageMatLine")
}

/// The mat: its tint and a fine grid.
struct MatSurface: View {
    /// Points between fine lines; every fifth line is stronger.
    private static let pitch: CGFloat = 6
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
        .background(Design.Surface.mat)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Lays this block on the cutting mat: a rounded mat lying on the plain screen, a little in from the screen
    /// edges. `bleed` is the horizontal padding of the enclosing content, so the mat keeps the same margin on
    /// every screen. The navigation bar stays plain; a tint behind it made the steps look heavy (founder, 0.20).
    func onMat(bleed: CGFloat = 0) -> some View {
        background {
            MatSurface()
                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.mat, style: .continuous))
                .padding(.horizontal, Design.Spacing.matMargin - bleed)
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
            .shadow(color: .black.opacity(dark ? 0.7 : 0.32), radius: 0.5, y: 0.5)
            .shadow(color: .black.opacity(dark ? 0.55 : 0.24), radius: lifted ? 16 : 8, y: lifted ? 10 : 5)
    }
}

extension Design.Radius {
    /// The mat's corners.
    static let mat: CGFloat = 26
}

extension Design.Spacing {
    /// Space between the mat and the screen edges.
    static let matMargin: CGFloat = 8
}

extension Design.Typography {
    /// A measurement shown as a readout ("34 mm", "35 × 45 mm", "10 × 15 cm"): monospaced design, so quantities
    /// have their own voice. Sentences that merely contain a number keep the text face with monospaced digits.
    static func readout(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }

    /// A choice that names a size ("10 × 15 cm" on a paper chip): rounded, so it reads as a friendly button
    /// rather than an instrument (founder, 0.20 review).
    static func sizeChoice(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

extension View {
    /// One light pass and a small lift at a real unlock. View-bound tasks cancel when the screen leaves.
    func unlockCelebration(trigger: Int) -> some View {
        modifier(UnlockLift(trigger: trigger)).lightSweep(trigger: trigger)
    }

    func lightSweep(trigger: Int) -> some View { modifier(UnlockLightSweep(trigger: trigger)) }
}

private struct UnlockLift: ViewModifier {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lifted = false
    @State private var event = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(lifted ? 1.03 : 1)
            .shadow(color: .black.opacity(lifted ? 0.18 : 0), radius: 16, y: 8)
            .onChange(of: trigger) { _, new in event = new }
            .onDisappear { event = 0; lifted = false }
            .task(id: event) {
                guard event > 0, !reduceMotion else { return }
                withAnimation(.spring(duration: 0.3, bounce: 0.15)) { lifted = true }
                do { try await Task.sleep(for: .milliseconds(300)) } catch { lifted = false; return }
                withAnimation(.spring(duration: 0.6, bounce: 0.25)) { lifted = false }
            }
    }
}

private struct UnlockLightSweep: ViewModifier {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var active = false
    @State private var event = 0
    @State private var position: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay {
            if active, !reduceMotion {
                GeometryReader { geometry in
                    LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 2)
                        .rotationEffect(.degrees(20))
                        .offset(x: position * geometry.size.width, y: -geometry.size.height / 2)
                }
                .clipped().blendMode(.plusLighter).allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .onChange(of: trigger) { _, new in event = new }
        .onDisappear { event = 0; active = false }
        .task(id: event) {
            guard event > 0, !reduceMotion else { return }
            position = -1
            active = true
            do { try await Task.sleep(for: .milliseconds(16)) } catch { active = false; return }
            withAnimation(.easeInOut(duration: 0.7)) { position = 2 }
            do { try await Task.sleep(for: .milliseconds(700)) } catch { active = false; return }
            active = false
        }
    }
}
