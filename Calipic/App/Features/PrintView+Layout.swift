import SwiftUI

extension PrintView {
    var layoutControls: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.entries.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: Design.Spacing.cardContent) {
                        ForEach(Array(model.entries.enumerated()), id: \.element.id) { index, entry in personCircle(entry, index: index) }
                    }.padding(.vertical, 8).padding(.horizontal, 4)
                }.scrollIndicators(.hidden)
            }
            TrayRows(leadingInset: 0) {
                if let person, let copies = copiesBinding(for: person) {
                    VStack(alignment: .leading, spacing: 0) {
                        TrayRow(title: Text("Copies"), detail: model.entries.count > 1 ? Text(model.label(for: person.id)) : nil,
                                value: Text(copies.wrappedValue, format: .number).monospacedDigit(), trailing: {
                            Stepper("Copies", onIncrement: { copies.wrappedValue = steppedCopies(from: copies.wrappedValue, up: true) },
                                    onDecrement: { copies.wrappedValue = steppedCopies(from: copies.wrappedValue, up: false) })
                                .labelsHidden().fixedSize()
                                .accessibilityValue(Text("^[\(copies.wrappedValue) copy](inflect: true)"))
                                .sensoryFeedback(.selection, trigger: copiesTick)
                                .guideTarget(.copies, current: guideTip).accessibilityIdentifier("copiesStepper")
                        })
                        .contentTransition(.numericText(value: Double(copies.wrappedValue)))
                        .animation(reduceMotion ? nil : .snappy, value: copies.wrappedValue)
                        if !fill.isEmpty { fillMenu(for: person).frame(minHeight: 44) }
                    }
                }
                TrayRow(title: Text("Paper"), trailing: { paperChips })
            }
            if !model.layout.isComplete {
                TrayRow(title: Text("\(model.layout.unplacedCount) copies do not fit within \(model.printJob.options.maxPages) pages."),
                        leading: { StatusMark(.warn) })
            }
        }
    }

    var paperChips: some View {
        let current = model.printJob.paper
        let quick = PaperNames.quickPapers
        return ScrollView(.horizontal) {
            HStack(spacing: Design.Spacing.text) {
                if !quick.contains(where: { $0.id == current.id }) { paperChip(current) }
                ForEach(quick) { paperChip($0) }
                Button { showOptions = true } label: { Text("More").frame(minHeight: 44) }.accessibilityIdentifier("morePaperOptions")
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.trailing, Design.Spacing.tray, for: .scrollContent)
        .padding(.trailing, -Design.Spacing.tray)
        .sensoryFeedback(.selection, trigger: model.printJob.paper.id)
        .guideTarget(.paper, current: guideTip, cornerRadius: 24)
    }

    func summary(_ layout: PrintLayout) -> String {
        let paper = PaperNames.short(for: model.printJob.paper)
        var text = String(AttributedString(localized: "^[\(layout.placedCount) copy](inflect: true) on \(paper) paper").characters)
        if layout.pages.count > 1 { text += " · " + String(AttributedString(localized: "^[\(layout.pages.count) page](inflect: true)").characters) }
        let room = layout.pages.last?.freeSlots.count ?? 0
        if room > 0 { text += " · " + String(localized: "Room for \(room) more") }
        return text
    }

    func revealCopies() async {
        guard !hasRevealed else { return }
        hasRevealed = true
        guard !reduceMotion, let index = path.lastIndex(of: .sheet), index > 0, case .check = path[index - 1],
              let rows = model.layout.pages.first?.displayRows.count, rows > 1 else { revealedRows = nil; return }
        do {
            try await Task.sleep(for: .milliseconds(300))
            for row in 1...rows {
                try Task.checkCancellation()
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { revealedRows = row }
                try await Task.sleep(for: .milliseconds(110))
            }
            withAnimation(.easeOut(duration: 0.25)) { revealedRows = nil }
        } catch { revealedRows = nil }
    }
    func personCircle(_ entry: PhotoEntry, index: Int) -> some View {
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

    func paperChip(_ paper: PaperSize) -> some View {
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
    func fillMenu(for person: PhotoEntry) -> some View {
        let request = fillRequest
        return Menu {
            ForEach(fill, id: \.pages) { choice in
                Button {
                    // A native menu can outlive the SwiftUI content that opened it.
                    guard request == fillRequest else { return }
                    if let copies = copiesBinding(for: person) { copies.wrappedValue = choice.copies }
                } label: {
                    Text("^[\(choice.pages) page](inflect: true) · ^[\(choice.copies) copy](inflect: true)")
                }
                .accessibilityIdentifier("fill-\(choice.pages)")
            }
        } label: {
            Text("Fill pages")
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.brandAccent)
        .accessibilityLabel(Text("Fill pages"))
        .accessibilityIdentifier("fillPages")
    }

    func steppedCopies(from copies: Int, up: Bool) -> Int {
        min(max(copies + (up ? 1 : -1), 0), max(200, copies))
    }

    func copiesBinding(for person: PhotoEntry) -> Binding<Int>? {
        guard let id = model.printItems(for: person.id).first?.id else { return nil }
        return Binding(get: { model.printJob.items.first { $0.id == id }?.copies ?? 0 },
                       set: { value in
                           if let index = model.printJob.items.firstIndex(where: { $0.id == id }), model.printJob.items[index].copies != value {
                               model.printJob.items[index].copies = value
                               copiesTick += 1
                           }
                       })
    }

}
