import SwiftUI

enum Step: Int, CaseIterable, Sendable {
    case photo, check, output
}

/// A quiet progress line in the navigation bar: Photo › Check › Print (or Save on the digital path).
struct StepMarker: View {
    let current: Step
    let output: Output
    /// Past steps shrink to a checkmark; Photo Check needs this to stay clear of Retake and More.
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Step.allCases, id: \.self) { step in
                if step != .photo {
                    Image(systemName: "chevron.compact.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                label(step)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(minHeight: Design.Size.minimumTarget)
        .accessibilityElement(children: .combine)
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

    @ViewBuilder
    private func label(_ step: Step) -> some View {
        if step.rawValue < current.rawValue {
            if compact {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark").font(.caption2.weight(.semibold))
                    Text(name(step))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        } else if step == current {
            Text(name(step)).font(.footnote.weight(.semibold)).foregroundStyle(.primary)
        } else {
            Text(name(step)).font(.footnote).foregroundStyle(.tertiary)
        }
    }
}
