import PhotosUI
import SwiftUI

/// The four-step task: Home → (Camera or picker) → Photo Check → Your Sheet → Share.
enum Route: Hashable {
    case check(UUID)
    case sheet
    case share
}

/// Owns navigation and the two acquisition presentations; every screen reads the shared workflow.
struct RootView: View {
    @Bindable var model: PhotoWorkflow
    @State private var path: [Route] = []
    @State private var showCamera = false
    @State private var showPicker = false
    @State private var selection: PhotosPickerItem?
    @State private var importMode: PhotoWorkflow.ImportMode = .replace

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(model: model, path: $path, acquire: acquire)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .check(let id):
                        PhotoCheckView(model: model, photoID: id, path: $path, acquire: acquire)
                    case .sheet:
                        SheetView(model: model, path: $path, acquire: acquire)
                    case .share:
                        ShareView(model: model, path: $path)
                    }
                }
        }
        .photosPicker(isPresented: $showPicker, selection: $selection, matching: .images, preferredItemEncoding: .current)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { staged, metrics in
                showCamera = false
                model.lastCameraMetrics = metrics
                model.importPhoto(mode: importMode) { staged }
            }
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
        .alert("Unable to complete", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    private func acquire(_ source: AcquisitionSource, mode: PhotoWorkflow.ImportMode) {
        importMode = mode
        switch source {
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
        Label { Text(text) } icon: { Image(systemName: AlignmentPresentation.symbol(for: state)).foregroundStyle(tint) }
    }

    private var tint: Color {
        switch state {
        case .pass: .green
        case .warn: .orange
        case .fail: .red
        case .manualCheck: .secondary
        }
    }
}
