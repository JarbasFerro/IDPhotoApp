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

    /// The selected item's own count does not change its choices, so + and − keep the Fill row on screen.
    @Test func cachedCountsSurviveTheSelectedItemsOwnCount() async {
        let first = PrintItem(photoID: UUID(), trimWidthMM: 26, trimHeightMM: 32, copies: 6)
        let job = PrintJob(paper: .photo4x6, items: [first])
        let snapshot = SheetChoices.Snapshot(request: SheetChoices.Request(job: job, itemID: first.id),
                                             values: await SheetChoices.fillChoices(job: job, itemID: first.id))
        var stepped = job
        stepped.items[0].copies = 23
        let current = SheetChoices.Request(job: stepped, itemID: first.id)
        #expect(!snapshot.choices(for: current).isEmpty)
        #expect(snapshot.choices(for: current).map(\.copies) == (await SheetChoices.fillChoices(job: stepped, itemID: first.id)).map(\.copies))
    }
}
