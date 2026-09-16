import SwiftUI

/// Step 3: the live sheet is the hero; people, paper and options below; Continue leads to Share.
struct SheetView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var customWidth = 100.0
    @State private var customHeight = 150.0
    @State private var customError = false
    @State private var showOptions = false
    @State private var addingSizeFor: UUID?

    var body: some View {
        let layout = model.layout
        List {
            Section {
                SheetPreview(layout: layout, thumbnails: model.sheetThumbnails)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                Text(summary(layout))
                    .font(.subheadline)
                    .accessibilityIdentifier("layoutSummary")
                if !layout.isComplete {
                    StatusLabel(text: "\(layout.unplacedCount) copies do not fit within \(model.printJob.options.maxPages) pages.", state: .warn)
                        .font(.subheadline)
                }
            }

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
                    HStack(spacing: 10) {
                        PortraitView(entry: entry).frame(width: 28)
                        Text(model.entries.count > 1 ? LocalizedStringKey("Photo \(index + 1)") : LocalizedStringKey("Your photo"))
                        Spacer()
                        Button { path.append(.check(entry.id)) } label: {
                            Text("Check").font(.subheadline).textCase(nil).frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityIdentifier("person-\(index + 1)")
                    }
                    .accessibilityElement(children: .contain)
                }
            }

            Section {
                Menu {
                    Button { acquire(.camera, .add) } label: { Label("Take Photo", systemImage: "camera") }
                        .accessibilityIdentifier("addPersonCamera")
                    Button { acquire(.library, .add) } label: { Label("Choose Photo", systemImage: "photo.on.rectangle") }
                        .accessibilityIdentifier("addPersonLibrary")
                } label: {
                    Label(model.canAddPhoto ? LocalizedStringKey("Add another person") : LocalizedStringKey("Sheet is full (\(PhotoWorkflow.maxPhotos) people)"),
                          systemImage: "person.badge.plus")
                }
                .disabled(!model.canAddPhoto || model.activity != nil)
                .accessibilityIdentifier("addPerson")
            } footer: {
                Text("Each person keeps their own framing, background and light. Everyone shares the sheet.")
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
                        Text("Enter sizes between 50 and 500 mm.").font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("AirPrint uses the nearest paper your printer offers; share the PDF or JPEG for other sizes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section {
                DisclosureGroup("Cutting options", isExpanded: $showOptions) {
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
        .navigationTitle("Your sheet")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button { path.append(.share) } label: {
                Label("Continue", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
            .disabled(layout.pages.isEmpty || model.activity != nil)
            .accessibilityIdentifier("continueToShare")
        }
        .confirmationDialog("Add a size", isPresented: Binding(get: { addingSizeFor != nil }, set: { if !$0 { addingSizeFor = nil } }),
                            titleVisibility: .visible, presenting: addingSizeFor) { photoID in
            ForEach(PhotoFormat.presets) { format in
                Button(formatName(format)) { model.addPrintItem(format: format, photoID: photoID) }
            }
        } message: { _ in
            Text("Sizes for other documents; each one gets its own copies.")
        }
        .task { model.refreshSheetThumbnails() }
        .onChange(of: model.printJob.items.map { "\($0.id)-\($0.photoID)" }) { _, _ in model.refreshSheetThumbnails() }
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

    private func summary(_ layout: PrintLayout) -> String {
        let pages = layout.pages.count
        let paper = PaperNames.name(for: model.printJob.paper)
        return String(localized: "\(paper) · \(pages) page(s) · \(layout.placedCount) of \(model.printJob.requestedCopies) copies placed")
    }

    private func formatName(_ item: PrintItem) -> String {
        formatName(PhotoFormat.format(widthMM: item.trimWidthMM, heightMM: item.trimHeightMM))
    }

    private func formatName(_ format: PhotoFormat) -> String {
        let width = format.widthMM.formatted(.number.precision(.fractionLength(0...1)))
        let height = format.heightMM.formatted(.number.precision(.fractionLength(0...1)))
        return String(localized: "\(width) × \(height) mm")
    }
}

enum PaperNames {
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

/// Schematic pages drawn from the layout: trim rectangles, bleed, ticks, and the calibration bar.
struct SheetPreview: View {
    let layout: PrintLayout
    /// Crops per print item; placements without one are drawn as grey boxes.
    var thumbnails: [UUID: CGImage] = [:]
    /// First page only, no captions, for cards.
    var compact = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array((compact ? Array(layout.pages.prefix(1)) : layout.pages).enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 4) {
                        Canvas { context, size in
                            let scale = min(size.width / page.widthMM, size.height / page.heightMM)
                            let origin = CGPoint(x: (size.width - page.widthMM * scale) / 2,
                                                 y: (size.height - page.heightMM * scale) / 2)
                            func rect(_ r: MillimeterRect) -> CGRect {
                                CGRect(x: origin.x + r.x * scale, y: origin.y + r.y * scale,
                                       width: r.width * scale, height: r.height * scale)
                            }
                            let paper = CGRect(origin: origin, size: CGSize(width: page.widthMM * scale, height: page.heightMM * scale))
                            context.fill(Path(paper), with: .color(.white))
                            context.stroke(Path(paper), with: .color(.secondary), lineWidth: 1)
                            for placement in page.placements {
                                context.fill(Path(rect(placement.bleed)), with: .color(.gray.opacity(0.25)))
                                let trim = rect(placement.trim)
                                if let thumbnail = thumbnails[placement.itemID] {
                                    context.drawLayer { layer in
                                        layer.clip(to: Path(trim))
                                        if placement.rotated {
                                            layer.translateBy(x: trim.midX, y: trim.midY)
                                            layer.rotate(by: .degrees(90))
                                            layer.draw(Image(decorative: thumbnail, scale: 1),
                                                       in: CGRect(x: -trim.height / 2, y: -trim.width / 2, width: trim.height, height: trim.width))
                                        } else {
                                            layer.draw(Image(decorative: thumbnail, scale: 1), in: trim)
                                        }
                                    }
                                } else {
                                    context.fill(Path(trim), with: .color(.gray.opacity(0.6)))
                                }
                            }
                            var ticks = Path()
                            for tick in page.cornerTicks {
                                ticks.move(to: CGPoint(x: origin.x + tick.fromX * scale, y: origin.y + tick.fromY * scale))
                                ticks.addLine(to: CGPoint(x: origin.x + tick.toX * scale, y: origin.y + tick.toY * scale))
                            }
                            context.stroke(ticks, with: .color(.primary), lineWidth: 1)
                            if let bar = page.calibrationBar {
                                var path = Path()
                                path.move(to: CGPoint(x: origin.x + bar.x * scale, y: origin.y + bar.y * scale))
                                path.addLine(to: CGPoint(x: origin.x + (bar.x + bar.lengthMM) * scale, y: origin.y + bar.y * scale))
                                context.stroke(path, with: .color(.primary), lineWidth: 1)
                            }
                        }
                        .aspectRatio(page.widthMM / page.heightMM, contentMode: .fit)
                        .frame(height: compact ? 130 : 220)
                        if !compact { Text("Page \(index + 1) of \(layout.pages.count)").font(.caption) }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Page \(index + 1) of \(layout.pages.count): \(page.placements.count) photos"))
                }
                if layout.pages.isEmpty, !compact {
                    ContentUnavailableView("Nothing to print", systemImage: "printer",
                                           description: Text("Add copies or choose a larger paper."))
                        .frame(height: 220)
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(compact ? .hidden : .visible)
        .scrollDisabled(compact)
        .accessibilityIdentifier(compact ? "sheetThumbnail" : "sheetPreview")
    }
}
