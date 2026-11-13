import SwiftUI

/// Step 3 (design 3b): the paper is the hero; people, copies and paper sit in one tray at thumb height.
/// Extra sizes and custom paper live in the options sheet; cutting options open from the scissors in the bar.
struct SheetView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var selectedPerson: UUID?
    @State private var showOptions = false
    @State private var showCutting = false
    /// Counts the person's own taps on the copies stepper, so switching person does not tick it.
    @State private var copiesTick = 0
    /// Rows of the first page shown so far while the copies appear after Photo Check; nil shows every row.
    @State private var revealedRows: Int?
    @State private var hasRevealed = false
    /// "Fill" menu choices for the selected person, worked out off the main actor whenever the sheet changes.
    @State private var fill: [FillChoice] = []
    @Environment(\.zoomNamespace) private var zoomNamespace
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var person: PhotoEntry? { model.entries.first { $0.id == selectedPerson } ?? model.entries.first }

    var body: some View {
        let layout = model.layout
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: Design.Spacing.group) {
                        matPreview(layout, box: CGSize(width: 260, height: 260))
                            .padding(.vertical, Design.Spacing.group)
                            .onMat()
                        summaryLine(layout)
                        trayContent(layout).padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            } else {
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        matPreview(layout, box: CGSize(width: max(160, geometry.size.width - 48),
                                                       height: max(160, geometry.size.height - 32)))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    // The page lies on the mat; the text sits below it.
                    .onMat()
                    summaryLine(layout)
                        .padding(.vertical, Design.Spacing.text)
                    trayContent(layout)
                        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, Design.Spacing.text)
                        .background {
                            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                                .fill(Design.Surface.tray)
                                .ignoresSafeArea(edges: .bottom)
                        }
                }
            }
        }
        .background(Design.Surface.screen)
        .navigationTitle("Your sheet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { StepMarker(current: .output, output: .print) }
            // Cutting options sat inside the paper list, where nobody looked for them (founder, 0.20 review).
            ToolbarItem(placement: .primaryAction) {
                Button { showCutting = true } label: { Label("Cutting options", systemImage: "scissors") }
                    .accessibilityIdentifier("cuttingOptions")
            }
        }
        .sheet(isPresented: $showOptions) { SheetOptionsView(model: model) }
        .sheet(isPresented: $showCutting) { CuttingOptionsView(model: model) }
        .task { model.refreshSheetThumbnails() }
        .task { await revealCopies() }
        .task(id: "\(model.printJob.hashValue)-\(person?.id.uuidString ?? "")") {
            guard let person, let itemID = model.printItems(for: person.id).first?.id else { fill = []; return }
            let choices = await Self.fillChoices(job: model.printJob, itemID: itemID)
            if !Task.isCancelled { fill = choices }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: revealedRows) { _, new in (new ?? 0) > 0 }
        .onChange(of: model.printJob.items.map { "\($0.id)-\($0.photoID)" }) { _, _ in model.refreshSheetThumbnails() }
    }

    private func matPreview(_ layout: PrintLayout, box: CGSize) -> some View {
        // Page captions are left to the accessibility label here: bare text may not sit on the mat's grid.
        SheetPreview(layout: layout, thumbnails: model.sheetThumbnails, captions: false, pageBox: box,
                     revealedRows: revealedRows)
            // Print zooms out of the page (U4).
            .zoomSource(.share, at: (path.firstIndex(of: .sheet) ?? 0) + 1, in: zoomNamespace)
    }

    /// Arriving from Photo Check, the photo has just zoomed into the page; its copies then appear one row after
    /// another with a light tap each (U4). Once per visit, never under Reduce Motion.
    private func revealCopies() async {
        guard !hasRevealed else { return }
        hasRevealed = true
        guard !reduceMotion, let index = path.firstIndex(of: .sheet), index > 0, case .check = path[index - 1],
              let rows = model.layout.pages.first?.displayRows.count, rows > 1 else { return }
        revealedRows = 0
        try? await Task.sleep(for: .milliseconds(300))
        for row in 1...rows {
            guard !Task.isCancelled else { break }
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { revealedRows = row }
            try? await Task.sleep(for: .milliseconds(110))
        }
        withAnimation(.easeOut(duration: 0.25)) { revealedRows = nil }
    }

    private func summaryLine(_ layout: PrintLayout) -> some View {
        Text(summary(layout))
            .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(layout.placedCount * 100 + layout.pages.count)))
            .animation(reduceMotion ? nil : .snappy, value: summary(layout))
            .accessibilityIdentifier("layoutSummary")
    }

    // MARK: - Tray

    private func trayContent(_ layout: PrintLayout) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.group) {
            if let person { personLine(person) }
            HStack(spacing: Design.Spacing.control) {
                ScrollView(.horizontal) {
                    HStack(spacing: Design.Spacing.cardContent) {
                        ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in
                            personCircle(entry, index: index)
                        }
                        addPersonMenu
                    }
                    .padding(.vertical, 8).padding(.horizontal, 4)
                }
                .scrollIndicators(.hidden)
                if let person, let copies = copiesBinding(for: person) {
                    if !fill.isEmpty { fillMenu(for: person) }
                    Stepper("Copies",
                            onIncrement: { copies.wrappedValue = steppedCopies(from: copies.wrappedValue, up: true) },
                            onDecrement: { copies.wrappedValue = steppedCopies(from: copies.wrappedValue, up: false) })
                        .labelsHidden()
                        .accessibilityValue(Text("^[\(copies.wrappedValue) copy](inflect: true)"))
                        .sensoryFeedback(.selection, trigger: copiesTick)
                        .accessibilityIdentifier("copiesStepper")
                }
            }
            paperChips
                .sensoryFeedback(.selection, trigger: model.printJob.paper.id)
            if !layout.isComplete {
                StatusLabel(text: "\(layout.unplacedCount) copies do not fit within \(model.printJob.options.maxPages) pages.", state: .warn)
                    .font(.subheadline)
            }
            Button { path.append(.share) } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .brandProminentButtonStyle()
            .controlSize(.large)
            .disabled(layout.pages.isEmpty || model.activity != nil)
            .accessibilityIdentifier("continueToShare")
        }
    }

    private func personLine(_ person: PhotoEntry) -> some View {
        let index = model.entries.firstIndex { $0.id == person.id } ?? 0
        let items = model.printItems(for: person.id)
        let copies = items.reduce(0) { $0 + $1.copies }
        let sizes = items.map { DocumentPresentation.size(widthMM: $0.trimWidthMM, heightMM: $0.trimHeightMM) }.joined(separator: ", ")
        return HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                Text(model.entries.count > 1 ? LocalizedStringKey("Photo \(index + 1)") : LocalizedStringKey("Your photo"))
                    .font(Design.Typography.rowTitle)
                Text("\(sizes) · ^[\(copies) copy](inflect: true)")
                    .font(Design.Typography.note).foregroundStyle(.secondary)
            }
            .contentTransition(.numericText(value: Double(copies)))
            .animation(reduceMotion ? nil : .snappy, value: copies)
            .accessibilityElement(children: .combine)
            Spacer()
            Button { path.append(.check(person.id)) } label: {
                Text("Check")
                    .font(.subheadline)
                    .frame(minWidth: Design.Size.minimumTarget, minHeight: Design.Size.minimumTarget, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("person-\(index + 1)")
        }
    }

    private func personCircle(_ entry: PhotoEntry, index: Int) -> some View {
        let selected = entry.id == person?.id
        let copies = model.printItems(for: entry.id).reduce(0) { $0 + $1.copies }
        // The miniature covers the whole circle whatever the photo's shape; a fitted one left bars at the sides.
        let aspect = model.renderTarget.format.aspectRatio
        let width = max(52, 52 * aspect)
        return Button { selectedPerson = entry.id } label: {
            PortraitView(entry: entry, format: model.renderTarget.format)
                .frame(width: width, height: width / aspect)
                .frame(width: 52, height: 52, alignment: .top)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(selected ? Color.brandAccent : Color(.separator), lineWidth: selected ? 3 : 1))
                .overlay(alignment: .topTrailing) {
                    Text(verbatim: "\(copies)")
                        .font(.caption2.weight(.bold)).monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Color.brandAccentFill, in: Capsule())
                        .offset(x: 6, y: -6)
                        .contentTransition(.numericText(value: Double(copies)))
                        .animation(reduceMotion ? nil : .snappy, value: copies)
                }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { path.append(.check(entry.id)) } label: { Label("Check Photo", systemImage: "checkmark.circle") }
            Button(role: .destructive) {
                model.selectedID = entry.id
                model.removePhoto()
                if model.entries.isEmpty { path.removeAll() }
            } label: { Label("Remove Photo", systemImage: "trash") }
            .disabled(model.activity != nil)
        }
        .sensoryFeedback(.selection, trigger: selectedPerson) { old, new in new == entry.id && old != new }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Photo \(index + 1): ^[\(copies) copy](inflect: true)"))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("personCircle-\(index + 1)")
    }

    private var addPersonMenu: some View {
        Menu {
            Button { acquire(.camera, .add) } label: { Label("Take Photo", systemImage: "camera") }
                .accessibilityIdentifier("addPersonCamera")
            Button { acquire(.library, .add) } label: { Label("Choose Photo", systemImage: "photo.on.rectangle") }
                .accessibilityIdentifier("addPersonLibrary")
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .frame(width: 52, height: 52)
                .overlay(Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])).foregroundStyle(.tertiary))
                .contentShape(Circle())
        }
        .disabled(!model.canAddPhoto || model.activity != nil)
        .accessibilityLabel(model.canAddPhoto ? Text("Add another person") : Text("Sheet is full (\(PhotoWorkflow.maxPhotos) people)"))
        .accessibilityIdentifier("addPerson")
    }

    /// Three everyday papers plus the current one when it is something else; the rest is in the options sheet.
    private var paperChips: some View {
        let current = model.printJob.paper
        let quick = PaperNames.quickPapers
        return ScrollView(.horizontal) {
            HStack(spacing: Design.Spacing.text) {
                if !quick.contains(where: { $0.id == current.id }) { paperChip(current) }
                ForEach(quick) { paperChip($0) }
                Button { showOptions = true } label: { Text("More").foregroundStyle(Color.primary) }
                    .buttonStyle(.bordered).buttonBorderShape(.capsule).tint(.gray)
                    .accessibilityIdentifier("moreOptions")
            }
        }
        .scrollIndicators(.hidden)
    }

    private func paperChip(_ paper: PaperSize) -> some View {
        let selected = paper.id == model.printJob.paper.id
        // A quiet neutral chip; the chosen paper carries the accent.
        return Button { model.printJob.paper = paper } label: {
            Text(PaperNames.short(for: paper))
                .font(Design.Typography.sizeChoice(.callout, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? Color.brandAccent : Color.primary)
        }
            .buttonStyle(.bordered).buttonBorderShape(.capsule)
            .tint(selected ? Color.brandAccent : Color.gray)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("paper-\(paper.id)")
    }

    /// Whole pages in one choice: "2 pages · 24 copies" instead of many taps on +. The counts come from the layout
    /// solver for the current paper, options and other people (founder's recording: 22 taps to reach 30 copies).
    private func fillMenu(for person: PhotoEntry) -> some View {
        Menu {
            ForEach(fill, id: \.pages) { choice in
                Button {
                    if let copies = copiesBinding(for: person) { copies.wrappedValue = choice.copies }
                } label: {
                    Text("^[\(choice.pages) page](inflect: true) · ^[\(choice.copies) copy](inflect: true)")
                }
            }
        } label: {
            Label("Fill", systemImage: "square.grid.3x3")
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.bordered).buttonBorderShape(.capsule).tint(.gray)
        .foregroundStyle(Color.primary)
        .accessibilityLabel(Text("Fill pages"))
        .accessibilityIdentifier("fillPages")
    }

    struct FillChoice: Sendable { let pages: Int; let copies: Int }

    /// For 1–3 pages, the most copies of item `itemID` that fit with everything else on the sheet unchanged.
    /// Pure layout work, so it runs off the main actor.
    @concurrent
    static func fillChoices(job: PrintJob, itemID: UUID) async -> [FillChoice] {
        var job = job
        guard let index = job.items.firstIndex(where: { $0.id == itemID }) else { return [] }
        var choices: [FillChoice] = []
        var copies = 1
        for pages in 1...3 {
            // Grow until one more copy would need another page.
            while copies < 200 {
                if Task.isCancelled { return [] }
                job.items[index].copies = copies + 1
                let layout = PrintLayoutSolver.solve(job)
                guard layout.isComplete, layout.pages.count <= pages else { break }
                copies += 1
            }
            job.items[index].copies = copies
            let layout = PrintLayoutSolver.solve(job)
            if layout.isComplete, layout.pages.count == pages, choices.last?.copies != copies {
                choices.append(FillChoice(pages: pages, copies: copies))
            }
            copies += 1
        }
        return choices
    }

    /// Up to one full page the stepper moves one copy at a time; beyond it, a page at a time (to the next or previous
    /// whole-page count), so 36 copies is three taps rather than twenty-four (founder's recording, 0.20.9).
    private func steppedCopies(from copies: Int, up: Bool) -> Int {
        let whole = fill.map(\.copies).sorted()
        guard let onePage = whole.first else { return min(max(copies + (up ? 1 : -1), 0), 50) }
        let next: Int
        if up {
            next = copies >= onePage ? (whole.first { $0 > copies } ?? copies + 1) : copies + 1
        } else {
            next = copies > onePage ? (whole.last { $0 < copies } ?? copies - 1) : copies - 1
        }
        return min(max(next, 0), 50)
    }

    private func copiesBinding(for person: PhotoEntry) -> Binding<Int>? {
        guard let id = model.printItems(for: person.id).first?.id else { return nil }
        return Binding(get: { model.printJob.items.first { $0.id == id }?.copies ?? 0 },
                       set: { value in
                           if let index = model.printJob.items.firstIndex(where: { $0.id == id }), model.printJob.items[index].copies != value {
                               model.printJob.items[index].copies = value
                               copiesTick += 1
                           }
                       })
    }

    private func summary(_ layout: PrintLayout) -> String {
        // AttributedString applies the ^[…](inflect: true) grammar; String(localized:) would show the markup.
        let base = String(AttributedString(localized: "^[\(layout.placedCount) copy](inflect: true) · ^[\(layout.pages.count) page](inflect: true)").characters)
        // The last page's empty slots, outlined on the paper: copies that cost no extra paper (capped by the stepper).
        var room = layout.pages.last?.freeSlots.count ?? 0
        if model.printJob.items.count == 1, let copies = model.printJob.items.first?.copies { room = min(room, 50 - copies) }
        return room > 0 ? base + " · " + String(localized: "Room for \(room) more") : base
    }
}

