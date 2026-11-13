import OSLog
import SwiftUI

/// Step 0 (design 1b): the printed result as the hero, one promise, the document, and one dominant action.
struct HomeView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    /// First launch in a region without a profile: ask "What is the photo for?" once.
    var promptForDocument = false
    @State private var showRequirements = false
    @State private var showDocuments = false
    @State private var showSettings = false
    @State private var showCredits = false
    /// The photo about to be removed from Home, or all of them; drives the confirmation.
    @State private var pendingRemoval: Removal?
    @State private var appIcon = AppIconController()
    /// Which sample person the hero shows; a tap on the sample brings the next one (easter egg).
    @State private var sampleIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(DocumentStore.promptShownKey) private var documentPromptShown = false
    @AppStorage(DeveloperMode.key) private var developerMode = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.zoomNamespace) private var zoomNamespace
    private static let signposter = OSSignposter(subsystem: "com.jarbasferro.calipic", category: "App")

    private enum Removal: Equatable { case one(UUID), all }

    private var isBusy: Bool { !model.isInitialized || model.activity != nil || !model.canAddPhoto }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.sectionTight) {
                hero
                Text("Take it at home.\nPrint it yourself.")
                    .font(Design.Typography.hero)
                    .accessibilityAddTraits(.isHeader)

                if !model.isInitialized {
                    ProgressView("Preparing private photo storage…")
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

                if !model.entries.isEmpty { sessionCard }
                documentCard
                if dynamicTypeSize.isAccessibilitySize { actions }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Design.Surface.screen)
        .tutorialCoach(coachCard)
        .animation(reduceMotion ? nil : .smooth, value: model.tutorial.state)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                actions
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.text)
                    .background(Design.Surface.screen)
            }
        }
        .navigationTitle(Text(verbatim: "Calipic"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "ellipsis") { showSettings = true }
                    .brandNeutralToolbarItem()
                    .accessibilityIdentifier("settingsButton")
            }
        }
        .sheet(isPresented: $showRequirements) { RequirementsView(document: model.document) }
        // Looking at the document list counts as confirming it in the tutorial.
        .sheet(isPresented: $showDocuments, onDismiss: { if model.tutorial.isActive { model.tutorial.confirmDocument() } }) {
            DocumentPickerView(model: model)
        }
        .sheet(isPresented: $showSettings) { SettingsView(appIcon: appIcon, credits: model.credits, tutorial: model.tutorial) }
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .confirmationDialog(pendingRemoval == .all ? Text("Remove all photos and their copies on the sheet?")
                                                   : Text("Remove this photo and its copies on the sheet?"),
                            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
                            titleVisibility: .visible, presenting: pendingRemoval) { removal in
            Button(removal == .all ? LocalizedStringKey("Remove All Photos") : LocalizedStringKey("Remove Photo"), role: .destructive) {
                switch removal {
                case .one(let id):
                    model.selectedID = id
                    model.removePhoto()
                case .all:
                    for id in model.entries.map(\.id) {
                        model.selectedID = id
                        model.removePhoto()
                    }
                }
            }
            .accessibilityIdentifier("confirmRemovePhoto")
        } message: { _ in Text("The original in your photo library is kept.") }
        // On a new install the question waits for the welcome page to close.
        .task(id: model.tutorial.needsWelcome) {
            guard promptForDocument, !documentPromptShown, !model.tutorial.needsWelcome else { return }
            documentPromptShown = true
            showDocuments = true
        }
        .onAppear { Self.signposter.emitEvent("HomeAppeared") }
    }

    // MARK: - Tutorial (ADR-052)

    private var coachStep: TutorialStep? {
        guard model.tutorial.isActive else { return nil }
        return TutorialFlow.step(on: .home, documentConfirmed: model.tutorial.state.documentConfirmed,
                                 hasPhoto: !model.entries.isEmpty, unlocked: false)
    }

    private var coachCard: CoachCard? {
        guard let step = coachStep else { return nil }
        let output = model.document.primaryOutput
        let hasPhoto = !model.entries.isEmpty && step == .photo
        var card = CoachCard(step: hasPhoto ? .check : step, steps: TutorialFlow.steps(for: output),
                             title: TutorialCopy.title(step, output: output, hasPhoto: hasPhoto),
                             message: TutorialCopy.message(step, output: output, hasPhoto: hasPhoto, route: nil))
        if step == .document {
            card.actionTitle = "Continue"
            card.action = { model.tutorial.confirmDocument() }
        } else if hasPhoto, let first = model.entries.first {
            // Back on Home with a photo in progress: pick up at its Photo Check.
            card.actionTitle = "Continue"
            card.action = { path = [.check(first.id)] }
        }
        return card
    }

    // MARK: - Hero

    /// Generated sample people (D-9): a selfie card and an ID photo each. The first is the default.
    private static let samples: [(selfie: String, portrait: String)] =
        [("SampleSelfie", "SamplePortrait")] + (1...8).map { ("SampleSelfie-\($0)", "SamplePortrait-\($0)") }

    /// Resting angles and offsets for the three papers, one set per sample, so each swap lands them slightly
    /// differently on the mat (selfie, sheet, photo).
    private static let poses: [(selfie: Double, sheet: Double, photo: Double, nudge: CGFloat)] = [
        (-6, 3, -3, 0), (-3, 5, -6, 4), (-8, 2, -1, -3), (-4, 4, -5, 2), (-7, 1, -2, -4),
        (-2, 4, -4, 3), (-5, 2, -7, -2), (-9, 3, -2, 1), (-3, 1, -5, -1)]

    /// The whole job in one picture: a selfie, the ID photo made from it, and the sheet of copies (U10).
    /// A sample person until the person has a photo, then their own original, photo, and copies.
    private var hero: some View {
        let entry = model.entries.last
        let pose = Self.poses[entry == nil ? sampleIndex % Self.poses.count : 0]
        return ZStack {
            RoundedRectangle(cornerRadius: Design.Radius.group).fill(Design.Surface.stage)
            // The selfie, as taken: a phone photo at the back.
            heroSelfie(entry)
                .frame(width: 150, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white, lineWidth: 3))
                .paperDimmedInDark()
                .paperShadow()
                .rotationEffect(.degrees(pose.selfie))
                .offset(x: -84 + pose.nudge, y: -50)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<2, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<4, id: \.self) { _ in
                            heroPhoto(entry).frame(width: 34)
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: 3))
            .paperDimmedInDark()
            .paperShadow()
            .rotationEffect(.degrees(pose.sheet))
            .offset(x: 66 - pose.nudge / 2, y: 14)
            // The ID photo, in front: what the selfie becomes.
            heroPhoto(entry)
                .frame(width: 96)
                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.photo))
                .paperDimmedInDark()
                .paperShadow()
                .rotationEffect(.degrees(pose.photo))
                .offset(x: -58 - pose.nudge, y: 44)
        }
        .frame(height: 236)
        .contentShape(Rectangle())
        .onTapGesture { if entry == nil { nextSample() } }
        .sensoryFeedback(.impact(weight: .light), trigger: sampleIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry == nil ? Text("Example: a selfie, the ID photo made from it, and a printed sheet of copies")
                                         : Text("Your photo and its printed sheet"))
        .accessibilityAction(named: Text("Show another example")) { if entry == nil { nextSample() } }
        .accessibilityIdentifier("homeHero")
    }

    /// Easter egg: the papers shuffle a little on the mat while the next sample person fades in.
    private func nextSample() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(duration: 0.55, bounce: 0.35)) {
            sampleIndex = (sampleIndex + 1) % Self.samples.count
        }
    }

    @ViewBuilder private func heroSelfie(_ entry: PhotoEntry?) -> some View {
        if let entry {
            Image(decorative: entry.photo.preview, scale: 1).resizable().scaledToFill()
        } else {
            Image(Self.samples[sampleIndex].selfie).resizable().scaledToFill()
                .id(sampleIndex)
                .transition(.opacity)
        }
    }

    @ViewBuilder private func heroPhoto(_ entry: PhotoEntry?) -> some View {
        let format = model.renderTarget.format
        if let entry {
            PortraitView(entry: entry, format: format)
        } else {
            // The sample keeps its own proportions (26:32); it is an example, not the chosen document.
            Image(Self.samples[sampleIndex].portrait).resizable().aspectRatio(488.0 / 600.0, contentMode: .fit)
                .id(sampleIndex)
                .transition(.opacity)
        }
    }

    // MARK: - Cards

    /// People already in the session: faces, copies, and the way back into the sheet.
    private var sessionCard: some View {
        HStack(spacing: 0) {
            Button { path.append(.sheet) } label: {
                HStack(spacing: Design.Spacing.cardContent) {
                    HStack(spacing: -10) {
                        ForEach(Array(model.entries.prefix(4).enumerated()), id: \.element.id) { index, entry in
                            Image(decorative: entry.photo.preview, scale: 1)
                                .resizable().scaledToFill()
                                .frame(width: Design.Size.thumbnail, height: Design.Size.thumbnail)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Design.Surface.card, lineWidth: Design.Stroke.separation))
                                .accessibilityIdentifier("face-\(index + 1)")
                        }
                    }
                    VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                        Text("Your sheet").font(Design.Typography.cardTitle)
                        Text("^[\(model.entries.count) person](inflect: true) · ^[\(model.layout.placedCount) copy](inflect: true) · \(PaperNames.name(for: model.printJob.paper))")
                            .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.leading).padding(.vertical)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text("Your sheet: \(model.entries.count) people, \(model.layout.placedCount) copies"))
            .accessibilityHint("Opens the print sheet.")
            .accessibilityIdentifier("yourSheet")
            .zoomSource(.sheet, at: 0, in: zoomNamespace)
            // Removing a photo from here, without opening Photo Check (founder, 0.20 review).
            Menu {
                ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in
                    Button(role: .destructive) { pendingRemoval = .one(entry.id) } label: {
                        Label(model.entries.count > 1 ? LocalizedStringKey("Remove Photo \(index + 1)") : LocalizedStringKey("Remove Photo"),
                              systemImage: "trash")
                    }
                }
                if model.entries.count > 1 {
                    Button(role: .destructive) { pendingRemoval = .all } label: {
                        Label("Remove All Photos", systemImage: "trash.slash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold)).foregroundStyle(.secondary)
                    .frame(width: Design.Size.minimumTarget + 8, height: Design.Size.minimumTarget + 8)
                    .contentShape(Rectangle())
            }
            .disabled(model.activity != nil)
            .accessibilityLabel(Text("Photo options"))
            .accessibilityIdentifier("sessionMenu")
        }
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
    }

    /// The document the photo is for, and its requirements, as one grouped card.
    private var documentCard: some View {
        VStack(spacing: 0) {
            Button { showDocuments = true } label: {
                HStack(spacing: Design.Spacing.control) {
                    if let profile = model.document.profile {
                        Text(verbatim: DocumentPresentation.flag(profile)).font(.title2).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                        Text(DocumentPresentation.name(model.document)).foregroundStyle(.primary)
                        Text(DocumentPresentation.detail(model.document))
                            .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .padding(.horizontal).padding(.vertical, Design.Spacing.control)
                .frame(minHeight: Design.Size.minimumTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Chooses the country and document, or a custom size.")
            .coachTarget(coachStep == .document, cornerRadius: Design.Radius.group)
            .accessibilityIdentifier("documentCard")
            Divider().padding(.leading)
            Button { showRequirements = true } label: {
                HStack {
                    Text("Photo requirements").foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("requirementsLink")
        }
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
    }

    // MARK: - Actions and footer

    private var actions: some View {
        VStack(spacing: Design.Spacing.tight) {
            Button {
                if model.tutorial.isActive { model.tutorial.confirmDocument() }
                acquire(.camera, model.entries.isEmpty ? .replace : .add)
            } label: {
                Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity)
            }
            .brandProminentButtonStyle()
            .controlSize(.large)
            .disabled(isBusy)
            .coachTarget(coachStep == .photo && model.entries.isEmpty)
            .accessibilityIdentifier("takePhoto")
            Button("Choose from Library") {
                if model.tutorial.isActive { model.tutorial.confirmDocument() }
                acquire(.library, model.entries.isEmpty ? .replace : .add)
            }
                .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
                .disabled(isBusy)
                .accessibilityIdentifier("choosePhoto")
            footer
        }
    }

    /// Credits and privacy in plain sight (ADR-048 §8), and the version (AGENTS.md §17).
    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your photos stay on your iPhone.")
                .font(Design.Typography.note)
                .foregroundStyle(.secondary)
            HStack(alignment: .center) {
                Button { showCredits = true } label: {
                    Text(CreditsPresentation.count(model.credits.balance))
                        .font(Design.Typography.note.weight(.semibold))
                        .frame(minHeight: Design.Size.minimumTarget)
                        .contentShape(Rectangle())
                }
                .accessibilityHint("Shows your credits and how to get more.")
                .accessibilityIdentifier("creditsButton")
                Spacer(minLength: Design.Spacing.control)
                Text(developerMode ? "\(AppVersion.display) · developer details on" : AppVersion.display)
                    .font(Design.Typography.noteDigits)
                    .foregroundStyle(.tertiary)
                    .frame(minHeight: Design.Size.minimumTarget)
                    .contentShape(Rectangle())
                    .accessibilityLabel(Text("Version \(AppVersion.display)"))
                    .accessibilityIdentifier("appVersion")
                    .onLongPressGesture(minimumDuration: 1.2) { developerMode.toggle() }
                    .sensoryFeedback(.impact(weight: .light), trigger: developerMode)
            }
            if developerMode, let metrics = model.lastCameraMetrics {
                Text("Camera: start \(metrics.startupMilliseconds ?? 0) ms · capture \(metrics.captureMilliseconds ?? 0) ms")
                    .font(Design.Typography.noteDigits).foregroundStyle(.tertiary)
                    .accessibilityIdentifier("cameraMetrics")
            }
        }
    }
}

/// Settings & About (S-19): durable things that are not part of making a photo.
struct SettingsView: View {
    let appIcon: AppIconController
    let credits: CreditStore
    var tutorial: TutorialCoach?
    @AppStorage(DeveloperMode.key) private var developerMode = false
    @Environment(\.dismiss) private var dismiss
    @State private var showAppIcons = false
    @State private var showCredits = false
    @ScaledMetric(relativeTo: .body) private var iconSide: CGFloat = Design.Size.settingsIcon

    var body: some View {
        NavigationStack {
            List {
                if appIcon.isSupported {
                    Section {
                        Button { showAppIcons = true } label: {
                            HStack(spacing: Design.Spacing.control) {
                                Image(appIcon.current.previewAssetName)
                                    .resizable()
                                    .frame(width: iconSide, height: iconSide)
                                    .accessibilityHidden(true)
                                Text("App Icon").foregroundStyle(.primary)
                                Spacer()
                                Text(appIcon.current.label).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("App Icon"))
                        .accessibilityValue(Text(appIcon.current.label))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier("appIconRow")
                    }
                }
                Section {
                    Button { showCredits = true } label: {
                        HStack {
                            Text("Credits").foregroundStyle(.primary)
                            Spacer()
                            Text(CreditsPresentation.count(credits.balance)).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("settingsCredits")
                }
                // Developer details only: walk the first-photo guide again on a device that already finished it.
                if developerMode, let tutorial {
                    Section {
                        Button("Restart the First-Photo Guide") { tutorial.restart(); dismiss() }
                            .accessibilityIdentifier("restartTutorial")
                    } footer: {
                        Text("Developer details are on. Credits are not changed.")
                    }
                }
                Section("Privacy") {
                    Text("Calipic works on your iPhone. No account, no ads, and nothing is uploaded.")
                }
                Section("About") {
                    LabeledContent("Version", value: AppVersion.display)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(isPresented: $showAppIcons) { AppIconPickerView(controller: appIcon) }
        .sheet(isPresented: $showCredits) { CreditsView(credits: credits) }
    }
}

struct RequirementsView: View {
    let document: DocumentChoice
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            RequirementsContent(document: document)
            .navigationTitle("Photo requirements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// Requirements for the chosen document, built from its catalog profile and sources; never literal rule text.
struct RequirementsContent: View {
    let document: DocumentChoice

    var body: some View {
        List {
            Section {
                Label("Recent colour photo, facing forward", systemImage: "person.crop.rectangle")
                Label(Self.backgroundLine(document), systemImage: "rectangle")
                Label("Face and eyes clearly visible, neutral expression", systemImage: "eye")
                Label("Even light from the front, no strong shadows", systemImage: "sun.max")
            } header: {
                Text(DocumentPresentation.name(document))
            } footer: {
                Text(DocumentPresentation.detail(document))
            }
            if let profile = document.profile {
                if !profile.checks.isEmpty {
                    Section("Check by eye") {
                        ForEach(profile.checks, id: \.id) { check in
                            Label(DocumentPresentation.check(check.id), systemImage: "checkmark.circle")
                        }
                    }
                }
                Section("Official sources") {
                    ForEach(profile.sources, id: \.sourceId) { source in
                        if let url = URL(string: source.url) {
                            Link(destination: url) {
                                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                                    Text(verbatim: source.authorityName)
                                    Text(verbatim: source.title).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Text("Sources reviewed \(Self.reviewed(profile)). Requirements can change, and the receiving office decides acceptance.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("What the app does") {
                    Text("Frames the photo to \(DocumentPresentation.size(document)), levels the eyes, and prepares the files. It can replace the background and even out light and colour. It does not retouch your face or decide acceptance.")
                }
            } else {
                Section("Custom size") {
                    Text("No official rules apply. Use the size your school or organisation asked for.")
                }
            }
        }
    }

    static func backgroundLine(_ document: DocumentChoice) -> LocalizedStringKey {
        switch document.profile?.background.requiredAppearance {
        case "white", "white_or_off_white": "Plain, uniform white background"
        case "light", "specified_colors": "Plain, uniform light background"
        default: "Plain, uniform background"
        }
    }

    static func lightLine(_ document: DocumentChoice) -> LocalizedStringKey {
        switch document.profile?.background.requiredAppearance {
        case "white", "white_or_off_white": "Use even light and a plain white background"
        case "light", "specified_colors": "Use even light and a plain, light background"
        default: "Use even light and a plain background"
        }
    }

    static func reviewed(_ profile: DocumentProfile) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: profile.effective.lastReviewed) else { return profile.effective.lastReviewed }
        return date.formatted(date: .long, time: .omitted)
    }
}
