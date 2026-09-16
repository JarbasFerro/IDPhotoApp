import Foundation

// Print-sheet domain: pure Swift, deterministic, no UI or graphics imports.
// Page coordinates are physical millimetres with a top-left origin (`PageMillimeterSpace`).
// The solver itself works in integer micrometres so identical inputs give identical layouts.

struct MillimeterRect: Sendable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var minX: Double { x }
    var minY: Double { y }
    var maxX: Double { x + width }
    var maxY: Double { y + height }

    func insetBy(_ amount: Double) -> MillimeterRect {
        MillimeterRect(x: x + amount, y: y + amount, width: width - 2 * amount, height: height - 2 * amount)
    }

    func overlaps(_ other: MillimeterRect, tolerance: Double = 0.0005) -> Bool {
        minX < other.maxX - tolerance && other.minX < maxX - tolerance
            && minY < other.maxY - tolerance && other.minY < maxY - tolerance
    }
}

struct PaperSize: Sendable, Hashable, Identifiable {
    let id: String
    let widthMM: Double
    let heightMM: Double
    let isCustom: Bool

    static let photo10x15 = PaperSize(id: "photo-10x15", widthMM: 100, heightMM: 150, isCustom: false)
    static let photo4x6 = PaperSize(id: "photo-4x6", widthMM: 101.6, heightMM: 152.4, isCustom: false)
    static let photo13x18 = PaperSize(id: "photo-13x18", widthMM: 127, heightMM: 178, isCustom: false)
    static let photo9x13 = PaperSize(id: "photo-9x13", widthMM: 89, heightMM: 127, isCustom: false)
    static let a6 = PaperSize(id: "a6", widthMM: 105, heightMM: 148, isCustom: false)
    static let a5 = PaperSize(id: "a5", widthMM: 148, heightMM: 210, isCustom: false)
    static let a4 = PaperSize(id: "a4", widthMM: 210, heightMM: 297, isCustom: false)
    static let usLetter = PaperSize(id: "us-letter", widthMM: 215.9, heightMM: 279.4, isCustom: false)

    static let presets: [PaperSize] = [photo10x15, photo4x6, photo13x18, photo9x13, a6, a5, a4, usLetter]

    static let customRange: ClosedRange<Double> = 50...500

    enum ValidationError: Error, Equatable { case outOfRange }

    static func custom(widthMM: Double, heightMM: Double) throws -> PaperSize {
        guard widthMM.isFinite, heightMM.isFinite,
              customRange.contains(widthMM), customRange.contains(heightMM) else {
            throw ValidationError.outOfRange
        }
        return PaperSize(id: "custom", widthMM: widthMM, heightMM: heightMM, isCustom: true)
    }
}

struct PrintItem: Sendable, Hashable, Identifiable {
    var id = UUID()
    var photoID: UUID
    var trimWidthMM: Double
    var trimHeightMM: Double
    var copies: Int
    var allowsRotation = true
}

enum BleedPolicy: Sendable, Hashable {
    /// Largest bleed in {max, max/2, 0} that does not reduce the page count.
    case adaptive(maxMM: Double)
    case fixed(mm: Double)
    case none

    var candidatesMM: [Double] {
        switch self {
        case .adaptive(let max): [max, max / 2, 0]
        case .fixed(let mm): [mm]
        case .none: [0]
        }
    }
}

enum FillStrategy: Sendable, Hashable, CaseIterable { case byType, interleave }
enum PageOrientation: Sendable, Hashable, CaseIterable { case automatic, portrait, landscape }

struct PrintOptions: Sendable, Hashable {
    /// Paper edge to the bleed edge. Trim edges therefore sit `marginMM + bleed` from the paper edge.
    var marginMM: Double = 4
    /// Space between neighbouring bleed boxes; corner ticks live here.
    var gutterMM: Double = 2
    var bleed: BleedPolicy = .adaptive(maxMM: 1)
    var cornerTicks = true
    var calibrationBar = true
    var fillStrategy: FillStrategy = .byType
    var orientation: PageOrientation = .automatic
    var maxPages = 10

    /// Opt-in: shared cut lines, no bleed. A cut error makes one photo oversize and its neighbour undersize.
    static let maximumCopies = PrintOptions(marginMM: 3, gutterMM: 0, bleed: .none, cornerTicks: true,
                                            calibrationBar: true)
}

struct PrintJob: Sendable, Hashable {
    var paper: PaperSize
    var items: [PrintItem]
    var options = PrintOptions()

    var requestedCopies: Int { items.reduce(0) { $0 + max(0, $1.copies) } }
}

