import SwiftUI

/// Step 2: the framed portrait, one headline, a few plain rows, and one primary action.
struct PhotoCheckView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var showAdjust = false
    @State private var showRequirements = false
    @State private var confirmRemove = false
    @State private var comparison = OriginalComparison()
    private var comparing: Bool { comparison.isComparing }
    /// The full list of checks, in a sheet: the screen itself stays one page with the photo in view.
    @State private var detailsFocus: CheckDetailsSheet.Focus?
    @State private var confirmEdit = false
    /// False until the screen has settled and the check has finished; the portrait then springs into its frame.
    @State private var landed = false
    /// The measuring lines (D-2): drawn when the photo lands, folded into the chip after a moment.
    @State private var showsMeasureLines = false
    @State private var measurementSequence = MeasurementSequence()
    /// Bumped once when a verdict appears or changes; drives the symbol bounce.
    @State private var verdictBounce = 0
    @State private var verdictRevealed = false
    @State private var celebratesVerdict = false
    @GestureState private var compareHeld = false
    @State private var suppressCompareTap = false
    @Environment(\.zoomNamespace) private var zoomNamespace
    /// Where this screen sits in the path; the screens it opens are pushed right after it.
    private var nextIndex: Int { (path.lastIndex(of: .check(photoID)) ?? path.count - 1) + 1 }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Developer details (long press on the version line) also switch on the L19-017 capture-protection test.
    @AppStorage(DeveloperMode.key) private var developerMode = false

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }
    private var position: (Int, Int)? {
        guard let index = model.entries.firstIndex(where: { $0.id == photoID }) else { return nil }
        return (index + 1, model.entries.count)
    }

    var body: some View {
        Group {
            if let entry {
                JourneyScreen { size in
                    portrait(entry, size: size)
                } tray: {
                    summaryBlock(entry)
                } actions: {
                    actions(entry)
                }
            } else {
                ContentUnavailableView("This photo was removed", systemImage: "photo")
            }
        }
        .guideOverlay(model.tutorial, current: guideTip, output: model.document.primaryOutput)
        .navigationTitle(position.map { $0.1 > 1 ? String(localized: "Photo \($0.0) of \($0.1)") : String(localized: "Photo Check") } ?? String(localized: "Photo Check"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { StepMarker(current: .check, output: model.document.primaryOutput, compact: true) }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { acquire(.camera, .replace) } label: { Label("Take Photo", systemImage: "camera") }
                    Button { acquire(.library, .replace) } label: { Label("Choose Photo", systemImage: "photo.on.rectangle") }
                } label: {
                    Text("Retake")
                }
                .accessibilityIdentifier("retake")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !model.tutorial.isActive {
                        ForEach(model.document.availableOutputs.filter { $0 != model.document.primaryOutput }, id: \.self) { output in
                            outputButton(output)
                        }
                    }
                    if shouldRetake(entry) { adjustButton }
                    Button { showRequirements = true } label: { Label("Photo requirements", systemImage: "list.bullet.rectangle") }
                    Button(role: .destructive) { confirmRemove = true } label: { Label("Remove Photo", systemImage: "trash") }
                        .disabled(model.activity != nil)
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
                .brandNeutralToolbarItem()
                .accessibilityIdentifier("photoMenu")
            }
        }
        .confirmationDialog("Remove this photo and its copies on the sheet?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove Photo", role: .destructive) {
                model.selectedID = photoID
                model.removePhoto()
                path.removeAll()
            }
        } message: { Text("The original in your photo library is kept.") }
        .confirmationDialog("This photo is final", isPresented: $confirmEdit, titleVisibility: .visible) {
            Button("Edit Photo") {
                model.relock(photoID)
                showAdjust = true
            }
        } message: { Text("Editing it locks it again. The changed photo will use another credit.") }
        .sheet(isPresented: $showAdjust) { AdjustSheet(model: model, photoID: photoID) }
        .sheet(isPresented: $showRequirements) { RequirementsView(document: model.document) }
        .sheet(item: $detailsFocus) { focus in
            if let entry {
                CheckDetailsSheet(summary: summary(for: entry), byEye: model.document.byEyeChecks, focus: focus)
            }
        }
        .onAppear { model.selectedID = photoID; model.showsOriginal = false }
        .task(id: photoID) { await presentPhoto() }
        .task(id: displayedSummary.headline) {
            guard celebratesVerdict, displayedSummary.headline != .checking, !reduceMotion else { return }
            do { try await Task.sleep(for: .milliseconds(80)) } catch { return }
            verdictBounce += 1
        }
        .task(id: comparison.pulse) {
            guard let pulse = comparison.pulse else { return }
            do { try await Task.sleep(for: .seconds(1.2)) } catch { return }
            updateComparison { $0.finishPulse(pulse) }
        }
        .onDisappear {
            comparison = OriginalComparison()
        }
    }

    private var displayedSummary: PhotoCheckSummary {
        guard verdictRevealed, let entry else { return .checking }
        return summary(for: entry)
    }

    /// A view-bound task: no landing, line reveal, or verdict can arrive after this visit is cancelled.
    private func presentPhoto() async {
        if model.presentedChecks.contains(photoID) {
            celebratesVerdict = false
            showsMeasureLines = false
            landed = true
            verdictRevealed = true
            return
        }
        landed = false
        verdictRevealed = false
        showsMeasureLines = false
        celebratesVerdict = true
        do {
            try await Task.sleep(for: Design.Motion.landingDelay(reduceMotion: reduceMotion))
            while entry?.isAnalyzing == true { try await Task.sleep(for: .milliseconds(50)) }
            try Task.checkCancellation()
            withAnimation(Design.Motion.landing.resolved(reduceMotion: reduceMotion)) { landed = true }
            if measurement(for: entry) != nil {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 600))
                try Task.checkCancellation()
                // Wait for the visible overlay's animation completion, also after a held comparison interrupts it.
                try await measurementSequence.waitForDraw { showsMeasureLines = true }
            }
            while entry.map({ summary(for: $0).headline == .checking }) == true {
                try await Task.sleep(for: .milliseconds(50))
            }
            try Task.checkCancellation()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { verdictRevealed = true }
            model.presentedChecks.insert(photoID)
            if showsMeasureLines {
                try await Task.sleep(for: .seconds(1.9))
                try Task.checkCancellation()
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { showsMeasureLines = false }
            }
        } catch { /* Leaving the screen cancels every delayed presentation change. */ }
    }

    /// The final look. While the photo is being checked it sits wide and uncropped; when the face is found the
    /// crop animates into the official frame and the white background fades in: "we found you and framed you".
    /// Press and hold to see the original.
    /// Where the head and eyes fall for the current framing; nil without exactly one measured face.
    private func measurement(for entry: PhotoEntry?) -> PhotoMeasurement? {
        guard let entry, let geometry = entry.analysis?.geometry else { return nil }
        let target = model.target(for: entry)
        return PhotoMeasurement.measure(geometry: geometry, adjustment: entry.adjustment, format: target.format, spec: target.spec)
    }

    private func portrait(_ entry: PhotoEntry, size: CGSize) -> some View {
        let checking = entry.isAnalyzing || !landed
        let format = model.renderTarget.format
        let photoHeight = max(0, min(size.height - 40, size.width / format.aspectRatio))
        let portrait = PortraitView(entry: entry, format: format, showsOriginal: comparing || !landed,
                                    label: comparing ? "Original photo" : "Framed photo", animated: !reduceMotion)
        return VStack(spacing: 0) {
            Group {
                if developerMode {
                    CaptureProtected { portrait }.aspectRatio(format.aspectRatio, contentMode: .fit)
                } else {
                    portrait
                }
            }
            .frame(width: photoHeight * format.aspectRatio, height: photoHeight)
            .contentShape(Rectangle())
            .paperDimmedInDark()
            .paperShadow(lifted: checking)
            .scaleEffect(checking && !reduceMotion ? 1.06 : 1)
            .animation(Design.Motion.landing.resolved(reduceMotion: reduceMotion), value: checking)
            .onLongPressGesture(minimumDuration: 0.15, maximumDistance: 40) {} onPressingChanged: { pressing in
                updateComparison { $0.holdPhoto(pressing) }
            }
            .accessibilityHint("Press and hold to compare with the original.")
            .accessibilityAction(named: Text("Compare with original")) { updateComparison { $0.toggle() } }
            .accessibilityIdentifier("portrait")
            .zoomSource(.sheet, at: nextIndex, in: zoomNamespace)
            .zoomSource(.digital(photoID), at: nextIndex, in: zoomNamespace)
            .overlay {
                if let measurement = measurement(for: entry), landed, !comparing {
                    let drawing = measurementSequence.id
                    MeasurementOverlay(measurement: measurement, showsRange: model.document.statesHeadHeight,
                                       visible: showsMeasureLines) {
                        if let drawing { measurementSequence.drawn(id: drawing) }
                    }
                }
            }
            HStack(spacing: 8) {
                Button {
                    if !suppressCompareTap { compareBriefly() }
                } label: {
                    Label("Original", systemImage: "rectangle.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.glass)
                .tint(comparing ? Color.brandAccentFill : nil)
                .foregroundStyle(comparing ? Color.white : Color.primary)
                .background { if comparing { Capsule().fill(Brand.accentFill) } }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5, maximumDistance: 40)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .updating($compareHeld) { value, state, _ in
                        if case .second(true, _) = value { state = true }
                    })
                .onChange(of: compareHeld) { _, held in
                    if held { suppressCompareTap = true }
                    updateComparison { $0.holdControl(held) }
                }
                .task(id: compareHeld) {
                    guard !compareHeld else { return }
                    // A native Button also sends its action on release. Consume that action after a hold.
                    do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                    suppressCompareTap = false
                }
                .frame(minHeight: 44)
                .disabled(displayedSummary.headline == .checking)
                .accessibilityHint("Press and hold to compare with the original.")
                .accessibilityIdentifier("photoCheck")
                Spacer(minLength: 0)
                if let measurement = measurement(for: entry), landed {
                    MeasurementChip(measurement: measurement, showsRange: model.document.statesHeadHeight, showsLines: $showsMeasureLines)
                        .disabled(displayedSummary.headline == .checking)
                }
            }
            .frame(height: 40)
            .zIndex(1)
        }
        .frame(width: size.width, height: size.height)
    }

    private func compareBriefly() {
        updateComparison { $0.showBriefly() }
    }

    private func updateComparison(_ change: (inout OriginalComparison) -> Void) {
        withAnimation(Design.Motion.compare.resolved(reduceMotion: reduceMotion)) { change(&comparison) }
    }

    // MARK: - Verdict and details (design 2a)

    private func summary(for entry: PhotoEntry) -> PhotoCheckSummary {
        let whiteApplied: Bool = { if case .color = entry.adjustment.background { return true } else { return false } }()
        return CheckPresentation.summary(for: entry, whiteApplied: whiteApplied, sourceIsSmall: model.sourceIsSmall)
    }

    private func summaryBlock(_ entry: PhotoEntry) -> some View {
        let summary = displayedSummary
        return VStack(alignment: .leading, spacing: Design.Spacing.tray) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Group {
                        if summary.headline == .checking { StatusMark.progress }
                        else { StatusMark(summary.worstState) }
                    }
                    .symbolEffect(.bounce, options: .nonRepeating, value: verdictBounce)
                    .accessibilityHidden(true)
                    Text(CheckPresentation.title(for: summary.headline))
                        .font(Design.Typography.trayTitle)
                        .contentTransition(.opacity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("checkHeadline")
                supportingLine(entry, summary: summary)
                    .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            }
            if summary.headline != .checking {
                TrayRows {
                    if !summary.rows.isEmpty {
                        TrayRow(title: Text("Measured"),
                                detail: Text(verbatim: (summary.attention.isEmpty ? summary.rows : summary.attention)
                                    .map { String(localized: $0.title) }.joined(separator: " · ")),
                                value: measurement(for: entry).map(measurementValue),
                                chevron: true, action: { detailsFocus = .measured },
                                leading: { StatusMark(summary.worstState) })
                            .accessibilityHint("Shows every check.")
                            .accessibilityIdentifier("measuredRow")
                    }
                    if !model.document.byEyeChecks.isEmpty {
                        TrayRow(title: Text("To check by eye"),
                                detail: Text(verbatim: model.document.byEyeChecks.prefix(2).map(DocumentPresentation.check).joined(separator: " · ")),
                                value: Text(model.document.byEyeChecks.count, format: .number),
                                chevron: true, action: { detailsFocus = .byEye },
                                leading: { StatusMark(.manualCheck) })
                            .accessibilityHint("Shows every check.")
                            .accessibilityIdentifier("byEyeRow")
                    }
                    if !entry.isUnlocked, let note = CheckPresentation.editingNote(for: entry, document: model.document) {
                        TrayRow(title: Text("Edited photo"),
                                detail: Text("This document's rules ask for an unedited photo. \(String(localized: note))"),
                                leading: { StatusMark(.manualCheck) }, trailing: {
                            Button("Use Original") { model.useOriginalLook(for: photoID) }
                                .frame(minHeight: 44).accessibilityIdentifier("useOriginal")
                        })
                    }
                }
                .guideTarget(.checkResult, current: guideTip, ring: false)
            }
        }
        .animation(Design.Motion.rearrange.resolved(reduceMotion: reduceMotion), value: summary.headline)
        .sensoryFeedback(trigger: summary.headline) { old, new in
            guard celebratesVerdict, old != new else { return nil }
            switch new {
            case .checking: return nil
            case .good: return .success
            case .review, .retake: return .warning
            }
        }
    }

    @ViewBuilder private func supportingLine(_ entry: PhotoEntry, summary: PhotoCheckSummary) -> some View {
        if summary.headline == .checking {
            Text("Finding your face and preparing the background.")
        } else if entry.analysis?.eyesLookClosed == true {
            Label { Text("Your eyes look closed or turned down.") } icon: { StatusMark(.warn) }
                .accessibilityIdentifier("eyesClosedNote")
        } else if entry.isUnlocked {
            Text("Unlocked. Printing and sharing this photo is free.").accessibilityIdentifier("unlockedNote")
        } else if summary.headline == .retake {
            Text("This photo has problems we can't fix. A new one takes a minute.")
        } else if summary.attention.count == 1, let only = summary.attention.first {
            Text(only.detail)
        } else {
            Text("Framed for \(DocumentPresentation.name(model.document))")
        }
    }

    private func measurementValue(_ measurement: PhotoMeasurement) -> Text {
        let value = (measurement.crownIsEstimate ? "≈ " : "") + MeasurementPresentation.millimetres(measurement.headHeightMM)
        return Text("\(value) mm").font(Design.Typography.readout(.subheadline))
    }

    private func shouldRetake(_ entry: PhotoEntry?) -> Bool {
        guard let entry, verdictRevealed else { return false }
        return summary(for: entry).headline == .retake || entry.analysis?.eyesLookClosed == true
    }

    private func actions(_ entry: PhotoEntry) -> some View {
        Group {
            if shouldRetake(entry) {
                TrayActions {
                    Button { acquire(.camera, .replace) } label: {
                        Label("Retake", systemImage: "camera").frame(maxWidth: .infinity)
                    }
                    .disabled(model.activity != nil)
                    .accessibilityIdentifier("retakePrimary")
                } secondary: {
                    Button(model.document.primaryOutput == .print ? "Print anyway" : "Use anyway") {
                        openOutput(model.document.primaryOutput)
                    }
                    .disabled(model.activity != nil)
                    .accessibilityIdentifier(model.document.primaryOutput == .print ? "outputPrint" : "outputDigital")
                    .guideTarget(.output, current: guideTip)
                }
            } else {
                TrayActions {
                    outputButton(model.document.primaryOutput).guideTarget(.output, current: guideTip)
                } peer: {
                    adjustButton
                }
            }
        }
    }

    private var adjustButton: some View {
        Button {
            if entry?.isUnlocked == true { confirmEdit = true } else { showAdjust = true }
        } label: {
            Text("Adjust").frame(maxWidth: .infinity, minHeight: 44)
        }
        .accessibilityIdentifier("adjust")
    }

    private func openOutput(_ output: Output) { path.append(output == .print ? .sheet : .digital(photoID)) }

    private func outputButton(_ output: Output) -> some View {
        Button {
            openOutput(output)
        } label: {
            Label(output == .print ? "Print" : "Digital Photo", systemImage: output == .print ? "printer" : "photo")
                .lineLimit(1).minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .disabled(model.activity != nil)
        .accessibilityIdentifier(output == .print ? "outputPrint" : "outputDigital")
    }
}

