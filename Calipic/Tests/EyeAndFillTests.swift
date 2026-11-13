import Foundation
import Testing
@testable import Calipic

struct EyeAndFillTests {
    /// Values measured on the founder's recording and the sample portraits (0.20.8).
    @Test func eyeOpennessSeparatesOpenFromDowncast() {
        for (left, right) in [(0.33, 0.337), (0.292, 0.293), (0.256, 0.254), (0.351, 0.369)] {
            #expect(!EyeOpenness.looksClosed(left: left, right: right), "\(left), \(right) are open eyes")
        }
        #expect(EyeOpenness.looksClosed(left: 0.084, right: 0.210))
        #expect(EyeOpenness.looksClosed(left: 0.05, right: 0.06))
        #expect(EyeOpenness.looksClosed(left: 0.18, right: 0.19)) // both half-closed
        #expect(EyeOpenness.ratio([(0, 0), (10, 0), (10, 3), (0, 3)]) == 0.3)
        #expect(EyeOpenness.ratio([(0, 0)]) == nil)
    }

    @Test func fillChoicesAreWholePages() async {
        let item = PrintItem(photoID: UUID(), trimWidthMM: 26, trimHeightMM: 32, copies: 8)
        let job = PrintJob(paper: .photo4x6, items: [item])
        let choices = await SheetView.fillChoices(job: job, itemID: item.id)
        #expect(choices.map(\.pages) == [1, 2, 3])
        #expect(choices.map(\.copies) == [12, 24, 36])
        for choice in choices {
            var filled = job
            filled.items[0].copies = choice.copies
            #expect(PrintLayoutSolver.solve(filled).pages.count == choice.pages)
            filled.items[0].copies = choice.copies + 1
            #expect(PrintLayoutSolver.solve(filled).pages.count == choice.pages + 1)
        }
    }
}
