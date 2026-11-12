import SwiftUI

enum Step: Int, CaseIterable, Sendable {
    case photo, check, output
}

/// A quiet progress line in the navigation bar: ✓ Photo › Check › Print (or Save on the digital path).
///
/// A centred bar item only gets twice the room to the nearer side, so on Photo Check (Back on one side, Retake and
/// More on the other) the full line may not fit. The marker then picks the first version that fits: smaller type,
/// then without the upcoming step, which the screen's own button already names. Every step it shows keeps its word;
/// a bare checkmark does not say what was done (founder, 0.18 review).
struct StepMarker: View {
    let current: Step
    let output: Output
    /// Kept for call sites that sit between crowded bar items; the fitting below handles the space either way.
    var compact = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            line(font: .footnote, steps: Step.allCases)
            line(font: .caption, steps: Step.allCases)
            line(font: .caption, steps: Step.allCases.filter { $0.rawValue <= current.rawValue })
        }
        .frame(minHeight: Design.Size.minimumTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(current.rawValue + 1) of 3: \(String(localized: name(current)))"))
        .accessibilityIdentifier("stepMarker")
    }

    private func line(font: Font, steps: [Step]) -> some View {
        HStack(spacing: 3) {
            ForEach(steps, id: \.self) { step in
                if step != steps.first {
                    Image(systemName: "chevron.compact.right").foregroundStyle(.tertiary)
                }
                label(step)
            }
        }
        .font(font)
        .lineLimit(1)
        .fixedSize()
    }

    private func name(_ step: Step) -> LocalizedStringResource {
        switch step {
        case .photo: "Photo"
        case .check: "Check"
        case .output: output == .print ? "Print" : "Save"
        }
    }

    @ViewBuilder
    private func label(_ step: Step) -> some View {
        if step.rawValue < current.rawValue {
            HStack(spacing: 2) {
                Image(systemName: "checkmark").imageScale(.small).fontWeight(.semibold)
                Text(name(step))
            }
            .foregroundStyle(.secondary)
        } else if step == current {
            Text(name(step)).fontWeight(.semibold).foregroundStyle(.primary)
        } else {
            Text(name(step)).foregroundStyle(.tertiary)
        }
    }
}
