import PhotosUI
import SwiftUI

/// Home → preparation → acquisition → Photo Check → output buttons on Photo Check → digital result or print sheet.
enum Route: Hashable {
    case check(UUID)
    case digital(UUID)
    case sheet
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
    /// The camera's photo is being prepared; the camera closes once Photo Check is in place behind it.
    @State private var awaitingCameraPhoto = false
    /// The white veil of the hand-over (F11, M1): full on the camera, then fading over Photo Check.
    @State private var cameraVeil = false
    @State private var arrivalVeil = false
    /// The photo whose Photo Check opened straight from the camera; it lands sooner (M2).
    @State private var cameraArrival: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: PhotosPickerItem?
    @State private var importMode: PhotoWorkflow.ImportMode = .replace
    /// Comma-separated ids of documents whose "Before your photo" sheet was shown (D-1: in full once per document).
    @AppStorage("preflightSeenDocuments") private var preflightSeen = ""

    /// M1's end (F11 step 3): the camera turns white, closes without sliding, and the white fades over Photo Check.
    /// Under Reduce Motion the camera simply closes.
    private func handOverFromCamera() async {
        var instant = Transaction()
        instant.disablesAnimations = true
        guard !reduceMotion else {
            withTransaction(instant) { showCamera = false }
            return
        }
        cameraVeil = true
        try? await Task.sleep(for: .milliseconds(150))
        withTransaction(instant) {
            arrivalVeil = true
            showCamera = false
        }
        withAnimation(.easeOut(duration: 0.35)) { arrivalVeil = false }
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(model: model, path: $path, acquire: acquire, promptForDocument: promptForDocument)
                .navigationDestination(for: Route.self) { route in
                    Group {
                        switch route {
                        case .check(let id):
                            PhotoCheckView(model: model, photoID: id, path: $path, acquire: acquire,
                                           arrivedFromCamera: cameraArrival == id)
                        case .digital(let id):
                            DigitalShareView(model: model, photoID: id, path: $path)
                        case .sheet:
                            PrintView(model: model, path: $path, acquire: acquire)
                        }
                    }
                    .zoomDestination(route, at: path.lastIndex(of: route) ?? 0, in: zoom)
                }
        }
        .environment(\.zoomNamespace, zoom)
        .overlay {
            Color.white.ignoresSafeArea().opacity(arrivalVeil ? 0.55 : 0).allowsHitTesting(false)
        }
        #if DEBUG
        .onChange(of: path) { _, routes in
            if routes.last == .sheet, ProcessInfo.processInfo.arguments.contains("--uitesting-print-import-error") {
                model.importPhoto(mode: .add) { throw PhotoError.unreadable }
            }
        }
        #endif
        // A new install begins with the welcome page and the guided first photo (ADR-052).
        .fullScreenCover(isPresented: Binding(get: { model.tutorial.needsWelcome }, set: { _ in })) {
            TutorialWelcomeView(credits: model.credits.balance) { model.tutorial.welcomed() }
        }
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
            awaitingCameraPhoto = false
            cameraVeil = false
            model.discardAhead()
            if choosePhotoAfterCamera { choosePhotoAfterCamera = false; showPicker = true }
        }) {
            CameraView(onCapture: { staged, metrics in
                // Stay on the camera until the photo is installed (onChange of lastInstalled below), so closing it
                // reveals Photo Check rather than Home (founder, 0.20 review).
                awaitingCameraPhoto = true
                model.lastCameraMetrics = metrics
                model.useCapture(staged, mode: importMode)
            }, onChoosePhoto: { choosePhotoAfterCamera = true; showCamera = false },
               onReviewChange: { staged in
                // Analyse the still at once, so Photo Check is ready when the camera closes (P2).
                if let staged { model.prepareAhead(staged) } else { model.discardAhead() }
            }, onCancelCapture: {
                awaitingCameraPhoto = false
                model.cancelCapture()
            }, veil: cameraVeil)
            .onAppear { model.warmUp() }
        }
        .onChange(of: selection) { _, item in
            guard let item else { return }
            model.importPhoto(mode: importMode) { try await item.loadTransferable(type: StagedPhoto.self) }
            selection = nil
        }
        .onChange(of: model.lastInstalled) { _, event in
            guard let event else { return }
            let fromCamera = awaitingCameraPhoto
            if fromCamera { cameraArrival = event.id }
            // Behind the camera the change happens without animation.
            var transaction = Transaction()
            transaction.disablesAnimations = fromCamera
            withTransaction(transaction) {
                // A retake replaces the current Photo Check; a new person gets their own.
                if case .check = path.last { path[path.count - 1] = .check(event.id) } else { path.append(.check(event.id)) }
            }
            if fromCamera {
                awaitingCameraPhoto = false
                Task { await handOverFromCamera() }
            }
        }
        .task(id: awaitingCameraPhoto) {
            // Safety net: never leave the camera waiting on a photo that will not arrive.
            guard awaitingCameraPhoto else { return }
            try? await Task.sleep(for: .seconds(15))
            if !Task.isCancelled, awaitingCameraPhoto { awaitingCameraPhoto = false; showCamera = false }
        }
        .onChange(of: model.errorMessage) { _, message in
            // Preparing the camera's photo failed: close the camera so the alert shows.
            if message != nil, awaitingCameraPhoto { awaitingCameraPhoto = false; showCamera = false }
        }
        .alert("Unable to complete", isPresented: Binding(get: {
            if case .digital = path.last { return false }
            if case .sheet = path.last { return false }
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
