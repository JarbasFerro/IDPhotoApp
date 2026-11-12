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
}

/// What unlocking costs, in credits, shown where the person is about to use them (design 5d, ADR-048 §4).
/// The sentence about final edits is the point-of-no-return warning.
struct UnlockCard: View {
    let photos: Int
    let balance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.text) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(CreditsPresentation.photos(photos))
                    Spacer()
                    Text(CreditsPresentation.count(photos)).fontWeight(.semibold)
                }
                .padding(.horizontal)
                .frame(minHeight: 52)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("unlockCard")
                Divider().padding(.leading)
                Text("Includes the digital photo and any number of prints. After this, framing and edits are final.")
                    .font(Design.Typography.note).foregroundStyle(.secondary)
                    .padding(.horizontal).padding(.vertical, Design.Spacing.control)
            }
            .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
            Text("You have \(CreditsPresentation.count(balance)).")
                .font(Design.Typography.note).foregroundStyle(.secondary)
                .padding(.horizontal, Design.Spacing.tight)
                .accessibilityIdentifier("creditBalanceLine")
        }
    }
}

/// The balance and the packs. In the spike a pack is added without payment; the note says so.
struct CreditsView: View {
    let credits: CreditStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: Design.Spacing.caption) {
                        Text(CreditsPresentation.count(credits.balance))
                            .font(Design.Typography.hero)
                            .contentTransition(.numericText())
                            .accessibilityIdentifier("creditBalance")
                        Text("One credit unlocks one photo: its digital file and any number of prints. Printing or sharing it again is free.")
                            .font(Design.Typography.cardDetail).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.text)
                }
                Section {
                    ForEach(CreditPack.all) { pack in
                        Button {
                            withAnimation { credits.add(pack) }
                        } label: {
                            HStack {
                                Text(CreditsPresentation.count(pack.credits)).foregroundStyle(Color.primary)
                                Spacer()
                                Text(CreditsPresentation.price(pack))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
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
