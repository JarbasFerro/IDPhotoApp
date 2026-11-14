import SwiftUI

/// Status always has a symbol and spoken words, independent of the brand colour.
struct StatusMark: View {
    private let state: CheckState?
    @ScaledMetric(relativeTo: .body) private var size = Design.Size.statusMark

    init(_ state: CheckState) { self.state = state }
    private init() { state = nil }
    static var progress: StatusMark { StatusMark() }

    var body: some View {
        Group {
            if let state {
                Image(systemName: symbol(state))
                    .font(.system(size: size))
                    .foregroundStyle(StatusStyle.color(for: state))
                    .accessibilityLabel(Text(StatusStyle.name(for: state)))
            } else {
                ProgressView().controlSize(.small)
                    .accessibilityLabel("Checking your photo…")
            }
        }
        .frame(width: size, height: size)
    }

    private func symbol(_ state: CheckState) -> String {
        switch state {
        case .pass: "checkmark.circle.fill"
        case .warn: "exclamationmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .manualCheck: "eye.circle.fill"
        }
    }
}
