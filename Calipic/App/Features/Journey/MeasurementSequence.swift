import Foundation
import Observation

/// A cancelled visit or interrupted overlay cannot release a later visit's verdict.
@MainActor @Observable
final class MeasurementSequence {
    private(set) var id: UUID?
    @ObservationIgnored private var completion: AsyncStream<Void>.Continuation?

    func waitForDraw(onStart: () -> Void = {}) async throws {
        try Task.checkCancellation()
        let visit = UUID()
        let (events, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        completion?.finish()
        id = visit
        completion = continuation
        defer {
            continuation.finish()
            if id == visit { id = nil; completion = nil }
        }
        onStart()
        for await _ in events { break }
        try Task.checkCancellation()
    }

    func drawn(id: UUID) {
        guard self.id == id else { return }
        completion?.yield(())
    }
}
