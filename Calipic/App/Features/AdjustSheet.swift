import SwiftUI

/// A photo editor: the portrait stays on screen while one tool's controls sit below it (photo, panel, tool strip).
struct AdjustSheet: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tool: Tool = .crop

    enum Tool: String, CaseIterable, Identifiable {
        case crop, straighten, background, light
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .crop: "Crop"
            case .straighten: "Straighten"
            case .background: "Background"
            case .light: "Light"
            }
        }
        var symbol: String {
            switch self {
            case .crop: "crop"
            case .straighten: "level"
            case .background: "person.and.background.dotted"
            case .light: "sun.max"
            }
        }
    }

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }

    private var availableTools: [Tool] {
        Tool.allCases.filter { $0 != .light || model.policy.alteration != .forbidden || model.document.isCustom }
    }

    private var activeTool: Tool { availableTools.contains(tool) ? tool : .crop }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let entry {
                    photoArea(entry)
                    panel(entry)
                }
            }
            .background(Design.Surface.screen)
            .navigationTitle("Adjust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { model.resetCrop() } label: {
                        Label(model.analysis?.solution != nil ? LocalizedStringKey("Auto") : LocalizedStringKey("Reset"), systemImage: "wand.and.stars")
                    }
                    .accessibilityIdentifier("resetCrop")
                    Toggle(isOn: $model.showsOriginal) { Label("Compare", systemImage: "rectangle.on.rectangle") }
                        .toggleStyle(.button)
                        .accessibilityIdentifier("showOriginal")
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("adjustDone") }
            }
            .onAppear { model.selectedID = photoID }
            .onDisappear { model.showsOriginal = false }
        }
        .presentationDetents([.large])
        // A rigid tick when Straighten passes level, or when zoom and position return exactly to the automatic framing.
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: model.adjustment) { old, new in
            let crossedLevel = old.rotationDegrees != 0
                && (new.rotationDegrees == 0 || old.rotationDegrees * new.rotationDegrees < 0)
            let auto = model.automaticAdjustment
            func atAuto(_ a: CropAdjustment) -> Bool {
                a.zoom == auto.zoom && a.horizontal == auto.horizontal && a.vertical == auto.vertical
            }
            return crossedLevel || (atAuto(new) && !atAuto(old))
        }
    }

    // MARK: Photo

    private func photoArea(_ entry: PhotoEntry) -> some View {
        VStack(spacing: Design.Spacing.caption) {
            CropPreview(photo: entry.photo, format: model.renderTarget.format, image: model.showsOriginal ? nil : entry.backgroundPreview, adjustment: $model.adjustment)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            status(entry)
                .font(Design.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .padding(.horizontal, Design.Spacing.group)
        .padding(.top, Design.Spacing.text)
        .padding(.bottom, Design.Spacing.text)
    }

    /// One line under the photo; it keeps its height when empty so the photo does not jump between tools.
    @ViewBuilder
    private func status(_ entry: PhotoEntry) -> some View {
        switch activeTool {
        case .crop:
            if model.sourceIsSmall {
                StatusLabel(text: "This crop may look soft when printed. Zoom out or choose a higher-resolution photo.", state: .warn)
            } else {
                Text("Drag to move, pinch to zoom.")
            }
        case .straighten:
            Text(verbatim: "")
        case .background:
            if let segmentation = entry.segmentation, segmentation.quality.state != .pass {
                StatusLabel(text: BackgroundPresentation.maskMessage(segmentation.quality), state: segmentation.quality.state)
            } else if entry.isSegmenting {
                HStack(spacing: Design.Spacing.text) { ProgressView(); Text("Separating the background…") }
            } else if !model.canReplaceBackground {
                Text("The background could not be separated in this photo, so the original is kept.")
            } else {
                Text(verbatim: "")
            }
        case .light:
            if let assessment = entry.toneAssessment {
                StatusLabel(text: TonePresentation.message(for: assessment), state: assessment.state)
            } else {
                Text("Evens out exposure and removes colour tints. Nothing on your face is retouched.")
            }
        }
    }

    // MARK: Panel and tool strip

    private func panel(_ entry: PhotoEntry) -> some View {
        VStack(spacing: 0) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView { panelContent(entry).padding(.vertical, Design.Spacing.group) }
                        .containerRelativeFrame(.vertical) { height, _ in height * 0.45 }
                } else {
                    panelContent(entry).padding(.vertical, Design.Spacing.group)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .top)
            .padding(.horizontal, Design.Spacing.group)
            toolStrip
        }
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Design.Radius.group, topTrailingRadius: Design.Radius.group)
                .fill(Design.Surface.card)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var toolStrip: some View {
        HStack(spacing: 0) {
            ForEach(availableTools) { item in
                Button { tool = item } label: {
                    VStack(spacing: Design.Spacing.tight) {
                        Image(systemName: item.symbol).font(.title3)
                        Text(item.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(item == activeTool ? Color.brandAccent : Color.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tool-\(item.rawValue)")
                .accessibilityAddTraits(item == activeTool ? .isSelected : [])
            }
        }
        .padding(.horizontal, Design.Spacing.text)
        .padding(.bottom, Design.Spacing.tight)
    }

    @ViewBuilder
    private func panelContent(_ entry: PhotoEntry) -> some View {
        Group {
            switch activeTool {
            case .crop: cropPanel(entry)
            case .straighten: straightenPanel
            case .background: backgroundPanel
            case .light: lightPanel
            }
        }
        .id(activeTool)
        .transition(.opacity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: activeTool)
    }

    private func cropPanel(_ entry: PhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.control) {
            if model.document.isCustom {
                VStack(alignment: .leading, spacing: Design.Spacing.text) {
                    Picker("Framing", selection: framingSelection) {
                        Text("Wider").tag(FramingPreset.wider)
                        Text("Standard").tag(FramingPreset.standard)
                        Text("Closer").tag(FramingPreset.closer)
                    }
                    .pickerStyle(.segmented)
                    .disabled(entry.analysis?.solution == nil)
                    .accessibilityIdentifier("framingPicker")
                    if entry.analysis?.solution == nil, !entry.isAnalyzing {
                        Text("Framing needs a face the app can find. Use Move and zoom instead.")
                            .font(Design.Typography.note).foregroundStyle(.secondary)
                    }
                }
            }
            slider("Zoom", value: $model.adjustment.zoom, range: 1...4, step: 0.05)
            HStack(spacing: Design.Spacing.text) {
                moveButton("Move Up", symbol: "arrow.up", dx: 0, dy: 0.05)
                moveButton("Move Down", symbol: "arrow.down", dx: 0, dy: -0.05)
                moveButton("Move Left", symbol: "arrow.left", dx: 0.05, dy: 0)
                moveButton("Move Right", symbol: "arrow.right", dx: -0.05, dy: 0)
                iconButton("Zoom Out", symbol: "minus.magnifyingglass") { changeZoom(by: -0.1) }
                iconButton("Zoom In", symbol: "plus.magnifyingglass") { changeZoom(by: 0.1) }
            }
        }
    }

    private var straightenPanel: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            Text(Measurement(value: model.adjustment.rotationDegrees, unit: UnitAngle.degrees)
                .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...1)))))
                .font(Design.Typography.readout(.subheadline))
                .frame(maxWidth: .infinity)
            slider("Straighten", value: $model.adjustment.rotationDegrees, range: CropAdjustment.rotationRange, step: 0.5)
        }
    }

    private var backgroundPanel: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.control) {
            Picker("Background", selection: backgroundSelection) {
                Text("Original").tag(BackgroundColor?.none)
                ForEach(model.document.replacementColors, id: \.self) { color in
                    Text(BackgroundPresentation.name(color)).tag(BackgroundColor?.some(color))
                }
            }
            .pickerStyle(.segmented)
            .disabled(!model.canReplaceBackground)
            .accessibilityIdentifier("backgroundPicker")
            if case .color = model.adjustment.background {
                slider("Edge softness", value: $model.adjustment.edgeSoftness, range: 0...1, step: 0.1) { model.refreshBackgroundPreview() }
            }
        }
    }

    private var lightPanel: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.control) {
            if model.policy.alteration != .forbidden {
                Toggle(isOn: Binding(get: { model.adjustment.tone.isEnabled },
                                     set: { model.adjustment.tone.isEnabled = $0; model.refreshBackgroundPreview() })) {
                    Text("Light and colour").font(Design.Typography.cardDetail.weight(.medium))
                }
                .disabled(!model.canAdjustTone)
                .accessibilityIdentifier("toneToggle")
                if model.adjustment.tone.isEnabled {
                    slider("Correction strength", value: $model.adjustment.tone.strength, range: 0...1, step: 0.1) { model.refreshBackgroundPreview() }
                }
            }
            if model.document.isCustom {
                Toggle(isOn: Binding(get: { model.adjustment.monochrome },
                                     set: { model.adjustment.monochrome = $0; model.refreshBackgroundPreview() })) {
                    Text("Black and white").font(Design.Typography.cardDetail.weight(.medium))
                }
                .accessibilityIdentifier("monochromeToggle")
            }
        }
    }

    private func moveButton(_ title: LocalizedStringKey, symbol: String, dx: Double, dy: Double) -> some View {
        iconButton(title, symbol: symbol) {
            var next = model.adjustment
            next.horizontal += dx
            next.vertical += dy
            model.adjustment = next.clamped()
        }
    }

    private func iconButton(_ title: LocalizedStringKey, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }

    private func changeZoom(by amount: Double) {
        var next = model.adjustment
        next.zoom += amount
        model.adjustment = next.clamped()
    }

    private func slider(_ title: LocalizedStringKey, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
                        onEnd: @escaping () -> Void = {}) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.tight) {
            Text(title).font(Design.Typography.cardDetail)
            Slider(value: value, in: range, step: step, onEditingChanged: { editing in if !editing { onEnd() } }) { Text(title) }
                .accessibilityValue(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
        }
    }

    /// nil is the original background; otherwise one of the document's replacement colours.
    private var backgroundSelection: Binding<BackgroundColor?> {
        Binding(get: { if case .color(let color) = model.adjustment.background { return color } else { return nil } },
                set: { color in
                    model.adjustment.background = color.map { .color($0) } ?? .original
                    model.refreshBackgroundPreview()
                })
    }

    private var framingSelection: Binding<FramingPreset> {
        Binding(get: { model.selected?.framing ?? .standard },
                set: { model.setFraming($0, for: photoID); model.refreshBackgroundPreview() })
    }
}
