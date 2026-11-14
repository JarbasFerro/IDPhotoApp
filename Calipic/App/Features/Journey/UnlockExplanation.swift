import SwiftUI

struct UnlockExplanation: View {
    let photos: Int
    let balance: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.tray) {
            Text("Unlocking gives you every print and the digital photo, as often as you like. Edits are final after that.")
                .font(.body).accessibilityIdentifier("unlockCard")
            if balance < photos {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    StatusMark(.warn)
                    if balance == 0 { Text("You have no credits.") }
                    else { Text("You have \(CreditsPresentation.count(balance)). You need \(CreditsPresentation.count(photos)).") }
                }
                .font(.body).accessibilityElement(children: .combine)
                .accessibilityIdentifier("creditBalanceLine")
            }
        }
    }
}
