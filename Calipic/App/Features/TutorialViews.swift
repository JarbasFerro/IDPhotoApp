import SwiftUI

// First-run tutorial (ADR-052): the welcome page, the guide bubble that sits just above the one control to use on
// each real screen, the outline around that control, and the closing "You're all set".

// MARK: - Copy

/// What the guide says on each step: one short instruction. Kept beside the views: it is presentation, not rules.
enum TutorialCopy {
    static func hint(_ step: TutorialStep, output: Output, hasPhoto: Bool, route: PrintCheckView.PrintRoute?) -> LocalizedStringResource {
        switch step {
        case .photo: hasPhoto ? "Your first photo is waiting where you left it."
                              : "Check the document above, then take your photo."
        case .check: output == .print ? "Looks good? Tap Print. Retakes and fixes are free."
                                      : "Looks good? Continue. Retakes and fixes are free."
        case .sheet: "Pick the paper and copies, then tap Continue."
        case .unlock: "Your free credit unlocks this first photo."
        case .finish:
            switch (output, route) {
            case (.digital, _): "Share it, or save it to Files for your online form."
            case (_, .home?): "Load photo paper in your printer, then tap Print."
            case (_, .shop?): "Send the image to your print shop."
            case (_, nil): "Choose where you'll print."
            }
        }
    }

    /// The control the hint is about is above it, in the content, rather than the button right below.
    static func pointsUp(_ step: TutorialStep, output: Output, route: PrintCheckView.PrintRoute?) -> Bool {
        step == .finish && output == .print && route == nil
    }
}

// MARK: - Guide bubble

/// The guide: a filled speech bubble right above the control to use, its tail pointing at it (founder, 0.20.15: a
/// plain line was easy to pass without noticing, and it should read as a temporary layer, not part of the app). The
/// filled teal sets it apart from the app's own cards and buttons; it pops in at each new step.
struct CoachLine: View {
    let step: TutorialStep
    let output: Output
    var hasPhoto = true
    var route: PrintCheckView.PrintRoute?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        let progress = TutorialFlow.progress(of: step, output: output)
        let hint = TutorialCopy.hint(step, output: output, hasPhoto: hasPhoto, route: route)
        let up = TutorialCopy.pointsUp(step, output: output, route: route)
        let key = "\(step)\(route.map { "\($0)" } ?? "")\(hasPhoto)"
        GuideBubble(position: progress.position, count: progress.count, hint: Text(hint), up: up,
                    bounce: reduceMotion ? "" : key)
        .scaleEffect(shown || reduceMotion ? 1 : 0.9, anchor: up ? .top : .bottom)
        .opacity(shown ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("coachLine")
        .onChange(of: key, initial: true) {
            shown = false
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.45, bounce: 0.35).delay(0.15)) { shown = true }
            // Each new instruction is read out without moving VoiceOver's focus.
            AccessibilityNotification.Announcement(String(localized: hint)).post()
        }
    }
}

/// The bubble itself, also shown on the welcome page so the guide is recognised when it appears.
struct GuideBubble: View {
    let position: Int
    let count: Int
    let hint: Text
    let up: Bool
    var bounce = ""

    var body: some View {
        VStack(spacing: 0) {
            if up { GuideTail(up: true) }
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
                                .fill(.white.opacity(index <= position ? 1 : 0.35))
                                .frame(width: 14, height: 3)
                        }
                    }
                    .accessibilityHidden(true)
                }
                .font(Design.Typography.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                hint
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Design.Spacing.control)
            .padding(.vertical, Design.Spacing.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.brandAccentFill, in: RoundedRectangle(cornerRadius: 16))
            if !up { GuideTail(up: false) }
        }
        .shadow(color: Color.brandAccentFill.opacity(0.35), radius: 10, y: 4)
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
        .fill(Color.brandAccentFill)
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
                        .strokeBorder(Color.brandAccent, lineWidth: 2)
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, Design.Spacing.text)
                        .padding(.vertical, Design.Spacing.tight)
                        .background(Color.brandAccentFill, in: Capsule())
                    Text("Let's make your first ID photo together")
                        .font(Design.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("tutorialWelcome")
                    Text("This one time, a guide walks you through each step, from the photo to the print. It takes a few minutes.")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: Design.Spacing.group) {
                    row("camera", "Take your photo", "Against a plain wall, with the camera guiding you.")
                    row("checkmark.seal", "We frame and check it", "Sized for your document, with anything to fix pointed out.")
                    row("printer", "Print it", "At home on photo paper, or at any print shop.")
                }
                guidePreview
                creditNote
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
            Text("Your first photo is free, and you can print it again at no cost.")
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
                    tip("creditcard", "Prints of this photo stay free", "A new person's photo uses one credit, for every print and digital copy.")
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
