import SwiftUI

/// Direct manipulation on the portrait plus four controls; exact values live under Details.
struct AdjustSheet: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showDetails = false

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let entry {
                    VStack(alignment: .leading, spacing: 20) {
                        CropPreview(photo: entry.photo, image: model.showsOriginal ? nil : entry.backgroundPreview, adjustment: $model.adjustment)
                            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 220 : 320)
                            .frame(maxWidth: .infinity)
                        Text("Drag to move, pinch to zoom.")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                        controls(entry)
                        DisclosureGroup(isExpanded: $showDetails) {
                            details
                        } label: {
                            Text("Details").font(.headline)
                        }
                        .accessibilityIdentifier("details")
                    }
                    .padding()
                }
            }
            .navigationTitle("Adjust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("adjustDone") }
            }
            .onAppear { model.selectedID = photoID }
            .onDisappear { model.showsOriginal = false }
        }
        .presentationDetents([.large])
    }

    private func controls(_ entry: PhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button { model.resetCrop() } label: {
                    Label(model.analysis?.solution != nil ? LocalizedStringKey("Auto") : LocalizedStringKey("Reset"), systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("resetCrop")
                Toggle(isOn: $model.showsOriginal) { Label("Compare", systemImage: "rectangle.on.rectangle") .frame(maxWidth: .infinity) }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("showOriginal")
            }
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 8) {
                Text("Background").font(.subheadline.weight(.medium))
                Picker("Background", selection: backgroundSelection) {
                    Text("Original").tag(false)
                    Text("White").tag(true)
                }
                .pickerStyle(.segmented)
                .disabled(!model.canReplaceBackground)
                .accessibilityIdentifier("backgroundPicker")
                if let segmentation = entry.segmentation, segmentation.quality.state != .pass {
                    StatusLabel(text: BackgroundPresentation.maskMessage(segmentation.quality), state: segmentation.quality.state)
                        .font(.footnote)
                } else if entry.isSegmenting {
                    HStack(spacing: 8) { ProgressView(); Text("Separating the background…").font(.footnote).foregroundStyle(.secondary) }
                } else if !model.canReplaceBackground {
                    Text("The background could not be separated in this photo, so the original is kept.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if model.policy.alteration != .forbidden {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(get: { model.adjustment.tone.isEnabled },
                                         set: { model.adjustment.tone.isEnabled = $0; model.refreshBackgroundPreview() })) {
                        Text("Light and colour").font(.subheadline.weight(.medium))
                    }
                    .disabled(!model.canAdjustTone)
                    .accessibilityIdentifier("toneToggle")
                    Text("Evens out exposure and removes colour tints. Nothing on your face is retouched.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let assessment = entry.toneAssessment {
                        StatusLabel(text: TonePresentation.message(for: assessment), state: assessment.state).font(.footnote)
                    }
                }
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            slider("Zoom", value: $model.adjustment.zoom, range: 1...4, step: 0.05)
            slider("Left and right", value: $model.adjustment.horizontal, range: 0...1, step: 0.025)
            slider("Up and down", value: $model.adjustment.vertical, range: 0...1, step: 0.025)
            slider("Straighten", value: $model.adjustment.rotationDegrees, range: CropAdjustment.rotationRange, step: 0.5)
            if case .color = model.adjustment.background {
                slider("Edge softness", value: $model.adjustment.edgeSoftness, range: 0...1, step: 0.1) { model.refreshBackgroundPreview() }
            }
            if model.adjustment.tone.isEnabled {
                slider("Correction strength", value: $model.adjustment.tone.strength, range: 0...1, step: 0.1) { model.refreshBackgroundPreview() }
            }
            if model.sourceIsSmall {
                StatusLabel(text: "This crop may look soft when printed. Zoom out or choose a higher-resolution photo.", state: .warn)
                    .font(.footnote)
            }
        }
        .padding(.top, 8)
    }

    private func slider(_ title: LocalizedStringKey, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                        onEnd: @escaping () -> Void = {}) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            Slider(value: value, in: range, step: step, onEditingChanged: { editing in if !editing { onEnd() } }) { Text(title) }
                .accessibilityValue(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
        }
    }

    private var backgroundSelection: Binding<Bool> {
        Binding(get: { if case .color = model.adjustment.background { return true } else { return false } },
                set: { white in
                    model.adjustment.background = white ? .color(.white) : .original
                    model.refreshBackgroundPreview()
                })
    }
}
