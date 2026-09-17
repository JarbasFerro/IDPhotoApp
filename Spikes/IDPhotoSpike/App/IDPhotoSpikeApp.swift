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
            RootView(model: model)
                // Teal (BD-033); `-brandCandidate` in Debug builds still swaps in a test system for comparisons.
                .tint(BrandCandidate.current?.color ?? Brand.accent)
                .task {
                    guard !model.isInitialized else { return }
                    do {
                        try await pipeline.prepareSession()
                        model.setInitialized()
                        #if DEBUG
                        // "--uitesting-fixture" loads one generated photo; "--uitesting-fixture-2" loads two people.
                        let arguments = ProcessInfo.processInfo.arguments
                        let fixtures = arguments.contains("--uitesting-fixture-2") ? 2 : arguments.contains("--uitesting-fixture") ? 1 : 0
                        for index in 0..<fixtures {
                            let palette: [CGColor] = index == 0 ? SyntheticFixture.defaultPalette
                                : Array(repeating: CGColor(red: 1, green: 0, blue: 1, alpha: 1), count: 4)
                            model.importPhoto(mode: .add) { try await SyntheticFixture.staged(palette: palette) }
                            while model.activity == .importing { try? await Task.sleep(for: .milliseconds(20)) }
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
