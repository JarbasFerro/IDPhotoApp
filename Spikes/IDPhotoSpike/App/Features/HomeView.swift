import SwiftUI

/// Step 0: start immediately. One dominant action, the document, and the session if there is one.
struct HomeView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var showRequirements = false
    @AppStorage(DeveloperMode.key) private var developerMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A correct ID photo in a minute.")
                        .font(.title2.weight(.semibold))
                    Text("Take it or choose one. The app frames it, whitens the background and prepares the print sheet. Everything stays on your iPhone.")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: 12) {
                    Button { acquire(.camera, model.entries.isEmpty ? .replace : .add) } label: {
                        Label("Take Photo", systemImage: "camera").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
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

                VStack(alignment: .leading, spacing: 6) {
                    Label("Your photos stay on your iPhone.", systemImage: "lock")
                    Text("The app formats the photo. Acceptance is decided by the office that receives it.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                versionLine
            }
            .padding()
        }
        .navigationTitle(Text("Foto carnet"))
        .sheet(isPresented: $showRequirements) { RequirementsView() }
    }

    /// People already in the session: faces, copies, and the way back into the sheet.
    private var sessionCard: some View {
        Button { path.append(.sheet) } label: {
            HStack(spacing: 14) {
                HStack(spacing: -10) {
                    ForEach(Array(model.entries.prefix(4).enumerated()), id: \.element.id) { index, entry in
                        Image(decorative: entry.photo.preview, scale: 1)
                            .resizable().scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 2))
                            .accessibilityIdentifier("face-\(index + 1)")
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your sheet").font(.headline)
                    Text("\(model.entries.count) \(model.entries.count == 1 ? String(localized: "person") : String(localized: "people")) · \(model.layout.placedCount) copies · \(PaperNames.name(for: model.printJob.paper))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
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
            HStack(spacing: 14) {
                Image(systemName: "person.text.rectangle")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.fill.secondary, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spain · DNI and passport").font(.headline)
                    Text("26 × 32 mm · white background").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Shows the photo requirements.")
        .accessibilityIdentifier("documentCard")
    }

    private var versionLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(developerMode ? "\(AppVersion.display) · developer details on" : AppVersion.display)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityLabel(Text("Version \(AppVersion.display)"))
                .accessibilityIdentifier("appVersion")
                .onLongPressGesture(minimumDuration: 1.2) { developerMode.toggle() }
                .sensoryFeedback(.impact(weight: .light), trigger: developerMode)
            if developerMode, let metrics = model.lastCameraMetrics {
                Text("Camera: start \(metrics.startupMilliseconds ?? 0) ms · capture \(metrics.captureMilliseconds ?? 0) ms")
                    .font(.footnote.monospacedDigit()).foregroundStyle(.tertiary)
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
