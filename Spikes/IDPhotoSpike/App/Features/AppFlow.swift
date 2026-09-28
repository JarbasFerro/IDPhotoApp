import PhotosUI
import SwiftUI

/// Home → preparation → acquisition → Photo Check → output choice → digital result or print sheet.
enum Route: Hashable {
    case check(UUID)
    case outputChoice(UUID)
    case digital(UUID)
    case sheet
    case share
}

private struct PendingAcquisition: Identifiable {
    let id = UUID()
    let source: AcquisitionSource
    let mode: PhotoWorkflow.ImportMode
}

/// Owns navigation and the two acquisition presentations; every screen reads the shared workflow.
struct RootView: View {
    @Bindable var model: PhotoWorkflow
    @State private var path: [Route] = []
    @State private var showCamera = false
    @State private var showPicker = false
    @State private var pendingAcquisition: PendingAcquisition?
    @State private var approvedAcquisition: PendingAcquisition?
    @State private var choosePhotoAfterCamera = false
    @State private var selection: PhotosPickerItem?
    @State private var importMode: PhotoWorkflow.ImportMode = .replace

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(model: model, path: $path, acquire: acquire)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .check(let id):
                        PhotoCheckView(model: model, photoID: id, path: $path, acquire: acquire)
                    case .outputChoice(let id):
                        OutputChoiceView(model: model, photoID: id, path: $path)
                    case .digital(let id):
                        DigitalShareView(model: model, photoID: id, path: $path)
                    case .sheet:
                        SheetView(model: model, path: $path, acquire: acquire)
                    case .share:
                        ShareView(model: model, path: $path)
                    }
                }
        }
        .sheet(item: $pendingAcquisition, onDismiss: startApprovedAcquisition) {
            pending in
            PreparationView(source: pending.source, onContinue: { selectedSource in
                approvedAcquisition = PendingAcquisition(source: selectedSource, mode: pending.mode)
                pendingAcquisition = nil
            })
        }
        .photosPicker(isPresented: $showPicker, selection: $selection, matching: .images, preferredItemEncoding: .current)
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            if choosePhotoAfterCamera { choosePhotoAfterCamera = false; showPicker = true }
        }) {
            CameraView(onCapture: { staged, metrics in
                showCamera = false
                model.lastCameraMetrics = metrics
                model.importPhoto(mode: importMode) { staged }
            }, onChoosePhoto: { choosePhotoAfterCamera = true; showCamera = false })
        }
        .onChange(of: selection) { _, item in
            guard let item else { return }
            model.importPhoto(mode: importMode) { try await item.loadTransferable(type: StagedPhoto.self) }
            selection = nil
        }
        .onChange(of: model.lastInstalled) { _, event in
            guard let event else { return }
            // A retake replaces the current Photo Check; a new person gets their own.
            if case .check = path.last { path[path.count - 1] = .check(event.id) } else { path.append(.check(event.id)) }
        }
        .alert("Unable to complete", isPresented: Binding(get: {
            if case .digital = path.last { return false }
            if case .share = path.last { return false }
            return model.errorMessage != nil
        }, set: { if !$0 { model.errorMessage = nil } })) {
            if model.errorActivity == .importing {
                Button("Choose Another Photo") {
                    model.errorMessage = nil
                    acquire(.library, mode: importMode)
                }
            }
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private func acquire(_ source: AcquisitionSource, mode: PhotoWorkflow.ImportMode) {
        pendingAcquisition = PendingAcquisition(source: source, mode: mode)
    }

    private func startApprovedAcquisition() {
        guard let approvedAcquisition else { return }
        self.approvedAcquisition = nil
        importMode = approvedAcquisition.mode
        switch approvedAcquisition.source {
        case .camera: showCamera = true
        case .library: showPicker = true
        }
    }
}

enum AcquisitionSource { case camera, library }
typealias Acquire = (AcquisitionSource, PhotoWorkflow.ImportMode) -> Void

/// Marketing version and build number from the bundle, e.g. "0.9.0 (52)". The build number is the git
/// commit count set by scripts/bump-version.sh, so a screenshot identifies the exact commit.
enum AppVersion {
    static var display: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "0"
        let build = info["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
}

/// Developer details (camera timings, live-analysis numbers) are off by default and toggled by a long press
/// on the version line, so normal users never see them.
enum DeveloperMode {
    static let key = "developerMode"
}

/// Shared status row: symbol plus text, never colour alone.
struct StatusLabel: View {
    let text: LocalizedStringResource
    let state: CheckState

    var body: some View {
        Label { Text(text) } icon: { Image(systemName: StatusStyle.symbol(for: state)).foregroundStyle(StatusStyle.color(for: state)) }
    }
}
