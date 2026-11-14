import SwiftUI

/// A stable portrait on the mat, from the credit decision through the verified file ready to share.
struct DigitalShareView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]
    @State private var showCredits = false
    @State private var showAllSet = false
    @State private var unlockTick = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var coaching: Bool { model.tutorial.isActive }
    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }
    private var locked: Bool { entry?.isUnlocked == false }
    private var result: DigitalExport? { model.digitalExport?.photoID == photoID ? model.digitalExport : nil }

    var body: some View {
        Group {
            if let entry {
                JourneyScreen(minimumObjectHeightFraction: 0.45) { size in
                    let format = model.renderTarget.digital.format(base: model.renderTarget.format)
                    let aspect = format.aspectRatio
                    let height = max(0, min(size.height, size.width / aspect))
                    PortraitView(entry: digitalPreview(entry), format: format,
                                 label: result == nil ? "Prepared photo" : "Digital photo ready to share")
                        .frame(width: height * aspect, height: height)
                        .paperDimmedInDark().paperShadow()
                        .unlockCelebration(trigger: unlockTick)
                } tray: {
                    VStack(alignment: .leading, spacing: Design.Spacing.tray) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                if result != nil { StatusMark(.pass).accessibilityHidden(true) }
                                else if !locked, model.activity == .exporting { StatusMark.progress.accessibilityHidden(true) }
                                title.font(Design.Typography.trayTitle)
                            }
                            if result != nil {
                                Text("Sized for online forms").font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                            }
                        }
                        if locked { UnlockExplanation(photos: 1, balance: model.credits.balance) }
                        else if model.activity != .exporting, result == nil {
                            Text(model.errorMessage ?? String(localized: "The photo could not be prepared. Try again.")).font(.body)
                        }
                    }
                    .animation(Design.Motion.rearrange.resolved(reduceMotion: reduceMotion), value: locked)
                } actions: {
                    actions
                }
            } else {
                ContentUnavailableView("This photo was removed", systemImage: "photo")
            }
        }
        .navigationTitle("Digital Photo")
        .toolbar { ToolbarItem(placement: .principal) { StepMarker(current: .output, output: .digital) } }
        .guideOverlay(model.tutorial, current: coaching ? (locked ? .unlock : result != nil ? .share : nil) : nil, output: .digital)
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .sheet(isPresented: $showAllSet, onDismiss: { path.removeAll() }) {
            TutorialDoneView(output: .digital, route: nil, creditsLeft: model.credits.balance, done: { showAllSet = false })
        }
        .task(id: photoID) {
            if !locked, result == nil, model.activity == nil { model.prepareDigitalExport(for: photoID) }
        }
        .onChange(of: locked) { old, new in if old, !new { unlockTick += 1 } }
        .sensoryFeedback(.success, trigger: unlockTick)
        .onDisappear { model.finishExport() }
    }

    /// Use the same domain recipe as export, including a document's looser online framing.
    private func digitalPreview(_ entry: PhotoEntry) -> PhotoEntry {
        var preview = entry
        preview.adjustment = model.renderTarget.digital.adjustment(for: entry.adjustment)
        return preview
    }

    private var title: Text {
        if locked { Text("Unlock this photo") }
        else if result != nil { Text("Your digital photo is ready") }
        else if model.activity == .exporting { Text("Preparing your photo…") }
        else { Text("Photo not ready") }
    }

    private var actions: some View {
        TrayActions {
            if locked {
                if model.credits.canAfford(1) {
                    Button {
                        if model.unlock([photoID]) { model.prepareDigitalExport(for: photoID) }
                    } label: { Text("Unlock · \(CreditsPresentation.count(1))").frame(maxWidth: .infinity) }
                        .guideTarget(.unlock, current: coaching ? .unlock : nil).accessibilityIdentifier("unlockDigital")
                } else {
                    Button { showCredits = true } label: { Text("Get Credits").frame(maxWidth: .infinity) }
                        .accessibilityIdentifier("getCredits")
                }
            } else if let result {
                Button {
                    ShareController.present([result.jpeg]) { shared in
                        if shared, coaching { model.tutorial.complete(); showAllSet = true }
                    }
                } label: { Label("Share Photo", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }
                    .guideTarget(.share, current: coaching ? .share : nil).accessibilityIdentifier("shareDigitalJPEG")
            } else if model.activity == .exporting {
                Button {} label: { Text("Preparing your photo…").frame(maxWidth: .infinity) }.disabled(true)
            } else {
                Button { model.prepareDigitalExport(for: photoID) } label: { Text("Try Again").frame(maxWidth: .infinity) }
            }
        } secondary: {
            Button(locked ? "Keep Editing" : "Done") { if locked { path.removeLast() } else { path.removeAll() } }
                .accessibilityIdentifier(locked ? "keepEditing" : "digitalDone")
        }
    }
}