/// What is not needed every time: extra sizes per person and any paper.
struct SheetOptionsView: View {
    @Bindable var model: PhotoWorkflow
    @Environment(\.dismiss) private var dismiss
    @State private var customWidth = 100.0
    @State private var customHeight = 150.0
    @State private var customError = false
    @State private var addingSizeFor: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in
                    Section {
                        ForEach($model.printJob.items) { $item in
                            if item.photoID == entry.id {
                                Stepper(value: $item.copies, in: 0...50) {
                                    LabeledContent(formatName(item), value: "\(item.copies)")
                                }
                                .accessibilityIdentifier("copies-\(item.id.uuidString)")
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { model.removePrintItem(id: item.id) } label: { Label("Remove", systemImage: "trash") }
                                }
                            }
                        }
                        Button { addingSizeFor = entry.id } label: {
                            Label("Add another size", systemImage: "plus")
                        }
                        .accessibilityIdentifier("addSize-\(index + 1)")
                    } header: {
                        Text(model.entries.count > 1 ? LocalizedStringKey("Photo \(index + 1)") : LocalizedStringKey("Your photo"))
                    }
                }

                Section("Paper") {
                    Picker("Paper size", selection: paperSelection) {
                        ForEach(PaperSize.presets) { paper in
                            Text(PaperNames.name(for: paper)).tag(paper.id)
                        }
                        Text("Custom").tag("custom")
                    }
                    if model.printJob.paper.isCustom {
                        LabeledContent("Width (mm)") {
                            TextField("Width", value: $customWidth, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).frame(width: 90)
                        }
                        LabeledContent("Height (mm)") {
                            TextField("Height", value: $customHeight, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).frame(width: 90)
                        }
                        Button("Apply custom size") { applyCustom() }
                        if customError {
                            Text("Enter sizes between 50 and 500 mm.").font(Design.Typography.note).foregroundStyle(.secondary)
                        }
                        Text("Your printer uses the nearest paper it offers. For other sizes, print at a shop.")
                            .font(Design.Typography.note).foregroundStyle(.secondary)
                    }
                }

            }
            .navigationTitle("Sheet options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("optionsDone") } }
            .confirmationDialog("Add a size", isPresented: Binding(get: { addingSizeFor != nil }, set: { if !$0 { addingSizeFor = nil } }),
                                titleVisibility: .visible, presenting: addingSizeFor) { photoID in
                ForEach(sizeChoices) { format in
                    Button(formatName(format)) { model.addPrintItem(format: format, photoID: photoID) }
                }
            } message: { _ in
                Text("Sizes for other documents; each one gets its own copies.")
            }
        }
    }

    private var paperSelection: Binding<String> {
        Binding(get: { model.printJob.paper.id }, set: { id in
            if id == "custom" {
                if let paper = try? PaperSize.custom(widthMM: customWidth, heightMM: customHeight) { model.printJob.paper = paper }
            } else if let paper = PaperSize.presets.first(where: { $0.id == id }) {
                model.printJob.paper = paper
            }
        })
    }

    private func applyCustom() {
        do {
            model.printJob.paper = try PaperSize.custom(widthMM: customWidth, heightMM: customHeight)
            customError = false
        } catch {
            customError = true
        }
    }

    /// The document's own size first, then the other engineering presets.
    private var sizeChoices: [PhotoFormat] {
        let current = model.renderTarget.format
        return [current] + PhotoFormat.presets.filter { abs($0.widthMM - current.widthMM) > 0.001 || abs($0.heightMM - current.heightMM) > 0.001 }
    }

    private func formatName(_ item: PrintItem) -> String {
        DocumentPresentation.size(widthMM: item.trimWidthMM, heightMM: item.trimHeightMM)
    }

    private func formatName(_ format: PhotoFormat) -> String {
        DocumentPresentation.size(widthMM: format.widthMM, heightMM: format.heightMM)
    }
}

