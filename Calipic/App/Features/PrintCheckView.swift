import SwiftUI
import UIKit

/// The hardware facts the true-size view needs. Kept out of the domain so `ScreenSize` stays pure.
enum DeviceScreen {
    /// Hardware model, for example "iPhone16,2". Simulators report the model they imitate.
    static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulated }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    /// Physical pixels per point of the screen showing the app (changes with Display Zoom).
    @MainActor static var nativeScale: Double {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return Double(scenes.first?.screen.nativeScale ?? 3)
    }

    static let calibrationKey = "screenPointsPerMM"
}

/// After printing: lay the print on the screen and compare it at true size (docs/03-design.md U1, roadmap 0.17).
/// The person's answer is the only evidence; the print panel finishing never counts as a correct print.
struct PrintCheckView: View {
    enum PrintRoute { case home, shop }
    private enum Answer: Hashable { case smaller, larger, unsure }

    let model: PhotoWorkflow
    let route: PrintRoute
    /// Opens the print panel again with the same files (home route only).
    var onPrintAgain: (() -> Void)?
    /// Leaves the whole printing flow (Finished → Done).
    let onFinished: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(DeviceScreen.calibrationKey) private var storedCalibration: Double = 0
    @State private var scale: ScreenScale = .unknown
    @State private var didNotMatch = false
    @State private var answer: Answer?
    @State private var showFinished = false
    @State private var showCalibration = false

