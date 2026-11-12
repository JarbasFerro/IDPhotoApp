import Foundation

// Guillotine cutting order for one print page: pure Swift, deterministic, no UI imports.
// All coordinates are physical millimetres on the page, origin top-left (`PageMillimeterSpace`).

struct MillimeterPoint: Sendable, Hashable {
    let x: Double
    let y: Double
}

struct Cut: Sendable, Hashable {
    enum Stage: Int, Sendable, Hashable, Comparable {
        /// Full-width horizontal cuts that separate the rows.
        case rows
        /// Vertical cuts that separate the photos inside one row.
        case columns
        /// Short horizontal cuts that trim photos shorter than their row.
        case trims

        static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    /// 1-based position in the cutting order.
    let index: Int
    let stage: Stage
    let from: MillimeterPoint
    let to: MillimeterPoint

    var isHorizontal: Bool { from.y == to.y }
}

struct CutPlan: Sendable, Hashable {
    static let toleranceMM = 0.05

    let cuts: [Cut]
    let rowCount: Int
    let photoCount: Int

    init(page: PrintPage) {
        let tol = Self.toleranceMM
        photoCount = page.placements.count

        // Rows: bleed vertical ranges that overlap, transitively, top to bottom.
        let sorted = page.placements.sorted {
            ($0.bleed.minY, $0.bleed.minX, $0.trim.minX) < ($1.bleed.minY, $1.bleed.minX, $1.trim.minX)
        }
        var rows: [[Placement]] = []
        var rowBottom = -Double.infinity
        for placement in sorted {
            if let last = rows.indices.last, placement.bleed.minY < rowBottom - 0.0005 {
                rows[last].append(placement)
                rowBottom = max(rowBottom, placement.bleed.maxY)
            } else {
                rows.append([placement])
                rowBottom = placement.bleed.maxY
            }
        }
        rowCount = rows.count

        struct Band { let top: Double; let bottom: Double; let placements: [Placement] }
        let bands = rows.map { row in
            Band(top: row.map(\.trim.minY).min() ?? 0, bottom: row.map(\.trim.maxY).max() ?? 0, placements: row)
        }

        var result: [Cut] = []
        func add(_ stage: Cut.Stage, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
            result.append(Cut(index: result.count + 1, stage: stage,
                              from: MillimeterPoint(x: x1, y: y1), to: MillimeterPoint(x: x2, y: y2)))
        }

        // Stage 1: separate the rows.
        var made: [Double] = []
        for band in bands {
            for y in [band.top, band.bottom] where !made.contains(where: { abs($0 - y) <= tol }) {
                made.append(y)
                add(.rows, 0, y, page.widthMM, y)
            }
        }

        // Stage 2: separate the photos in each row.
        for band in bands {
            var xs: [Double] = []
            for x in band.placements.flatMap({ [$0.trim.minX, $0.trim.maxX] }).sorted()
            where !xs.contains(where: { abs($0 - x) <= tol }) {
                xs.append(x)
            }
            for x in xs { add(.columns, x, band.top, x, band.bottom) }
        }

        // Stage 3: trim photos shorter than their row.
        for band in bands {
            for placement in band.placements.sorted(by: { $0.trim.minX < $1.trim.minX }) {
                let trim = placement.trim
                if trim.minY - band.top > tol { add(.trims, trim.minX, trim.minY, trim.maxX, trim.minY) }
                if band.bottom - trim.maxY > tol { add(.trims, trim.minX, trim.maxY, trim.maxX, trim.maxY) }
            }
        }
        cuts = result
    }

    /// The first cut of a stage, which is where the drawing puts its number badge.
    func firstCut(of stage: Cut.Stage) -> Cut? { cuts.first { $0.stage == stage } }
}
