import SwiftUI

/// One side of the checks for a photo: what the app measured, or what only a person can judge. Each short row on
/// Photo Check opens its own list, at half height so the photo stays in view above it.
struct CheckDetailsSheet: View {
    enum Focus: String, Identifiable { case measured, byEye; var id: String { rawValue } }
    let summary: PhotoCheckSummary
    let byEye: [String]
    let focus: Focus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if focus == .measured {
                    // What needs attention first; the checks that passed follow.
                    let passed = summary.rows.filter { $0.state == .pass }
                    if !summary.attention.isEmpty {
                        Section("To look at") { ForEach(summary.attention) { row in measuredRow(row) } }
                    }
                    if !passed.isEmpty {
                        Section("Looks fine") { ForEach(passed) { row in measuredRow(row) } }
                    }
                } else if !byEye.isEmpty {
                    Section {
                        ForEach(byEye, id: \.self) { id in
                            Label { Text(DocumentPresentation.check(id)) } icon: {
                                Image(systemName: StatusStyle.symbol(for: .manualCheck))
                                    .foregroundStyle(StatusStyle.color(for: .manualCheck))
                            }
                        }
                    } footer: {
                        Text("The office that receives the photo decides whether to accept it.")
                    }
                }
            }
            .navigationTitle(focus == .measured ? Text("Measured") : Text("Check by eye"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("checkDetailsDone")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func measuredRow(_ row: PhotoCheckSummary.Row) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(row.title).font(Design.Typography.rowTitle)
                Text(row.detail).font(Design.Typography.note).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: StatusStyle.symbol(for: row.state))
                .foregroundStyle(StatusStyle.color(for: row.state))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(String(localized: row.title)), \(String(localized: StatusStyle.name(for: row.state))). \(String(localized: row.detail))"))
    }
}
