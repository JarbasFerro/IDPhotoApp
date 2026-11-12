import SwiftUI

/// Step 3 (design 3b): the paper is the hero; people, copies and paper sit in one tray at thumb height.
/// Extra sizes, custom paper and cutting options live in the options sheet.
struct SheetView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var selectedPerson: UUID?
    @State private var showOptions = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var person: PhotoEntry? { model.entries.first { $0.id == selectedPerson } ?? model.entries.first }

    var body: some View {
        let layout = model.layout
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: Design.Spacing.group) {
                        paper(layout, box: CGSize(width: 260, height: 260))
                        trayContent(layout).padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        // Room for the summary line, and for the page captions when there are several pages.
                        let reserved: CGFloat = layout.pages.count > 1 ? 96 : 64
                        paper(layout, box: CGSize(width: max(160, geometry.size.width - 48),
                                                  height: max(160, geometry.size.height - reserved)))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    trayContent(layout)
                        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, Design.Spacing.text)
                        .background {
                            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                                .fill(Design.Surface.card)
                                .ignoresSafeArea(edges: .bottom)
                        }
                }
            }
        }
        .background(Design.Surface.screen)
        .navigationTitle("Your sheet")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOptions) { SheetOptionsView(model: model) }
        .task { model.refreshSheetThumbnails() }
        .onChange(of: model.printJob.items.map { "\($0.id)-\($0.photoID)" }) { _, _ in model.refreshSheetThumbnails() }
    }

    private func paper(_ layout: PrintLayout, box: CGSize) -> some View {
        VStack(spacing: Design.Spacing.text) {
            SheetPreview(layout: layout, thumbnails: model.sheetThumbnails, pageBox: box)
            Text(summary(layout))
                .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                .accessibilityIdentifier("layoutSummary")
        }
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
                    Stepper("Copies", value: copies, in: 0...50)
                        .labelsHidden()
                        .accessibilityIdentifier("copiesStepper")
                }
            }
            paperChips
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
        return Button { selectedPerson = entry.id } label: {
            PortraitView(entry: entry, format: model.renderTarget.format)
                .frame(width: 52)
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
                }
        }
        .buttonStyle(.plain)
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
            Text(PaperNames.short(for: paper)).foregroundStyle(selected ? Color.brandAccent : Color.primary)
        }
            .buttonStyle(.bordered).buttonBorderShape(.capsule)
            .tint(selected ? Color.brandAccent : Color.gray)
            .fontWeight(selected ? .semibold : .regular)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("paper-\(paper.id)")
    }

    private func copiesBinding(for person: PhotoEntry) -> Binding<Int>? {
        guard let id = model.printItems(for: person.id).first?.id else { return nil }
        return Binding(get: { model.printJob.items.first { $0.id == id }?.copies ?? 0 },
                       set: { value in
                           if let index = model.printJob.items.firstIndex(where: { $0.id == id }) { model.printJob.items[index].copies = value }
                       })
    }

    private func summary(_ layout: PrintLayout) -> String {
        // AttributedString applies the ^[…](inflect: true) grammar; String(localized:) would show the markup.
        String(AttributedString(localized: "^[\(layout.placedCount) copy](inflect: true) · ^[\(layout.pages.count) page](inflect: true)").characters)
    }
}

/// Everything about the sheet that is not needed every time: extra sizes per person, any paper, cutting options.
struct SheetOptionsView: View {
    @Bindable var model: PhotoWorkflow
    @Environment(\.dismiss) private var dismiss
    @State private var customWidth = 100.0
    @State private var customHeight = 150.0
    @State private var customError = false
    @State private var showCutting = false
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

                Section {
                    DisclosureGroup("Cutting options", isExpanded: $showCutting) {
                        Picker("Orientation", selection: $model.printJob.options.orientation) {
                            Text("Automatic").tag(PageOrientation.automatic)
                            Text("Portrait").tag(PageOrientation.portrait)
                            Text("Landscape").tag(PageOrientation.landscape)
                        }
                        Toggle("Safety margin around each photo", isOn: bleedBinding)
                        Toggle("Corner cut marks", isOn: $model.printJob.options.cornerTicks)
                        Toggle("50 mm check bar", isOn: $model.printJob.options.calibrationBar)
                        Toggle("As many copies as possible", isOn: maximumCopiesBinding)
                        Picker("Order on the page", selection: $model.printJob.options.fillStrategy) {
                            Text("One size at a time").tag(FillStrategy.byType)
                            Text("Mix sizes").tag(FillStrategy.interleave)
                        }
                    }
                    .accessibilityIdentifier("cuttingOptions")
                } footer: {
                    Text("The safety margin lets a slightly off cut stay inside the photo. The check bar lets you confirm the print is at real size.")
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
    let layout: PrintLayout
    /// Crops per print item; placements without one are drawn as grey boxes.
    var thumbnails: [UUID: CGImage] = [:]
    /// First page only, no captions, for cards.
    var compact = false
    var compactHeight: CGFloat = 130
    /// The space each full page is fitted into, keeping the paper's proportions.
    var pageBox = CGSize(width: 260, height: 260)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pages = compact ? Array(layout.pages.prefix(1)) : layout.pages
        if compact, let page = pages.first {
            SheetPageView(page: page, thumbnails: thumbnails, animated: false)
                .aspectRatio(page.widthMM / page.heightMM, contentMode: .fit)
                .frame(height: compactHeight)
                .accessibilityLabel(Text("Page 1 of \(layout.pages.count): \(page.placements.count) photos"))
                .accessibilityIdentifier("sheetThumbnail")
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Design.Spacing.group) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        let aspect = page.widthMM / page.heightMM
                        let width = min(pageBox.width, pageBox.height * aspect)
                        VStack(spacing: Design.Spacing.tight) {
                            SheetPageView(page: page, thumbnails: thumbnails, animated: !reduceMotion)
                                .frame(width: width, height: width / aspect)
                                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                            if layout.pages.count > 1 {
                                Text("Page \(index + 1) of \(layout.pages.count)").font(Design.Typography.caption)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Page \(index + 1) of \(layout.pages.count): \(page.placements.count) photos"))
                    }
                    if layout.pages.isEmpty {
                        ContentUnavailableView("Nothing to print", systemImage: "printer",
                                               description: Text("Add copies or choose a larger paper."))
                            .frame(height: 220)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            // One page sits in the middle; several pages start at the first and scroll.
            .defaultScrollAnchor(.center, for: .alignment)
            .accessibilityIdentifier("sheetPreview")
        }
    }
}

struct SheetPageView: View {
    let page: PrintPage
    let thumbnails: [UUID: CGImage]
    var animated = true

    private struct Key: Hashable { let item: UUID; let copy: Int }
    private struct Keyed: Identifiable { let id: Key; let placement: Placement }
    private var keyed: [Keyed] { page.placements.map { Keyed(id: Key(item: $0.itemID, copy: $0.copyIndex), placement: $0) } }

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / page.widthMM, geometry.size.height / page.heightMM)
            ZStack(alignment: .topLeading) {
                Color.white
                ForEach(keyed) { item in
                    let placement = item.placement
                    placementView(placement, scale: scale)
                        .frame(width: placement.bleed.width * scale, height: placement.bleed.height * scale)
                        .position(x: (placement.bleed.x + placement.bleed.width / 2) * scale,
                                  y: (placement.bleed.y + placement.bleed.height / 2) * scale)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
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
            }
            .animation(Design.Motion.rearrange.resolved(animated: animated), value: page.placements)
        }
        .overlay(Rectangle().strokeBorder(.secondary, lineWidth: Design.Stroke.hairline))
        .clipped()
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
