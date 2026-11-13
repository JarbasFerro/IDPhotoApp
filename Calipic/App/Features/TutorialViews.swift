import SwiftUI

// First-run tutorial (ADR-052): the welcome page, the coach card shown under the navigation bar of each real screen,
// the outline around the one control to use, and the closing "You're all set".

// MARK: - Copy

/// What the coach says on each step. Kept beside the views: it is presentation, not rules.
enum TutorialCopy {
    static func title(_ step: TutorialStep, output: Output, hasPhoto: Bool) -> LocalizedStringKey {
        switch step {
        case .document: "Is this your document?"
        case .photo: hasPhoto ? "Continue your first photo" : "Take your photo"
        case .check: "Framed and checked"
        case .sheet: "Lay out your sheet"
        case .unlock: "Unlock with a free credit"
        case .finish: output == .print ? "Print your photos" : "Save your photo"
        }
    }

    static func message(_ step: TutorialStep, output: Output, hasPhoto: Bool, route: PrintCheckView.PrintRoute?) -> LocalizedStringKey {
        switch step {
        case .document: "The photo is sized for it. Tap it to choose another, or continue."
        case .photo: hasPhoto ? "Your photo is waiting where you left it."
                              : "Stand facing a window, in front of a plain light wall. Or choose a photo from your library."
        case .check: output == .print ? "Look at anything marked. Retakes and adjustments are free. Then tap Print."
                                      : "Look at anything marked. Retakes and adjustments are free. Then continue."
        case .sheet: "Choose the paper and how many copies, then tap Continue."
        case .unlock: "This first photo uses one of your two free credits. After that, it's yours to print and share again."
        case .finish:
            switch (output, route) {
            case (.digital, _): "Share it, or save it to Files, to use it in your online form."
            case (_, .home?): "Load photo paper in your printer, then tap Print."
            case (_, .shop?): "Send the image to your print shop, or save it to Files to take with you."
            case (_, nil): "Choose where you'll print: at home or at a shop."
            }
        }
    }

    static func symbol(_ step: TutorialStep, output: Output) -> String {
        switch step {
        case .document: "person.text.rectangle"
        case .photo: "camera"
        case .check: "checkmark.seal"
        case .sheet: "square.grid.3x3"
        case .unlock: "lock.open"
        case .finish: output == .print ? "printer" : "square.and.arrow.up"
        }
    }
}

// MARK: - Coach card

/// One card under the navigation bar: where the person is in the tutorial, what to do, and at most one action.
struct CoachCard: View {
    let step: TutorialStep
    let steps: [TutorialStep]
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        let position = TutorialFlow.position(of: step, in: steps)
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: TutorialCopy.symbol(step, output: steps.contains(.sheet) ? .print : .digital))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 36, height: 36)
                .background(Color.brandAccent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                HStack(spacing: Design.Spacing.text) {
                    Text("First photo · \(position) of \(steps.count)")
                        .font(Design.Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.brandAccent)
                    progress(position)
                }
                Text(title).font(Design.Typography.rowTitle)
                Text(message)
                    .font(Design.Typography.cardDetail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .padding(.top, Design.Spacing.tight)
                        .accessibilityIdentifier("coachAction")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Design.Spacing.cardContent)
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .strokeBorder(Color.brandAccent.opacity(0.35), lineWidth: Design.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("coachCard")
    }

    /// Short segments, filled up to the current step; the words above carry the same information.
    private func progress(_ position: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(1...steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= position ? Color.brandAccent : Color.secondary.opacity(0.25))
                    .frame(width: 10, height: 3)
            }
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the coach card under the navigation bar while the tutorial is active.
    func tutorialCoach(_ card: CoachCard?) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            if let card {
                card
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.tight)
                    .padding(.bottom, Design.Spacing.text)
                    .background(Design.Surface.screen)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

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
                    Text("Let's make your first ID photo")
                        .font(Design.Typography.hero)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("tutorialWelcome")
                    Text("We'll guide you through it, from the photo to the print. It takes a few minutes.")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: Design.Spacing.group) {
                    row("camera", "Take your photo", "Against a plain wall, with the camera guiding you.")
                    row("checkmark.seal", "We frame and check it", "Sized for your document, with anything to fix pointed out.")
                    row("printer", "Print it", "At home on photo paper, or at any print shop.")
                }
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

    private var creditNote: some View {
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: "gift")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.brandAccent)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
            Text("You have \(credits) free credits. This first photo uses one, and it's yours to print again at no cost.")
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
                tip("creditcard", "^[\(creditsLeft) credit](inflect: true) left", "Each credit unlocks one person's photo, for every print and digital copy.")
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