/// How the photos are laid out and marked for cutting.
struct CuttingOptionsView: View {
    @Bindable var model: PhotoWorkflow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Safety margin around each photo", isOn: bleedBinding)
                    Toggle("Corner cut marks", isOn: $model.printJob.options.cornerTicks)
                    Toggle("50 mm check bar", isOn: $model.printJob.options.calibrationBar)
                } footer: {
                    Text("The safety margin lets a slightly off cut stay inside the photo. The check bar lets you confirm the print is at real size.")
                }
                Section {
                    Picker("Orientation", selection: $model.printJob.options.orientation) {
                        Text("Automatic").tag(PageOrientation.automatic)
                        Text("Portrait").tag(PageOrientation.portrait)
                        Text("Landscape").tag(PageOrientation.landscape)
                    }
                    Toggle("As many copies as possible", isOn: maximumCopiesBinding)
                    Picker("Order on the page", selection: $model.printJob.options.fillStrategy) {
                        Text("One size at a time").tag(FillStrategy.byType)
                        Text("Mix sizes").tag(FillStrategy.interleave)
                    }
                }
            }
            .navigationTitle("Cutting options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("cuttingDone") } }
        }
        .presentationDetents([.fraction(0.45), .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
        .presentationContentInteraction(.scrolls)
    }

    private var bleedBinding: Binding<Bool> {
        Binding(get: { model.printJob.options.bleed != .none },
                set: { model.printJob.options.bleed = $0 ? .adaptive(maxMM: 1) : .none })
    }

    private var maximumCopiesBinding: Binding<Bool> {
        Binding(get: { model.printJob.options.gutterMM == 0 }, set: { on in
            let keep = model.printJob.options
            var next = on ? PrintOptions.maximumCopies : PrintOptions()
            next.fillStrategy = keep.fillStrategy
            next.orientation = keep.orientation
            next.calibrationBar = keep.calibrationBar
            model.printJob.options = next
        })
    }
}

