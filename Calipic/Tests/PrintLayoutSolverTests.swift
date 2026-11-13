import Foundation
import Testing
@testable import Calipic

struct PrintLayoutSolverTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let paper: PaperSize
        let trim: (width: Double, height: Double)
        /// Lower bound from the single-grid formula; the row packer may find more.
        let minimum: Int
        /// True where mixed-orientation columns cannot beat the grid, so the count is exact.
        let exact: Bool
        var testDescription: String { "\(paper.id) \(trim.width)x\(trim.height) >= \(minimum)" }
    }

    // Verified against the formula floor((W - 2m + g) / (cell + g)) with m = 4, g = 2, adaptive bleed.
    static let table: [Case] = [
        Case(paper: .photo4x6, trim: (26, 32), minimum: 12, exact: false),
        Case(paper: .photo4x6, trim: (35, 45), minimum: 6, exact: true),
        Case(paper: .photo4x6, trim: (50.8, 50.8), minimum: 2, exact: false),
        Case(paper: .photo4x6, trim: (50, 70), minimum: 2, exact: false),
        Case(paper: .photo4x6, trim: (26, 32), minimum: 12, exact: false),
        Case(paper: .photo4x6, trim: (35, 45), minimum: 6, exact: false),
        Case(paper: .photo13x18, trim: (26, 32), minimum: 20, exact: false),
        Case(paper: .photo13x18, trim: (35, 45), minimum: 9, exact: false),
        Case(paper: .photo9x13, trim: (26, 32), minimum: 8, exact: false),
        Case(paper: .photo9x13, trim: (35, 45), minimum: 4, exact: true),
        Case(paper: .a6, trim: (26, 32), minimum: 12, exact: false),
        Case(paper: .a6, trim: (35, 45), minimum: 6, exact: false),
        Case(paper: .a5, trim: (26, 32), minimum: 30, exact: false),
        Case(paper: .a4, trim: (26, 32), minimum: 60, exact: false),
        Case(paper: .a4, trim: (35, 45), minimum: 30, exact: false),
        Case(paper: .usLetter, trim: (26, 32), minimum: 56, exact: false),
        Case(paper: .usLetter, trim: (35, 45), minimum: 28, exact: false)
    ]

    private func job(_ paper: PaperSize, items: [(Double, Double, Int)], options: PrintOptions = PrintOptions()) -> PrintJob {
        PrintJob(paper: paper, items: items.map {
            PrintItem(photoID: UUID(), trimWidthMM: $0.0, trimHeightMM: $0.1, copies: $0.2)
        }, options: options)
    }

    @Test(arguments: table)
    func singleSizeFillsOnePage(testCase: Case) {
        let job = job(testCase.paper, items: [(testCase.trim.width, testCase.trim.height, 200)], options: {
            var options = PrintOptions(); options.maxPages = 1; return options
        }())
        let layout = PrintLayoutSolver.solve(job)
        let count = layout.pages.first?.placements.count ?? 0
        if testCase.exact {
            #expect(count == testCase.minimum)
        } else {
            #expect(count >= testCase.minimum)
        }
        assertValid(layout, job: job)
    }

    @Test(arguments: table)
    func layoutIsDeterministic(testCase: Case) {
        let job = job(testCase.paper, items: [(testCase.trim.width, testCase.trim.height, 37), (26, 32, 5)])
        #expect(PrintLayoutSolver.solve(job) == PrintLayoutSolver.solve(job))
    }

    /// Founder's recording (0.20.11): each added copy re-planned the page, so it flipped between portrait and
    /// landscape and every photo moved. One photo now fills a fixed grid slot by slot.
    @Test func addingACopyOnlyAddsAPhoto() {
        var previous: PrintLayout?
        var regrids = 0
        for copies in 1...40 {
            let layout = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, copies)]))
            #expect(layout.placedCount == copies)
            let first = try! #require(layout.pages.first)
            // Every page uses the same grid: placed plus free slots is the full page, and only the last has free slots.
            let capacity = first.placements.count + first.freeSlots.count
            for (index, page) in layout.pages.enumerated() {
                #expect(page.placements.count + page.freeSlots.count == capacity)
                #expect(page.widthMM == first.widthMM && page.heightMM == first.heightMM)
                if index < layout.pages.count - 1 { #expect(page.freeSlots.isEmpty) }
            }
            if let previous, let old = previous.pages.first {
                if old.bleedMM == first.bleedMM && old.widthMM == first.widthMM {
                    // Same grid: the old copies keep their exact places.
                    let before = previous.pages.flatMap(\.placements).map(\.trim)
                    let after = layout.pages.flatMap(\.placements).map(\.trim)
                    #expect(Array(after.prefix(before.count)) == before, "copies \(copies)")
                } else {
                    regrids += 1
                }
            }
            previous = layout
        }
        // The grid never changes with the count (0.20.12: a change at the 10th copy read as a flash).
        #expect(regrids == 0)
    }

    @Test func gridFillsTopLeftFirstAsShown() throws {
        let layout = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, 2)]))
        let page = try #require(layout.pages.first)
        let rows = page.displayRows
        // Both copies sit in the first row seen on screen, starting at its left.
        #expect(rows.first == [0, 1])
        #expect(!page.freeSlots.isEmpty)
        let all = page.placements.map(\.trim) + page.freeSlots.map(\.trim)
        for (i, a) in all.enumerated() { for b in all[(i + 1)...] { #expect(!a.overlaps(b)) } }
    }

    @Test func adaptiveBleedKeepsCountAndFixedBleedCosts() {
        let adaptive = PrintLayoutSolver.solve(job(.photo4x6, items: [(35, 45, 6)]))
        #expect(adaptive.pages.count == 1)
        #expect(adaptive.pages[0].bleedMM == 0.5)
        let fixed = PrintLayoutSolver.solve(job(.photo4x6, items: [(35, 45, 6)], options: {
            var options = PrintOptions(); options.bleed = .fixed(mm: 1); return options
        }()))
        // Beyond one page the fullest grid is used: two upright rows of two plus one rotated copy in the 44 mm strip.
        #expect(fixed.pages[0].placements.count == 5)
        #expect(fixed.pages.count == 2)
        let full = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, 12)]))
        // A full 12-up sheet keeps the check bar with a smaller margin (0.20.7); it used to drop the bar for 1 mm.
        #expect(full.pages.count == 1 && full.pages[0].bleedMM > 0 && full.pages[0].bleedMM < 1)
        #expect(full.pages[0].calibrationBar != nil)
        let spare = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, 6)]))
        #expect(spare.pages[0].calibrationBar != nil)
    }

    @Test func maximumCopiesModeUsesSharedCuts() {
        let layout = PrintLayoutSolver.solve(job(.photo4x6, items: [(35, 45, 8)], options: .maximumCopies))
        #expect(layout.pages.count == 1)
        #expect(layout.pages[0].placements.count == 8)
        #expect(layout.pages[0].placements.allSatisfy { $0.rotated })
        #expect(layout.pages[0].placements.allSatisfy { $0.trim == $0.bleed })
    }

    @Test func overflowAddsPagesAndRespectsCap() {
        let layout = PrintLayoutSolver.solve(job(.photo4x6, items: [(35, 45, 30)]))
        #expect(layout.pages.count == 5)
        #expect(layout.placedCount == 30 && layout.isComplete)
        let capped = PrintLayoutSolver.solve(job(.photo4x6, items: [(35, 45, 30)], options: {
            var options = PrintOptions(); options.maxPages = 2; return options
        }()))
        #expect(capped.pages.count == 2)
        #expect(capped.placedCount == 12 && capped.unplacedCount == 18)
    }

    @Test func mixedSizesShareAPageWithPerItemCopies() {
        let job = job(.photo4x6, items: [(35, 45, 4), (26, 32, 6)])
        let layout = PrintLayoutSolver.solve(job)
        #expect(layout.isComplete)
        #expect(layout.pages.count <= 2)
        #expect(layout.pages[0].placements.count >= 7)
        let large = job.items[0].id, small = job.items[1].id
        #expect(layout.pages.flatMap(\.placements).filter { $0.itemID == large }.count == 4)
        #expect(layout.pages.flatMap(\.placements).filter { $0.itemID == small }.count == 6)
        let copyIndices = layout.pages.flatMap(\.placements).filter { $0.itemID == small }.map(\.copyIndex).sorted()
        #expect(copyIndices == Array(0..<6))
        assertValid(layout, job: job)

        var interleaved = job
        interleaved.options.fillStrategy = .interleave
        let mixed = PrintLayoutSolver.solve(interleaved)
        #expect(mixed.isComplete)
        #expect(mixed.pages.count <= 2)
        #expect(Set(mixed.pages[0].placements.map(\.itemID)).count == 2)
    }

    @Test func oversizedItemIsReportedNotLooped() {
        let job = job(.photo9x13, items: [(120, 160, 3), (26, 32, 2)])
        let layout = PrintLayoutSolver.solve(job)
        #expect(layout.unplaced[job.items[0].id] == 3)
        #expect(layout.placedCount == 2)
        let nothing = PrintLayoutSolver.solve(self.job(.photo9x13, items: [(120, 160, 3)]))
        #expect(nothing.pages.isEmpty && nothing.unplacedCount == 3)
    }

    @Test func customPaperValidationAndOrientationLock() throws {
        #expect(throws: PaperSize.ValidationError.self) { try PaperSize.custom(widthMM: 20, heightMM: 100) }
        #expect(throws: PaperSize.ValidationError.self) { try PaperSize.custom(widthMM: .nan, heightMM: 100) }
        let paper = try PaperSize.custom(widthMM: 150, heightMM: 100)
        let layout = PrintLayoutSolver.solve(job(paper, items: [(35, 45, 20)]))
        #expect(layout.pages.count == 4)
        #expect(Set(layout.pages.map { "\($0.widthMM)x\($0.heightMM)" }).count == 1)
        var landscape = job(.photo4x6, items: [(26, 32, 3)])
        landscape.options.orientation = .landscape
        #expect(PrintLayoutSolver.solve(landscape).pages[0].widthMM == 152.4)
    }

    @Test func ticksNeverEnterANeighbourAndStayOnPage() {
        let layout = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, 12)]))
        let page = layout.pages[0]
        #expect(!page.cornerTicks.isEmpty)
        for tick in page.cornerTicks {
            for placement in page.placements {
                let inside = { (x: Double, y: Double) in
                    x > placement.bleed.minX + 0.001 && x < placement.bleed.maxX - 0.001
                        && y > placement.bleed.minY + 0.001 && y < placement.bleed.maxY - 0.001
                }
                #expect(!inside(tick.fromX, tick.fromY) && !inside(tick.toX, tick.toY))
            }
            #expect(tick.fromX >= 0 && tick.toX <= page.widthMM && tick.fromY >= 0 && tick.toY <= page.heightMM)
        }
    }

    private func assertValid(_ layout: PrintLayout, job: PrintJob) {
        let margin = job.options.marginMM
        for page in layout.pages {
            for (index, placement) in page.placements.enumerated() {
                #expect(placement.bleed.minX >= margin - 0.001 && placement.bleed.minY >= margin - 0.001)
                #expect(placement.bleed.maxX <= page.widthMM - margin + 0.001)
                #expect(placement.bleed.maxY <= page.heightMM - margin + 0.001)
                let item = job.items.first { $0.id == placement.itemID }!
                let expected = placement.rotated ? (item.trimHeightMM, item.trimWidthMM) : (item.trimWidthMM, item.trimHeightMM)
                #expect(abs(placement.trim.width - expected.0) < 0.001 && abs(placement.trim.height - expected.1) < 0.001)
                #expect(abs(placement.bleed.width - placement.trim.width - 2 * page.bleedMM) < 0.001)
                for other in page.placements.dropFirst(index + 1) {
                    #expect(!placement.bleed.overlaps(other.bleed))
                }
            }
            #expect(page.utilisation <= 1)
        }
    }

    /// Founder's recording (0.20.6): 8 copies with no safety margin and no check bar came out as 5 sideways and
    /// 3 upright, although 9 upright fit. At equal copies, one orientation wins.
    @Test func equalCountsPreferOneOrientation() {
        var options = PrintOptions()
        options.bleed = .none
        options.calibrationBar = false
        for copies in 1...9 {
            let page = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, copies)], options: options)).pages[0]
            #expect(page.placements.count == copies)
            #expect(Set(page.placements.map(\.rotated)).count == 1, "\(copies) copies mix orientations")
        }
    }

    /// Founder's second recording (0.20.7): with the default options, 10 and 11 copies still had a sideways row because
    /// a full 1 mm margin outranked one orientation, although 12 upright copies fit with a smaller margin.
    @Test func defaultOptionsKeepOneOrientationUpToAFullPage() {
        for copies in 1...12 {
            let page = PrintLayoutSolver.solve(job(.photo4x6, items: [(26, 32, copies)])).pages[0]
            #expect(page.placements.count == copies)
            #expect(Set(page.placements.map(\.rotated)).count == 1, "\(copies) copies mix orientations")
            #expect(page.bleedMM > 0 && page.calibrationBar != nil, "\(copies) copies lost the margin or the check bar")
        }
    }
}
