import SwiftUI

/// Every check for one photo: what the app measured, then what only a person can judge. Opened from the two
/// short rows on Photo Check, at half height so the photo stays in view above it.
struct CheckDetailsSheet: View {
    let summary: PhotoCheckSummary
    let byEye: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !summary.rows.isEmpty {
                    Section("Measured") {
                        ForEach(summary.rows) { row in measuredRow(row) }
                    }
                }
                if !byEye.isEmpty {
                    Section {
                        ForEach(byEye, id: \.self) { id in
                            Label { Text(DocumentPresentation.check(id)) } icon: {
                                Image(systemName: StatusStyle.symbol(for: .manualCheck))
                                    .foregroundStyle(StatusStyle.color(for: .manualCheck))
                            }
                        }
                    } header: {
                        Text("Check by eye")
                    } footer: {
                        Text("The office that receives the photo decides whether to accept it.")
                    }
                }
            }
            .navigationTitle("Checks")
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
