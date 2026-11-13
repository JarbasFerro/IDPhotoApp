import CoreGraphics
import Foundation
import Testing
@testable import Calipic

/// Credits (ADR-048, amended 2026-11-13): two to start (one for the tutorial), one per photo, packs of 1, 5, and 10.
struct CreditLedgerTests {
    @Test func aNewInstallStartsWithTwoCredits() {
        #expect(CreditLedger().balance == 2)
        #expect(CreditLedger.startingBalance == 2)
    }

    @Test func spendingNeverGoesBelowZero() {
        var ledger = CreditLedger(balance: 2)
        let spentAll = ledger.spend(2)
        #expect(spentAll)
        #expect(ledger.balance == 0)
        let overspent = ledger.spend(1)
        #expect(!overspent)
        #expect(ledger.balance == 0)
        let spentNothing = ledger.spend(0)
        #expect(spentNothing)
        #expect(!ledger.canAfford(-1))
        #expect(CreditLedger(balance: -5).balance == 0)
    }

    @Test func addingIgnoresNegativeAmounts() {
        var ledger = CreditLedger(balance: 1)
        ledger.add(5)
        ledger.add(-3)
        #expect(ledger.balance == 6)
    }

    @Test func packsAreOneFiveAndTen() {
        #expect(CreditPack.all.map(\.credits) == [1, 5, 10])
        #expect(CreditPack.all.map(\.referencePriceUSD) == [Decimal(string: "0.99")!, Decimal(string: "3.99")!, Decimal(string: "6.99")!])
        #expect(Set(CreditPack.all.map(\.id)).count == 3)
        // Larger packs cost less per credit.
        let perCredit = CreditPack.all.map { $0.referencePriceUSD / Decimal($0.credits) }
        #expect(perCredit[0] > perCredit[1] && perCredit[1] > perCredit[2])
    }
}

@MainActor
struct CreditStoreTests {
    @Test func balanceSurvivesANewStoreOnTheSameDefaults() throws {
        let suite = "CreditStoreTests-" + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CreditStore(defaults: defaults)
        #expect(store.balance == 2)
        store.add(CreditPack.all[1])
        #expect(store.spend(2))
        #expect(CreditStore(defaults: defaults).balance == 5)
    }

    @Test func aFailedSpendChangesNothing() {
        let store = CreditStore(startingBalance: 1)
        #expect(!store.spend(2))
        #expect(store.balance == 1)
    }
}

/// Unlocking, the export gate, and "edits are final" (ADR-048 §3–5, ADR-049 §3).
@MainActor
struct UnlockTests {
    private func photo() throws -> PreparedPhoto {
        let context = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        return PreparedPhoto(id: UUID(), pixels: SourcePixels(width: 8, height: 8), preview: try #require(context.makeImage()))
    }

    private func workflow(credits: Int) -> PhotoWorkflow {
        PhotoWorkflow(pipeline: PhotoPipeline(root: FileManager.default.temporaryDirectory.appendingPathComponent("Unlock-" + UUID().uuidString)),
                      credits: CreditStore(startingBalance: credits))
    }

    @Test func unlockingSpendsOneCreditPerLockedPhotoOnce() throws {
        let model = workflow(credits: 3)
        let first = try photo(), second = try photo()
        model.install(first, mode: .add)
        model.install(second, mode: .add)
        #expect(model.lockedCount == 2)
        #expect(model.unlock([first.id]))
        #expect(model.credits.balance == 2)
        #expect(model.lockedCount == 1)
        // Unlocking everyone charges only for the person still locked.
        #expect(model.unlockAll())
        #expect(model.credits.balance == 1)
        #expect(model.unlockAll())
        #expect(model.credits.balance == 1)
        model.cancel()
    }

    @Test func aShortBalanceUnlocksNobody() throws {
        let model = workflow(credits: 1)
        model.install(try photo(), mode: .add)
        model.install(try photo(), mode: .add)
        #expect(!model.unlockAll())
        #expect(model.credits.balance == 1)
        #expect(model.lockedCount == 2)
        model.cancel()
    }

    @Test func nothingIsExportedForALockedPhoto() throws {
        let model = workflow(credits: 1)
        let person = try photo()
        model.install(person, mode: .add)
        model.prepareExport()
        #expect(model.activity == nil)
        model.prepareDigitalExport(for: person.id)
        #expect(model.activity == nil)
        #expect(model.exported == nil && model.digitalExport == nil)
        #expect(model.credits.balance == 1)
        model.cancel()
    }

    @Test func anUnlockedPhotoIsFinalUntilItIsLockedAgain() throws {
        let model = workflow(credits: 2)
        let person = try photo()
        model.install(person, mode: .add)
        model.adjustment.zoom = 2
        #expect(model.unlock([person.id]))
        model.adjustment.zoom = 3
        #expect(model.adjustment.zoom == 2)
        model.useOriginalLook(for: person.id)
        model.relock(person.id)
        #expect(model.lockedCount == 1)
        model.adjustment.zoom = 3
        #expect(model.adjustment.zoom == 3)
        // The changed photo needs its own credit.
        #expect(model.unlock([person.id]))
        #expect(model.credits.balance == 0)
        model.cancel()
    }

    @Test func anotherDocumentIsAnotherPhoto() throws {
        let model = workflow(credits: 2)
        let person = try photo()
        model.install(person, mode: .add)
        #expect(model.unlock([person.id]))
        model.setDocument(.custom(widthMM: 30, heightMM: 40))
        #expect(model.lockedCount == 1)
        model.cancel()
    }

    @Test func aRetakeIsANewLockedPhoto() throws {
        let model = workflow(credits: 2)
        model.install(try photo(), mode: .add)
        #expect(model.unlockAll())
        model.install(try photo(), mode: .replace)
        #expect(model.lockedCount == 1)
        model.cancel()
    }
}