struct Placement: Sendable, Hashable {
    let itemID: UUID
    let copyIndex: Int
    /// Final photo size after cutting.
    let trim: MillimeterRect
    /// Printed raster extent; equals `trim` when bleed is zero.
    let bleed: MillimeterRect
    /// The upright photo raster is turned 90° clockwise on the page.
    let rotated: Bool
}

struct CalibrationBar: Sendable, Hashable {
    let x: Double
    let y: Double
    let lengthMM: Double
}

struct PrintPage: Sendable, Hashable {
    let widthMM: Double
    let heightMM: Double
    let bleedMM: Double
    let placements: [Placement]
    let calibrationBar: CalibrationBar?

    var utilisation: Double {
        placements.reduce(0) { $0 + $1.trim.width * $1.trim.height } / (widthMM * heightMM)
    }
}

struct PrintLayout: Sendable, Hashable {
    let pages: [PrintPage]
    /// Copies that did not fit within `maxPages` or that are larger than the printable area.
    let unplaced: [UUID: Int]

    var placedCount: Int { pages.reduce(0) { $0 + $1.placements.count } }
    var unplacedCount: Int { unplaced.values.reduce(0, +) }
    var isComplete: Bool { unplacedCount == 0 }

    /// Rasters are rendered per item and per page bleed, because bleed can differ between pages.
    struct RasterKey: Hashable, Sendable {
        let itemID: UUID
        let bleedMicrometers: Int
        init(itemID: UUID, bleedMM: Double) {
            self.itemID = itemID
            self.bleedMicrometers = PrintLayoutSolver.micrometers(bleedMM)
        }
    }

    var rasterKeys: Set<RasterKey> {
        Set(pages.flatMap { page in page.placements.map { RasterKey(itemID: $0.itemID, bleedMM: page.bleedMM) } })
    }
}

/// Two-stage guillotine (row) packer with exhaustive search over type order, per-row photo orientation,
/// row-major vs column-major stacking, paper orientation, and bleed candidates.
enum PrintLayoutSolver {
    static let tickLengthMM = 3.0
    static let calibrationBarLengthMM = 50.0
    private static let calibrationReserve = micrometers(6)

    static func micrometers(_ mm: Double) -> Int { Int((mm * 1_000).rounded()) }
    static func millimeters(_ um: Int) -> Double { Double(um) / 1_000 }

    static func solve(_ job: PrintJob) -> PrintLayout {
        let options = job.options
        let items = job.items
        var demand = items.map { max(0, $0.copies) }
        let margin = micrometers(options.marginMM)
        let gutter = micrometers(options.gutterMM)
        let bleeds = options.bleed.candidatesMM.map(micrometers)
        let barChoices = options.calibrationBar ? [true, false] : [false]
        let portraitSize = (w: micrometers(min(job.paper.widthMM, job.paper.heightMM)),
                            h: micrometers(max(job.paper.widthMM, job.paper.heightMM)))
        var orientations: [(w: Int, h: Int)]
        switch options.orientation {
        case .automatic:
            orientations = portraitSize.w == portraitSize.h ? [portraitSize] : [portraitSize, (portraitSize.h, portraitSize.w)]
        case .portrait: orientations = [portraitSize]
        case .landscape: orientations = [(portraitSize.h, portraitSize.w)]
        }

        var pages: [PrintPage] = []
        while demand.contains(where: { $0 > 0 }), pages.count < max(1, options.maxPages) {
            var best: (score: [Int], plan: PagePlan, pageW: Int, pageH: Int, bleed: Int, bar: Bool)?
            for (index, size) in orientations.enumerated() {
                for bleed in bleeds {
                    for bar in barChoices {
                        let reserve = bar ? calibrationReserve + gutter : 0
                        guard let plan = bestPlan(demand: demand, items: items, bleed: bleed,
                                                  availableWidth: size.w - 2 * margin,
                                                  availableHeight: size.h - 2 * margin - reserve,
                                                  gutter: gutter, strategy: options.fillStrategy) else { continue }
                        let score = [plan.placed, bleed, bar ? 1 : 0, -plan.distinctHeights, -plan.usedLength, -index]
                        if best == nil || best!.score.lexicographicallyPrecedes(score) {
                            best = (score, plan, size.w, size.h, bleed, bar)
                        }
                    }
                }
            }
            guard let best, best.plan.placed > 0 else { break }
            orientations = [(best.pageW, best.pageH)] // keep every page in the same orientation
            let page = makePage(plan: best.plan, items: items, startCopyIndex: items.map { $0.copies - demand[items.firstIndex(of: $0)!] },
                                pageW: best.pageW, pageH: best.pageH, margin: margin, gutter: gutter,
                                bleed: best.bleed, bar: best.bar)
            pages.append(page)
            for row in best.plan.rows { demand[row.cell.itemIndex] -= row.count }
        }
        var unplaced: [UUID: Int] = [:]
        for (index, remaining) in demand.enumerated() where remaining > 0 {
            unplaced[items[index].id] = remaining
        }
        return PrintLayout(pages: pages, unplaced: unplaced)
    }

