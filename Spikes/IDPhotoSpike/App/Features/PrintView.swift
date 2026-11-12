import SwiftUI

/// Step 4 (designs 4a and 5d): the job here is printing. The three things that make a print come out right are the
/// content of the screen; unlocking with credits happens in place, before any file is made.
struct PrintView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    @State private var pending: Action?
    @State private var showShop = false
    @State private var showFormats = false
    @State private var showCredits = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum Action { case home, shop, formats }

    private var locked: Int { model.lockedCount }
    private var shopOnly: Bool { model.document.printIsShopOnly }
    private var canPrintAtHome: Bool { PrintController.isAvailable && !shopOnly }
    private var isWorking: Bool { model.activity == .exporting }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.sectionTight) {
                header
                steps
                if dynamicTypeSize.isAccessibilitySize { actions }
            }
            .padding(.horizontal)
            .padding(.vertical, Design.Spacing.text)
        }
        .background(Design.Surface.screen)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                actions
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.text)
                    .padding(.bottom, Design.Spacing.caption)
                    .background(Design.Surface.screen)
            }
        }
        .navigationTitle("Print")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if locked == 0 {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { path.removeAll() }.accessibilityIdentifier("shareDone")
                }
            }
        }
        .sheet(isPresented: $showShop) { if let result = model.exported { ShopPrintView(model: model, result: result) } }
        .sheet(isPresented: $showFormats) { if let result = model.exported { FormatsView(result: result) } }
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .task { model.refreshSheetThumbnails() }
        .onChange(of: model.exported?.id) { _, _ in
            guard let result = model.exported, let action = pending else { return }
            pending = nil
            perform(action, result)
        }
        .onChange(of: model.errorMessage) { _, message in if message != nil { pending = nil } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: locked == 0)
    }

    // MARK: - Content

    private var header: some View {
        let layout = model.layout
        // A landscape page is kept lower so the title beside it still has room.
        let landscape = layout.pages.first.map { $0.widthMM > $0.heightMM } ?? false
        return HStack(alignment: .center, spacing: Design.Spacing.group) {
            SheetPreview(layout: layout, thumbnails: model.sheetThumbnails, compact: true, compactHeight: landscape ? 84 : 130)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Image(systemName: "checkmark.circle.fill")
                    .font(Design.Typography.titleGlyph)
                    .foregroundStyle(StatusStyle.pass)
                    .accessibilityHidden(true)
                Text("Your sheet is ready").font(Design.Typography.screenTitle)
                Text("^[\(layout.placedCount) copy](inflect: true) on \(PaperNames.short(for: model.printJob.paper)) paper")
                    .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("printHeader")
        }
    }

    /// The instructions that decide whether the print comes out at the right size (docs/03-design.md §3).
    private var steps: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            Text("Before you print")
                .font(Design.Typography.note.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, Design.Spacing.tight)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                step(1, title: PaperNames.isPhotoPaper(model.printJob.paper)
                        ? Text("Load \(PaperNames.short(for: model.printJob.paper)) photo paper")
                        : Text("Load \(PaperNames.short(for: model.printJob.paper)) paper"), detail: nil)
                Divider().padding(.leading, 56)
                step(2, title: Text("Choose Actual Size, or 100 %"), detail: Text("Never Fit to Page or borderless"))
                Divider().padding(.leading, 56)
                step(3, title: model.printJob.options.calibrationBar
                        ? Text("Measure the 50 mm line before cutting") : Text("Measure one photo before cutting"),
                     detail: nil)
            }
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            if let note = model.document.printNoteKey {
                Label(String(localized: String.LocalizationValue(note)), systemImage: "storefront")
                    .font(Design.Typography.note)
                    .padding(.horizontal, Design.Spacing.tight)
                    .accessibilityIdentifier("printRouteNote")
            }
        }
    }

    private func step(_ number: Int, title: Text, detail: Text?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.control) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold)).monospacedDigit()
                .foregroundStyle(Color.brandAccent)
                .frame(width: 28, height: 28)
                .background(Color.brandAccent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                title
                if let detail { detail.font(Design.Typography.note).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal).padding(.vertical, Design.Spacing.control)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    @ViewBuilder private var actions: some View {
        VStack(spacing: Design.Spacing.text) {
            if locked > 0 {
                UnlockCard(photos: locked, balance: model.credits.balance)
                if model.credits.canAfford(locked) {
                    Button { unlockAndPrint() } label: {
                        Text(canPrintAtHome ? "Unlock and Print" : "Unlock and Continue").frame(maxWidth: .infinity)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("unlockAndPrint")
                } else {
                    Button { showCredits = true } label: { Text("Get Credits").frame(maxWidth: .infinity) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("getCredits")
                }
                Button("Keep Editing") { path.removeLast() }
                    .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
                    .accessibilityIdentifier("keepEditing")
            } else {
                if canPrintAtHome {
                    Button { run(.home) } label: { label("Print at Home", working: pending == .home) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("printAtHome")
                    Button { run(.shop) } label: { label("Print at a Shop", working: pending == .shop) }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityIdentifier("printAtShop")
                } else {
                    Button { run(.shop) } label: { label("Print at a Shop", working: pending == .shop) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .accessibilityIdentifier("printAtShop")
                }
                Button { run(.formats) } label: { label("More Formats", working: pending == .formats) }
                    .frame(minHeight: Design.Size.minimumTarget)
                    .accessibilityIdentifier("moreFormats")
            }
        }
        .disabled(isWorking && pending != nil)
    }

    private func label(_ title: LocalizedStringKey, working: Bool) -> some View {
        HStack(spacing: Design.Spacing.text) {
            if working { ProgressView() }
            Text(title)
        }
        .frame(maxWidth: .infinity)
    }

    private func unlockAndPrint() {
        guard model.unlockAll() else { showCredits = true; return }
        run(canPrintAtHome ? .home : .shop)
    }

    /// Files are made on demand, once, and only for unlocked photos (the export gate in `PhotoWorkflow`).
    private func run(_ action: Action) {
        if let result = model.exported {
            perform(action, result)
        } else {
            pending = action
            if model.activity == nil { model.prepareExport() }
        }
    }

    private func perform(_ action: Action, _ result: PhotoExport) {
        switch action {
        case .home:
            // UI tests cannot drive the system print panel; everything up to it is covered.
            guard !PrintController.isSuppressedForUITests else { return }
            PrintController.shared.present(pdf: result.pdf, jobName: String(localized: "Calipic sheet"))
        case .shop: showShop = true
        case .formats: showFormats = true
        }
    }
}

/// Printing at a kiosk or print service: one image per page at the paper's size, and how to order it.
struct ShopPrintView: View {
    @Bindable var model: PhotoWorkflow
    let result: PhotoExport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Order a standard print on \(PaperNames.short(for: model.printJob.paper)) paper", systemImage: "1.circle")
                    Label("Ask for no cropping and no Fit to Page", systemImage: "2.circle")
                    Label(model.printJob.options.calibrationBar
                          ? LocalizedStringKey("Measure the 50 mm line before cutting") : LocalizedStringKey("Measure one photo before cutting"),
                          systemImage: "3.circle")
                } footer: {
                    if let note = model.document.printNoteKey {
                        Text(String(localized: String.LocalizationValue(note)))
                    }
                }
                Section {
                    ShareLink(items: result.pages) {
                        Label(result.pages.count == 1 ? "Share Print Image" : "Share Print Images", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("sharePages")
                }
            }
            .navigationTitle("Print at a shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("shopDone") } }
        }
        .presentationDetents([.medium, .large])
    }
}

/// The other files of an unlocked sheet: the print document and each person's digital photo.
struct FormatsView: View {
    let result: PhotoExport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ShareLink(item: result.pdf) { Label("Share Print Document", systemImage: "doc") }
                        .accessibilityIdentifier("sharePDF")
                } footer: {
                    Text("A document with every page at its exact size, for printing from a computer.")
                }
                Section {
                    ForEach(Array(result.jpegs.enumerated()), id: \.offset) { index, url in
                        ShareLink(item: url) {
                            HStack(spacing: Design.Spacing.control) {
                                // Show the actual file being shared, not a possibly stale editor preview.
                                if let image = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: image)
                                        .resizable().scaledToFit()
                                        .frame(width: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .accessibilityHidden(true)
                                }
                                Text(result.jpegs.count == 1 ? LocalizedStringKey("Share Digital Photo") : LocalizedStringKey("Share Digital Photo \(index + 1)"))
                            }
                        }
                        .accessibilityIdentifier(index == 0 ? "shareJPEG" : "shareJPEG-\(index + 1)")
                    }
                    if result.jpegs.count > 1 {
                        ShareLink(items: result.jpegs) { Label("Share All Digital Photos", systemImage: "square.and.arrow.up.on.square") }
                            .accessibilityIdentifier("shareAllJPEGs")
                    }
                } header: {
                    Text(result.jpegs.count == 1 ? "Digital photo" : "Digital photos")
                } footer: {
                    Text("For online forms.")
                }
            }
            .navigationTitle("More formats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("formatsDone") } }
        }
    }
}