enum PaperNames {
    /// The papers offered as chips on Your sheet: photo paper first, then the region's everyday office paper.
    static var quickPapers: [PaperSize] {
        Locale.current.measurementSystem == .us ? [.photo4x6, .photo13x18, .usLetter] : [.photo4x6, .photo13x18, .a4]
    }

    /// The photo-lab sizes; office papers (A4, Letter) are plain paper unless the person says otherwise.
    static func isPhotoPaper(_ paper: PaperSize) -> Bool {
        [PaperSize.photo4x6.id, PaperSize.photo13x18.id, PaperSize.photo9x13.id].contains(paper.id)
    }

    /// A short name in the region's own units, for chips and print instructions. It never breaks across lines.
    static func short(for paper: PaperSize) -> String {
        breakingName(for: paper).replacingOccurrences(of: " ", with: "\u{00A0}")
    }

    private static func breakingName(for paper: PaperSize) -> String {
        let us = Locale.current.measurementSystem == .us
        switch paper.id {
        case PaperSize.photo4x6.id: return us ? String(localized: "4 × 6 in") : String(localized: "10 × 15 cm")
        case PaperSize.photo13x18.id: return us ? String(localized: "5 × 7 in") : String(localized: "13 × 18 cm")
        case PaperSize.photo9x13.id: return us ? String(localized: "3.5 × 5 in") : String(localized: "9 × 13 cm")
        case PaperSize.a6.id: return "A6"
        case PaperSize.a5.id: return "A5"
        case PaperSize.a4.id: return "A4"
        case PaperSize.usLetter.id: return String(localized: "Letter")
        default: return DocumentPresentation.size(widthMM: paper.widthMM, heightMM: paper.heightMM)
        }
    }