/// Non-interactive rendering of an entry's crop with its background and tone, or the untouched original.
struct PortraitView: View {
    let entry: PhotoEntry
    let format: PhotoFormat
    var showsOriginal = false
    /// Without a label the portrait is decorative and hidden from assistive technologies.
    var label: LocalizedStringResource? = nil
    /// Animate crop changes (the landing) and the background fade; off under Reduce Motion.
    var animated = false

    var body: some View {
        GeometryReader { geometry in
            let adjustment = showsOriginal ? CropAdjustment() : entry.adjustment
            let crop = adjustment.crop(in: entry.photo.pixels, format: format)
            let hasPreview = !showsOriginal && entry.backgroundPreview != nil
            // Both layers stay mounted and move together; only their opacity crossfades. Inserting the white
            // layer on demand made it appear at its final geometry while the other layer was still animating.
            ZStack(alignment: .topLeading) {
                layer(entry.photo.preview, crop: crop, adjustment: adjustment, in: geometry.size)
                if let preview = entry.backgroundPreview {
                    layer(preview, crop: crop, adjustment: adjustment, in: geometry.size)
                        .opacity(hasPreview ? 1 : 0)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
            .animation(Design.Motion.backgroundFade.resolved(animated: animated), value: hasPreview)
            .animation(Design.Motion.reframe.resolved(animated: animated), value: adjustment)
        }
        .aspectRatio(format.aspectRatio, contentMode: .fit)
        .environment(\.layoutDirection, .leftToRight)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.photo))
        .overlay(RoundedRectangle(cornerRadius: Design.Radius.photo).strokeBorder(.primary.opacity(0.15), lineWidth: Design.Stroke.hairline))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label ?? ""))
        .accessibilityHidden(label == nil)
    }

    private func layer(_ image: CGImage, crop: NormalizedCrop, adjustment: CropAdjustment, in size: CGSize) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .frame(width: size.width / crop.width, height: size.height / crop.height)
            .rotationEffect(.degrees(-adjustment.clamped().rotationDegrees),
                            anchor: UnitPoint(x: crop.x + crop.width / 2, y: crop.y + crop.height / 2))
            .offset(x: -crop.x / crop.width * size.width, y: -crop.y / crop.height * size.height)
    }
}

extension PhotoCheckView {
    /// The guide on Photo Check (ADR-052): what the check found, then the way on.
    fileprivate var guideTip: GuideTip? { model.tutorial.current([.checkResult, .output]) }
}
