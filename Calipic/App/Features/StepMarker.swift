import SwiftUI

enum Step: Int, CaseIterable, Sendable {
    case photo, check, output
}

/// The three journey steps, with the current word emphasized (ADR-054).
struct StepMarker: View {
    let current: Step
    let output: Output
    /// Kept for existing call sites; the marker is compact everywhere now.
    var compact = false

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Step.allCases, id: \.self) { step in
                Text(name(step))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(step == current ? Color.primary : Color.secondary)
                    .lineLimit(1)
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
