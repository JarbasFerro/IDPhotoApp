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
    /// nil follows the verdict: details open by themselves when something needs a look.
    @State private var showMeasured: Bool?
    @State private var showByEye = false
    @State private var confirmEdit = false
    /// False until the screen has settled and the check has finished; the portrait then springs into its frame.
    @State private var landed = false
    /// Bumped once when a verdict appears or changes; drives the symbol bounce.
    @State private var verdictBounce = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        .onAppear { model.selectedID = photoID; model.showsOriginal = false }
        .task(id: photoID) {
            // Landing: show the uncropped photo first, wait for the push to settle and the check to finish, then frame it.
            landed = false
            try? await Task.sleep(for: Design.Motion.landingDelay(reduceMotion: reduceMotion))
            while (entry?.isAnalyzing ?? false), !Task.isCancelled { try? await Task.sleep(for: .milliseconds(50)) }
            guard !Task.isCancelled else { return }
            withAnimation(Design.Motion.landing.resolved(reduceMotion: reduceMotion)) { landed = true }
        }
    }

    /// The final look. While the photo is being checked it sits wide and uncropped; when the face is found the
    /// crop animates into the official frame and the white background fades in: "we found you and framed you".
    /// Press and hold to see the original.
    private func portrait(_ entry: PhotoEntry) -> some View {
        let checking = entry.isAnalyzing || !landed
        let width: CGFloat = dynamicTypeSize.isAccessibilitySize ? 200 : (checking ? 250 : 210)
        let format = model.renderTarget.format
        let portrait = PortraitView(entry: entry, format: format, showsOriginal: comparing || !landed,
                                    label: comparing ? "Original photo" : "Framed photo", animated: !reduceMotion)
        return VStack(spacing: Design.Spacing.caption) {
            Group {
                if developerMode {
                    CaptureProtected { portrait }.aspectRatio(format.aspectRatio, contentMode: .fit)
                } else {
                    portrait
                }
            }
                .frame(maxWidth: width)
                .shadow(color: .black.opacity(checking ? 0.04 : 0.12), radius: 12, y: 6)
                .animation(Design.Motion.landing.resolved(reduceMotion: reduceMotion), value: checking)
                .onLongPressGesture(minimumDuration: 0.15, maximumDistance: 40) {} onPressingChanged: { pressing in
                    withAnimation(Design.Motion.compare.resolved(reduceMotion: reduceMotion)) { comparing = pressing }
                }
                .accessibilityHint("Press and hold to compare with the original.")
                .accessibilityAction(named: Text("Compare with original")) { comparing.toggle() }
                .accessibilityIdentifier("portrait")
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

    private func summaryBlock(_ entry: PhotoEntry) -> some View {
        let whiteApplied: Bool = { if case .color = entry.adjustment.background { return true } else { return false } }()
        let summary = CheckPresentation.summary(for: entry, whiteApplied: whiteApplied, sourceIsSmall: model.sourceIsSmall)
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

    private func detailsCard(_ summary: PhotoCheckSummary) -> some View {
        let measuredOpen = showMeasured ?? (summary.headline != .good)
        let byEye = model.document.byEyeChecks
        let worst = summary.worstState
        return VStack(spacing: 0) {
            if !summary.rows.isEmpty {
                disclosureRow(symbol: StatusStyle.symbol(for: worst), color: StatusStyle.color(for: worst),
                              title: summary.attention.isEmpty
                                  ? Text("Everything measured looks fine")
                                  : Text("^[\(summary.attention.count) thing](inflect: true) to look at"),
                              subtitle: nil, isOpen: measuredOpen, identifier: "measuredRow") {
                    showMeasured = !measuredOpen
                }
                if measuredOpen {
                    VStack(alignment: .leading, spacing: Design.Spacing.control) {
                        ForEach(summary.rows) { row in measuredRow(row) }
                    }
                    .padding(.horizontal).padding(.bottom, Design.Spacing.cardContent)
                }
            }
            if !byEye.isEmpty {
                if !summary.rows.isEmpty { Divider().padding(.leading) }
                disclosureRow(symbol: StatusStyle.symbol(for: .manualCheck), color: StatusStyle.color(for: .manualCheck),
                              title: Text("^[\(byEye.count) thing](inflect: true) to check by eye"),
                              subtitle: Text(verbatim: byEye.prefix(2).map(DocumentPresentation.check).joined(separator: " · ")),
                              isOpen: showByEye, identifier: "byEyeRow") {
                    showByEye.toggle()
                }
                if showByEye {
                    VStack(alignment: .leading, spacing: Design.Spacing.row) {
                        ForEach(byEye, id: \.self) { id in
                            Label { Text(DocumentPresentation.check(id)) } icon: {
                                Image(systemName: "circle").foregroundStyle(.tertiary)
                            }
                        }
                        Text("The office that receives the photo decides whether to accept it.")
                            .font(Design.Typography.note).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal).padding(.bottom, Design.Spacing.cardContent)
                }
            }
        }
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
    }

    private func disclosureRow(symbol: String, color: Color, title: Text, subtitle: Text?, isOpen: Bool,
                               identifier: String, toggle: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(reduceMotion ? nil : .default) { toggle() } }) {
            HStack(spacing: Design.Spacing.control) {
                Image(systemName: symbol).foregroundStyle(color).frame(width: 24)
                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                    title.foregroundStyle(.primary)
                    if let subtitle, !isOpen {
                        subtitle.font(Design.Typography.note).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
            }
            .padding(.horizontal)
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOpen ? Text("Expanded") : Text("Collapsed"))
        .accessibilityIdentifier(identifier)
    }

    private func measuredRow(_ row: PhotoCheckSummary.Row) -> some View {
        HStack(alignment: .top, spacing: Design.Spacing.control) {
            Image(systemName: StatusStyle.symbol(for: row.state))
                .foregroundStyle(StatusStyle.color(for: row.state))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(row.title).font(Design.Typography.rowTitle)
                Text(row.detail).font(Design.Typography.note).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(String(localized: row.title)), \(String(localized: StatusStyle.name(for: row.state))). \(String(localized: row.detail))"))
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

    private var actions: some View {
        VStack(spacing: Design.Spacing.control) {
            Button { path.append(.outputChoice(photoID)) } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .brandProminentButtonStyle()
            .controlSize(.large)
            .disabled(model.activity != nil)
            .accessibilityIdentifier("continueFromCheck")
            Button {
                // An unlocked photo is final (ADR-048 §5): warn before it is locked again.
                if model.entries.first(where: { $0.id == photoID })?.isUnlocked == true { confirmEdit = true } else { showAdjust = true }
            } label: {
                Text("Adjust").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("adjust")
        }
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
