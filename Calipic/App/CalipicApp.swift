import SwiftUI

@main
struct CalipicApp: App {
    private let pipeline: PhotoPipeline
    @State private var model: PhotoWorkflow
    @Environment(\.scenePhase) private var scenePhase
    /// UI tests pass "--uitesting-fresh": Spain DNI, nothing read from or written to saved settings, no first-launch question.
    private let isolated: Bool
    private let needsDocumentPrompt: Bool

    init() {
        let pipeline = PhotoPipeline()
        self.pipeline = pipeline
        isolated = ProcessInfo.processInfo.arguments.contains("--uitesting-fresh")
        let start = isolated
            ? DocumentStore.Start(choice: .initial, needsPrompt: false)
            : DocumentStore.start(stored: UserDefaults.standard.string(forKey: DocumentStore.key),
                                  regionCode: Locale.current.region?.identifier, catalog: .bundled)
        needsDocumentPrompt = start.needsPrompt
        // UI tests get an in-memory balance of one credit; real launches keep the balance on the device.
        let credits = CreditStore(defaults: isolated ? nil : .standard)
        _model = State(initialValue: PhotoWorkflow(pipeline: pipeline, document: start.choice, credits: credits))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--camera-review-fixture") {
                    CameraView(onCapture: { _, _ in }, onChoosePhoto: {})
                } else {
                    RootView(model: model, promptForDocument: needsDocumentPrompt)
                }
                #else
                RootView(model: model, promptForDocument: needsDocumentPrompt)
                #endif
            }
                // Teal (BD-033).
                .tint(Brand.accent)
                .task {
                    guard !model.isInitialized else { return }
                    do {
                        try await pipeline.prepareSession()
                        model.setInitialized()
                        #if DEBUG
                        // "--uitesting-fixture" loads one generated photo; "--uitesting-fixture-2" loads two people.
                        // "--uitesting-custom-size" starts with a 30 × 40 mm custom size (ADR-018 controls).
                        let arguments = ProcessInfo.processInfo.arguments
                        if arguments.contains("--uitesting-custom-size") { model.setDocument(.custom(widthMM: 30, heightMM: 40)) }
                        model.debugSyntheticFace = arguments.contains("--uitesting-measured")
                        let fixtures = arguments.contains("--uitesting-fixture-2") ? 2 : arguments.contains("--uitesting-fixture") ? 1 : 0
                        for index in 0..<fixtures {
                            let palette: [CGColor] = index == 0 ? SyntheticFixture.defaultPalette
                                : Array(repeating: CGColor(red: 1, green: 0, blue: 1, alpha: 1), count: 4)
                            // The first person is the local portrait when one exists (never in git); otherwise colour blocks.
                            if index == 0, let portrait = LocalPortrait.url {
                                model.debugLocalFace = LocalPortrait.face
                                model.importPhoto(mode: .add) { try await StagedPhoto.stage(portrait) }
                            } else {
                                model.importPhoto(mode: .add) { try await SyntheticFixture.staged(palette: palette) }
                            }
                            while model.activity == .importing { try? await Task.sleep(for: .milliseconds(20)) }
                        }
                        #endif
                    } catch {
                        model.errorMessage = String(localized: "Private photo storage could not be prepared. Reopen the app to try again.")
                    }
                }
                .onChange(of: model.document) { _, document in
                    if !isolated { UserDefaults.standard.set(DocumentStore.encode(document), forKey: DocumentStore.key) }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { model.cancel() }
                }
        }
    }
}
