import SwiftUI

/// One page on the mat, with layout, unlock, route and send trays. Only this screen owns print navigation.
struct PrintView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State var selectedPerson: UUID?
    @State var showOptions = false
    @State var showCutting = false
    @State var copiesTick = 0
    @State var revealedRows: Int?
    @State var hasRevealed = false
    @State var fillResult: SheetChoices.Snapshot?
    @State var layoutConfirmed = false
    @State var chosenRoute: PrintCheckView.PrintRoute?
    @State var pending: Action?
    @State var showFormats = false
    @State var showCredits = false
    @State var showCheck = false
    @State var printAfterCheck = false
    @State var showAllSet = false
    @State var checkAfterAllSet = false
    @State var unlockTick = 0
    @State var holdsUnlockTray = false
    @State var unlockCost = 1
    @State var balanceBeforeUnlock = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    enum Action { case home, formats }
    enum PrintStep { case layout, unlock, route, send }
    var locked: Int { model.lockedCount }
    var displayedUnlockCount: Int { holdsUnlockTray ? unlockCost : max(1, locked) }
    var displayedBalance: Int { holdsUnlockTray ? balanceBeforeUnlock : model.credits.balance }
    var canPrintAtHome: Bool { PrintController.isAvailable && !model.document.printIsShopOnly }
    var route: PrintCheckView.PrintRoute? { canPrintAtHome ? chosenRoute : .shop }
    var person: PhotoEntry? { model.entries.first { $0.id == selectedPerson } ?? model.entries.first }
    var coaching: Bool { model.tutorial.isActive }
    var fillRequest: SheetChoices.Request {
        SheetChoices.Request(job: model.printJob, itemID: person.flatMap { model.printItems(for: $0.id).first?.id })
    }
    var fill: [SheetChoices.FillChoice] { fillResult?.choices(for: fillRequest) ?? [] }

    var step: PrintStep {
        if !layoutConfirmed { return .layout }
        if locked > 0 || holdsUnlockTray { return .unlock }
        return route == nil ? .route : .send
    }
    var guideTip: GuideTip? {
        guard coaching else { return nil }
        switch step {
        case .layout: return model.tutorial.current([.copies, .paper, .continueSheet])
        case .unlock: return .unlock
        case .route: return .route
        case .send: return route == .home ? .printHome : .share
        }
    }

    init(model: PhotoWorkflow, path: Binding<[Route]>, acquire: @escaping Acquire) {
        self.model = model; _path = path; self.acquire = acquire
        let routes = path.wrappedValue
        let arrivesFromCheck: Bool = {
            guard let index = routes.lastIndex(of: .sheet), index > 0 else { return false }
            if case .check = routes[index - 1] { return true }
            return false
        }()
        _revealedRows = State(initialValue: arrivesFromCheck && !UIAccessibility.isReduceMotionEnabled ? 0 : nil)
    }

    var body: some View {
        JourneyScreen(reservedTrayFraction: 0.45) { size in
            SheetPreview(layout: model.layout, thumbnails: model.sheetThumbnails, captions: false,
                         pageBox: CGSize(width: size.width, height: max(0, size.height - 44)), revealedRows: revealedRows, unlockTrigger: unlockTick)
                .frame(width: size.width, height: size.height)
        } tray: {
            tray.id(step).transition(.opacity)
                .animation(Design.Motion.rearrange.resolved(reduceMotion: reduceMotion), value: step)
        } actions: {
            actions
        }
        .guideOverlay(model.tutorial, current: guideTip, output: .print)
        .navigationTitle("Print")
        .navigationBarBackButtonHidden(step != .layout)
        .toolbar {
            ToolbarItem(placement: .principal) { StepMarker(current: .output, output: .print) }
            if step != .layout {
                ToolbarItem(placement: .topBarLeading) {
                    Button { goBack() } label: { Label("Back", systemImage: "chevron.backward") }
                        .labelStyle(.iconOnly).accessibilityIdentifier("printBack")
                }
            }
            ToolbarItem(placement: .topBarTrailing) { printMenu }
            if locked == 0, !coaching {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { path.removeAll() }.accessibilityIdentifier("shareDone")
                }
            }
        }
        .sheet(isPresented: $showOptions) { SheetOptionsView(model: model) }
        .sheet(isPresented: $showCutting) { CuttingOptionsView(model: model) }
        .sheet(isPresented: $showCheck, onDismiss: {
            if printAfterCheck { printAfterCheck = false; run(.home) }
        }) {
            NavigationStack {
                PrintCheckView(model: model, route: route ?? .home,
                    onPrintAgain: route == .home ? { printAgain() } : nil,
                    onFinished: { showCheck = false; path.removeAll() })
            }
        }
        .sheet(isPresented: $showAllSet, onDismiss: {
            if checkAfterAllSet { checkAfterAllSet = false; showCheck = true } else { path.removeAll() }
        }) {
            TutorialDoneView(output: .print, route: route, creditsLeft: model.credits.balance,
                checkPrint: route == .home ? { checkAfterAllSet = true; showAllSet = false } : nil,
                done: { showAllSet = false })
        }
        .sheet(isPresented: $showFormats) { if let result = model.exported { FormatsView(result: result) } }
        .sheet(isPresented: $showCredits) { CreditsView(credits: model.credits) }
        .task { model.refreshSheetThumbnails(); await revealCopies() }
        .task(id: fillRequest) {
            let request = fillRequest
            guard let itemID = request.itemID else { fillResult = nil; return }
            let choices = await SheetChoices.fillChoices(job: request.job, itemID: itemID)
            guard !Task.isCancelled, request == fillRequest else { return }
            fillResult = SheetChoices.Snapshot(request: request, values: choices)
        }
        .task(id: step) {
            if step == .send, model.exported == nil, model.activity == nil { model.prepareExport() }
        }
        .task(id: unlockTick) {
            guard unlockTick > 0 else { return }
            do { try await Task.sleep(for: .milliseconds(250)) } catch { holdsUnlockTray = false; return }
            withAnimation(Design.Motion.rearrange.resolved(reduceMotion: reduceMotion)) { holdsUnlockTray = false }
        }
        .onChange(of: locked) { old, new in
            if old > 0, new == 0 { unlockTick += 1 }
        }
        .sensoryFeedback(.success, trigger: unlockTick)
        .sensoryFeedback(.impact(weight: .light), trigger: revealedRows) { _, new in (new ?? 0) > 0 }
        .onChange(of: model.exported?.id) { _, _ in
            guard let result = model.exported, let action = pending else { return }
            pending = nil; perform(action, result)
        }
        .onChange(of: model.errorMessage) { _, message in if message != nil { pending = nil } }
        .onChange(of: model.printJob) { _, _ in if layoutConfirmed { returnToLayout() } }
        .onChange(of: model.printJob.items.map { "\($0.id)-\($0.photoID)-\($0.trimWidthMM)-\($0.trimHeightMM)" }) { _, _ in model.refreshSheetThumbnails() }
        .onChange(of: model.printJob.paper.id) { _, _ in model.tutorial.pass(.paper) }
        .onChange(of: copiesTick) { _, _ in model.tutorial.pass(.copies) }
        .onDisappear { pending = nil; model.finishExport() }
        .alert("Unable to complete", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            if model.errorActivity == .importing {
                Button("Choose Another Photo") {
                    model.errorMessage = nil
                    returnToLayout()
                    acquire(.library, .add)
                }
            } else {
                Button("Try Again") { model.errorMessage = nil; if layoutConfirmed { model.prepareExport() } }
            }
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }

    var tray: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.tray) {
            VStack(alignment: .leading, spacing: 2) {
                title.font(Design.Typography.trayTitle)
                Text(summary(model.layout)).font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(model.layout.placedCount * 100 + model.layout.pages.count)))
                    .animation(reduceMotion ? nil : .snappy, value: model.layout.placedCount)
                    .accessibilityIdentifier(step == .layout ? "layoutSummary" : "printSummary")
            }
            .accessibilityElement(children: .contain)
            switch step {
            case .layout: layoutControls
            case .unlock:
                UnlockExplanation(photos: displayedUnlockCount, balance: displayedBalance)
            case .route:
                TrayRows {
                    routeRow(.home, title: "At Home", detail: "Your printer and photo paper", symbol: "printer")
                    routeRow(.shop, title: "At a Shop", detail: "A print shop or kiosk", symbol: "storefront")
                }
                .guideTarget(.route, current: guideTip, ring: false)
            case .send: instructions
            }
        }
    }

    var title: some View {
        Group {
            switch step {
            case .layout: Text("Your sheet")
            case .unlock: displayedUnlockCount > 1 ? Text("Unlock \(CreditsPresentation.photos(displayedUnlockCount))") : Text("Unlock this photo")
            case .route: Text("Where will you print?")
            case .send: Text(route == .home ? "Print at home" : "Print at a shop")
            }
        }
        .accessibilityIdentifier(step == .layout ? "layoutTitle" : "printHeader")
    }

    var actions: some View {
        Group {
            switch step {
            case .layout:
                TrayActions {
                    Button { layoutConfirmed = true } label: { Text("Continue").frame(maxWidth: .infinity) }
                        .disabled(model.layout.pages.isEmpty || !model.layout.isComplete || model.activity != nil)
                        .guideTarget(.continueSheet, current: guideTip).accessibilityIdentifier("continueToShare")
                }
            case .unlock:
                TrayActions {
                    if displayedBalance >= displayedUnlockCount {
                        Button { unlock() } label: {
                            Label("Unlock · \(CreditsPresentation.count(displayedUnlockCount))", systemImage: "lock.open").frame(maxWidth: .infinity)
                        }
                        .disabled(holdsUnlockTray).guideTarget(.unlock, current: guideTip).accessibilityIdentifier("unlockAndPrint")
                    } else {
                        Button { showCredits = true } label: { Text("Get Credits").frame(maxWidth: .infinity) }
                            .accessibilityIdentifier("getCredits")
                    }
                } secondary: {
                    Button("Keep Editing") { returnToLayout() }.accessibilityIdentifier("keepEditing")
                }
            case .route:
                TrayActions {
                    Button {} label: { Text("Choose where to print").frame(maxWidth: .infinity) }
                        .disabled(true).accessibilityIdentifier("chooseRouteFirst")
                }
            case .send:
                TrayActions {
                    if route == .home {
                        Button { run(.home) } label: { actionLabel("Print", symbol: "printer", working: pending == .home) }
                            .disabled(model.activity != nil && pending != nil)
                            .guideTarget(.printHome, current: guideTip).accessibilityIdentifier("printAtHome")
                    } else {
                        Button {
                            if let result = model.exported { ShareController.present(result.pages) { shared in if shared { finishTutorial() } } }
                        } label: { actionLabel(model.exported?.pages.count == 1 ? "Share Print Image" : "Share Print Images", symbol: "square.and.arrow.up", working: model.exported == nil) }
                            .disabled(model.exported == nil)
                            .guideTarget(.share, current: guideTip)
                            .accessibilityIdentifier(model.exported == nil ? "sharePagesPreparing" : "sharePages")
                    }
                } secondary: {
                    Button("Change where") { if canPrintAtHome { chosenRoute = nil } else { returnToLayout() } }
                        .accessibilityIdentifier("changeRoute")
                }
            }
        }
    }

    var instructions: some View {
        let paper = PaperNames.short(for: model.printJob.paper)
        return TrayRows {
            TrayRow(title: route == .home
                ? (PaperNames.isPhotoPaper(model.printJob.paper) ? Text("Load \(paper) photo paper") : Text("Load \(paper) paper"))
                : Text("Order a standard print on \(paper) paper"), leading: { Text(1, format: .number).monospacedDigit().foregroundStyle(Color.brandAccent) })
            TrayRow(title: route == .home ? Text("Choose Actual Size, or 100 %. Never Fit to Page.")
                       : Text("Ask for no cropping and no Fit to Page"), leading: { Text(2, format: .number).monospacedDigit().foregroundStyle(Color.brandAccent) })
            TrayRow(title: model.printJob.options.calibrationBar ? Text("Measure the 50 mm line before cutting") : Text("Measure one photo before cutting"),
                    leading: { Text(3, format: .number).monospacedDigit().foregroundStyle(Color.brandAccent) })
            if route == .shop, let note = model.document.printNoteKey {
                TrayRow(title: Text(String(localized: String.LocalizationValue(note))), leading: { Image(systemName: "storefront").foregroundStyle(Color.brandAccent) })
                    .accessibilityIdentifier("printRouteNote")
            }
            TrayRow(title: Text("Check Your Print"), detail: Text(route == .home ? "Lay it on the screen to see it is the right size" : "When the prints are back, lay one on the screen"),
                    chevron: true, action: { showCheck = true }, leading: { Image(systemName: "ruler").foregroundStyle(Color.brandAccent) })
                .accessibilityIdentifier("checkPrintButton")
        }
    }

    func routeRow(_ value: PrintCheckView.PrintRoute, title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
        TrayRow(title: Text(title), detail: Text(detail), chevron: true,
                action: { chosenRoute = value }, leading: { Image(systemName: symbol).foregroundStyle(Color.brandAccent) })
            .sensoryFeedback(.selection, trigger: chosenRoute) { old, new in old != new && new == value }
            .accessibilityIdentifier(value == .home ? "routeHome" : "routeShop")
    }

    var printMenu: some View {
        Menu {
            Button { returnToLayout(); showCutting = true } label: { Label("Cutting options", systemImage: "scissors") }.accessibilityIdentifier("cuttingOptions")
            Menu {
                Button { returnToLayout(); acquire(.camera, .add) } label: { Label("Take Photo", systemImage: "camera") }.accessibilityIdentifier("addPersonCamera")
                Button { returnToLayout(); acquire(.library, .add) } label: { Label("Choose Photo", systemImage: "photo.on.rectangle") }.accessibilityIdentifier("addPersonLibrary")
            } label: { Label("Add another person", systemImage: "person.badge.plus") }
                .disabled(!model.canAddPhoto || model.activity != nil).accessibilityIdentifier("addPerson")
            Button { returnToLayout(); showOptions = true } label: { Label("More sizes and paper", systemImage: "doc.on.doc") }.accessibilityIdentifier("moreOptions")
            if locked == 0 {
                Button { run(.formats) } label: { Label("More Formats", systemImage: "square.and.arrow.up") }
                    .disabled(!layoutConfirmed || model.activity != nil).accessibilityIdentifier("moreFormats")
            }
        } label: { Label("More", systemImage: "ellipsis") }
        .accessibilityIdentifier("printMenu")
    }

    func returnToLayout() {
        pending = nil; layoutConfirmed = false; holdsUnlockTray = false
        model.finishExport()
    }

    func goBack() {
        if step == .send, canPrintAtHome { chosenRoute = nil }
        else { returnToLayout() }
    }

    func unlock() {
        unlockCost = locked
        balanceBeforeUnlock = model.credits.balance
        holdsUnlockTray = true
        guard model.unlockAll() else { holdsUnlockTray = false; showCredits = true; return }
        if model.exported == nil, model.activity == nil { model.prepareExport() }
    }

    func actionLabel(_ title: LocalizedStringKey, symbol: String, working: Bool) -> some View {
        HStack {
            if working { ProgressView() } else { Image(systemName: symbol) }
            Text(title)
        }.frame(maxWidth: .infinity)
    }

    func printAgain() { printAfterCheck = true; showCheck = false }
    func finishTutorial() { if coaching { model.tutorial.complete(); showAllSet = true } }
    func run(_ action: Action) {
        guard locked == 0 else { return }
        if let result = model.exported { perform(action, result) }
        else { pending = action; if model.activity == nil { model.prepareExport() } }
    }
    func perform(_ action: Action, _ result: PhotoExport) {
        switch action {
        case .formats: showFormats = true
        case .home:
            guard !PrintController.isSuppressedForUITests else { if coaching { finishTutorial() }; return }
            PrintController.shared.present(pdf: result.pdf, jobName: String(localized: "Calipic sheet")) { sent in
                guard sent else { return }
                if coaching { finishTutorial() } else { showCheck = true }
            }
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
