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
    @State private var appIcon = AppIconController()
    @AppStorage(DocumentStore.promptShownKey) private var documentPromptShown = false
    @AppStorage(DeveloperMode.key) private var developerMode = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        .sheet(isPresented: $showDocuments) { DocumentPickerView(model: model) }
        .sheet(isPresented: $showSettings) { SettingsView(appIcon: appIcon, credits: model.credits) }
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .task {
            guard promptForDocument, !documentPromptShown else { return }
            documentPromptShown = true
            showDocuments = true
        }
    }

    // MARK: - Hero

    /// One photo and the sheet of copies it becomes. A sample until the person has a photo, then their own.
    private var hero: some View {
        let entry = model.entries.last
        return ZStack {
            RoundedRectangle(cornerRadius: Design.Radius.group).fill(Design.Surface.stage)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach(0..<2, id: \.self) { _ in
                    GridRow {
                        ForEach(0..<4, id: \.self) { _ in
                            heroPhoto(entry).frame(width: 36)
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(.white, in: RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.16), radius: 12, y: 8)
            .rotationEffect(.degrees(3))
            .offset(x: 46, y: -8)
            heroPhoto(entry)
                .frame(width: 100)
                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.photo))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
                .rotationEffect(.degrees(-4))
                .offset(x: -98, y: 38)
        }
        .frame(height: 236)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry == nil ? Text("Example: one photo and a printed sheet of copies") : Text("Your photo and its printed sheet"))
        .accessibilityIdentifier("homeHero")
    }

    @ViewBuilder private func heroPhoto(_ entry: PhotoEntry?) -> some View {
        let format = model.renderTarget.format
        if let entry {
            PortraitView(entry: entry, format: format)
        } else {
            // The sample keeps its own proportions (26:32); it is an example, not the chosen document.
            Image("SamplePortrait").resizable().aspectRatio(488.0 / 600.0, contentMode: .fit)
        }
    }

    // MARK: - Cards

    /// People already in the session: faces, copies, and the way back into the sheet.
    private var sessionCard: some View {
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
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding()
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("Your sheet: \(model.entries.count) people, \(model.layout.placedCount) copies"))
        .accessibilityHint("Opens the print sheet.")
        .accessibilityIdentifier("yourSheet")
    }

    /// The document the photo is for, and its requirements, as one grouped card.
    private var documentCard: some View {
        VStack(spacing: 0) {
            Button { showDocuments = true } label: {
                HStack(spacing: Design.Spacing.control) {
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
            Button { acquire(.camera, model.entries.isEmpty ? .replace : .add) } label: {
                Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity)
            }
            .brandProminentButtonStyle()
            .controlSize(.large)
            .disabled(isBusy)
            .accessibilityIdentifier("takePhoto")
            Button("Choose from Library") { acquire(.library, model.entries.isEmpty ? .replace : .add) }
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
