import PhotosUI
import SwiftUI

/// Home → preparation → acquisition → Photo Check → output buttons on Photo Check → digital result or print sheet.
enum Route: Hashable {
    case check(UUID)
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
    var promptForDocument = false
    @State private var path: [Route] = []
    @Namespace private var zoom
    @State private var showCamera = false
    @State private var showPicker = false
    @State private var pendingAcquisition: PendingAcquisition?
    @State private var approvedAcquisition: PendingAcquisition?
    @State private var choosePhotoAfterCamera = false
    @State private var selection: PhotosPickerItem?
    @State private var importMode: PhotoWorkflow.ImportMode = .replace
    /// Comma-separated ids of documents whose "Before your photo" sheet was shown (D-1: in full once per document).
    @AppStorage("preflightSeenDocuments") private var preflightSeen = ""

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(model: model, path: $path, acquire: acquire, promptForDocument: promptForDocument)
                .navigationDestination(for: Route.self) { route in
                    Group {
                        switch route {
                        case .check(let id):
                            PhotoCheckView(model: model, photoID: id, path: $path, acquire: acquire)
                        case .digital(let id):
                            DigitalShareView(model: model, photoID: id, path: $path)
                        case .sheet:
                            SheetView(model: model, path: $path, acquire: acquire)
                        case .share:
                            PrintView(model: model, path: $path)
                        }
                    }
                    .zoomDestination(route, at: path.firstIndex(of: route) ?? 0, in: zoom)
                }
        }
        .environment(\.zoomNamespace, zoom)
        .sheet(item: $pendingAcquisition, onDismiss: startApprovedAcquisition) {
            pending in
            PreparationView(source: pending.source, document: model.document, onContinue: { selectedSource in
                markPreflightSeen()
                approvedAcquisition = PendingAcquisition(source: selectedSource, mode: pending.mode)
                pendingAcquisition = nil
            })
        }
        .photosPicker(isPresented: $showPicker, selection: $selection, matching: .images, preferredItemEncoding: .current)
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            // A still prepared during its review but never used (Cancel) is thrown away.
            model.discardAhead()
            if choosePhotoAfterCamera { choosePhotoAfterCamera = false; showPicker = true }
        }) {
            CameraView(onCapture: { staged, metrics in
                showCamera = false
                model.lastCameraMetrics = metrics
                model.useCapture(staged, mode: importMode)
            }, onChoosePhoto: { choosePhotoAfterCamera = true; showCamera = false },
               onReviewChange: { staged in
                // Analyse the still while the person looks at it, so Photo Check is ready on Use Photo (P2).
                if let staged { model.prepareAhead(staged) } else { model.discardAhead() }
            })
            .onAppear { model.warmUp() }
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
        if preflightWasSeen {
            approvedAcquisition = PendingAcquisition(source: source, mode: mode)
            startApprovedAcquisition()
        } else {
            pendingAcquisition = PendingAcquisition(source: source, mode: mode)
        }
    }

    /// UI tests ("--uitesting-fresh") never read or write the stored value: the preflight always shows.
    private var persistsPreflight: Bool { !ProcessInfo.processInfo.arguments.contains("--uitesting-fresh") }
    /// Custom sizes count as one document.
    private var preflightID: String { model.document.isCustom ? "custom" : model.document.id }
    private var preflightWasSeen: Bool {
        persistsPreflight && preflightSeen.split(separator: ",").contains { $0 == preflightID }
    }

    private func markPreflightSeen() {
        guard persistsPreflight, !preflightWasSeen else { return }
        preflightSeen = preflightSeen.isEmpty ? preflightID : preflightSeen + "," + preflightID
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
