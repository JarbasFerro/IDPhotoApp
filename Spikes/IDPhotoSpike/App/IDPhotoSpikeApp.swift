import SwiftUI

@main
struct IDPhotoSpikeApp: App {
    private let pipeline: PhotoPipeline
    @State private var model: PhotoWorkflow
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let pipeline = PhotoPipeline()
        self.pipeline = pipeline
        _model = State(initialValue: PhotoWorkflow(pipeline: pipeline))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task {
                    guard !model.isInitialized else { return }
                    do {
                        try await pipeline.prepareSession()
                        model.setInitialized()
                        #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("--uitesting-fixture") {
                            model.importPhoto { try await SyntheticFixture.staged() }
                        }
                        #endif
                    } catch {
                        model.errorMessage = String(localized: "Private photo storage could not be prepared. Reopen the app to try again.")
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { model.cancel() }
                }
        }
    }
}
