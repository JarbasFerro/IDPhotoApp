import SwiftUI

/// Names and short descriptions for documents, localized from the String Catalog. No rule text lives in views:
/// everything comes from the catalog profile (AGENTS.md §11).
enum DocumentPresentation {
    static func name(_ document: DocumentChoice) -> String {
        switch document {
        case .official(let profile): String(localized: String.LocalizationValue(profile.document.nameKey))
        case .custom: String(localized: "Custom size")
        }
    }

    /// "26 × 32 mm", "2 × 2 in" for whole quarter inches, or pixels for digital-only documents.
    static func size(_ document: DocumentChoice) -> String {
        if let profile = document.profile, profile.referenceFrameMm == nil, let digital = profile.digitalOutput,
           let width = digital.pixelWidth, let height = digital.pixelHeight {
            return String(localized: "\(width) × \(height) px")
        }
        return size(widthMM: document.format.widthMM, heightMM: document.format.heightMM)
    }

    static func size(widthMM: Double, heightMM: Double) -> String {
        let quarters = (widthMM / 25.4 * 4, heightMM / 25.4 * 4)
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))
        if abs(quarters.0 - quarters.0.rounded()) < 0.01, abs(quarters.1 - quarters.1.rounded()) < 0.01 {
            let width = (widthMM / 25.4).formatted(style), height = (heightMM / 25.4).formatted(style)
            return String(localized: "\(width) × \(height) in")
        }
        let millimetres = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        return String(localized: "\(widthMM.formatted(millimetres)) × \(heightMM.formatted(millimetres)) mm")
    }

    static func detail(_ document: DocumentChoice) -> String {
        guard let profile = document.profile else {
            return String(localized: "\(size(document)) · no official rules")
        }
        return "\(size(document)) · \(background(profile.background.requiredAppearance))"
    }

    static func background(_ appearance: String) -> String {
        switch appearance {
        case "white": String(localized: "white background")
        case "white_or_off_white": String(localized: "white or off-white background")
        case "light", "specified_colors": String(localized: "light background")
        default: String(localized: "plain background")
        }
    }

    static func group(_ profile: DocumentProfile) -> String {
        if let code = profile.jurisdiction.countryCode {
            return Locale.current.localizedString(forRegionCode: code) ?? code
        }
        return String(localized: "Schengen area")
    }

    /// The key is built as a plain String first: an interpolated literal would look up "check.%@" instead.
    static func check(_ id: String) -> String {
        let key = "check." + id
        return String(localized: String.LocalizationValue(key))
    }

    static func shortcut(_ shortcut: CustomSizeShortcut, locale: Locale = .current) -> String {
        let language = locale.language.languageCode?.identifier ?? ""
        let region = locale.region?.identifier ?? ""
        let key = shortcut.localeNameKeys["\(language)-\(region)"] ?? shortcut.nameKey
        return String(localized: String.LocalizationValue(key))
    }
}

/// Choose the document for the session: official profiles grouped by country, or a custom size.
struct DocumentPickerView: View {
    @Bindable var model: PhotoWorkflow
    var catalog: ProfileCatalog = .bundled
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var groups: [(name: String, profiles: [DocumentProfile])] {
        let matching = catalog.profiles.filter { profile in
            query.isEmpty
                || DocumentPresentation.name(.official(profile)).localizedStandardContains(query)
                || DocumentPresentation.group(profile).localizedStandardContains(query)
                || (profile.document.localName?.localizedStandardContains(query) ?? false)
        }
        let grouped = Dictionary(grouping: matching, by: DocumentPresentation.group)
        return grouped.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { (name: $0, profiles: grouped[$0]!.sorted { DocumentPresentation.name(.official($0)) < DocumentPresentation.name(.official($1)) }) }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        NavigationLink {
                            CustomSizeView(model: model, catalog: catalog) { dismiss() }
                        } label: {
                            row(title: String(localized: "Custom size"),
                                detail: String(localized: "Any size, for school, work, or a club. No official rules."),
                                selected: model.document.isCustom)
                        }
                        .accessibilityIdentifier("customSizeRow")
                    }
                }
                ForEach(groups, id: \.name) { group in
                    Section(group.name) {
                        ForEach(group.profiles) { profile in
                            let choice = DocumentChoice.official(profile)
                            Button {
                                model.setDocument(choice)
                                dismiss()
                            } label: {
                                row(title: DocumentPresentation.name(choice), detail: DocumentPresentation.detail(choice),
                                    selected: model.document.id == choice.id)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("profile-\(profile.profileId)")
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: Text("Country or document"))
            .overlay {
                if !query.isEmpty, groups.isEmpty { ContentUnavailableView.search(text: query) }
            }
            .navigationTitle("Choose document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func row(title: String, detail: String, selected: Bool) -> some View {
        HStack(spacing: Design.Spacing.row) {
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(title).foregroundStyle(.primary)
                Text(detail).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if selected {
                Image(systemName: "checkmark").foregroundStyle(Color.brandAccent)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A photo size the person types or picks from shortcuts. No country, no rules, no compliance claim (ADR-018).
struct CustomSizeView: View {
    @Bindable var model: PhotoWorkflow
    let catalog: ProfileCatalog
    let onDone: () -> Void

    enum Unit: String, CaseIterable, Identifiable { case millimetres, inches; var id: String { rawValue } }

    @State private var unit: Unit = Locale.current.measurementSystem == .us ? .inches : .millimetres
    @State private var width: Double?
    @State private var height: Double?

    private var factor: Double { unit == .inches ? 25.4 : 1 }
    private var widthMM: Double? { width.map { $0 * factor } }
    private var heightMM: Double? { height.map { $0 * factor } }
    private var isValid: Bool {
        guard let widthMM, let heightMM else { return false }
        return DocumentChoice.customSizeRange.contains(widthMM) && DocumentChoice.customSizeRange.contains(heightMM)
    }

    var body: some View {
        Form {
            Section {
                Picker("Unit", selection: $unit) {
                    Text("mm").tag(Unit.millimetres)
                    Text("in").tag(Unit.inches)
                }
                .pickerStyle(.segmented)
                LabeledContent("Width") {
                    TextField("Width", value: $width, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("customWidth")
                }
                LabeledContent("Height") {
                    TextField("Height", value: $height, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("customHeight")
                }
            } footer: {
                Text("Use the size your school or organisation asked for. Each side between 10 and 100 mm.")
            }
            if !catalog.customSizes.shortcuts.isEmpty {
                Section("Common sizes") {
                    ForEach(catalog.customSizes.shortcuts) { shortcut in
                        Button(DocumentPresentation.shortcut(shortcut)) {
                            unit = .millimetres
                            width = shortcut.widthMm
                            height = shortcut.heightMm
                        }
                        .accessibilityIdentifier("shortcut-\(shortcut.id)")
                    }
                }
            }
            Section {
                Text("Calipic frames the photo and checks sharpness, eyes, and light. It doesn't check any official rules for a custom size.")
                    .font(Design.Typography.note).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Custom size")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case let .custom(w, h) = model.document { unit = .millimetres; width = w; height = h }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                guard let widthMM, let heightMM else { return }
                model.setDocument(.custom(widthMM: (widthMM * 10).rounded() / 10, heightMM: (heightMM * 10).rounded() / 10))
                onDone()
            } label: {
                Text("Use This Size").frame(maxWidth: .infinity)
            }
            .brandProminentButtonStyle()
            .controlSize(.large)
            .disabled(!isValid)
            .padding()
            .background(.bar)
            .accessibilityIdentifier("useCustomSize")
        }
    }
}
