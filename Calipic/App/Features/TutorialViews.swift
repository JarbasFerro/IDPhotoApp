import SwiftUI

// First-run tutorial (ADR-052): the welcome page, the guide bubble that sits just above the one control to use on
// each real screen, the outline around that control, and the closing "You're all set".

// MARK: - Copy

/// What the guide says in each bubble: one short sentence. Kept beside the views: it is presentation, not rules.
enum TutorialCopy {
    static func text(_ tip: GuideTip, output: Output) -> LocalizedStringResource {
        switch tip {
        case .document: "Your photo is sized for this document. Tap it to choose another."
        case .takePhoto: "Stand facing a window, against a plain light wall. Then tap Take Photo."
        case .resume: "Your first photo is waiting. Tap Continue."
        case .checkResult: "Framed and checked. Look at anything marked."
        case .output: output == .print ? "Looks good? Tap Print. Retakes and fixes are free."
                                       : "Looks good? Tap here to continue. Retakes and fixes are free."
        case .paper: "Choose the paper you'll print on."
        case .copies: "Choose how many copies you need. Fill Pages adds whole pages."
        case .continueSheet: "All set? Tap Continue."
        case .unlock: "This is your one free photo. Unlocking it uses your free credit."
        case .route: "Choose where you'll print."
        case .printHome: "Load photo paper in your printer, then tap Print."
        case .share: output == .print ? "Send the image to your print shop."
                                      : "Share it, or save it to Files for your online form."
        }
    }
}

// MARK: - Guide colour

/// The guide's own colour (founder, 2026-11-14, round 1 in docs/ui/explorations): highlighter yellow, so it stands
/// apart from the teal app and reads as a layer on top. A lemon yellow, never amber, to stay clear of the orange warn
/// status. Not a brand colour and never used outside the guide.
enum GuideStyle {
    /// Bubble and chip fill: system yellow.
    static let fill = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1, green: 0.839, blue: 0.039, alpha: 1)    // #FFD60A
        : UIColor(red: 1, green: 0.8, blue: 0, alpha: 1) })       // #FFCC00
    /// The ring around the control to use: a touch deeper in Light so it holds against the light screen.
    static let ring = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1, green: 0.839, blue: 0.039, alpha: 1)    // #FFD60A
        : UIColor(red: 0.949, green: 0.718, blue: 0, alpha: 1) }) // #F2B700
    /// Text and glyphs on the yellow, in both appearances.
    static let ink = Color(red: 0.11, green: 0.11, blue: 0.118)   // #1C1C1E
}

// MARK: - Anchors

/// Where each guided control is on screen, and where the bottom controls start (a bubble placed below its control
/// must not cover them), collected for the screen's guide overlay.
struct GuideAnchors {
    var tips: [GuideTip: Anchor<CGRect>] = [:]
    var avoid: Anchor<CGRect>?
}

struct GuideAnchorKey: PreferenceKey {
    static let defaultValue = GuideAnchors()
    static func reduce(value: inout GuideAnchors, nextValue: () -> GuideAnchors) {
        let next = nextValue()
        value.tips.merge(next.tips) { $1 }
        value.avoid = next.avoid ?? value.avoid
    }
}

extension View {
    /// Marks the screen's bottom controls: a guide bubble never sits on them unless it points at one.
    func guideAvoid() -> some View {
        // Merged, not set: the controls inside the bar carry their own anchors.
        transformAnchorPreference(key: GuideAnchorKey.self, value: .bounds) { $0.avoid = $1 }
    }

    /// Marks the control `tip` points at, and outlines it while that tip is shown.
    func guideTarget(_ tip: GuideTip, current: GuideTip?, cornerRadius: CGFloat = 100, ring: Bool = true) -> some View {
        coachTarget(ring && current == tip, cornerRadius: cornerRadius)
            .transformAnchorPreference(key: GuideAnchorKey.self, value: .bounds) { $0.tips[tip] = $1 }
    }

