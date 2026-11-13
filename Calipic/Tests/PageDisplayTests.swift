import Foundation
import Testing
@testable import Calipic

/// How a printed page is shown on screen: turned a quarter when its photos lie sideways, and grouped into the rows
/// the copies appear in (U4).
struct PageDisplayTests {
    private func placement(x: Double, y: Double, width: Double, height: Double, rotated: Bool) -> Placement {
        let rect = MillimeterRect(x: x, y: y, width: width, height: height)
        return Placement(itemID: UUID(), copyIndex: 0, trim: rect, bleed: rect, rotated: rotated)
    }

    private func page(_ placements: [Placement], width: Double = 152.4, height: Double = 101.6) -> PrintPage {
        PrintPage(widthMM: width, heightMM: height, bleedMM: 0, placements: placements, calibrationBar: nil)
    }

    @Test func pageWithSidewaysPhotosIsShownTurned() {
        // Two rows of four photos lying sideways (32 × 26 on the paper) on a landscape 10 × 15 cm page.
        let sideways = (0..<8).map { placement(x: 4 + Double($0 % 4) * 34, y: 4 + Double($0 / 4) * 28, width: 32, height: 26, rotated: true) }
        let turned = page(sideways)
        #expect(turned.displaysTurned)
        #expect(abs(turned.displayAspect - 101.6 / 152.4) < 0.000_1)
        // On screen the four printed columns become four rows of two, the printed right edge on top.
        let rows = turned.displayRows
        #expect(rows.count == 4)
        #expect(rows.allSatisfy { $0.count == 2 })
        #expect(rows.first?.allSatisfy { sideways[$0].trim.x > 100 } == true)
        // Within a row, left to right on screen is top to bottom on the paper.
        #expect(rows.first.map { sideways[$0[0]].trim.y < sideways[$0[1]].trim.y } == true)
    }

    @Test func uprightPageIsShownAsPrinted() {
        let upright = (0..<6).map { placement(x: 4 + Double($0 % 3) * 28, y: 4 + Double($0 / 3) * 34, width: 26, height: 32, rotated: false) }
        let shown = page(upright, width: 101.6, height: 152.4)
        #expect(!shown.displaysTurned)
        #expect(shown.displayRows == [[0, 1, 2], [3, 4, 5]])
    }

    @Test func mixedPageFollowsTheMajority() {
        let mixed = [placement(x: 4, y: 4, width: 32, height: 26, rotated: true),
                     placement(x: 40, y: 4, width: 32, height: 26, rotated: true),
                     placement(x: 80, y: 4, width: 26, height: 32, rotated: false)]
        #expect(page(mixed).displaysTurned)
        #expect(!page([]).displaysTurned)
    }
}