    // MARK: - Planning in solve space (rows along the S-y axis)

    private struct Cell: Hashable {
        let itemIndex: Int
        let rotated: Bool
        let width: Int
        let height: Int
    }

    private struct Row: Hashable {
        let cell: Cell
        let count: Int
    }

    private struct PagePlan {
        var rows: [Row]
        var transposed: Bool
        var availableWidth: Int
        var availableHeight: Int
        var gutter: Int
        var placed: Int { rows.reduce(0) { $0 + $1.count } }
        var usedLength: Int { rows.reduce(0) { $0 + $1.cell.height } + max(0, rows.count - 1) * gutter }
        var distinctHeights: Int { Set(rows.map(\.cell.height)).count }
    }

    private static func bestPlan(demand: [Int], items: [PrintItem], bleed: Int, availableWidth: Int,
                                 availableHeight: Int, gutter: Int, strategy: FillStrategy) -> PagePlan? {
        guard availableWidth > 0, availableHeight > 0 else { return nil }
        let active = demand.indices.filter { demand[$0] > 0 }
        var best: (key: [Int], plan: PagePlan)?
        for (orderIndex, ordering) in permutations(active).enumerated() {
            for transposed in [false, true] {
                let width = transposed ? availableHeight : availableWidth
                let height = transposed ? availableWidth : availableHeight
                let cells = items.indices.map { index -> [Cell] in
                    let item = items[index]
                    let w = micrometers(item.trimWidthMM) + 2 * bleed
                    let h = micrometers(item.trimHeightMM) + 2 * bleed
                    // In column-major (transposed) solving the S-width axis is the page's height axis, so an
                    // upright photo has S-width = trim height. `rotated` describes the photo on the page.
                    var result = [Cell(itemIndex: index, rotated: false, width: transposed ? h : w, height: transposed ? w : h)]
                    if item.allowsRotation, w != h {
                        result.append(Cell(itemIndex: index, rotated: true, width: transposed ? w : h, height: transposed ? h : w))
                    }
                    return result.filter { $0.width <= width && $0.height <= height }
                }
                let plan = fill(ordering: ordering, demand: demand, cells: cells, width: width, height: height,
                                gutter: gutter, strategy: strategy, transposed: transposed)
                let key = [plan.placed, -plan.distinctHeights, -plan.usedLength, transposed ? 0 : 1, -orderIndex]
                if best == nil || best!.key.lexicographicallyPrecedes(key) { best = (key, plan) }
            }
        }
        return best?.plan
    }

    private static func fill(ordering: [Int], demand: [Int], cells: [[Cell]], width: Int, height: Int,
                             gutter: Int, strategy: FillStrategy, transposed: Bool) -> PagePlan {
        var plan = PagePlan(rows: [], transposed: transposed, availableWidth: width, availableHeight: height, gutter: gutter)
        var remaining = demand
        var remainingHeight = height

        func addRow(for index: Int) -> Bool {
            let spacing = plan.rows.isEmpty ? 0 : gutter
            var choice: (cell: Cell, count: Int)?
            for cell in cells[index] where cell.height + spacing <= remainingHeight {
                let columns = (width + gutter) / (cell.width + gutter)
                let count = min(remaining[index], columns)
                guard count > 0 else { continue }
                if let current = choice {
                    // More copies first, then the shorter row, then the upright orientation.
                    if count > current.count || (count == current.count && cell.height < current.cell.height) {
                        choice = (cell, count)
                    }
                } else {
                    choice = (cell, count)
                }
            }
            guard let choice else { return false }
            plan.rows.append(Row(cell: choice.cell, count: choice.count))
            remainingHeight -= choice.cell.height + spacing
            remaining[index] -= choice.count
            return true
        }

        switch strategy {
        case .byType:
            for index in ordering {
                while remaining[index] > 0, addRow(for: index) {}
            }
        case .interleave:
            var progressed = true
            while progressed {
                progressed = false
                for index in ordering where remaining[index] > 0 {
                    if addRow(for: index) { progressed = true }
                }
            }
        }
        return plan
    }

