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
                    PortraitView(entry: entry, format: model.renderTarget.format, label: "Prepared photo")
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
                        choice(title: "Digital Photo", detail: "For online forms", symbol: "photo")
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens a single digital photo ready to share.")
                    .accessibilityIdentifier("digitalChoice")

                    if model.document.supportsPrint {
                        Button { path.append(.sheet) } label: {
                            choice(title: "Print Sheet", detail: "Set paper size and copies", symbol: "printer")
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("printChoice")
                    }

                } else {
                    ContentUnavailableView("This photo was removed", systemImage: "photo")
                }
            }
            .padding()
        }
        .background(Design.Surface.screen)
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
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.card))
        .contentShape(RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

struct DigitalShareView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]

    @State private var showCredits = false

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
                    PortraitView(entry: entry, format: model.renderTarget.format, label: "Digital photo ready to share")
                        .frame(maxWidth: 240)
                    Text("Sized for online forms")
                        .font(Design.Typography.cardDetail)
                        .foregroundStyle(.secondary)
                    ShareLink(item: result.jpeg) {
                        Label("Share Photo", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("shareDigitalJPEG")
                    Button { path.removeAll() } label: { Text("Done").frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityIdentifier("digitalDone")
                } else if let entry, !entry.isUnlocked {
                    // Nothing is made for a locked photo: unlock in place, with the cost in credits (design 5d).
                    PortraitView(entry: entry, format: model.renderTarget.format, label: "Prepared photo")
                        .frame(maxWidth: 200)
                    UnlockCard(photos: 1, balance: model.credits.balance)
                    if model.credits.canAfford(1) {
                        Button {
                            if model.unlock([photoID]) { model.prepareDigitalExport(for: photoID) }
                        } label: { Text("Unlock and Save").frame(maxWidth: .infinity) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("unlockDigital")
                    } else {
                        Button { showCredits = true } label: { Text("Get Credits").frame(maxWidth: .infinity) }
                            .brandProminentButtonStyle()
                            .controlSize(.large)
                            .accessibilityIdentifier("getCredits")
                    }
                    Button("Keep Editing") { path.removeLast() }
                        .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
                        .accessibilityIdentifier("keepEditing")
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
        .background(Design.Surface.screen)
        .navigationTitle("Digital Photo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .task { if result == nil, model.activity == nil { model.prepareDigitalExport(for: photoID) } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: result?.id)
    }
}