    /// What the print has to compare: the 50 mm line when the page has one, otherwise one photo.
    private var reference: Reference {
        let page = model.layout.pages.first
        if let bar = page?.calibrationBar { return .line(lengthMM: bar.lengthMM) }
        if let trim = page?.placements.first?.trim { return .photo(widthMM: trim.width, heightMM: trim.height) }
        return .line(lengthMM: PrintLayoutSolver.calibrationBarLengthMM)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.section) {
                if let answer {
                    diagnosis(answer)
                } else if didNotMatch {
                    direction
                } else {
                    compare
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Design.Spacing.text)
            .frame(maxWidth: .infinity)
            if dynamicTypeSize.isAccessibilitySize { actions.padding() }
        }
        .background(Design.Surface.screen)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                actions
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.text)
                    .padding(.bottom, Design.Spacing.caption)
                    .background(Design.Surface.screen)
            }
        }
        .navigationTitle("Check Your Print")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }.accessibilityIdentifier("checkClose")
            }
        }
        .navigationDestination(isPresented: $showFinished) { FinishedView(model: model, onDone: onFinished) }
        .navigationDestination(isPresented: $showCalibration) { CardCalibrationView() }
        .onAppear(perform: resolveScale)
        .onChange(of: storedCalibration) { _, _ in resolveScale() }
        .sensoryFeedback(.selection, trigger: didNotMatch)
        .sensoryFeedback(.warning, trigger: answer) { _, new in new != nil }
    }

    private func resolveScale() {
        scale = ScreenScale.resolve(model: DeviceScreen.modelIdentifier, nativeScale: DeviceScreen.nativeScale,
                                    storedCalibration: storedCalibration > 0 ? storedCalibration : nil)
    }

    // MARK: - Step 1: compare

    @ViewBuilder private var compare: some View {
        if let perMM = scale.pointsPerMM {
            VStack(spacing: Design.Spacing.group) {
                Text(reference.layOnScreenInstruction)
                    .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("printCheckInstruction")
                TrueSizeReference(reference: reference, pointsPerMM: perMM)
                    .padding(.vertical, Design.Spacing.block)
                Text(reference.sameSizeQuestion)
                    .font(Design.Typography.screenTitle)
                    .multilineTextAlignment(.center)
                if case .calibrated = scale {
                    Button("Set Up Screen Size Again") { showCalibration = true }
                        .font(Design.Typography.note)
                        .accessibilityIdentifier("recalibrate")
                }
            }
        } else {
            VStack(spacing: Design.Spacing.group) {
                Image(systemName: "ruler")
                    .font(Design.Typography.titleGlyph).foregroundStyle(Color.brandAccent)
                    .accessibilityHidden(true)
                Text(reference.rulerQuestion)
                    .font(Design.Typography.screenTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("printCheckInstruction")
                Text("Or set up this screen once with a bank card or ID card, and compare the print on the screen.")
                    .font(Design.Typography.note).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Set Up Screen Size") { showCalibration = true }
                    .accessibilityIdentifier("calibrateWithCard")
            }
            .padding(.top, Design.Spacing.section)
        }
    }

    // MARK: - Step 2: which way

    private var direction: some View {
        VStack(spacing: Design.Spacing.group) {
            Image(systemName: "arrow.left.and.right")
                .font(Design.Typography.titleGlyph).foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Is the print smaller or larger?")
                .font(Design.Typography.screenTitle)
                .multilineTextAlignment(.center)
            Text("This tells us which printer setting changed the size.")
                .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Design.Spacing.section)
    }

    // MARK: - Step 3: the fix

    private func diagnosis(_ answer: Answer) -> some View {
        VStack(spacing: Design.Spacing.group) {
            Image(systemName: "printer")
                .font(Design.Typography.titleGlyph).foregroundStyle(StatusStyle.warn)
                .accessibilityHidden(true)
            Text(title(for: answer))
                .font(Design.Typography.screenTitle)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("diagnosisTitle")
            Text(fix(for: answer))
                .font(Design.Typography.cardDetail)
                .multilineTextAlignment(.center)
            Text(route == .home
                 ? "Your photos are unlocked, so printing again is free."
                 : "Your photos are unlocked, so sharing them again is free.")
                .font(Design.Typography.note).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Design.Spacing.section)
    }

    private func title(for answer: Answer) -> LocalizedStringKey {
        if route == .shop { return "The print was resized" }
        switch answer {
        case .smaller: return "The printer shrank the page"
        case .larger: return "The printer enlarged the page"
        case .unsure: return "The printer changed the size"
        }
    }

    private func fix(for answer: Answer) -> LocalizedStringKey {
        if route == .shop { return "Ask the shop to print the image at its original size: no cropping, no Fit to Page, and no borderless printing." }
        switch answer {
        case .smaller: return "In the print options, choose Actual Size or 100 %, and turn off Fit to Page."
        case .larger: return "Turn off Borderless and Fit to Page, and choose the paper size you loaded."
        case .unsure: return "Choose Actual Size or 100 %, turn off Fit to Page and Borderless, and choose the paper size you loaded."
        }
    }

    // MARK: - Actions

    @ViewBuilder private var actions: some View {
        VStack(spacing: Design.Spacing.text) {
            if answer != nil {
                if route == .home, let onPrintAgain {
                    Button { onPrintAgain() } label: { Text("Print Again").frame(maxWidth: .infinity) }
                        .brandProminentButtonStyle().controlSize(.large)
                        .accessibilityIdentifier("printAgain")
                }
                Button { dismiss() } label: { Text("Close").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered).controlSize(.large)
                    .accessibilityIdentifier("diagnosisClose")
            } else if didNotMatch {
                HStack(spacing: Design.Spacing.control) {
                    Button { withAnimation { answer = .smaller } } label: { Text("Smaller").frame(maxWidth: .infinity) }
                        .accessibilityIdentifier("checkSmaller")
                    Button { withAnimation { answer = .larger } } label: { Text("Larger").frame(maxWidth: .infinity) }
                        .accessibilityIdentifier("checkLarger")
                }
                .buttonStyle(.bordered).controlSize(.large)
                Button("Not Sure") { withAnimation { answer = .unsure } }
                    .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
                    .accessibilityIdentifier("checkNotSure")
            } else {
                Button { showFinished = true } label: { Text("Yes, Same Size").frame(maxWidth: .infinity) }
                    .brandProminentButtonStyle().controlSize(.large)
                    .accessibilityIdentifier("checkMatches")
                Button { withAnimation { didNotMatch = true } } label: { Text("No").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered).controlSize(.large)
                    .accessibilityIdentifier("checkNoMatch")
            }
        }
    }
}

