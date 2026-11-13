import Foundation
import Observation

/// A pack of credits sold as one consumable (ADR-048, amended 2026-11-12).
/// Prices are reference values in US dollars; the App Store sets the local price for each tier.
struct CreditPack: Identifiable, Hashable, Sendable {
    /// App Store product identifier (proposed; products are not created yet).
    let id: String
    let credits: Int
    let referencePriceUSD: Decimal

    static let all: [CreditPack] = [
        CreditPack(id: "com.jarbasferro.calipic.credits.1", credits: 1, referencePriceUSD: Decimal(string: "0.99")!),
        CreditPack(id: "com.jarbasferro.calipic.credits.5", credits: 5, referencePriceUSD: Decimal(string: "3.99")!),
        CreditPack(id: "com.jarbasferro.calipic.credits.10", credits: 10, referencePriceUSD: Decimal(string: "6.99")!)
    ]
}

/// Pure credit arithmetic. One credit unlocks one photo; a new install starts with two, one of them for the
/// first-run tutorial (ADR-048 amended, ADR-052).
struct CreditLedger: Equatable, Sendable {
    static let startingBalance = 2
    private(set) var balance: Int

    init(balance: Int = CreditLedger.startingBalance) { self.balance = max(0, balance) }

    func canAfford(_ count: Int) -> Bool { count >= 0 && balance >= count }

    /// Spends `count` credits, or changes nothing and returns false when the balance is short.
    mutating func spend(_ count: Int) -> Bool {
        guard canAfford(count) else { return false }
        balance -= count
        return true
    }

    mutating func add(_ count: Int) { balance += max(0, count) }
}

/// The person's balance. Until StoreKit (0.22) it lives in UserDefaults; the App Store version reconciles it with StoreKit
/// and the iCloud key-value store (ADR-048 §7). Pass no defaults for an in-memory balance (tests).
@MainActor
@Observable
final class CreditStore {
    static let key = "creditBalance"
    private(set) var ledger: CreditLedger
    @ObservationIgnored private let defaults: UserDefaults?

    init(defaults: UserDefaults? = nil, startingBalance: Int? = nil) {
        self.defaults = defaults
        if let startingBalance {
            ledger = CreditLedger(balance: startingBalance)
        } else if let defaults, defaults.object(forKey: Self.key) != nil {
            ledger = CreditLedger(balance: defaults.integer(forKey: Self.key))
        } else {
            ledger = CreditLedger()
        }
    }

    var balance: Int { ledger.balance }

    func canAfford(_ count: Int) -> Bool { ledger.canAfford(count) }

    func spend(_ count: Int) -> Bool {
        guard ledger.spend(count) else { return false }
        save()
        return true
    }

    /// Adds a pack's credits. Until StoreKit (0.22) it adds them without payment; StoreKit replaces this call site later.
    func add(_ pack: CreditPack) {
        ledger.add(pack.credits)
        save()
    }

    /// Gives credits back without a purchase (a tutorial photo lost before it left the app).
    func grant(_ count: Int) {
        ledger.add(count)
        save()
    }

    private func save() { defaults?.set(ledger.balance, forKey: Self.key) }
}
