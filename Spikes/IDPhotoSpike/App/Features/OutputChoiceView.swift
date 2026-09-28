import SwiftUI

/// One decision after the photo check: a single digital file or a composed print sheet.
struct OutputChoiceView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.sectionTight) {
                if let entry {
                    PortraitView(entry: entry, label: "Prepared photo")
                        .frame(width: 160)
                        .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: Design.Spacing.text) {
                        Text("How will you use it?")
                            .font(Design.Typography.screenTitle)
                        Text("Your edits are saved for either option.")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .contain)

                    Button { path.append(.digital(photoID)) } label: {
                        choice(title: "Digital Photo", detail: "One JPEG to share or upload", symbol: "photo")
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens a single digital photo ready to share.")
                    .accessibilityIdentifier("digitalChoice")

                    Button { path.append(.sheet) } label: {
                        choice(title: "Print Sheet", detail: "Set paper size and copies", symbol: "printer")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("printChoice")

                    Text("Check the photo by eye before use. The receiving office decides acceptance.")
                        .font(Design.Typography.note)
                        .foregroundStyle(.secondary)
                } else {
                    ContentUnavailableView("This photo was removed", systemImage: "photo")
                }
            }
            .padding()
        }
        .navigationTitle("Choose result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choice(title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
        HStack(alignment: .center, spacing: Design.Spacing.cardContent) {
            Image(systemName: symbol).font(Design.Typography.titleGlyph)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 32, height: Design.Size.minimumTarget)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(title).font(Design.Typography.cardTitle)
                Text(detail).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Design.Radius.card))
        .contentShape(RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

struct DigitalShareView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }
    private var result: DigitalExport? {
        guard model.digitalExport?.photoID == photoID else { return nil }
        return model.digitalExport
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: Design.Spacing.block) {
                if let result, let entry {
                    HStack(spacing: Design.Spacing.row) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Design.Typography.titleGlyph)
                            .foregroundStyle(StatusStyle.pass)
                            .accessibilityHidden(true)
                        Text("Your digital photo is ready.")
                            .font(Design.Typography.screenTitle)
                    }
                    PortraitView(entry: entry, label: "Digital photo ready to share")
                        .frame(maxWidth: 240)
                    Text("JPEG · \(PhotoFormat.spainPrototype.output.width) × \(PhotoFormat.spainPrototype.output.height) pixels")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                    Text("Remove headphones. Check headwear, glasses, eyes and expression before use. The receiving office decides acceptance.")
                        .font(Design.Typography.note)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ShareLink(item: result.jpeg) {
                        Label("Share JPEG", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("shareDigitalJPEG")
                    Button("Done") { path.removeAll() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("digitalDone")
                } else if model.activity == .exporting {
                    ProgressView("Preparing your photo…")
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ContentUnavailableView {
                        Label("Photo not ready", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(model.errorMessage ?? String(localized: "The photo could not be prepared. Try again."))
                    } actions: {
                        Button("Try Again") { model.prepareDigitalExport(for: photoID) }
                            .brandProminentButtonStyle()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Digital Photo")
        .navigationBarTitleDisplayMode(.inline)
        .task { if result == nil, model.activity == nil { model.prepareDigitalExport(for: photoID) } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: result?.id)
    }
}
