import SwiftUI

extension DocumentChoice {
    /// The "allowed" band is shown only when the document's own rules state a head height. Otherwise the app's
    /// framing band is an engineering default, and calling it "allowed" would invent a rule (AGENTS.md §11).
    var statesHeadHeight: Bool { profile?.composition.headHeight != nil }
}

/// Words for a measurement. Lengths are facts about the framing Calipic made; the top of the head is an estimate
/// when hair or headwear hides it, and then the length says "about" (docs/03-design.md §4, the wording ladder).
enum MeasurementPresentation {
    static func millimetres(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// "Head 34 mm" or "Head about 34 mm".
    static func head(_ m: PhotoMeasurement) -> String {
        let length = millimetres(m.headHeightMM)
        return m.crownIsEstimate ? String(localized: "Head about \(length) mm") : String(localized: "Head \(length) mm")
    }

    /// "allowed 32–36 mm".
    static func allowed(_ m: PhotoMeasurement) -> String {
        String(localized: "allowed \(millimetres(m.headRangeMM.lowerBound))–\(millimetres(m.headRangeMM.upperBound)) mm")
    }

    static func spoken(_ m: PhotoMeasurement, showsRange: Bool) -> String {
        showsRange ? "\(head(m)), \(allowed(m))" : head(m)
    }
}

/// The measuring lines over the framed photo (decision D-2): top of head, eyes, chin, and a bracket with the head
/// length. They draw in when the photo lands, hold, then fold into the chip; the chip brings them back.
/// White hairlines with a soft shadow read on any photo; the brand teal is never drawn over a portrait.
struct MeasurementOverlay: View {
    let measurement: PhotoMeasurement
    let showsRange: Bool
    let visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width, height = geometry.size.height
            let crown = CGFloat(measurement.crownY) * height
            let eyes = CGFloat(measurement.eyeY) * height
            let chin = CGFloat(measurement.chinY) * height
            let bracketX = width - 10
            ZStack(alignment: .topLeading) {
                line(at: crown, width: width, dashed: true)
                line(at: eyes, width: width, dashed: false)
                line(at: chin, width: width, dashed: true)
                Path { path in
                    path.move(to: CGPoint(x: bracketX - 4, y: crown)); path.addLine(to: CGPoint(x: bracketX, y: crown))
                    path.addLine(to: CGPoint(x: bracketX, y: chin)); path.addLine(to: CGPoint(x: bracketX - 4, y: chin))
                }
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .shadow(color: .black.opacity(0.55), radius: 1)
                label
                    .frame(width: width - 8, alignment: .trailing)
                    .offset(x: 0, y: min(chin + 6, height - 34))
                    .opacity(progress)
            }
        }
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { if visible { drawIn() } }
        .onChange(of: visible) { _, now in if now { drawIn() } else { progress = 0 } }
    }

    private func line(at y: CGFloat, width: CGFloat, dashed: Bool) -> some View {
        Path { path in path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: width, y: y)) }
            .trim(from: 0, to: progress)
            .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 1, dash: dashed ? [4, 3] : []))
            .shadow(color: .black.opacity(0.55), radius: 1)
    }

    private var label: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(MeasurementPresentation.head(measurement)).font(.caption2.weight(.semibold))
            if showsRange { Text(MeasurementPresentation.allowed(measurement)).font(.caption2) }
        }
        .monospacedDigit()
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
        .environment(\.colorScheme, .dark)
    }

    private func drawIn() {
        progress = 0
        if reduceMotion { progress = 1 } else { withAnimation(.easeOut(duration: 0.7)) { progress = 1 } }
    }
}

/// The folded measurement under the photo. Tapping it shows the lines again.
struct MeasurementChip: View {
    let measurement: PhotoMeasurement
    let showsRange: Bool
    @Binding var showsLines: Bool

    var body: some View {
        Button { showsLines.toggle() } label: {
            HStack(spacing: Design.Spacing.tight) {
                Image(systemName: "ruler").accessibilityHidden(true)
                Text(MeasurementPresentation.head(measurement)).monospacedDigit()
                if showsRange {
                    Image(systemName: measurement.headInRange ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(measurement.headInRange ? StatusStyle.pass : StatusStyle.warn)
                        .accessibilityHidden(true)
                }
            }
            .font(Design.Typography.caption)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .tint(Color.secondary)
        .accessibilityLabel(Text(MeasurementPresentation.spoken(measurement, showsRange: showsRange)))
        .accessibilityHint(showsLines ? Text("Hides the measuring lines.") : Text("Shows the measuring lines on the photo."))
        // Two identifiers so UI tests can tell whether the lines are on the photo.
        .accessibilityIdentifier(showsLines ? "measureChipLinesShown" : "measureChip")
    }
}
