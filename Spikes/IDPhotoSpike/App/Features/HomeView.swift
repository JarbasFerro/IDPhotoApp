import SwiftUI

/// Step 0: start immediately. One dominant action, the document, and the session if there is one.
struct HomeView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var showRequirements = false
    @State private var showAppIcons = false
    @State private var appIcon = AppIconController()
    @ScaledMetric(relativeTo: .footnote) private var appIconRowSide: CGFloat = Design.Size.settingsIcon
    @AppStorage(DeveloperMode.key) private var developerMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.section) {
                VStack(alignment: .leading, spacing: Design.Spacing.text) {
                    Text("A correct ID photo in a minute.")
                        .font(Design.Typography.screenTitle)
                    Text("Take it or choose one. The app frames it, whitens the background and prepares the print sheet. Everything stays on your iPhone.")
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

                VStack(alignment: .leading, spacing: Design.Spacing.caption) {
                    Label("Your photos stay on your iPhone.", systemImage: "lock")
                    Text("The app formats the photo. Acceptance is decided by the office that receives it.")
                }
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
        .sheet(isPresented: $showRequirements) { RequirementsView() }
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
        Button { showRequirements = true } label: {
            HStack(spacing: Design.Spacing.cardContent) {
                Image(systemName: "person.text.rectangle")
                    .font(Design.Typography.titleGlyph)
                    .frame(width: Design.Size.thumbnail, height: Design.Size.thumbnail)
                    .background(.fill.secondary, in: RoundedRectangle(cornerRadius: Design.Radius.tile))
                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                    Text("Spain · DNI and passport").font(Design.Typography.cardTitle)
                    Text("26 × 32 mm · white background").font(Design.Typography.cardDetail).foregroundStyle(.secondary)
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
        .accessibilityHint("Shows the photo requirements.")
        .accessibilityIdentifier("documentCard")
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
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Before you take the photo") {
                    Label("Recent colour photo, facing forward", systemImage: "person.crop.rectangle")
                    Label("Plain, light background; the app makes it white", systemImage: "rectangle")
                    Label("Face and eyes clearly visible, neutral expression", systemImage: "eye")
                    Label("No headphones, hats or sunglasses", systemImage: "headphones")
                    Label("Even light from the front, no strong shadows", systemImage: "sun.max")
                }
                Section("Official guidance") {
                    Text("The DNI guidance includes medical and religious exceptions for head coverings and glasses. Review the source for your situation.")
                    Link("Spanish Ministry of the Interior", destination: URL(string:
                        "https://www.interior.gob.es/opencms/es/servicios-al-ciudadano/tramites-y-gestiones/dni/documentacion-necesaria-para-su-tramitacion/")!)
                    Text("Source reviewed September 15, 2026. Other document types may have different requirements.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("What the app does") {
                    Text("Frames the photo to 26 × 32 mm, levels the eyes, replaces the background with white, corrects exposure and colour, and prepares a print sheet. It does not retouch your face and does not decide acceptance.")
                }
            }
            .navigationTitle("Photo requirements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
