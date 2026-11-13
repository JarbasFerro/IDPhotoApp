import SwiftUI

/// Words for credit counts. People see credits everywhere; money appears only where a pack is bought.
enum CreditsPresentation {
    /// "1 credit", "5 credits", with the language's own grammar.
    static func count(_ credits: Int) -> String {
        String(AttributedString(localized: "^[\(credits) credit](inflect: true)").characters)
    }

    static func photos(_ photos: Int) -> String {
        String(AttributedString(localized: "^[\(photos) photo](inflect: true)").characters)
    }

    /// The reference price in US dollars, written for the person's locale. The App Store version shows
    /// StoreKit's own localized price instead.
    static func price(_ pack: CreditPack) -> String {
        pack.referencePriceUSD.formatted(.currency(code: "USD"))
    }

    static func pricePerPhoto(_ pack: CreditPack) -> String {
        (pack.referencePriceUSD / Decimal(pack.credits)).formatted(.currency(code: "USD"))
    }

    /// The pack with the lowest price per photo.
    static let bestValue = CreditPack.all.min { $0.referencePriceUSD / Decimal($0.credits) < $1.referencePriceUSD / Decimal($1.credits) }
}

/// What one credit buys, as three short lines. Shown where a credit is about to be spent and where credits are bought,
/// so the number always sits next to what it is for.
struct UnlockBenefits: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            line("The digital photo, sized for online forms", symbol: "photo")
            line("As many prints as you like", symbol: "printer")
            line("Print or share it again at no cost", symbol: "arrow.clockwise")
        }
        .font(Design.Typography.cardDetail)
    }

    private func line(_ text: LocalizedStringKey, symbol: String) -> some View {
        Label { Text(text) } icon: {
            Image(systemName: symbol).foregroundStyle(Color.brandAccent).frame(width: 24)
        }
    }
}

/// A count of credits as a small filled badge.
struct CreditBadge: View {
    let credits: Int

    var body: some View {
        Text(CreditsPresentation.count(credits))
            .font(Design.Typography.rowTitle).monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, Design.Spacing.row).padding(.vertical, Design.Spacing.tight)
            .background(Color.brandAccentFill, in: Capsule())
    }
}

/// What unlocking gives and what it costs, shown where the person is about to use a credit (design 5d, ADR-048 §4).
/// The line about final edits is the point-of-no-return warning.
struct UnlockCard: View {
    let photos: Int
    let balance: Int

    private var title: Text {
        photos == 1 ? Text("Unlock your photo") : Text("Unlock \(CreditsPresentation.photos(photos))")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            VStack(alignment: .leading, spacing: Design.Spacing.control) {
                HStack(alignment: .center) {
                    title.font(Design.Typography.cardTitle)
                    Spacer(minLength: Design.Spacing.text)
                    CreditBadge(credits: photos)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("unlockCard")
                UnlockBenefits()
                Divider()
                Label("After this, framing and edits are final.", systemImage: "lock")
                    .font(Design.Typography.note).foregroundStyle(.secondary)
            }
            .padding()
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            Group {
                if balance >= photos {
                    Text("You have \(CreditsPresentation.count(balance)). After this: \(CreditsPresentation.count(balance - photos)).")
                } else {
                    Text("You have \(CreditsPresentation.count(balance)). You need \(CreditsPresentation.count(photos)).")
                }
            }
            .font(Design.Typography.note).foregroundStyle(.secondary)
            .padding(.horizontal, Design.Spacing.tight)
            .accessibilityIdentifier("creditBalanceLine")
        }
    }
}

/// The balance and the packs. Until StoreKit (0.22) a pack is added without payment; the note says so.
struct CreditsView: View {
    let credits: CreditStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: Design.Spacing.control) {
                        Text(CreditsPresentation.count(credits.balance))
                            .font(Design.Typography.balance)
                            .foregroundStyle(Color.brandAccent)
                            .contentTransition(.numericText())
                            .accessibilityIdentifier("creditBalance")
                        Text("One credit unlocks one photo")
                            .font(Design.Typography.rowTitle)
                        UnlockBenefits()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.text)
                }
                Section {
                    ForEach(CreditPack.all) { pack in
                        Button {
                            withAnimation { credits.add(pack) }
                        } label: {
                            HStack(spacing: Design.Spacing.text) {
                                VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                                    HStack(spacing: Design.Spacing.text) {
                                        Text(CreditsPresentation.count(pack.credits)).foregroundStyle(Color.primary)
                                        if pack == CreditsPresentation.bestValue {
                                            Text("Best value")
                                                .font(Design.Typography.caption.weight(.semibold))
                                                .foregroundStyle(Color.brandAccent)
                                                .padding(.horizontal, Design.Spacing.text).padding(.vertical, Design.Spacing.titlePair)
                                                .background(Color.brandAccent.opacity(0.14), in: Capsule())
                                        }
                                    }
                                    if pack.credits > 1 {
                                        Text("\(CreditsPresentation.pricePerPhoto(pack)) per photo")
                                            .font(Design.Typography.note).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(CreditsPresentation.price(pack))
                                    .font(Design.Typography.rowTitle).monospacedDigit()
                                    .padding(.horizontal, Design.Spacing.control).padding(.vertical, Design.Spacing.caption)
                                    .background(Color.brandAccent.opacity(0.14), in: Capsule())
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("pack-\(pack.credits)")
                    }
                } header: {
                    Text("Get more")
                } footer: {
                    Text("Test version: credits are added without payment. In the App Store version, Apple handles the purchase.")
                }
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("creditsDone") } }
            .sensoryFeedback(.success, trigger: credits.balance)
        }
    }
}