/// What is compared, and how to ask about it.
enum Reference: Equatable {
    case line(lengthMM: Double)
    case photo(widthMM: Double, heightMM: Double)

    var label: String {
        switch self {
        case .line(let length): String(localized: "\(length.formatted(.number.precision(.fractionLength(0...1)))) mm")
        case .photo(let width, let height): DocumentPresentation.size(widthMM: width, heightMM: height)
        }
    }

    var layOnScreenInstruction: LocalizedStringKey {
        switch self {
        case .line: "Lay the printed page on the screen so the line at its bottom sits on this line."
        case .photo: "Lay one printed photo on the screen, over this outline."
        }
    }

    var sameSizeQuestion: LocalizedStringKey {
        switch self {
        case .line: "Are the two lines the same length?"
        case .photo: "Is the photo the same size as the outline?"
        }
    }

    var rulerQuestion: LocalizedStringKey {
        switch self {
        case .line(let length):
            "Measure the line at the bottom of your page with a ruler. Is it \(Int(length.rounded())) mm?"
        case .photo(let width, let height):
            "Measure one photo with a ruler. Is it \(DocumentPresentation.size(widthMM: width, heightMM: height))?"
        }
    }
}

/// The reference drawn at its physical size. Fixed in points: it must not grow with Dynamic Type.
struct TrueSizeReference: View {
    let reference: Reference
    let pointsPerMM: Double

    var body: some View {
        VStack(spacing: Design.Spacing.text) {
            switch reference {
            case .line(let length):
                let width = length * pointsPerMM
                Canvas { context, size in
                    var path = Path()
                    let y = size.height / 2
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: width, y: y))
                    for x in [0, width] { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)) }
                    context.stroke(path, with: .color(.primary), lineWidth: 1)
                }
                .frame(width: width, height: 24)
            case .photo(let w, let h):
                Rectangle()
                    .strokeBorder(Color.primary, lineWidth: 1)
                    .frame(width: w * pointsPerMM, height: h * pointsPerMM)
            }
            Text(reference.label)
                .font(Design.Typography.readout(.caption, weight: .regular)).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Real-size guide, \(reference.label)"))
        .accessibilityIdentifier("trueSizeReference")
    }
}

/// One-time setup for a screen whose density is unknown: match a card's short side, then save.
struct CardCalibrationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(DeviceScreen.calibrationKey) private var storedCalibration: Double = 0
    /// Width of the outline in points; starts at a typical 460 ppi, 3× screen.
    @State private var width: Double = 53.98 * 460 / 25.4 / 3

    private var range: ClosedRange<Double> { (53.98 * ScreenSize.plausibleRange.lowerBound)...(53.98 * 6.9) }

    var body: some View {
        VStack(spacing: Design.Spacing.group) {
            Text("Hold a bank card or ID card upright against the screen. Change the size until the outline matches the card's width.")
                .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 3.18 * width / 53.98)
                .strokeBorder(Color.brandAccent, lineWidth: 2)
                .frame(width: width, height: width * ScreenSize.cardWidthMM / ScreenSize.cardHeightMM)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            HStack(spacing: Design.Spacing.control) {
                Button { width = max(range.lowerBound, width - 0.5) } label: { Image(systemName: "minus") }
                    .accessibilityLabel("Smaller")
                Slider(value: $width, in: range)
                    .accessibilityLabel("Outline size")
                    .accessibilityIdentifier("calibrationSlider")
                Button { width = min(range.upperBound, width + 0.5) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Larger")
            }
            .buttonStyle(.bordered)
            Button {
                if let value = ScreenSize.pointsPerMillimetre(cardShortSidePoints: width) { storedCalibration = value }
                dismiss()
            } label: { Text("Save").frame(maxWidth: .infinity) }
            .brandProminentButtonStyle().controlSize(.large)
            .accessibilityIdentifier("calibrationSave")
        }
        .padding()
        .background(Design.Surface.screen)
        .navigationTitle("Screen Size")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if storedCalibration > 0 { width = storedCalibration * 53.98 } }
    }
}
