import Foundation
import Testing
@testable import Calipic

struct FillSnapshotTests {
    @Test(arguments: ["paper", "person", "copies", "options"])
    func cachedCountsAreUnavailableAfterAnInputChanges(change: String) async {
        let first = PrintItem(photoID: UUID(), trimWidthMM: 26, trimHeightMM: 32, copies: 6)
        let second = PrintItem(photoID: UUID(), trimWidthMM: 26, trimHeightMM: 32, copies: 4)
        let job = PrintJob(paper: .photo4x6, items: [first, second])
        let original = SheetChoices.Request(job: job, itemID: first.id)
        let snapshot = SheetChoices.Snapshot(request: original, values: await SheetChoices.fillChoices(job: job, itemID: first.id))
        #expect(!snapshot.choices(for: original).isEmpty)
        var changed = job
        var selected = first.id
        switch change {
        case "paper": changed.paper = .a4
        case "person": selected = second.id
        case "copies": changed.items[1].copies += 1
        default: changed.options.calibrationBar.toggle()
        }
        #expect(snapshot.choices(for: SheetChoices.Request(job: changed, itemID: selected)).isEmpty)
        #expect(!snapshot.choices(for: original).isEmpty)
    }
}
