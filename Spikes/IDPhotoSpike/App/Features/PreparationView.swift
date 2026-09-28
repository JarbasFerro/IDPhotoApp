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
                    Label("Face forward with your eyes open", systemImage: "person.crop.rectangle")
                    Label("Remove headphones; check headwear and glasses", systemImage: "headphones")
                    Label("Use even light and a plain white background", systemImage: "sun.max")
                } header: {
                    Text("Spain · DNI photo")
                } footer: {
                    Text("Leave room around your head and shoulders. You can adjust the framing later.")
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