    /// Draws the current tip's bubble over the screen, next to its control, without moving anything (founder,
    /// 2026-11-14: a line in the bottom bar made the bar taller and hid the screen behind it).
    func guideOverlay(_ coach: TutorialCoach, current: GuideTip?, output: Output) -> some View {
        overlayPreferenceValue(GuideAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if let current, let anchor = anchors.tips[current] {
                    GuideCallout(tip: current, output: output, target: proxy[anchor], area: proxy.size,
                                 floor: anchors.avoid.map { proxy[$0].minY }) {
                        coach.pass(current)
                    }
                }
            }
        }
    }
}

// MARK: - Callout

/// One bubble placed above or below its control (where there is more room), its tail on the control's centre. An
/// explanation carries Next; a bubble about a button lets taps through to it.
private struct GuideCallout: View {
    let tip: GuideTip
    let output: Output
    let target: CGRect
    let area: CGSize
    /// Where the bottom controls start, when the screen marked them.
    var floor: CGFloat?
    let next: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    /// Measured, so a bubble goes below its control only when it fits there whole (longer languages wrap more).
    @State private var height: CGFloat = 72

    private static let margin: CGFloat = 16
    private static let gap: CGFloat = 8

    var body: some View {
        let bottom = floor.map { $0 > target.maxY ? $0 : area.height } ?? area.height
        let roomBelow = bottom - target.maxY
        let fitsBelow = roomBelow >= height + Self.gap
        let above = tip.prefersBelow && fitsBelow ? false : target.minY > roomBelow
        let progress = TutorialFlow.progress(of: tip.step, output: output)
        let text = TutorialCopy.text(tip, output: output)
        let tailX = min(max(target.midX - Self.margin, 28), area.width - 2 * Self.margin - 28)
        GuideBubble(position: progress.position, count: progress.count, hint: Text(text), up: !above,
                    tailX: tailX, bounce: reduceMotion ? "" : tip.rawValue,
                    next: tip.isExplanation ? { withAnimation(reduceMotion ? nil : .smooth) { next() } } : nil)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
            .allowsHitTesting(tip.isExplanation)
            .padding(.horizontal, Self.margin)
            .padding(above ? .bottom : .top, above ? area.height - target.minY + Self.gap : target.maxY + Self.gap)
            .frame(width: area.width, height: area.height, alignment: above ? .bottom : .top)
            .scaleEffect(shown || reduceMotion ? 1 : 0.92, anchor: above ? .bottom : .top)
            .opacity(shown ? 1 : 0)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("coachLine")
            .onChange(of: tip, initial: true) {
                shown = false
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.3).delay(0.2)) { shown = true }
                // Each new instruction is read out without moving VoiceOver's focus.
                AccessibilityNotification.Announcement(String(localized: text)).post()
            }
    }
}

