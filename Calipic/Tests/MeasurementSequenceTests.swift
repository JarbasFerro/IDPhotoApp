import Foundation
import Testing
@testable import Calipic

@MainActor
struct MeasurementSequenceTests {
    @Test(.timeLimit(.minutes(1)))
    func anImmediateDrawCompletionIsNotLost() async throws {
        let sequence = MeasurementSequence()
        var started = false
        try await sequence.waitForDraw {
            started = true
            if let id = sequence.id { sequence.drawn(id: id) }
        }
        #expect(started)
        #expect(sequence.id == nil)
    }

    @Test func onlyTheCurrentDrawReleasesTheVerdict() async throws {
        let sequence = MeasurementSequence()
        let waiting = Task { try await sequence.waitForDraw() }
        let visit = try await currentVisit(sequence)
        sequence.drawn(id: UUID())
        // Let an incorrectly resumed waiter run before checking that it is still suspended.
        try await Task.sleep(for: .milliseconds(50))
        #expect(sequence.id == visit)
        sequence.drawn(id: visit)
        try await waiting.value
        #expect(sequence.id == nil)
    }

    @Test func cancellationDiscardsLateCompletionBeforeAnotherVisit() async throws {
        let sequence = MeasurementSequence()
        let first = Task { try await sequence.waitForDraw() }
        let oldVisit = try await currentVisit(sequence)
        first.cancel()
        do { try await first.value; Issue.record("Cancelled measuring released a verdict") }
        catch is CancellationError { }
        #expect(sequence.id == nil)

        let second = Task { try await sequence.waitForDraw() }
        let newVisit = try await currentVisit(sequence)
        #expect(newVisit != oldVisit)
        sequence.drawn(id: oldVisit)
        try await Task.sleep(for: .milliseconds(50))
        #expect(sequence.id == newVisit)
        sequence.drawn(id: newVisit)
        try await second.value
        #expect(sequence.id == nil)
    }

    private func currentVisit(_ sequence: MeasurementSequence) async throws -> UUID {
        let deadline = ContinuousClock.now + .seconds(10)
        while sequence.id == nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        return try #require(sequence.id)
    }
}
