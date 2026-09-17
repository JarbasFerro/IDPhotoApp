import SwiftUI
import Testing
@testable import IDPhotoSpike

struct StatusStyleTests {
    @Test func checkStatesUseSystemSemanticColours() {
        #expect(StatusStyle.color(for: CheckState.pass) == Color.green)
        #expect(StatusStyle.color(for: CheckState.warn) == Color.orange)
        #expect(StatusStyle.color(for: CheckState.fail) == Color.red)
        #expect(StatusStyle.color(for: CheckState.manualCheck) == Color.secondary)
    }

    @Test func headlinesFollowTheSameMapping() {
        #expect(StatusStyle.color(for: PhotoCheckSummary.Headline.checking) == Color.secondary)
        #expect(StatusStyle.color(for: PhotoCheckSummary.Headline.good) == StatusStyle.color(for: CheckState.pass))
        #expect(StatusStyle.color(for: PhotoCheckSummary.Headline.review) == StatusStyle.color(for: CheckState.warn))
        #expect(StatusStyle.color(for: PhotoCheckSummary.Headline.retake) == StatusStyle.color(for: CheckState.fail))
    }

    /// Colour is never the only signal: every state has its own symbol.
    @Test func everyStateHasADistinctSymbol() {
        let states: [CheckState] = [.pass, .warn, .fail, .manualCheck]
        #expect(Set(states.map { StatusStyle.symbol(for: $0) }).count == states.count)
    }
}