/// The bubble itself, also shown on the welcome page so the guide is recognised when it appears.
struct GuideBubble: View {
    let position: Int
    let count: Int
    let hint: Text
    let up: Bool
    /// The tail's centre from the bubble's leading edge; nil centres it.
    var tailX: CGFloat?
    var bounce = ""
    /// Shown as Next when the bubble is an explanation.
    var next: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if up { tail }
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                HStack(spacing: Design.Spacing.text) {
                    Image(systemName: up ? "hand.point.up.left.fill" : "hand.point.down.fill")
                        .symbolEffect(.bounce, options: .repeat(2), value: bounce)
                    Text("Guide · \(position) of \(count)")
                        .contentTransition(.numericText())
                    Spacer(minLength: Design.Spacing.text)
                    HStack(spacing: 3) {
                        ForEach(1...count, id: \.self) { index in
                            Capsule()
                                .fill(GuideStyle.ink.opacity(index <= position ? 1 : 0.3))
                                .frame(width: 14, height: 3)
                        }
                    }
                    .accessibilityHidden(true)
                }
                .font(Design.Typography.caption.weight(.semibold))
                .foregroundStyle(GuideStyle.ink.opacity(0.8))
                HStack(alignment: .lastTextBaseline, spacing: Design.Spacing.control) {
                    hint
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GuideStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let next {
                        Button(action: next) {
                            Text("Next")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(GuideStyle.fill)
                                .padding(.horizontal, Design.Spacing.control)
                                .padding(.vertical, Design.Spacing.tight)
                                .background(GuideStyle.ink, in: Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("guideNext")
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.control)
            .padding(.vertical, Design.Spacing.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GuideStyle.fill, in: RoundedRectangle(cornerRadius: 16))
            if !up { tail }
        }
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
    }

    private var tail: some View {
        GuideTail(up: up)
            .frame(maxWidth: .infinity, alignment: tailX == nil ? .center : .leading)
            .padding(.leading, tailX.map { max(0, $0 - 9) } ?? 0)
    }
}

/// The bubble's pointer, centred: every control the guide points at spans the width of the screen.
private struct GuideTail: View {
    let up: Bool

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: up ? 9 : 0))
            path.addLine(to: CGPoint(x: 9, y: up ? 0 : 9))
            path.addLine(to: CGPoint(x: 18, y: up ? 9 : 0))
            path.closeSubpath()
        }
        .fill(GuideStyle.fill)
        .frame(width: 18, height: 9)
        .padding(up ? .bottom : .top, -1)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Outlines the one control the coach asks for, with a slow breathing ring (steady under Reduce Motion).
    func coachTarget(_ active: Bool, cornerRadius: CGFloat = 100) -> some View {
        modifier(CoachTarget(active: active, cornerRadius: cornerRadius))
    }
}

private struct CoachTarget: ViewModifier {
    let active: Bool
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(GuideStyle.ring, lineWidth: 3)
                        .padding(-4)
                        .opacity(reduceMotion ? 1 : (breathing ? 1 : 0.35))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .onAppear {
                            guard !reduceMotion else { return }
                            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { breathing = true }
                        }
                        .onDisappear { breathing = false }
                }
            }
    }
}

// MARK: - Welcome

/// Shown once, on a new install, before anything else. No skip (ADR-052): one button starts the first photo.
struct TutorialWelcomeView: View {
    let credits: Int
    let start: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.sectionTight) {
                hero
                VStack(alignment: .leading, spacing: Design.Spacing.text) {
                    Label("Guided first photo", systemImage: "hand.point.down.fill")
                        .font(Design.Typography.caption.weight(.semibold))
                        .foregroundStyle(GuideStyle.ink)
                        .padding(.horizontal, Design.Spacing.text)
                        .padding(.vertical, Design.Spacing.tight)
                        .background(GuideStyle.fill, in: Capsule())
                    Text("Let's make your first ID photo together")
                        .font(Design.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("tutorialWelcome")
                    Text("This one time, a guide walks you through each step, from the photo to the print. It takes a few minutes.")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                }
                // The free photo first, where it is seen without scrolling (founder, 2026-11-14).
                creditNote
                guidePreview
                VStack(alignment: .leading, spacing: Design.Spacing.group) {
                    row("camera", "Take your photo", "Against a plain wall, with the camera guiding you.")
                    row("checkmark.seal", "We frame and check it", "Sized for your document, with anything to fix pointed out.")
                    row("printer", "Print it", "At home on photo paper, or at any print shop.")
                }
            }
            .padding(.horizontal)
            .padding(.top, Design.Spacing.block)
        }
        .background(Design.Surface.screen)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Design.Spacing.text) {
                Button(action: start) { Text("Start").frame(maxWidth: .infinity) }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("tutorialStart")
                Text("Your photos stay on your iPhone.")
                    .font(Design.Typography.note)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, Design.Spacing.text)
            .background(Design.Surface.screen)
        }
        .interactiveDismissDisabled()
    }

    /// The selfie becomes the ID photo: the app's promise in one picture, on the mat.
    private var hero: some View {
        HStack(spacing: Design.Spacing.group) {
            Image("SampleSelfie")
                .resizable().scaledToFill()
                .frame(width: 132, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.photo))
                .paperShadow()
                .rotationEffect(.degrees(-4))
            Image(systemName: "arrow.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Image("SamplePortrait")
                .resizable().scaledToFit()
                .frame(height: 112)
                .padding(5)
                .background(.white)
                .paperShadow()
                .rotationEffect(.degrees(3))
        }
        .padding(.vertical, Design.Spacing.section)
        .frame(maxWidth: .infinity)
        .onMat(bleed: 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("A selfie becomes an ID photo"))
    }

    private func row(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 36, height: 36)
                .background(Color.brandAccent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(title).font(Design.Typography.rowTitle)
                Text(detail).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// What the guide will look like, so it is recognised on the real screens and known to be temporary.
    private var guidePreview: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            Text("Follow the guide").font(Design.Typography.cardTitle)
            GuideBubble(position: 1, count: 4, hint: Text("It sits above the next button to tap, and goes away after your first photo."), up: false)
                .accessibilityElement(children: .combine)
            // Stands for "the next button": an outline, so it is not mistaken for a real, disabled one.
            RoundedRectangle(cornerRadius: 100)
                .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .frame(height: 44)
                .accessibilityHidden(true)
        }
    }

    private var creditNote: some View {
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: "gift")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
            Text("The guide gives you one free photo: this first one. You can print it again at no cost. After that, each photo uses one credit.")
                .font(Design.Typography.cardDetail)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Design.Spacing.cardContent)
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.card))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - All set

