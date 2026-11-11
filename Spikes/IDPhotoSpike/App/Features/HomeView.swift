import SwiftUI

/// Step 0: start immediately. One dominant action, the document, and the session if there is one.
struct HomeView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var showRequirements = false
    @State private var showDocuments = false
    @State private var showAppIcons = false
    @State private var appIcon = AppIconController()
    @ScaledMetric(relativeTo: .footnote) private var appIconRowSide: CGFloat = Design.Size.settingsIcon
    @AppStorage(DeveloperMode.key) private var developerMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.section) {
                VStack(alignment: .leading, spacing: Design.Spacing.text) {
                    Text("Make an ID photo")
                        .font(Design.Typography.screenTitle)
                    Text("Take a photo or choose one for your document. Save a JPEG or print a sheet.")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: Design.Spacing.control) {
                    Button { acquire(.camera, model.entries.isEmpty ? .replace : .add) } label: {
                        Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .disabled(!model.isInitialized || model.activity != nil || !model.canAddPhoto)
                    .accessibilityIdentifier("takePhoto")
                    Button { acquire(.library, model.entries.isEmpty ? .replace : .add) } label: {
                        Label("Choose Photo", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!model.isInitialized || model.activity != nil || !model.canAddPhoto)
                    .accessibilityIdentifier("choosePhoto")
                }

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

                Label("Your photos stay on your iPhone.", systemImage: "lock")
                .font(Design.Typography.note)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 0) {
                    if appIcon.isSupported { appIconRow }
                    versionLine
                }
            }
            .padding()
        }
        .navigationTitle(Text(verbatim: "Calipic"))
        .sheet(isPresented: $showRequirements) { RequirementsView(document: model.document) }
        .sheet(isPresented: $showDocuments) { DocumentPickerView(model: model) }
        .sheet(isPresented: $showAppIcons) { AppIconPickerView(controller: appIcon) }
    }

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
                            .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: Design.Stroke.separation))
                            .accessibilityIdentifier("face-\(index + 1)")
                    }
                }
                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                    Text("Your sheet").font(Design.Typography.cardTitle)
                    Text("^[\(model.entries.count) person](inflect: true) · ^[\(model.layout.placedCount) copy](inflect: true) · \(PaperNames.name(for: model.printJob.paper))")
                        .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Design.Radius.card))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("Your sheet: \(model.entries.count) people, \(model.layout.placedCount) copies"))
        .accessibilityHint("Opens the print sheet.")
        .accessibilityIdentifier("yourSheet")
    }

    private var documentCard: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.control) {
            Button { showDocuments = true } label: {
                HStack(spacing: Design.Spacing.cardContent) {
                    Image(systemName: model.document.isCustom ? "ruler" : "person.text.rectangle")
                        .font(Design.Typography.titleGlyph)
                        .frame(width: Design.Size.thumbnail, height: Design.Size.thumbnail)
                        .background(.fill.secondary, in: RoundedRectangle(cornerRadius: Design.Radius.tile))
                    VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                        Text(DocumentPresentation.name(model.document)).font(Design.Typography.cardTitle)
                        Text(DocumentPresentation.detail(model.document)).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Change").font(Design.Typography.cardDetail).foregroundStyle(Color.brandAccent)
                }
                .padding()
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Design.Radius.card))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Chooses the country and document, or a custom size.")
            .accessibilityIdentifier("documentCard")
            Button { showRequirements = true } label: {
                HStack(spacing: Design.Spacing.row) {
                    Label("Photo requirements", systemImage: "list.bullet.rectangle")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .font(Design.Typography.note)
                .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("requirementsLink")
        }
    }

    /// Quiet entry to choose-your-icon (BD-038). It lives here, outside the capture → check → print path.
    private var appIconRow: some View {
        Button { showAppIcons = true } label: {
            HStack(spacing: Design.Spacing.row) {
                Image(appIcon.current.previewAssetName)
                    .resizable()
                    .frame(width: appIconRowSide, height: appIconRowSide)
                    .accessibilityHidden(true)
                Text("App Icon")
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .font(Design.Typography.note)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(Text(appIcon.current.label))
        .accessibilityIdentifier("appIconRow")
    }

    private var versionLine: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.tight) {
            Text(developerMode ? "\(AppVersion.display) · developer details on" : AppVersion.display)
                .font(Design.Typography.noteDigits)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityLabel(Text("Version \(AppVersion.display)"))
                .accessibilityIdentifier("appVersion")
                .onLongPressGesture(minimumDuration: 1.2) { developerMode.toggle() }
                .sensoryFeedback(.impact(weight: .light), trigger: developerMode)
            if developerMode, let metrics = model.lastCameraMetrics {
                Text("Camera: start \(metrics.startupMilliseconds ?? 0) ms · capture \(metrics.captureMilliseconds ?? 0) ms")
                    .font(Design.Typography.noteDigits).foregroundStyle(.tertiary)
                    .accessibilityIdentifier("cameraMetrics")
            }
        }
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