    static func name(for paper: PaperSize) -> String {
        switch paper.id {
        case PaperSize.photo4x6.id: return String(localized: "10 × 15 cm · 4 × 6 in")
        case PaperSize.photo13x18.id: return String(localized: "13 × 18 cm · 5 × 7 in")
        case PaperSize.photo9x13.id: return String(localized: "9 × 13 cm · 3.5 × 5 in")
        case PaperSize.a6.id: return String(localized: "A6 (105 × 148 mm)")
        case PaperSize.a5.id: return String(localized: "A5 (148 × 210 mm)")
        case PaperSize.a4.id: return String(localized: "A4 (210 × 297 mm)")
        case PaperSize.usLetter.id: return String(localized: "US Letter (8.5 × 11 in)")
        default:
            let width = paper.widthMM.formatted(.number.precision(.fractionLength(0...1)))
            let height = paper.heightMM.formatted(.number.precision(.fractionLength(0...1)))
            return String(localized: "Custom \(width) × \(height) mm")
        }
    }
}

/// Pages drawn from the layout: each placement is a view keyed by item and copy, so a change of copies or paper
/// animates every photo to its new position; ticks and the calibration bar are drawn in a Canvas on top.
struct SheetPreview: View {
    private var firstPageWidth: CGFloat {
        guard let page = layout.pages.first else { return pageBox.width }
        return min(pageBox.width, pageBox.height * page.displayAspect)
    }

