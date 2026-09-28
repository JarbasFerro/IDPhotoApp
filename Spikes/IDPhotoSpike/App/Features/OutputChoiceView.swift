import SwiftUI

/// One decision after the photo check: a single digital file or a composed print sheet.
struct OutputChoiceView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.section) {
                if let entry {
                    HStack(alignment: .top, spacing: Design.Spacing.block) {
                        PortraitView(entry: entry, label: "Prepared photo")
                            .frame(width: 92)
                        VStack(alignment: .leading, spacing: Design.Spacing.text) {
                            Text("Choose your result")
                                .font(Design.Typography.screenTitle)
                            Text("Your framing and adjustments are saved for both choices.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .contain)

                    Button { path.append(.digital(photoID)) } label: {
                        choice(title: "Digital Photo", detail: "One JPEG for online forms, ready to share.", symbol: "photo")
                    }
                    .brandProminentButtonStyle()
                    .accessibilityIdentifier("digitalChoice")

                    Button { path.append(.sheet) } label: {
                        choice(title: "Print Sheet", detail: "Set paper and copies for one or more people.", symbol: "printer")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("printChoice")

                    Text("Review expression, eyes and glasses by eye before using the photo. The receiving office decides acceptance.")
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
                .frame(width: Design.Size.minimumTarget, height: Design.Size.minimumTarget)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(title).font(Design.Typography.cardTitle)
                Text(detail).font(Design.Typography.cardDetail)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Design.Spacing.control)
    }
}

struct DigitalShareView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrated = false

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }
    private var result: DigitalExport? {
        guard model.digitalExport?.photoID == photoID else { return nil }
        return model.digitalExport
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: Design.Spacing.block) {
                if let result, let entry {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Design.Size.completionSeal))
                        .foregroundStyle(StatusStyle.pass)
                        .symbolEffect(.bounce, options: .nonRepeating, isActive: celebrated && !reduceMotion)
                        .accessibilityHidden(true)
                    Text("Your digital photo is ready.")
                        .font(Design.Typography.screenTitle)
                    PortraitView(entry: entry, label: "Digital photo ready to share")
                        .frame(maxWidth: 240)
                    Text("JPEG · \(PhotoFormat.spainPrototype.output.width) × \(PhotoFormat.spainPrototype.output.height) pixels")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                    Text("Check expression, eyes and glasses by eye. Calipic does not decide whether an office accepts the photo.")
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
        .onChange(of: result?.id) { _, new in if new != nil { celebrated = true } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: result?.id)
    }
}
