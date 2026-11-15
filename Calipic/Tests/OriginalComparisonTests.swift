import Testing
@testable import Calipic

struct OriginalComparisonTests {
    @Test func aTimedTapCannotEndAHeldPhoto() throws {
        var comparison = OriginalComparison()
        comparison.showBriefly()
        let expired = try #require(comparison.pulse)
        comparison.holdPhoto(true)
        comparison.finishPulse(expired)
        #expect(comparison.isComparing)
        #expect(comparison.pulse == nil)
        comparison.holdPhoto(false)
        #expect(!comparison.isComparing)
    }

    @Test func overlappingHoldsEndOnlyAfterBothRelease() {
        var comparison = OriginalComparison()
        comparison.holdPhoto(true)
        comparison.holdControl(true)
        comparison.holdPhoto(false)
        #expect(comparison.isComparing)
        comparison.holdControl(false)
        #expect(!comparison.isComparing)
    }

    @Test func anOldTimerCannotEndANewerTap() throws {
        var comparison = OriginalComparison()
        comparison.showBriefly()
        let expired = try #require(comparison.pulse)
        comparison.showBriefly()
        let current = try #require(comparison.pulse)
        comparison.finishPulse(expired)
        #expect(comparison.isComparing)
        comparison.finishPulse(current)
        #expect(!comparison.isComparing)
    }

    @Test func accessibleToggleStillWorks() {
        var comparison = OriginalComparison()
        comparison.toggle()
        #expect(comparison.isComparing)
        comparison.toggle()
        #expect(!comparison.isComparing)
    }

    @Test func accessibleToggleEndsATimedComparison() throws {
        var comparison = OriginalComparison()
        comparison.showBriefly()
        let expired = try #require(comparison.pulse)
        comparison.toggle()
        #expect(!comparison.isComparing)
        comparison.finishPulse(expired)
        #expect(!comparison.isComparing)
    }
}
