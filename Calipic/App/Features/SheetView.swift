import SwiftUI

enum SheetChoices {
    struct FillChoice: Sendable { let pages: Int; let copies: Int }
    struct Request: Hashable, Sendable {
        let job: PrintJob
        let itemID: UUID?

        /// The choices never depend on the item's own count, so it is left out: tapping + or − keeps the
        /// cached choices instead of hiding the Fill row until they are recomputed (founder's recording, 0.21.7).
        init(job: PrintJob, itemID: UUID?) {
            var job = job
            if let itemID, let index = job.items.firstIndex(where: { $0.id == itemID }) { job.items[index].copies = 1 }
            self.job = job
            self.itemID = itemID
        }
    }
    struct Snapshot: Sendable {
        let request: Request
        let values: [FillChoice]

        func choices(for current: Request) -> [FillChoice] { current == request ? values : [] }
    }

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
        return page.displaySizeMM.width * pointsPerMM
    }

    /// One scale for every page, the tightest fit among them, so a page shown turned (its photos lie sideways) is not
    /// drawn larger than an upright one: the same photo is the same size on every page (founder, 0.21.10).
    private var pointsPerMM: CGFloat {
        let fits = layout.pages.map { page -> CGFloat in
            let size = page.displaySizeMM
            return min(pageBox.width / size.width, pageBox.height / size.height)
        }
        return fits.min() ?? 1
    }

    let layout: PrintLayout
    /// Crops per print item; placements without one are drawn as grey boxes.
    var thumbnails: [UUID: CGImage] = [:]
    /// "Page 1 of 2" under each page. Off when the pages lie on the mat, where bare text is not allowed.
    var captions = true
    /// The space each full page is fitted into, keeping the paper's proportions.
    var pageBox = CGSize(width: 260, height: 260)
    /// Rows of the first page to show; nil shows them all.
    var revealedRows: Int?
    var unlockTrigger = 0
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
        let pages = layout.pages
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: Design.Spacing.group) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        let size = page.displaySizeMM
                        let width = size.width * pointsPerMM
                        let aspect = size.width / size.height
                        VStack(spacing: Design.Spacing.tight) {
                            UprightPageView(page: page, thumbnails: thumbnails, animated: !reduceMotion,
                                            revealedRows: rows(onPage: index), showsEmptySlots: true)
                                .frame(width: width, height: width / aspect)
                                .paperDimmedInDark()
                                .paperShadow()
                                .unlockCelebration(trigger: unlockTrigger)
                            if captions, layout.pages.count > 1 {
                                Text("Page \(index + 1) of \(layout.pages.count)").font(Design.Typography.caption)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Page \(index + 1) of \(layout.pages.count): \(page.placements.count) photos"))
                        .accessibilityIdentifier("sheetPage-\(index)")
                        .id(index)
                    }
                    if layout.pages.isEmpty {
                        ContentUnavailableView("Nothing to print", systemImage: "printer",
                                               description: Text("Add copies or choose a larger paper."))
                            .frame(height: 220)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 0)
            }
            // Pages snap one at a time and sit in the middle of the mat; the margin centres a page of the first one's
            // width, so a single page sits centred too.
            .contentMargins(.horizontal, max(4, (pageBox.width - firstPageWidth) / 2), for: .scrollContent)
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
            .frame(height: pageBox.height)
            .padding(.bottom, 24)
            .onDisappear {
                arrival?.cancel(); arrival = nil
                arrivingFrom = nil; arrivingRows = 0
            }
            .overlay(alignment: .bottom) {
                if layout.pages.count > 1 { PageDots(count: layout.pages.count, selection: $focusedPage).frame(height: 44).fixedSize(horizontal: true, vertical: false).offset(y: 10) }
            }
            .accessibilityIdentifier("sheetPreview")
    }
}

extension SheetPreview {
    /// New pages slide in empty, showing only their outlined slots, then their copies drop in row by row, as on the
    /// first page after Photo Check (founder's recording, 0.20.11: a new page arrived already full). Not under
    /// Reduce Motion.
    fileprivate func fill(newPagesFrom first: Int) {
        arrival?.cancel()
        guard !reduceMotion else { return }
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

    /// The page's size as shown on screen, in millimetres.
    var displaySizeMM: CGSize { displaysTurned ? CGSize(width: heightMM, height: widthMM) : CGSize(width: widthMM, height: heightMM) }
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

/// Native page indicators keep the existing scrolling strip and its copy animations.
private struct PageDots: UIViewRepresentable {
    let count: Int
    @Binding var selection: Int?
    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }
    func makeUIView(context: Context) -> UIPageControl {
        let view = UIPageControl()
        view.backgroundStyle = .prominent
        view.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return view
    }
    func updateUIView(_ view: UIPageControl, context: Context) {
        context.coordinator.selection = $selection
        view.numberOfPages = count
        view.currentPage = min(max(0, selection ?? 0), max(0, count - 1))
    }
    @MainActor final class Coordinator: NSObject {
        var selection: Binding<Int?>
        init(selection: Binding<Int?>) { self.selection = selection }
        @objc func changed(_ view: UIPageControl) {
            withAnimation(Design.Motion.rearrange.resolved(reduceMotion: UIAccessibility.isReduceMotionEnabled)) { selection.wrappedValue = view.currentPage }
        }
    }
}
