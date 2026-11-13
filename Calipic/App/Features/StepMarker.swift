import SwiftUI

enum Step: Int, CaseIterable, Sendable {
    case photo, check, output
}

/// Where the person is in the three steps: the current step's name over three short segments, filled up to and
/// including the current one. It replaces the breadcrumb "✓ Photo › Check › Print" (founder, 0.20 review: it never
/// sat well in the bar). A compact header that names only the current step is the usual pattern for a short linear
/// flow on a phone; it always fits between the bar's buttons, and the screen's own button names the next step.
struct StepMarker: View {
    let current: Step
    let output: Output
    /// Kept for existing call sites; the marker is compact everywhere now.
    var compact = false

    var body: some View {
        VStack(spacing: 5) {
            Text(name(current))
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 4) {
                ForEach(Step.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= current.rawValue ? AnyShapeStyle(Color.brandAccent) : AnyShapeStyle(.quaternary))
                        .frame(width: 18, height: 3)
                }
            }
        }
        .fixedSize()
        .frame(minHeight: Design.Size.minimumTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(current.rawValue + 1) of 3: \(String(localized: name(current)))"))
        .accessibilityIdentifier("stepMarker")
    }

    private func name(_ step: Step) -> LocalizedStringResource {
        switch step {
        case .photo: "Photo"
        case .check: "Check"
        case .output: output == .print ? "Print" : "Save"
        }
    }
}