    let layout: PrintLayout
    /// Crops per print item; placements without one are drawn as grey boxes.
    var thumbnails: [UUID: CGImage] = [:]
    /// First page only, no captions, for cards.
    var compact = false
    var compactHeight: CGFloat = 130
    /// "Page 1 of 2" under each page. Off when the pages lie on the mat, where bare text is not allowed.
    var captions = true
    /// The space each full page is fitted into, keeping the paper's proportions.
    var pageBox = CGSize(width: 260, height: 260)
    /// Rows of the first page to show; nil shows them all.
    var revealedRows: Int?
    /// The page in the middle of the strip. It follows new pages as copies are added (founder, 0.20.9: pages 3–5 were
    /// never brought into view).
    @State private var focusedPage: Int?
    /// Pages from this index on arrived with the last change and are still filling; nil when none are.
    @State private var arrivingFrom: Int?
    /// Rows shown so far on the arriving pages.
    @State private var arrivingRows = 0
    @State private var arrival: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func rows(onPage index: Int) -> Int? {
        if index == 0, let revealedRows { return revealedRows }
        if let arrivingFrom, index >= arrivingFrom { return arrivingRows }
        return nil
    }

    var body: some View {
        let pages = compact ? Array(layout.pages.prefix(1)) : layout.pages
        if compact, let page = pages.first {
            UprightPageView(page: page, thumbnails: thumbnails, animated: false)
                .aspectRatio(page.displayAspect, contentMode: .fit)
                .frame(height: compactHeight)
                .paperDimmedInDark()
                .paperShadow()
                .accessibilityLabel(Text("Page 1 of \(layout.pages.count): \(page.placements.count) photos"))
                .accessibilityIdentifier("sheetThumbnail")
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Design.Spacing.group) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        let aspect = page.displayAspect
                        let width = min(pageBox.width, pageBox.height * aspect)
                        VStack(spacing: Design.Spacing.tight) {
                            UprightPageView(page: page, thumbnails: thumbnails, animated: !reduceMotion,
                                            revealedRows: rows(onPage: index), showsEmptySlots: true)
                                .frame(width: width, height: width / aspect)
                                .paperDimmedInDark()
                                .paperShadow()
                            if captions, layout.pages.count > 1 {
                                Text("Page \(index + 1) of \(layout.pages.count)").font(Design.Typography.caption)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Page \(index + 1) of \(layout.pages.count): \(page.placements.count) photos"))
                        .id(index)
                    }
                    if layout.pages.isEmpty {
                        ContentUnavailableView("Nothing to print", systemImage: "printer",
                                               description: Text("Add copies or choose a larger paper."))
                            .frame(height: 220)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 6)
            }
            // Pages snap one at a time and sit in the middle of the mat; the margin centres a page of the first one's
            // width, so a single page sits centred too.
            .contentMargins(.horizontal, max(4, (pageBox.width + 48 - firstPageWidth) / 2), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $focusedPage, anchor: .center)
            .onChange(of: layout.pages.count) { old, new in
                // A new page appears where the new copies went: bring it into view. Fewer pages: stay in range.
                let animation: Animation? = reduceMotion ? nil : .smooth(duration: 0.4)
                if new > old {
                    withAnimation(animation) { focusedPage = new - 1 }
                    fill(newPagesFrom: old)
                } else {
                    if let focusedPage, focusedPage >= new { withAnimation(animation) { self.focusedPage = max(0, new - 1) } }
                    if let arrivingFrom, arrivingFrom >= new { arrival?.cancel(); self.arrivingFrom = nil }
                }
            }
            .accessibilityIdentifier("sheetPreview")
        }
    }
}

