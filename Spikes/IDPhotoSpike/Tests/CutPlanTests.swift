import Foundation
import Testing
@testable import IDPhotoSpike

struct CutPlanTests {
    private func page(_ items: [(Double, Double, Int)], paper: PaperSize = .photo4x6,
                      options: PrintOptions = PrintOptions()) -> PrintPage {
        let job = PrintJob(paper: paper, items: items.map {
            PrintItem(photoID: UUID(), trimWidthMM: $0.0, trimHeightMM: $0.1, copies: $0.2)
        }, options: options)
        return PrintLayoutSolver.solve(job).pages[0]
    }

    private func covered(_ plan: CutPlan, x: Double, in rows: ClosedRange<Double>) -> Bool {
        plan.cuts.contains { !$0.isHorizontal && abs($0.from.x - x) < 0.051 && $0.from.y <= rows.lowerBound + 0.051 && $0.to.y >= rows.upperBound - 0.051 }
    }

    private func covered(_ plan: CutPlan, y: Double, xs: ClosedRange<Double>) -> Bool {
        plan.cuts.contains { $0.isHorizontal && abs($0.from.y - y) < 0.051 && $0.from.x <= xs.lowerBound + 0.051 && $0.to.x >= xs.upperBound - 0.051 }
    }

    private func assertSound(_ plan: CutPlan, _ page: PrintPage) {
        #expect(plan.cuts.map(\.index) == Array(1...max(1, plan.cuts.count)).prefix(plan.cuts.count).map { $0 })
        let stages = plan.cuts.map(\.stage)
        #expect(stages == stages.sorted())
        for cut in plan.cuts {
            for point in [cut.from, cut.to] {
                #expect(point.x >= 0 && point.x <= page.widthMM && point.y >= 0 && point.y <= page.heightMM)
            }
        }
        for placement in page.placements {
            let trim = placement.trim
            #expect(plan.cuts.contains { !$0.isHorizontal && abs($0.from.x - trim.minX) < 0.051 && $0.from.y <= trim.minY + 0.051 && $0.to.y >= trim.maxY - 0.051 })
            #expect(plan.cuts.contains { !$0.isHorizontal && abs($0.from.x - trim.maxX) < 0.051 && $0.from.y <= trim.minY + 0.051 && $0.to.y >= trim.maxY - 0.051 })
            #expect(covered(plan, y: trim.minY, xs: trim.minX...trim.maxX))
            #expect(covered(plan, y: trim.maxY, xs: trim.minX...trim.maxX))
        }
    }

    @Test func tenByFifteenWithPassportSizeCoversEveryEdge() {
        let page = page([(26, 32, 12)])
        let plan = CutPlan(page: page)
        #expect(plan.photoCount == 12)
        #expect(plan.rowCount >= 2)
        #expect(!plan.cuts.isEmpty)
        #expect(plan.cuts.allSatisfy { $0.stage != .trims })
        #expect(plan.cuts.filter { $0.stage == .rows }.count <= 2 * plan.rowCount)
        assertSound(plan, page)
    }

    @Test func mixedSizesProduceTrimCuts() {
        let page = page([(35, 45, 2), (26, 32, 4)])
        let plan = CutPlan(page: page)
        let heights = Set(page.placements.map { $0.trim.height })
        #expect(heights.count > 1)
        #expect(plan.photoCount == 6)
        assertSound(plan, page)
    }

    @Test func shortPhotoInTallRowGetsHorizontalTrims() {
        let tall = Placement(itemID: UUID(), copyIndex: 0, trim: MillimeterRect(x: 10, y: 10, width: 35, height: 45),
                             bleed: MillimeterRect(x: 10, y: 10, width: 35, height: 45), rotated: false)
        let short = Placement(itemID: UUID(), copyIndex: 0, trim: MillimeterRect(x: 50, y: 10, width: 26, height: 32),
                              bleed: MillimeterRect(x: 50, y: 10, width: 26, height: 32), rotated: false)
        let page = PrintPage(widthMM: 101.6, heightMM: 152.4, bleedMM: 0, placements: [tall, short], calibrationBar: nil)
        let plan = CutPlan(page: page)
        #expect(plan.rowCount == 1)
        #expect(plan.cuts.filter { $0.stage == .rows }.count == 2)
        #expect(plan.cuts.filter { $0.stage == .columns }.count == 4)
        let trims = plan.cuts.filter { $0.stage == .trims }
        #expect(trims.count == 1)
        #expect(trims[0].from == MillimeterPoint(x: 50, y: 42) && trims[0].to == MillimeterPoint(x: 76, y: 42))
        assertSound(plan, page)
    }

    @Test func emptyPageHasNoCuts() {
        let page = PrintPage(widthMM: 101.6, heightMM: 152.4, bleedMM: 0, placements: [], calibrationBar: nil)
        let plan = CutPlan(page: page)
        #expect(plan.cuts.isEmpty && plan.rowCount == 0 && plan.photoCount == 0)
    }

    @Test func sameInputGivesSameOutput() {
        let page = page([(35, 45, 3), (26, 32, 5)])
        #expect(CutPlan(page: page) == CutPlan(page: page))
    }
}
