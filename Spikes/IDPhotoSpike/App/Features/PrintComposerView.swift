import SwiftUI

/// Paper, copies, and sheet options with a live preview of the solved layout.
struct PrintComposerView: View {
    @Bindable var model: PhotoWorkflow
    @Environment(\.dismiss) private var dismiss
    @State private var customWidth = 100.0
    @State private var customHeight = 150.0
    @State private var customError = false

    var body: some View {
        let layout = model.layout
        NavigationStack {
            List {
                Section {
                    SheetPreview(layout: layout)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    Text(summary(layout))
                        .font(.subheadline)
                        .accessibilityIdentifier("layoutSummary")
                    if !layout.isComplete {
                        Label("\(layout.unplacedCount) copies do not fit within \(model.printJob.options.maxPages) pages.",
                              systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
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
                            Text("Enter sizes between 50 and 500 mm.").font(.footnote).foregroundStyle(.secondary)
                        }
                        Text("AirPrint uses the nearest paper your printer offers; share the PDF or JPEG for other sizes.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Picker("Orientation", selection: $model.printJob.options.orientation) {
                        Text("Automatic").tag(PageOrientation.automatic)
                        Text("Portrait").tag(PageOrientation.portrait)
                        Text("Landscape").tag(PageOrientation.landscape)
                    }
                }

                Section {
                    ForEach($model.printJob.items) { $item in
                        Stepper(value: $item.copies, in: 0...50) {
                            LabeledContent(formatName(item), value: "\(item.copies)")
                        }
                        .accessibilityIdentifier("copies-\(item.id.uuidString)")
                    }
                    .onDelete(perform: model.removePrintItems)
                    .onMove(perform: model.movePrintItems)
                    ForEach(PhotoFormat.presets) { format in
                        Button {
                            model.addPrintItem(format: format)
                        } label: {
                            Label(String(localized: "Add \(formatName(format))"), systemImage: "plus")
                        }
                        .accessibilityIdentifier("add-\(format.id)")
                    }
                } header: {
                    Text("Photos on this sheet")
                } footer: {
                    Text("This prototype places crops of the same photo. Different people per sheet use the same layout engine.")
                }

                Section("Cutting") {
                    Toggle("Bleed up to 1 mm", isOn: bleedBinding)
                    Toggle("Corner cut marks", isOn: $model.printJob.options.cornerTicks)
                    Toggle("50 mm calibration bar", isOn: $model.printJob.options.calibrationBar)
                    Toggle("Maximum copies (shared cuts, no bleed)", isOn: maximumCopiesBinding)
                    Picker("Fill order", selection: $model.printJob.options.fillStrategy) {
                        Text("One size at a time").tag(FillStrategy.byType)
                        Text("Mix sizes on every page").tag(FillStrategy.interleave)
                    }
                }
            }
            .navigationTitle("Print sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
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
        case PaperSize.photo10x15.id: return String(localized: "10 × 15 cm (100 × 150 mm)")
        case PaperSize.photo4x6.id: return String(localized: "4 × 6 in (101.6 × 152.4 mm)")
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

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(layout.pages.enumerated()), id: \.offset) { index, page in
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
                                context.fill(Path(rect(placement.trim)), with: .color(.gray.opacity(0.6)))
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
                        .frame(height: 220)
                        Text("Page \(index + 1) of \(layout.pages.count)").font(.caption)
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
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.visible)
        .accessibilityIdentifier("sheetPreview")
    }
}