extension SheetPreview {
    /// New pages slide in empty, showing only their outlined slots, then their copies drop in row by row, as on the
    /// first page after Photo Check (founder's recording, 0.20.11: a new page arrived already full). Not under
    /// Reduce Motion.
    fileprivate func fill(newPagesFrom first: Int) {
        arrival?.cancel()
        guard !reduceMotion, !compact else { return }
        let rowCount = layout.pages.dropFirst(first).map(\.displayRows.count).max() ?? 0
        guard rowCount > 0 else { return }
        arrivingRows = 0
        arrivingFrom = first
        arrival = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            for row in 1...rowCount {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { arrivingRows = row }
                try? await Task.sleep(for: .milliseconds(90))
            }
            guard !Task.isCancelled else { return }
            arrivingFrom = nil
        }
    }
}

extension PrintPage {
    /// True when most photos lie sideways on the paper (rotated to fit more copies). Such a page is shown turned a
    /// quarter anticlockwise so the faces stand upright; the printed page is unchanged (founder, 0.20 review).
    var displaysTurned: Bool {
        // The empty slots count too, so a page keeps its turn while it fills.
        let rotated = placements.filter(\.rotated).count + freeSlots.filter(\.rotated).count
        return rotated * 2 > placements.count + freeSlots.count
    }

    /// Width over height of the page as shown on screen.
    var displayAspect: Double { displaysTurned ? heightMM / widthMM : widthMM / heightMM }
}

/// A page as shown on screen: turned when its photos lie sideways, so faces are always upright.
struct UprightPageView: View {
    let page: PrintPage
    let thumbnails: [UUID: CGImage]
    var animated = true
    var revealedRows: Int?
    var showsEmptySlots = false

