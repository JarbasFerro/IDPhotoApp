import SwiftUI

/// Step 4 (designs 4a and 5d): the job here is printing. The three things that make a print come out right are the
/// content of the screen; unlocking with credits happens in place, before any file is made.
struct PrintView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    @State private var pending: Action?
    /// Home or shop: one choice drives the steps and the main button, so a shop print needs no extra sheet
    /// (founder, 0.20 review: Print at a Shop opened a sheet whose button opened the share sheet).
    /// Nothing is chosen at first: where to print is a decision the person makes (founder, 0.20.9).
    @State private var chosenRoute: PrintCheckView.PrintRoute?
    @State private var showFormats = false
    @State private var showCredits = false
    @State private var showCheck = false
    /// The photo was unlocked on this screen with no route chosen: the cards are scrolled into view and outlined.
    @State private var promptRoute = false
    /// Opacity of the one-time 2 pt pulse around the route cards.
    @State private var pulseOpacity = 0.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    enum Action { case home, formats }

    private var locked: Int { model.lockedCount }
    private var shopOnly: Bool { model.document.printIsShopOnly }
    private var canPrintAtHome: Bool { PrintController.isAvailable && !shopOnly }
    private var route: PrintCheckView.PrintRoute? { canPrintAtHome ? chosenRoute : .shop }
    private var isWorking: Bool { model.activity == .exporting }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.sectionTight) {
                    header
                    steps
                    if locked == 0, route != nil { checkRow }
                    if dynamicTypeSize.isAccessibilitySize { actions }
                }
                .padding(.horizontal)
                .padding(.vertical, Design.Spacing.text)
            }
            .onChange(of: locked) { old, new in
                guard old > 0, new == 0, canPrintAtHome, chosenRoute == nil else { return }
                promptRouteChoice(proxy)
            }
        }
        .background(Design.Surface.screen)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                // A raised tray, as on Your sheet, so it reads as a panel over the steps rather than more of the page
                // (founder, 0.20 review: the unlock card blended into the screen).
                actions
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, Design.Spacing.caption)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                            .fill(Design.Surface.tray)
                            .shadow(color: .black.opacity(colorScheme == .dark ? 0.6 : 0.12), radius: 16, y: -4)
                            .ignoresSafeArea(edges: .bottom)
                    }
            }
        }
        .navigationTitle("Print")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { StepMarker(current: .output, output: .print) }
            if locked == 0 {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { path.removeAll() }.accessibilityIdentifier("shareDone")
                }
            }
        }
        .sheet(isPresented: $showCheck) {
            NavigationStack {
                PrintCheckView(model: model, route: route ?? .home,
                               onPrintAgain: route == .home ? { printAgain() } : nil,
                               onFinished: { showCheck = false; path.removeAll() })
            }
        }
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
        let landscape = layout.pages.first.map { $0.displayAspect > 1 } ?? false
        let thumbHeight: CGFloat = landscape ? 110 : 170
        let paper = PaperNames.short(for: model.printJob.paper)
        return VStack(alignment: .leading, spacing: Design.Spacing.group) {
            // The page lies on the mat; the words sit below, on the plain screen.
            SheetPreview(layout: layout, thumbnails: model.sheetThumbnails, compact: true, compactHeight: thumbHeight)
                .background(alignment: .topLeading) { pageStack(layout, height: thumbHeight) }
                .padding(.vertical, Design.Spacing.group)
                .frame(maxWidth: .infinity)
                .onMat(bleed: 16)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Image(systemName: "checkmark.circle.fill")
                    .font(Design.Typography.titleGlyph)
                    .foregroundStyle(StatusStyle.pass)
                    .accessibilityHidden(true)
                Text("Your sheet is ready").font(Design.Typography.screenTitle)
                Group {
                    if layout.pages.count > 1 {
                        Text("^[\(layout.placedCount) copy](inflect: true) on ^[\(layout.pages.count) page](inflect: true) of \(paper) paper")
                    } else {
                        Text("^[\(layout.placedCount) copy](inflect: true) on \(paper) paper")
                    }
                }
                .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("printHeader")
        }
    }

    /// Two plain sheets peeking out behind the thumbnail when the print has several pages.
    @ViewBuilder
    private func pageStack(_ layout: PrintLayout, height: CGFloat) -> some View {
        if layout.pages.count > 1, let aspect = layout.pages.first?.displayAspect {
            ZStack(alignment: .topLeading) {
                ForEach([12.0, 6.0], id: \.self) { offset in
                    Rectangle().fill(.white)
                        .aspectRatio(aspect, contentMode: .fit)
                        .frame(height: height)
                        .paperDimmedInDark()
                        .paperShadow()
                        .offset(x: offset, y: offset)
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// The instructions that decide whether the print comes out at the right size (docs/03-design.md §3), for printing
    /// at home or ordering at a shop.
    private var steps: some View {
        let paper = PaperNames.short(for: model.printJob.paper)
        let measure = model.printJob.options.calibrationBar
            ? Text("Measure the 50 mm line before cutting") : Text("Measure one photo before cutting")
        return VStack(alignment: .leading, spacing: Design.Spacing.text) {
            if canPrintAtHome {
                Text("Where will you print?")
                    .font(Design.Typography.cardTitle)
                    .padding(.horizontal, Design.Spacing.tight)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: Design.Spacing.control) {
                    routeCard(.home, title: "At Home", detail: "Your printer and photo paper", symbol: "printer")
                    routeCard(.shop, title: "At a Shop", detail: "A print shop or kiosk", symbol: "storefront")
                }
                .fixedSize(horizontal: false, vertical: true) // both cards as tall as the taller one
                .padding(.bottom, Design.Spacing.text)
                .id(Self.routeSectionID)
            }
            Text("Before you print")
                .font(Design.Typography.note.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, Design.Spacing.tight)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if route == nil {
                    Text("Choose where you print to see the steps.")
                        .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal).padding(.vertical, Design.Spacing.control)
                } else if route == .home {
                    step(1, title: PaperNames.isPhotoPaper(model.printJob.paper)
                            ? Text("Load \(paper) photo paper") : Text("Load \(paper) paper"), detail: nil)
                    Divider().padding(.leading, 56)
                    step(2, title: Text("Choose Actual Size, or 100 %"), detail: Text("Never Fit to Page or borderless"))
                } else {
                    step(1, title: Text("Order a standard print on \(paper) paper"), detail: nil)
                    Divider().padding(.leading, 56)
                    step(2, title: Text("Ask for no cropping and no Fit to Page"), detail: nil)
                }
                if route != nil {
                    Divider().padding(.leading, 56)
                    step(3, title: measure, detail: nil)
                }
            }
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            .animation(reduceMotion ? nil : .snappy, value: route)
            if let note = model.document.printNoteKey {
                Label(String(localized: String.LocalizationValue(note)), systemImage: "storefront")
                    .font(Design.Typography.note)
                    .padding(.horizontal, Design.Spacing.tight)
                    .accessibilityIdentifier("printRouteNote")
            }
        }
    }

    private static let routeSectionID = "routeSection"

    /// Shown while the photo is unlocked and the person has not yet chosen where to print.
    private var routeIsRequired: Bool { canPrintAtHome && locked == 0 && chosenRoute == nil }

    /// Right after unlocking: bring the cards into view and pulse their outline once (no pulse under Reduce Motion;
    /// the static outline of `routeIsRequired` stays until a route is chosen).
    private func promptRouteChoice(_ proxy: ScrollViewProxy) {
        promptRoute = true
        withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(Self.routeSectionID, anchor: .center) }
        guard !reduceMotion else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 0.45)) { pulseOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeInOut(duration: 0.45)) { pulseOpacity = 0 }
        }
    }

    /// One of the two places to print, as a large selectable card: the choice has to be obvious.
    private func routeCard(_ value: PrintCheckView.PrintRoute, title: LocalizedStringKey, detail: LocalizedStringKey,
                           symbol: String) -> some View {
        let selected = chosenRoute == value
        return Button {
            withAnimation(reduceMotion ? nil : .snappy) { chosenRoute = value }
        } label: {
            VStack(alignment: .leading, spacing: Design.Spacing.caption) {
                HStack(alignment: .top) {
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(Color.brandAccent)
                    Spacer(minLength: 0)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selected ? Color.brandAccent : Color.secondary.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace))
                }
                Text(title).font(Design.Typography.rowTitle).foregroundStyle(.primary)
                Text(detail).font(Design.Typography.note).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Design.Spacing.cardContent)
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.group)
                    .strokeBorder(selected ? Color.brandAccent
                                  : routeIsRequired ? Color.brandAccent.opacity(0.5) : Color(.separator),
                                  lineWidth: selected ? 2 : 1)
            }
            .overlay {
                // One pulse, or a static stroke under Reduce Motion, until a route is chosen.
                RoundedRectangle(cornerRadius: Design.Radius.group)
                    .strokeBorder(Color.brandAccent, lineWidth: 2)
                    .opacity(routeIsRequired && promptRoute ? (reduceMotion ? 1 : pulseOpacity) : 0)
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: Design.Radius.group))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected) { _, now in now }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(value == .home ? "routeHome" : "routeShop")
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

    /// After printing, compare the print with the screen (U1). Shown once the photos are unlocked.
    private var checkRow: some View {
        Button { showCheck = true } label: {
            HStack(spacing: Design.Spacing.control) {
                Image(systemName: "ruler")
                    .font(.body.weight(.semibold)).foregroundStyle(Color.brandAccent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                    Text("Check Your Print").foregroundStyle(.primary)
                    Text(route == .home ? "Lay it on the screen to see it is the right size"
                                        : "When the prints are back, lay one on the screen")
                        .font(Design.Typography.note).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal).padding(.vertical, Design.Spacing.control)
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("checkPrintButton")
    }

    /// Closes the check, then opens the print panel once the sheet has gone.
    private func printAgain() {
        showCheck = false
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            run(.home)
        }
    }

    // MARK: - Actions

    @ViewBuilder private var actions: some View {
        VStack(spacing: Design.Spacing.text) {
            if locked > 0 {
                UnlockCard(photos: locked, balance: model.credits.balance, inTray: !dynamicTypeSize.isAccessibilitySize)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom))))
                if model.credits.canAfford(locked) {
                    Button { unlock() } label: {
                        Label("Unlock", systemImage: "lock.open").frame(maxWidth: .infinity)
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
                if route == nil {
                    // The choice comes first; the button says so instead of guessing.
                    Button {} label: {
                        Text("Choose where to print").foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(true)
                        .accessibilityIdentifier("chooseRouteFirst")
                } else if route == .home {
                    Button { run(.home) } label: {
                        label("Print", systemImage: "printer", working: pending == .home)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("printAtHome")
                } else if let result = model.exported {
                    // Straight to the share sheet: AirDrop to a kiosk, a print app, or a message to the shop.
                    ShareLink(items: result.pages) {
                        Label(result.pages.count == 1 ? "Share Print Image" : "Share Print Images",
                              systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .brandProminentButtonStyle()
                    .controlSize(.large)
                    .accessibilityIdentifier("sharePages")
                } else {
                    // The files are still being made after unlocking.
                    Button {} label: { label("Share Print Image", systemImage: "square.and.arrow.up", working: true) }
                        .brandProminentButtonStyle()
                        .controlSize(.large)
                        .disabled(true)
                        .accessibilityIdentifier("sharePagesPreparing")
                }
                Button { run(.formats) } label: { label("More Formats", systemImage: nil, working: pending == .formats) }
                    .frame(minHeight: Design.Size.minimumTarget)
                    .accessibilityIdentifier("moreFormats")
            }
        }
        .disabled(isWorking && pending != nil)
    }

    private func label(_ title: LocalizedStringKey, systemImage: String?, working: Bool) -> some View {
        HStack(spacing: Design.Spacing.text) {
            if working { ProgressView() } else if let systemImage { Image(systemName: systemImage) }
            Text(title)
        }
        .frame(maxWidth: .infinity)
    }

    /// Unlocking only unlocks: the person then chooses home or shop (founder, 0.20 review: opening the print panel
    /// straight away skipped that choice). The files are prepared meanwhile, so either choice is quick.
    private func unlock() {
        // The unlock card folds away and the print buttons take its place (U4); the success tap is on `locked`.
        var unlocked = false
        withAnimation(Design.Motion.rearrange.resolved(reduceMotion: reduceMotion)) { unlocked = model.unlockAll() }
        guard unlocked else { showCredits = true; return }
        if model.exported == nil, model.activity == nil { model.prepareExport() }
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
            PrintController.shared.present(pdf: result.pdf, jobName: String(localized: "Calipic sheet")) { sent in
                // A finished job leads straight to the check; a cancelled panel leaves Print as it was.
                if sent { showCheck = true }
            }
        case .formats: showFormats = true
        }
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
