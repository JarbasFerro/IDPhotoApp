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
    @State private var comparing = false
    /// The full list of checks, in a sheet: the screen itself stays one page with the photo in view.
    @State private var detailsFocus: CheckDetailsSheet.Focus?
    @State private var confirmEdit = false
    /// False until the screen has settled and the check has finished; the portrait then springs into its frame.
    @State private var landed = false
    /// The measuring lines (D-2): drawn when the photo lands, folded into the chip after a moment.
    @State private var showsMeasureLines = false
    /// Bumped once when a verdict appears or changes; drives the symbol bounce.
    @State private var verdictBounce = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.zoomNamespace) private var zoomNamespace
    /// Where this screen sits in the path; the screens it opens are pushed right after it.
    private var nextIndex: Int { (path.firstIndex(of: .check(photoID)) ?? path.count - 1) + 1 }
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
                ScrollView {
                    VStack(alignment: .leading, spacing: Design.Spacing.group) {
                        portrait(entry)
                        summaryBlock(entry)
                        if dynamicTypeSize.isAccessibilitySize { actions }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Design.Surface.screen)
                .safeAreaInset(edge: .bottom) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        actions
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                            .background(Design.Surface.screen)
                    }
                }
            } else {
                ContentUnavailableView("This photo was removed", systemImage: "photo")
            }
        }
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
        .task(id: photoID) {
            // Landing: show the uncropped photo first, wait for the push to settle and the check to finish, then frame it.
            landed = false
            try? await Task.sleep(for: Design.Motion.landingDelay(reduceMotion: reduceMotion))
            while (entry?.isAnalyzing ?? false), !Task.isCancelled { try? await Task.sleep(for: .milliseconds(50)) }
            guard !Task.isCancelled else { return }
            withAnimation(Design.Motion.landing.resolved(reduceMotion: reduceMotion)) { landed = true }
            // Show the measuring once, then fold it into the chip.
            guard measurement(for: entry) != nil else { return }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 600))
            showsMeasureLines = true
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) { showsMeasureLines = false }
        }
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

    private func portrait(_ entry: PhotoEntry) -> some View {
        let checking = entry.isAnalyzing || !landed
        let width: CGFloat = dynamicTypeSize.isAccessibilitySize ? 200 : (checking ? 250 : 210)
        let format = model.renderTarget.format
        let portrait = PortraitView(entry: entry, format: format, showsOriginal: comparing || !landed,
                                    label: comparing ? "Original photo" : "Framed photo", animated: !reduceMotion)
        return VStack(spacing: Design.Spacing.caption) {
            // The photo and its measurement lie on the mat; the only thing on the grid besides the photo is the chip,
            // which has its own solid background. Captions sit below, on the plain screen.
            VStack(spacing: Design.Spacing.control) {
                Group {
                    if developerMode {
                        CaptureProtected { portrait }.aspectRatio(format.aspectRatio, contentMode: .fit)
                    } else {
                        portrait
                    }
                }
                .frame(maxWidth: width)
                .paperDimmedInDark()
                .paperShadow(lifted: checking)
                .animation(Design.Motion.landing.resolved(reduceMotion: reduceMotion), value: checking)
                .onLongPressGesture(minimumDuration: 0.15, maximumDistance: 40) {} onPressingChanged: { pressing in
                    withAnimation(Design.Motion.compare.resolved(reduceMotion: reduceMotion)) { comparing = pressing }
                }
                .accessibilityHint("Press and hold to compare with the original.")
                .accessibilityAction(named: Text("Compare with original")) { comparing.toggle() }
                .accessibilityIdentifier("portrait")
                // The photo is what Your sheet and Digital Photo zoom out of (U4).
                .zoomSource(.sheet, at: nextIndex, in: zoomNamespace)
                .zoomSource(.digital(photoID), at: nextIndex, in: zoomNamespace)
                .overlay {
                    if let measurement = measurement(for: entry), landed, !comparing, !entry.isAnalyzing {
                        MeasurementOverlay(measurement: measurement, showsRange: model.document.statesHeadHeight,
                                           visible: showsMeasureLines)
                    }
                }
                if let measurement = measurement(for: entry), landed, !entry.isAnalyzing {
                    MeasurementChip(measurement: measurement, showsRange: model.document.statesHeadHeight, showsLines: $showsMeasureLines)
                }
            }
            .padding(.vertical, Design.Spacing.group)
            .frame(maxWidth: .infinity)
            .onMat(bleed: 16)
            Text(comparing ? "Original" : entry.isAnalyzing ? "Finding your face…" : !landed ? "Framing…" : "Hold to compare with the original")
                .font(Design.Typography.caption).foregroundStyle(.secondary)
                .animation(nil, value: checking)
                // Leaf element that marks the screen for UI tests; identifiers on containers hide their children.
                .accessibilityIdentifier("photoCheck")
            if developerMode {
                Text(verbatim: CaptureProtection.isAvailable
                     ? "Capture protection test: on. Take a screenshot to check."
                     : "Capture protection test: unavailable on this iOS.")
                    .font(Design.Typography.noteDigits).foregroundStyle(.tertiary)
                    .accessibilityIdentifier("captureProtectionStatus")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Verdict and details (design 2a)

    private func summary(for entry: PhotoEntry) -> PhotoCheckSummary {
        let whiteApplied: Bool = { if case .color = entry.adjustment.background { return true } else { return false } }()
        return CheckPresentation.summary(for: entry, whiteApplied: whiteApplied, sourceIsSmall: model.sourceIsSmall)
    }

    private func summaryBlock(_ entry: PhotoEntry) -> some View {
        let summary = summary(for: entry)
        return VStack(alignment: .leading, spacing: Design.Spacing.group) {
            verdict(summary)
            if summary.headline != .checking {
                // Said right under the verdict: an unlocked photo is final, and Adjust asks before changing it.
                if entry.isUnlocked {
                    Label("Unlocked. Printing and sharing this photo is free.", systemImage: "checkmark.seal")
                        .font(Design.Typography.note).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("unlockedNote")
                }
                detailsCard(summary)
                if !entry.isUnlocked, let note = CheckPresentation.editingNote(for: entry, document: model.document) {
                    editingNote(note)
                }
            }
        }
        .animation(.default, value: summary)
        // Only when the analysis finishes or the verdict changes; a photo that is already checked stays quiet.
        .sensoryFeedback(trigger: summary.headline) { old, new in
            guard old != new else { return nil }
            switch new {
            case .checking: return nil
            case .good: return .success
            case .review, .retake: return .warning
            }
        }
        .onChange(of: summary.headline) { _, new in
            guard new != .checking, !reduceMotion else { return }
            // The symbol may be inserted by this very change; bounce once it is on screen.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(80))
                verdictBounce += 1
            }
        }
    }

    /// One large answer. Facts and advisory checks sit behind it (docs/03-design.md §4: only facts say a thing is done).
    private func verdict(_ summary: PhotoCheckSummary) -> some View {
        VStack(spacing: Design.Spacing.caption) {
            if summary.headline == .checking {
                ProgressView().controlSize(.large)
            } else {
                Image(systemName: CheckPresentation.verdictSymbol(for: summary.headline))
                    .font(.largeTitle)
                    .foregroundStyle(StatusStyle.color(for: summary.headline))
                    .symbolEffect(.bounce, options: .nonRepeating, value: verdictBounce)
                    .accessibilityHidden(true)
            }
            Text(CheckPresentation.title(for: summary.headline))
                .font(Design.Typography.hero)
            Group {
                if summary.headline == .good {
                    Text("Framed for \(DocumentPresentation.name(model.document))")
                } else if summary.attention.count == 1, let only = summary.attention.first {
                    // One thing to look at: say it here, so nobody has to open the list to learn what it is.
                    Text(only.detail)
                } else {
                    Text(CheckPresentation.subtitle(for: summary.headline))
                }
            }
            .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("checkHeadline")
    }

    /// Two short rows that open the full list in a sheet. The list used to unfold in place and pushed the photo
    /// and the buttons off the screen (founder, 0.20 review).
    private func detailsCard(_ summary: PhotoCheckSummary) -> some View {
        let byEye = model.document.byEyeChecks
        let worst = summary.worstState
        return VStack(spacing: 0) {
            if !summary.rows.isEmpty {
                disclosureRow(symbol: StatusStyle.symbol(for: worst), color: StatusStyle.color(for: worst),
                              title: summary.attention.isEmpty
                                  ? Text("Everything measured looks fine")
                                  : Text("^[\(summary.attention.count) thing](inflect: true) to look at"),
                              subtitle: Text(verbatim: (summary.attention.isEmpty ? summary.rows : summary.attention)
                                  .map { String(localized: $0.title) }.joined(separator: " · ")),
                              identifier: "measuredRow") { detailsFocus = .measured }
            }
            if !byEye.isEmpty {
                if !summary.rows.isEmpty { Divider().padding(.leading) }
                disclosureRow(symbol: StatusStyle.symbol(for: .manualCheck), color: StatusStyle.color(for: .manualCheck),
                              title: Text("^[\(byEye.count) thing](inflect: true) to check by eye"),
                              subtitle: Text(verbatim: byEye.prefix(2).map(DocumentPresentation.check).joined(separator: " · ")),
                              identifier: "byEyeRow") { detailsFocus = .byEye }
            }
        }
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
    }

    private func disclosureRow(symbol: String, color: Color, title: Text, subtitle: Text?,
                               identifier: String, open: @escaping () -> Void) -> some View {
        Button(action: open) {
            HStack(spacing: Design.Spacing.control) {
                Image(systemName: symbol).foregroundStyle(color).frame(width: 24)
                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                    title.foregroundStyle(.primary)
                    if let subtitle {
                        subtitle.font(Design.Typography.note).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Shows every check.")
        .accessibilityIdentifier(identifier)
    }

    /// Honest editing (ADR-051): when the document's own rules ask for an unedited photo, say what Calipic changed
    /// and offer the original in one tap. Editing itself stays available (ADR-051).
    private func editingNote(_ note: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            Text("This document's rules ask for an unedited photo. \(String(localized: note))")
                .font(Design.Typography.note).foregroundStyle(.secondary)
            Button("Use Original Photo") { model.useOriginalLook(for: photoID) }
                .font(Design.Typography.note.weight(.semibold))
                .frame(minHeight: Design.Size.minimumTarget)
                .accessibilityIdentifier("useOriginal")
        }
        .padding(.horizontal, Design.Spacing.tight)
    }

    /// The main output on its own line; the other output and Adjust share the next one, so the buttons take two
    /// lines instead of three. At accessibility text sizes they stack.
    private var actions: some View {
        let outputs = model.document.availableOutputs
        let secondary = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Design.Spacing.control)) : AnyLayout(HStackLayout(spacing: Design.Spacing.control))
        return VStack(spacing: Design.Spacing.control) {
            if let first = outputs.first { outputButton(first).brandProminentButtonStyle() }
            secondary {
                ForEach(Array(outputs.dropFirst()), id: \.self) { output in
                    outputButton(output).buttonStyle(.bordered)
                }
                Button {
                    // An unlocked photo is final (ADR-048 §5): warn before it is locked again.
                    if model.entries.first(where: { $0.id == photoID })?.isUnlocked == true { confirmEdit = true } else { showAdjust = true }
                } label: {
                    Label("Adjust", systemImage: "slider.horizontal.3").lineLimit(1).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("adjust")
            }
        }
    }

    private func outputButton(_ output: Output) -> some View {
        Button {
            path.append(output == .print ? .sheet : .digital(photoID))
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
