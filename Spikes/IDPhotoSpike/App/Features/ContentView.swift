import PhotosUI
import SwiftUI

struct ContentView: View {
    @Bindable var model: PhotoWorkflow
    @State private var selection: PhotosPickerItem?
    @State private var showRequirements = false
    @State private var confirmRemove = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let hasPhoto = model.photo != nil
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Spain").font(.headline)
                        Spacer()
                        Text("26 × 32 mm").foregroundStyle(.secondary)
                    }
                    if let photo = model.photo {
                        CropPreview(photo: photo, adjustment: $model.adjustment)
                            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 200 : 320)
                            .frame(maxWidth: .infinity)
                            .disabled(model.activity != nil)
                        adjustmentControls
                    } else {
                        ContentUnavailableView {
                            Label("Choose a portrait", systemImage: "person.crop.rectangle")
                        } description: {
                            Text("Start with a recent, front-facing photo against a plain white background.")
                        }
                        .frame(minHeight: 260)
                    }

                    if let activity = model.activity {
                        HStack {
                            ProgressView()
                            Text(activity == .importing ? LocalizedStringKey("Opening photo…") : LocalizedStringKey("Preparing files…"))
                            Spacer()
                            Button("Cancel", role: .cancel) { model.cancel() }
                        }
                        .accessibilityElement(children: .contain)
                    }

                    if model.photo == nil || model.activity == nil {
                        PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
                            Label(hasPhoto ? LocalizedStringKey("Replace Photo") : LocalizedStringKey("Choose Photo"), systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!model.isInitialized || model.activity != nil)
                        .accessibilityIdentifier("choosePhoto")
                    }

                    if model.photo != nil {
                        Button(action: model.prepareExport) {
                            Label("Prepare Export", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(model.activity != nil)
                        .accessibilityIdentifier("prepareExport")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Manual review needed", systemImage: "eye")
                            .font(.headline)
                        Text("Check your face, lighting, and background. This prototype formats your photo; it does not check official acceptance.")
                            .foregroundStyle(.secondary)
                        Button { showRequirements = true } label: {
                            Text("Photo requirements").frame(minHeight: 44)
                        }
                    }
                    .font(.subheadline)
                    Label("Your photo stays on your iPhone.", systemImage: "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Foto carnet")
            .toolbar {
                if model.photo != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Remove Photo", systemImage: "trash", role: .destructive) { confirmRemove = true }
                            .disabled(model.activity != nil)
                    }
                }
            }
            .confirmationDialog("Remove this photo and its crop?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove Photo", role: .destructive, action: model.removePhoto)
            } message: {
                Text("The original in your photo library is kept.")
            }
            .sheet(isPresented: $showRequirements) { RequirementsView() }
            .sheet(item: $model.exported, onDismiss: model.finishExport) { result in
                ExportView(result: result)
            }
            .alert("Unable to complete", isPresented: Binding(
                get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            .onChange(of: selection) { _, item in
                guard let item else { return }
                model.importPhoto { try await item.loadTransferable(type: StagedPhoto.self) }
                selection = nil
            }
        }
    }

    private var adjustmentControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adjust crop").font(.headline)
                Spacer()
                Button { model.adjustment = CropAdjustment() } label: {
                    Text("Reset").frame(minWidth: 44, minHeight: 44)
                }
            }
            cropSlider("Zoom", value: $model.adjustment.zoom, range: 1...4, step: 0.05)
            cropSlider("Horizontal position", value: $model.adjustment.horizontal, range: 0...1, step: 0.025)
            cropSlider("Vertical position", value: $model.adjustment.vertical, range: 0...1, step: 0.025)
            if model.sourceIsSmall {
                Label("This crop may look soft when printed. Zoom out or choose a higher-resolution photo.",
                      systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
            }
        }
        .disabled(model.activity != nil)
    }

    private func cropSlider(_ title: LocalizedStringKey, value: Binding<Double>,
                            range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            Slider(value: value, in: range, step: step) { Text(title) }
                .accessibilityValue(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
        }
    }
}

private struct RequirementsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Before you choose a photo") {
                    Label("Recent color photo, facing forward", systemImage: "person.crop.rectangle")
                    Label("Plain, uniform white background", systemImage: "rectangle")
                    Label("Face and eyes clearly visible", systemImage: "eye")
                }
                Section("Check the official guidance") {
                    Text("The DNI guidance includes medical and religious exceptions for head coverings and glasses. Review the source for your situation.")
                    Link("Spanish Ministry of the Interior", destination: URL(string:
                        "https://www.interior.gob.es/opencms/es/servicios-al-ciudadano/tramites-y-gestiones/dni/documentacion-necesaria-para-su-tramitacion/")!)
                    Text("Source reviewed September 15, 2026. Other document types may have different requirements.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("What this prototype does") {
                    Text("Crop and export only. Your original background is preserved. Face analysis and background correction are not included yet.")
                }
            }
            .navigationTitle("Photo requirements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct ExportView: View {
    let result: PhotoExport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Files prepared", systemImage: "checkmark.circle")
                        .font(.headline)
                    Text("File dimensions were verified. Review your photo before using it for a document.")
                }
                Section("Digital photo") {
                    Text("JPEG · 520 × 640 pixels")
                    Text("Image resolution is an app setting, not an official upload requirement.")
                        .font(.footnote).foregroundStyle(.secondary)
                    ShareLink(item: result.jpeg) { Label("Share JPEG", systemImage: "square.and.arrow.up") }
                        .accessibilityIdentifier("shareJPEG")
                }
                Section("Print sheet") {
                    Text("A6 · 6 copies · 26 × 32 mm each")
                    Text("Print at Actual Size / 100%. Disable Fit to Page and measure a copy before use. Physical print accuracy still needs testing.")
                        .font(.subheadline)
                    ShareLink(item: result.pdf) { Label("Share PDF", systemImage: "square.and.arrow.up") }
                        .accessibilityIdentifier("sharePDF")
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