    var body: some View {
        GeometryReader { geometry in
            let turned = page.displaysTurned
            SheetPageView(page: page, thumbnails: thumbnails, animated: animated, revealedRows: revealedRows,
                          showsEmptySlots: showsEmptySlots)
                .frame(width: turned ? geometry.size.height : geometry.size.width,
                       height: turned ? geometry.size.width : geometry.size.height)
                .rotationEffect(.degrees(turned ? -90 : 0))
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct SheetPageView: View {
    let page: PrintPage
    let thumbnails: [UUID: CGImage]
    var animated = true
    /// Rows (as seen on screen) to show; the rest wait, invisible, to appear in turn. nil shows all.
    var revealedRows: Int?
    /// Outlines where more copies fit (and where waiting copies will land). Never on cutting guides or prints.
    var showsEmptySlots = false

    private struct Key: Hashable { let item: UUID; let copy: Int }
    private struct Keyed: Identifiable { let id: Key; let placement: Placement }
    private var keyed: [Keyed] { page.placements.map { Keyed(id: Key(item: $0.itemID, copy: $0.copyIndex), placement: $0) } }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / page.widthMM, geometry.size.height / page.heightMM)
            let hidden = hiddenPlacements
            ZStack(alignment: .topLeading) {
              // The paper stays put; only the photos cross-fade. With the paper inside the fading layer, the mat
              // showed through for a moment and the page flashed dark on every added copy (founder, 0.20.9).
              Color.white
              if showsEmptySlots {
                  emptySlots(hidden: hidden, scale: scale)
              }
              ZStack(alignment: .topLeading) {
                ForEach(keyed) { item in
                    let placement = item.placement
                    let waiting = hidden.contains(item.id)
                    placementView(placement, scale: scale)
                        .opacity(waiting ? 0 : 1)
                        .scaleEffect(waiting ? 0.6 : 1)
                        .frame(width: placement.bleed.width * scale, height: placement.bleed.height * scale)
                        .position(x: (placement.bleed.x + placement.bleed.width / 2) * scale,
                                  y: (placement.bleed.y + placement.bleed.height / 2) * scale)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
              }
              // When the grid re-flows (paper, margin, orientation, or a centred grid shifting), the page cross-fades
              // instead of every photo flying to a new place (founder's recording, 0.20.8). A copy added into a free
              // slot keeps the same grid and simply appears.
              .id(layoutSignature)
              .transition(.opacity)
                Canvas { context, _ in
                    var ticks = Path()
                    for tick in page.cornerTicks {
                        ticks.move(to: CGPoint(x: tick.fromX * scale, y: tick.fromY * scale))
                        ticks.addLine(to: CGPoint(x: tick.toX * scale, y: tick.toY * scale))
                    }
                    // The paper is white in both appearances, so its marks are always dark.
                    context.stroke(ticks, with: .color(.black), lineWidth: Design.Stroke.hairline)
                    if let bar = page.calibrationBar {
                        var path = Path()
                        path.move(to: CGPoint(x: bar.x * scale, y: bar.y * scale))
                        path.addLine(to: CGPoint(x: (bar.x + bar.lengthMM) * scale, y: bar.y * scale))
                        context.stroke(path, with: .color(.black), lineWidth: Design.Stroke.hairline)
                    }
                }
                .allowsHitTesting(false)
                // While copies appear row by row, the marks wait too: alone they read as an empty, broken page.
                .opacity(revealedRows == nil ? 1 : 0)
            }
            .animation(Design.Motion.rearrange.resolved(animated: animated), value: page.placements)
        }
        .overlay(Rectangle().strokeBorder(.secondary, lineWidth: Design.Stroke.hairline))
        .clipped()
    }

    /// Faint dashed outlines on the white paper: the free grid positions and the copies still waiting to appear.
    private func emptySlots(hidden: Set<Key>, scale: CGFloat) -> some View {
        let waiting = page.placements.filter { hidden.contains(Key(item: $0.itemID, copy: $0.copyIndex)) }.map(\.trim)
        let rects = page.freeSlots.map(\.trim) + waiting
        return Canvas { context, _ in
            var path = Path()
            for rect in rects {
                path.addRect(CGRect(x: rect.x * scale, y: rect.y * scale, width: rect.width * scale, height: rect.height * scale))
            }
            // The paper is white in both appearances, so the outline is always dark.
            context.stroke(path, with: .color(.black.opacity(0.28)),
                           style: StrokeStyle(lineWidth: Design.Stroke.hairline, dash: [3, 2]))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var layoutSignature: String {
        let rotation = page.placements.allSatisfy(\.rotated) ? "r" : page.placements.contains(where: \.rotated) ? "m" : "u"
        let anchor = page.placements.first.map { "\(Int($0.trim.x * 10)),\(Int($0.trim.y * 10))" } ?? "-"
        return "\(page.widthMM)x\(page.heightMM)-\(page.bleedMM)-\(rotation)-\(anchor)"
    }

    private var hiddenPlacements: Set<Key> {
        guard let revealedRows else { return [] }
        let waiting = page.displayRows.dropFirst(revealedRows).flatMap { $0 }
        return Set(waiting.map { Key(item: page.placements[$0].itemID, copy: page.placements[$0].copyIndex) })
    }

    @ViewBuilder private func placementView(_ placement: Placement, scale: CGFloat) -> some View {
        let trimWidth = placement.trim.width * scale, trimHeight = placement.trim.height * scale
        ZStack {
            Rectangle().fill(Color.gray.opacity(0.25))
            if let thumbnail = thumbnails[placement.itemID] {
                Image(decorative: thumbnail, scale: 1)
                    .resizable()
                    .frame(width: placement.rotated ? trimHeight : trimWidth, height: placement.rotated ? trimWidth : trimHeight)
                    .rotationEffect(.degrees(placement.rotated ? 90 : 0))
                    .frame(width: trimWidth, height: trimHeight)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray.opacity(0.6)).frame(width: trimWidth, height: trimHeight)
            }
        }
    }
}
