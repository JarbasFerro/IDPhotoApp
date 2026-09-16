import PhotosUI
import SwiftUI

struct ContentView: View {
    @Bindable var model: PhotoWorkflow
    @State private var selection: PhotosPickerItem?
    @State private var showRequirements = false
    @State private var showComposer = false
    @State private var showCamera = false
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
                        CropPreview(photo: photo, image: model.showsOriginal ? nil : model.backgroundPreview, adjustment: $model.adjustment)
                            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 200 : 320)
                            .frame(maxWidth: .infinity)
                            .disabled(model.activity != nil)
                        alignmentStatus
                        backgroundControls
                        toneControls
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
                        acquisitionButtons(hasPhoto: hasPhoto)
                    }

                    if model.photo != nil {
                        printSheetSummary
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
                    #if DEBUG
                    if let metrics = model.lastCameraMetrics {
                        Text("Camera: start \(metrics.startupMilliseconds ?? 0) ms · capture \(metrics.captureMilliseconds ?? 0) ms")
                            .font(.footnote.monospacedDigit()).foregroundStyle(.tertiary)
                            .accessibilityIdentifier("cameraMetrics")
                    }
                    #endif
                    Text(AppVersion.display)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .accessibilityLabel(Text("Version \(AppVersion.display)"))
                        .accessibilityIdentifier("appVersion")
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
            .sheet(isPresented: $showComposer) { PrintComposerView(model: model) }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { staged, metrics in
                    showCamera = false
                    model.lastCameraMetrics = metrics
                    model.importPhoto { staged }
                }
            }
            .sheet(item: $model.exported, onDismiss: model.finishExport) { result in
                ExportView(result: result, paperName: PaperNames.name(for: model.printJob.paper))
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

    @ViewBuilder private func acquisitionButtons(hasPhoto: Bool) -> some View {
        let disabled = !model.isInitialized || model.activity != nil
        if hasPhoto {
            Button { showCamera = true } label: {
                Label("Retake Photo", systemImage: "camera").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(disabled)
            .accessibilityIdentifier("takePhoto")
        } else {
            Button { showCamera = true } label: {
                Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(disabled)
            .accessibilityIdentifier("takePhoto")
        }
        PhotosPicker(selection: $selection, matching: .images, preferredItemEncoding: .current) {
            Label(hasPhoto ? LocalizedStringKey("Replace Photo") : LocalizedStringKey("Choose Photo"), systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(disabled)
        .accessibilityIdentifier("choosePhoto")
    }

    private var printSheetSummary: some View {
        let layout = model.layout
        return Button { showComposer = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Print sheet", systemImage: "printer").font(.headline)
                    Text("\(PaperNames.name(for: model.printJob.paper)) · \(layout.placedCount) copies · \(layout.pages.count) page(s)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(model.activity != nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Choose paper, copies, and cutting options.")
        .accessibilityIdentifier("printSheet")
    }

    @ViewBuilder private var alignmentStatus: some View {
        if model.isAnalyzing {
            HStack(spacing: 8) {
                ProgressView()
                Text("Finding face…").font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        } else if model.analysisUnavailable {
            Label("Automatic alignment is not available on this device. Adjust the crop by hand.", systemImage: "info.circle")
                .font(.subheadline).foregroundStyle(.secondary)
                .accessibilityIdentifier("alignmentStatus")
        } else if let analysis = model.analysis {
            VStack(alignment: .leading, spacing: 8) {
                if let solution = analysis.solution, analysis.faceCount == 1 {
                    statusLabel(AlignmentPresentation.title(for: solution.overall), symbol: AlignmentPresentation.symbol(for: solution.overall))
                        .font(.headline)
                        .accessibilityIdentifier("alignmentTitle")
                    ForEach(solution.checks.filter { $0.state != .pass }) { check in
                        statusLabel(AlignmentPresentation.message(for: check), symbol: AlignmentPresentation.symbol(for: check.state))
                            .font(.subheadline)
                    }
                    if let smudge = analysis.lensSmudgeConfidence, smudge >= FaceAnalysis.smudgeThreshold {
                        statusLabel("The lens may be smudged. Clean it and retake for a sharper photo.", symbol: "camera.filters")
                            .font(.subheadline)
                    }
                    if solution.checks.allSatisfy({ $0.state == .pass }) {
                        Text(AlignmentPresentation.message(for: solution.checks.first { $0.kind == .headHeight }!))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } else {
                    statusLabel(AlignmentPresentation.message(for: AlignmentCheck(kind: .faceCount, state: .fail, measured: Double(analysis.faceCount))),
                                symbol: AlignmentPresentation.symbol(for: .fail))
                        .font(.subheadline)
                        .accessibilityIdentifier("alignmentTitle")
                }
                Text("Automatic alignment uses ICAO portrait proportions as engineering defaults, not official DNI numbers.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("alignmentStatus")
        }
    }

    @ViewBuilder private var backgroundControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background").font(.headline)
            if model.isSegmenting {
                HStack(spacing: 8) { ProgressView(); Text("Separating the background…").font(.subheadline).foregroundStyle(.secondary) }
                    .accessibilityElement(children: .combine)
            } else if let segmentation = model.segmentation {
                statusLabel(BackgroundPresentation.originalMessage(segmentation.background), symbol: AlignmentPresentation.symbol(for: segmentation.background.state))
                    .font(.subheadline)
                if segmentation.quality.state != .pass {
                    statusLabel(BackgroundPresentation.maskMessage(segmentation.quality), symbol: AlignmentPresentation.symbol(for: segmentation.quality.state))
                        .font(.subheadline)
                }
            } else if model.analysis != nil || model.analysisUnavailable {
                Label("Background separation is not available for this photo. The original background is kept.", systemImage: "info.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Picker("Background", selection: backgroundSelection) {
                Text("Original").tag(false)
                Text("White").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!model.canReplaceBackground)
            .accessibilityIdentifier("backgroundPicker")
            if case .color = model.adjustment.background {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edge softness").font(.subheadline)
                    Slider(value: Binding(get: { model.adjustment.edgeSoftness }, set: { model.adjustment.edgeSoftness = $0 }),
                           in: 0...1, step: 0.1, onEditingChanged: { editing in if !editing { model.refreshBackgroundPreview() } }) { Text("Edge softness") }
                        .accessibilityValue(model.adjustment.edgeSoftness.formatted(.number.precision(.fractionLength(1))))
                }
                Text("White is the Spain DNI requirement. Check hair and shoulder edges in the preview; the original is kept until export.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .disabled(model.activity != nil)
    }

    @ViewBuilder private var toneControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Tone").font(.headline)
            if model.policy.alteration == .forbidden {
                Label("This document requires an unaltered photo, so tonal correction is off.", systemImage: "info.circle")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Toggle("Automatic exposure and colour", isOn: Binding(
                    get: { model.adjustment.tone.isEnabled },
                    set: { model.adjustment.tone.isEnabled = $0; model.refreshBackgroundPreview() }))
                    .disabled(!model.canAdjustTone)
                    .accessibilityIdentifier("toneToggle")
                if model.adjustment.tone.isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strength").font(.subheadline)
                        Slider(value: Binding(get: { model.adjustment.tone.strength }, set: { model.adjustment.tone.strength = $0 }),
                               in: 0...1, step: 0.1, onEditingChanged: { editing in if !editing { model.refreshBackgroundPreview() } }) { Text("Strength") }
                            .accessibilityValue("\(Int((model.adjustment.tone.strength * 100).rounded())) percent")
                    }
                    Toggle("Show original for comparison", isOn: $model.showsOriginal)
                        .accessibilityIdentifier("showOriginal")
                }
                if let assessment = model.toneAssessment {
                    statusLabel(TonePresentation.message(for: assessment), symbol: AlignmentPresentation.symbol(for: assessment.state))
                        .font(.subheadline)
                }
                Text("Global exposure, white balance, and mild sharpening only. No retouching, no relighting; the original is kept.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .disabled(model.activity != nil)
    }

    private var backgroundSelection: Binding<Bool> {
        Binding(get: { if case .color = model.adjustment.background { return true } else { return false } },
                set: { white in
                    model.adjustment.background = white ? .color(.white) : .original
                    model.refreshBackgroundPreview()
                })
    }

    private func statusLabel(_ text: LocalizedStringResource, symbol: String) -> some View {
        Label { Text(text) } icon: { Image(systemName: symbol) }
    }

    private var adjustmentControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adjust crop").font(.headline)
                Spacer()
                Button { model.resetCrop() } label: {
                    Text(model.analysis?.solution != nil ? LocalizedStringKey("Align automatically") : LocalizedStringKey("Reset"))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier("resetCrop")
            }
            cropSlider("Zoom", value: $model.adjustment.zoom, range: 1...4, step: 0.05)
            cropSlider("Horizontal position", value: $model.adjustment.horizontal, range: 0...1, step: 0.025)
            cropSlider("Vertical position", value: $model.adjustment.vertical, range: 0...1, step: 0.025)
            cropSlider("Straighten", value: $model.adjustment.rotationDegrees, range: CropAdjustment.rotationRange, step: 0.5)
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
                    Label("No headphones, earbuds, hats, or other accessories", systemImage: "headphones")
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
    let paperName: String
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
                    Text("\(paperName) · \(result.layout.placedCount) copies · \(result.layout.pages.count) page(s)")
                    Text("Print at Actual Size / 100%. Disable Fit to Page and borderless printing, then measure the 50 mm bar and one copy before cutting.")
                        .font(.subheadline)
                    ShareLink(item: result.pdf) { Label("Share PDF", systemImage: "square.and.arrow.up") }
                        .accessibilityIdentifier("sharePDF")
                    ShareLink(items: result.pages) { Label("Share page JPEGs for a photo lab", systemImage: "photo.on.rectangle.angled") }
                        .accessibilityIdentifier("sharePages")
                    if PrintController.isAvailable {
                        Button {
                            PrintController.shared.present(pdf: result.pdf, jobName: String(localized: "Foto carnet sheet"))
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                        .accessibilityIdentifier("print")
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// Marketing version and build number from the bundle, e.g. "0.3.0 (34)". The build number is the git
/// commit count set by scripts/bump-version.sh, so a screenshot identifies the exact commit.
enum AppVersion {
    static var display: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "0"
        let build = info["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
}
