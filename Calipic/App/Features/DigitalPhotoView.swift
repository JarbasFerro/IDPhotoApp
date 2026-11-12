import SwiftUI

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
                    // The photo lies on the mat, running up behind the navigation bar; the words sit below it.
                    PortraitView(entry: entry, format: model.renderTarget.format, label: "Digital photo ready to share")
                        .frame(maxWidth: 240)
                        .paperDimmedInDark()
                        .paperShadow()
                        .padding(.vertical, Design.Spacing.group)
                        .frame(maxWidth: .infinity)
                        .onMat(bleed: 16)
                    HStack(spacing: Design.Spacing.row) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Design.Typography.titleGlyph)
                            .foregroundStyle(StatusStyle.pass)
                            .accessibilityHidden(true)
                        Text("Your digital photo is ready.")
                            .font(Design.Typography.screenTitle)
                    }
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
        .toolbar { ToolbarItem(placement: .principal) { StepMarker(current: .output, output: .digital) } }
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .task { if result == nil, model.activity == nil { model.prepareDigitalExport(for: photoID) } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: result?.id)
    }
}