    private static func makePage(plan: PagePlan, items: [PrintItem], startCopyIndex: [Int], pageW: Int, pageH: Int,
                                 margin: Int, gutter: Int, bleed: Int, bar: Bool) -> PrintPage {
        var copyIndex = startCopyIndex
        var placements: [Placement] = []
        let startY = (plan.availableHeight - plan.usedLength) / 2
        var sy = startY
        for row in plan.rows {
            let rowWidth = row.count * row.cell.width + (row.count - 1) * gutter
            let startX = (plan.availableWidth - rowWidth) / 2
            for column in 0..<row.count {
                let sx = startX + column * (row.cell.width + gutter)
                let x = margin + (plan.transposed ? sy : sx)
                let y = margin + (plan.transposed ? sx : sy)
                let w = plan.transposed ? row.cell.height : row.cell.width
                let h = plan.transposed ? row.cell.width : row.cell.height
                let bleedRect = MillimeterRect(x: millimeters(x), y: millimeters(y), width: millimeters(w), height: millimeters(h))
                let item = items[row.cell.itemIndex]
                placements.append(Placement(itemID: item.id, copyIndex: copyIndex[row.cell.itemIndex],
                                            trim: bleedRect.insetBy(millimeters(bleed)), bleed: bleedRect,
                                            rotated: row.cell.rotated))
                copyIndex[row.cell.itemIndex] += 1
            }
            sy += row.cell.height + gutter
        }
        var calibration: CalibrationBar?
        if bar, pageW - 2 * margin >= micrometers(calibrationBarLengthMM) {
            calibration = CalibrationBar(x: millimeters((pageW - micrometers(calibrationBarLengthMM)) / 2),
                                         y: millimeters(pageH - margin - calibrationReserve / 2),
                                         lengthMM: calibrationBarLengthMM)
        }
        return PrintPage(widthMM: millimeters(pageW), heightMM: millimeters(pageH), bleedMM: millimeters(bleed),
                         placements: placements, calibrationBar: calibration)
    }

    private static func permutations(_ values: [Int]) -> [[Int]] {
        guard values.count > 1 else { return [values] }
        var result: [[Int]] = []
        for (index, value) in values.enumerated() {
            var rest = values
            rest.remove(at: index)
            for tail in permutations(rest) { result.append([value] + tail) }
        }
        return result
    }
}

extension PrintPage {
    /// Corner ticks in millimetres, clipped so they never enter a neighbouring bleed box.
    struct Tick: Sendable, Hashable {
        let fromX: Double, fromY: Double, toX: Double, toY: Double
    }

    var cornerTicks: [Tick] {
        var ticks: [Tick] = []
        let length = PrintLayoutSolver.tickLengthMM
        for placement in placements {
            let trim = placement.trim, bleed = placement.bleed
            let others = placements.filter { $0 != placement }.map(\.bleed)
            for y in [trim.minY, trim.maxY] {
                // leftward from the left bleed edge
                let leftLimit = others.filter { $0.maxX <= bleed.minX + 0.0005 && $0.minY <= y && y <= $0.maxY }.map(\.maxX).max() ?? 0
                let leftStart = max(bleed.minX - length, leftLimit)
                if bleed.minX - leftStart > 0.2 { ticks.append(Tick(fromX: leftStart, fromY: y, toX: bleed.minX, toY: y)) }
                let rightLimit = others.filter { $0.minX >= bleed.maxX - 0.0005 && $0.minY <= y && y <= $0.maxY }.map(\.minX).min() ?? widthMM
                let rightEnd = min(bleed.maxX + length, rightLimit)
                if rightEnd - bleed.maxX > 0.2 { ticks.append(Tick(fromX: bleed.maxX, fromY: y, toX: rightEnd, toY: y)) }
            }
            for x in [trim.minX, trim.maxX] {
                let topLimit = others.filter { $0.maxY <= bleed.minY + 0.0005 && $0.minX <= x && x <= $0.maxX }.map(\.maxY).max() ?? 0
                let topStart = max(bleed.minY - length, topLimit)
                if bleed.minY - topStart > 0.2 { ticks.append(Tick(fromX: x, fromY: topStart, toX: x, toY: bleed.minY)) }
                let bottomLimit = others.filter { $0.minY >= bleed.maxY - 0.0005 && $0.minX <= x && x <= $0.maxX }.map(\.minY).min() ?? heightMM
                let bottomEnd = min(bleed.maxY + length, bottomLimit)
                if bottomEnd - bleed.maxY > 0.2 { ticks.append(Tick(fromX: x, fromY: bleed.maxY, toX: x, toY: bottomEnd)) }
            }
        }
        return ticks
    }
}
