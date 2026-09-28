import SwiftUI

/// A short, sourced reminder before either acquisition path. No permission is requested here.
struct PreparationView: View {
    let source: AcquisitionSource
    let onContinue: (AcquisitionSource) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Face the camera with your eyes open", systemImage: "person.crop.rectangle")
                    Label("Use even light and a plain, light background", systemImage: "sun.max")
                    Label("Keep your full head and shoulders in the photo", systemImage: "viewfinder")
                } header: {
                    Text("Spain · DNI photo")
                } footer: {
                    Text("Calipic frames the result. Check expression, glasses and any headwear requirements by eye.")
                }
                Section {
                    NavigationLink("Full requirements") {
                        RequirementsContent()
                            .navigationTitle("Photo requirements")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    Button {
                        onContinue(source == .camera ? .library : .camera)
                    } label: {
                        Label(source == .camera ? "Choose Photo Instead" : "Take Photo Instead",
                              systemImage: source == .camera ? "photo.on.rectangle" : "camera")
                    }
                }
            }
            .navigationTitle("Before your photo")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button { onContinue(source) } label: {
                    Label(source == .camera ? "Open Camera" : "Choose Photo",
                          systemImage: source == .camera ? "camera" : "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .brandProminentButtonStyle()
                .controlSize(.large)
                .padding()
                .background(.bar)
                .accessibilityIdentifier("preparationContinue")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