/// The tutorial's last page, once the photo has been printed, shared or saved.
struct TutorialDoneView: View {
    let output: Output
    let route: PrintCheckView.PrintRoute?
    let creditsLeft: Int
    /// Opens Check Your Print (home printing only).
    var checkPrint: (() -> Void)?
    let done: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Design.Spacing.block) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: Design.Size.completionSeal))
                .foregroundStyle(StatusStyle.pass)
                .symbolEffect(.bounce, value: appeared)
                .accessibilityHidden(true)
            VStack(spacing: Design.Spacing.text) {
                Text("You're all set")
                    .font(Design.Typography.hero)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("tutorialAllSet")
                Text(summary)
                    .font(Design.Typography.cardDetail)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: Design.Spacing.group) {
                if output == .print {
                    tip("ruler", "Check the size", "Measure the 50 mm line on the print. If it's right, every photo is the right size.")
                }
                if creditsLeft > 0 {
                    tip("creditcard", "^[\(creditsLeft) credit](inflect: true) left", "Each credit unlocks one person's photo, for every print and digital copy.")
                } else {
                    tip("creditcard", "Your free photo is used", "Prints of this photo stay free. A new photo uses one credit, for every print and digital copy.")
                }
                tip("photo", "Need it for an online form?", "The digital photo is included: tap Digital Photo on Photo Check.")
            }
            .padding(Design.Spacing.cardContent)
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.card))
            Spacer(minLength: 0)
            VStack(spacing: Design.Spacing.text) {
                if let checkPrint {
                    Button(action: checkPrint) { Text("Check Your Print").frame(maxWidth: .infinity) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("tutorialCheckPrint")
                    Button("Done", action: done)
                        .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
                        .accessibilityIdentifier("tutorialDone")
                } else {
                    Button(action: done) { Text("Done").frame(maxWidth: .infinity) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("tutorialDone")
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, Design.Spacing.section)
        .padding(.bottom, Design.Spacing.text)
        .background(Design.Surface.screen)
        .interactiveDismissDisabled()
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear { if !reduceMotion { appeared = true } }
    }

    private var summary: LocalizedStringKey {
        switch (output, route) {
        case (.digital, _): "Your first ID photo is saved. Next time, it works the same way, without the guide."
        case (_, .shop?): "Your print image is on its way to the shop. Next time, it works the same way, without the guide."
        default: "Your first ID photos are printing. Next time, it works the same way, without the guide."
        }
    }

    private func tip(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(title).font(Design.Typography.rowTitle)
                Text(detail).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
